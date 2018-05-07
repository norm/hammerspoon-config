require "mover"

-- standard "terminal in the middle" split
mover:bind('',      '1', function() resize_to(0,    23, 875,  768) end )
mover:bind('shift', '1', function() resize_to(0,    23, 490,  768) end )
mover:bind('',      '2', function() resize_to(876,  23, 490,  768) end )
mover:bind('shift', '2', function() resize_to(491,  23, 875,  768) end )
