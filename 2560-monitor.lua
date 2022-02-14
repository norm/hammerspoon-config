require "mover"

-- standard "terminal in the middle" split
mover:bind('',      '1', function() resize_to(0,    23, 1160, 1440) end )
mover:bind('shift', '1', function() resize_to(0,    23, 1040, 1440) end )
mover:bind('',      '2', function() resize_to(1161, 23, 490,  1440) end )
mover:bind('shift', '2', function() resize_to(1161, 23, 908,  1440) end )
mover:bind('',      '3', function() resize_to(1652, 23, 908,  1440) end )
mover:bind('shift', '3', function() resize_to(2070, 23, 490,  1440) end )
mover:bind('',      'q', function() resize_to(0,    23, 1651, 1440) end )

-- larger terminals
mover:bind('',      '-', function() resize_to(1652, 23, 610,  1440) end )
mover:bind('shift', '-', function() resize_to(1652, 23, 730,  1440) end )
mover:bind('',      '0', function() resize_to(1041, 23, 610,  1440) end )
mover:bind('shift', '0', function() resize_to(921,  23, 730,  1440) end )
mover:bind('',      '9', function() resize_to(430,  23, 610,  1440) end )
mover:bind('shift', '9', function() resize_to(190,  23, 730,  1440) end )
mover:bind('',      '8', function() resize_to(0,    23, 919,  1440) end )
mover:bind('shift', '8', function() resize_to(10,   23, 1030, 1440) end )

-- 7/10 split
mover:bind('',      '[', function() resize_to(0,    23, 1280, 1440) end )
mover:bind('',      ']', function() resize_to(1281, 23, 1279, 1440) end )
mover:bind('option','2', function() resize_to(1281, 23, 490,  1440) end )


-- YouTube
mover:bind('',      'y', function() resize_to(256,  23, 2048, 1440) end )

-- Things
mover:bind('',      't', function() resize_to(132,  23, 908, 1440) end )
