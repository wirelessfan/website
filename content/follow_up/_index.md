---
title: "Follow Up"
description: "U380 数据面优化的持续评估与行动跟进：热点路径、uni_netbuf、virtio-ring 简化。"
---

本栏目持续记录 **U380 数据面通路优化** 的评估、实测基线与行动清单。

- **a) USB / SDIO → uni_netbuf**：CPU 为主、轻量加速为辅，优化热点路径。
- **b) 双核合并后的 virtio-ring 简化**：减少不必要的跨核流程与 memory 开销。

当前主题文章：**[《U380 数据面优化：两大系统性问题的跟进方案》](/follow_up/u380-datapath-followup-plan/)**。

## 待评审提案

- **[用 MP_FIFO 替代 virtio ring：背景、框架、收益与副作用（送审稿）](/follow_up/mp-fifo-vs-virtio-ring/)** —— 需要独立评审，问题清单见文内 §6（9 个待答问题）。

访问保护：本栏目文章延续 VIP 内部技术基线的访问控制；未授权访问会返回登录框。
