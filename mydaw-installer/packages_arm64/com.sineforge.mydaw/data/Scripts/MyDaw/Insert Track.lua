


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

function tracksnotzero()

if reaper.CountSelectedTracks() > 0 then
  local last_sel = reaper.GetSelectedTrack(0,reaper.CountSelectedTracks()-1)
  reaper.SetOnlyTrackSelected(last_sel)
  reaper.Main_OnCommand(40914,0) -- Track: Set first selected track as last touched track
  local dep = reaper.GetMediaTrackInfo_Value(last_sel, "I_FOLDERDEPTH")

  
  if dep > 0 then
    reaper.Main_OnCommand(40001, 0)----Track: Insert new track
    reaper.SetMediaTrackInfo_Value( last_sel , 'I_FOLDERCOMPACT', 0 )


  else
    reaper.Main_OnCommand(40001, 0)----Track: Insert new track
  end
else 
  local n = reaper.CountTracks(0)
  if n > 0 then
    local was_last_tr = reaper.GetTrack(0, n-1)
    local dep = reaper.GetMediaTrackInfo_Value(was_last_tr, "I_FOLDERDEPTH")
    reaper.SetOnlyTrackSelected(was_last_tr)
    reaper.Main_OnCommand(40702, 0) --Track: Insert new track at end of track list
  end
end

end

tracks = reaper.CountTracks()


if tracks == 0 then  reaper.Main_OnCommand(40001, 0)-------Track: Insert new track
else 
tracksnotzero() 
end





local tracks =  reaper.CountTracks(0)


if tracks == 0 then return end



 
reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('Insert Track', -1)




















