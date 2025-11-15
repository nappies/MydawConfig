package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("SetMidiEditorGrid")   



midieditor = reaper.MIDIEditor_GetActive()
reaper.MIDIEditor_OnCommand(midieditor, 1012)  ---Zoom

tk = reaper.MIDIEditor_GetTake(midieditor)
SetMidiGrid(tk)
