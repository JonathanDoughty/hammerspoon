# hammerspoon

My collection of [Hammerspoon](https://www.hammerspoon.org/)
customization scripts and wrappers for the
[Spoons](./Spoons) I have adopted.

* [init](./init.lua) - controller that loads all others
* [config](./examples) - configuration examples - modified copies in
  the `.configs` directory take precedence
* [utils](./utils.lua) - generic utility functions used by many of below

The remainder of implement customizations and/or
act as wrappers around standard [Spoons](https://github.com/Hammerspoon/Spoons).

Someday I will get around to converting these into actual Spoons. Until then
maybe you'll find these useful.

* [auto_reload](./auto_reload.lua) - watch for changes and re-load Hammerspoon config
* [bindings](./bindings.lua) - set up generic bindings and report
* [caffeine](./caffeine.lua) - wrapper for Caffeine replacement; See also
  bindings and sleepwatcher
* [ksheet](./ksheet.lua) - Wrapper for KSheet spoon - application shortcut keys
* [passwords](./passwords.lua) - Extract / use passwords from Keychain
    * [update_password](./update_password.sh) - bash script to update Keychain passwords
* [sleepwatcher](./sleepwatcher.lua) - Act on system sleep events
* [switcher](./switcher.lua) - Handle app switching/un-minimizing the way I like
* [tm_progress](./tm_progress.lua) - wrapper for the TimeMachineProgress Spoon
* [usb](./usb.lua) - Watch/act on USB device connect/disconnects
* [webviews](./webviews.lua) - Display web pages
* [wifi](./wifi.lua) - Deal with wifi / network location transitions
* [window_mgr](./window_mgr.lua) - Set up window management bindings
* [work_apps](./work_apps.lua) - Work in progress related to office
  applications
  
