# dot-hammerspoon

This is my collection of [Hammerspoon](https://www.hammerspoon.org/)
customization scripts and wrappers for the
[Spoons](https://github.com/Hammerspoon/Spoons) I have adopted.

* [init](./init.lua) - controller that loads all others
* [config](./examples) - configuration examples
* [utils](./utils.lua) - generic utility functions used by many of below

The remainder of these implement specific customizations and/or
act as wrappers around standard Spoons I have adopted.

ToDo: Convert some / all to actual Spoons.

* [auto_reload](./auto_reload.lua) - watch for changes and re-load Hammerspoon config
* [bindings](./bindings.lua) - set up generic bindings and report
* [caffeine](./caffeine.lua) - wrapper for Caffeine replacement; See also
  bindings and sleepwatcher
* [ksheet](./ksheet.lua) - Wrapper for KSheet spoon - application shortcut keys
* [passwords](./passwords.lua) - Set up key bindings to extract / use passwords from Keychain
    * [update_password](./update_password.sh) - bash script to update Keychain passwords
* [sleepwatcher](./sleepwatcher.lua) - Act on system sleep events
* [switcher](./switcher.lua) - Handle app switching/un-minimizing the way I like
* [tm_progress](./tm_progress.lua) - wrapper for Time Machine progress widget
* [usb](./usb.lua) - Watch/act on USB device connect/disconnects
* [webviews](./webviews.lua) - Display web pages
* [wifi](./wifi.lua) - Deal with wifi / network location transitions
* [window_mgr](./window_mgr.lua) - Set up window management bindings
  

