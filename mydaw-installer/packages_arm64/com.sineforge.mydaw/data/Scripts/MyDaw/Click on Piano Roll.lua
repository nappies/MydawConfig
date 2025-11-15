function click()



midieditor = reaper.MIDIEditor_GetActive()
reaper.PreventUIRefresh(1)
reaper.MIDIEditor_OnCommand(midieditor, 40745)
reaper.MIDIEditor_OnCommand(midieditor, 40214)




reaper.MIDIEditor_OnCommand(midieditor, 40443)


----[[
reaper.MIDIEditor_OnCommand(midieditor, 40048)
reaper.MIDIEditor_OnCommand(midieditor, 40047)
--reaper.Main_OnCommand(40289, 0)
--]]


reaper.PreventUIRefresh(-1)

end

reaper.defer(click)
