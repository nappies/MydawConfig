package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

function SplitItemAtLTTrack()
    local pos = reaper.GetCursorPosition()

    local track = reaper.GetLastTouchedTrack()
	-- Get selected track 0

    -- INITIALIZE loop through selected items
    local item_on_tracks = reaper.CountTrackMediaItems(reaper.GetLastTouchedTrack())
    for j = 0, item_on_tracks - 1 do
	   -- GET ITEM
	   local item = reaper.GetTrackMediaItem(track, j) -- Get selected item i

	   -- GET INFOS
	   local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	   local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	   local item_end = item_pos + item_len

	   if item_pos < pos and item_end > pos then
		  reaper.SplitMediaItem(item, pos)
	   end
    end -- END LOOP ITEMS ON TRACK
end

function getitems()
    lastitem = reaper.GetExtState("MyDaw", "Click On Bottom Half")
    if not lastitem or lastitem == "" then
	   SplitItemAtLTTrack()
    end

    item = GuidToItem(lastitem)

    if reaper.ValidatePtr2(0, item, "MediaItem*") then
	   reaper.SplitMediaItem(item, reaper.GetCursorPosition())
    end
end

function justsplititems()
    if reaper.CountSelectedMediaItems() == 0 then
	   getitems()
    else
	   reaper.Main_OnCommand(40757, 0) ---Item: Split items at edit cursor (no change selection)
    end
end

startOut, endOut = reaper.GetSet_LoopTimeRange2(0, 0, 0, 0, 0, 0) --  Даем переменную "Time selection"

isrzr = IsRazorEdits()

if endOut == 0 and isrzr == false then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    justsplititems()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Split", -1)
elseif isrzr == true or endOut > 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    reaper.Main_OnCommand(40061, 0) -- Split items at time selection

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Split", -1)
end

reaper.Main_OnCommand(40289, 0)
 ----Item: Unselect all items

reaper.UpdateTimeline()

