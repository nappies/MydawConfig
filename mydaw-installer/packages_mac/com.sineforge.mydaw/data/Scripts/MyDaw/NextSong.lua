 
 reaper.PreventUIRefresh(1)
 
 --reaper.Main_OnCommand(40020, 0) --remove time selection
  
  --reaper.Main_OnCommand(41802, 0)  --Goto Next Region
  
  
 -- if 0==1 then
  
  edit_pos = reaper.GetCursorPosition()
  play = reaper.GetPlayState()
 
 if play > 0 then
    pos = reaper.GetPlayPosition()
  else
    pos = edit_pos
  end

  i=0
  repeat
    iRetval, bIsrgnOut, iPosOut, _, _, _, _ = reaper.EnumProjectMarkers3(0,i)
    if iRetval >= 1 then
      if bIsrgnOut == true and iPosOut > pos then
 
        reaper.SetEditCurPos(iPosOut,true,true) -- moveview and seekplay
        break
      end
      i = i+1
    end
  until iRetval == 0
  
  
  --end
  
  

  
  reaper.PreventUIRefresh(-1)
  
  
  
  
  
