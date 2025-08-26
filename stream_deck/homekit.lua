-- Stream Deck control buttons for HomeKit scenes

-- Hammerspoon can't control homekit, so a workaround is to create a control
-- in Shortcuts called "Set scene ___" that sets the scene. Tedious, I know.
function set_homekit_scene(scene_name)
    local shortcut_name = "Set scene " .. scene_name
    console_debug(
        "homekit:scene",
        string.format("Running shortcut '%s'", shortcut_name)
    )
    hs.shortcuts.run(shortcut_name)
end


function set_homekit_scene_button(scene_name, image)
    return {
        ['name'] = scene_name,
        ['image'] = image_from_elements(image),
        ['pressed'] = function()
            set_homekit_scene(scene_name)
        end
    }
end
