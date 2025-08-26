-- Stream Deck control buttons for stepping through lists of effects


function list_step_button(button_name, default_icons, scenes)
    return {
        ['name'] = button_name,
        ['initialise'] = function()
            return { index = 0 }
        end,
        ['get_image'] = function(state)
            if state['index'] == 0 then
                return image_from_elements(default_icons)
            end
            return image_from_elements(scenes[state['index']].image)
        end,
        ['pressed'] = function(state)
            local new_index = state['index'] + 1
            if new_index > #scenes then new_index = 1 end
            console_debug(
                'stream_deck:list_step',
                'Button pressed, triggering state ' .. new_index
            )

            scenes[new_index].callback()
            stream_deck_update_button_state(button_name, {index = new_index})
        end,
        ['update_every'] = 60,
    }
end
