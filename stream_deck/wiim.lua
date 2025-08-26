-- Stream Deck control buttons for WiiM

local wiim_state = {
    connected = false,
    player = "stop",
    volume = 0
}


function send_wiim_command(command)
    hs.task.new('/usr/bin/curl', function(exit_code, stdout, stderr)
        local success = exit_code == 0
        if success then
            wiim_state.connected = true
            get_wiim_status()
        else
            wiim_state.connected = false
            console_debug('stream_deck:wiim', string.format(
                'WiiM command %s exit_code=%d %s %s',
                command, exit_code, stdout, stderr
            ))
            play_system_sound("Sosumi")
        end
    end, {'-k', '-s', 'https://' .. wiim_ip .. '/httpapi.asp?command=setPlayerCmd:' .. command}):start()
end


function get_wiim_status()
    hs.task.new('/usr/bin/curl', function(exit_code, stdout, stderr)
        if exit_code == 0 and stdout then
            console_debug('stream_deck_verbose:wiim', 'WiiM status output: ' .. stdout)
            local success, data = pcall(hs.json.decode, stdout)
            if success and data then
                wiim_state.connected = true
                wiim_state.player = data.status
                wiim_state.volume = tonumber(data.vol) or 0
            else
                wiim_state.connected = false
            end
        else
            wiim_state.connected = false
            console_debug('stream_deck:wiim', string.format(
                'WiiM status fetch exit_code=%d %s %s',
                exit_code, stdout, stderr
            ))
        end
        stream_deck_update_button_state('WiiM Play/Pause', wiim_state)
        stream_deck_update_button_state('WiiM Playback Controls Overlay', wiim_state)
    end, {'-k', '-s', 'https://' .. wiim_ip .. '/httpapi.asp?command=getPlayerStatus'}):start()
end


function wiim_previous_button(closer)
    held_action = function() end
    if closer then
        held_action = function()
            set_permanent_value("wiim", "wiim_overlay_active", false)
        end
    end

    return {
        ['name'] = 'WiiM Previous Track',
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            else
                return button_image_from_file({"wiim.png", "overlay_previous.png"})
            end
        end,
        ['pressed'] = function(state)
            if not wiim_state.connected then return end
            send_wiim_command("prev")
        end,
        ['held'] = held_action
    }
end


function wiim_playback_button()
    return {
        ['name'] = 'WiiM Play/Pause',
        ['initialise'] = function()
            return wiim_state
        end,
        ['update_state'] = function(button)
            get_wiim_status()
        end,
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            elseif wiim_state.player == "play" then
                return button_image_from_file({"wiim.png", "overlay_play.png"})
            elseif wiim_state.player == "pause" then
                return button_image_from_file({"wiim.png", "overlay_pause.png"})
            end

            -- stopped for any other state
            return button_image_from_file({"wiim.png", "overlay_stop.png"})
        end,
        ['pressed'] = function(state)
            if not wiim_state.connected then return end

            if wiim_state.player == "play" then
                wiim_state.player = "pause"
            else
                wiim_state.player = "play"
            end
            stream_deck_update_button_state('WiiM Play/Pause', wiim_state)
            send_wiim_command(wiim_state.player)
        end,
        ['held'] = function()
            if not wiim_state.connected then return end

            wiim_state.player = "stop"
            stream_deck_update_button_state('WiiM Play/Pause', wiim_state)
            send_wiim_command(wiim_state.player)
        end,
        ['update_every'] = 5
    }
end


function wiim_next_button()
    return {
        ['name'] = 'WiiM Next Track',
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            else
                return button_image_from_file({"wiim.png", "overlay_next.png"})
            end
        end,
        ['pressed'] = function(state)
            if not wiim_state.connected then return end
            send_wiim_command("next")
        end
    }
end


function wiim_volume_down_button()
    return {
        ['name'] = 'WiiM Volume Down',
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            else
                return button_image_from_file({"wiim.png", "overlay_quieter.png"})
            end
        end,
        ['pressed'] = function(state)
            if not wiim_state.connected then return end

            wiim_state.volume = math.max(0, wiim_state.volume - 5)
            show_volume_bar(
                wiim_state.volume,
                {"wiim.png", "overlay_quieter.png"},
                hex_to_hammerspoon_colour('#59adc4')
            )
            send_wiim_command("vol:" .. wiim_state.volume)
        end
    }
end


function wiim_volume_up_button()
    return {
        ['name'] = 'WiiM Volume Up',
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            else
                return button_image_from_file({"wiim.png", "overlay_louder.png"})
            end
        end,
        ['pressed'] = function(state)
            if not wiim_state.connected then return end

            wiim_state.volume = math.min(100, wiim_state.volume + 5)
            show_volume_bar(
                wiim_state.volume,
                {"wiim.png", "overlay_louder.png"},
                hex_to_hammerspoon_colour('#59adc4')
            )
            send_wiim_command("vol:" .. wiim_state.volume)
        end
    }
end


function create_wiim_overlay()
    set_permanent_value("wiim", "wiim_overlay_active", true)
    stream_deck_create_panel_overlay(
        "WiiM Playback Controls Overlay",
        {
            [1] = wiim_previous_button(true),
            [2] = wiim_playback_button(),
            [3] = wiim_next_button(),
            [4] = wiim_volume_down_button(),
            [5] = wiim_volume_up_button(),
        }
    )
end


function overlay_wiim_playback_controls()
    local restore_timer

    return {
        ['name'] = 'WiiM Playback Controls Overlay',
        ['initialise'] = function()
            restore_timer = hs.timer.doAfter(1, restore_wiim_overlay_if_needed)
            return wiim_state
        end,
        ['update_state'] = function(button)
            get_wiim_status()
        end,
        ['get_image'] = function(state)
            if not wiim_state.connected then
                return button_image_from_file("disabled.png")
            else
                return button_image_from_file({"wiim.png", "wiim_select.png"})
            end
        end,
        ['pressed'] = function(state)
            if wiim_state.connected then
                create_wiim_overlay()
            end
        end,
        ['held'] = function()
            if wiim_state.connected then
                create_wiim_overlay()
            end
        end
    }
end


function restore_wiim_overlay_if_needed()
    if hs.settings.get("wiim_overlay_active") then
        console_debug('stream_deck:wiim', 'Restoring WiiM overlay after reload')
        if wiim_state.connected then
            create_wiim_overlay()
        end
    end
end
