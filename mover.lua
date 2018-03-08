function move_by(x, y)
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = hs.screen.mainScreen():fullFrame()

    -- don't allow windows to move offscreen
    frame.x = math.min( math.max(frame.x + x, 0), screen.w - frame.w )
    frame.y = math.min( math.max(frame.y + y, 0), screen.h - frame.h )
    window:setFrame(frame)
end

function move_to(x, y)
    local window = hs.window.focusedWindow()
    local frame = window:frame()

    frame.x = x
    frame.y = y
    window:setFrame(frame)
end

function center()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = hs.screen.mainScreen():fullFrame()

    frame.x = math.floor((screen.w - frame.w) / 2)
    frame.y = math.floor((screen.h - frame.h) / 2)
    window:setFrame(frame)
end

function resize_right(w, h) 
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = hs.screen.mainScreen():fullFrame()

    -- no further than the edge of the screen
    frame.w = math.min(frame.w + w, screen.w)
    frame.h = math.min(frame.h + h, screen.h)
    window:setFrame(frame)
end

function resize_left(w, h) 
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = hs.screen.mainScreen():fullFrame()

    -- no further than the edge of the screen
    w = math.min(w, frame.x)
    h = math.min(h, frame.y)

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
    local screen = hs.screen.mainScreen():fullFrame()

    frame.x = 0
    frame.y = 0
    frame.w = screen.w
    frame.h = screen.h
    window:setFrame(frame)
end

function debug_position()
    local window = hs.window.focusedWindow()
    local frame = window:frame()
    local screen = hs.screen.mainScreen():fullFrame()

    hs.alert.show(frame, 5)
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
mover:bind('',      'p',      function() debug_position()       end )


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

size_right:bind('',      'escape', function() size_right:exit()       end )
size_right:bind('shift', 'left',   function() resize_right(-1, 0)     end )
size_right:bind('',      'left',   function() resize_right(-10, 0)    end )
size_right:bind('alt',   'left',   function() resize_right(-100, 0)   end )
size_right:bind('shift', 'right',  function() resize_right(1, 0)      end )
size_right:bind('',      'right',  function() resize_right(10, 0)     end )
size_right:bind('alt',   'right',  function() resize_right(100, 0)    end )
size_right:bind('cmd',   'right',  function() resize_right(10000, 0)  end )
size_right:bind('shift', 'up',     function() resize_right(0, -1)     end )
size_right:bind('',      'up',     function() resize_right(0, -10)    end )
size_right:bind('alt',   'up',     function() resize_right(0, -100)   end )
size_right:bind('shift', 'down',   function() resize_right(0, 1)      end )
size_right:bind('',      'down',   function() resize_right(0, 10)     end )
size_right:bind('alt',   'down',   function() resize_right(0, 100)    end )
size_right:bind('cmd',   'down',   function() resize_right(0, 10000)  end )
size_right:bind('',      '=',      function() center()                end )
size_right:bind('shift', '=',      function() maximise()              end )


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

size_left:bind('',      'escape', function() size_left:exit()         end )
size_left:bind('shift', 'left',   function() resize_left(1, 0)        end )
size_left:bind('',      'left',   function() resize_left(10, 0)       end )
size_left:bind('alt',   'left',   function() resize_left(100, 0)      end )
size_left:bind('cmd',   'left',   function() resize_left(10000, 0)    end )
size_left:bind('shift', 'right',  function() resize_left(-1, 0)       end )
size_left:bind('',      'right',  function() resize_left(-10, 0)      end )
size_left:bind('alt',   'right',  function() resize_left(-100, 0)     end )
size_left:bind('shift', 'up',     function() resize_left(0, 1)        end )
size_left:bind('',      'up',     function() resize_left(0, 10)       end )
size_left:bind('alt',   'up',     function() resize_left(0, 100)      end )
size_left:bind('cmd',   'up',     function() resize_left(0, 10000)    end )
size_left:bind('shift', 'down',   function() resize_left(0, -1)       end )
size_left:bind('',      'down',   function() resize_left(0, -10)      end )
size_left:bind('alt',   'down',   function() resize_left(0, -100)     end )
size_left:bind('',      '=',      function() center()                 end )
size_left:bind('shift', '=',      function() maximise()               end )
