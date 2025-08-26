-- Stream Deck button state management

local stream_deck_panel_stack = {}
local stream_deck_active_buttons = {}
local stream_deck_button_loop_timer = nil
local stream_deck_button_loop_counter = 0


local function copy_button_state(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = copy_button_state(v)
    end
    return copy
end


function stream_deck_start_button_loop()
    stream_deck_button_loop_timer = hs.timer.new(1, stream_deck_button_loop)
    stream_deck_button_loop_timer:start()
    console_debug('stream_deck:control', 'Starting the core button loop')
end


function stream_deck_stop_button_loop()
    if stream_deck_button_loop_timer ~= nil then
        stream_deck_button_loop_timer:stop()
        console_debug('stream_deck:control', 'Stopping the core button loop')
    end
end


function stream_deck_button_loop()
    stream_deck_button_loop_counter = stream_deck_button_loop_counter + 1

    console_debug(
        'stream_deck_verbose:loop',
        'Running the core button loop ' .. stream_deck_button_loop_counter
    )
    for _, button in pairs(stream_deck_active_buttons) do
        local update_interval = button['update_every'] or 1
        if stream_deck_button_loop_counter % update_interval == 0 then
            local update_state_function = button['update_state']
            if update_state_function then
                console_debug(
                    'stream_deck_verbose:loop',
                    '  update_state called for ' .. button['name']
                )
                update_state_function(button)
            end
        end
    end
end


function stream_deck_current_panel()
    return stream_deck_panel_stack[#stream_deck_panel_stack]
end


function stream_deck_home_panel(new_panel)
    -- set the panel state, destroying any existing state
    console_debug('stream_deck:control', 'Resetting the home panel state')
    stream_deck_panel_stack = {}
    stream_deck_active_buttons = {}
    stream_deck_add_panel(new_panel)
end


function stream_deck_add_panel(panel)
    console_debug('stream_deck:control', 'Opening new panel')
    for index, button in pairs(panel) do
        if button['name'] ~= "" then
            local initialiser = button['initialise'] or function() return {} end
            button['_state'] = copy_button_state(initialiser())
            console_debug(
                'stream_deck_verbose:control',
                string.format("Adding button %s to position %d", button['name'], index)
            )
            stream_deck_active_buttons[button['name']] = button
        end
    end
    stream_deck_panel_stack[#stream_deck_panel_stack + 1] = panel
    stream_deck_render_panel()
end


function stream_deck_open_panel(panel)
    -- fill in blanks, add a back button
    local full_panel = stream_deck_create_panel(panel)
    full_panel[11] = {
        ['name'] = 'Back',
        ['image'] = image_from_elements({"back.png"}),
        ['pressed'] = function()
            stream_deck_close_panel()
        end,
        ['held'] = function()
            stream_deck_close_panel()
        end
    }
    stream_deck_add_panel(full_panel)
end


function stream_deck_create_panel(buttons)
    -- create a full panel state, filling blanks with empty buttons
    local columns, rows = current_stream_deck:buttonLayout()
    local filled_buttons = {}

    console_debug('stream_deck:construct', 'Creating a new panel')
    console_debug('stream_deck_verbose:construct', hs.inspect(buttons))
    for position = 1, columns * rows do
        if buttons[position] then
            filled_buttons[position] = buttons[position]
        else
            filled_buttons[position] = {
                ['name'] = '',
            }
        end
    end

    return filled_buttons
end


function stream_deck_close_panel()
    console_debug('stream_deck:control', 'Closing panel')

    if #stream_deck_panel_stack <= 1 then
        print('Cannot close last Stream Deck panel')
        return
    end

    -- only remove buttons from the active list when they are not in any previous panel
    for index, check_button in pairs(stream_deck_current_panel()) do
        if check_button['name'] ~= "" then
            local button_exists_in_stack = false

            for stack_index = 1, #stream_deck_panel_stack - 1 do
                for _, button in pairs(stream_deck_panel_stack[stack_index]) do
                    if button['name'] == check_button['name'] then
                        button_exists_in_stack = true
                        break
                    end
                end
                if button_exists_in_stack then
                    break
                end
            end

            if not button_exists_in_stack then
                console_debug(
                    'stream_deck_verbose:control',
                    string.format(
                        "Removing button %s from active_buttons", check_button['name']
                    )
                )
                stream_deck_active_buttons[check_button['name']] = nil
            end
        end
    end

    stream_deck_panel_stack[#stream_deck_panel_stack] = nil
    stream_deck_render_panel()
end



function stream_deck_get_button_position(name)
    local current_panel = stream_deck_current_panel()
    for index, button in pairs(current_panel) do
        if button['name'] == name then
            return index
        end
    end
    return nil
end


function stream_deck_render_panel()
    local current_panel = stream_deck_current_panel()
    console_debug('stream_deck:render', 'Rendering panel and updating button states')

    for index, button in pairs(current_panel) do
        if button['name'] ~= "" then
            local update_state_function = button['update_state']
            if update_state_function then
                update_state_function(button)
            end
        end
    end

    for index, button in pairs(current_panel) do
        if button['name'] ~= nil then
            stream_deck_render_button(index, button)
        end
    end
end


function stream_deck_render_button(position, button)
    local static_image = button['image']
    local image_provider = button['get_image'] or function() return nil end
    local generated_image = image_provider(button['_state'])

    if generated_image ~= nil then
        current_stream_deck:setButtonImage(position, generated_image)
    else
        if static_image ~= nil then
            current_stream_deck:setButtonImage(position, static_image)
        else
            current_stream_deck:setButtonImage(
                position,
                solid_colour_fill(stream_deck_button_background)
            )
        end
    end
    console_debug(
        'stream_deck_verbose:render',
        string.format("Rendered button '%s'", button["name"])
    )
end


function stream_deck_button_pressed(deck, position, pressed)
    if stream_deck_asleep then
        return
    end

    local current_panel = stream_deck_current_panel()
    local button = current_panel[position]

    if button == nil or button['name'] == '' then
        return
    end

    local pressed_action = button['pressed'] or function() end
    local held_action = button['held'] or function() end

    if pressed then
        -- check for holding the button (300ms minimum)
        button['_holding'] = hs.timer.new(
            0.3,
            function()
                button['_held'] = true
                button['_holding']:stop()
            end
        )
        button['_holding']:start()
    else
        -- button released, take the action
        if button['_held'] ~= nil then
            button['_held'] = nil
            console_debug(
                'stream_deck:button',
                string.format("Button '%s' held", button['name'])
            )
            if button['held'] then
                held_action(button['_state'])
            else
                -- visual clue there is no held state
                local disabled_image = image_from_elements({"disabled.png"})
                current_stream_deck:setButtonImage(position, disabled_image)
                hs.timer.doAfter(0.75, function()
                    stream_deck_render_button(position, button)
                end)
            end
        else
            console_debug(
                'stream_deck:button',
                string.format("Button '%s' pressed", button['name'])
            )
            pressed_action(button['_state'])
        end
        if button['_holding'] ~= nil then
            button['_holding']:stop()
        end
    end
end


local function tables_equal(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not tables_equal(v, b[k]) then return false end
    end
    for k, v in pairs(b) do
        if not tables_equal(v, a[k]) then return false end
    end
    return true
end


function stream_deck_update_button_state(button_name, new_state)
    local button = stream_deck_active_buttons[button_name]
    if not button then
        return false
    end

    local old_state = button['_state']
    if not old_state or not tables_equal(new_state, old_state) then
        button['_state'] = copy_button_state(new_state)
        local position = stream_deck_get_button_position(button_name)
        if position then
            local current_panel = stream_deck_current_panel()
            if current_panel[position] == button then
                stream_deck_render_button(position, button)
                return true
            end
        end
    end
    return false
end


function stream_deck_create_panel_overlay(name, overlay_buttons)
    -- replace some, not all, buttons from current panel
    local current_panel = stream_deck_current_panel()
    local overlay_panel = {}

    for position, button in pairs(current_panel) do
        overlay_panel[position] = button
    end
    for position, button in pairs(overlay_buttons) do
        overlay_panel[position] = button
    end

    -- button 1 long press is always 'back'
    if overlay_panel[1] then
        local original_held = overlay_panel[1]['held']
        overlay_panel[1]['held'] = function()
            if original_held then original_held() end
            stream_deck_close_panel()
        end
    else
        overlay_panel[1] = back_button()
    end

    -- Use stream_deck_add_panel to push onto stack without forcing back button
    stream_deck_add_panel(overlay_panel)
end


function create_image_from_canvas(contents)
    local canvas = hs.canvas.new({
        w = stream_deck_button_pixels,
        h = stream_deck_button_pixels
    })
    canvas:replaceElements(contents)

    local image = canvas:imageFromCanvas()
    canvas:delete()

    return image
end


function image_from_elements(image_elements)
    local canvas_elements = {}

    for i, element in ipairs(image_elements) do
        if element then
            if type(element) == "string" then
                -- either an image filename...
                local image = image_from_file(element)
                if image then
                    table.insert(canvas_elements, {
                        type = "image",
                        image = image,
                        frame = {
                            x = 0,
                            y = 0,
                            w = stream_deck_button_pixels,
                            h = stream_deck_button_pixels
                        },
                        imageScaling = "scaleProportionally"
                    })
                else
                    -- ...or treat as solid color
                    table.insert(canvas_elements, {
                        type = "image",
                        image = solid_colour_fill(element),
                        frame = {
                            x = 0,
                            y = 0,
                            w = stream_deck_button_pixels,
                            h = stream_deck_button_pixels
                        },
                        imageScaling = "scaleProportionally"
                    })
                end
            elseif type(element) == "table" then
                -- a canvas element
                table.insert(canvas_elements, element)
            else
                -- an image object
                table.insert(canvas_elements, {
                    type = "image",
                    image = element
                })
            end
        end
    end

    return create_image_from_canvas(canvas_elements)
end


function solid_colour_fill(colour)
    if type(colour) == "string" then
        local success, resolved_colour = pcall(hammerspoon_colour, colour)
        colour = success and resolved_colour or {
            red = 0.33,
            green = 0.33,
            blue = 0.33,
            alpha = 0.8
        }
    end

    local elements = {}
    table.insert(elements, {
        action = "fill",
        frame = {
            x = 0,
            y = 0,
            w = stream_deck_button_pixels,
            h = stream_deck_button_pixels
        },
        fillColor = colour,
        type = "rectangle",
    })

    return create_image_from_canvas(elements)
end


function create_countdown_canvas(progress, colour, radius)
    return create_image_from_canvas({
        {
            type = "arc",
            action = "fill",
            center = { x = 48, y = 48 },
            radius = radius or 33,
            startAngle = 0,
            endAngle = 360 * progress,
            fillColor = colour
        }
    })
end


function create_button_from_text(text, background_colour)
    background_colour = background_colour or "dark purple"
    local resolved_colour = hammerspoon_colour(background_colour)

    local text_color = { red = 1, green = 1, blue = 1, alpha = 1 }
    local font_size = 32
    local elements = {}

    -- background
    table.insert(elements, {
        action = "fill",
        frame = {
            x = 0,
            y = 0,
            w = stream_deck_button_pixels,
            h = stream_deck_button_pixels
        },
        fillColor = resolved_colour,
        type = "rectangle",
    })

    -- Vertically centered text (better than full-height centering)
    local text_height = font_size * 1.2
    local y_offset = (stream_deck_button_pixels - text_height) / 2

    -- text
    table.insert(elements, {
        frame = {
            x = 0,
            y = y_offset,
            w = stream_deck_button_pixels,
            h = text_height
        },
        text = hs.styledtext.new(text, {
            font = { name = ".AppleSystemUIFont", size = font_size },
            paragraphStyle = { alignment = "center" },
            color = text_color,
        }),
        type = "text",
    })

    return {
        ['name'] = text,
        ['image'] = create_image_from_canvas(elements),
    }
end
