focus = reaper.GetCursorContext() --  Даем переменную значения где сейчас фокус?


if focus == 0 then
reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)


reaper.Main_OnCommand(40696, 0) -- rename last touched selected track


reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Rename', -1)

elseif  focus == 1 then

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)


reaper.Main_OnCommand(reaper.NamedCommandLookup('_MYDAW_REN_IT'), 0) -- group rename selected items
   



reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Rename', -1)
elseif  focus == 2 then
reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

reaper.Main_OnCommand(42091, 0) ---Envelope: Rename automation item...

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Rename', -1)
end
