# gha-linter-poc

GitHub Actions のワークフロー（`.github/workflows/*.yml`）とアクション（`action.yml`）をチェックするリンターを試すための PoC です。次の 4 つのツールを、ローカルでは Git の pre-commit フック、リモートでは CI で実行します。

| ツール | 主な役割 | ルール一覧 |
| --- | --- | --- |
| [actionlint](https://github.com/rhysd/actionlint) | 構文・式・型などの静的チェック（`run:` は ShellCheck でチェック） | [docs/actionlint-rules.md](docs/actionlint-rules.md) |
| [ghalint](https://github.com/suzuki-shunsuke/ghalint) | セキュリティのベストプラクティスに沿っているかのチェック | [docs/ghalint-rules.md](docs/ghalint-rules.md) |
| [ghasec](https://github.com/koki-develop/ghasec) | セキュリティ上の問題の検出 | [docs/ghasec-rules.md](docs/ghasec-rules.md) |
| [zizmor](https://github.com/zizmorcore/zizmor) | セキュリティ上の問題の検出（Dependabot・pre-commit の設定も対象） | [docs/zizmor-rules.md](docs/zizmor-rules.md) |

各ツールのバージョンは [`mise.toml`](mise.toml) で固定しています。

## workflow lockfile

ワークフローで使うアクションは、GitHub の [workflow lockfile](https://docs.github.com/actions/concepts/security/workflow-dependency-lockfiles)（[`.github/workflows/actions.lock`](.github/workflows/actions.lock)）でコミットに固定しています。`uses:` はタグ（例: `actions/checkout@v7.0.1`）で書き、実行時には lockfile に記録されたコミットが使われます。lockfile は GitHub CLI の拡張 [gh actions-lock](https://github.com/github/gh-actions-lock) で作ります。

```bash
gh actions-lock             # uses: を追加・変更したら実行して、lockfile も一緒にコミットする
gh actions-lock --verify    # 書き込まずに、lockfile が最新で正しいかを確かめる
```

- アクションの更新は [Dependabot](.github/dependabot.yml) が行い、lockfile も同じ PR で更新されます。
- ghalint と zizmor は lockfile を読むので、タグで書いた `uses:` を指摘しません。ghasec は lockfile に対応していないため、各 `uses:` に `# ghasec-ignore: unpinned-action` を付けています。

## セットアップ

[devcontainer](.devcontainer/github-actions/devcontainer.json) を使います。コンテナを作ると、`mise install` で `mise.toml` のツールが入り、`lefthook install` で Git フックが設定されます。

必要なツールが揃っているかは次のコマンドで確認できます。

```bash
task environment:check
```

devcontainer を使わない場合は、[mise](https://mise.jdx.dev/) を入れたうえで次を実行してください。

```bash
mise install
gh extension install github/gh-actions-lock --pin v0.4.1
lefthook install
```

## 使い方

### pre-commit フック

ワークフローやアクションなど、各ツールが読むファイルをコミットすると [lefthook](lefthook.yml) が 4 つのツールと `gh actions-lock --verify-local`（すべての `uses:` が lockfile に載っているかのオフラインチェック）を実行します。手動で実行するには次のようにします。

```bash
lefthook run pre-commit
```

ツールを個別に実行することもできます。

```bash
actionlint
ghalint run          # ワークフロー
ghalint run-action   # アクション
zizmor --offline .
ghasec
```

ローカルでは GitHub のトークンやネットワークがなくても動くよう、zizmor と ghasec をオフラインで実行します。GitHub API を使うルール（zizmor の `impostor-commit`、ghasec のオンラインルールなど）は CI でだけ実行されます。

### CI

| ワークフロー | 内容 |
| --- | --- |
| [run_github_actions_lint](.github/workflows/run_github_actions_lint.yaml) | 4 つのツールと `gh actions-lock --verify` を別々のジョブで実行し、結果を PR のアノテーションとして表示します。zizmor と ghasec はオンラインのルールも有効にします |
| [run_devcontainer_ci](.github/workflows/run_devcontainer_ci.yaml) | devcontainer を build し、`task environment:check` が通るか確認します |

どちらも PR と `main` への push で、関係するファイルが変わったときに実行されます。

## ツールのバージョンを上げるとき

`mise.toml` のバージョンを上げたときは、次も確認してください。

- 対応する `docs/<ツール名>-rules.md`（ルール一覧は固定したバージョンの公式ドキュメントをもとにしています）
- actionlint の場合は [`.github/actionlint-matcher.json`](.github/actionlint-matcher.json)（actionlint 本家の同じバージョンからコピーしています）

gh actions-lock は mise で管理できないため、[postCreateCommand.sh](.devcontainer/github-actions/postCreateCommand.sh) と [run_github_actions_lint.yaml](.github/workflows/run_github_actions_lint.yaml) の `--pin` でバージョンを揃えてください。

mise 本体のバージョンは、[devcontainer.json](.devcontainer/github-actions/devcontainer.json) と [run_github_actions_lint.yaml](.github/workflows/run_github_actions_lint.yaml) の各ジョブで揃えてください。
