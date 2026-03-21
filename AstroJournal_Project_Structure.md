# AstroJournal 项目结构总体设计

基于本项目的产品需求文档 (PRD)、页面设计规范以及技术架构设计，本项目将采用以下结构进行构建：

## 1. 整体架构与技术栈
- **应用类型**: 离线优先的移动端/跨平台应用
- **核心框架**: Flutter@3.x + Dart@3.x
- **状态管理**: Riverpod@2 (StateNotifier/AsyncNotifier)
- **路由方案**: go_router (声明式路由)
- **当前数据层实现**: 轻量本地仓储（内存 Repository，零代码生成依赖）
- **持久化规划**: 下一阶段接入 Drift (SQLite) 或 Isar（作为正式离线持久化方案）
- **图表展示**: fl_chart
- **后端服务 (后续迭代)**: Supabase (Auth, Postgres)

## 2. 目录结构设计 (Directory Structure)

```text
lib/
├── main.dart                   # 应用入口，初始化本地库与服务
├── core/                       # 核心层 (基础配置、全局样式、通用工具)
│   ├── theme/                  # 深空神秘暗黑主题设计规范 (Colors, Typography, Theme)
│   ├── router/                 # go_router 路由定义与导航
│   ├── database/               # 统一数据访问入口（当前为内存模型与仓储）
│   ├── constants/              # 全局常量、配置信息
│   └── utils/                  # 通用工具函数 (日期格式化、星象计算等)
├── providers/                  # 全局状态管理层 (Riverpod Providers)
│   ├── database_provider.dart  # 数据库实例 Provider
│   ├── profile_provider.dart   # 用户信息与建档状态 Provider
│   └── journal_provider.dart   # 日记流与历史记录 Provider
├── features/                   # 功能模块层 (按特性划分)
│   ├── onboarding/             # 建档模块
│   │   ├── view/               # 建档页面 UI
│   │   └── provider/           # 建档页面独有状态
│   ├── capture/                # 日记输入模块 (核心默认页)
│   │   ├── view/               # 全屏输入框及星尘动效组件
│   │   └── provider/           # 暂存与发送状态
│   ├── history/                # 历史图表模块
│   │   ├── view/               # 折线图与信息抽屉 UI
│   │   └── widgets/            # 图表组件与节点弹窗
│   └── chart/                  # 星盘模块
│       ├── view/               # 星盘页面
│       └── provider/           # 星象计算/缓存状态
└── shared_widgets/             # 全局复用 UI 组件
    ├── custom_buttons.dart     # 星辉紫渐变发光按钮
    ├── background_noise.dart   # 深空星点噪声背景
    └── empty_states.dart       # 空状态展示
```

## 3. 核心功能流程 (Core Workflows)
1. **应用启动流程**：
   - 检查本地仓储中是否存在完整的 `Profile`。
   - 若无，路由重定向至 `/onboarding`。
   - 若有，路由至默认首页 `/`（即 Capture 页面）。
2. **记录交互流程**：
   - 用户在 Capture 页面进行无边框输入。
   - 点击保存后触发“星尘消散”动画，清理输入框。
   - 异步将 `JournalEntry` 写入当前数据仓储（后续可无缝切换为 SQLite）。
3. **历史回溯流程**：
   - 从 Capture 页面右上角 "+" 进入 `/history`。
   - 获取历史日记数据并按时间-运势分进行可视化折线图渲染。
   - 用户点击发光节点，触发底部抽屉展示当天日志和星象快照。

## 4. 样式设计规范 (Design Tokens)
- **主题风格**: 中世纪复古羊皮纸风格 (Medieval Parchment Theme)，极简无边框设计
- **背景色**: `#F4EBD0` (羊皮纸浅黄)
- **面板色**: `#E6D5B8` (稍深羊皮纸色，用于卡片/组件背景)
- **边框/分割线**: `#26000000` (半透明深色墨水)
- **主文本色**: `#DB000000` (深黑色墨水)
- **次文本色**: `#8A000000` (褪色墨水)
- **强调色 (主色)**: `#B8860B` (暗金/黄铜色)
- **辅助色**: `#704214` (深棕/褐色)
- **字体**: 全局使用衬线字体 (serif)，以凸显复古感
- **组件动效**: 所有页面过渡与组件交互保持 200ms easeOut 曲线，避免繁琐动画。

## 5. 开发里程碑 (Milestones)
- **M1: 基础设施搭建** (路由配置、主题配置、统一数据层接口建立)。
- **M2: 核心功能开发** (建档 Onboarding 页面，日记 Capture 页面开发与本地存储打通)。
- **M3: 历史与星盘模块** (fl_chart 折线图接入，历史详情抽屉，静态星盘展示)。
- **M4: 持久化升级与细节优化** (接入 SQLite/Isar、星尘消散动画、星点背景层、交互打磨与最终联调)。

## 6. 架构调整说明（本次更新）
- **调整原因**: 由于当前环境中代码生成链路不稳定，`database.g.dart` 无法可靠生成，导致 Drift 编译链受阻。
- **已完成调整**: 数据层改为纯 Dart 模型 + 内存仓储，保留 `AppDatabase` 访问入口与 Provider 调用方式，避免上层业务改动。
- **影响范围**:
  - `Profile` 与 `JournalEntry` 由代码生成实体改为手写实体。
  - `profile_provider`、`journal_provider` 的接口保持不变，仅参数类型从 Companion 切换为实体对象。
  - Onboarding 与 Capture 页面保存逻辑已适配新实体模型。
- **后续迁移策略**:
  - 保持 `providers -> AppDatabase` 的调用边界不变。
  - 在 `AppDatabase` 内部替换为 Drift/Isar 实现即可完成持久化升级。
  - 业务页面无需大范围重写，可最小成本迁移。
