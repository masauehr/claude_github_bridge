# PLAN.md — 実装計画

## フェーズ1: 基盤構築（最初のマイルストーン）

### 1-1. 環境セットアップ
- [ ] `requirements.txt` 作成（anthropic, PyGithub, python-dotenv）
- [ ] `.env.example` 作成
- [ ] `.gitignore` 作成

### 1-2. Claude APIクライアント（`src/claude_client.py`）
- [ ] `anthropic` SDKを使った基本的なメッセージ送受信
- [ ] システムプロンプトのテンプレート管理
- [ ] エラーハンドリング

### 1-3. GitHub APIクライアント（`src/github_client.py`）
- [ ] Issue取得・コメント投稿
- [ ] PR差分取得・レビュー投稿
- [ ] ファイル読み取り・コミット

### 1-4. ブリッジロジック（`src/bridge.py`）
- [ ] GitHubデータ → Claude入力フォーマット変換
- [ ] Claude出力 → GitHub書き込み処理

---

## フェーズ2: ユースケース実装

### 2-1. Issue要約（`examples/summarize_issue.py`）
- [ ] Issue本文 + コメント履歴をClaudeに渡す
- [ ] 要約結果をIssueコメントとして投稿

### 2-2. PRコードレビュー（`examples/review_pr.py`）
- [ ] PR差分（unified diff）をClaudeに渡す
- [ ] レビューコメントをPRに投稿

---

## フェーズ3: 応用・自動化（将来検討）

- [ ] GitHub Actionsとの連携（Webhook or workflow）
- [ ] 複数Issueのバッチ処理
- [ ] ラベル自動分類
- [ ] リリースノート自動生成

---

## 技術メモ

### Claude APIの基本パターン
```python
import anthropic

client = anthropic.Anthropic()
message = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "ここにGitHubのデータを渡す"}]
)
print(message.content[0].text)
```

### GitHub APIの基本パターン
```python
from github import Github

g = Github(token)
repo = g.get_repo("owner/repo")
issue = repo.get_issue(number=123)
issue.create_comment("Claudeの出力結果")
```
