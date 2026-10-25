#!/usr/bin/env bash
# 本地构建并发布博客到 VPS。
# 用法: bash deploy/deploy.sh [ssh别名或主机]
# 默认使用 ~/.ssh/config 中的 aliyun 别名（见 mifi-nat 仓库《SSH接入与多机同步指南》）。
#
# 私密配置（VPS 地址等）放在 deploy/local.env，已 gitignore、不入库：
#   BLOG_URL=http://x.x.x.x/    # 构建用 baseURL，影响 RSS 与搜索索引链接
#   WEB_ROOT=/var/www/blog      # 服务器上的站点目录
#   REMOTE=aliyun               # ssh 别名或主机，也可用命令行第一个参数覆盖
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$script_dir/local.env" ]]; then
    . "$script_dir/local.env"
fi

REMOTE="${1:-${REMOTE:-aliyun}}"
WEB_ROOT="${WEB_ROOT:-/var/www/blog}"
BLOG_URL="${BLOG_URL:-http://localhost:1313/}"

cd "$script_dir/.."

# 防误删保护：vip-content 缺失时全量替换会把服务器上的 VIP 页面一起删掉
if [[ ! -d vip-content ]] || [[ -z $(ls -A vip-content 2>/dev/null) ]]; then
    echo "错误: vip-content/ 缺失或为空，本次部署中止（防止清空线上 VIP 区）。" >&2
    echo "  新机器请先按 VIP-GUIDE.md 恢复 vip-content/；确认要无 VIP 部署请设 FORCE_NO_VIP=1" >&2
    if [[ ${FORCE_NO_VIP:-0} != 1 ]]; then
        exit 1
    fi
    echo "  FORCE_NO_VIP=1：继续无 VIP 部署" >&2
fi

if ! command -v hugo >/dev/null 2>&1; then
    echo "未找到 hugo 命令。安装: winget install Hugo.Hugo.Extended" >&2
    exit 1
fi

hugo --gc --minify --baseURL "$BLOG_URL"

ssh "$REMOTE" "mkdir -p '$WEB_ROOT'"
if command -v rsync >/dev/null 2>&1; then
    rsync -avz --delete public/ "$REMOTE:$WEB_ROOT/"
else
    # Git Bash 自带环境通常没有 rsync，退化为 tar over ssh 全量替换
    ssh "$REMOTE" "rm -rf '$WEB_ROOT' && mkdir -p '$WEB_ROOT'"
    tar -C public -czf - . | ssh "$REMOTE" "tar -xzf - -C '$WEB_ROOT'"
fi

echo "已发布到 $REMOTE:$WEB_ROOT"
