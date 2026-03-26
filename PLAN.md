# PLAN.md — 実装計画

> **注記**: このプロジェクトは2026-03-26に実験完了。
> 実際に検証した内容は [EXPERIMENT_REPORT.md](./EXPERIMENT_REPORT.md) を参照。

---

## 当初の計画

### フェーズ1: 基盤構築

- Claude Code CLI + gh CLI を組み合わせた連携スクリプト → **実装済み** (`scripts/run_github_task.sh`)
- Remote Trigger による定期実行 → **実装・検証済み**

### フェーズ2: ユースケース実装

#### Issue要約・PRレビュー
- `run_github_task.sh summarize-issue` → **実装済み**
- `run_github_task.sh review-pr` → **実装済み**

#### 外部データ取得（週次レポート）
- 日経平均データ（Yahoo Finance / stooq.com） → **❌ Remote Trigger環境から接続不可**
- 気象庁天気予報 → **❌ IPジオブロッキングにより接続不可**
- GitHub Search API → **✅ 成功**

### フェーズ3: 応用・自動化（今後の参考）

Remote Trigger 環境では `api.github.com` のみ安定利用可能なため、
以下は GitHub API の範囲内で実現可能:

- Issue / PR の自動要約・レビュー投稿（`GITHUB_TOKEN` 設定が必要）
- GitHub Search API を使ったトレンドレポート生成
- リポジトリ統計の定期レポート

日本国内データ（気象・金融）を使う場合は、macOS launchd やローカル実行が現実的。

---

## 技術メモ

### Remote Trigger の制約（検証済み）

- 利用可能ツール: `Bash`, `Read`, `Glob`, `Grep`
- `jq` コマンドは存在しない → Python で代替可能
- 外部アクセス: `api.github.com` のみ安定。日本国内向けAPIはIPブロックされる

### Claude CLI 実行パターン

```bash
echo "$PROMPT" | ~/.local/bin/claude \
  --print \
  --dangerously-skip-permissions \
  --model sonnet \
  --max-budget-usd 0.50 \
  --allowedTools "Bash,Read,Write,Edit,WebFetch,WebSearch,Glob,Grep" \
  --input-format text
```

### GitHub API（認証なし・読み取り）

```bash
# リポジトリ情報
curl -s "https://api.github.com/repos/owner/repo"

# Issue一覧
curl -s "https://api.github.com/repos/owner/repo/issues?state=open"

# Search API
curl -s "https://api.github.com/search/repositories?q=claude&sort=stars"
```

### GitHub API（書き込み・GITHUB_TOKEN 必要）

```bash
curl -s -X PUT "https://api.github.com/repos/owner/repo/contents/path/to/file" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "コミットメッセージ", "content": "<base64>"}'
```
