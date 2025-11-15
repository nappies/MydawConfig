-- MIDI Smart Split
function CutNotesByTimeSelection(take, startTime, endTime, selectedOnly)
  reaper.MIDI_DisableSort(take)
  
  local _, noteCount = reaper.MIDI_CountEvts(take)
  if noteCount == 0 then return end
  
  -- Convert time to PPQ
  local startPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, startTime)
  local endPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, endTime)
  
  local notes = {}
  
  -- Collect all notes
  for i = 0, noteCount - 1 do
    local note = {}
    _, note.selected, note.muted, note.startPos, note.endPos, note.chan, note.pitch, note.vel = 
      reaper.MIDI_GetNote(take, i)
    note.index = i
    table.insert(notes, note)
  end
  
  -- Process notes in reverse order to avoid index issues
  for i = #notes, 1, -1 do
    local note = notes[i]
    
    -- Skip if we're only processing selected notes and this note isn't selected
    if selectedOnly and not note.selected then
      goto continue
    end
    
    -- Check if note overlaps with time selection
    if note.startPos < endPPQ and note.endPos > startPPQ then
      -- Delete the original note
      reaper.MIDI_DeleteNote(take, i - 1)
      
      -- Create up to 3 segments
      -- Before cut
      if note.startPos < startPPQ then
        reaper.MIDI_InsertNote(take, note.selected, note.muted, 
          note.startPos, startPPQ, note.chan, note.pitch, note.vel, false)
      end
      
      -- Inside cut (middle segment)
      local midStart = math.max(note.startPos, startPPQ)
      local midEnd = math.min(note.endPos, endPPQ)
      if midStart < midEnd then
        reaper.MIDI_InsertNote(take, note.selected, note.muted, 
          midStart, midEnd, note.chan, note.pitch, note.vel, false)
      end
      
      -- After cut
      if note.endPos > endPPQ then
        reaper.MIDI_InsertNote(take, note.selected, note.muted, 
          endPPQ, note.endPos, note.chan, note.pitch, note.vel, false)
      end
    else
      -- Note doesn't overlap, keep it as is
      -- (already exists, no need to re-insert)
    end
    
    ::continue::
  end
  
  reaper.MIDI_Sort(take)
end

function HasSelectedNotes(take)
  local _, noteCount = reaper.MIDI_CountEvts(take)
  for i = 0, noteCount - 1 do
    local _, selected = reaper.MIDI_GetNote(take, i)
    if selected then return true end
  end
  return false
end


function CutNotesAtCursor(take, cursorPPQ)
  reaper.MIDI_DisableSort(take)
  
  local _, noteCount = reaper.MIDI_CountEvts(take)
  if noteCount == 0 then return end
  
  local notes = {}
  
  -- Collect all notes
  for i = 0, noteCount - 1 do
    local note = {}
    _, note.selected, note.muted, note.startPos, note.endPos, note.chan, note.pitch, note.vel = 
      reaper.MIDI_GetNote(take, i)
    note.index = i
    table.insert(notes, note)
  end
  
  -- Process notes in reverse order
  for i = #notes, 1, -1 do
    local note = notes[i]
    
    -- Check if cursor is within the note
    if note.startPos < cursorPPQ and note.endPos > cursorPPQ then
      -- Delete the original note
      reaper.MIDI_DeleteNote(take, i - 1)
      
      -- Create two segments, both selected
      -- Before cursor
      reaper.MIDI_InsertNote(take, true, note.muted, 
        note.startPos, cursorPPQ, note.chan, note.pitch, note.vel, false)
      
      -- After cursor
      reaper.MIDI_InsertNote(take, true, note.muted, 
        cursorPPQ, note.endPos, note.chan, note.pitch, note.vel, false)
    end
  end
  
  reaper.MIDI_Sort(take)
end




function Main()
  local midiEditor = reaper.MIDIEditor_GetActive()
  if not midiEditor then 
    reaper.ShowMessageBox("No active MIDI editor found", "Error", 0)
    return 
  end
  
  local take = reaper.MIDIEditor_GetTake(midiEditor)
  if not take then 
    reaper.ShowMessageBox("No active MIDI take found", "Error", 0)
    return 
  end
  
  -- Check for time selection
  local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local hasTimeSelection = (startTime ~= endTime)
  
  if hasTimeSelection then
    -- TIME SELECTION EXISTS
    local hasSelected = HasSelectedNotes(take)
    if hasSelected then
      -- Cut only selected notes along time selection
      CutNotesByTimeSelection(take, startTime, endTime, true)
    else
      -- Cut all notes along time selection
      CutNotesByTimeSelection(take, startTime, endTime, false)
    end
    
  else
    -- NO TIME SELECTION
    local hasSelected = HasSelectedNotes(take)
    
    if hasSelected then
      -- Use action 40641: Split notes on grid (selected notes)
      reaper.MIDIEditor_OnCommand(midiEditor, 40641)
    else
      -- Use action 40052: Split all notes on grid
      local cursorPos = reaper.GetCursorPosition()
       local cursorPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, cursorPos)
        CutNotesAtCursor(take, cursorPPQ)
    end
  end
  
  
end


reaper.Undo_BeginBlock2(0) 
Main()
reaper.Undo_EndBlock2(0,"Smart Split", 0)
