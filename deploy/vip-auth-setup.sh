#!/usr/bin/env bash
# 在 VPS 上为 /vip/ 配置 HTTP Basic Auth（写入 /etc/caddy/vip.conf 并 reload），支持多账号。
# 本机执行（用户名密码成对传入）：
#   ssh aliyun "bash -s -- vip <pass> bluewave <pass>" < deploy/vip-auth-setup.sh
# 密码位置留空（传 ""）则随机生成并打印一次；不传参数则默认生成 vip 账号。
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "请用 root 运行" >&2
    exit 2
fi

args=("$@")
if (( ${#args[@]} == 0 )); then
    args=(vip "")
fi
if (( ${#args[@]} % 2 == 1 )); then
    args+=("")
fi

cred_lines=()
generated_report=""
for ((i = 0; i < ${#args[@]}; i += 2)); do
    u="${args[i]}"
    p="${args[i + 1]}"
    if [[ -z $p ]]; then
        p=$(openssl rand -base64 12 | tr '+/' 'Aa')
        generated_report+="  ${u} : ${p}"$'\n'
    fi
    h=$(caddy hash-password --plaintext "$p")
    cred_lines+=("	${u} ${h}")
done

{
    echo "# VIP 区访问控制（由 deploy/vip-auth-setup.sh 生成；重新运行脚本即可更换口令）"
    echo "# 注意：Caddy 2.6.x 指令名为 basicauth；2.7+ 改名 basic_auth（旧名仍兼容）"
    echo "@vip path /vip /vip/*"
    echo "basicauth @vip {"
    printf '%s\n' "${cred_lines[@]}"
    echo "}"
} > /etc/caddy/vip.conf

caddy fmt --overwrite /etc/caddy/vip.conf >/dev/null 2>&1 || true
systemctl reload caddy 2>/dev/null || systemctl restart caddy

echo "---- VIP 已更新，当前账号: ${args[0]} 等 $((${#args[@]} / 2)) 个 ----"
if [[ -n $generated_report ]]; then
    echo "随机生成的密码（仅显示这一次，请立即保存）："
    printf '%s' "$generated_report"
fi
