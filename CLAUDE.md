# CLAUDE.md — claude_github_bridge

## プロジェクト概要
`claude` CLI と GitHub CLI (`gh`) を組み合わせた試験的な統合プロジェクト。
GitHub の Issue / PR の内容を Claude（クラウド）に渡して処理し、結果を GitHub に書き戻す。

## 仕組み
```
run_github_task.sh
  └── gh コマンドで GitHub からデータ取得
  └── echo prompt | claude --print でClaudeクラウドへ送信
       └── Claude が gh コマンドを使って GitHub にコメント投稿
```

## 前提ツール
- `claude` CLI: `~/.local/bin/claude`（Claude Code CLIのバイナリ）
- `gh` CLI: GitHub CLI（`brew install gh` でインストール）
- 認証済みであること:
  - `gh auth login` で GitHub 認証
  - Claude Code は起動時に Anthropic 認証済み

## ディレクトリ構成
```
claude_github_bridge/
├── CLAUDE.md
├── README.md
├── PLAN.md
├── .env                  # GITHUB_REPO のデフォルト値（任意）
├── .env.example
├── .gitignore
└── scripts/
    ├── run_github_task.sh              # メイン実行スクリプト
    ├── setup_launchd.sh                # launchd 登録/削除
    ├── com.user.claude_github_bridge.plist  # launchd 設定
    └── logs/                           # 実行ログ
```

## 環境変数（.envに定義、任意）
```
GITHUB_REPO=owner/repo_name   # デフォルトリポジトリ（--repo 省略時に使用）
```

## 注意事項
- `--post` フラグを付けると実際に GitHub にコメントを投稿する。本番リポジトリで使う際は注意
- Claude の budget（`--max-budget-usd`）は小さめに設定しておくこと
- `gh` コマンドが Claude に渡る allowedTools に含まれていないため、Claude は Bash 経由で実行する
