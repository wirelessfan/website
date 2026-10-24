# BW 技术札记

基于 Hugo + PaperMod 的技术博客，部署在阿里云轻量 VPS（IP 直访，暂未备案/绑域名）。

- 三个栏目：`content/chip`（芯片设计与选型）、`content/network`（网络技术优化）、`content/ai`（AI 自动化）
- 站点标题/介绍在 `hugo.yaml` 的 `title` 与 `params.homeInfoParams` 中修改

## 环境准备（一次性）

```bash
winget install Hugo.Hugo.Extended   # 或从 mirrors.huaweicloud.com/hugo/ 下载解压，放入 PATH
```

## 写一篇新文章

每个栏目一个目录，文章用页面 bundle（`index.md` + 图片同目录）：

```bash
# 新建文章（--draft 草稿，去掉 draft 或 hugo 加 -D 预览）
hugo new content/network/my-topic/index.md

# 本地预览 http://localhost:1313/
hugo server -D
```

front matter 常用字段：`title`、`date`、`tags`、`description`（列表摘要/SEO）。

## 发布

真实服务器地址放在 `deploy/local.env`（已 gitignore，不入库，参考 `deploy/local.env.example`）：

```bash
cp deploy/local.env.example deploy/local.env   # 首次：填入 BLOG_URL / WEB_ROOT / REMOTE
bash deploy/deploy.sh                          # 本地构建 + tar/rsync 推送
```

首次部署前，服务器需要初始化一次（安装 Caddy 并配置站点，不影响已有 WireGuard/demo 服务）：

```bash
ssh aliyun "bash -s" < deploy/server-setup.sh
```

若服务器已装好但外网打不开，多半是阿里云轻量控制台防火墙没放行 TCP 80。

## VIP 专区（受限文章）

- **源码隔离**：VIP 文章放 `vip-content/`（已 gitignore，不入公开仓），由 `hugo.yaml` 的 module mounts 挂到 `content/vip/`；入库的 `content/vip/_index.md` 只维护栏目说明与文章链接。
- **构建隔离**：`cascade.build.list=never`——VIP 文章不进搜索索引/RSS/sitemap/归档/分类，只渲染 `/vip/` 路径下的页面（已验证零泄漏）。
- **服务器侧**：`/vip` 由 Caddy Basic Auth 保护（2.6.x 指令名 `basicauth`）。配置/更换口令：

  ```bash
  ssh aliyun "bash -s -- <用户名> <密码>" < deploy/vip-auth-setup.sh   # 密码留空则随机生成
  ```

- **安全边界**：IP 直访阶段无 TLS，Basic Auth 是访问控制而非加密（口令与内容走明文）——VIP 内容仍须脱敏，绑域名后升级 HTTPS 才是完整方案。

## CI 自动发布（可选）

推送到 GitHub 并在仓库 Settings → Secrets and variables → Actions 配置三个 Secret：

| Secret | 内容 |
|---|---|
| `VPS_SSH_KEY` | 可登录 VPS 的私钥（pem 全文，含 BEGIN/END 行） |
| `VPS_HOST` | 服务器地址 |
| `VPS_BASEURL` | 站点对外地址，如 `http://x.x.x.x/`（影响 RSS/搜索索引） |

配置后 `.github/workflows/deploy.yml` 会在 push 到 main 时自动构建并 rsync 部署。
未配置 Secret 时 Deploy 步骤会失败（红叉属预期，不影响本地 `deploy.sh` 部署）。

## 写作约定（重要）

- **三层分类**：栏目（`content/chip|network|ai`）→ 主题分类（`categories`，从 `data/topics.yaml` 框架中选取，一个栏目可写多个）→ 标签（`tags`，自由关键词）。框架本身在 `data/topics.yaml` 维护，「主题」页自动渲染并计数。
- **脱敏**：仓库公开可分享——真实公网 IP 只允许出现在两处不入库/加密的位置：本地 `deploy/local.env`（gitignore）与 GitHub Secrets；文章与源码中一律用 RFC 5737 示例地址（如 `203.0.113.x`），且不出现密钥、客户名称、公司内部代码路径。
- 内容基于真实项目复盘，选型结论注明前提条件与时间。
- 大文件/图片放文章同名 bundle 目录内，不要引用仓库外路径。
