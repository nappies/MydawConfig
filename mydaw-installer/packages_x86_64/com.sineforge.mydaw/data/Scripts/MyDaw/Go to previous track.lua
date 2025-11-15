function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


focus = reaper.GetCursorContext()

reaper.Main_OnCommand(40286, 0) ---Track: Go to previous track








