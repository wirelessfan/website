---
title: "HiFi4 语音算法库选型：开源预研与商业量产两条线"
date: 2026-05-20
tags: ["DSP", "HiFi4", "语音算法", "选型"]
description: "面向 Cadence Tensilica HiFi4 的 AMR 编解码与 AEC/NS/AGC/VAD 前处理选型分析：开源怎么起步、商业怎么询价、AMR 专利为何要单独看。"
---

本文面向 `Cadence Tensilica HiFi4` 语音开发，聚焦三类需求：

- `AMR-NB / AMR-WB` 语音编解码
- `AEC / NS / AGC / VAD` 语音前处理
- 后续量产时的商业授权与集成路径

## 结论

如果目标是尽快启动研发，建议分两条线并行：

- 开源预研线：`opencore-amr + SpeexDSP` 先跑通，需要更高效果时再评估 `RNNoise` 或 `WebRTC APM`
- 商业量产线：先向 `Cadence HiFi` 生态伙伴、`VOCAL`、`DSP Concepts` 询价和拿评估包，同时单独核 `AMR` 的专利授权

不建议一上来就把 `WebRTC APM` 当第一阶段落地方案。它效果强，但移植复杂度和维护成本明显高于 `SpeexDSP`。

## 选型表

| 功能 | 候选 | 类型 | 许可/授权 | HiFi4 适配性 | 优点 | 风险/缺点 | 建议 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AMR-NB / AMR-WB | `opencore-amr` | 开源 | `Apache-2.0` 源码许可 | 高 | 代码成熟，适合先做 bit-exact、MIPS、RAM 评估 | `AMR` 涉及标准专利，源码可用不等于可直接商用 | 作为第一阶段参考实现和移植基线 |
| AEC / NS / AGC / VAD | `SpeexDSP` | 开源 | BSD 风格开源许可 | 高 | 纯 `C`，结构简单，AEC 与 preprocess 组合直接可用 | 效果上限通常不如较新的商业方案或 WebRTC AEC3 | 作为第一阶段前处理主选 |
| NS | `RNNoise` | 开源 | `BSD-3-Clause` | 中 | 单麦降噪效果通常优于传统 NS，适合做后续增强 | 默认训练/使用链条偏 `48 kHz`，需要处理采样率、帧长和算力 | 第二阶段增强项，适合做 denoise 升级 |
| AEC / NS / AGC / VAD | `WebRTC Audio Processing` | 开源 | BSD 类开源许可 | 中偏低 | `AEC3`、NS、AGC、VAD 比较完整，效果基线高 | `C++` 依赖重，移植和裁剪成本高，RTOS/DSP 集成更复杂 | 不作为首发方案，作为高效果备选 |
| AEC / NS | `VOCAL` | 商业 | 商业授权 | 中高 | 明确面向嵌入式语音，支持 `AEC + NR`，可带集成支持 | 官方无公开报价，需要商务沟通；平台适配是否含 `HiFi4` 需单问 | 适合量产导向项目尽早接触 |
| AEC / NS / 语音前端框架 | `DSP Concepts / Audio Weaver` | 商业 | 商业授权 | 高 | 强在整条语音前端、调参和多核分发，不只是单算法 | 成本通常高于单个裸算法库；更像平台而不是一个小库 | 适合做完整 voice front-end 和调参体系 |
| AMR-NB / AMR-WB | `Cadence HiFi` 生态伙伴方案 | 商业 | `Cadence license + codec-dependent license` | 高 | 更可能已有 `HiFi` 优化版本，落地速度快 | 供应商、价格、交付形式要逐家确认 | 商业 `AMR` 首选路径之一 |

## 分项说明

### 1. `opencore-amr`

适合做什么：

- 做 `AMR-NB / AMR-WB` 的首版移植
- 建立 `ISS` 性能基线
- 做 bit-exact 回归和码流兼容验证

不适合直接当什么：

- 不建议未经 `IPR` 审核就直接进入量产出货

原因很简单：`AMR` 是标准编解码，不只是"有没有源码"的问题，还有"有没有专利授权"的问题。

### 2. `SpeexDSP`

适合做什么：

- 第一阶段的 `AEC`
- `NS / AGC / VAD`
- 在 `HiFi4` 上先把一条低风险、易维护的前处理链跑起来

它的优点不是"最好"，而是"最容易先做成"。
对 DSP 移植来说，这一点很重要。

### 3. `RNNoise`

适合做什么：

- 单麦降噪增强
- 做传统 NS 的效果升级对照组

注意点：

- 官方训练与示例链条偏 `48 kHz`
- 电话链路常见是 `8 kHz / 16 kHz`
- 上 HiFi4 前要先确定重采样策略、帧长、状态缓存和算力预算

### 4. `WebRTC Audio Processing`

适合做什么：

- 当确认效果目标较高，愿意接受更高集成复杂度时

不建议作为第一阶段落地方案，原因是：

- 代码体量更大
- `C++` 和构建系统更重
- 裁剪、封装、线程和内存模型适配会花不少时间

### 5. `VOCAL`

官方能确认的点：

- `AEC` 支持 `8 kHz` 和 `WB`
- 强调面向 `DSP` 优化
- `AEC` 可以单独授权，也可以作为整套语音增强系统的一部分授权
- `Noise Reduction` 也支持单独授权或整套授权

目前不能公开确认的点：

- 官方未公开价目
- 官方页面没有列出 `HiFi4`，所以是否已有 `Xtensa/HiFi4` 优化版，要单独问销售或 FAE

### 6. `DSP Concepts / Audio Weaver`

它更适合这类场景：

- 不是只买一个 `AEC`
- 而是要一整套语音前端框架
- 后续还要做调参、多个产品 SKU 复用、多核分发和量产维护

如果未来会做：

- `AEC`
- `NS`
- beamforming
- wake word 前端
- 多麦方案

那它的工程价值通常高于单点算法库。

## 商业授权怎么判断

### `VOCAL` 这样的公司，费用会不会很高

截至 2026-05-20，我没有查到 `VOCAL` 官方公开报价。官方公开信息只说明：

- 可单独授权某个算法
- 也可打包进完整语音增强系统
- 需要联系销售沟通需求

这类报价通常取决于：

- 是否只买目标码，还是买源码
- 是否只买单算法，还是买整套 `AEC + NS + AGC`
- 是否已有目标平台版本，还是需要新做 `HiFi4` 移植
- 是否包含调参、验收、现场支持
- 产品年出货量
- 是否需要独占条款或区域条款

这里给一个工程判断，不是公开报价：

- 如果只买单算法、无源码、无独占、少支持，成本相对可控
- 如果要源码、要 `HiFi4` 新移植、要调参支持、还要量产 royalty 打包，预算就会明显上升
- 如果再叠加 `AMR` 专利授权，整体成本会比单买 `AEC/NS` 高一截

所以更现实的做法不是先问"贵不贵"，而是先把询价输入准备齐：

- 目标 SoC / DSP：`Cadence HiFi4`
- 主频、内存限制、缓存结构
- 采样率：`8 kHz / 16 kHz / 48 kHz`
- 单麦 / 双麦 / 多麦
- 算法清单：`AMR-NB/WB`、`AEC`、`NS`、`AGC`、`VAD`
- 是否要源码
- 计划年出货量
- 是否需要中国本地支持和交付验收

这样拿回来的报价才有可比性。

## `AMR` 的授权要单独看

`AMR-NB / AMR-WB` 和一般开源 DSP 库不一样，源码之外还要看标准必要专利。

商业上至少要把下面两件事分开：

- 算法实现授权
- 专利/IPR 授权

`VoiceAge` 官方页面明确提供 `AMR` 和 `AMR-WB` 的 licensing 联系入口。
这意味着即便内部先用开源实现做评估，后续量产也要尽早让法务/IP 团队介入。

## 推荐推进顺序

考虑到阶段切太细会放大组织成本，这里建议最多保留两阶段。

### 第一阶段：开源跑通并建立基线

1. `opencore-amr` 跑通 `AMR-NB/WB`
2. `SpeexDSP` 跑通 `AEC + NS + AGC`
3. 在 `ISS` 和板级各做一次 `MIPS / RAM / 效果` 评估
4. 只有当效果明显不够时，再补评估 `RNNoise` 或 `WebRTC APM`

这一阶段的目标不是一次到位，而是尽快拿到三类确定性：

- `HiFi4` 上真实算力和内存开销
- 基础语音链路是否跑得通
- 当前开源效果与产品目标差距有多大

优点：

- 最快开工
- 风险和成本最低
- 能尽早摸清 `HiFi4` 上的真实性能瓶颈

### 第二阶段：商业替换或商业补强

1. 让 `Cadence` 提供 `HiFi` 生态伙伴 shortlist
2. 并行联系 `VOCAL`、`DSP Concepts`
3. `AMR` 方向同步联系 `VoiceAge` 或其指定授权路径
4. 基于第一阶段的基线结果，决定是整包替换，还是只替换 `AMR` / `AEC` 等单模块
5. 拿评估包和商务条款后做技术/商务双评审

这一阶段的核心不是"从零选型"，而是"用第一阶段测出来的数据去压缩选择范围"。

优点：

- 更适合量产导向项目
- 供应商通常能给效果、调参和验收支持
- 基于真实基线做商务判断，不容易高估或低估商业包价值

缺点：

- 前期商务动作更多
- 没有公开价，推进速度取决于对接效率

## 建议的当前决策

如果团队刚开始上 `HiFi4`，建议直接按两阶段推进：

- 第一阶段先用 `opencore-amr + SpeexDSP`
- 第二阶段按第一阶段结果决定是否引入 `VOCAL`、`DSP Concepts` 或其他 `Cadence HiFi` 伙伴方案
- `AMR` 的专利授权不要拖到第二阶段末尾才看，第一阶段就应同步让法务/IP 介入

这样做的好处是：

- 技术路线足够短
- 商务动作不会脱离技术实际
- 不会把团队拆进过多阶段切换和重复评审

## 参考链接

- Cadence HiFi 软件生态：<https://www.cadence.com/en_US/home/tools/silicon-solutions/compute-ip/hifi-dsps/software.html>
- VOCAL G.167 AEC：<https://vocal.com/echo-cancellation/g-167-acoustic-echo-canceller/>
- VOCAL Noise Reduction：<https://vocal.com/noise-reduction/>
- opencore-amr：<https://sourceforge.net/projects/opencore-amr/>
- WebRTC Audio Processing：<https://webrtc.googlesource.com/src/+/refs/heads/main/modules/audio_processing/>
- SpeexDSP AEC / preprocess 文档：<https://www.speex.org/docs/manual/speex-manual/node7.html>
- RNNoise：<https://gitlab.xiph.org/xiph/rnnoise>
- VoiceAge AMR-NB licensing：<https://voiceage.com/AMR-NB.AMR.html>
- VoiceAge AMR-WB licensing：<https://voiceage.com/AMR-WB.G.722.2.html>
