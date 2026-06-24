--- === HotkeyApps===
---
--- Quickly ensure access to apps in the current Space via hotkeys.
---
--- Download: https://github.com/adammillerio/Spoons/raw/main/Spoons/HotkeyApps.spoon.zip
---
--- README with Example Usage: [README.md](https://github.com/adammillerio/HotkeyApps.spoon/blob/main/README.md)
local HotkeyApps = {}

HotkeyApps.__index = HotkeyApps

-- Metadata
HotkeyApps.name = "HotkeyApps"
HotkeyApps.version = "0.0.2"
HotkeyApps.author = "Adam Miller <adam@adammiller.io>"
HotkeyApps.homepage = "https://github.com/adammillerio/HotkeyApps.spoon"
HotkeyApps.license = "MIT - https://opensource.org/licenses/MIT"

-- Dependency Spoons
-- EnsureApp is used for handling app movements when showing/hiding.
EnsureApp = spoon.EnsureApp

--- HotkeyApps.modifierMap
--- Constant
--- Key used for persisting space names between Hammerspoon launches via hs.settings.
--- Mapping of modifier keys to their left/right event masks.
HotkeyApps.modifierFlagMap = {
    ["cmd"] = {
        left = hs.eventtap.event.rawFlagMasks.deviceLeftCommand,
        right = hs.eventtap.event.rawFlagMasks.deviceRightCommand
    },
    ["shift"] = {
        left = hs.eventtap.event.rawFlagMasks.deviceLeftShift,
        right = hs.eventtap.event.rawFlagMasks.deviceRightShift
    },
    ["ctrl"] = {
        left = hs.eventtap.event.rawFlagMasks.deviceLeftControl,
        right = hs.eventtap.event.rawFlagMasks.deviceRightControl
    },
    ["alt"] = {
        left = hs.eventtap.event.rawFlagMasks.deviceLeftAlternate,
        right = hs.eventtap.event.rawFlagMasks.deviceRightAlternate
    }
}

--- HotkeyApps.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log
--- level for the messages coming from the Spoon.
HotkeyApps.logger = nil

--- HotkeyApps.logLevel
--- Variable
--- HotkeyApps specific log level override, see hs.logger.setLogLevel for options.
HotkeyApps.logLevel = nil

HotkeyApps.leftChord = "cmd"
HotkeyApps.rightChord = "cmd"

HotkeyApps.leftChordFlag = nil
HotkeyApps.rightChordFlag = nil

HotkeyApps.nonChordedHotkeys = nil
HotkeyApps.leftChordHotkeys = nil
HotkeyApps.rightChordHotkeys = nil

HotkeyApps.flagsChangedEventTap = nil

HotkeyApps.leftChordActive = false
HotkeyApps.rightChordActive = false

--- HotkeyApps:init()
--- Method
--- Spoon initializer method for EnsureApp.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function HotkeyApps:init()
    self.nonChordedHotkeys = {}
    self.leftChordHotkeys = {}
    self.rightChordHotkeys = {}
end

-- Utility method for having instance specific callbacks.
-- Inputs are the callback fn and any arguments to be applied after the instance
-- reference.
function HotkeyApps:_instanceCallback(callback, ...)
    return hs.fnutils.partial(callback, self, ...)
end

--- HotkeyApps:bindHotkeys(mapping)
--- Method
--- Bind method, binds all provided hotkeys to their app ensure callbacks.
---
--- Parameters:
---  * mapping - Table of app -> hotkey mappings where app is the name of the
---    app in the EnsureApps config.
--- Returns:
---  * None
function HotkeyApps:bindHotkeys(mapping)
    -- Enable toggling of show/hide for all app hotkeys.
    local actionConfig = {toggle = true}

    -- Bind each hotkey to the ensure callback for the app.
    for app, hotkey in pairs(mapping) do
        local hotkeyChord = hotkey[3]

        -- This is not a chorded input.
        if hotkeyChord == nil or hotkeyChord == "both" then
            -- Chorded hotkeys can be created and enabled, they have no special
            -- logic.
            local appHotkey = hs.hotkey.new(hotkey[1], hotkey[2],
                                            EnsureApp:ensureAppCallback(app,
                                                                        actionConfig))
            appHotkey:enable()

            self.nonChordedHotkeys[app] = appHotkey
            -- This is a left chord input.
        elseif hotkeyChord == "left" then
            if self.nonChordedHotkeys[app] then
                self.logger.ef(
                    "Non-chorded hotkey for app %s already exists, cannot create left chorded hotkey",
                    app)
            end

            -- Chorded hotkeys are created, but enabled only when the cord is
            -- down in the eventtap _flagsChanged handler.
            self.leftChordHotkeys[app] =
                hs.hotkey.new(hotkey[1], hotkey[2],
                              EnsureApp:ensureAppCallback(app, actionConfig))
            -- This is a right chord input.
        elseif hotkeyChord == "right" then
            if self.nonChordedHotkeys[app] then
                self.logger.ef(
                    "Non-chorded hotkey for app %s already exists, cannot create right chorded hotkey",
                    app)
            end

            -- Chorded hotkeys are created, but enabled only when the cord is
            -- down in the eventtap _flagsChanged handler.
            self.rightChordHotkeys[app] =
                hs.hotkey.new(hotkey[1], hotkey[2],
                              EnsureApp:ensureAppCallback(app, actionConfig))
        end
    end

    -- Bind generated hotkey spec.
    -- hs.spoons.bindHotkeysToSpec(hotkeyBindings, mapping)
end

function HotkeyApps:_flagsChanged(event)
    self.logger.vf("Received flag change event: %s", hs.inspect(event))
    local flags = event:rawFlags()
    if flags & self.leftChordFlag > 0 then
        if not self.leftChordActive then
            self.logger.v("Enabling left chord")
            for _, hotkey in pairs(self.leftChordHotkeys) do
                hotkey:enable()
            end

            self.leftChordActive = true
        end
    elseif flags & self.rightChordFlag > 0 then
        if not self.rightChordActive then
            self.logger.v("Enabling right chord")
            for _, hotkey in pairs(self.rightChordHotkeys) do
                hotkey:enable()
            end

            self.rightChordActive = true
        end
    else
        if self.leftChordActive then
            self.logger.v("Disabling left chord")
            for _, hotkey in pairs(self.leftChordHotkeys) do
                hotkey:disable()
            end

            self.leftChordActive = false
        end

        if self.rightChordActive then
            self.logger.v("Disabling right chord")
            for _, hotkey in pairs(self.rightChordHotkeys) do
                hotkey:disable()
            end

            self.rightChordActive = false
        end
    end
end

function HotkeyApps:start()
    -- Start logger, this has to be done in start because it relies on config.
    self.logger = hs.logger.new("HotkeyApps")

    if self.logLevel ~= nil then self.logger.setLogLevel(self.logLevel) end

    self.logger.v("Starting HotkeyApps")

    -- Look up the flags for the selected modifier chords in the flag map.
    self.leftChordFlag = self.modifierFlagMap[self.leftChord].left
    self.rightChordFlag = self.modifierFlagMap[self.rightChord].right

    self.logger.v("Starting flagsChanged EventTap listener")
    self.flagsChangedEventTap = hs.eventtap.new({
        hs.eventtap.event.types.flagsChanged
    }, self:_instanceCallback(self._flagsChanged))
    self.flagsChangedEventTap:start()
end

function HotkeyApps:stop() self.logger.v("Stopping HotkeyApps") end

return HotkeyApps
