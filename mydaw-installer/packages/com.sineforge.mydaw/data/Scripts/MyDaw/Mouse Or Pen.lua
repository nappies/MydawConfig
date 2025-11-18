function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end



--pen1 = reaper.GetToggleCommandState(39291) --Set default mouse modifier action for "MIDI note left drag" to "Erase notes"

local pen1 = reaper.GetMouseModifier( "MM_CTX_MIDI_NOTE", 0)



---m(pen1)

---------Make Mouse ON
if (pen1 == "3 m") then
reaper.Mydaw_Mouse_SetCursor(reaper.Mydaw_Mouse_LoadCursor(32512))
  
  reaper.SetMouseModifier( "MM_CTX_MIDI_NOTE", 0, -1 ) --"MIDI note left drag" to "Move note" (factory default) --reaper.Main_OnCommand(39289, 0)
  reaper.SetMouseModifier( 'MM_CTX_MIDI_NOTE_CLK', 0, 1) --"MIDI note left click" to "Select note"  --reaper.Main_OnCommand(39705, 0)
  
  reaper.SetMouseModifier( 'MM_CTX_MIDI_PIANOROLL', 0, 10)   --"MIDI piano roll left drag" to "Marquee select notes and time" --reaper.Main_OnCommand(39490, 0)
  reaper.SetMouseModifier( 'MM_CTX_MIDI_PIANOROLL_CLK', 0, 1) --"MIDI piano roll left click" to Deselect all notes and mode edit cursor
 
  reaper.SetMouseModifier( 'MM_CTX_MIDI_CCLANE', 0, 12) ---"MIDI CC lane left drag" to "Marquee select CC and time" --reaper.Main_OnCommand(39364, 0)
  reaper.SetMouseModifier( 'MM_CTX_MIDI_CCLANE', 4, 13 ) ---For Alt CC LINE -- - Select time ignoring snap 
  
  reaper.SetMouseModifier( 'MM_CTX_MIDI_CCEVT', 0, 2 ) ---Move CC event
  reaper.SetMouseModifier( 'MM_CTX_MIDI_CCEVT', 4, 10 ) ---For Alt CC EVENT --  Move CC  
 
  
  reaper.SetMouseModifier( "MM_CTX_ENVSEG", 0, 2  ) --"Set default mouse modifier action for "Envelope segment left drag" to "Insert envelope point" --reaper.Main_OnCommand(39162, 0)
  reaper.SetMouseModifier( "MM_CTX_ENVSEG", 4, -1 ) --- Mouse + alt to edit Curvature  
  reaper.SetMouseModifier( "MM_CTX_ENVPT", 0, -1 )--"Envelope point left drag" to "Move envelope point" (factory default) reaper.Main_OnCommand(39129, 0)
  
  reaper.TrackList_AdjustWindows(0)

    toggleState = 0
---------Make Pen ON
  elseif (pen1 == "1 m") then



cur = reaper.GetResourcePath()..'/Cursors/midi_paint.cur'

curhandle = reaper.Mydaw_Mouse_LoadCursorFromFile(cur)

   reaper.Mydaw_Mouse_SetCursor(curhandle)
   
   reaper.SetMouseModifier("MM_CTX_MIDI_NOTE", 0, 3 ) --"MIDI note left drag" to "Erase notes" reaper.Main_OnCommand(39291, 0)
   reaper.SetMouseModifier( "MM_CTX_MIDI_NOTE_CLK", 0, 6) --"MIDI note left click" to "Erase note" reaper.Main_OnCommand(39678, 0)
   
   reaper.SetMouseModifier( "MM_CTX_MIDI_PIANOROLL", 0, 22) --"MIDI piano roll left drag" to "Paint notes" reaper.Main_OnCommand(39502, 0)
   reaper.SetMouseModifier( "MM_CTX_MIDI_PIANOROLL_CLK", 0, 4) --"MIDI piano roll left click" to "Insert note" reaper.Main_OnCommand(39708, 0)
   
  
   reaper.SetMouseModifier( "MM_CTX_MIDI_CCLANE", 0, 1 ) --MIDI CC lane left drag" to "Draw/edit CC events ignoring selection" reaper.Main_OnCommand(39353, 0)
   reaper.SetMouseModifier( "MM_CTX_MIDI_CCLANE", 4, 6  ) ---For Alt CC LINE -- Draw/edit CC events ignoring snap and selection 
   
   reaper.SetMouseModifier( "MM_CTX_MIDI_CCEVT", 0, 3 ) --"MIDI CC event left click/drag" to Delete CC
   reaper.SetMouseModifier( "MM_CTX_MIDI_CCEVT", 4, 20 ) ---For Alt CC EVENT -- Draw/edit CC events ignoring selection and snap
   
   reaper.SetMouseModifier( "MM_CTX_ENVSEG", 0, 3  ) --"Envelope segment left drag" to "Freehand draw envelope" reaper.Main_OnCommand(39170, 0)
   reaper.SetMouseModifier( "MM_CTX_ENVSEG", 4,4)  --- Mouse + alt to Draw no Snapping
   reaper.SetMouseModifier( "MM_CTX_ENVPT", 0, 3 ) --"Envelope point left drag" to "Freehand draw envelope" reaper.Main_OnCommand(39141, 0)
   
  reaper.TrackList_AdjustWindows(0)

    
    toggleState = 1
  end


is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
reaper.SetToggleCommandState(sec, cmd, toggleState);  
reaper.RefreshToolbar2(sec, cmd);  

