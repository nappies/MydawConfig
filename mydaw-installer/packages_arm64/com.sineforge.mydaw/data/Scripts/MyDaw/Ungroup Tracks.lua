function DoSetSelectedTrackNormal()
 
 
 
 
 for i = 0,reaper.CountSelectedTracks(0)-1 do
  local track = reaper.GetSelectedTrack(0,i)
 
 -- Get folder depth of the selected track
    local foldepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    
    -- Check if selected track is a folder parent
    if foldepth == 1 then
      local tracksToReset = {}
      table.insert(tracksToReset, track)
      
      local foldepAccum = 1
      local tkIDX = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
      
      -- Loop through tracks to find child tracks
      while foldepAccum > 0 do
        local tk = reaper.GetTrack(0, tkIDX)
        if not tk then break end
        
        foldepth = reaper.GetMediaTrackInfo_Value(tk, "I_FOLDERDEPTH")
        if foldepth ~= 0 then 
          table.insert(tracksToReset, tk)
        end
        
        foldepAccum = foldepAccum + foldepth
        tkIDX = tkIDX + 1
        
        if tkIDX >= reaper.CountTracks(0) then
          break
        end
      end
      
      -- Reset folder depth for all tracks in the list
      for i = 1, #tracksToReset do
        reaper.SetMediaTrackInfo_Value(tracksToReset[i], "I_FOLDERDEPTH", 0)
      end
      

    end
 
 
  end
    
    
end

-- Execute the function
DoSetSelectedTrackNormal()
