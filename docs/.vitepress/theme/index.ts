import { h } from 'vue'
import DefaultTheme from 'vitepress/theme'
import './custom.css'
import { registerComponents } from './components'
import HomeDownloads from './components/HomeDownloads.vue'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'home-features-before': () => h(HomeDownloads)
    })
  },
  enhanceApp({ app }) {
    registerComponents(app)
  }
}
