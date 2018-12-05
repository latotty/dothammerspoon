
function changeToNextKeyboardLanguage()
  local current = hs.keycodes.currentLayout()
  local layouts = hs.keycodes.layouts()
  
  local index = 1
  for k,v in pairs(layouts) do
    if v == current then
      index = k
    end
  end
  
  local newIndex = ((index - 1 + 1) % #layouts) + 1
  
  hs.keycodes.setLayout(layouts[newIndex])
end

hs.hotkey.bind(hyper, "space", changeToNextKeyboardLanguage)