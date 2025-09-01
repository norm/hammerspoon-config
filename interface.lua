-- mac UI state and visual feedback utilities

local notification_duration = 2
local notification_canvas = nil
local notification_timer = nil
local volume_canvas = nil
local volume_timer = nil


function icon_path(filename)
    return hs.configdir .. "/icons/" .. filename
end


function screen_frame()
    local screen = hs.screen.mainScreen()
    return screen:frame()
end


function toggle_microphone_mute()
    local default_mic = hs.audiodevice.defaultInputDevice()
    if not default_mic then
        return false
    end

    local new_state = not default_mic:inputMuted()

    hs.fnutils.each(
        hs.audiodevice.allInputDevices(),
        function(device) device:setInputMuted(new_state) end
    )

    play_system_sound(new_state and "Bottle" or "Hero")
    notification_icon({new_state and 'mic_mute.png' or 'mic_active.png'})

    return new_state
end


function play_system_sound(sound_name)
    local sound = hs.sound.getByName(sound_name)
    if sound then sound:stop(); sound:play() end
end


function image_from_file(filename)
    local image_path = icon_path(filename)
    return hs.image.imageFromPath(image_path)
end


function composite_image_from_file(filename)
    -- takes both single filename and array of filenames
    local filenames = type(filename) == "table" and filename or {filename}

    local elements = {}
    local has_valid_image = false
    local max_width = 0
    local max_height = 0

    -- Find the largest dimensions and layer each image on the canvas
    for _, fname in ipairs(filenames) do
        local image = image_from_file(fname)

        if image then
            has_valid_image = true
            local size = image:size()
            max_width = math.max(max_width, size.w)
            max_height = math.max(max_height, size.h)

            table.insert(elements, {
                type = "image",
                image = image,
                frame = { x = 0, y = 0, w = size.w, h = size.h },
                imageScaling = "none"
            })
        end
    end

    if not has_valid_image then
        return nil
    end

    -- Create canvas with the largest dimensions
    local canvas = hs.canvas.new({x=0, y=0, w=max_width, h=max_height})
    for i, element in ipairs(elements) do
        canvas[i] = element
    end
    local image = canvas:imageFromCanvas()
    canvas:delete()
    return image
end


function notification_icon(icon_names)
    if notification_timer then
        notification_timer:stop()
        notification_timer = nil
    end
    if notification_canvas then
        notification_canvas:delete()
        notification_canvas = nil
    end

    local icon_image = composite_image_from_file(icon_names)
    if icon_image then
        local screen_frame = screen_frame()
        local icon_size = icon_image:size()
        local canvas_x = (screen_frame.w - icon_size.w) / 2
        local canvas_y = screen_frame.h * 0.8 - icon_size.h - 10

        notification_canvas = hs.canvas.new({
            x = canvas_x,
            y = canvas_y,
            w = icon_size.w,
            h = icon_size.h
        })

        notification_canvas[1] = {
            type = "image",
            image = icon_image,
            frame = { x = 0, y = 0, w = icon_size.w, h = icon_size.h }
        }

        notification_canvas:show()
        notification_timer = hs.timer.doAfter(
            notification_duration,
            function()
                if notification_canvas then
                    notification_canvas:delete()
                    notification_canvas = nil
                end
                notification_timer = nil
            end
        )
    end
end


function show_volume_bar(volume, icon_names, bar_color)
    local screen_frame = screen_frame()
    local bar_width = 600
    local bar_height = 40

    if volume_timer then
        volume_timer:stop()
        volume_timer = nil
    end
    if volume_canvas then
        volume_canvas:delete()
    end

    local icon_image = composite_image_from_file(icon_names)
    local icon_height = icon_image and icon_image:size().h or 128
    volume_canvas = hs.canvas.new({
        x = (screen_frame.w - bar_width) / 2,
        y = screen_frame.h * 0.8 - icon_height - 10,
        w = bar_width,
        h = bar_height + icon_height + 10
    })

    -- bar background
    volume_canvas[1] = {
        type = "rectangle",
        action = "fill",
        frame = {
            x = 0,
            y = icon_height + 10,
            w = bar_width,
            h = bar_height
        },
        fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.8 },
        roundedRectRadii = { xRadius = 10, yRadius = 10 }
    }

    -- bar progress
    volume_canvas[2] = {
        type = "rectangle",
        action = "fill",
        frame = {
            x = 2,
            y = icon_height + 12,
            w = (volume / 100) * (bar_width - 4),
            h = bar_height - 4
        },
        fillColor = bar_color,
        roundedRectRadii = { xRadius = 8, yRadius = 8 }
    }

    if icon_image then
        local icon_size = icon_image:size()
        volume_canvas[3] = {
            type = "image",
            image = icon_image,
            frame = {
                x = (bar_width - icon_size.w) / 2,
                y = 0,
                w = icon_size.w,
                h = icon_size.h
            }
        }
    end

    volume_canvas:show()
    volume_timer = hs.timer.doAfter(
        notification_duration,
        function()
            if volume_canvas then
                volume_canvas:delete()
                volume_canvas = nil
            end
            volume_timer = nil
        end
    )
end


function get_audio_mute_state()
    local output_device = hs.audiodevice.defaultOutputDevice()
    if output_device then
        return output_device:outputMuted()
    end
    return false
end


function get_microphone_mute_state()
    local input_device = hs.audiodevice.defaultInputDevice()
    if input_device then
        return input_device:inputMuted()
    end
    return false
end
