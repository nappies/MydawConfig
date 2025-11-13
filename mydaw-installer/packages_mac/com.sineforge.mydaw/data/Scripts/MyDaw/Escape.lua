function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


local win_foc =  reaper.Mydaw_Window_GetFocus()

local midieditor = reaper.MIDIEditor_GetActive()
local prwin =  reaper.Mydaw_Window_GetParent(win_foc)



if prwin == midieditor    then

reaper.MIDIEditor_OnCommand(midieditor, 40036) ---View: Go to start of file
reaper.MIDIEditor_OnCommand(midieditor, 40745) --- Time selection: Remove time selection
reaper.MIDIEditor_OnCommand(midieditor, 40214)  --Edit: Unselect all 
reaper.MIDIEditor_OnCommand(midieditor, 1142)   ---Transport: Stop
reaper.Main_OnCommand(40345, 0) --- Send all notes off to all MIDI outputs/plug-ins

else


reaper.Main_OnCommand(40289, 0) ---Item: Unselect all items
reaper.Main_OnCommand(40331, 0)---Envelope: Unselect all points
reaper.Main_OnCommand(40340, 0) --Track: Unsolo all tracks
reaper.Main_OnCommand(40345, 0) --- Send all notes off to all MIDI outputs/plug-ins
reaper.Main_OnCommand(40635, 0) --  Time selection: Remove time selection
reaper.Main_OnCommand(42406, 0) ---Clear Razor Edit
reaper.Main_OnCommand(1016, 0) ---Transport: Stop
reaper.Main_OnCommand(40020, 0) ---Remove TS/Loop
reaper.Main_OnCommand(41175, 0) ---Reset all MIDI devices
reaper.Main_OnCommand(42348, 0) ---Reset all MIDI control surface devices
reaper.Main_OnCommand(40668, 0) ---Transport: Stop (DELETE all recorded media)



end

reaper.PreventUIRefresh(-1)
