function moveFocusedWindowToUnit(unit)
  return function ()
    local win = hs.window.focusedWindow();
    if not win then
      return
    end
    win:moveToUnit(unit)
  end
end

function moveWindowToNextScreen()
  local win = hs.window.focusedWindow();
  if not win then
    return
  end
  win:moveToScreen(win:screen():next())
end

hs.hotkey.bind(hyper, "h", moveFocusedWindowToUnit(hs.layout.left50))
hs.hotkey.bind(hyper, "j", moveFocusedWindowToUnit(hs.layout.maximized))
hs.hotkey.bind(hyper, "k", moveWindowToNextScreen)
hs.hotkey.bind(hyper, "l", moveFocusedWindowToUnit(hs.layout.right50))

hs.hotkey.bind(hyper, "y", moveFocusedWindowToUnit(hs.layout.left30))
hs.hotkey.bind(hyper, "u", moveFocusedWindowToUnit(hs.layout.left70))
hs.hotkey.bind(hyper, "i", moveFocusedWindowToUnit('[30,0,70,100]'))
hs.hotkey.bind(hyper, "o", moveFocusedWindowToUnit(hs.layout.right70))
hs.hotkey.bind(hyper, "p", moveFocusedWindowToUnit(hs.layout.right30))
