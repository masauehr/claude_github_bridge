#!/bin/bash
# GitHub × Claude 連携スクリプト
# 用途: GitHub の Issue / PR の内容を Claude に渡し、結果を GitHub に書き戻す。
#
# 使い方:
#   Issue要約:   bash scripts/run_github_task.sh summarize-issue  --repo owner/repo --issue 123
#   PRレビュー:  bash scripts/run_github_task.sh review-pr        --repo owner/repo --pr 456
#   Issue要約+投稿: bash scripts/run_github_task.sh summarize-issue --repo owner/repo --issue 123 --post
#   PRレビュー+投稿: bash scripts/run_github_task.sh review-pr    --repo owner/repo --pr 456 --post

set -euo pipefail

# ── パス設定 ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$SCRIPT_DIR/logs"
PROMPTS_DIR="$PROJECT_DIR/prompts"
CLAUDE_BIN="${HOME}/.local/bin/claude"
TODAY=$(date '+%Y-%m-%d')
LOG_FILE="$LOG_DIR/${TODAY}_github_task.log"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Claude CLI 実行
run_claude() {
  local budget="$1"
  local prompt="$2"
  echo "$prompt" | "$CLAUDE_BIN" \
    --print \
    --dangerously-skip-permissions \
    --model sonnet \
    --max-budget-usd "$budget" \
    --allowedTools "Bash,Read,Write,Edit,WebFetch,WebSearch,Glob,Grep" \
    --input-format text \
    2>&1 | tee -a "$LOG_FILE"
  return ${PIPESTATUS[0]}
}

# ── 引数パース ─────────────────────────────────────────────
TASK="${1:-}"
shift || true

REPO=""
ISSUE_NUM=""
PR_NUM=""
POST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  REPO="$2";      shift 2 ;;
    --issue) ISSUE_NUM="$2"; shift 2 ;;
    --pr)    PR_NUM="$2";    shift 2 ;;
    --post)  POST=true;      shift   ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
done

# .env 読み込み
if [ -f "$PROJECT_DIR/.env" ]; then
  set -o allexport
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +o allexport
fi

REPO="${REPO:-${GITHUB_REPO:-}}"
if [ -z "$REPO" ]; then
  echo "エラー: --repo または .env の GITHUB_REPO を指定してください"
  exit 1
fi

# ── タスク分岐 ─────────────────────────────────────────────
case "$TASK" in

  # ----------------------------------------------------------------
  # Issue 要約
  # ----------------------------------------------------------------
  summarize-issue)
    if [ -z "$ISSUE_NUM" ]; then
      echo "エラー: --issue を指定してください"
      exit 1
    fi

    log "=== Issue #${ISSUE_NUM} 要約開始 (repo: ${REPO}) ==="

    POST_INSTRUCTION=""
    if [ "$POST" = true ]; then
      POST_INSTRUCTION="
5. 要約が完成したら、以下のコマンドでIssueにコメントとして投稿すること:
   gh issue comment ${ISSUE_NUM} --repo ${REPO} --body '## Claude による要約\n\n{要約内容}\n\n---\n*この要約はClaude AIによって自動生成されました*'"
    fi

    PROMPT="今日は${TODAY}です。GitHub の Issue を要約してください。

【手順】
1. 以下のコマンドでIssueの内容を取得する:
   gh issue view ${ISSUE_NUM} --repo ${REPO} --comments
2. Issue本文・コメント履歴を読み込む
3. 以下の形式で日本語の要約を作成する:
   - 問題/目的の概要（2〜3文）
   - 主な議論のポイント（箇条書き）
   - 現在の状態と結論（あれば）
4. 要約をターミナルに出力する${POST_INSTRUCTION}

【注意】
- 要約は簡潔に（全体で300字以内を目安）
- コードや技術用語はそのまま使用してよい"

    run_claude "0.50" "$PROMPT"
    log "=== 完了 ==="
    ;;

  # ----------------------------------------------------------------
  # PR レビュー
  # ----------------------------------------------------------------
  review-pr)
    if [ -z "$PR_NUM" ]; then
      echo "エラー: --pr を指定してください"
      exit 1
    fi

    log "=== PR #${PR_NUM} レビュー開始 (repo: ${REPO}) ==="

    POST_INSTRUCTION=""
    if [ "$POST" = true ]; then
      POST_INSTRUCTION="
5. レビューが完成したら、以下のコマンドでPRにコメントとして投稿すること:
   gh pr comment ${PR_NUM} --repo ${REPO} --body '{レビュー内容}\n\n---\n*このレビューはClaude AIによって自動生成されました*'"
    fi

    PROMPT="今日は${TODAY}です。GitHub の Pull Request をコードレビューしてください。

【手順】
1. 以下のコマンドでPRの情報を取得する:
   gh pr view ${PR_NUM} --repo ${REPO}
2. 以下のコマンドで差分を取得する:
   gh pr diff ${PR_NUM} --repo ${REPO}
3. 以下の観点でレビューを行い、マークダウン形式で出力する:
   ## 概要
   （PRの目的と変更内容を1〜2文で）

   ## 良い点
   （コードの優れている点）

   ## 問題点・改善提案
   （バグリスク、可読性、パフォーマンス等。該当ファイル名と行番号を可能な限り明示）

   ## その他コメント
   （マイナーな提案や質問）
4. レビューをターミナルに出力する${POST_INSTRUCTION}

【注意】
- 建設的で具体的なレビューを行う
- 問題がない場合は「特に問題なし」と明記する"

    run_claude "0.80" "$PROMPT"
    log "=== 完了 ==="
    ;;

  *)
    echo "使い方:"
    echo "  $0 summarize-issue --repo owner/repo --issue 123 [--post]"
    echo "  $0 review-pr       --repo owner/repo --pr 456    [--post]"
    exit 1
    ;;

esac
