#!/bin/bash
# launchd 登録スクリプト（macOS用定期実行）
# 用途: 定期的なGitHub巡回タスクを launchd に登録する
#
# 使い方:
#   bash scripts/setup_launchd.sh install    # launchd に登録
#   bash scripts/setup_launchd.sh uninstall  # launchd から削除
#   bash scripts/setup_launchd.sh status     # 登録状況確認

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LABEL="com.user.claude_github_bridge"
PLIST_SRC="$SCRIPT_DIR/${LABEL}.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

case "${1:-}" in
  install)
    if [ ! -f "$PLIST_SRC" ]; then
      echo "エラー: $PLIST_SRC が見つかりません。先に plist ファイルを作成してください。"
      exit 1
    fi
    cp "$PLIST_SRC" "$PLIST_DEST"
    launchctl load "$PLIST_DEST"
    echo "登録完了: $LABEL"
    echo "次回実行確認: launchctl list | grep $LABEL"
    ;;
  uninstall)
    if launchctl list "$LABEL" &>/dev/null; then
      launchctl unload "$PLIST_DEST"
      rm -f "$PLIST_DEST"
      echo "削除完了: $LABEL"
    else
      echo "登録されていません: $LABEL"
    fi
    ;;
  status)
    if launchctl list "$LABEL" &>/dev/null; then
      echo "登録済み:"
      launchctl list "$LABEL"
    else
      echo "未登録"
    fi
    ;;
  *)
    echo "使い方: $0 install | uninstall | status"
    exit 1
    ;;
esac
