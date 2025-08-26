-- Stream Deck control buttons for antirsi

local antirsi_state = {
    active = true,
    start_time = 0,
    end_time = 0,
}

local antirsi_button_presets = {
    [1] = { time = 1, label = "1h" },
    [2] = { time = 2, label = "2h" },
    [3] = { time = 3, label = "3h" },
    [4] = { time = 4, label = "4h" },
    [5] = { time = 5, label = "5h" },
    [6] = { time = 6, label = "6h" },
    [7] = { time = 8, label = "8h" },
    [8] = { time = 10, label = "10h" },
    [9] = { time = 12, label = "12h" },
    [10] = { time = 24, label = "24h" },
}


local function run_antirsi(arg)
    local command = "/usr/local/bin/antirsi " .. arg
    hs.task.new("/bin/sh", function(exitCode, stdout, stderr)
        local updated = false

        if exitCode == 0 then
            if stdout and stdout:match("%S") then
                -- output means it is off and reporting when it returns on
                local end_time = tonumber(stdout:match("(%d+)"))

                if antirsi_state.end_time ~= end_time then
                    antirsi_state.active = false
                    antirsi_state.start_time = os.time()
                    antirsi_state.end_time = end_time
                end

                updated = true
                antirsi_state.remaining = antirsi_state.end_time - os.time()
            else
                -- no output, antirsi is on
                if not antirsi_state.active then
                    antirsi_state.active = true
                    antirsi_state.start_time = 0
                    antirsi_state.end_time = 0
                    antirsi_state.remaining = 0
                    updated = true
                end
            end
        else
            print('antirsi error: ' .. (stdout or "") .. (stderr or ""))
        end

        console_debug(
            'stream_deck:antirsi',
            "State now " .. hs.inspect(antirsi_state)
        )
        if updated then
            stream_deck_update_button_state('AntiRSI', antirsi_state)
        end
    end, {"-c", command}):start()
end


function antirsi_button()
    return {
        ['name'] = 'AntiRSI',
        ['initialise'] = function()
            return antirsi_state
        end,
        ['update_state'] = function(button)
            run_antirsi("show")
        end,
        ['get_image'] = function(state)
            if antirsi_state.active then
                return image_from_elements({"status_ring.png", "overlay_keyboard_watch.png"})
            else
                local elements = {
                    [1] = "status_ring.png",
                    [2] = create_countdown_canvas(
                            math.min(
                                1,
                                math.max(
                                    0,
                                    state.remaining / (state.end_time - state.start_time)
                                )
                            ),
                            hex_to_hammerspoon_colour('#333333')
                        ),
                    [3] = {
                            type = "image",
                            image = composite_image_from_file("overlay_keyboard.png"),
                            imageAlpha = 0.5
                        }
                }
                return image_from_elements(elements)
            end
        end,
        ['pressed'] = function(state)
            -- toggle antirsi on / off (1h)
            run_antirsi(antirsi_state.active and "off" or "on")
        end,
        ['held'] = function(state)
            -- open a panel with more antirsi off duration options
            local preset_buttons = {}
            for position, preset in pairs(antirsi_button_presets) do
                local button = create_button_from_text(preset.label)
                button['name'] = 'AntiRSI ' .. preset.label
                button['pressed'] = function()
                    run_antirsi("off " .. preset.time)
                    stream_deck_close_panel()
                end
                preset_buttons[position] = button
            end
            
            stream_deck_open_panel(preset_buttons)
        end,
        ['update_every'] = 15,
    }
end
