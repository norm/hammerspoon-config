require "mover"

-- standard "terminal in the middle" split
mover:bind('',      '1', function() resize_to(0,    23, 1160, 1440) end )
mover:bind('',      '2', function() resize_to(1161, 23, 490,  1440) end )
mover:bind('shift', '2', function() resize_to(1161, 23, 908,  1440) end )
mover:bind('',      '3', function() resize_to(1652, 23, 908,  1440) end )
mover:bind('shift', '3', function() resize_to(2070, 23, 490,  1440) end )
mover:bind('',      'q', function() resize_to(0,    23, 1651, 1440) end )


-- 7/10 split
mover:bind('',      '[', function() resize_to(0,    23, 1280, 1440) end )
mover:bind('',      ']', function() resize_to(1281, 23, 1279, 1440) end )
mover:bind('',      't', function() resize_to(1281, 23, 490,  1440) end )

