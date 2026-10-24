#!/usr/bin/env bash
# 本地构建并发布博客到 VPS。
# 用法: bash deploy/deploy.sh [ssh别名或主机]
# 默认使用 ~/.ssh/config 中的 aliyun 别名（见 mifi-nat 仓库《SSH接入与多机同步指南》）。
set -euo pipefail

REMOTE="${1:-aliyun}"
WEB_ROOT="${WEB_ROOT:-/var/www/blog}"

cd "$(dirname "$0")/.."

if ! command -v hugo >/dev/null 2>&1; then
    echo "未找到 hugo 命令。安装: winget install Hugo.Hugo.Extended" >&2
    exit 1
fi

hugo --gc --minify

ssh "$REMOTE" "mkdir -p '$WEB_ROOT'"
if command -v rsync >/dev/null 2>&1; then
    rsync -avz --delete public/ "$REMOTE:$WEB_ROOT/"
else
    # Git Bash 自带环境通常没有 rsync，退化为 tar over ssh 全量替换
    ssh "$REMOTE" "rm -rf '$WEB_ROOT' && mkdir -p '$WEB_ROOT'"
    tar -C public -czf - . | ssh "$REMOTE" "tar -xzf - -C '$WEB_ROOT'"
fi

echo "已发布: http://123.56.217.104/"
