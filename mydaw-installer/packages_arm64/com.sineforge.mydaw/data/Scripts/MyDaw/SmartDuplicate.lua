reaper.DeleteExtState("MyDaw_copy-paste", "take_envelopes",0)
focus = reaper.GetCursorContext() --  Даем переменную значения где сейчас фокус?


if focus == 0 then
reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

reaper.Main_OnCommand(40062, 0) --Track: Duplicate tracks  
reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Duplicate', -1)
else
reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(41295, 0) --Duplicate
reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Duplicate', -1)

end

