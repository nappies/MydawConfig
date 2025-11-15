focus = reaper.GetCursorContext()



if focus == 0 then 

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)


reaper.Main_OnCommand(40183, 0)

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Mute Track', -1)  

elseif focus == 1 then

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

reaper.Main_OnCommand(40175, 0)

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Mute Item(s)', -1)  


elseif focus == 2 then

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

reaper.Main_OnCommand(42211, 0)

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Mute Automation Item(s) ', -1)  

end
