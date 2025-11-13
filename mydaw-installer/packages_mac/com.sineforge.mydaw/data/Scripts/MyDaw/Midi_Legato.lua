local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
if not take then  return end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
reaper.MIDIEditor_LastFocused_OnCommand(40405, 0) -- Set note ends to start of next note (legato)

local _, notes = reaper.MIDI_CountEvts(take)

local max_sel = 0


for i = 0, notes - 1 do
  local _, sel, _, start_note, end_note = reaper.MIDI_GetNote(take, i)
  if sel then max_sel = math.max(max_sel,start_note) end
end

d = math.huge

for i = 0, notes - 1 do
  local _, _, _, start_note = reaper.MIDI_GetNote(take, i)
  if d > start_note-max_sel and start_note-max_sel >0 then
    max_next = start_note
    d = start_note-max_sel
  end
end


t = {}

local item = reaper.GetMediaItemTake_Item(take)

local item_end = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')+reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
local item_end_ppq = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, item_end)+0.5)

for i = 0, notes - 1 do
  local _, sel, _, start_note, end_note = reaper.MIDI_GetNote(take, i)
  if sel and start_note == max_sel and end_note ~= item_end_ppq then t[#t+1] = i end
end

if not max_next or max_next <= max_sel then

  for i = 1, #t do
    reaper.MIDI_SetNote(take,t[i],nil,nil,nil,item_end_ppq,nil,nil,nil)
  end

elseif max_next > max_sel then

  for i = 1, #t do
    reaper.MIDI_SetNote(take,t[i],nil,nil,nil,max_next,nil,nil,nil)
  end

end

reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('Legato', -1)