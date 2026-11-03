# actionlint チェックルール一覧

actionlint は、GitHub Actions のワークフローファイル（`.github/workflows/*.yml`）とアクションのメタデータ（`action.yml`）を静的にチェックするリンターです。このドキュメントは、このリポジトリで固定している **v1.7.12** の公式ドキュメント [checks.md](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md) に載っている全チェック項目をまとめたものです。

チェック項目は actionlint のバージョンによって変わるため、リンク先も v1.7.12 に固定しています。`mise.toml` で actionlint のバージョンを上げたときは、このドキュメントも見直してください。

エラーは次の形式で出力されます。末尾の `[ルール名]` で、どのルールが出したエラーかが分かります。

```text
.github/workflows/ci.yaml:6:23: undefined variable "foo". available variables are ... [expression]
```

## ルール名一覧

エラー末尾に出るルール名は全部で 18 種類です（[`rule_*.go`](https://github.com/rhysd/actionlint/tree/v1.7.12) と `syntax-check` から抽出）。

| ルール名 | 内容 |
| --- | --- |
| `syntax-check` | ワークフローの構文（キー・値・必須項目・空のマッピングなど） |
| `expression` | `${{ }}` 式の構文・型・コンテキスト・関数、スクリプトインジェクション |
| `action` | `uses:` の形式、アクションの入力（`with:`）、古いアクション、`action.yml` の構文、非推奨の入力 |
| `credentials` | ハードコードされた認証情報 |
| `deprecated-commands` | 非推奨のワークフローコマンド（`set-output` など） |
| `env-var` | 環境変数名 |
| `events` | トリガー（`on:`）のイベント・`workflow_dispatch`・CRON |
| `glob` | `branches:` や `paths:` などの glob パターン |
| `id` | ジョブ ID・ステップ ID の重複と命名規則 |
| `if-cond` | `if:` の定数条件 |
| `job-needs` | `needs:` のジョブ依存関係 |
| `matrix` | `matrix:` の値 |
| `permissions` | `permissions:` のスコープとアクセスレベル |
| `runner-label` | `runs-on:` のランナーラベル |
| `shell-name` | `shell:` のシェル名 |
| `workflow-call` | 再利用可能ワークフローの呼び出し |
| `shellcheck` | `run:` のシェルスクリプト（shellcheck 連携） |
| `pyflakes` | `run:` の Python スクリプト（pyflakes 連携） |

## チェック項目一覧

公式ドキュメントの 38 項目を、対象ごとに分けて載せています。項目名は公式ドキュメントの該当セクションへのリンクです。

### ワークフローの構文

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [想定外のキー](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-unexpected-keys) | 存在しないキーや、大文字・小文字の誤り | `syntax-check` |
| [必須キーの欠落とキーの重複](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-missing-required-duplicate-keys) | ジョブの `runs-on:` などの必須キーがない。キーが重複している（ジョブ ID などは大文字・小文字を区別せず比較） | `syntax-check` |
| [空のマッピング](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-empty-mapping) | `steps:` が空など、空にできないマッピングやシーケンス | `syntax-check` |
| [想定外の値](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-mapping-values) | 決まった文字列・真偽値・数値しか取れない項目に、それ以外の値を書いている | `syntax-check` |
| [YAML アンカー](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#yaml-anchors) | アンカー先の内容を展開してチェックする。再帰的なエイリアスや使われていないアンカーも検出 | `syntax-check` ほか |

### `${{ }}` 式

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [式の構文](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-syntax-expression) | 不正な文字、括弧の閉じ忘れ、式の途中での終了など | `expression` |
| [式の型チェック](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-type-check-expression) | 式の型をチェックする。GitHub Actions の実行時より厳しい | `expression` |
| [コンテキストと組み込み関数](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-contexts-and-builtin-func) | 存在しないコンテキストや関数、関数の引数の数・型の誤り | `expression` |
| [`steps` の型](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-contextual-step-object) | 存在しないステップや、まだ実行されていないステップの出力の参照 | `expression` |
| [`matrix` の型](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-contextual-matrix-object) | `matrix:` の定義から型を推論し、存在しないプロパティの参照を検出 | `expression` |
| [`needs` の型](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-contextual-needs-object) | `needs:` にないジョブや、ジョブの `outputs:` にない出力の参照 | `expression` |
| [比較演算子の厳密な型チェック](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-comparison-types) | 型が違うため意味をなさない `==` や `<` などの比較 | `expression` |
| [コンテキストと特殊関数の使える場所](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#ctx-spfunc-availability) | その場所では使えないコンテキストや関数（`success()` などは `if:` でしか使えない） | `expression` |
| [信頼できない入力によるスクリプトインジェクション](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#untrusted-inputs) | Issue のタイトルなど、攻撃者が操作できる値を `run:` で `${{ }}` から直接展開している | `expression` |

### ジョブ・ステップ

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [ジョブの依存関係](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-job-deps) | `needs:` の循環依存、存在しないジョブ、重複 | `job-needs` |
| [matrix の値](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-matrix-values) | `exclude:` の値が `matrix:` や `include:` にない。組み合わせの重複 | `matrix` |
| [ランナーラベル](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-runner-labels) | `runs-on:` に存在しないラベルを指定している。セルフホストランナーのラベルは設定ファイルで追加する | `runner-label` |
| [シェル名](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-shell-names) | `shell:` に使えないシェルを指定している | `shell-name` |
| [ジョブ ID・ステップ ID の重複](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-job-step-ids) | ID の重複（大文字・小文字は区別しない） | `id` |
| [ID の命名規則](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#id-naming-convention) | ID が英字か `_` で始まり、英数字・`-`・`_` だけでできているか | `id` |
| [`if:` の定数条件](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#if-cond-constant) | `if: true` のような消し忘れの条件や、常に真になってしまう書き方 | `if-cond` |
| [環境変数名](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-env-var-names) | `env:` の変数名に `=`、`&`、空白が含まれている | `env-var` |
| [ハードコードされた認証情報](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-hardcoded-credentials) | `container:` や `services:` のパスワードを secrets を使わずに直接書いている | `credentials` |
| [パーミッション](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#permissions) | `permissions:` のスコープ名とアクセスレベルの誤り | `permissions` |
| [非推奨のワークフローコマンド](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-deprecated-workflow-commands) | `set-output`、`save-state`、`set-env`、`add-path` の使用 | `deprecated-commands` |

### トリガー（`on:`）

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [Webhook イベント](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-webhook-events) | イベント名と、イベントごとに使える `types:` | `events`、`syntax-check` |
| [workflow_dispatch イベント](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-workflow-dispatch-events) | 入力の型、`choice` 型の `options:`、デフォルト値など | `events`、`expression`、`syntax-check` |
| [glob パターン](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-glob-pattern) | `branches:`、`tags:`、`paths:` などの glob の構文誤り | `glob` |
| [CRON 構文](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-cron-syntax-and-timezone) | `schedule:` の CRON 構文と、5 分より短い間隔の指定 | `events` |

### アクション（`uses:`）

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [`uses:` の形式](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-action-format) | `owner/repo@ref`、`./path`、`docker://image:tag` の形式になっているか | `action` |
| [ローカルアクションの入力](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-local-action-inputs) | ローカルアクションの `action.yml` と照らして、必須入力の不足や未定義の入力を検出 | `action` |
| [主要アクションの入力](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-popular-action-inputs) | `actions/checkout` などの主要アクションについて、必須入力の不足や未定義の入力（タイポ）を検出 | `action` |
| [古い主要アクション](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#detect-outdated-popular-actions) | `node12` など、サポートが終わったランタイムで動くバージョンを使っている（最新かどうかはチェックしない） | `action` |
| [アクションのメタデータの構文](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#action-metadata-syntax) | ワークフローで使っている `action.yml` / `action.yaml` の構文 | `action` |
| [非推奨の入力](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#deprecated-inputs-usage) | `deprecationMessage` が設定された入力の使用 | `action` |

### 再利用可能ワークフロー

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [再利用可能ワークフロー](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-reusable-workflows) | 呼び出し側と呼び出される側の構文、`inputs` の型、`inputs`・`outputs`・`secrets` の参照 | `workflow-call`、`events`、`expression`、`syntax-check` |

### 外部ツール連携（`run:`）

| チェック項目 | 内容 | ルール名 |
| --- | --- | --- |
| [shellcheck 連携](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-shellcheck-integ) | `run:` のシェルスクリプトを shellcheck でチェックする | `shellcheck` |
| [pyflakes 連携](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/checks.md#check-pyflakes-integ) | `shell: python` の `run:` を pyflakes でチェックする | `pyflakes` |

shellcheck と pyflakes は、それぞれ `PATH` 上にあるときだけ実行されます。このリポジトリでは shellcheck を `mise.toml` で入れているので shellcheck 連携は有効です。pyflakes は入れていないので、pyflakes 連携は動きません。

## エラーを無視する方法

- **コマンドラインで無視する**：`-ignore` にエラーメッセージの正規表現を渡します。複数回指定できます。

  ```sh
  actionlint -ignore 'label ".+" is unknown'
  ```

- **設定ファイルで無視する**：`.github/actionlint.yaml` の `paths:` に、ファイルの glob パターンごとに `ignore:` を書きます。`actionlint -init-config` でひな形を作れます。

  ```yaml
  paths:
    .github/workflows/**/*.{yml,yaml}:
      ignore:
        - 'shellcheck reported issue in this script: SC2086:.+'
  ```

- **外部ツール連携を止める**：`-shellcheck=` や `-pyflakes=` のように空の値を渡すと、その連携を無効にできます。

設定ファイルでは、ほかにセルフホストランナーのラベル（`self-hosted-runner.labels`）や、`vars` で参照する設定変数（`config-variables`）も指定できます。詳しくは [config.md](https://github.com/rhysd/actionlint/blob/v1.7.12/docs/config.md) を参照してください。

## このリポジトリでの実行

| タイミング | 実行方法 | 対象 |
| --- | --- | --- |
| 手動 | `actionlint` | 全ワークフロー |
| コミット前 | lefthook の pre-commit（`lefthook.yml`） | 全ワークフロー（ワークフロー、`.github/actionlint.yaml`、`action.yml` のいずれかをステージしたとき） |
| CI | `.github/workflows/run_github_actions_lint.yaml` | 全ワークフロー（ワークフロー、`action.yml`、各ツールの設定ファイル、`mise.toml` のいずれかが変わった PR と `main` への push） |

actionlint と shellcheck は、どの実行方法でも `mise.toml` で固定したバージョンを使います。
