reaper.Main_OnCommand(40100,0)  ---Item: Set all media offline
reaper.Main_OnCommand(40109,0)  ----Item: Open items in primary external editor



function run()
  
  if  reaper.Mydaw_Window_GetForeground()~=  reaper.GetMainHwnd() then reaper.defer(run) else
  
   reaper.Main_OnCommand(40101,0)---Item: Set all media online
  reaper.Main_OnCommand(40047,0) --- Peaks: Build any missing peaks
  
  end
end




function wait()
  
  if  reaper.Mydaw_Window_GetForeground()==  reaper.GetMainHwnd() then reaper.defer( wait) else
  run()
  end
end
 wait()







