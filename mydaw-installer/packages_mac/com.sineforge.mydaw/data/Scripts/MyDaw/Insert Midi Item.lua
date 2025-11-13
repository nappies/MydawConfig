reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(40214, 0) ---insert midi
  for i = 0, reaper.CountMediaItems(0) - 1 do
    local take = reaper.GetActiveTake( reaper.GetMediaItem(0, i) )
    if take then
      local _,midiname = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", 0, false)
     
     newname = midiname:gsub("untitled MIDI item", "")
     
       reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", newname, true)
    end
  end  
  

reaper.PreventUIRefresh(-1)
