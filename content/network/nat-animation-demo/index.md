---
title: "NAT 包转发动画演示：下行、上行与哈希查表"
date: 2026-10-25
categories: ["NAT与内网穿透", "数据面与性能优化"]
tags: ["NAT", "流表", "动画", "可视化"]
description: "三个纯 SMIL 动画：下行包如何被 NAT 改写转发、上行包的对称路径、以及五元组哈希在 4 路组相联流表中的查表与判决过程。无需 JS，浏览器原生播放。"
---

配套《[双重 NAT 问题模型与穿透技术路线](/network/dual-nat-traversal/)》的可视化演示：三个动画都是**纯 SMIL**（无 JavaScript），浏览器原生自动循环播放。

## 动画 1 · 下行：公网服务器 → 内网设备

一张来自 `8.8.8.8:443`（HTTPS）的包进入 NAT 网关：演示五元组如何匹配流表、目的 MAC/IP/端口如何改写、以及 IPv4 头与 TCP 校验和的 **RFC 1624 差量修正链**——只改几个字节，1400 字节的 Payload 原地不动。

![NAT 下行转发动画：virtio 入口到 Wi-Fi 出口](nat_anim_1_down_virtio_to_wifi.svg)

## 动画 2 · 上行：内网设备 → 公网

同一流量的对称方向：内网私有地址与端口如何被转换成公网五元组、出接口 MAC 如何替换、校验和差量如何重算。

![NAT 上行转发动画](nat_anim_2_up_wifi_to_virtio.svg)

## 动画 3 · 哈希查表：五元组 → 4 路组相联 → 判决

流表的内部机制特写：五元组计算哈希 → 定位组（set）→ 4 路逐项比对 tag → 命中/未命中判决。示例哈希值 `0x457D`、`0xED49` 展示了"tag 低 6 位恰为组索引"的同一位移技巧。

![NAT 哈希查表演示：五元组到 4 路组相联](nat_anim_3_hash_lookup.svg)

## 延伸阅读

- 想了解为什么"头身分离"是所有主流加速器的铁律：《[路由数据面加速器五派对比](/network/datapath-accelerator-five-vendors/)》
- 流表项的原子发布、延迟绑定与双水位背压：《[轻量嵌入式 NAT 加速的八个设计原则](/network/nat-offload-design-principles/)》
