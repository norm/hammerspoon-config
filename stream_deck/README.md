# Stream Deck hammerspoon control

This is heavily influenced by
[Peter Hajas's post](https://peterhajas.com/blog/streamdeck/) and
[code](https://github.com/peterhajas/dotfiles/tree/master/hammerspoon/.hammerspoon)
-- except that I don't like camelCase and I reengineered the button handling
to have one central loop rather than individual timers on each button.

Buttons are tables:

```lua
function example_button()
    return {
        ['name'] = 'Example Button',
        ['initialise'] = function()
            -- create the initial button state
            return { timers = {} }
        end,
        ['update_state'] = function(button)
            -- called every second (also see update_every below)
            -- to refresh the current button state if it is dynamic
            stream_deck_update_button_state(
                button['name'],
                { timers = {next=1} }
            )
        end,
        ['image'] = function()
            -- if the button has a static image
            return button_image_from_file({'mac.png', 'mac_select.png'})
        end,
        ['get_image'] = function(state)
            -- if the button has a dynamic image that changes based on state
            return draw_timer_button_image(active_timers, finished)
        end,
        ['pressed'] = function()
            -- executed when the button is pressed and let go
            print('boop!')
        end,
        ['held'] = function
            -- executed when the button is held for at least 0.3 seconds
            --  before being letting go
            print('boooooop!')
        end,
        -- update_state every second, set this for every n seconds
        ['update_every'] = 5
    }
end
```

that are added to panels:

```lua
local home_buttons = {}
home_buttons[1] = example_button()

on_stream_deck_ready(
    function(deck)
        stream_deck_home_panel(
            stream_deck_create_panel(home_buttons)
        )
    end
)
```

Once added to a visible panel, every second (or every `upate_every` seconds)
the button's `update_state` is run. If state changes mean redrawing the
button, the button itself is responsible for making that happen by calling
`stream_deck_update_button_state`. This will check the new state against the
cached previous state, and if different call the `get_image` function on the
button to update the image.

If the button is no longer visible (a subpanel has been opened) `update_state`
is still called, but the button will not be redrawn. This is useful if a
button needs to countdown a timer, for example.


## Visual patterns

A button is a control, but it can also be a status indicator. Where the button
a toggle between two (or more) stats such as mute/unmute, the visual
representation informs you of the **current** state.

A panel is an array of buttons. A button can trigger opening a new panel
(replace all of the visible buttons) or an overlay (replace some). Opened
panels and overlays must always have a back button in a predictable location.

When a button controls something that has a most-often action but also other
less-frequently used options (such as a light, most commonly turn it on and
off, but you can also adjust brightness and colour) then the pressing the
button does the common action, holding the button opens a new panel or overlay
with the other options.
