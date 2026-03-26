# claude_github_bridge

`claude` CLI と `gh` CLI を使って GitHub データを Claude（クラウド）で処理する試験的プロジェクト。

## 仕組み

```
シェルスクリプト
  → gh コマンドで GitHub からデータ取得
  → echo prompt | claude --print でプロンプトをClaudeクラウドへ
  → Claude が gh コマンドを呼び出して GitHub にコメント投稿
```

## 前提条件

```bash
# GitHub CLI インストール・認証
brew install gh
gh auth login

# Claude Code CLI が ~/.local/bin/claude にある
claude --version
```

## 使い方

```bash
# Issue を要約して表示
bash scripts/run_github_task.sh summarize-issue --repo owner/repo --issue 123

# Issue を要約して GitHub にコメント投稿
bash scripts/run_github_task.sh summarize-issue --repo owner/repo --issue 123 --post

# PR をレビューして表示
bash scripts/run_github_task.sh review-pr --repo owner/repo --pr 456

# PR をレビューして GitHub にコメント投稿
bash scripts/run_github_task.sh review-pr --repo owner/repo --pr 456 --post
```

## 定期実行のセットアップ（macOS launchd）

1. `scripts/com.user.claude_github_bridge.plist` を編集して対象リポジトリ・実行スケジュールを設定
2. 登録:

```bash
bash scripts/setup_launchd.sh install
```

## ログ

実行ログは `scripts/logs/YYYY-MM-DD_github_task.log` に出力される。
