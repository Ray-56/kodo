# Kodo MVP 设计实施说明

## 优先级

**HANDOFF.md 产品规则 → contracts 操作契约 → tokens.json 与本页 → implementation/ → references/**。

references 中六张 PNG 是上一轮生成的品牌/视觉概念图，不是已实现页面或可以直接贴进 Flutter 的 UI。它们展示的分类、五栏导航、Goals、Notes、同比百分比和山景横幅全部不在本期范围。实施时只沿用留白、低饱和绿、清爽字重和圆角语言。

implementation/index.html 是按最终 MVP 规则制作的静态布局基线，包含项目首页、详情、新建、统计、空态和设置/离线状态。可以用浏览器直接打开；按钮不执行业务逻辑。对应 PNG 是这份 HTML 的实际渲染，不是 Flutter 的验收截图。数字来自 examples/demo_export.json，不能用旧概念稿中不一致的数值验证计算。

## 可直接使用的资源

| 目录/文件 | 使用方式 |
| --- | --- |
| assets/icons/*.svg | 22 个独立 24×24 线性图标，Flutter 原生 SVG 组件加载 |
| assets/brand/logo_mark*.svg | 原始矢量符号，常规/单色/反白；系统文字另行绘制 Kodo/行一 |
| assets/brand/app_icon_master.svg | 1024×1024 母版：不预烘焙圆角、阴影、机框或文字 |
| assets/brand/app_icon_1024/512/192/180.png | 不透明 RGB 应用图标源，交给各平台图标产物流程 |
| assets/brand/android_foreground_1024.png | 透明前景，主体位于中心安全区域；背景色见 txt |
| tokens.json | 颜色、字号、间距、圆角、尺寸、动效的唯一参数来源 |
| copy.zh-CN.json | 中文文案与插值占位符，实施时转为 ARB 或集中字符串 |
| contrast_checks.json | 对实际 token 色值计算的正文对比度结果 |
| asset_manifest.json | 文件列表、用途、字节与 SHA-256 校验值 |

矢量符号是本次按概念方向独立绘制的工程化版本，不是从模糊 AI 图中精确描摹的商标成品；小尺寸用纯符号，不把「行一」塞进 48px 图标。母版仅为源资产，不代表全部平台适应性蒙版和商店图标均已生成验收。Android 要实际检查圆形、方圆形等不同蒙版，iOS 要检查平台最终图标尺寸。

## Flutter 接入

仅复制 design/assets 下内容到 `apps/mobile/assets`；不要把 references 或 HTML 整套打进 App。pubspec 资源声明样例见 scaffolding/pubspec_assets.yaml。SVG 无外部链接、外部字体或 base64 背景；颜色需要主题化时使用 ColorFilter。图标视觉为 24px，但外层点击容器必须至少 48px。

```dart
// 依赖 flutter_svg；这是接入示例，需在选定版本中编译验证。
SvgPicture.asset(
  'assets/icons/dumbbell.svg',
  width: 24,
  height: 24,
  colorFilter: const ColorFilter.mode(
    KodoTokens.primary,
    BlendMode.srcIn,
  ),
)
```

所有文字使用平台系统字体；无需下载字体，不附带系统字体文件，也不在运行时请求 Google Fonts。概念图中写的 Inter 不意味着已打包该字体。字体度量差异允许按平台微调，但层级、间距与功能含义不可变。

## 必须重建的组件

KodoScaffold、ProjectCard、QuickRecordButton、AmountInput、PresetSelector、RecordRow、StatsBarChart、EmptyState、SyncStatusBanner、UndoSnackbar 和确认弹层。文字、按钮、输入框、柱状图都是 Flutter 真实控件，不能裁一张页面图片叠透明点击区。首页卡片和按钮点击事件彼此独立。

参考宽度 390，左右边距 20，卡片内边距 16、圆角 20、卡片间距 12。主按钮高度 52、圆角 14；输入框最小高度 52，随字体放大可增高。底栏最小高度 64 外加系统安全区域；不要硬编码截图中的状态栏或 Home Indicator。

## 视觉修正与状态

概念图的浅 Sage (#6B8F7A) 仅用于非关键装饰。可交互主色改为 #416954，白字对比度约 6.23:1；正文 #1F2937，辅助文字 #667085。正常文本阈值采用 4.5:1 作为检查基线 [S10]；disabled 色仅用于真的禁用状态。图表不依靠颜色独自表达数据。

保存中禁用重复提交，本地成功给短提示；远端超时只显示副本状态，不吞本地成功。空/加载/本地写入错误/断网待同步/永久同步阻塞/已归档/删除待联网都要实施，不能只做有数据的一种截图。200% 字体下优先增高、换行和滚动，不强制缩小字号。开启系统减少动态效果时禁用不必要数字动效。

## 来源

概念 PNG：当前对话此前通过图像生成得到，原文件完整打包。SVG、母版、HTML、tokens、文案：本次交接制作的独立源文件，没有复制第三方图标库或摄影素材。无字体文件随包分发。本资源说明不替代名称/图形的商标清查，也不改变原始生成图片的适用条款；正式品牌授权与主仓库许可证由项目所有者确定。
