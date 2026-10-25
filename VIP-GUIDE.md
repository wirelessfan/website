# VIP 专区：访问与投稿指南

本站采用"公开仓 + 私有仓"双仓结构：

```
wirelessfan/website           （公开仓）Hugo 框架、公开文章、部署脚本
wirelessfan/website-vip-priv  （私有仓）VIP 文章源码，位于本仓 .gitignore 的 vip-content/
```

VIP 区在站点上位于 `/vip/`，由服务器 Basic Auth 保护，不出现在搜索/RSS/sitemap/归档中。

## 一、如何获得访问权限

1. 向站点管理员申请账号（公司内公共账号见内部通知）；
2. 管理员在任意能 SSH 到服务器的机器上执行（可一次加/换多个账号，密码留空则随机生成）：

   ```bash
   ssh aliyun "bash -s -- <用户名> <密码>" < deploy/vip-auth-setup.sh
   ```

3. 浏览器打开 `http://<站点地址>/vip/`，在弹出的登录框输入账号密码即可。

## 二、如何在新机器上投稿

### 1. 恢复工作区（双仓并排）

```bash
git clone https://github.com/wirelessfan/website.git blog
cd blog
git clone git@github.com:wirelessfan/website-vip-priv.git vip-content   # 私有仓放入忽略槽位
```

> `hugo.yaml` 的 module mounts 会把 `vip-content/` 挂载为 `content/vip/`，构建自动包含。

### 2. 写文章

在 `vip-content/` 下新建目录 + `index.md`（页面 bundle，图片放同目录）：

```
vip-content/my-article/index.md
```

front matter 只需三字段（VIP 文章不进分类/标签体系）：

```yaml
---
title: "文章标题"
date: 2026-10-25
description: "一段摘要"
---
```

**脱敏红线**（即使 VIP 区也必须遵守）：不写密钥/口令/AK、客户名称、可定位的真实公网 IP（示例用 203.0.113.x）；内部代号与内部代码路径允许。

### 3. 本地预览

```bash
hugo server -D          # http://localhost:1313/vip/my-article/
```

### 4. 提交与发布

两条路径任选：

**路径 A · 推送后自动部署（推荐，管理员一次性配置）**
私有仓已内置 `.github/workflows/deploy-vip.yml`：推送 main 即自动构建整站（公开+VIP）并部署。前提是私有仓 Settings → Secrets 配好三个值（与公开仓相同）：`VPS_SSH_KEY`、`VPS_HOST`、`VPS_BASEURL`。

```bash
cd vip-content
git add . && git commit -m "新增: my-article" && git push
```

**路径 B · 本机部署（需有服务器 SSH 权限的机器）**

```bash
bash deploy/deploy.sh
```

> `deploy.sh` 带防误删保护：`vip-content/` 缺失或为空会中止部署，防止一次全量替换清空线上 VIP 区。

### 5. 登记（每次新文章必做）

在**公开仓**的 `content/vip/_index.md` 文章列表里追加一行链接（只需标题，不含内容）：

```markdown
- [我的新文章](/vip/my-article/)
```

这是 VIP 区首页的目录，双仓各一次提交即完成整个投稿。

## 三、常见问题

| 问题 | 处理 |
|---|---|
| 构建报 `duplicate mount` | 检查 vip-content/ 内是否误放了 `_index.md`（该文件只存在于公开仓 content/vip/） |
| 推送后 Actions 红叉 | 检查私有仓三个 Secrets 是否配齐；错误信息会明确指出缺哪个 |
| 部署后线上没有新文章 | ①确认 date 不是未来日期之外的问题；②确认走的是带 `--baseURL` 的部署（deploy.sh 或 CI），本地裸 `hugo` 产物不要手动上传 |
| 想撤回某篇 | 删除 vip-content/ 内目录 + 删公开仓索引行 + push，下次部署自动下线 |
| 换密码/加账号 | 见第一节管理员命令，密码改完立即生效 |
