-- personal colour palette definitions

require "colours"
require "console_debug"


palette_norman = {
    { name = 'Blackcurrant', hex = '#1d0322' },
    { name = 'Cognac', hex = '#9f481b' },
    { name = 'Cosmic', hex = '#7b3c58' },
    { name = 'Desert Storm', hex = '#efeeec' },
    { name = 'Eerie Black', hex = '#1e1b1d' },
    { name = 'Kimberly', hex = '#7373a9' },
    { name = 'Limed Spruce', hex = '#33484f' },
    { name = 'Nevada', hex = '#5c7178' },
    { name = 'Olivine', hex = '#93bf8a' },
    { name = 'Opal', hex = '#acc9c8' },
    { name = 'Pearly Purple', hex = '#bf6b8d' },
    { name = 'Pomodoro', hex = '#c30232' },
    { name = 'Roti', hex = '#bea13e' },
    { name = 'Skeptic', hex = '#bfe3d5' },
    { name = 'Te Papa Green', hex = '#1e333a' },
    { name = 'Waterloo', hex = '#7a7f8f' },

    -- alias names
    { name = 'Alert', alias = 'Pomodoro' },
    { name = 'Dark Purple', alias = 'Blackcurrant' }
}


for _, entry in ipairs(palette_norman) do
    if entry.hex then
        local colour = hex_to_hammerspoon_colour(entry.hex)
        if colour then
            add_hammerspoon_colour(entry.name, colour)
        else
            console_debug('palette', 'unknown value for ' .. entry.name)
        end
    elseif entry.alias then
        local target_hex = nil
        for _, target_def in ipairs(palette_norman) do
            if string.lower(target_def.name) == string.lower(entry.alias) and target_def.hex then
                target_hex = target_def.hex
                break
            end
        end
        if target_hex then
            local target_colour = hex_to_hammerspoon_colour(target_hex)
            if target_colour then
                add_hammerspoon_colour(entry.name, target_colour)
            else
                console_debug('palette', 'unknown value for ' .. entry.name)
            end
        else
            console_debug(
                'palette',
                string.format('unknown alias %s for %s', entry.alias, entry.name)
            )
        end
    end
end
