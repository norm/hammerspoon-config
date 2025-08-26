-- colour palettes, builtin and user defined


function hammerspoon_colour(colour)
    -- look up a colour by name
    if not colour or type(colour) ~= "string" then
        error("hammerspoon_colour expects a colour name")
        return hs.drawing.color.x11.gray
    end

    local colour = string.lower(colour)
    local collections = {}

    if hs.drawing.color.hammerspoon then
        table.insert(collections, hs.drawing.color.hammerspoon)
    end
    table.insert(collections, hs.drawing.color.x11)
    for name, collection in pairs(hs.drawing.color.lists()) do
        table.insert(collections, collection)
    end

    for _, collection in ipairs(collections) do
        if collection then
            for colour_name, value in pairs(collection) do
                if string.lower(colour_name) == colour then
                    return value
                end
            end
        end
    end
    error("colour " .. colour .. " not found")
end


function add_hammerspoon_colour(name, colour)
    -- adds new colour to the custom colours (which are searched first)
    if not name or type(name) ~= "string" then
        error("colour name must be a string")
    end
    if (
        not colour
        or type(colour) ~= "table"
        or not colour.red
        or not colour.green
        or not colour.blue
    ) then
        error("colour value expects a table of red, green, blue, alpha")
    end
    hs.drawing.color.hammerspoon[name] = colour
    console_debug(
        'hammerspoon:colours',
        string.format(
            "Added colour %s = {r=%.3f, g=%.3f, b=%.3f, a=%.3f}",
            name,
            colour.red,
            colour.green,
            colour.blue,
            colour.alpha
        )
    )
end


function generate_colour(...)
    -- generate a random colour from the input using FNV-1a:
    -- https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function
    local function fnv1a_hash(data)
        local hash = 2166136261
        for char in data:gmatch('.') do
            hash = hash ~ string.byte(char)
            hash = (hash * 16777619) % 4294967296
        end
        return hash % 16777215
    end

    local data_string = ""
    for _, arg in ipairs({...}) do
        data_string = data_string .. tostring(arg)
    end
    data_string = data_string

    return hex_to_hammerspoon_colour(string.format("%06x", fnv1a_hash(data_string)))
end


function hex_to_hammerspoon_colour(hex)
    local r, g, b, a

    if not hex or type(hex) ~= "string" then
        error("hex_to_hammerspoon_colour expects hex string")
    end
    if hex:sub(1,1) == "#" then
        hex = hex:sub(2)
    end
    if #hex == 8 then
        -- RGBA in hexadecimal
        r = tonumber(hex:sub(1,2), 16)
        g = tonumber(hex:sub(3,4), 16)
        b = tonumber(hex:sub(5,6), 16)
        a = tonumber(hex:sub(7,8), 16)
    elseif #hex == 6 then
        -- RGB in hexadecimal
        r = tonumber(hex:sub(1,2), 16)
        g = tonumber(hex:sub(3,4), 16)
        b = tonumber(hex:sub(5,6), 16)
        a = 255
    elseif #hex == 3 then
        -- CSS-style RGB as three hexadecimal shorthand (#39c)
        r = tonumber(hex:sub(1,1) .. hex:sub(1,1), 16)
        g = tonumber(hex:sub(2,2) .. hex:sub(2,2), 16)
        b = tonumber(hex:sub(3,3) .. hex:sub(3,3), 16)
        a = 255
    end

    if not r or not g or not b or not a then
        return nil
    end
    return { red = r / 255, green = g / 255, blue = b / 255, alpha = a / 255 }
end
