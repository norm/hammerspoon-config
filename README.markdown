# Hammerspoon configuration

My [hammerspoon](http://www.hammerspoon.org) configuration.
Feel free to borrow/steal.

## `mover`

The `mover` module is a lightweight copy of an old OS X program I used
called [MercuryMover](http://www.heliumfoot.com/mercurymover), now sadly
defunct.

Hitting Function-Command-Up (Command-Pageup on a full-width keyboard) starts
the movement mode, where up/down/left/right will move the active window about
in 10 pixel increments. Hold Shift to move by 1 pixel, Option to move by 100
pixels, and Command to move to the screen edge. The Equals key will center the
window, and Plus (Shift-Equals) will resize the window to the size of the
screen.

Hitting Function-Command-Right (Command-End) starts the resize to the right
mode, where up/down/left/right will resize the window from the bottom/right
edges.

Hitting Function-Command-Left (Command-Home) starts the resize to the left
mode, where up/down/left/right will resize the window from the top/left
edges.

## `init.lua`

As each computer I use this on may have subtly different `mover`
requirements, I create `init.lua` as a symlink to the right
`$HOSTNAME.lua` file on installation.
