#!/usr/bin/env bash
# 在 VPS 上执行一次（服务器侧初始化，不影响已有 WireGuard hub 与 demo 服务）：
#   ssh aliyun "bash -s" < deploy/server-setup.sh
# 自包含：Caddyfile 内嵌于脚本，不依赖上传其他文件。
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "请用 root 运行" >&2
    exit 2
fi

apt-get update
if ! apt-get install -y caddy; then
    echo "系统源没有 caddy，改用 Cloudsmith 源安装" >&2
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        | tee /etc/apt/sources.list.d/caddy-stable.list
    apt-get update && apt-get install -y caddy
fi

install -d -m 755 /var/www/blog

if [[ -f /etc/caddy/Caddyfile ]]; then
    cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%Y%m%d%H%M%S)"
fi

cat > /etc/caddy/Caddyfile <<'CADDYFILE'
# 博客站点（IP 直访阶段）。
# 备案后绑域名：把 :80 改成你的域名，Caddy 会自动签发并续期 HTTPS 证书。
:80 {
	root * /var/www/blog
	file_server
	encode zstd gzip
}
CADDYFILE

systemctl enable --now caddy >/dev/null 2>&1 || true
systemctl reload caddy 2>/dev/null || systemctl restart caddy

echo "---- 完成。检查监听: ss -ltnp | grep -E ':80\b'"
echo "---- 若服务器本机可访问但外网不通，需在阿里云轻量控制台放行 TCP 80："
echo "----   控制台 → 防火墙 → 添加规则 TCP 80"
echo "----   或: aliyun swas-open CreateFirewallRule --RegionId cn-beijing --InstanceId <实例ID> --RuleProtocol TCP --Port 80"
