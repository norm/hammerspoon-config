-- debugging helpers, primarily for diagnosing problems in button
-- interactions, where leaving the debugging in place but turning it
-- on or off at runtime is helpful

local console_debug_matchers = {}


local function load_debug_matchers()
    console_debug_matchers = hs.settings.get("console_debug_matchers") or {}
end

load_debug_matchers()


local function save_debug_matchers()
    set_permanent_value("console", "console_debug_matchers", console_debug_matchers)
end


function set_permanent_value(category, key, value)
    local value_str
    if type(value) == "table" then
        value_str = hs.inspect(value)
    else
        value_str = tostring(value)
    end
    console_debug("hammerspoon_state:" .. category, 'Saving ' .. key .. ' = ' .. value_str)
    hs.settings.set(key, value)
end


local function name_matches(name)
    for pattern in pairs(console_debug_matchers) do
        local lua_pattern = pattern:gsub('%*', '.*')
        if name:match('^' .. lua_pattern) then
            return true
        end
    end
    return false
end


function console_debug(name, ...)
    if name_matches(name) then
        local args = {...}
        local content = ""

        for i, arg in ipairs(args) do
            if type(arg) == "table" then
                content = content .. " " .. hs.inspect(arg)
            else
                content = content .. " " .. tostring(arg)
            end
        end

        print(string.format("[%s] %s", name, content))
    end
end


function enable_console_debug(pattern)
    if pattern == nil then
        pattern = "*"
    end

    console_debug_matchers[pattern] = true

    save_debug_matchers()
end


function disable_console_debug(pattern)
    if pattern == nil then
        console_debug_matchers = {}
    else
        console_debug_matchers[pattern] = nil
    end

    save_debug_matchers()
end


function toggle_console_debug(pattern)
    if pattern == nil then
        pattern = "*"
    end

    if console_debug_matchers[pattern] then
        disable_console_debug(pattern)
    else
        enable_console_debug(pattern)
    end
end


function show_console_debug()
    print(hs.inspect(console_debug_matchers))
    if console_debug_matchers == {} then
        print("  no debug patterns")
    else
        for name in pairs(console_debug_matchers) do
            print(string.format("  %s", name))
        end
    end
end
