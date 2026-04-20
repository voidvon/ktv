# App Update Strategy

## 目标

本文档用于约束麦麦 KTV 的多平台更新方案，避免后续在 Android、Windows、macOS、iOS 上用同一套错误思路强行统一实现。

这里的核心原则只有一条：

- Flutter 统一负责“检查更新、展示更新说明、触发更新入口”
- 平台各自负责“如何下载、如何安装、如何替换当前应用”

更新能力主要由分发渠道决定，而不是由 Flutter 决定。

## 当前仓库现状

截至 `2026-04-20`，仓库已经具备以下能力：

- Android APK 构建脚本：`scripts/build_android_apk.sh`
- iOS IPA 构建脚本：`scripts/build_ios_ipa.sh`
- Windows ZIP 构建脚本：`scripts/build_windows.ps1`
- GitHub Releases 发布脚本：`scripts/publish_github_release.sh`
- 设置页已有“其他”分组和“关于我们”入口，适合作为更新入口

当前版本来源：

- 应用版本号定义在 `pubspec.yaml`
- 当前版本格式为 `1.0.0-alpha.7+7`

当前分发现状：

- Android：GitHub Releases 分发 APK
- Windows：GitHub Releases 分发 ZIP
- macOS：已有桌面测试分发包
- iOS：已有 unsigned IPA 测试分发包

当前代码库里还没有现成的应用内更新模块。

## 不做的方案

以下方案不建议采用：

- 不做“一套 Flutter 代码直接覆盖所有平台安装逻辑”
- 不做 Windows ZIP 下载后自行覆盖程序目录
- 不做 macOS 压缩包下载后手写替换 `.app`
- 不做 iOS 应用内下载 IPA 并覆盖安装
- 不直接解析 GitHub Release HTML 页面判断最新版本

原因：

- Windows 和 macOS 的安装/替换流程涉及签名、权限、进程退出、目录替换和系统安全策略
- iOS 对自更新限制严格
- GitHub 页面结构不是稳定 API，不适合作为程序依赖

## 总体架构

建议新增独立的 `update` 模块，不和现有 KTV、歌库、下载管理逻辑耦合。

建议结构：

- `lib/features/update/domain/app_update_info.dart`
- `lib/features/update/domain/update_check_result.dart`
- `lib/features/update/data/update_manifest_client.dart`
- `lib/features/update/application/update_service.dart`
- `lib/features/update/application/update_controller.dart`
- `lib/features/update/presentation/update_dialog.dart`
- `lib/features/update/presentation/update_entry_tile.dart`

职责划分：

- `UpdateManifestClient`
  - 拉取远端更新元数据
- `UpdateService`
  - 读取当前版本
  - 比较版本
  - 输出更新结果
- `UpdateController`
  - 驱动设置页和关于页上的更新状态
- `Platform Adapter`
  - 执行平台安装、跳转或原生 updater 调用

## 更新源设计

不建议直接依赖 GitHub Releases API 作为唯一更新源。

更稳的做法是发布时同时生成一个稳定的 `latest.json`，由客户端读取。

这里建议继续保留一份统一入口文件，但不要再把所有平台绑到同一组全局版本号上。

原因：

- Android、Windows x64、macOS、iOS 往往不会在同一天发布
- 如果只保留一组顶层 `version/buildNumber`，后发布的平台会覆盖先发布的平台语义
- 客户端真正关心的是“当前平台的最新可用版本”，不是“整个项目是否所有平台同时发版”

建议字段：

```json
{
  "platforms": {
    "android": {
      "version": "1.0.0-alpha.8",
      "buildNumber": 8,
      "publishedAt": "2026-04-20T12:00:00Z",
      "required": false,
      "notes": [
        "修复播放切换稳定性"
      ],
      "download": {
        "mode": "apk",
        "variants": [
          {
            "abi": "arm64-v8a",
            "url": "https://example.com/maimai-ktv-1.0.0-alpha.8-android-arm64-v8a.apk",
            "sha256": "..."
          },
          {
            "abi": "armeabi-v7a",
            "url": "https://example.com/maimai-ktv-1.0.0-alpha.8-android-armeabi-v7a.apk",
            "sha256": "..."
          }
        ],
        "fallbackUrl": "https://example.com/maimai-ktv-1.0.0-alpha.8-android-universal.apk",
        "fallbackSha256": "..."
      }
    },
    "windows": {
      "version": "1.0.0-alpha.9",
      "buildNumber": 9,
      "publishedAt": "2026-04-23T09:00:00Z",
      "required": false,
      "notes": [
        "Windows x64 独立修复包"
      ],
      "download": {
        "mode": "appinstaller",
        "url": "https://example.com/maimai-ktv.appinstaller"
      }
    },
    "macos": {
      "version": "1.0.0-alpha.8",
      "buildNumber": 8,
      "publishedAt": "2026-04-21T10:00:00Z",
      "required": false,
      "notes": [
        "macOS 桌面更新"
      ],
      "download": {
        "mode": "sparkle",
        "feedUrl": "https://example.com/appcast.xml"
      }
    },
    "ios": {
      "version": "1.0.0-alpha.8",
      "buildNumber": 8,
      "publishedAt": "2026-04-21T10:00:00Z",
      "required": false,
      "notes": [
        "iOS 测试分发更新"
      ],
      "download": {
        "mode": "external",
        "url": "https://testflight.apple.com/join/xxxx"
      }
    }
  }
}
```

设计要求：

- `latest.json` 要稳定、可缓存、易于手工检查
- 不同平台必须能独立记录自己的最新版本和发布时间
- 不同平台下载入口必须分开描述
- 支持是否强制更新的标记
- 支持更新说明展示
- Android 需要提供文件校验信息

兼容策略：

- 客户端可以短期兼容旧版“顶层 `version + downloads`”格式
- 发布脚本应尽快切换到 `platforms.<platform>` 结构

## 版本比较规则

`pubspec.yaml` 当前版本格式为：

```text
1.0.0-alpha.7+7
```

这里必须拆成两部分处理：

- 展示版本：`1.0.0-alpha.7`
- 构建号：`7`

比较规则建议：

1. 先比较展示版本
2. 展示版本相同时，再比较构建号
3. 不要只按字符串比较
4. 不要忽略 `+buildNumber`

原因：

- 标准语义版本里的 build metadata 通常不参与优先级比较
- 如果只比较 `1.0.0-alpha.7`，会丢掉 `+7` 这类发布序号信息

## 平台策略

### Android

当前现状：

- 已有 APK 构建脚本
- 已支持 split-per-ABI APK 和 universal APK
- 当前更适合继续沿用 GitHub Releases 分发

建议方案：

- Flutter 端检查更新
- Android 原生层负责安装 APK
- 优先按设备 `ABI` 选择 split APK
- 若没有匹配变体，再回退到 `universal APK`

不建议的做法：

- 不在客户端硬编码固定下载 universal APK

原因：

- split APK 体积更小，下载更快
- Android 可以通过原生层读取 `Build.SUPPORTED_ABIS` 后精确选择对应安装包
- universal APK 仍然适合作为兜底包，但不应成为默认选择

落地建议：

- 更新元数据中同时提供 `variants` 和 `fallbackUrl`
- 通过原生层读取 `Build.SUPPORTED_ABIS`
- 优先选择命中的 ABI 包，下载完成后通过平台通道调起系统安装器
- 安装前校验文件 hash
- 如果后续上架 Google Play，再补一套 Play In-App Updates 分支

### Windows

当前现状：

- 现有产物是 ZIP
- ZIP 适合下载测试，不适合做完善的自动更新

建议方案：

- 从 ZIP 分发切换为 `MSIX + .appinstaller`
- Windows 的更新安装交给系统 `App Installer`

为什么不继续用 ZIP：

- 应用运行中无法稳定覆盖自身文件
- 解压后替换目录、快捷方式、权限、回滚都需要自己处理
- 一旦失败，恢复成本高

建议的 Windows 角色划分：

- Flutter：检查更新、展示更新信息、触发“立即更新”
- Windows 原生/系统：下载并安装 MSIX 更新

实施前提：

- 新增 Windows 打包脚本，输出 `.msix`
- 新增 `.appinstaller` 文件生成逻辑
- 发布时上传 `.msix` 和 `.appinstaller`

第一阶段降级方案：

- 如果暂时还没有改成 MSIX，则 Flutter 只提供“检查更新后打开下载页”
- 不实现 ZIP 覆盖更新

### macOS

当前现状：

- 已有桌面测试包
- 当前尚未接入标准 updater

建议方案：

- 自分发场景下接入 `Sparkle`
- Flutter 端仍然保留统一的检查更新入口和版本展示
- 真正安装更新由 Sparkle 完成

为什么用 Sparkle：

- 它是 macOS 自分发应用的成熟更新方案
- 已覆盖检查更新、下载、签名验证、退出替换、重启等关键流程

实施前提：

- 使用 `Developer ID Application` 签名
- 完成 notarization
- 发布可供 Sparkle 使用的 `appcast.xml`

第一阶段降级方案：

- 在 Sparkle 尚未接入前，Flutter 先只提供“检查更新后打开发布页”

### iOS

当前现状：

- 已有 unsigned IPA 测试分发包
- 当前更偏向测试分发，不是 App Store 正式发布

建议方案：

- App Store / TestFlight 分发时，只做“检查更新并跳转”
- 不在应用内下载 IPA 并覆盖安装

原因：

- iOS 平台不适合做 Android/桌面那种应用内覆盖安装
- 更新入口通常应交给 App Store、TestFlight 或企业分发页面

## Flutter 统一能力

Flutter 层应统一提供以下能力：

- 检查更新
- 显示当前版本
- 显示最新版本
- 显示发布时间
- 显示更新说明
- 标记是否强制更新
- 展示“已是最新版本”
- 对不同平台显示不同按钮文案

建议按钮文案：

- Android：`下载并安装`
- Windows：`立即更新` 或 `打开更新器`
- macOS：`立即更新`
- iOS：`前往更新`

## 建议的接入位置

优先接入以下 UI：

- 设置页“其他”分组下新增 `检查更新`
- 关于页新增：
  - 当前版本
  - 检查更新
  - 最新版本信息
  - 更新说明

当前适合修改的位置：

- `lib/features/settings/presentation/settings_page.dart`
- `lib/app/app.dart`
- `lib/app/ktv_dependencies.dart`

## 发布链路改造

现有发布脚本为：

- `scripts/publish_github_release.sh`

建议在发布阶段补充以下能力：

1. 读取 `pubspec.yaml` 当前版本
2. 上传平台安装产物
3. 生成 `latest.json`
4. 如有 macOS Sparkle，生成或更新 `appcast.xml`
5. 如有 Windows App Installer，生成或更新 `.appinstaller`
6. 将相关更新元数据一并发布到固定 URL

建议发布产物：

- Android：`maimai-ktv-<version>-android-universal.apk`
- Windows：`maimai-ktv-<version>-windows-x64.msix`
- Windows：`maimai-ktv.appinstaller`
- macOS：Sparkle 使用的归档包
- macOS：`appcast.xml`
- iOS：分发页地址或 TestFlight 地址
- 通用：`latest.json`

## 推荐依赖

Flutter 侧建议引入：

- `package_info_plus`
  - 读取当前 app 版本
- `url_launcher`
  - 打开下载页、App Store、TestFlight、外部更新地址

是否需要额外 HTTP 依赖可以在实现时决定：

- 若使用 `dart:io` / `HttpClient` 即可满足需求，可以不额外引入
- 若希望统一请求层和解析逻辑，可再评估 `http`

## 实施顺序

建议按以下顺序落地，避免一次性把所有平台都做到一半：

### 第一阶段

- 建立 Flutter 更新模块
- 增加设置页和关于页入口
- 接入 `latest.json`
- 完成版本比较
- 所有平台先支持“检查更新”

### 第二阶段

- Android 完成 APK 下载和安装
- Android 更新只使用 universal APK

### 第三阶段

- Windows 改成 `MSIX + .appinstaller`
- Flutter 触发 Windows 原生更新

### 第四阶段

- macOS 接入 Sparkle
- 完成签名、公证、appcast 发布流程

### 第五阶段

- iOS 接入 App Store / TestFlight 跳转
- 根据分发方式补充强制更新策略

## 风险与约束

需要提前接受以下现实约束：

- 不同平台的“安装更新”一定不一致
- Windows 若不改分发格式，更新体验不会好
- macOS 若没有签名和 notarization，自更新链路不完整
- iOS 的更新能力受分发渠道强约束
- GitHub Releases 可以继续作为产物托管，但不应承担客户端唯一的更新协议职责

## 最终建议

对于当前仓库，最稳妥的路线是：

1. 先做统一的 Flutter 更新框架
2. 先把更新源标准化为 `latest.json`
3. Android 率先支持完整下载安装
4. Windows 尽快改为 `MSIX + .appinstaller`
5. macOS 走 Sparkle
6. iOS 保持跳转式更新

这套方案的重点不是“所有平台看起来完全一样”，而是“每个平台都用最适合自己的更新机制，同时在 Flutter 层保持一致的用户入口和信息展示”。
