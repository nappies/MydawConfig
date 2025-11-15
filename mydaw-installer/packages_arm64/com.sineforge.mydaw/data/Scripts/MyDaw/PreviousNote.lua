function move_to_next_note()
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) 
  if take == nil then 
    return
  end
  local retval, notecntOut, ccevtcntOut, textsyxevtcntOut = reaper.MIDI_CountEvts(take) 
  local curpos = reaper.GetCursorPosition()
  for i = notecntOut - 1, 0, -1 do 
  local retval, selectedOut, mutedOut, startppqposOut, endppqposOut, chanOut, pitchOut, velOut = reaper.MIDI_GetNote(take,i-1)
    local note_position = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqposOut)
    
    if note_position < curpos then
      reaper.SetEditCurPos(note_position, 1, 0)
      break
    end
  end
end


reaper.defer(move_to_next_note) -- using "defer" here prevents reaper from adding an undo point
