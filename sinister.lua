require "2560-monitor"
require "1920-sidecar-monitor"

require "colours"
require "palette"
require "stream_deck"
require "stream_deck.audio"
require "stream_deck.wiim"


stream_deck_brightness = 30
stream_deck_button_background = "dark purple"
wiim_ip = "192.168.1.147"


local home_buttons = {}
-- first row, reserved for media controls
home_buttons[1] = overlay_wiim_playback_controls()
home_buttons[2] = overlay_mac_playback_controls()
-- second row
home_buttons[9] = audio_mute_button()
home_buttons[10] = microphone_mute_button()
-- third row

on_stream_deck_ready(function(deck)
    stream_deck_home_panel(stream_deck_create_panel(home_buttons))
end)
