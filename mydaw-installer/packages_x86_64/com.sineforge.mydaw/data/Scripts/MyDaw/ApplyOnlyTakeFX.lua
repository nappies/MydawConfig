package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")
 
 

SelTracksWItems()
reaper.Main_OnCommand(40535, 0) ----set offline all track fx
reaper.Main_OnCommand(40209, 0)  ----apply take 40361 mono
reaper.Main_OnCommand(40536, 0)  ----set online
