require "mover"

-- standard "terminal in the middle" split
mover:bind('',      'z', function() resize_to(0,    38,  610,  944) end )
mover:bind('shift', 'z', function() resize_to(0,    38,  901,  944) end )
mover:bind('',      'x', function() resize_to(611,  38,  901,  944) end )
mover:bind('shift', 'x', function() resize_to(902,  38,  610,  944) end )
