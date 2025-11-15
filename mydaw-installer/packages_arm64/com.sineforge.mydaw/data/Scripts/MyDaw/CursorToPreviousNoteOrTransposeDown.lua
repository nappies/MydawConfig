local midieditor =  reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  reaper.MIDIEditor_GetTake( midieditor )
    local item =  reaper.GetMediaItemTake_Item( take )
local startpos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
local leng = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
local cursorpos = reaper.GetCursorPosition()
local edge = cursorpos ~= startpos
local endpos = startpos + leng
local outedge = cursorpos >= startpos




function Down()
midieditor = reaper.MIDIEditor_GetActive()
reaper.MIDIEditor_OnCommand(midieditor, 40178)
reaper.MIDIEditor_OnCommand(midieditor, 40745)
end




function move_to_previous_note()
  reaper.MIDIEditor_OnCommand(midieditor, 40745)
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) 
  if take == nil then 
    return
  end
  local retval, notecntOut, ccevtcntOut, textsyxevtcntOut = reaper.MIDI_CountEvts(take) 
  local curpos = reaper.GetCursorPosition()
  for i = notecntOut - 1, 0, -1 do 
  local retval, selectedOut, mutedOut, startppqposOut, endppqposOut, chanOut, pitchOut, velOut = reaper.MIDI_GetNote(take,i-1)
    local note_position = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqposOut)
    local note_positionend = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqposOut)
    if note_position < curpos then
      reaper.SetEditCurPos(note_position, 1, 0)
      break
    end
  if note_positionend < curpos then
        reaper.SetEditCurPos(note_positionend, 1, 0)
        break
    end
  end
end




  take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())                     
  if take == nil then return end                                                    
  retval,count_notes,ccs,sysex = reaper.MIDI_CountEvts(take)                            
  for i = 0,count_notes do                                                                
  local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take,i-1)
    if sel then Down() break                                           
    elseif count_notes == i and edge and outedge then reaper.defer(move_to_previous_note)                   
    end
  end

