# claude_github_bridge

Claude Code の **Remote Trigger** 機能を使って何ができるかを検証する実験的プロジェクト。
`claude` CLI と `gh` CLI を組み合わせ、GitHub データを Claude（クラウド）で処理する。

> **ステータス**: 実験完了（2026-03-26）
> 検証結果は [EXPERIMENT_REPORT.md](./EXPERIMENT_REPORT.md) を参照。

## 仕組み

```
Remote Trigger（クラウド上のClaude）
  → Bash ツールで curl / gh コマンドを実行
  → api.github.com からデータ取得・書き込み
  → 結果をターミナルに出力 or GitHub に保存
```

## わかったこと（実験結果サマリー）

Remote Trigger 環境（Anthropic クラウド・海外DC）から外部APIにアクセスした結果:

| サービス | 結果 |
|----------|------|
| `api.github.com` | ✅ 成功 |
| Yahoo Finance | ❌ タイムアウト |
| stooq.com | ❌ ネットワークエラー |
| 気象庁 (jma.go.jp) | ❌ 403（国内IPのみ許可） |

**→ GitHub API のみ安定利用可能。** 詳細は [EXPERIMENT_REPORT.md](./EXPERIMENT_REPORT.md) を参照。

## スクリプト

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

## 前提条件

```bash
# GitHub CLI インストール・認証
brew install gh
gh auth login

# Claude Code CLI が ~/.local/bin/claude にある
claude --version
```

## 定期実行のセットアップ（macOS launchd）

1. `scripts/com.user.claude_github_bridge.plist` を編集して対象リポジトリ・実行スケジュールを設定
2. 登録:

```bash
bash scripts/setup_launchd.sh install
```

## ファイル構成

```
claude_github_bridge/
├── README.md
├── CLAUDE.md                 # プロジェクト設定
├── PLAN.md                   # 当初の実装計画
├── EXPERIMENT_REPORT.md      # 実験レポート（外部API接続検証）
├── .env.example
└── scripts/
    ├── run_github_task.sh    # メイン実行スクリプト
    ├── setup_launchd.sh      # launchd 登録/削除
    └── com.user.claude_github_bridge.plist
```

## ログ

実行ログは `scripts/logs/YYYY-MM-DD_github_task.log` に出力される。
