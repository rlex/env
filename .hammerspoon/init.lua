-- Kitty quick terminal - with async launch and proper quick terminal support
local kitty_task = nil
hs.hotkey.bind({"shift"}, "Tab", function()
    if not kitty_task or not kitty_task:isRunning() then
        -- First press or daemon died => launch fresh
        if kitty_task then kitty_task = nil end
        kitty_task = hs.task.new(
            "/Applications/kitty.app/Contents/MacOS/kitten",
            nil,
            {"quick-access-terminal"}
        )
        -- Since it's launched from hammerspoon, default cwd will be ~/.hammerspoon
        kitty_task:setWorkingDirectory(os.getenv("HOME"))
        kitty_task:start()
    else
        -- Daemon is running => send toggle signal
        hs.execute("/Applications/kitty.app/Contents/MacOS/kitten quick-access-terminal", true)
    end
end)