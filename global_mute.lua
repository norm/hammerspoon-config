function toggle_global_mute()
    local mic = hs.audiodevice.defaultInputDevice()
    local state = not mic:muted()

    hs.fnutils.each(
        hs.audiodevice.allInputDevices(),
        function(device) device:setInputMuted(state) end
    )

    if mic:muted() then
        hs.alert('Muted')
    else
        hs.alert('Unmuted')
    end
end
