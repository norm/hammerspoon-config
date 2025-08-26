-- Stream Deck control buttons for Elgato Key Light

local elgato_key_light_notification = nil
local elgato_key_light_state = {
    on = false,
    brightness = 20,
    temperature = 4000,
}


local function update_state_from_response(body)
    local function mired_to_kelvin(mired)
        return math.floor(1000000 / mired)
    end

    if not body then return end

    local success, data = pcall(hs.json.decode, body)
    if success and data and data.lights and data.lights[1] then
        elgato_key_light_state.on = data.lights[1].on == 1
        elgato_key_light_state.brightness = data.lights[1].brightness
        elgato_key_light_state.temperature = mired_to_kelvin(data.lights[1].temperature)
    end
    console_debug(
        'stream_deck:elgato',
        "State now " .. hs.inspect(elgato_key_light_state)
    )
end


local function sync_elgato_key_light_state()
    hs.http.asyncGet(
        'http://' .. elgato_key_light_ip .. ':9123/elgato/lights',
        nil,
        function(status, body, headers)
            if status == 200 then
                update_state_from_response(body)
                stream_deck_update_button_state(
                    'Elgato Key Light Toggle',
                    elgato_key_light_state
                )
            end
        end
    )
end


local function get_elgato_key_light_state()
    return {
        on = elgato_key_light_state.on,
        brightness = elgato_key_light_state.brightness,
        temperature = elgato_key_light_state.temperature
    }
end


local function update_elgato_key_light()
    function kelvin_to_mired(kelvin)
        return math.floor(1000000 / kelvin)
    end

    hs.http.doAsyncRequest(
        'http://' .. elgato_key_light_ip .. ':9123/elgato/lights',
        'PUT',

        hs.json.encode({
            numberOfLights = 1,
            lights = {
                {
                    on = elgato_key_light_state.on,
                    brightness = elgato_key_light_state.brightness,
                    temperature = kelvin_to_mired(elgato_key_light_state.temperature)
                }
            }
        }),
        {['Content-Type'] = 'application/json'},

        function(status, body, headers)
            if status == 200 then
                update_state_from_response(body)
                if elgato_key_light_notification then
                    hs.alert.closeSpecific(elgato_key_light_notification)
                    elgato_key_light_notification = nil
                end

                if elgato_key_light_state.on then
                    elgato_key_light_notification = hs.alert.show(
                        string.format(
                            'Key Light at %d%%, %dK',
                            elgato_key_light_state.brightness,
                            elgato_key_light_state.temperature
                        ),
                        2
                    )
                end

            end
        end
    )
end


function adjust_elgato_key_light_brightness(adjustment)
    elgato_key_light_state.on = true
    elgato_key_light_state.brightness = math.max(
        1,
        math.min(
            100,
            elgato_key_light_state.brightness + adjustment
        )
    )
    update_elgato_key_light()
end


function adjust_elgato_key_light_temperature(delta_kelvin)
    elgato_key_light_state.on = true
    elgato_key_light_state.temperature = math.max(
        2906,
        math.min(
            6993,
            elgato_key_light_state.temperature + delta_kelvin
        )
    )
    update_elgato_key_light()
end


function elgato_key_light_on()
    elgato_key_light_state.on = true
    update_elgato_key_light()
    stream_deck_update_button_state('Elgato Key Light Toggle', elgato_key_light_state)
end

function elgato_key_light_off()
    elgato_key_light_state.on = false
    update_elgato_key_light()
    stream_deck_update_button_state('Elgato Key Light Toggle', elgato_key_light_state)
end


function elgato_controls_panel()
    return {
        [1] = {
            ['name'] = 'Elgato Key Light On',
            ['image'] = image_from_elements({"keylight.png", "overlay_panel_on.png"}),
            ['pressed'] = function()
                elgato_key_light_on()
            end
        },
        [2] = {
            ['name'] = 'Elgato Key Light Off',
            ['image'] = image_from_elements({"keylight.png", "overlay_panel_off.png"}),
            ['pressed'] = function()
                elgato_key_light_off()
            end
        },
        [4] = {
            ['name'] = 'Elgato Key Light Dim',
            ['image'] = image_from_elements({"keylight.png", "overlay_dim.png"}),
            ['pressed'] = function()
                adjust_elgato_key_light_brightness(-5)
            end,
            ['held'] = function()
                adjust_elgato_key_light_brightness(-100)
            end
        },
        [5] = {
            ['name'] = 'Elgato Key Light Bright',
            ['image'] = image_from_elements({"keylight.png", "overlay_bright.png"}),
            ['pressed'] = function()
                adjust_elgato_key_light_brightness(5)
            end,
            ['held'] = function()
                adjust_elgato_key_light_brightness(100)
            end
        },
        [9] = {
            ['name'] = 'Elgato Key Light Cool',
            ['image'] = image_from_elements({"keylight.png", "overlay_panel_cool.png"}),
            ['pressed'] = function()
                adjust_elgato_key_light_temperature(200)
            end,
            ['held'] = function()
                adjust_elgato_key_light_temperature(10000)
            end
        },
        [10] = {
            ['name'] = 'Elgato Key Light Warm',
            ['image'] = image_from_elements({"keylight.png", "overlay_panel_warm.png"}),
            ['pressed'] = function()
                adjust_elgato_key_light_temperature(-200)
            end,
            ['held'] = function()
                adjust_elgato_key_light_temperature(-10000)
            end
        },
        [15] = {
            ['name'] = 'Default',
            ['image'] = image_from_elements({
                "keylight.png",
                "overlay_panel_default.png"
            }),
            ['pressed'] = function()
                elgato_key_light_state.on = true
                elgato_key_light_state.brightness = 20
                elgato_key_light_state.temperature = 4000
                update_elgato_key_light()
            end
        }
    }
end


function elgato_key_light_button()
    if not elgato_key_light_ip then
        return {
            ['name'] = 'Elgato Key Light (Disabled)',
            ['image'] = image_from_elements({"disabled.png"}),
            ['pressed'] = function()
                play_system_sound("Sosumi")
            end
        }
    end

    return {
        ['name'] = 'Elgato Key Light Toggle',
        ['initialise'] = function()
            return elgato_key_light_state
        end,
        ['update_state'] = function(button)
            sync_elgato_key_light_state()
            stream_deck_update_button_state(button['name'], elgato_key_light_state)
        end,
        ['get_image'] = function(state)
            return image_from_elements({
                "keylight.png",
                state.on and "overlay_panel_on.png" or "overlay_panel_off.png"
            })
        end,
        ['pressed'] = function(state)
            elgato_key_light_state.on = not elgato_key_light_state.on
            update_elgato_key_light()
            stream_deck_update_button_state(
                'Elgato Key Light Toggle',
                elgato_key_light_state
            )
        end,
        ['held'] = function()
            stream_deck_open_panel(elgato_controls_panel())
        end,
        ['update_every'] = 5
    }
end
