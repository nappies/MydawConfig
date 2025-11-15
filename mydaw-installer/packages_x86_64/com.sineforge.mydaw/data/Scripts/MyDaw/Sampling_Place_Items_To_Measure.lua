function m(nm,ms,tm)
  reaper.ShowConsoleMsg(tostring(nm).." "..tostring(ms).." ".. tostring(tm) .. "\n")
 end


    local CntSelIt = reaper.CountSelectedMediaItems(0)
    if CntSelIt ~= 0 then  


   for i = 0, CntSelIt - 1 do
        local selIt = reaper.GetSelectedMediaItem(0,i);
        local pos = reaper.GetMediaItemInfo_Value(selIt,'D_POSITION')
       
       
       Meas = reaper.TimeMap2_beatsToTime(0, 0, i )
       
       
     
         m(reaper.GetTakeName(reaper.GetActiveTake(selIt)), i+1,Meas)
        
         reaper.SetMediaItemInfo_Value(selIt,'D_POSITION',Meas)
       
         reaper.UpdateItemInProject(selIt)
         reaper.UpdateArrange()
         reaper.UpdateTimeline()
       
       
    end

  
    
    end
  
