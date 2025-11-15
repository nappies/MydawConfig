package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")


reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)
    

local cupos = reaper.GetCursorPosition()
SelTracksWItems()
reaper.Main_OnCommand(41173, 0)-- Cursor to start of items
reaper.Main_OnCommand(40698, 0)-- Copy items
reaper.Main_OnCommand(40129, 0)-- Delete Active trake
reaper.Main_OnCommand(40001, 0)-- isert ne track
reaper.Main_OnCommand(40058, 0)-- Paste Items
reaper.Main_OnCommand(40131, 0)-- crop to acive
reaper.MoveEditCursor( cupos, 0)


reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Cut Take', -1)  
