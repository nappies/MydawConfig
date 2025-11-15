local midieditor =  reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  reaper.MIDIEditor_GetTake( midieditor )
    local item =  reaper.GetMediaItemTake_Item( take )
local startpos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
local leng = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
local cursorpos = reaper.GetCursorPosition()
local endpos = startpos + leng
local edge = cursorpos ~= endpos
local outedge = cursorpos <= endpos
midieditor = reaper.MIDIEditor_GetActive()
reaper.MIDIEditor_OnCommand(midieditor, 40745)

  take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())                     
  if take == nil then return end                                                    
  retval,count_notes,ccs,sysex = reaper.MIDI_CountEvts(take)                            
  for i = 0,count_notes do                                                                
  local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take,i-1)
    if sel then reaper.MIDIEditor_OnCommand(midieditor, 40184) break                                           
    elseif count_notes == i and edge and outedge  then reaper.MIDIEditor_OnCommand(midieditor, 40048)
    elseif count_notes == 0 and edge and outedge then reaper.MIDIEditor_OnCommand(midieditor, 40048)                   
    end
  end

