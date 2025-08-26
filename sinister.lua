require "2560-monitor"
require "1920-sidecar-monitor"

require "colours"
require "palette"
require "stream_deck"
require "stream_deck.antirsi"
require "stream_deck.audio"
require "stream_deck.elgato_key_light"
require "stream_deck.list_step"
require "stream_deck.homekit"
require "stream_deck.timer"
require "stream_deck.wiim"


stream_deck_brightness = 30
stream_deck_button_background = "dark purple"
elgato_key_light_ip = "192.168.1.194"
wiim_ip = "192.168.1.147"
stream_deck_timer_default = 25 * 60  -- 25 minutes (Pomodoro timer)


local home_buttons = {}
-- first row, reserved for media controls
home_buttons[1] = overlay_wiim_playback_controls()
home_buttons[2] = overlay_mac_playback_controls()
-- second row
home_buttons[9] = audio_mute_button()
home_buttons[10] = microphone_mute_button()
-- third row
home_buttons[11] = timer_button()
home_buttons[13] = antirsi_button()
home_buttons[14] = elgato_key_light_button()
home_buttons[15] = list_step_button(
    "Video Conference",
    {"video_conf_off.png"},
    {
        {
            name = "Video Conference",
            image = {"video_conf_on.png"},
            callback = function()
                set_homekit_scene("Video Conference")
                elgato_key_light_on()
            end
        },
        {
            name = "Study Normal",
            image = {"video_conf_off.png"},
            callback = function()
                set_homekit_scene("Study Medium")
                elgato_key_light_off()
            end
        },
    }
)

on_stream_deck_ready(function(deck)
    stream_deck_home_panel(stream_deck_create_panel(home_buttons))
end)
