function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end



focus = reaper.GetCursorContext()


reaper.Main_OnCommand(40285, 0) ---Track: Go to next track


