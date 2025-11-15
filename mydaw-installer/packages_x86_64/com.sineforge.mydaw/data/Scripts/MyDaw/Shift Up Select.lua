package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local has_razor_edit = false
local firsttr = nil
local lasttr = nil
local ltouch_tr_num = reaper.GetMediaTrackInfo_Value(reaper.GetLastTouchedTrack(), "IP_TRACKNUMBER")  

local GetSetTrackInfo = reaper.GetSetMediaTrackInfo_String
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local _, razor_edit = GetSetTrackInfo(track, 'P_RAZOREDITS', '', false)
    if razor_edit ~= '' then
    if firsttr==nil then firsttr = track end
    has_razor_edit = true
    lasttr = track
 end
end

if has_razor_edit and lasttr ~= nil then

firsttr_num = reaper.GetMediaTrackInfo_Value( firsttr, "IP_TRACKNUMBER")
lasttr_num = reaper.GetMediaTrackInfo_Value( lasttr, "IP_TRACKNUMBER")


if firsttr_num == ltouch_tr_num and lasttr_num > ltouch_tr_num then

reaper.GetSetMediaTrackInfo_String(lasttr, 'P_RAZOREDITS', '', true)

elseif firsttr_num <= ltouch_tr_num and lasttr_num == ltouch_tr_num then

prev_tr =  reaper.CSurf_TrackFromID( firsttr_num-1, false)
local _, razor_edit = GetSetTrackInfo(firsttr, 'P_RAZOREDITS', '', false)
reaper.GetSetMediaTrackInfo_String(prev_tr, 'P_RAZOREDITS', razor_edit, true)

end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Move razor edit up', -1)
