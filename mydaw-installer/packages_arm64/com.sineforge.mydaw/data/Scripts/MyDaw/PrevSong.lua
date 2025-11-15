  
     reaper.PreventUIRefresh(1)
   
   ---reaper.Main_OnCommand(40020, 0) --remove time selection
   
   
  -- reaper.Main_OnCommand(41801, 0) --Goto previous region
  
  
--  if 0==1 then
  
  edit_pos = reaper.GetCursorPosition()

  play = reaper.GetPlayState()
  if play > 0 then
    pos = reaper.GetPlayPosition()
  else
    pos = edit_pos
  end

  count_markers_regions, count_markersOut, count_regionsOut = reaper.CountProjectMarkers(0)

  i=1
  repeat
    iRetval, bIsrgnOut, iPosOut, _, _, _, _ = reaper.EnumProjectMarkers3(0,count_markers_regions-i)
    if iRetval >= 1 then
      if bIsrgnOut == true and iPosOut < pos then

        reaper.SetEditCurPos(iPosOut,true,true) -- moveview and seekplay
        break
      end
      i = i+1
    end
  until iRetval == 0
  
  --end
  

