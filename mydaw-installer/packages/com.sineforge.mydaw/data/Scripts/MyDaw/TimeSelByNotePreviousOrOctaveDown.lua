package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

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

function Time()


CursorToTime = 40276
CursorToTime_State = reaper.GetToggleCommandState(CursorToTime)
wason = 0
if (CursorToTime_State == 1) then
reaper.Main_OnCommand(CursorToTime, 0)
wason= 1
end




_, arrange_division, _, _ = reaper.GetSetProjectGrid(0, 0)
midieditor = reaper.MIDIEditor_GetActive()
reaper.PreventUIRefresh(1)
if midieditor then
  snap_enabled = reaper.MIDIEditor_GetSetting_int(midieditor, "snap_enabled")
  sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
  cursorpos = reaper.GetCursorPosition()
  if cursorpos == sel_start and cursorpos == sel_end then
    reaper.Main_OnCommand(40635, 0) 
    sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
  end
  
  if snap_enabled == 0 then
    reaper.MIDIEditor_OnCommand(midieditor, 1014)
  end
  if reaper.GetToggleCommandState(42010) == 0 then 
    reaper.MIDIEditor_OnCommand(midieditor, 41022) 
  end
  grid = SnapNextGridLine(cursorpos)
  if sel_start == 0 and sel_end == 0 then
    reaper.Main_OnCommand(40626, 0)  
 
 
 
end




  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) 
  if take == nil then 
    return
  end
  local retval, notecntOut, ccevtcntOut, textsyxevtcntOut = reaper.MIDI_CountEvts(take) 
  local curpos = reaper.GetCursorPosition()
  for i = notecntOut - 1, 0, -1 do 
  local retval, selectedOut, mutedOut, startppqposOut, endppqposOut, chanOut, pitchOut, velOut = reaper.MIDI_GetNote(take,i-1)
    local note_position = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqposOut)
    local note_positionend = reaper.MIDI_GetProjTimeFromPPQPos(take, endppqposOut)
    
    if note_positionend < curpos then
                  reaper.SetEditCurPos(note_positionend, 1, 0)
                  break
       end
  if note_position < curpos then
        reaper.SetEditCurPos(note_position, 1, 0)
        break
  
  
  
  
 end
 
 end











 if sel_start == 0 and sel_end == 0 then
    reaper.Main_OnCommand(40625, 0) 
  else
    if cursorpos >= (sel_start+sel_end)/2 then
      reaper.Main_OnCommand(40626, 0) 
    else
      reaper.Main_OnCommand(40625, 0) 
    end
  end
  
end
reaper.MIDIEditor_OnCommand(midieditor, 41022) 
reaper.SetProjectGrid(0, arrange_division)


 if (wason == 1) then
 reaper.Main_OnCommand(CursorToTime, 0)
 end



reaper.PreventUIRefresh(-1)
end


function OctaveDown()
midieditor = reaper.MIDIEditor_GetActive()
reaper.MIDIEditor_OnCommand(midieditor, 40180)
end

  
  
  
  
  take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())                     
  if take == nil then return end                                                    
  retval,count_notes,ccs,sysex = reaper.MIDI_CountEvts(take)                            
  for i = 0,count_notes do                                                                
  local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take,i-1)
    if sel then 

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)   

    
    OctaveDown()
    
reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Octave Down', -1) 
    
     break                                           
    elseif count_notes == i and edge and outedge then 

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)  
    
    Time()                   

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Selection', -1)    
    
    end
  end
