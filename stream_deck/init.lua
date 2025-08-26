-- See README.md

stream_deck_button_pixels = 96
stream_deck_system_watcher = nil
current_stream_deck = nil
stream_deck_asleep = false
local deck_ready_callbacks = {}


require "console_debug"
require "stream_deck.buttons"


function on_stream_deck_ready(callback)
    if current_stream_deck ~= nil then
        callback(current_stream_deck)
    else
        table.insert(deck_ready_callbacks, callback)
    end
end


local function stream_deck_ready_callbacks(deck)
    for _, callback in ipairs(deck_ready_callbacks) do
        callback(deck)
    end
    deck_ready_callbacks = {}
end


local function stream_deck_discovery_callback(connected, deck)
    if connected then
        console_debug('stream_deck:discovery', string.format('%s connected', deck))
        current_stream_deck = deck
        deck:buttonCallback(stream_deck_button_pressed)
        deck:reset()
        stream_deck_ready_callbacks(deck)
        stream_deck_start_button_loop()
    else
        console_debug('stream_deck:discovery', string.format('%s disconnected', deck))
        current_stream_deck = nil
    end
end

hs.streamdeck.init(stream_deck_discovery_callback)


function stream_deck_caffeinate_callback(event)
    if event == hs.caffeinate.watcher.screensDidLock then
        stream_deck_lock()
    elseif event == hs.caffeinate.watcher.screensDidSleep then
        stream_deck_sleep()
    elseif event == hs.caffeinate.watcher.screensDidWake then
        -- no-op
    elseif event == hs.caffeinate.watcher.screensDidUnlock then
        on_stream_deck_ready(function(deck)
            stream_deck_unlock()
        end)
    else
        console_debug("stream_deck:caffeinate", "caffeinate callback " .. event)
    end
end

stream_deck_system_watcher = hs.caffeinate.watcher.new(stream_deck_caffeinate_callback)
stream_deck_system_watcher:start()


function stream_deck_lock()
    if current_stream_deck ~= nil then
        console_debug('stream_deck:caffeinate', 'Locking Stream Deck')
        stream_deck_asleep = true
        stream_deck_stop_button_loop()

        for button_index = 1, 15 do
            if button_index == 8 then
                current_stream_deck:setButtonImage(
                    button_index,
                    button_image_from_file({"dark purple", "locked.png"})
                )
            else
                current_stream_deck:setButtonImage(
                    button_index,
                    create_solid_colour("dark purple")
                )
            end
        end
    end
end


function stream_deck_sleep()
    if current_stream_deck ~= nil then
        console_debug('stream_deck:caffeinate', 'Deactivating Stream Deck')
        stream_deck_asleep = true
        stream_deck_stop_button_loop()
        current_stream_deck:setBrightness(0)
    end
end


function stream_deck_unlock()
    if current_stream_deck ~= nil then
        console_debug('stream_deck:unlock', 'Unlocking Stream Deck')
        stream_deck_asleep = false
        stream_deck_render_panel()
        stream_deck_start_button_loop()
        current_stream_deck:setBrightness(stream_deck_brightness)
    end
end
