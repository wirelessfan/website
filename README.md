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

```bash
bash deploy/deploy.sh          # 本地构建 + tar/rsync 推送到 aliyun:/var/www/blog
```

首次部署前，服务器需要初始化一次（安装 Caddy 并配置站点，不影响已有 WireGuard/demo 服务）：

```bash
ssh aliyun "bash -s" < deploy/server-setup.sh
```

若服务器已装好但外网打不开，多半是阿里云轻量控制台防火墙没放行 TCP 80。

## CI 自动发布（可选）

推送到 GitHub 并配置 `Settings → Secrets → VPS_SSH_KEY`（可登录 VPS 的私钥）后，
`.github/workflows/deploy.yml` 会在 push 到 main 时自动构建并 rsync 部署。

## 写作约定（重要）

- **脱敏**：不写真实公网 IP（试验台 IP、实例 ID）、密钥、客户名称、公司内部代码路径；示例一律用 RFC 5737 地址（如 `203.0.113.x`）。
- 内容基于真实项目复盘，选型结论注明前提条件与时间。
- 大文件/图片放文章同名 bundle 目录内，不要引用仓库外路径。
