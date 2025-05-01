-- Configuration for webviews.lua preferences

local webview_config = {
  modal = "w",
  -- logLevel = "debug", -- default is info
  views = {
    -- See https://www.hammerspoon.org/docs/hs.doc.hsdocs.html
    { key = 'h', type = 'doc',  url = 'http://localhost:12345/', desc = 'Hammerspoon API via internal server'},
    -- Other websites, see https://www.hammerspoon.org/docs/hs.webview.html
    { key = 'm', type = 'view', url = 'https://mastodon.social/home', desc = 'Mastodon'},
  },
}
return webview_config
