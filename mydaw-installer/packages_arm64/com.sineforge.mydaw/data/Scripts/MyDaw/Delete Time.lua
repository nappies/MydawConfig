
reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

reaper.Mydaw_RazorEditToAllTracks()

reaper.Main_OnCommand(40311, 0) ---Set ripple edit for all tracks

reaper.Main_OnCommand(40312, 0) ---Item: Remove selected area of items

reaper.Main_OnCommand(40309, 0)---Set ripple edit off

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Cut Time', -1)


