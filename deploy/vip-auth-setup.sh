#!/usr/bin/env bash
# 在 VPS 上为 /vip/ 配置 HTTP Basic Auth（写入 /etc/caddy/vip.conf 并 reload）。
# 本机执行：
#   ssh aliyun "bash -s -- <user> <password>" < deploy/vip-auth-setup.sh
#   user 缺省 vip；password 缺省则随机生成并打印（只打印这一次，请自行保存）。
set -euo pipefail

VIP_USER="${1:-vip}"
VIP_PASS="${2:-}"
if [[ -z $VIP_PASS ]]; then
    VIP_PASS=$(openssl rand -base64 12 | tr '+/' 'Aa')
fi

if [[ $(id -u) -ne 0 ]]; then
    echo "请用 root 运行" >&2
    exit 2
fi

HASH=$(caddy hash-password --plaintext "$VIP_PASS")

cat > /etc/caddy/vip.conf <<EOF
# VIP 区访问控制（由 deploy/vip-auth-setup.sh 生成；重新运行脚本即可更换口令）
# 注意：Caddy 2.6.x 指令名为 basicauth；2.7+ 改名 basic_auth（旧名仍兼容）
@vip path /vip /vip/*
basicauth @vip {
	$VIP_USER $HASH
}
EOF

caddy fmt --overwrite /etc/caddy/vip.conf >/dev/null 2>&1 || true
systemctl reload caddy 2>/dev/null || systemctl restart caddy

echo "---- VIP 已启用 ----"
echo "  用户名: $VIP_USER"
echo "  密  码: $VIP_PASS"
echo "  验证: curl -o /dev/null -w '%{http_code}' http://<host>/vip/   # 应为 401"
