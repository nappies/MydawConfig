--_MwIs
----Thanks To Yanick

local info = debug.getinfo(1,'S');
local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
script_path = script_path:match([[(.*MyDaw\)]])
package.path = script_path.."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions") 


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
mono_stereo = 2
MixdownToTrack(mono_stereo)

reaper.UpdateArrange()
reaper.Undo_EndBlock('Mixdwon selection', -1)
reaper.PreventUIRefresh(-1)

   
  

    

