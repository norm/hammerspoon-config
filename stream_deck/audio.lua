-- Stream Deck control buttons for audio


function audio_mute_button()
    return {
        ['name'] = 'Speaker Mute',
        ['update_state'] = function(button)
            stream_deck_update_button_state(
                'Speaker Mute',
                { muted = get_audio_mute_state() }
            )
        end,
        ['get_image'] = function(state)
            if state.muted then
                return button_image_from_file({"status_ring.png", "audio_mute.png"})
            else
                return button_image_from_file({"status_ring.png", "audio_active.png"})
            end
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("MUTE", true):post()
            hs.eventtap.event.newSystemKeyEvent("MUTE", false):post()
            hs.timer.doAfter(
                0.1,
                function()
                    stream_deck_update_button_state(
                        'Speaker Mute',
                        { muted = get_audio_mute_state() }
                    )
                end
            )
        end,
    }
end


function microphone_mute_button()
    return {
        ['name'] = 'Microphone Mute',
        ['update_state'] = function(button)
            stream_deck_update_button_state(
                'Microphone Mute',
                { muted = get_microphone_mute_state() }
            )
        end,
        ['get_image'] = function(state)
            if state.muted then
                return button_image_from_file({"status_ring.png", "mic_mute.png"})
            else
                return button_image_from_file({"status_ring.png", "mic_active.png"})
            end
        end,
        ['pressed'] = function(state)
            toggle_microphone_mute()
            stream_deck_update_button_state(
                'Microphone Mute',
                { muted = get_microphone_mute_state() }
            )
        end,
    }
end


function volume_increase_button()
    return {
        ['name'] = 'Volume Up',
        ['get_image'] = function(state)
            return button_image_from_file("louder.png")
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("SOUND_UP", true):post()
            hs.eventtap.event.newSystemKeyEvent("SOUND_UP", false):post()
        end
    }
end


function volume_decrease_button()
    return {
        ['name'] = 'Volume Down',
        ['get_image'] = function(state)
            return button_image_from_file("quieter.png")
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", true):post()
            hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", false):post()
        end
    }
end


function play_pause_button()
    return {
        ['name'] = 'Play/Pause',
        ['get_image'] = function(state)
            return button_image_from_file("play_pause.png")
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()
            hs.eventtap.event.newSystemKeyEvent("PLAY", false):post()
        end
    }
end

function previous_track_button()
    return {
        ['name'] = 'Previous Track',
        ['get_image'] = function(state)
            return button_image_from_file("play_previous.png")
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("PREVIOUS", true):post()
            hs.eventtap.event.newSystemKeyEvent("PREVIOUS", false):post()
        end
    }
end

function next_track_button()
    return {
        ['name'] = 'Next Track',
        ['get_image'] = function(state)
            return button_image_from_file("play_next.png")
        end,
        ['pressed'] = function(state)
            hs.eventtap.event.newSystemKeyEvent("NEXT", true):post()
            hs.eventtap.event.newSystemKeyEvent("NEXT", false):post()
        end
    }
end


function overlay_mac_playback_controls()
    return {
        ['name'] = 'Mac Playback Controls Overlay',
        ['image'] = button_image_from_file({"mac.png", "mac_select.png"}),
        ['pressed'] = function(state)
            stream_deck_create_panel_overlay(
                "Mac Playback Controls",
                {
                    [1] = previous_track_button(),
                    [2] = play_pause_button(),
                    [3] = next_track_button(),
                    [4] = volume_decrease_button(),
                    [5] = volume_increase_button()
                }
            )
        end
    }
end
