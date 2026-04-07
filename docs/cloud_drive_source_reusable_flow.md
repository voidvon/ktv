# 云盘数据源可复用流程

本文把当前百度网盘接入整理为一套可复用的云盘接入流程，后续新增阿里云盘、OneDrive、Dropbox 等数据源时，优先复用这一套抽象，而不是再从百度实现复制一份。

## 目标

统一以下通用步骤：

1. App 级配置
2. 用户 OAuth 登录
3. 选择一个云盘根目录
4. 仅扫描该根目录下的歌曲文件
5. 需要播放时拉取远端文件并缓存到本地
6. 用户主动下载时复制到本地目录
7. 聚合进现有歌库和点歌流程

## 代码分层

通用层位于 `lib/features/media_library/data/cloud/`：

- `cloud_models.dart`
  统一云盘令牌、根目录配置、远端文件、用户信息、容量信息模型。
- `cloud_auth_repository.dart`
  统一授权码登录、令牌刷新、读取有效 token 的接口。
- `cloud_source_config_store.dart`
  统一根目录配置的持久化接口。
- `cloud_remote_data_source.dart`
  统一“按根目录扫描”“按关键词搜索”“查询可播放文件元数据”接口。
- `cloud_playback_cache.dart`
  统一远端媒体下载到本地缓存的接口。
- `cloud_song_source.dart`
  统一“读取云盘根目录 -> 过滤媒体文件 -> 写入聚合索引”的刷新流程。
- `cloud_song_download_service.dart`
  统一“从播放缓存复制到用户本地目录/应用目录，并记录下载索引”的下载流程。

设置层通用控制器位于 `lib/features/settings/application/cloud_source_settings_controller.dart`：

- 负责加载配置
- 构建授权地址
- 执行登录/退出
- 加载账号与容量摘要
- 保存或清空云盘根目录

## 提供方实现方式

每个网盘只需要实现自己的 Provider 适配：

1. `CloudAppCredentials` 子类
2. `CloudAuthRepository` 实现
3. `CloudSourceConfigStore` 实现
4. `CloudRemoteDataSource` 实现
5. `CloudPlaybackCache` 实现
6. `CloudSongSource` 子类，补一个 `RemoteFile -> SourceSongRecord` 映射
7. `CloudSourceSettingsController` 子类，补配置工厂和 provider 文案

百度网盘现在就是这一套模式：

- 模型：`lib/features/media_library/data/baidu_pan/baidu_pan_models.dart`
- 扫描源：`lib/features/media_library/data/baidu_pan/baidu_pan_song_source.dart`
- 下载：`lib/features/media_library/data/baidu_pan/baidu_pan_song_download_service.dart`
- 设置控制器：`lib/features/settings/application/baidu_pan_settings_controller.dart`

## KTV 侧复用点

KTV 业务层不再只认识百度网盘，而是按 `sourceId` 复用：

- `DefaultPlayableSongResolver`
  按 `sourceId -> CloudPlaybackCache` 解析可播放文件。
- `KtvController`
  按 `sourceId -> CloudSongDownloadService` 处理下载。
- `SongBookLibraryViewModel`
  通过 `supportsDownload(song)` / `isSongDownloaded(song)` 判断是否展示下载按钮。

这意味着后续接入新云盘时，只要把新的 `sourceId` 对应服务注册进去，点歌页和下载链路可以直接复用。

## 接入新云盘的最小步骤

1. 新建 `features/media_library/data/<provider>/` 目录。
2. 实现 OAuth 与 API Client。
3. 实现 `RemoteDataSource` 和 `PlaybackCache`。
4. 实现 `<Provider>SongSource` 和 `<Provider>SongDownloadService`。
5. 实现 `<Provider>SettingsController`。
6. 在 `lib/app/ktv_dependencies.dart` 注册：
   - `AggregatedSongSource`
   - `CloudPlaybackCache`
   - `CloudSongDownloadService`

## 当前约束

这套流程现在面向“云盘里的歌曲文件”这个业务场景，已经抽掉了大部分百度专有逻辑，但仍保留了两类业务约束：

1. 聚合索引的目标仍然是 `Song`
2. 下载行为仍然是“先缓存可播放文件，再复制到本地”

如果未来要支持图片、文档、非歌曲目录同步，可以在通用层之上再补更高一层的文件类型策略，而不用重写认证、配置、扫描、下载基础链路。
