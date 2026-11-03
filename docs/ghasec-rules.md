# ghasec ルール一覧

ghasec は、GitHub Actions のワークフローファイル（`.github/workflows/*.yml`）とアクションのメタデータ（`action.yml`）を静的に解析し、セキュリティ上の問題を見つけるツールです。このドキュメントは、このリポジトリで固定している **v0.18.0** の公式ドキュメント（[README](https://github.com/koki-develop/ghasec/blob/v0.18.0/README.md) と [rules](https://github.com/koki-develop/ghasec/tree/v0.18.0/rules)）に載っている全ルールをまとめたものです。

ルールは ghasec のバージョンによって変わるため、リンク先も v0.18.0 に固定しています。`mise.toml` で ghasec のバージョンを上げたときは、このドキュメントも見直してください。

指摘は次の形式で出力されます。メッセージの最後の `( )` の中がルール名、`Ref:` の URL がそのルールの説明ページです。`Ref:` の URL は最新版（`main` ブランチ）のドキュメントを指します。

```text
--> .github/workflows/ci.yaml:10:32
...
 3 | jobs:
 4 |   build:
...
 9 |     steps:
10 |       - uses: actions/checkout@v6
   |                                ^^ "actions/checkout@v6" must be pinned to a full length commit SHA (unpinned-action)
...
  Ref: https://github.com/koki-develop/ghasec/blob/main/rules/unpinned-action/README.md

✗ 1 error found in 1 of 1 file
⚠ 4 online rules skipped; use --online to enable them
```

ghasec には重大度の区別がなく、指摘はすべてエラーです。指摘が 1 つでもあると終了コードが 1 になり、コマンドは失敗します。

## 基本的な考え方

### チェックするファイル

引数なしで実行すると、ghasec はカレントディレクトリ（`--workdir` で変更可）の中から次のファイルを探してチェックします。ファイルを引数で指定すると、そのファイルだけをチェックします。

- `.github/workflows/*.yml` / `*.yaml`（ワークフロー）
- `**/action.yml` / `**/action.yaml`（アクション）

ghasec には設定ファイルがありません。ルールを無効にしたり動きを変えたりする方法はなく、指摘を消すには[コメントで指摘を無視する](#コメントで指摘を無視する)しかありません。

### 必須のルール

`invalid-workflow` と `invalid-action` は、ファイルの構造が正しいかを確かめる必須のルールです。このルールで指摘が出たファイルには、ほかのルールを適用しません。必須のルールの指摘は、コメントで無視することもできません。

### オンラインのルール

一部のルールは GitHub API を使うため、ネットワーク接続が必要です（[一覧](#ルール一覧)の「オンライン」列が ✅ のもの）。これらのルールは既定では実行されず、`--online` を付けたときだけ実行されます。実行しなかったときは、結果の最後に `⚠ 4 online rules skipped; use --online to enable them` と表示されます。

GitHub API にはレート制限があるため、`--online` を付けるときは環境変数 `GHASEC_GITHUB_TOKEN` か `GITHUB_TOKEN` にトークンを設定してください。トークンがなくても動きますが、制限にかかりやすくなります。

### 出力形式

`--format` で出力形式を選べます。

| 形式 | 指定方法 | 用途 |
| --- | --- | --- |
| `default`（既定） | 指定なし | 人が読むための形式（上の例） |
| `github-actions` | `--format github-actions` | GitHub Actions の注釈（`::error ...`）として出力し、PR の差分に表示する |
| `markdown` | `--format markdown` | 指摘ごとに、問題になる理由と直し方を付けた Markdown。Claude Code などの AI エージェントに渡して直してもらうのに向く |
| `sarif` | `--format sarif` | SARIF 2.1.0。GitHub Code Scanning や reviewdog と連携できる |

## ルール一覧

ルールは全部で 25 個です。ルール名は公式ドキュメントへのリンクです。

- **対象**: W = ワークフロー、A = アクション（`action.yml`）。`unused-ignore` は、ファイルの種類によらず `ghasec-ignore` コメントをチェックします。
- **必須**: 指摘が出ると、そのファイルにほかのルールを適用しないルールです（[必須のルール](#必須のルール)を参照）。
- **オンライン**: `--online` を付けたときだけ実行するルールです（[オンラインのルール](#オンラインのルール)を参照）。
- **追加**: そのルールが追加された ghasec のバージョンです。

| ルール名 | 内容 | 対象 | 必須 | オンライン | 追加 |
| --- | --- | --- | --- | --- | --- |
| [`invalid-workflow`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/invalid-workflow/README.md) | ワークフローの構造が正しいかを確かめる | W | ✅ | | v0.0.1 |
| [`invalid-action`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/invalid-action/README.md) | `action.yml` の構造が正しいかを確かめる | A | ✅ | | v0.0.1 |
| [`invalid-expression`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/invalid-expression/README.md) | `${{ }}` の式の構文が正しいかを確かめる | W, A | | | v0.0.1 |
| [`actor-bot-check`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/actor-bot-check/README.md) | PR のワークフローの `if:` で、bot かどうかを `github.actor` で判定しない | W | | | v0.5.0 |
| [`archived-action`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/archived-action/README.md) | アーカイブされたリポジトリのアクションを使わない | W, A | | ✅ | v0.9.0 |
| [`broad-secret-env`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/broad-secret-env/README.md) | ワークフロー全体やジョブの `env:` にシークレットや `github.token` を入れない | W | | | v0.8.0 |
| [`checkout-persist-credentials`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/checkout-persist-credentials/README.md) | `actions/checkout` に `persist-credentials: false` を指定する | W, A | | | v0.0.1 |
| [`dangerous-checkout`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/dangerous-checkout/README.md) | `pull_request_target` / `workflow_run` のワークフローで PR のコードをチェックアウトしない | W | | | v0.2.0 |
| [`default-permissions`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/default-permissions/README.md) | ワークフロー全体の `permissions:` を `{}` にする | W | | | v0.0.1 |
| [`deprecated-commands`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/deprecated-commands/README.md) | 非推奨のワークフローコマンドや `ACTIONS_ALLOW_UNSECURE_COMMANDS` を使わない | W, A | | | v0.3.0 |
| [`impostor-commit`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/impostor-commit/README.md) | `uses:` で固定したコミットが、参照先リポジトリのブランチかタグに含まれている | W, A | | ✅ | v0.1.0 |
| [`job-all-permissions`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/job-all-permissions/README.md) | ジョブの `permissions:` に `read-all` / `write-all` を使わない | W | | | v0.0.1 |
| [`job-timeout-minutes`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/job-timeout-minutes/README.md) | すべてのジョブに `timeout-minutes:` を書く | W | | | v0.0.1 |
| [`mismatched-sha-tag`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/mismatched-sha-tag/README.md) | `uses:` で固定したコミット SHA が、コメントに書いたタグと一致する | W, A | | ✅ | v0.0.1 |
| [`missing-app-token-permissions`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/missing-app-token-permissions/README.md) | `actions/create-github-app-token` に `permission-*` の入力を 1 つ以上指定する | W, A | | | v0.8.0 |
| [`missing-sha-ref-comment`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/missing-sha-ref-comment/README.md) | コミット SHA で固定した `uses:` に、タグなどを書いたコメントを付ける | W, A | | | v0.0.5 |
| [`script-injection`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/script-injection/README.md) | `run:` や `actions/github-script` の `script:` に `${{ }}` の式を直接書かない | W, A | | | v0.0.3 |
| [`secrets-inherit`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/secrets-inherit/README.md) | 再利用可能ワークフローの呼び出しで `secrets: inherit` を使わない | W | | | v0.5.0 |
| [`shellcheck`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/shellcheck/README.md) | `run:` のシェルスクリプトを ShellCheck でチェックする | W, A | | | v0.14.0 |
| [`unpinned-action`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/unpinned-action/README.md) | サードパーティのアクションを 40 文字のコミット SHA で、Docker のアクションをダイジェストで固定する | W, A | | | v0.0.1 |
| [`unpinned-container`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/unpinned-container/README.md) | ジョブの `container:` / `services:` のイメージをダイジェストで固定する | W | | | v0.7.0 |
| [`unpinned-reusable-workflow`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/unpinned-reusable-workflow/README.md) | 再利用可能ワークフローの参照を 40 文字のコミット SHA で固定する | W | | | v0.12.0 |
| [`unpinned-transitive-action`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/unpinned-transitive-action/README.md) | SHA で固定したアクションが、その中で固定されていないアクションや Docker イメージを使っていない | W, A | | ✅ | v0.11.0 |
| [`unused-ignore`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/unused-ignore/README.md) | 使われていない・存在しないルール名を書いた `ghasec-ignore` コメントを残さない | — | | | v0.0.1 |
| [`workspace-relative-action`](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/workspace-relative-action/README.md) | 同じリポジトリのアクションを `./` ではなく `$/` で参照する | W, A | | | v0.18.0 |

`broad-secret-env` は v0.18.0 の [rules/README.md](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/README.md) の一覧に載っていませんが、実装されていて既定で有効です（ルールの説明は[こちら](https://github.com/koki-develop/ghasec/blob/v0.18.0/rules/broad-secret-env/README.md)）。

## ルールの詳細

### 構造と構文のチェック

- **`invalid-workflow`**: トップレベルのキー（`on`、`jobs` が必須で、知らないキーは不可）、イベント名とフィルター（`branches` と `branches-ignore` の併用不可など）、`permissions:` のスコープと値、ジョブ（`runs-on` と `uses` のどちらか一方）、ステップ（`uses` と `run` のどちらか一方、リモートのアクションには `@<ref>` が必要）などをチェックします。
- **`invalid-action`**: `runs:` が必須で、`runs.using` は `composite`、`node12`〜`node24`、`docker` のどれかです。`using` の値によって書けるキーが変わります。composite アクションのステップで `run:` を書くときは `shell:` も必要です。
- **`invalid-expression`**: `${{ }}` の構文エラーや閉じ忘れを見つけます。`${{ }}` で囲まない `if:` の式もチェックします。

### 権限とシークレット

- **`default-permissions`**: ワークフロー全体の `permissions:` が書かれていないか `{}` 以外だと指摘します。`contents: read` のように絞っていても指摘されます。ワークフロー全体は `{}` にして、各ジョブで必要な権限だけを付けてください。
- **`job-all-permissions`**: ワークフロー全体を `{}` にしていても、ジョブで `write-all` を付けると意味がなくなるため、ジョブの `read-all` / `write-all` を指摘します。
- **`broad-secret-env`**: ワークフロー全体やジョブの `env:` に `${{ secrets.* }}` や `${{ github.token }}` を入れると、そのスコープのすべてのステップ（サードパーティのアクションを含む）から見えてしまいます。ステップの `env:` に入れてください。
- **`secrets-inherit`**: `secrets: inherit` は、呼び出し元のすべてのシークレットを再利用可能ワークフローに渡してしまいます。必要なシークレットだけを明示して渡してください。
- **`missing-app-token-permissions`**: `actions/create-github-app-token` は、`permission-*` を指定しないと GitHub App が持つすべての権限のトークンを発行します。

### チェックアウト

- **`checkout-persist-credentials`**: `actions/checkout` は既定で `GITHUB_TOKEN` を `.git/config` に残すため、後のステップから取り出せてしまいます。
- **`dangerous-checkout`**: `pull_request_target` / `workflow_run` のワークフローはシークレットにアクセスできるため、フォークの PR のコードをチェックアウトして実行すると、攻撃者のコードがシークレット付きで動きます（いわゆる "pwn request"）。`ref:` に PR の head を指定したり、`repository:` に PR のリポジトリを指定したり、`allow-unsafe-pr-checkout: true` を指定したりすると指摘されます。

### アクションやイメージの固定

- **`unpinned-action`**: タグやブランチは書き換えられるため、サードパーティのアクションは 40 文字のコミット SHA で固定します。`docker://` のアクションはダイジェストで固定します。
- **`unpinned-reusable-workflow`**: ジョブの `uses:` で呼ぶ再利用可能ワークフローも、40 文字のコミット SHA で固定します。
- **`unpinned-container`**: ジョブの `container:` と `services:` のイメージを、`@sha256:...` のダイジェストで固定します。
- **`unpinned-transitive-action`**（オンライン）: SHA で固定したアクションの `action.yml` を GitHub から取得し、その中で使っているアクションや Docker イメージが固定されているかを、再帰的にチェックします。
- **`missing-sha-ref-comment`**: SHA だけでは何のバージョンか分からないため、`# v6.0.2` のようにタグなどを書いたコメントを付けます。
- **`mismatched-sha-tag`**（オンライン）: コメントに書いたタグが指すコミットと、実際に固定した SHA が一致するかを GitHub API で確かめます。
- **`impostor-commit`**（オンライン）: GitHub はフォークとオブジェクトを共有しているため、フォークにしかないコミットの SHA を元のリポジトリ名で参照できてしまいます。固定した SHA が、参照先リポジトリのブランチかタグから辿れるかを確かめます。
- **`archived-action`**（オンライン）: アーカイブされたリポジトリのアクションは、セキュリティの修正を受けられません。
- **`workspace-relative-action`**: `./` で参照したアクションは、その時点のワークスペースにある `action.yml` を実行するため、前のステップ（PR のコードのチェックアウトなど）で中身を差し替えられます。同じリポジトリのアクションは `$/` で参照します。

### スクリプト

- **`script-injection`**: `run:` や `actions/github-script` の `script:` に `${{ github.event.pull_request.title }}` のような式を直接書くと、攻撃者が値に仕込んだコマンドが実行されます。式の値はステップの `env:` で環境変数に入れてから使ってください。
- **`deprecated-commands`**: `::set-env`、`::add-path`、`::set-output`、`::save-state` の代わりに、`$GITHUB_ENV`、`$GITHUB_PATH`、`$GITHUB_OUTPUT`、`$GITHUB_STATE` のファイルに書き込みます。`echo` / `printf` / `print` で出力したものだけを見つけます。
- **`shellcheck`**: `run:` のスクリプトを ShellCheck でチェックし、その結果を `shellcheck/SC2086` のようなルール名で報告します。`PATH` に `shellcheck` がないときは、このルールは実行されません。
- **`actor-bot-check`**: bot のブランチに誰かが push すると `github.actor` はその人に変わるため、`github.actor == 'dependabot[bot]'` のような判定はすり抜けられます。`github.event.pull_request.user.login` を使ってください。

## コメントで指摘を無視する

指摘を無視したい行には、その行の末尾か 1 つ前の行に `ghasec-ignore` コメントを書きます。

```yaml
steps:
  # 1 つ前の行に書く
  # ghasec-ignore: unpinned-action
  - uses: actions/checkout@v6

  # 行の末尾に書く。カンマで区切って複数のルールを指定できる
  - uses: actions/checkout@v6 # ghasec-ignore: unpinned-action, checkout-persist-credentials

  # ルール名を省略すると、その行のすべての指摘を無視する
  - uses: actions/checkout@v6 # ghasec-ignore
```

`shellcheck` の指摘は、1 行の `run:` なら `# ghasec-ignore:shellcheck/SC2086`（`# ghasec-ignore:shellcheck` で ShellCheck の指摘すべて）で無視できます。複数行の `run: |` では、ShellCheck のディレクティブ（`# shellcheck disable=SC2086`）をスクリプトの中に書きます。

無視するコメントを書いたのに指摘が出なかったときや、存在しないルール名を書いたときは、`unused-ignore` で指摘されます。

## このリポジトリでの実行

| タイミング | 実行方法 | オンラインのルール | 対象 |
| --- | --- | --- | --- |
| 手動 | `ghasec`（`--online` を付けるとオンラインのルールも実行） | `--online` を付けたときだけ実行する | リポジトリ内のすべてのワークフローと `action.yml` |
| コミット前 | lefthook の pre-commit（`lefthook.yml`）で `ghasec` | 実行しない | 同上（ワークフローか `action.yml` をステージしたとき） |
| CI | `.github/workflows/run_github_actions_lint.yaml` で `ghasec --online --format github-actions` | `GHASEC_GITHUB_TOKEN` にトークンを渡して実行する | 同上（ワークフロー、`action.yml`、各ツールの設定ファイル、`mise.toml` のいずれかが変わった PR と `main` への push） |

コミット前のチェックはオフラインなので、`archived-action`、`impostor-commit`、`mismatched-sha-tag`、`unpinned-transitive-action` は CI でしかチェックされません。

CI では `--format github-actions` で、指摘を PR の差分に注釈として表示します。GitHub の制限で、1 つのステップに表示できる注釈は 10 個までです。それより多い指摘は、ジョブのログで確認してください。

ghasec と、`shellcheck` ルールが使う ShellCheck は、どの実行方法でも `mise.toml` で固定したバージョンを使います。CI では、ランナーにあらかじめ入っている ShellCheck ではなく、mise で入れたものを使います。このリポジトリでは、ワークフローのアクションをロックファイル（`.github/workflows/actions.lock`）で固定しており、`uses:` はタグで書いています。ghasec（v0.18.0）はロックファイルを読まず、タグで書いた `uses:` を `unpinned-action` で指摘するため、各 `uses:` の行末に `# ghasec-ignore: unpinned-action` を書いています。ロックファイルで固定していない `uses:` にはこのコメントを書かないでください。ghasec がロックファイルに対応したら、このコメントは外します。ほかのルールはすべて適用しています。
