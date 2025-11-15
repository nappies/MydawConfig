---_MwMs
--based on juliansader, MPL code https://forum.cockos.com/member.php?u=14710 https://forum.cockos.com/showthread.php?t=188335
package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")

  msg_type = 0xB -- Midi CC  
  

   reaper.Undo_BeginBlock()  
  for i = 1 , reaper.CountSelectedMediaItems(0) do
    local item = reaper.GetSelectedMediaItem(0,i-1)
    local take = reaper.GetActiveTake(item)
    if reaper.TakeIsMIDI(take) then 
      FilterMIDIData(take, msg_type)
    end
  end
  reaper.Undo_EndBlock("Filter All Midi CC from Item(s)", 1)   
