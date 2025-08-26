-- Stream Deck control buttons for timers

local function load_timers()
    local stored_timers = hs.settings.get("stream_deck_timers") or {}
    local timer_map = {}
    for _, timer in pairs(stored_timers) do
        if timer.end_time then
            console_debug('stream_deck:timer', 'Loaded timer:', timer)
            timer_map[timer.end_time] = timer
        end
    end
    return timer_map
end


local timer_state = {
    active_timers = load_timers(),
    current_hour = 0,
    current_minute = 0,
    last_rung = os.time()
}
local timer_button_presets = {
    [1] = { time = 30, label = "30s" },
    [2] = { time = 60, label = "1m" },
    [3] = { time = 120, label = "2m" },
    [4] = { time = 300, label = "5m" },
    [5] = { time = 600, label = "10m" },
    [6] = { time = 900, label = "15m" },
    [7] = { time = 1800, label = "30m" },
    [8] = { time = 2700, label = "45m" },
    [9] = { time = 3600, label = "60m" },
    [10] = { time = 7200, label = "2h" },
    -- 11 is back button
    [12] = { time = 3000, label = "50m" },
    [15] = { time = 3, label = "" } -- sekrit unlabelled debug button
}


local function save_timers()
    local timer_array = {}
    for end_time, timer in pairs(timer_state.active_timers) do
        console_debug('stream_deck:timer', 'Saving timer:', timer)
        table.insert(timer_array, timer)
    end
    console_debug('stream_deck:timer', 'Saving timer array:', timer_array)
    hs.settings.set("stream_deck_timers", timer_array)
end




local function render_clock_hands()
    local now = os.date("*t")
    local hour = now.hour % 12
    local minute = now.min
    local angle_adjustment = -90 -- 3'oclock is 0°
    local icon_centre = 48

    local hour_angle = (hour * 30) + (minute * 0.5) + angle_adjustment
    local minute_angle = minute * 6 + angle_adjustment
    local elements = {}

    -- hour hand
    local hour_length = 20
    local hour_x = icon_centre + math.cos(math.rad(hour_angle)) * hour_length
    local hour_y = icon_centre + math.sin(math.rad(hour_angle)) * hour_length
    table.insert(elements, {
        type = "segments",
        action = "stroke",
        coordinates = {
            { x = icon_centre, y = icon_centre },
            { x = hour_x, y = hour_y }
        },
        strokeColor = hammerspoon_colour('white'),
        strokeWidth = 5
    })

    -- minute hand
    local minute_length = 28
    local minute_x = icon_centre + math.cos(math.rad(minute_angle)) * minute_length
    local minute_y = icon_centre + math.sin(math.rad(minute_angle)) * minute_length
    table.insert(elements, {
        type = "segments",
        action = "stroke",
        coordinates = {
            { x = icon_centre, y = icon_centre },
            { x = minute_x, y = minute_y }
        },
        strokeColor = hammerspoon_colour('white'),
        strokeWidth = 3
    })

    -- centre blob
    table.insert(elements, {
        type = "circle",
        action = "fill",
        center = { x = icon_centre, y = icon_centre },
        radius = 4,
        fillColor = hammerspoon_colour('white')
    })

    return create_image_from_canvas(elements)
end

local function get_finished_timers()
    local finished = {}

    for end_time, timer in pairs(timer_state.active_timers) do
        if end_time <= os.time() then
            table.insert(finished, timer)
        end
    end

    return finished
end

local function draw_timer_button_image(state)
    local elements = {}

    table.insert(elements, "status_ring.png")

    -- outermost is the 5th timer to fire but the first drawn,
    -- innermost is the soonest to fire but the last drawn,
    -- any further timers are not drawn
    local max_timers = 5
    local sorted_timers = {}
    local current_time = os.time()

    for end_time, timer in pairs(state.active_timers) do
        if timer.remaining and timer.remaining > 0 then
            table.insert(sorted_timers, timer)
        end
    end

    table.sort(sorted_timers, function(a, b)
        return a.remaining < b.remaining
    end)

    local timers_to_show = math.min(#sorted_timers, max_timers)
    for ring_position = timers_to_show, 1, -1 do
        local timer = sorted_timers[ring_position]
        local progress = timer.remaining / timer.total
        local radius = countdown_maximum_radius - (timers_to_show - ring_position) * 5
        table.insert(
            elements,
            create_countdown_canvas(progress, timer.colour, radius)
        )
    end

    if #get_finished_timers() > 0 then
        if #sorted_timers == 0 then
            -- colour ring around the alarm when last/only alarm goes off
            table.insert(
                elements,
                create_countdown_canvas(
                    1,
                    hammerspoon_colour('alert'),
                    countdown_maximum_radius
                )
            )
        end
        table.insert(elements, image_from_file("overlay_alert.png"))
    else
        table.insert(elements, render_clock_hands())
    end
    return image_from_elements(elements)
end


local function assign_timer_colour(timer)
    if timer_colours and #timer_colours > 0 then
        local used_colours = {}
        local resolved_colours = {}

        for index, colour_name in ipairs(timer_colours) do
            resolved_colours[index] = hammerspoon_colour(colour_name)
        end

        for end_time, timer in pairs(timer_state.active_timers) do
            if timer.colour then
                for colour_index, resolved_colour in ipairs(resolved_colours) do
                    if tables_equal(resolved_colour, timer.colour) then
                        used_colours[colour_index] = true
                        break
                    end
                end
            end
        end

        for index = 1, #timer_colours do
            if not used_colours[index] then
                return resolved_colours[index]
            end
        end
    end

    -- we've run out of predefined timer colours
    return generate_colour(
        timer.start_time,
        timer.start_time + timer.total,
        timer.total
    )
end


function create_new_timer(duration)
    local start_time = os.time()
    local end_time = start_time + duration
    local new_timer = {
        start_time = start_time,
        total = duration,
        end_time = end_time
    }
    new_timer.colour = assign_timer_colour(new_timer)
    timer_state.active_timers[end_time] = new_timer

    console_debug('stream_deck:timer', 'New timer added:', new_timer)
    save_timers()

    return new_timer
end




local function get_soonest_active_timer()
    local soonest = nil

    for end_time, timer in pairs(timer_state.active_timers) do
        if end_time > os.time() then
            if not soonest or end_time < soonest then
                soonest = end_time
            end
        end
    end

    return soonest
end


local function update_timer_state()
    local any_finished = #get_finished_timers() > 0
    local current_time = os.time()

    if any_finished then
        -- play a sound every four seconds
        if current_time - timer_state.last_rung >= 4 then
            timer_state.last_rung = current_time
            play_system_sound("Glass")
        end
    end

    for end_time, timer in pairs(timer_state.active_timers) do
        if end_time > current_time then
            timer.remaining = end_time - current_time
        else
            timer.remaining = 0
        end
    end

    local now = os.date("*t")
    timer_state.current_hour = now.hour
    timer_state.current_minute = now.min
end

-- assign colors to loaded timers that don't have them
for end_time, timer in pairs(timer_state.active_timers) do
    if not timer.colour then
        timer.colour = assign_timer_colour(timer)
    end
end

-- initialize timer state
update_timer_state()


local function timer_preset_button(time, label)
    local button = create_button_from_text(label)
    button['name'] = 'Timer Select ' .. label
    button['pressed'] = function(state)
        create_new_timer(time)
        stream_deck_close_panel()
    end
    return button
end


function timer_button()
    return {
        ['name'] = 'Timer',
        ['initialise'] = function()
            return timer_state
        end,
        ['update_state'] = function(button)
            update_timer_state()
            stream_deck_update_button_state(button['name'], timer_state)
        end,
        ['get_image'] = function(state)
            return draw_timer_button_image(state)
        end,
        ['held'] = function(state)
            -- open a panel with more timer duration options
            local preset_buttons = {}
            for position, preset in pairs(timer_button_presets) do
                preset_buttons[position] = timer_preset_button(
                    preset.time,
                    preset.label
                )
            end
            stream_deck_open_panel(preset_buttons)
        end,
        ['pressed'] = function(state)
            local finished_timers = get_finished_timers()
            if #finished_timers > 0 then
                -- button cancels all ringing timers
                for _, timer in ipairs(finished_timers) do
                    console_debug(
                        'stream_deck:timer',
                        'Removing finished timer:', timer
                    )
                    timer_state.active_timers[timer.end_time] = nil
                end
                save_timers()
            else
                soonest = get_soonest_active_timer()
                if soonest then
                    -- button cancels the timer with the least remaining
                    console_debug(
                        'stream_deck:timer',
                        'Removing cancelled timer:',
                        timer_state.active_timers[soonest]
                    )
                    timer_state.active_timers[soonest] = nil
                    save_timers()
                else
                    -- buttons starts the default timer
                    create_new_timer(stream_deck_timer_default)
                end
            end
            update_timer_state()
            stream_deck_update_button_state('Timer', timer_state)
        end,
    }
end
