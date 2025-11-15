package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

reaper.Undo_BeginBlock2(0)
left,right =GetRazorStartEnd()
startOut, endOut = reaper.GetSet_LoopTimeRange2( 0, 0, true, 0, 0, 0 )

    reaper.PreventUIRefresh(1)
    if (left and right and left <= right) then
    reaper.GetSet_LoopTimeRange2(0, true, true, left, right, false)
    reaper.SetEditCurPos(left, true, false)
    else
    if endout then  reaper.SetEditCurPos(startOut, true, false) end
    end
    
	reaper.Main_OnCommand(40630, 0) ------Cursor to LOOP
	reaper.Main_OnCommand(1068, 0) ------------------TOGGLE REPEAT
	reaper.Main_OnCommand(40635, 0) -------------------remove TS
	
    reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Loop Selection", -1)
