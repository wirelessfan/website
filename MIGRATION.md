# 服务器迁移手册（Aliyun → 新服务器）

> 目标：换服务器时 30 分钟内完成博客栈重建，不丢任何状态。本文按"状态在哪、怎么搬、怎么验"组织。
> 原则：**所有博客内容与配置都在 git 里**（公开仓 + VIP 私有仓），服务器只是一台无状态渲染机——这是整个迁移方案的地基。

## 0. 迁移面总览（先看这个）

| 状态/组件 | 在哪 | 迁移动作 |
|---|---|---|
| 博客内容+构建 | GitHub 双仓 | **无需迁移**（新服务器部署即得） |
| Caddy 配置 | 仓库 `deploy/server-setup.sh` | 新服务器重跑脚本 |
| VIP 认证 | 仓库 `deploy/vip-auth-setup.sh` | 重跑脚本（口令可沿用或换新） |
| SSH 别名/IP | 每台协作机 `~/.ssh/config` + `deploy/local.env` | 各机改 2 行 |
| CI 部署 | GitHub 两仓 Secrets（各 3 个） | 浏览器更新（见 §3） |
| WireGuard hub | 服务器 `/etc/wireguard/`（**不在 git**，2 个 peer） | §5 导出搬移 |
| mosquitto/vsftpd/iperf3 | 服务器 `/etc/`（**不在任何仓**） | §5 导出搬移 |
| hello-all demo 服务 | mifi-nat 仓 `vps/demo_service.py` | 重跑 |

## 1. 新服务器准备（阿里云控制台）

1. 购买/创建实例（Ubuntu 22.04/24.04），**绑定或新建 SSH 密钥对**——新密钥对文件保存好，它将替换下面的 `VPS_SSH_KEY`；
2. **防火墙放行**：TCP 80（博客）、22（SSH）；若同机迁其他服务另加：TCP 1883（MQTT）、21 与 30000-30009（FTP 被动段）、8081（demo）、**UDP 51820**（WireGuard）；
3. 控制台远程连接验证能登录。

## 2. 博客栈三连（约 5 分钟）

在**任一已配好 SSH 的机器**上，先把 `~/.ssh/config` 的 `HostName` 指向新 IP（别名 `aliyun` 不变，所有脚本继续工作）：

```bash
# ① Caddy + 站点目录 + 防火墙提示（幂等，可重复跑）
ssh aliyun "bash -s" < deploy/server-setup.sh

# ② 构建并推送全站内容（公开+VIP）
bash deploy/deploy.sh

# ③ VIP 认证（沿用原口令或换新；多账号成对传入）
ssh aliyun "bash -s -- vip <密码> bluewave <密码>" < deploy/vip-auth-setup.sh
```

## 3. CI 自动部署切换（浏览器，两个仓各一次）

新服务器的 SSH **私钥**与地址就绪后，更新两个仓的 Secrets（Settings → Secrets and variables → Actions）：

| 仓 | Secret | 新值 |
|---|---|---|
| `website` 与 `website-vip-priv` 各 3 个 | `VPS_SSH_KEY` | **新服务器**的私钥全文（新密钥对 .pem） |
| 同上 | `VPS_HOST` | 新公网 IP |
| 同上 | `VPS_BASEURL` | `http://<新IP>/` |

更新后在 `website-vip-priv` 的 Actions 页手动 Run 一次 `Deploy site (VIP update)`，绿了即 CI 链路切换完成。

## 4. 每台协作机的本地更新（告知所有同事）

每台机器改两处，共 3 行：

```text
~/.ssh/config          HostName <新IP>          （IdentityFile 换新 pem）
deploy/local.env       BLOG_URL=http://<新IP>/
```

随后 `bash deploy/deploy.sh` 验证一次即可（不放心可先跑 `hugo server -D` 本地预览）。

## 5. 博客之外的服务器状态搬移（**容易漏的部分**）

老服务器上还跑着这些（与博客无关但同机）：

| 服务 | 状态位置 | 搬移方式 |
|---|---|---|
| WireGuard hub（2 peers） | `/etc/wireguard/wg0.conf` + peer 配置 | **含私钥，不在 git**：`tar czf wg-backup.tgz /etc/wireguard`，scp 到新机同路径，`systemctl restart wg-quick@wg0`；或用 mifi-nat 仓 `bootstrap_wg.sh`/`add_mifi_peer.sh` 重建后重新登记 peer |
| mosquitto (MQTT:1883) | `/etc/mosquitto/` | 打包搬移（注意密码/ACL 文件） |
| vsftpd (FTP:21 + 被动段 30000-30009) | `/etc/vsftpd.conf` | 打包搬移；确认被动端口段防火墙已放行 |
| iperf3d (:5201) | systemd 服务 | `apt install iperf3` + 重建 service 文件 |
| hello-all demo (:8081) | mifi-nat 仓 `vps/demo_service.py` | 按 mifi-nat README 重跑 |
| `/root/.ssh/authorized_keys` | 各协作机公钥 | 从老服务器原样拷贝 |

一键打包老服务器配置（在新机可 ssh 老机时执行）：

```bash
ssh aliyun "tar czf - /etc/wireguard /etc/mosquitto /etc/vsftpd.conf /root/.ssh/authorized_keys 2>/dev/null" > old-server-config.tgz
```

## 6. 切换验证清单（全部通过才算迁移完成）

```text
博客：  curl -o /dev/null -w '%{http_code}' http://<新IP>/                 → 200
       curl … http://<新IP>/vip/            （匿名）                       → 401
       curl -u bluewave:… …/vip/            （带认证）                     → 200
       curl … /vip/<任意文章>/two-routes.svg （匿名）                       → 401（图也受保护）
CI：    私有仓 Actions 手动跑一次                                            → success
WG：    wg show wg0（peer 数与老机一致）；PC/MiFi 端 ping 通新 hub
其他：  mosquitto_sub 测试一条、FTP 登录一次、8081 demo 页面打开
```

## 7. 老服务器退役

1. §6 全绿后观察 1~2 天（防有遗漏依赖）；
2. 确认 `old-server-config.tgz` 已离线保存（含 WG 私钥，妥善保管）；
3. 控制台**释放实例**；绑定的弹性 IP/带宽如有保留价值记得先解绑保留；
4. 更新团队内文档/书签里的站点地址。

## 8. 已内置的防坑设计（迁移时自动受益）

- 仓库源码**零 IP 硬编码**（baseURL 部署时注入、服务器地址走 ssh 别名与 CI Secrets）；
- `deploy.sh` 自带 `vip-content/` 缺失中止保护（新机器忘 clone 私有仓不会清空线上 VIP 区）；
- `.gitattributes` 强制 `*.sh` LF 行尾（新机器 clone 后脚本可直接在服务器执行）；
- Caddy 配置脚本幂等，重复执行安全。
