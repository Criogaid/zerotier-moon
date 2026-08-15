#!/bin/bash
set -e

# 用法: ./notify.sh <状态> <消息> <Webhook URL (可选)>

if [ "$#" -lt 2 ]; then
  echo "用法: $0 <状态> <消息> <Webhook URL (可选)>" >&2
  exit 2
fi

STATUS=$1
MESSAGE=$2
WEBHOOK_URL=${3:-}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

case $STATUS in
  success)
    TERMINAL_COLOR=$GREEN
    WEBHOOK_COLOR=good
    ICON="✅"
    ;;
  failure)
    TERMINAL_COLOR=$RED
    WEBHOOK_COLOR=danger
    ICON="❌"
    ;;
  warning)
    TERMINAL_COLOR=$YELLOW
    WEBHOOK_COLOR=warning
    ICON="⚠️"
    ;;
  *)
    TERMINAL_COLOR=$NC
    WEBHOOK_COLOR='#999999'
    ICON="ℹ️"
    ;;
esac

printf '%b\n' "${TERMINAL_COLOR}${ICON} ${MESSAGE}${NC}"

if [ -n "$WEBHOOK_URL" ]; then
  PAYLOAD=$(jq -n \
    --arg text "$ICON ZeroTier Moon Docker Image Build" \
    --arg color "$WEBHOOK_COLOR" \
    --arg status "$STATUS" \
    --arg message "$MESSAGE" \
    --arg time "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" \
    --arg repository "${GITHUB_REPOSITORY:-Unknown}" \
    '{
      text: $text,
      attachments: [{
        color: $color,
        fields: [
          {title: "Status", value: $status, short: true},
          {title: "Message", value: $message, short: false},
          {title: "Time", value: $time, short: true},
          {title: "Repository", value: $repository, short: true}
        ]
      }]
    }')

  curl --fail-with-body --location --retry 3 --retry-all-errors \
    --connect-timeout 5 --max-time 20 --show-error --silent \
    -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" "$WEBHOOK_URL"
fi