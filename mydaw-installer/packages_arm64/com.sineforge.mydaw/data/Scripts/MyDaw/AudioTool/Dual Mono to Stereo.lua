--_MwAs



local info = debug.getinfo(1,'S');
local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
script_path = script_path:match([[(.*MyDaw\)]])
package.path = script_path.."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions") 

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

if reaper.CountSelectedMediaItems(0) ~= 2 then
    return
end

local it1 = reaper.GetSelectedMediaItem(0, 0)
local it2 = reaper.GetSelectedMediaItem(0, 1)

local itleft
local itright

if reaper.GetMediaItem_Track(it1) ~= reaper.GetMediaItem_Track(it2) then
    if
        reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(it1), "IP_TRACKNUMBER") <
            reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(it1), "IP_TRACKNUMBER")
     then
        itleft = it1
        itright = it2
    else
        itleft = it2
        itright = it1
    end

    reaper.Main_OnCommand(40644, 0) ---Item: Implode items across tracks into items on one track
else
    it1y = reaper.GetMediaItemInfo_Value(it1, "I_LASTY")
    it2y = reaper.GetMediaItemInfo_Value(it1, "I_LASTY")

    if it1y ~= it2y then
        if it1y < it2y then
            itleft = it1
            itright = it2
        else
            itleft = it2
            itright = it1
        end
    else
        if reaper.GetMediaItemInfo_Value(it1, "IP_ITEMNUMBER") < reaper.GetMediaItemInfo_Value(it1, "IP_ITEMNUMBER") then
            itleft = it1
            itright = it2
        else
            itleft = it2
            itright = it1
        end
    end
end

reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(itleft), "D_PAN", 1)
reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(itright), "D_PAN", -1)

reaper.Main_OnCommand(42432, 0) ---Item: Glue items

trash = "-glued"
DelNameTrash(trash)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Dual Mono To Stereo", -1)

