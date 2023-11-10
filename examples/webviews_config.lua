-- Configuration for webviews.lua preferences

local webview_config = {
  modal = "w",
  -- logLevel = "debug",
  views = {
    { key = 'h', url = 'https://www.hammerspoon.org/docs/index.html', desc = 'Hammerspoon API'},
    { key = 'm', url = 'https://mastodon.social/home', desc = 'Mastodon'},
  },
}
return webview_config
