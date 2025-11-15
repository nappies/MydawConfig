reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)


reaper.Main_OnCommand(40689,0)  ---unlock
                  

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Flatten', -1)



reaper.UpdateArrange()
