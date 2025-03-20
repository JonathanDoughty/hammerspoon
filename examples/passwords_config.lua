-- Configuration for passwords.lua preferences
-- Never fear, all actual passwords are stored in/retrieved from login keychain.
-- This does mean, however, that passwords are ultimately only as secure as my login password.
-- The CLI comments below illustrate how to add them for various pwTypes.
-- luacheck: globals hs

local password_config = {
  modal = nil,             -- revert to non-modal for breakage that started with 11.3
  -- modal = "p",          -- when combined with hyper (see config.lua) enter password mode
  timeout = 15,            -- seconds before extracted password is wiped from pasteboard
                           -- set = 0 to not temporarily cache passwords.
                           -- This also disables key stroking into secure input fields.
  use_system = false,      -- Whether to use a unique or system pasteboard.
                           -- Set true will potentially expose passwords to other apps; don't.
  notifySound = "Hero",    -- which of hs.sound.systemSounds to play to get attention
  loglevel = 'info',       -- detail level in hammerspoon console
                           -- Warning: 'verbose' will result in some password details in console
  passwords = { -- paste/keystoke Keychain password when bindTo charecter is pressed
    -- CLI: security add-internet-password -a ${USER} -s $(hostname) -w
    -- service == server in this case
    { desc = "login", bindTo = "l", pwType = "internet", service = hs.host.localizedName() },
    -- CLI: security add-generic-password -a ${USER} -s "pwmgr" -w
    { desc = "pwmgr", bindTo = "p", pwType = "generic", service = "pwmgr" },
    -- CLI: security add-generic-password -a ${USER} -s "ssh passphrase" -w
    { desc = "ssh", bindTo = "s", pwType = "generic", service = "ssh passphrase" },
    -- For those forms that think that supporting copy/paste is insecure ...
    -- Stroke into currently active field whateever is currently on pasteboard,
    -- signaled using the fake 'clipboard' service. If used for stroking an extracted password
    -- then this must be issued before timeout seconds have elapsed.
    -- If timeout <= 0 then stroking from pasteboard is disabled.
    { desc = "clipboard", bindTo = "v", pwType = "clipboard" }, -- think Command-V
  },
}
return password_config
