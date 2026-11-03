# zizmor ルール一覧

zizmor は、GitHub Actions のワークフローファイル（`.github/workflows/*.yml`）、アクションのメタデータ（`action.yml`）、Dependabot の設定ファイル（`.github/dependabot.yml`）、pre-commit の設定ファイル（`.pre-commit-config.yaml`）を静的に解析し、セキュリティ上の問題を見つけるツールです。zizmor ではルールを「audit（監査）」と呼びます。このドキュメントは、このリポジトリで固定している **v1.32.0** の公式ドキュメント（[docs/audits.md](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md)）に載っている全ルールをまとめたものです。

ルールは zizmor のバージョンによって変わるため、リンク先も v1.32.0 に固定しています。`mise.toml` で zizmor のバージョンを上げたときは、このドキュメントも見直してください。

指摘は次の形式で出力されます。`[ ]` の中がルール名、先頭の `help` / `warning` / `error` などが重大度、`audit confidence` が確信度（誤検知でない可能性の高さ）です。`audit documentation` の URL は最新版のドキュメントを指します。

```text
error[unpinned-uses]: unpinned action reference
 --> .github/workflows/ci.yaml:9:15
  |
9 |       - uses: actions/checkout@v6
  |               ^^^^^^^^^^^^^^^^^^^ action is not pinned to a hash (required by blanket policy)
  |
  = note: audit confidence → High
  = help: audit documentation → https://docs.zizmor.sh/audits/#unpinned-uses

1 finding: 0 informational, 0 low, 0 medium, 1 high
```

重大度は低いほうから informational、low、medium、high の 4 段階です。指摘があると、最も高い重大度に応じて終了コードが 11（informational）〜 14（high）になり、コマンドは失敗します。

## 基本的な考え方

### ペルソナ

zizmor には、どこまで細かく指摘するかを決める 3 つの「ペルソナ」があります。このリポジトリでは、ローカルでも CI でも既定の `regular` を使っています。

| ペルソナ | 指定方法 | 指摘する内容 |
| --- | --- | --- |
| `regular`（既定） | 指定なし | 誤検知が少なく、すぐに直すべきセキュリティの問題だけ |
| `pedantic` | `--pedantic` または `--persona=pedantic` | `regular` に加えて、すぐには問題にならない「コードの臭い」も |
| `auditor` | `--persona=auditor` | 誤検知の可能性が高いものも含めて、すべて |

ルールの中には、`pedantic` や `auditor` のときにしか指摘しないもの（[一覧](#ルール一覧)の「ペルソナ」列）や、ペルソナによって指摘の範囲が変わるものがあります。`regular` で隠れた指摘は、結果の最後に `(N suppressed)` と件数だけが表示されます。

### オンラインのルール

一部のルールは GitHub API を使うため、ネットワーク接続と GitHub のトークンが必要です（[一覧](#ルール一覧)の「オフライン」列が ❌ のもの）。zizmor は、環境変数 `GH_TOKEN`、`GITHUB_TOKEN`、`ZIZMOR_GITHUB_TOKEN` のどれかがあればオンラインで、なければオフラインで動きます。`--offline` を付けると、トークンがあってもオフラインで動きます。オフラインで動いたときは、これらのルールは実行されません。

### 自動修正

一部のルールは `--fix` で指摘を自動で直せます（[一覧](#ルール一覧)の「自動修正」列）。ファイルはその場で書き換えられます。

| 記号 | 意味 | 実行方法 |
| --- | --- | --- |
| ✅ | 安全な修正（壊れる可能性が低い） | `--fix` または `--fix=safe` |
| ⚠️ | 安全でない修正（たいてい正しいが、人が確認する必要がある） | `--fix=all` または `--fix=unsafe-only` |

## ルール一覧

ルールは全部で 41 個です。ルール名は公式ドキュメントへのリンクです。

- **対象**: W = ワークフロー、A = アクション（`action.yml`）、D = Dependabot の設定、P = pre-commit の設定
- **ペルソナ**: 空欄は `regular` で指摘するルールです。「一部」は、`regular` でも指摘するが、`pedantic` / `auditor` にすると指摘の範囲が広がるルールです（[ルールの詳細](#ルールの詳細)を参照）。
- **設定**: 設定ファイルの `rules.<ルール名>.config` で動きを変えられるルールです（[設定でルールの動きを変える](#設定でルールの動きを変える)を参照）。

| ルール名 | 内容 | 対象 | ペルソナ | オフライン | 自動修正 | 設定 | 追加 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [`adhoc-packages`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#adhoc-packages) | `run:` でロックファイルを使わずにパッケージを入れていないか | W, A | | ✅ | | | v1.26.0 |
| [`anonymous-definition`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#anonymous-definition) | ワークフロー・アクションに `name:` があるか | W, A | pedantic | ✅ | | | v1.10.0 |
| [`archived-uses`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#archived-uses) | アーカイブされたリポジトリのアクションを使っていないか | W, A | | ✅ | | | v1.19.0 |
| [`artipacked`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#artipacked) | `actions/checkout` が認証情報をディスクに残していないか | W | | ✅ | ⚠️ | | v0.1.0 |
| [`bot-conditions`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#bot-conditions) | なりすましできる bot の判定（`github.actor`）を使っていないか | W | | ✅ | ✅ | | v1.2.0 |
| [`cache-poisoning`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#cache-poisoning) | キャッシュを汚染される経路がないか | W | | ✅ | ⚠️ | | v0.10.0 |
| [`concurrency-limits`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#concurrency-limits) | `concurrency:` で同じワークフローの重複実行を止めているか | W | pedantic | ✅ | | | v1.16.0 |
| [`dangerous-triggers`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#dangerous-triggers) | 危険なトリガー（`pull_request_target` など）を使っていないか | W | | ✅ | | | v0.1.0 |
| [`dependabot-cooldown`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#dependabot-cooldown) | Dependabot に十分な `cooldown` があるか | D | | ✅ | ✅ | ✅ | v1.15.0 |
| [`dependabot-execution`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#dependabot-execution) | Dependabot に外部コードの実行を許可していないか | D | | ✅ | ⚠️ | | v1.15.0 |
| [`excessive-permissions`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#excessive-permissions) | `GITHUB_TOKEN` に必要以上の権限を与えていないか | W | | ✅ | | | v0.1.0 |
| [`forbidden-uses`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#forbidden-uses) | 禁止したアクションを使っていないか（設定したときだけ動く） | W, A | | ✅ | | ✅ | v1.6.0 |
| [`github-app`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#github-app) | GitHub App のトークンを危険な形で発行していないか | W, A | | ✅ | | | v1.25.0 |
| [`github-env`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#github-env) | `GITHUB_ENV` / `GITHUB_PATH` に危険な書き込みをしていないか | W, A | | ✅ | | | v0.6.0 |
| [`hardcoded-container-credentials`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#hardcoded-container-credentials) | コンテナの認証情報を直接書いていないか | W | | ✅ | | | v0.1.0 |
| [`impostor-commit`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#impostor-commit) | `uses:` の SHA がフォークにしかない偽のコミットでないか | W, A, P | | ❌ | ✅ | | v0.1.0 |
| [`insecure-commands`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#insecure-commands) | 廃止された危険なワークフローコマンドを有効にしていないか | W, A | | ✅ | ⚠️ | | v0.5.0 |
| [`insecure-url-scheme`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#insecure-url-scheme) | 暗号化されない URL（`http://`、`git://`）を使っていないか | P | | ✅ | | | v1.29.0 |
| [`known-vulnerable-actions`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#known-vulnerable-actions) | 既知の脆弱性があるアクションを使っていないか | W, A | | ❌ | ⚠️ | ✅ | v0.1.0 |
| [`misfeature`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#misfeature) | 使うべきでない機能（CMD シェルなど）を使っていないか | W, A | 一部 | ✅ | | | v1.21.0 |
| [`obfuscation`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#obfuscation) | 難読化された書き方をしていないか | W, A | | ✅ | ⚠️ | | v1.7.0 |
| [`overprovisioned-secrets`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#overprovisioned-secrets) | `secrets` コンテキスト全体を渡していないか | W, A | | ✅ | | | v1.3.0 |
| [`ref-confusion`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#ref-confusion) | `uses:` のブランチ名・タグ名が紛らわしくないか | W, A | | ❌ | | | v0.1.0 |
| [`ref-version-mismatch`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#ref-version-mismatch) | `uses:` の SHA とバージョンのコメントが一致しているか | W, A | 一部 | ✅ | ⚠️ | | v1.14.0 |
| [`secrets-inherit`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#secrets-inherit) | `secrets: inherit` を使っていないか | W | | ✅ | | | v1.1.0 |
| [`secrets-outside-env`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#secrets-outside-env) | シークレットを環境（environment）の外で使っていないか | W | auditor | ✅ | | ✅ | v1.23.0 |
| [`self-hosted-runner`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#self-hosted-runner) | セルフホストランナーを使っていないか | W | pedantic | ✅ | | | v0.1.0 |
| [`self-repository`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#self-repository) | 同じリポジトリのアクションを `$/` の書き方で参照しているか | W, A | | ✅ | ⚠️ | | v1.30.0 |
| [`stale-action-refs`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#stale-action-refs) | `uses:` の SHA がタグの付いたコミットか | W, A | pedantic | ❌ | | | v1.7.0 |
| [`superfluous-actions`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#superfluous-actions) | ランナーにあるコマンドで代わりがきくアクションを使っていないか | W, A | | ✅ | | | v1.23.0 |
| [`template-injection`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#template-injection) | `${{ }}` の展開でコードを注入されないか | W, A | 一部 | ✅ | ⚠️ | | v0.1.0 |
| [`typosquat-uses`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#typosquat-uses) | 有名なアクションに似せた名前のリポジトリを使っていないか | W, A, P | | ✅ | | | v1.26.0 |
| [`undocumented-permissions`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#undocumented-permissions) | `permissions:` の各権限に理由のコメントがあるか | W | pedantic | ✅ | | | v1.13.0 |
| [`unpinned-images`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unpinned-images) | コンテナイメージを固定しているか | W, A | 一部 | ✅ | | | v1.7.0 |
| [`unpinned-tools`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unpinned-tools) | アクションが中で使うツールのバージョンを固定しているか | W, A | | ✅ | | | v1.25.0 |
| [`unpinned-uses`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unpinned-uses) | `uses:` をコミット SHA で固定しているか | W, A | | ✅ | ⚠️ | ✅ | v0.4.0 |
| [`unredacted-secrets`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unredacted-secrets) | ログでマスクされない形でシークレットを使っていないか | W, A | | ✅ | | | v1.4.0 |
| [`unsound-condition`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unsound-condition) | `if:` が意図せず常に真になっていないか | W, A | | ✅ | ✅ | | v1.12.0 |
| [`unsound-contains`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unsound-contains) | `contains()` を部分一致ですり抜けられる形で使っていないか | W | | ✅ | | | v1.7.0 |
| [`unsound-ternary`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#unsound-ternary) | `&&` / `\|\|` の疑似三項演算子が意図どおりに動くか | W, A | | ✅ | | | v1.26.0 |
| [`use-trusted-publishing`](https://github.com/zizmorcore/zizmor/blob/v1.32.0/docs/audits.md#use-trusted-publishing) | パッケージの公開に Trusted Publishing を使えないか | W | | ✅ | | | v0.1.0 |

公式ドキュメントの各ルールの表では、`known-vulnerable-actions` と `secrets-outside-env` の「Configurable」は ❌ になっています。ただし同じページの本文では、それぞれ v1.26.0、v1.24.0 から `allow` を設定できると書かれているため、ここでは ✅ にしています。

## ルールの詳細

対象ごとに分けて、理由と直し方を載せています。

### 使うアクション・イメージ・ツールの固定

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `unpinned-uses` | `uses:` をブランチ名やタグではなく、コミット SHA で固定する。既定では `actions/*` を含むすべてのアクションが対象（v1.20.0 から）。`docker://` のイメージはタグがないと指摘する。ワークフローの依存ロックファイル（`.github/workflows/actions.lock`）があるときは、ロックファイルで固定されるワークフローのアクションは指摘せず、ロックファイルで固定できない再利用可能ワークフローの呼び出しと `action.yml` 内のアクションだけを指摘する（v1.32.0 から、実験的な対応。[説明](https://docs.zizmor.sh/usage/#workflow-lockfiles)） | ブランチやタグは付け替えられるので、アクションのリポジトリが乗っ取られると悪意のあるコードが実行されるため | `actions/checkout@<SHA> # v6` のように SHA で固定する。[pinact](https://github.com/suzuki-shunsuke/pinact) などで自動化できる。ワークフローのアクションは、`gh actions-lock` で作るロックファイルで固定してもよい |
| `ref-confusion` | `uses:` の `@v1` などが、同じ名前のブランチとタグのどちらも指しうる形になっていないか | 攻撃者が同名のブランチやタグを作ると、利用者側を変えずに悪意のあるアクションを配れるため | SHA で固定する |
| `impostor-commit` | `uses:` の SHA が、そのリポジトリではなくフォークにしかないコミットでないか | GitHub はフォークのコミットも元のリポジトリ名で参照できるので、SHA で固定していても偽のコミットを紛れ込ませられるため | 外部からの PR で SHA が変わったら、そのコミットが本当に元のリポジトリにあるか確かめる。見つかったら正しいコミットに差し替える |
| `stale-action-refs` | `uses:` の SHA が、タグの付いていないコミットを指していないか | リリースされていないコミットには、修正済みでも公表されていないバグや脆弱性があるかもしれず、変更履歴からどの変更を含むかも分かりにくいため | タグの付いたコミットの SHA で固定する |
| `ref-version-mismatch` | `uses:` の SHA と、後ろのバージョンのコメント（`# v6` など）が一致しているか。`pedantic` ではコメントがない場合も指摘する | コメントが古いと、Dependabot がコメントを更新しなくなり、ずれが大きくなるため | SHA に合わせてコメントを直す。pinact で自動化できる |
| `typosquat-uses` | `uses:` や pre-commit の `repo:` が、有名なアクションやフックの名前を 1 文字だけ変えた別の持ち主のリポジトリでないか | 打ち間違えた名前のリポジトリを攻撃者が作っていると、そのコードが実行されるため | 正しいリポジトリ名に直す。オフラインでは確信度が低く、トークンがあると実在を確かめて確信度を上げる |
| `archived-uses` | アーカイブされたリポジトリのアクション・再利用可能ワークフローを使っていないか | 保守されておらず、脆弱性が見つかっても直らないため | 使うのをやめるか、保守されている別のアクションに替える。`gh` コマンドで代わりがきくことが多い |
| `known-vulnerable-actions` | [GitHub Advisory Database](https://github.com/advisories) に載っている脆弱性があるアクションを使っていないか | 公表された脆弱性を突かれるため | 直ったバージョンに上げるか、使うのをやめる |
| `unpinned-images` | ジョブの `container.image:` などのイメージを固定しているか。タグなしや `latest` は `regular` で、`latest` 以外のタグ（SHA256 でない）は `pedantic` で指摘する | 固定しないと、レジストリ側でイメージが差し替えられたときに防げないため | SHA256 のダイジェストで固定する |
| `unpinned-tools` | アクションが中で取ってくるツールのバージョンを固定しているか。今の対象は `aquasecurity/setup-trivy` と `1password/load-secrets-action` だけ | アクションを固定していても、中で常に最新のツールを取ってくると固定の意味がないため | `with.version` に具体的なバージョンを書く |
| `self-repository` | 同じリポジトリのアクション・再利用可能ワークフローを `uses: ./...` ではなく `uses: $/...` で参照しているか | `./...` は実行時のファイルの状態に左右され、前のステップで取ってきたコードを読み込めてしまうため。`$/...` なら GitHub の「すべて固定する」ポリシーも適用できる | `uses: ./...` を `uses: $/...` に書き換える |
| `superfluous-actions` | ランナーに最初からあるコマンドで代わりがきくアクションを使っていないか（例：`softprops/action-gh-release` → `gh release create`） | アクション自体の依存関係が攻撃される範囲を広げるため | アクションをやめ、ランナーにあるコマンド（`gh`、`git`、`docker`、`jq` など）を使う |
| `forbidden-uses` | 設定ファイルで許可・禁止したアクションの一覧に反していないか。設定しないと何もしない | 使ってよいアクションを組織で決めるため | 該当する `uses:` を消すか、設定ファイルで許可する |

### 権限・トークン

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `excessive-permissions` | `GITHUB_TOKEN` に必要以上の権限を与えていないか。`permissions:` を書かない場合（リポジトリの既定の権限になる）も指摘する | ワークフロー全体の権限はすべてのジョブに引き継がれ、既定の権限も広いことがあるため | ワークフロー全体では `permissions: {}` にして、必要な権限をジョブごとに書く |
| `undocumented-permissions` | `permissions:` の各権限に、なぜ必要かのコメントがあるか。`contents: read` は対象外 | 理由が分かれば、権限を広げすぎるのを防ぎやすいため | 権限の行にコメントで理由を書く |
| `artipacked` | `actions/checkout` が認証情報をディスクに残していないか。v6.0.0 以降は保存場所が変わったので重大度を下げて指摘する | 残った認証情報が、アーティファクトのアップロードなどで漏れるおそれがあるため | git の操作が要らなければ `persist-credentials: false` を付ける。要るなら `persist-credentials: true` と明示する |
| `github-app` | GitHub App のトークン（`actions/create-github-app-token` など）を危険な形で発行していないか。`skip-token-revoke: true`、`owner:` だけで `repositories:` がない、権限を絞っていない場合を指摘する | トークンの有効期間や、使えるリポジトリ・権限が必要以上に広がるため | 必要なリポジトリと権限だけに絞り、使い終わったら失効させる |

### シークレット

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `secrets-inherit` | 再利用可能ワークフローの呼び出しで `secrets: inherit` を使っていないか | 必要のないシークレットまで渡り、どのシークレットで動いたのか分からなくなるため | 必要なシークレットだけを `secrets:` で 1 つずつ渡す |
| `overprovisioned-secrets` | `${{ toJSON(secrets) }}` のように `secrets` コンテキスト全体を使っていないか | 使わないシークレットまでランナーに渡るため | シークレットを名前で 1 つずつ参照する |
| `unredacted-secrets` | `fromJSON(secrets.X).password` のように、シークレットを構造化された値として扱っていないか | ランナーはシークレット全体の文字列しかマスクしないので、取り出した一部がログに出るため | JSON などにまとめず、項目ごとに別のシークレットにする |
| `secrets-outside-env` | 環境（environment）を指定していないジョブでシークレットを使っていないか。`GITHUB_TOKEN` は対象外 | 環境のシークレットなら、保護ルールを満たすジョブにだけ渡せるため | シークレットを環境に移し、それを使うジョブにだけ環境を指定する。再利用可能ワークフローとの相性の問題があるため、v1.24.0 から `auditor` だけで指摘する |
| `hardcoded-container-credentials` | `container:` や `services:` のレジストリの認証情報を直接書いていないか | リポジトリを読める人に認証情報が見えるため | シークレットを使う |

### トリガー・実行条件

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `dangerous-triggers` | `pull_request_target`、`workflow_run`、`issue_comment`（v1.31.0 から）を使っていないか | フォークからの PR などで起動できるのに、元のリポジトリの権限で動くため。PR のコードを実行しないつもりでも、引数や環境変数の注入で実行される例が多い | `pull_request` や `workflow_call` に置き換える。どうしても使うなら、PR のコードを実行せず、対象ブランチを絞る |
| `bot-conditions` | `github.actor == 'dependabot[bot]'` のような bot の判定を使っていないか | `github.actor` は最後に操作した人なので、攻撃者が bot に最後の操作をさせればすり抜けられるため | `github.event.pull_request.user.login` など、PR を作った人を見る |
| `unsound-condition` | `if:` が意図せず常に真になっていないか | YAML の `\|` などは末尾に改行が付くので、`${{ false }}` が `'false\n'` という真の値になるため | `if:` では `${{ }}` を付けずに書くか、`\|-` / `>-` を使う |
| `unsound-contains` | `contains('refs/heads/main refs/heads/develop', github.ref)` のように、文字列に対して `contains()` を使っていないか | 部分一致になるので、`mai` のようなブランチ名でもすり抜けられるため | `contains(fromJSON('["refs/heads/main", "refs/heads/develop"]'), github.ref)` のように配列を渡すか、`==` を `\|\|` でつなぐ |
| `unsound-ternary` | `cond && '' \|\| 'b'` のように、`&&` / `\|\|` の疑似三項演算子で真のときの値が偽になりうる形になっていないか | 真のときの値が偽（`''`、`0`、`false`、`null`）だと、条件が真でも後ろの値になるため | `case(...)` 関数を使うか、真のときの値が偽にならないように書き換える |
| `concurrency-limits` | `concurrency:` で、同じワークフローの古い実行を止めているか | 不要な実行がランナーを無駄に使い、アーティファクトの取り違えも起こりうるため | `concurrency:` に `cancel-in-progress: true` を書く |

### コードの注入・環境

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `template-injection` | `run:` などで、攻撃者が操作できる値（`github.event.issue.title` など）を `${{ }}` で直接展開していないか。`pedantic` / `auditor` では、安全そうな値も含めてすべての展開を指摘する | `${{ }}` は実行前にそのまま埋め込まれるので、シェルのコードを注入されるため | 値を `env:` で環境変数に入れ、`${VARNAME}` で参照する（`${{ env.VARNAME }}` では直らない） |
| `github-env` | `GITHUB_ENV` / `GITHUB_PATH` に、攻撃者が操作できる値を書き込んでいないか | `LD_PRELOAD` を設定されたり、`PATH` で別のコマンドに差し替えられたりして、任意のコードが実行されるため | 危険なトリガーのワークフローでは書き込まない。ステップ間の値の受け渡しには `GITHUB_OUTPUT` を使う |
| `insecure-commands` | `ACTIONS_ALLOW_UNSECURE_COMMANDS` で、廃止されたワークフローコマンド（`::set-env`、`::add-path`）を有効にしていないか | 標準出力に書ける処理なら環境変数を書き換えられ、コードを実行されるため | `GITHUB_ENV` や `GITHUB_PATH` などのファイルを使う |
| `cache-poisoning` | リリースのワークフローがキャッシュを読んでいないか。危険なトリガーのワークフローが `cache-mode: write` でキャッシュに書いていないか（v1.31.0 から） | 権限の低いワークフローでキャッシュを汚染し、リリースのワークフローに悪意のあるコードを持ち込めるため | リリースのワークフローで `cache-mode: none` にするか、キャッシュを使うアクションをやめる・無効にする |
| `adhoc-packages` | `run:` で `npm install <pkg>` や `gem install <pkg>` のように、ロックファイルを使わずにパッケージを入れていないか（npm、yarn、pnpm、gem、bundle が対象） | バージョンを固定しないと、乗っ取られた新しいバージョンを入れてしまうため | パッケージをマニフェストに書いてロックファイルをコミットし、`npm ci` や `bundle install` で入れる |
| `obfuscation` | `uses:` のパスの余分な `/` や `..`、`fromJSON(toJSON(...))` のような意味のない式など、難読化された書き方をしていないか | ほかのルールが見逃す原因になるため | 書き方を単純にする |
| `misfeature` | `actions/setup-python` の `pip-install`、Windows の CMD シェル（`shell: cmd`）を使っていないか。`auditor` では、GitHub が文書化していないシェルも指摘する | 監査しにくく、壊れやすいため | 使うのをやめるか、別の方法に置き換える |
| `self-hosted-runner` | セルフホストランナーを使っていないか | セルフホストランナーは安全に保つのが難しく、公開リポジトリでは特に危険なため | 非公開リポジトリだけで使う。公開リポジトリで使うなら、外部の人の実行に承認を必須にし、使い捨て（ephemeral）のランナーにする |

公式ドキュメントでは、`self-hosted-runner` は `audits.md` に「`--pedantic` のときだけ」、`usage.md` に「`auditor` のときだけ」と書かれています。どちらにしても、既定の `regular` では指摘されません。

### Dependabot・pre-commit・パッケージの公開

| ルール名 | 内容 | 理由 | 直し方 |
| --- | --- | --- | --- |
| `dependabot-cooldown` | Dependabot の各アップデーターに `cooldown:` があり、`default-days` が 7 日以上か（日数は設定で変えられる） | 公開直後のバージョンは、乗っ取られたものがまだ取り下げられていないおそれがあるため | `cooldown: { default-days: 7 }` を書く |
| `dependabot-execution` | Dependabot に `insecure-external-code-execution: allow` を設定していないか | 依存関係を解決するときに外部のコードが実行され、認証情報を盗まれるおそれがあるため | `deny` にするか、書かない（既定は `deny`） |
| `insecure-url-scheme` | pre-commit の設定の `repo:` で、`http://` や `git://` を使っていないか | 通信が暗号化されず、改ざんされるおそれがあるため | `https://` か `ssh://` を使う |
| `use-trusted-publishing` | PyPI や RubyGems などへの公開に、API トークンではなく Trusted Publishing（OIDC）を使えないか | 長く使える API トークンを持たずに済むため | パッケージの公開先で Trusted Publishing を設定し、対応するアクション（`pypa/gh-action-pypi-publish` など）を使う |

## 指摘を無視する方法

### コメントで無視する

指摘された場所に `# zizmor: ignore[ルール名]` というコメントを書くと、その指摘を無視できます。カンマで区切って複数のルールを書くこともでき、後ろに理由も書けます。

```yaml
run: | # zizmor: ignore[template-injection] 無視する理由を書く
  echo "${{ github.event.issue.title }}"
```

コメントは YAML のコメントとして書く必要があります。`run: |` の中（文字列の一部）に書いても無視されません。

### 設定ファイルで無視する

設定ファイルの `rules.<ルール名>.ignore` に、無視する場所を `ファイル名[:行[:列]]` の形式で書きます。ファイル名はワークフローのファイル名（ディレクトリを含まない）で、行と列は 1 から数えます。行や列を省くと、そのファイル全体・行全体が対象になります。

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/zizmorcore/zizmor/v1.32.0/support/zizmor.schema.json
rules:
  template-injection:
    ignore:
      # ci.yaml の 100 行目はすべて無視する
      - ci.yaml:100
  # ルール自体を止める（最終手段）
  concurrency-limits:
    disable: true
```

設定ファイルは、リポジトリのルートで次の順に探され、最初に見つかったものを使います。`--config` オプションか環境変数 `ZIZMOR_CONFIG` で場所を指定することもできます。ghalint と違い、`.zizmor.yml` のようにドットで始まる名前は探されません。

1. `.github/zizmor.yml`
2. `.github/zizmor.yaml`
3. `zizmor.yml`
4. `zizmor.yaml`

設定ファイルではアクション（`action.yml`）の指摘は無視できないので、コメントで無視してください。また、`disable: true` で止めたルールは、無視した件数にも表示されなくなり、新しい指摘に気づけません。公式ドキュメントでは、まず `ignore` で個別に無視することを勧めています。`--no-ignores` を付けると、すべての無視を外して実行できます。

### 設定でルールの動きを変える

設定ファイルの `rules.<ルール名>.config` で、次の 5 つのルールの動きを変えられます。

| ルール名 | 設定項目 | 内容 | 既定値 |
| --- | --- | --- | --- |
| `unpinned-uses` | `policies` | `uses:` のパターンごとに、`hash-pin`（SHA で固定）、`ref-pin`（タグでもよい）、`any`（固定しなくてよい）を決める | すべて `hash-pin` |
| `forbidden-uses` | `allow` / `deny` | 使ってよい・いけないアクションのパターンを並べる | なし（何もしない） |
| `dependabot-cooldown` | `days` | `cooldown` の `default-days` の最小値 | `7` |
| `known-vulnerable-actions` | `allow` | 無視する脆弱性のアドバイザリ ID（`GHSA-...`） | なし |
| `secrets-outside-env` | `allow` | 環境の外で使ってよいシークレットの名前 | なし |

`rules.<ルール名>.remap.severity` で、ルールの重大度を変えることもできます（v1.25.0 から）。

```yaml
rules:
  unpinned-uses:
    config:
      policies:
        # actions/* はタグでもよいが、actions/checkout は SHA で固定する
        "actions/*": ref-pin
        "actions/checkout": hash-pin
  artipacked:
    remap:
      severity: high
```

## このリポジトリでの実行

| タイミング | 実行方法 | オンラインのルール | 対象 |
| --- | --- | --- | --- |
| 手動 | `zizmor .`（`--offline` を付けるとオフライン） | トークンがあれば実行する | リポジトリ内のすべてのワークフロー、`action.yml`、Dependabot・pre-commit の設定 |
| コミット前 | lefthook の pre-commit（`lefthook.yml`）で `zizmor --offline .` | 実行しない | 同上（ワークフロー、`action.yml`、Dependabot・pre-commit の設定、zizmor の設定ファイルをステージしたとき） |
| CI | `.github/workflows/run_github_actions_lint.yaml` で `zizmor --format github .` | `GITHUB_TOKEN` を渡して実行する | 同上（ワークフロー、`action.yml`、各ツールの設定ファイル、`mise.toml` のいずれかが変わった PR と `main` への push） |

コミット前のチェックはオフラインなので、`impostor-commit`、`known-vulnerable-actions`、`ref-confusion` は CI でしかチェックされません（`stale-action-refs` もオンラインのルールですが、`pedantic` 専用なので CI でも実行されません）。`typosquat-uses` はオフラインでも動きますが、リポジトリが実在するかを確かめられないため、確信度は低くなります。

CI では `--format github` で、指摘を PR の差分に注釈として表示します。GitHub の制限で、1 つのステップに表示できる注釈は 10 個までです。それより多い指摘は、ジョブのログで確認してください。

zizmor は、どの実行方法でも `mise.toml` で固定したバージョンを使います。どの実行方法でもペルソナは既定の `regular` です。このリポジトリには今のところ zizmor の設定ファイルはなく、すべてのルールを既定の設定で適用しています。ワークフローのアクションはロックファイル（`.github/workflows/actions.lock`）で固定しており、`uses:` はタグで書いていますが、zizmor はロックファイルを読むので `unpinned-uses` で指摘されません。ロックファイルがあると、実行のたびに実験的な対応である旨の警告（`WARN ... uses a GitHub Actions workflow lockfile`）が出ます。
