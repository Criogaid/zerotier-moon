#!/bin/bash

# 通知脚本
# 用法: ./notify.sh <状态> <消息> <Webhook URL (可选)>

STATUS=$1
MESSAGE=$2
WEBHOOK_URL=${3:-""}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 根据状态设置颜色和图标
case $STATUS in
  "success")
    COLOR=$GREEN
    ICON="✅"
    ;;
  "failure")
    COLOR=$RED
    ICON="❌"
    ;;
  "warning")
    COLOR=$YELLOW
    ICON="⚠️"
    ;;
  *)
    COLOR=$NC
    ICON="ℹ️"
    ;;
esac

# 打印带颜色的消息
echo -e "${COLOR}${ICON} ${MESSAGE}${NC}"

# 如果提供了Webhook URL，发送通知
if [ -n "$WEBHOOK_URL" ]; then
  # 根据状态设置颜色（适配Slack）
  case $STATUS in
    "success")
      COLOR="good"
      ;;
    "failure")
      COLOR="danger"
      ;;
    "warning")
      COLOR="warning"
      ;;
    *)
      COLOR="#999999"
      ;;
  esac
  
  # 构建JSON负载
  PAYLOAD=$(cat <<EOF
{
  "text": "${ICON} ZeroTier Moon Docker Image Build",
  "attachments": [
    {
      "color": "${COLOR}",
      "fields": [
        {
          "title": "Status",
          "value": "${STATUS}",
          "short": true
        },
        {
          "title": "Message",
          "value": "${MESSAGE}",
          "short": false
        },
        {
          "title": "Time",
          "value": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
          "short": true
        },
        {
          "title": "Repository",
          "value": "${GITHUB_REPOSITORY:-"Unknown"}",
          "short": true
        }
      ]
    }
  ]
}
EOF
)

  # 发送HTTP请求
  curl -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$WEBHOOK_URL"
fi