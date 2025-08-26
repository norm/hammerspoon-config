-- to reload from the CLI after making changes:
-- hs -c "hs.console.clearConsole(); hs.reload()"

-- this should be only things that apply to all computers
require "hs.ipc"
require "console_debug"
require "interface"
require "mover"

-- shortcut to mute the mic globally
hs.hotkey.bind("", "F10", function() toggle_microphone_mute() end)

-- hostname-specific configuration
require("" .. hs.host.localizedName())
