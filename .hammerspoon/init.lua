-- Kitty quake-style with dropdown window
hs.hotkey.bind({"shift"}, "Tab", function()
  local app = hs.application.get("net.kovidgoyal.kitty-quick-access")
  if app then
    if app:isHidden() then
      app:activate()        -- hidden → show it
    else
      app:hide()            -- visible (frontmost or not) → hide it
    end
  else
    hs.execute("open /Applications/kitty.app/Contents/kitty-quick-access.app")
  end
end)