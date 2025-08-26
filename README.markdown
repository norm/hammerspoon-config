# Hammerspoon configuration

My [hammerspoon](http://www.hammerspoon.org) configuration.
Feel free to borrow/steal.

## Stream Deck controls

See the [README in the stream_deck directory](stream_deck/README.md).

![A photo of my Stream Deck showing my button configuration](deck.jpg)


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

