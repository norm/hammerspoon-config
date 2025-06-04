require 'mover'

-- hostname-based configuration
require('' .. hs.host.localizedName())

-- F12 to {un,}mute the microphone
require 'global_mute'
hs.hotkey.bind('', 'F12', function() toggle_global_mute() end)
