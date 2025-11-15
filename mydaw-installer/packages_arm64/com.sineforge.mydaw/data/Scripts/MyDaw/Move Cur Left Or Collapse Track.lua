package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

local focus = reaper.GetCursorContext()


if focus == 0 then

for i = 0,reaper.CountSelectedTracks(0)-1 do
  local tr = reaper.GetSelectedTrack(0,i)
  if reaper.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 then
    reaper.SetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT',0)
  end
end


function Increase()
  for sel_tr = 1, reaper.CountSelectedTracks(0) do
    local track = reaper.GetSelectedTrack(0,sel_tr-1)
    if track then 
    reaper.SetMediaTrackInfo_Value( track, 'I_HEIGHTOVERRIDE', 26 )
    reaper.TrackList_AdjustWindows(true) -- Update the arrangement (often needed)
      
      reaper.UpdateArrange()
    
    
     
      end
   end
end
  
Increase()


--TODO HIDE ENVELOPEHERE
---reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_ENV_HIDE_ALL_BUT_ACTIVE_SEL'), 0)

else
reaper.SetEditCurPos(SnapPrevGridLine(reaper.GetCursorPosition()),1,0)
reaper.Main_OnCommand(40289, 0) ---Item: Unselect all items
reaper.Main_OnCommand(40331, 0)---Envelope: Unselect all points
reaper.Main_OnCommand(40635, 0)----Time selection: Remove time selection
reaper.Main_OnCommand(42406, 0)----Razor edit: Clear all areas
end

