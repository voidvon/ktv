---
layout: home

hero:
  name: 麦麦KTV
  text: 把点歌、排队、播放和歌库管理，整理成一套跨平台 KTV 体验
  tagline: 面向家庭娱乐、包厢点歌和大屏播放场景，覆盖 Android、macOS、Windows x64 与 iOS 测试分发。
  image:
    src: /images/song-search-screen.jpg
    alt: 麦麦KTV 歌名点歌界面截图
  actions:
    - theme: brand
      text: 快速开始
      link: /guide/
    - theme: alt
      text: 查看发布记录
      link: /release-history
    - theme: alt
      text: GitHub 仓库
      link: https://github.com/voidvon/maimai-ktv

features:
  - title: 为大屏点歌而设计
    details: 左侧预览、右侧点歌工作区和快捷检索被放进同一套横屏交互里，适合电视、投屏设备和包厢环境。
  - title: 多源歌库统一接入
    details: 本地目录歌曲与云端歌曲走同一套点歌流程，支持继续扩展百度网盘等云盘数据源。
  - title: 播放控制完整
    details: 提供播放、暂停、切歌、重唱、原唱/伴唱切换和已点队列管理，围绕真实 KTV 使用过程组织能力。
  - title: 面向测试分发
    details: 当前发布节奏以 Alpha 预发布为主，Android、macOS、Windows x64 与 iOS 都已经进入持续验证。
  - title: 开发资料集中
    details: 构建说明、播放链路、数据源接入、发版策略和 UI 规格都已经收口到同一个文档站点。
  - title: 为后续官网铺路
    details: 现在先用 VitePress 交付清晰的官网与文档骨架，后续可以继续加公告页、FAQ、案例和部署流程。
---

## 为什么是麦麦KTV

麦麦KTV不是单纯的视频播放器，而是一套围绕“找歌更快、排队更清楚、播放更稳定、歌库更易管理”展开的 KTV 软件。它把用户真正高频的动作放在一起：点歌、切歌、下载、收藏、查看已点、配置歌库来源。

## 当前平台状态

| 平台 | 当前状态 | 说明 |
| --- | --- | --- |
| Android | 已发布 APK | 功能最完整，支持本地歌库、百度网盘、原唱/伴唱切换 |
| macOS | 已发布桌面包 | 适合桌面和大屏测试使用 |
| Windows x64 | 已发布桌面包 | 已提供首个 Windows 桌面测试包 |
| iOS | 已发布 unsigned IPA | 适合真机侧载测试，当前用于链路验证 |

## 文档地图

- [快速开始](/guide/)：先看平台支持、歌库准备、点歌流程和常用入口。
- [版本发布记录](/release-history)：了解当前版本节奏和发布内容。
- [开发总览](/develop/)：进入构建、播放链路、数据库规则和云盘接入资料。
- [UI 设计入口](/design/)：查看界面规格、状态矩阵、文案和资源说明。

> 当前官网的定位是“产品介绍 + 可持续维护的项目文档”。后续如果要接入自定义域名、公告流或下载页，这套结构可以直接扩展。
