import { defineConfig } from 'vitepress'

const repositoryOwner = process.env.GITHUB_REPOSITORY?.split('/')[0] ?? ''
const repositoryName = process.env.GITHUB_REPOSITORY?.split('/')[1] ?? ''
const isGitHubPagesBuild = process.env.GITHUB_ACTIONS === 'true'
const base = isGitHubPagesBuild && repositoryName
  ? `/${repositoryName}/`
  : '/'
const withBase = (path: string) => `${base}${path.replace(/^\/+/, '')}`
const pagesSiteOrigin = isGitHubPagesBuild && repositoryOwner && repositoryName
  ? `https://${repositoryOwner}.github.io`
  : ''
const withPublicUrl = (path: string) => {
  const resolvedPath = withBase(path)
  return pagesSiteOrigin ? `${pagesSiteOrigin}${resolvedPath}` : resolvedPath
}

export default defineConfig({
  base,
  lang: 'zh-CN',
  title: '麦麦KTV',
  description: '面向家庭娱乐、包厢点歌和大屏播放场景的跨平台 KTV 点歌应用。',
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: [
    /^\/Users\//,
    /^\/Volumes\//,
    /^\/scripts\/build_android_apk\.sh$/,
    /^\/scripts\/build_windows\.ps1$/
  ],
  head: [
    ['link', { rel: 'icon', href: withPublicUrl('/favicon.ico') }],
    ['link', { rel: 'apple-touch-icon', href: withPublicUrl('/app-icon.png') }],
    ['meta', { name: 'theme-color', content: '#ff6a3d' }],
    ['meta', { name: 'apple-mobile-web-app-title', content: '麦麦KTV' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: '麦麦KTV' }],
    ['meta', { property: 'og:description', content: '点歌、排队、播放控制、下载管理与歌库配置统一在同一套界面里。' }],
    ['meta', { property: 'og:image', content: withPublicUrl('/images/song-search-screen.jpg') }]
  ],
  themeConfig: {
    logo: withBase('/app-icon.png'),
    nav: [
      { text: '首页', link: '/' },
      { text: '快速开始', link: '/guide/' },
      { text: '开发文档', link: '/develop/' },
      { text: 'UI 设计', link: '/design/' },
      { text: '版本发布', link: '/release-history' }
    ],
    search: {
      provider: 'local'
    },
    outline: {
      level: [2, 3],
      label: '本页目录'
    },
    docFooter: {
      prev: '上一页',
      next: '下一页'
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/voidvon/maimai-ktv' }
    ],
    footer: {
      message: '麦麦KTV 官方网站与文档',
      copyright: 'Copyright © 2026 麦麦KTV'
    },
    sidebar: {
      '/guide/': [
        {
          text: '快速开始',
          items: [
            { text: '概览', link: '/guide/' },
            { text: '版本发布记录', link: '/release-history' },
            { text: '多平台更新策略', link: '/app_update_strategy' },
            { text: '发版与 latest.json 维护', link: '/release_publish' }
          ]
        }
      ],
      '/develop/': [
        {
          text: '开发入口',
          items: [
            { text: '开发总览', link: '/develop/' },
            { text: 'Android 构建', link: '/android_build' },
            { text: 'Windows 构建', link: '/windows_build' },
            { text: 'Android 播放链路', link: '/android_playback_notes' },
            { text: 'SQLite 歌曲入库规则', link: '/sqlite_song_import_rules' }
          ]
        },
        {
          text: '云盘与数据源',
          items: [
            { text: '云盘数据源可复用流程', link: '/cloud_drive_source_reusable_flow' },
            { text: '百度网盘接入准备', link: '/baidu_pan_data_source_guide' },
            { text: '百度网盘类设计草案', link: '/baidu_pan_data_source_design' },
            { text: '115 开放平台整理', link: '/115_open_platform_guide' }
          ]
        }
      ],
      '/design/': [
        {
          text: 'UI 设计',
          items: [
            { text: '设计入口', link: '/design/' },
            { text: 'UI 复刻规格', link: '/ktv_ui/ui_rebuild_spec' },
            { text: '设计 Tokens', link: '/ktv_ui/ui_design_tokens' },
            { text: '布局线框', link: '/ktv_ui/ui_layout_wireframe' },
            { text: '状态矩阵', link: '/ktv_ui/ui_state_matrix' },
            { text: '文案清单', link: '/ktv_ui/ui_copywriting_inventory' },
            { text: '资源说明', link: '/ktv_ui/ui_asset_notes' },
            { text: '组件检查表', link: '/ktv_ui/ui_component_checklist' }
          ]
        }
      ],
      '/': [
        {
          text: '开始使用',
          items: [
            { text: '快速开始', link: '/guide/' },
            { text: '版本发布记录', link: '/release-history' }
          ]
        },
        {
          text: '开发与发布',
          items: [
            { text: '开发总览', link: '/develop/' },
            { text: 'Android 构建', link: '/android_build' },
            { text: '发版与 latest.json 维护', link: '/release_publish' }
          ]
        },
        {
          text: 'UI 设计',
          items: [
            { text: '设计入口', link: '/design/' },
            { text: 'UI 复刻规格', link: '/ktv_ui/ui_rebuild_spec' }
          ]
        }
      ]
    }
  }
})
