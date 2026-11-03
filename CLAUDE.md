# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリについて

GitHub Actions のワークフロー・アクション向けリンター（actionlint / ghalint / ghasec / zizmor）を検証する PoC。アプリケーションコードはなく、中身は「リンターの実行設定（lefthook・CI）」「ツールのバージョン固定（mise）」「開発用 devcontainer」「各リンターのルール解説（`docs/`）」で構成される。

## よく使うコマンド

ツールはすべて `mise.toml` でバージョン固定しており、`mise install` で入る（devcontainer では `postCreateCommand.sh` が `mise install` と `lefthook install` を実行する）。

```bash
task                        # タスク一覧
task environment:check      # 必要なツールが揃っているか確認（devcontainer CI でも実行）

task lint                   # 全リンターを全ファイルに実行（lefthook run pre-commit --all-files）

# リンターを個別に実行（lefthook の pre-commit はこれらのタスクを呼ぶ）
task lint:actionlint        # actionlint
task lint:ghalint           # ghalint run（ワークフロー）
task lint:ghalint-action    # ghalint run-action（action.yml）
task lint:zizmor            # zizmor --offline .
task lint:ghasec            # ghasec
task lint:actions-lock      # gh actions-lock --verify-local（全 uses: が lockfile に載っているか。オフライン）

# workflow lockfile（.github/workflows/actions.lock）
gh actions-lock             # uses: を追加・変更したら実行して lockfile を更新
gh actions-lock --verify    # 書き込まずに検証（CI と同じ。ネットワークが必要）
```

- ローカル（lefthook）は zizmor・ghasec を**オフライン**で動かす。GitHub API を使うルール（zizmor の impostor-commit、ghasec の online ルールなど）は CI でのみ `--online` / トークン付きで実行される。
- actionlint・ghalint はファイル間の参照をチェックするため、ステージされたファイルだけでなく常に全ファイルを対象にする。

## 構成と同期が必要な箇所

複数ファイルに同じ情報が重複しており、変更時は揃える必要がある。

- **mise 本体のバージョン**: `.devcontainer/github-actions/devcontainer.json` の mise feature と、`.github/workflows/run_github_actions_lint.yaml` の各ジョブの `jdx/mise-action` の `version:`（全ジョブ分）。
- **gh actions-lock 拡張のバージョン**: gh の拡張は mise で管理できないため、`.devcontainer/github-actions/postCreateCommand.sh` と `run_github_actions_lint.yaml` の `gh extension install ... --pin` で揃える。
- **ツールのバージョン**（`mise.toml`）を上げたとき:
  - 対応する `docs/<tool>-rules.md` を見直す（各ドキュメントは固定バージョンの公式ドキュメントへのリンクと、その版のルール一覧を持つ）。
  - actionlint の場合、`.github/actionlint-matcher.json` は actionlint 本家の同バージョンからコピーしたもの。
- **`run_github_actions_lint.yaml` のトリガー `paths:`**: 各ツールが読む設定ファイルの和集合になっているので、ツール追加時はそのツールの設定ファイル名も追加する。`lefthook.yml` の各ジョブの `glob:` も同じ考え方で書かれている。
- **`run_devcontainer_ci.yaml` のトリガー `paths:`**: devcontainer を build して `task environment:check` を実行するので、`Taskfile.yml` にツールを追加したら `mise.toml` にも追加する。
- どちらのワークフローも `paths:` は `pull_request` 側に YAML アンカー（`&paths`）を付けて定義し、`push` 側はエイリアス（`*paths`）で参照している。リストは `pull_request` 側だけを編集すればよい。`lefthook.yml` の `glob:` も、複数ジョブで使うパターン（`*workflows`・`*actions` など）は最初に出てくる箇所でアンカーを付けて定義している。
- CI の各リンターは独立したジョブにしてあり、1 つが失敗しても他の結果が出る。ghasec の `shellcheck` ルールは PATH 上の shellcheck を使うため、CI では mise で固定版の shellcheck も入れている。

## ワークフローを書くときの規約

このリポジトリ自身のワークフローは上記リンターをすべて通す必要がある。既存ワークフローに倣うこと:

- トップレベルに `permissions: {}`、各ジョブで必要最小限の `permissions:` と `timeout-minutes:` を指定する。
- アクションは workflow lockfile（`.github/workflows/actions.lock`、GitHub 公式の `gh actions-lock` で生成。手で編集しない）でコミットに固定する。`uses:` は `actions/checkout@v7.0.1` のように完全なタグで書き、`gh actions-lock` を実行して lockfile も一緒にコミットする。
  - ghasec（v0.18.0）は lockfile 非対応のため、各 `uses:` の行末に `# ghasec-ignore: unpinned-action` を付ける。ghalint と zizmor（v1.32.0 以降）は lockfile を読むので設定不要。
  - 他リポジトリの reusable workflow（`jobs.<id>.uses`）、`action.yml` 内のアクション、コンテナイメージは lockfile で固定されないので、従来どおり SHA やダイジェストで固定する。
- `actions/checkout` には `persist-credentials: false` を付ける。
- `run:` 内で `${{ }}` を直接展開せず、`env:` 経由で渡す。
- `defaults.run.shell: bash` と `concurrency`（`cancel-in-progress: true`）を設定する。

## devcontainer

`.devcontainer/github-actions/` が唯一の devcontainer。`initializeCommand.sh` がホストのユーザー情報から `.devcontainer/.env`（git 管理外）を生成し、`compose.yml` がそれを build 引数に使う。`/misc` はボリュームで、Claude Code・gh・herdr の設定を保持する。

## ドキュメント・コミット

- `docs/` とコミットメッセージは日本語。コミットは `feat:` / `fix:` / `docs:` / `refactor:` などの Conventional Commits 形式。
