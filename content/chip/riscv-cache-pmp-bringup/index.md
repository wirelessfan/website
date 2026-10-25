---
title: "RISC-V 板级 Bring-up 实录：Cache/PMP CSR 驱动与测试"
date: 2026-10-25
categories: ["板级调试与Bring-up"]
tags: ["RISC-V", "bring-up", "CSR", "FPGA"]
description: "新 SoC 点板阶段如何给 Cache 与 PMP 两套 CSR 子系统写配置驱动和功能测试：与原厂 demo 对齐的取舍、无 libc 环境的测试输出设计、以及 9/9 与 8/9 背后的硬件发现。"
---

> 场景：一颗新 RISC-V SoC 的 FPGA 点板阶段，需要把 cache 控制寄存器（MCACHE_CTL/CCTL）与物理内存保护（PMP）两块 CSR 子系统的驱动和测试补齐。原厂 SDK 有 demo，但 demo ≠ 可交付固件——本文记录从 demo 到工程化驱动的完整路径。

## 为什么要"对齐 demo"而不是"重写"

原厂 demo（启动代码包里的 cache/pmp 示例）的价值是**位定义与编码公式的权威出处**：`MCACHE_CTL` 的使能/预取位、几何解码公式（`sets = 1<<(f+6)`、`ways = f+1`、`line = 1<<(f+2)`）、CCTL 命令码（L1D_VA_WB=1、WBINVAL=2、WBINVAL_ALL=6…）、PMP 的 NAPOT/TOR/NA4 编码与探测方法。这些**一字不改照搬**——bring-up 阶段最忌讳"顺手优化"权威定义，出了问题你分不清是自己的理解错还是硬件错。

要替换的是**平台胶水**，见下表：

| 原 demo 做法 | 工程化替换 | 理由 |
|---|---|---|
| `printf` 输出 | 结果结构体（magic 头 + 每场景一行结果）经 JTAG 回读 | 板级无 UART；结构体可断言、可比对 |
| trap 死循环等调试器 | guard 化 CSR 访问（缺 CSR 记 mcause 继续） | 一个不存在的 CSR 不该烧掉整个测试批次 |
| 驱动与测试混在 main.c | `*_drv.c`（只编程硬件）/ `*_test.c`（只编排场景）分离 | 驱动进产品，测试留在 bring-up |
| 浮点换算打印 | 定点/整型，换算放上位机 | 固件不做非必要计算 |

## 测试设计：场景表 + 三态断言

每个子系统一张场景表，逐行执行、逐行记录。PMP 的典型场景：

1. **探测**：entry 数（写 RW 回读数字节）、granularity（全 1 写 pmpaddr 数尾零）、NA4 支持、Smepmp 扩展（MMSC_CFG 链）；
2. **NAPOT 编码**：写 pmpcfg(R/W/X) + pmpaddr(NAPOT 尾 1 展开) → 回读校验 → 反解码验证；
3. **三态访问**：对 locked entry 覆盖的地址分别读/写/执行，断言 mcause = 5/7/1（分别对应读/写/取指异常）。

cache 侧则覆盖：几何解码、使能/预取开关、`fence.i` 语义、**运行时自修改代码**（改指令 → 刷 I-cache → 执行新指令，验证 CCTL L1I 失效命令真的生效）——这是最容易被"看起来过了"骗过的场景。

## 实测结果与硬件发现

FPGA 上跑出 **cache 9/9 PASS、PMP 8/9 PASS**——第 9 项 NA4 模式硬件不支持，驱动探测正确并记 NOTEST 而非 FAIL。三态访问异常全部可复现；burst 写在 cache 使能前后差异巨大（单字读 7.4× 加速），这组数字后来直接成为 cache 配置策略的依据。

测试同时抓出了 6 项硬件问题（寄存器位行为与手册不符等），全部记录在测试报告并转硬件团队——**bring-up 测试的第一个用户是硬件团队，不是软件团队**。

## 三条可迁移的经验

1. **demo 的角色是参考实现**：位定义照抄，胶水重写——两者的修改权限要一开始就划清；
2. **无输出环境下的测试输出设计**（结果结构体 + magic 头 + DONE 标记）决定了测试能不能进自动化批次；
3. **不支持 ≠ 失败**：探测到能力缺失记 NOTEST，与 FAIL 严格分开——否则测试报告会因为平台差异永远"不绿"，大家就会开始忽略红灯。

相关阅读：《[HyperRAM 带宽实测](/chip/hyperram-bandwidth-measure/)》是同一块板上的另一场实测战役。
