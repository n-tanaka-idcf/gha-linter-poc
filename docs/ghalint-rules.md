# ghalint ポリシー一覧

ghalint は、GitHub Actions のワークフローファイル（`.github/workflows/*.yml`）とアクションのメタデータ（`action.yml`）が、セキュリティのベストプラクティスに沿っているかをチェックするリンターです。このドキュメントは、このリポジトリで固定している **v1.6.0** の公式ドキュメント（[README](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/README.md#policies) と [docs/policies](https://github.com/suzuki-shunsuke/ghalint/tree/v1.6.0/docs/policies)）に載っている全ポリシーをまとめたものです。

ポリシーは ghalint のバージョンによって変わるため、リンク先も v1.6.0 に固定しています。`mise.toml` で ghalint のバージョンを上げたときは、このドキュメントも見直してください。

違反は次の形式で出力されます。`policy_name=` でどのポリシーの違反かが、`reference=` でそのポリシーの説明ページが分かります。

```text
ERR the step violates policies program=ghalint version=1.6.0 workflow_file_path=.github/workflows/ci.yaml policy_name=checkout_persist_credentials_should_be_false reference=https://github.com/suzuki-shunsuke/ghalint/blob/main/docs/policies/013.md job_name=build step_name="Checkout repository" error="persist-credentials should be false"
```

## ポリシー一覧

ポリシーは全部で 13 個です。ワークフロー（`ghalint run`）には 12 個、アクション（`ghalint run-action`）には 5 個を適用します。ポリシー名は公式ドキュメントへのリンクです。

| 番号 | ポリシー名 | 内容 | ワークフロー | アクション | 無視 |
| --- | --- | --- | --- | --- | --- |
| 001 | [`job_permissions`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/001.md) | すべてのジョブに `permissions:` を書く | ✅ | | |
| 002 | [`deny_read_all_permission`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/002.md) | `permissions: read-all` を使わない | ✅ | | |
| 003 | [`deny_write_all_permission`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/003.md) | `permissions: write-all` を使わない | ✅ | | |
| 004 | [`deny_inherit_secrets`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/004.md) | 再利用可能ワークフローの呼び出しで `secrets: inherit` を使わない | ✅ | | ✅ |
| 005 | [`workflow_secrets`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/005.md) | ワークフロー全体の `env:` にシークレットを入れない | ✅ | | |
| 006 | [`job_secrets`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/006.md) | ジョブの `env:` にシークレットを入れない | ✅ | | ✅ |
| 007 | [`deny_job_container_latest_image`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/007.md) | ジョブの `container:` のイメージに `latest` タグを使わない | ✅ | | |
| 008 | [`action_ref_should_be_full_length_commit_sha`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/008.md) | `uses:` のバージョンを 40 文字のコミット SHA で固定する | ✅ | ✅ | ✅ |
| 009 | [`github_app_should_limit_repositories`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/009.md) | GitHub App のトークンを発行するとき、使えるリポジトリを絞る | ✅ | ✅ | ✅ |
| 010 | [`github_app_should_limit_permissions`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/010.md) | GitHub App のトークンを発行するとき、権限を絞る | ✅ | ✅ | |
| 011 | [`action_shell_is_required`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/011.md) | `run:` を書いたステップには `shell:` も書く | | ✅ | |
| 012 | [`job_timeout_minutes_is_required`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/012.md) | すべてのジョブに `timeout-minutes:` を書く | ✅ | | |
| 013 | [`checkout_persist_credentials_should_be_false`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/013.md) | `actions/checkout` に `persist-credentials: false` を付ける | ✅ | ✅ | ✅ |

「無視」の列は、設定ファイルで違反を無視できるポリシーです（[エラーを無視する方法](#エラーを無視する方法)を参照）。

## ポリシーの詳細

対象ごとに分けて、理由と例外（違反にならない場合）を載せています。

### 権限（`permissions:`）

| ポリシー名 | 内容 | 理由 | 例外 |
| --- | --- | --- | --- |
| `job_permissions` | すべてのジョブに `permissions:` を書く | 必要な権限だけを与えるため | ワークフロー全体の `permissions:` が `{}`（空）のとき。ワークフローのジョブが 1 つだけで、ワークフロー全体に `permissions:` があるとき |
| `deny_read_all_permission` | `read-all` を使わず、必要なスコープだけを書く（例：`contents: read`） | 必要な権限だけを与えるため | なし |
| `deny_write_all_permission` | `write-all` を使わず、必要なスコープだけを書く（例：`contents: write`） | 必要な権限だけを与えるため | なし |

### シークレット

| ポリシー名 | 内容 | 理由 | 例外 |
| --- | --- | --- | --- |
| `deny_inherit_secrets` | `secrets: inherit` を使わず、必要なシークレットだけを 1 つずつ渡す | 必要なジョブにだけシークレットを渡すため | なし |
| `workflow_secrets` | ワークフロー全体の `env:` にシークレット（`${{ secrets.* }}` や `${{ github.token }}`）を入れず、ジョブかステップの `env:` に入れる | 必要なジョブ・ステップにだけシークレットを渡すため | ワークフローのジョブが 1 つだけのとき |
| `job_secrets` | ジョブの `env:` にシークレットを入れず、ステップの `env:` に入れる | 必要なステップにだけシークレットを渡すため | ジョブのステップが 1 つだけのとき |

### 使うアクション・イメージの固定

| ポリシー名 | 内容 | 理由 | 例外 |
| --- | --- | --- | --- |
| `action_ref_should_be_full_length_commit_sha` | `uses:` のバージョンを `actions/checkout@v4` のようなタグではなく、40 文字のコミット SHA で固定する（例：`actions/checkout@<SHA> # v4`）。アクションのほか、再利用可能ワークフロー（`jobs.<job_id>.uses`）と `docker://` のイメージも対象 | タグは付け替えられるので、SHA で固定しないと、アクションのリポジトリに悪意のあるコードを入れられたときに防げないため | ワークフローのアクションが、ワークフローの依存ロックファイル（`.github/workflows/actions.lock`）でコミットに固定されているとき（再利用可能ワークフロー、Docker イメージ、`action.yml` 内のアクションはロックファイルがあってもチェックする） |
| `deny_job_container_latest_image` | ジョブの `container:` のイメージに `latest` タグを使わず、タグかダイジェストで固定する | 実行するイメージを固定するため | なし |

タグを SHA に書き換えるには [pinact](https://github.com/suzuki-shunsuke/pinact) が使えます。

`action_ref_should_be_full_length_commit_sha` は、ロックファイルを読めなかった場合（壊れている、ghalint が対応していない新しい形式など）、このポリシー自体をスキップします。ほかのポリシーはチェックしますが、違反がなくても ghalint は終了コード 1 で失敗します。

### GitHub App のトークン

[`tibdex/github-app-token`](https://github.com/tibdex/github-app-token) と [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token) の 2 つのアクションが対象です。

| ポリシー名 | 内容 | 理由 | 例外 |
| --- | --- | --- | --- |
| `github_app_should_limit_repositories` | トークンを使えるリポジトリを絞る（`tibdex/github-app-token` は `repositories:`、`actions/create-github-app-token` は `repositories:`） | トークンでできることを最小限にするため | `actions/create-github-app-token` で `owner:` と `repositories:` をどちらも書かない場合は、今のリポジトリだけに絞られるので違反にならない |
| `github_app_should_limit_permissions` | トークンの権限を絞る（`tibdex/github-app-token` は `permissions:`、`actions/create-github-app-token` は `permission-<スコープ>:`） | トークンでできることを最小限にするため | なし |

`actions/create-github-app-token` で権限を絞れるのは v1.12.0 からです。それより古い場合は、先にアクションを上げてください。

### ジョブ・ステップの設定

| ポリシー名 | 内容 | 理由 | 例外 |
| --- | --- | --- | --- |
| `job_timeout_minutes_is_required` | すべてのジョブに `timeout-minutes:` を書く | 書かないと、止まったジョブが 6 時間動き続けるため | ジョブのすべてのステップに `timeout-minutes:` があるとき。ジョブが再利用可能ワークフローを呼び出すとき（`timeout-minutes:` を書けないため） |
| `checkout_persist_credentials_should_be_false` | `actions/checkout` に `persist-credentials: false` を付ける | 付けないとトークンが `.git/config` に残り、checkout より後のすべてのステップから使えてしまうため | なし |
| `action_shell_is_required` | `action.yml` で `run:` を書いたステップには `shell:` も書く（アクションのみ） | コンポジットアクションでは `run:` を書いたら `shell:` が必須のため | なし |

`timeout-minutes:` は [ghatm](https://github.com/suzuki-shunsuke/ghatm)、`persist-credentials: false` は [disable-checkout-persist-credentials](https://github.com/suzuki-shunsuke/disable-checkout-persist-credentials) で自動的に付けられます。

## エラーを無視する方法

設定ファイルの `excludes:` に、無視する違反を書きます。設定ファイルは、リポジトリのルートで次の順に探され、最初に見つかったものを使います。`-config`（`-c`）オプションか環境変数 `GHALINT_CONFIG` で場所を指定することもできます。

1. `ghalint.yaml`
2. `.ghalint.yaml`
3. `.github/ghalint.yaml`
4. `ghalint.yml`
5. `.ghalint.yml`
6. `.github/ghalint.yml`

無視できるのは次の 5 つのポリシーだけです。それ以外のポリシーを書くと、`the policy can't be excluded` のエラーになります。

| ポリシー名 | ワークフローで必須の項目 | アクションで必須の項目 |
| --- | --- | --- |
| `deny_inherit_secrets` | `workflow_file_path`、`job_name` | （対象外） |
| `job_secrets` | `workflow_file_path`、`job_name` | （対象外） |
| `action_ref_should_be_full_length_commit_sha` | `action_name` | `action_name` |
| `github_app_should_limit_repositories` | `workflow_file_path`、`job_name`、`step_id` | `action_file_path`、`step_id` |
| `checkout_persist_credentials_should_be_false` | `workflow_file_path`、`job_name` | `action_file_path` |

`policy_name` はどの場合も必須です。`action_name` には glob パターン（[Go の `path.Match`](https://pkg.go.dev/path#Match) の形式）も書けます。

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/suzuki-shunsuke/ghalint/v1.6.0/json-schema/ghalint.json
excludes:
  # SHA での固定に対応していないアクション
  - policy_name: action_ref_should_be_full_length_commit_sha
    action_name: slsa-framework/slsa-github-generator/*
  # このジョブだけは checkout 後に git push するのでトークンを残す
  - policy_name: checkout_persist_credentials_should_be_false
    workflow_file_path: .github/workflows/release.yaml
    job_name: release
```

公式 README の「Disable policies」には 4 つしか載っていませんが、v1.6.0 のソースコード（[`pkg/config/config.go`](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/pkg/config/config.go)）と [013 の説明](https://github.com/suzuki-shunsuke/ghalint/blob/v1.6.0/docs/policies/013.md#how-to-ignore-the-violation)では、`checkout_persist_credentials_should_be_false` も無視できます。

## このリポジトリでの実行

| タイミング | 実行方法 | 対象 |
| --- | --- | --- |
| 手動 | `ghalint run` / `ghalint run-action` | 全ワークフロー / 全 `action.yml` |
| コミット前 | lefthook の pre-commit（`lefthook.yml`） | 全ワークフロー（ワークフローか ghalint の設定ファイルをステージしたとき）、全 `action.yml`（`action.yml` か ghalint の設定ファイルをステージしたとき） |
| CI | `.github/workflows/run_github_actions_lint.yaml` | 全ワークフローと全 `action.yml`（ワークフロー、`action.yml`、各ツールの設定ファイル、`mise.toml` のいずれかが変わった PR と `main` への push） |

`ghalint run-action` がチェックするのは、リポジトリのルートから 3 階層下までにある `action.yml` / `action.yaml`（例：`foo/bar/baz/action.yml`）です。それより深い場所に置いた `action.yml` はチェックされません。

ghalint は、どの実行方法でも `mise.toml` で固定したバージョンを使います。このリポジトリには今のところ ghalint の設定ファイルはなく、すべてのポリシーをそのまま適用しています。
