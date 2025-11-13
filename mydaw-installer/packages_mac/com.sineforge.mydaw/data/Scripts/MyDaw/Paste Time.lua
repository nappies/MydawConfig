function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end


function  DeleteTempoMarkers()
local range = 0.01

count_tempo_markers = reaper.CountTempoTimeSigMarkers(0);

if count_tempo_markers <= 3 then

left, right = math.huge, -math.huge
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
            if razorLeft  < left  then left  = razorLeft end
            if razorRight > right then right = razorRight end
        end
    end
end
if left <= right then
   
for i = count_tempo_markers - 1, 0, -1 do

ret, timepos,_, _, bpm, timesig_num, timesig_denom,_ = reaper.GetTempoTimeSigMarker( 0,i )

if ret then



if (timepos == 0) or (((left-range) <= timepos) and (timepos <= (left+range))) 

or (((right-range) <= timepos) and (timepos <= (right+range))) 

then

 reaper.DeleteTempoTimeSigMarker(0, i);
 
end
end
end
end
end
end

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

track  = reaper.GetTrack( 0, 0 )

if track then

reaper.SetOnlyTrackSelected(track)


reaper.Main_OnCommand(40914, 0) --Track: Set first selected track as last touched track



reaper.Main_OnCommand(40311, 0) ---Set ripple edit for all tracks

reaper.Main_OnCommand(42398, 0) ----- Paste

reaper.Main_OnCommand(40309, 0)---Set ripple edit off

DeleteTempoMarkers()

end

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Paste Time', -1)
