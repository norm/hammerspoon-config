--[[

## mover.lua

A Hammerspoon script to move/resize windows purely from the keyboard, as a
replacement for an old OS X program I used called
[MercuryMover](https://web.archive.org/web/20230307035103/http://www.heliumfoot.com/mercurymover/),
now sadly defunct. To use it, copy the `mover.lua` file into your
`.hammerspoon` directory and add `require "mover"` to your configuration.

### Move the window

Hitting Function+Command+Up (Command+Pageup on a full-width keyboard) starts
the movement mode.

**Move within display** The cursor keys will move the active window, and the
amount it moves changes depending on the modifier key you are holding:

| Modifier | Movement            |
| -------- | ------------------- |
| Shift    | 1 pixel             |
|          | 10 pixels           |
| Option   | 100 pixels          |
| Command  | to the display edge |

**Move to another display** When a side of the window is at the display's
edge, hitting *Command+Cursor* will move the window to the next display in
that direction if there is one.

**Centre in display** Pressing the equals key will centre the window in the
current display.

**Fill display** Pressing the plus key (Shift+equals) will resize the window
to fill the display (note, this is different from either macOS's Maximise or
Zoom functions).

**Show frame size** Pressing the minus key will display text showing the
current top, left, width, and height of the window.

### Resize the window

**Resize right and/or down** Hitting Function+Command+Right (Command+End)
starts the resize mode, anchored on the bottom-right corner of the window.

**Resize left and/or up** Hitting Function+Command+Left (Command+Home) starts
the resize mode, anchored on the top-left corner of the window.

The cursor keys will move the relevant side of the window. The different
amounts the window resizes by when modifiers are held is the same as it is for
movement.

### Specific sizes

As well as on-demand sizing of windows, you can create predefined size and
placement rules for windows in your Hammerspoon configuration by adding a
[`hs.hotkey.modal.bind`](https://www.hammerspoon.org/docs/hs.hotkey.modal.html#bind)
function onto the `mover` modal, like so:

    mover:bind(
        'shift',
        '1',
        function() resize_to(0, 0, 1160, 1440) end
    )

The first argument is what modifiers are being held. The second argument is
the keypress. The third argument is the function to run when the key is
pressed, typically an anonymous function to call `resize_to(top, left, width,
height)` as shown.

You could create "left-half" and "right-half" sizes for your main display, for
example. I like to have keys that place my text editor, terminal window, and
web browser to fill my display without gaps.

]]

function get_current_screen()
    local window_frame = hs.window.focusedWindow():frame()
    local current_screen = hs.screen.mainScreen()
    local screen_frame

    for i, check_screen in ipairs(hs.screen.allScreens()) do
        screen_frame = check_screen:fullFrame()

        if (
            screen_frame.x <= window_frame.x and
            window_frame.x <= (screen_frame.x + screen_frame.w - 1) and
            screen_frame.y <= window_frame.y and
            window_frame.y <= (screen_frame.y + screen_frame.h - 1)
        ) then
            current_screen = check_screen
        end
    end

    return current_screen
end

function move_by(x, y)
    -- move a window relative to its current position
    local window = hs.window.focusedWindow()
    local window_frame = window:frame()
    local current_screen = get_current_screen()
    local current_screen_frame = current_screen:frame()
    local current_screen_fullframe = current_screen:fullFrame()
    local duration = 0.05

    if x > 100 and y == 0 then
        -- attempting to smash right; when the window is already at the edge
        -- of the screen check for another monitor to move the window into
        duration = 0.2
        local right_edge = window_frame.x + window_frame.w
        if right_edge == (current_screen_frame.x + current_screen_frame.w) then
            for i, scr in ipairs(hs.screen.allScreens()) do
                scr_frame = scr:fullFrame()
                if (
                    scr_frame.x == right_edge and
                        scr_frame.y <= window_frame.y and
                        window_frame.y <= (scr_frame.y + scr_frame.h - 1)
                ) then
                    window_frame.x = scr_frame.x
                end
            end
        else
            window_frame.x = (current_screen_frame.x + current_screen_frame.w) - window_frame.w
        end

    elseif x < -100 and y == 0 then
        -- attempting to smash left...
        duration = 0.2
        local left_edge = window_frame.x
        if left_edge == current_screen_frame.x then
            for i, scr in ipairs(hs.screen.allScreens()) do
                scr_frame = scr:fullFrame()
                if (
                    (scr_frame.x + scr_frame.w) == left_edge and
                        scr_frame.y <= window_frame.y and
                        window_frame.y <= (scr_frame.y + scr_frame.h - 1)
                ) then
                    window_frame.x = (scr_frame.x + scr_frame.w) - window_frame.w
                end
            end
        else
            window_frame.x = current_screen_frame.x
        end

    elseif y < -100 and x == 0 then
        -- attempting to smash up...
        duration = 0.2
        -- allow for the menu bar
        local top_edge = window_frame.y - (current_screen_frame.y - current_screen_fullframe.y)
        if top_edge == current_screen_fullframe.y then
            for i, scr in ipairs(hs.screen.allScreens()) do
                scr_frame = scr:fullFrame()
                if (
                    (scr_frame.y + scr_frame.h) == top_edge and
                        scr_frame.x <= window_frame.x and
                        window_frame.x <= (scr_frame.x + scr_frame.w - 1)
                ) then
                    window_frame.y = (scr_frame.y + scr_frame.h) - window_frame.h
                end
            end
        else
            window_frame.y = current_screen_frame.y
        end

    elseif y > 100 and x == 0 then
        -- attempting to smash down...
        duration = 0.2
        local bottom_edge = window_frame.y + window_frame.h
        if bottom_edge == (current_screen_frame.y + current_screen_frame.h) then
            for i, scr in ipairs(hs.screen.allScreens()) do
                scr_frame = scr:fullFrame()
                if (
                    scr_frame.y == bottom_edge and
                        scr_frame.x <= window_frame.x and
                        window_frame.x <= (scr_frame.x + scr_frame.w - 1)
                ) then
                    window_frame.y = scr_frame.y
                end
            end
        else
            window_frame.y = (current_screen_frame.y + current_screen_frame.h) - window_frame.h
        end

    else
        -- normal movement around screen
        window_frame.x = math.min(
            math.max(window_frame.x + x, current_screen_frame.x),
            current_screen_frame.x + current_screen_frame.w - window_frame.w
        )
        window_frame.y = math.min(
            math.max(window_frame.y + y, current_screen_frame.y),
            (current_screen_frame.y + current_screen_frame.h) - window_frame.h
        )
    end

    window:setFrame(window_frame, duration)
end

function center()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = get_current_screen():frame()

    frame.x = math.floor((screen.w - frame.w) / 2) + screen.x
    frame.y = math.floor((screen.h - frame.h) / 2) + screen.y
    window:setFrame(frame)
end

function resize_bottomright(w, h)
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = get_current_screen():fullFrame()

    -- no further than the edge of the screen
    frame.w = math.min(
        frame.w + w,
        (screen.x + screen.w) - frame.x
    )
    frame.h = math.min(
        frame.h + h,
        (screen.h - screen.y) - frame.y
    )
    window:setFrame(frame)
end

function resize_topleft(w, h)
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = get_current_screen():fullFrame()

    -- no further than the edge of the screen
    w = math.min(w, frame.x - screen.x)
    h = math.min(h, frame.y - screen.y)

    frame.x = frame.x - w
    frame.y = frame.y - h
    frame.w = frame.w + w
    frame.h = frame.h + h
    window:setFrame(frame)
end

function resize_to(x, y, w, h)
    local window = hs.window.focusedWindow()
    local frame = window:frame()

    frame.x = x
    frame.y = y
    frame.w = w
    frame.h = h
    window:setFrame(frame)
end

function maximise()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = get_current_screen():frame()

    frame.x = screen.x
    frame.y = screen.y
    frame.w = screen.w
    frame.h = screen.h
    window:setFrame(frame)
end

function debug_position()
    local frame = hs.window.focusedWindow():frame()
    local text =
        'top=' .. math.floor(frame.y)
        .. ' left=' .. math.floor(frame.x)
        .. ' width=' .. math.floor(frame.w)
        .. ' height=' .. math.floor(frame.h)

    hs.alert.show(text, 5)
end


mover = hs.hotkey.modal.new({"cmd"}, "pageup")      -- pageup = fn+up
size_right = hs.hotkey.modal.new('cmd', 'end')      -- end    = fn+right
size_left = hs.hotkey.modal.new('cmd', 'home')      -- home   = fn+left


function mover:entered()
    size_right:exit()
    size_left:exit()
    hs.alert.closeAll()
    hs.alert.show( "Move windows . . .", 1 )
end

function mover:exited() 
  hs.alert.closeAll() 
  hs.alert.show( "Moving done", 0.5 )
end

mover:bind('',      'escape', function() mover:exit()           end )
mover:bind('shift', 'up',     function() move_by(0, -1)         end )
mover:bind('',      'up',     function() move_by(0, -10)        end )
mover:bind('alt',   'up',     function() move_by(0, -100)       end )
mover:bind('cmd',   'up',     function() move_by(0, -10000)     end )
mover:bind('shift', 'down',   function() move_by(0, 1)          end )
mover:bind('',      'down',   function() move_by(0, 10)         end )
mover:bind('alt',   'down',   function() move_by(0, 100)        end )
mover:bind('cmd',   'down',   function() move_by(0, 10000)      end )
mover:bind('shift', 'left',   function() move_by(-1, 0)         end )
mover:bind('',      'left',   function() move_by(-10, 0)        end )
mover:bind('alt',   'left',   function() move_by(-100, 0)       end )
mover:bind('cmd',   'left',   function() move_by(-10000, 0)     end )
mover:bind('shift', 'right',  function() move_by(1, 0)          end )
mover:bind('',      'right',  function() move_by(10, 0)         end )
mover:bind('alt',   'right',  function() move_by(100, 0)        end )
mover:bind('cmd',   'right',  function() move_by(10000, 0)      end )
mover:bind('',      '=',      function() center()               end )
mover:bind('shift', '=',      function() maximise()             end )
mover:bind('',      '-',      function() debug_position()       end )


function size_right:entered() 
    mover:exit()
    size_left:exit()
    hs.alert.closeAll()
    hs.alert.show( "Resize to the right . . .", 1 )
end

function size_right:exited() 
    hs.alert.closeAll() 
    hs.alert.show( "Resize done", 0.5 )
end

size_right:bind('',      'escape', function() size_right:exit()             end )
size_right:bind('shift', 'left',   function() resize_bottomright(-1, 0)     end )
size_right:bind('',      'left',   function() resize_bottomright(-10, 0)    end )
size_right:bind('alt',   'left',   function() resize_bottomright(-100, 0)   end )
size_right:bind('shift', 'right',  function() resize_bottomright(1, 0)      end )
size_right:bind('',      'right',  function() resize_bottomright(10, 0)     end )
size_right:bind('alt',   'right',  function() resize_bottomright(100, 0)    end )
size_right:bind('cmd',   'right',  function() resize_bottomright(10000, 0)  end )
size_right:bind('shift', 'up',     function() resize_bottomright(0, -1)     end )
size_right:bind('',      'up',     function() resize_bottomright(0, -10)    end )
size_right:bind('alt',   'up',     function() resize_bottomright(0, -100)   end )
size_right:bind('shift', 'down',   function() resize_bottomright(0, 1)      end )
size_right:bind('',      'down',   function() resize_bottomright(0, 10)     end )
size_right:bind('alt',   'down',   function() resize_bottomright(0, 100)    end )
size_right:bind('cmd',   'down',   function() resize_bottomright(0, 10000)  end )
size_right:bind('',      '=',      function() center()                      end )
size_right:bind('shift', '=',      function() maximise()                    end )
size_right:bind('',      '-',      function() debug_position()              end )


function size_left:entered() 
    mover:exit()
    size_right:exit()
    hs.alert.closeAll()
    hs.alert.show( "Resize to the left . . .", 1 )
end

function size_left:exited() 
    hs.alert.closeAll() 
    hs.alert.show( "Resize done", 0.5 )
end

size_left:bind('',      'escape', function() size_left:exit()            end )
size_left:bind('shift', 'left',   function() resize_topleft(1, 0)        end )
size_left:bind('',      'left',   function() resize_topleft(10, 0)       end )
size_left:bind('alt',   'left',   function() resize_topleft(100, 0)      end )
size_left:bind('cmd',   'left',   function() resize_topleft(10000, 0)    end )
size_left:bind('shift', 'right',  function() resize_topleft(-1, 0)       end )
size_left:bind('',      'right',  function() resize_topleft(-10, 0)      end )
size_left:bind('alt',   'right',  function() resize_topleft(-100, 0)     end )
size_left:bind('shift', 'up',     function() resize_topleft(0, 1)        end )
size_left:bind('',      'up',     function() resize_topleft(0, 10)       end )
size_left:bind('alt',   'up',     function() resize_topleft(0, 100)      end )
size_left:bind('cmd',   'up',     function() resize_topleft(0, 10000)    end )
size_left:bind('shift', 'down',   function() resize_topleft(0, -1)       end )
size_left:bind('',      'down',   function() resize_topleft(0, -10)      end )
size_left:bind('alt',   'down',   function() resize_topleft(0, -100)     end )
size_left:bind('',      '=',      function() center()                    end )
size_left:bind('shift', '=',      function() maximise()                  end )
size_left:bind('',      '-',      function() debug_position()            end )
