local qa_task = nil

hs.hotkey.bind({"shift"}, "Tab", function()
    if not qa_task or not qa_task:isRunning() then
        -- First press or daemon died → launch fresh
        if qa_task then qa_task = nil end
        qa_task = hs.task.new(
            "/Applications/kitty.app/Contents/MacOS/kitten",
            nil,
            {"quick-access-terminal"}
        )
        qa_task:start()
    else
        -- Daemon is running → send toggle signal
        hs.execute("/Applications/kitty.app/Contents/MacOS/kitten quick-access-terminal", true)
    end
end)