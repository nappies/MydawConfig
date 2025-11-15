-- Optimized MIDI Note/CC Cut Script for Reaper
-- Cuts MIDI events based on time selection and event selection

-- Check if events exist within time selection
local function IsEventsInTs()
  local notes_ints, cc_ints = 0, 0
  local x_ts, y_ts = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  
  if x_ts and y_ts and x_ts ~= y_ts then
    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
    if take then
      local _, notes, ccs = reaper.MIDI_CountEvts(take)  
      local x_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, x_ts)
      local y_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, y_ts)
      
      -- Check notes
      if notes > 0 then
        for n = notes - 1, 0, -1 do
          local _, _, _, start_ppq, end_ppq = reaper.MIDI_GetNote(take, n)
          if (start_ppq < y_ppq and start_ppq > x_ppq) or 
             (end_ppq > x_ppq and end_ppq < y_ppq) or 
             (start_ppq <= x_ppq and end_ppq >= y_ppq) then
            notes_ints = 1
            break
          end
        end
      end
      
      -- Check CCs
      if ccs > 0 then
        for c = ccs - 1, 0, -1 do
          local _, _, _, ppq = reaper.MIDI_GetCC(take, c)
          if ppq >= x_ppq and ppq <= y_ppq then
            cc_ints = 1
            break
          end
        end
      end
    end
  end
  
  return notes_ints, cc_ints
end

-- Check if any events are selected
local function IsEventsSel()
  local selnote, selcc = 0, 0
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  
  if not take then return 0, 0 end
  
  local _, count_notes, ccs = reaper.MIDI_CountEvts(take)
  
  -- Check selected notes
  for i = 0, count_notes - 1 do
    local _, selected = reaper.MIDI_GetNote(take, i)
    if selected then
      selnote = 1
      break
    end
  end
  
  -- Check selected CCs
  for i = 0, ccs - 1 do
    local _, selected = reaper.MIDI_GetCC(take, i)
    if selected then
      selcc = 1
      break
    end
  end
  
  return selnote, selcc
end

-- Deselect MIDI events outside time selection
local function jsUnselectNotInTime()
  local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  local numItems = reaper.CountMediaItems(0)
  
  for i = 0, numItems - 1 do
    local curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then
      local itemStartTime = reaper.GetMediaItemInfo_Value(curItem, "D_POSITION")
      local itemEndTime = itemStartTime + reaper.GetMediaItemInfo_Value(curItem, "D_LENGTH")
      local numTakes = reaper.CountTakes(curItem)
      
      for t = 0, numTakes - 1 do
        local curTake = reaper.GetTake(curItem, t)
        if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then
          
          if itemStartTime >= timeSelEnd or itemEndTime <= timeSelStart then
            reaper.MIDI_SelectAll(curTake, false)
          else
            local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(curTake, "")
            if not gotAllOK then
              reaper.ShowMessageBox("Could not load raw MIDI data.", "ERROR", 0)
              return false
            end
            
            local timeSelStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelStart)
            local timeSelEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelEnd)
            local tableEvents = {}
            local t_idx = 0
            local countDeselects = 0
            
            -- Track note-off deselection requirements
            local tableDeselectNextNoteOff = {}
            for flags = 0, 3 do
              tableDeselectNextNoteOff[flags] = {}
              for chan = 0, 15 do
                tableDeselectNextNoteOff[flags][chan] = {}
              end
            end
            
            local nextPos, prevPos, unchangedPos = 1, 1, 1
            local runningPPQpos = 0
            local MIDIlen = MIDIstring:len()
            
            while nextPos < MIDIlen do
              local mustDeselect = false
              prevPos = nextPos
              local offset, flags, msg
              offset, flags, msg, nextPos = string.unpack("i4Bs4", MIDIstring, prevPos)
              
              if offset < 0 then
                reaper.ShowMessageBox("Improperly sorted MIDI data encountered.", "ERROR", 0)
                return false
              end
              
              runningPPQpos = runningPPQpos + offset
              
              if flags & 1 == 1 then
                local eventType = msg:byte(1) >> 4
                
                -- Note-offs
                if eventType == 8 or (msg:byte(3) == 0 and eventType == 9) then
                  local channel = msg:byte(1) & 0x0F
                  local pitch = msg:byte(2)
                  if tableDeselectNextNoteOff[flags][channel][pitch] then
                    mustDeselect = true
                  end
                  tableDeselectNextNoteOff[flags][channel][pitch] = nil
                  
                -- Note-ons
                elseif eventType == 9 then
                  local channel = msg:byte(1) & 0x0F
                  local pitch = msg:byte(2)
                  
                  if tableDeselectNextNoteOff[flags][channel][pitch] ~= nil then
                    reaper.ShowMessageBox("Overlapping notes detected.", "ERROR", 0)
                    return false
                  end
                  
                  tableDeselectNextNoteOff[flags][channel][pitch] = false
                  
                  if runningPPQpos >= timeSelEndPPQ then
                    mustDeselect = true
                    tableDeselectNextNoteOff[flags][channel][pitch] = true
                  elseif runningPPQpos < timeSelStartPPQ then
                    -- Search for matching note-off
                    local matchNoteOff = string.char(0x80 | channel, pitch)
                    local matchNoteOn = msg:sub(1, 2)
                    local evPos = nextPos
                    local evPPQpos = runningPPQpos
                    
                    repeat
                      local evOffset, evFlags, evMsg
                      evOffset, evFlags, evMsg, evPos = string.unpack("i4Bs4", MIDIstring, evPos)
                      evPPQpos = evPPQpos + evOffset
                      if evFlags == flags and 
                         (evMsg:sub(1, 2) == matchNoteOff or 
                          (evMsg:sub(1, 2) == matchNoteOn and evMsg:byte(3) == 0)) then
                        if evPPQpos <= timeSelStartPPQ then
                          mustDeselect = true
                          tableDeselectNextNoteOff[flags][channel][pitch] = true
                        end
                        break
                      end
                    until evPos >= MIDIlen - 12
                  end
                  
                -- All other event types
                else
                  if runningPPQpos < timeSelStartPPQ or runningPPQpos >= timeSelEndPPQ then
                    mustDeselect = true
                  end
                end
              end
              
              -- Write events to table
              if mustDeselect then
                countDeselects = countDeselects + 1
                if unchangedPos < prevPos then
                  t_idx = t_idx + 1
                  tableEvents[t_idx] = MIDIstring:sub(unchangedPos, prevPos - 1)
                end
                t_idx = t_idx + 1
                tableEvents[t_idx] = string.pack("i4Bs4", offset, flags & 0xFE, msg)
                unchangedPos = nextPos
              end
            end
            
            -- Write last block
            t_idx = t_idx + 1
            tableEvents[t_idx] = MIDIstring:sub(unchangedPos)
            
            -- Apply changes
            if countDeselects > 0 then
              local newMIDIstring = table.concat(tableEvents)
              if newMIDIstring:len() == MIDIlen then
                reaper.MIDI_SetAllEvts(curTake, newMIDIstring)
              else
                reaper.ShowMessageBox("Error parsing MIDI data.", "ERROR", 0)
                return false
              end
            end
          end
        end
      end
    end
  end
end

-- Cut with time selection and event selection
local function SelAllInTsCut()
  local midieditor = reaper.MIDIEditor_GetActive()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  reaper.MIDIEditor_OnCommand(midieditor, 40875) -- Select all events in time selection
  jsUnselectNotInTime()
  reaper.MIDIEditor_OnCommand(midieditor, 40734) -- Smart cut
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Cut MIDI', -1)
end

-- Cut selected events only
local function CutEventsOnly()
  local midieditor = reaper.MIDIEditor_GetActive()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  reaper.MIDIEditor_OnCommand(midieditor, 40440) -- Move cursor to start of selected events
  reaper.Main_OnCommand(40625, 0) -- Set start point of time selection
  reaper.MIDIEditor_OnCommand(midieditor, 40639) -- Move cursor to end of selected events
  reaper.Main_OnCommand(40626, 0) -- Set end point of time selection
  reaper.MIDIEditor_OnCommand(midieditor, 40734) -- Smart cut
  reaper.Main_OnCommand(40635, 0) -- Remove time selection
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Cut MIDI', -1)
end

-- Cut with time selection
local function CutTS()
  local midieditor = reaper.MIDIEditor_GetActive()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  jsUnselectNotInTime()
  reaper.MIDIEditor_OnCommand(midieditor, 40734) -- Smart cut
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Cut MIDI', -1)
end

-- Main execution logic
local notes_ints, cc_ints = IsEventsInTs()
local selnote, selcc = IsEventsSel()

-- Remove time selection if no events in it
if notes_ints == 0 and cc_ints == 0 then
  reaper.Main_OnCommand(40635, 0)
end

local _, endOut = reaper.GetSet_LoopTimeRange2(0, 0, 0, 0, 0, 0)

-- Determine which cut method to use
if endOut == 0 and (selnote == 1 or selcc == 1) then
  CutEventsOnly()
elseif endOut > 0 and (selnote == 1 or selcc == 1) then
  CutTS()
elseif endOut > 0 and selnote == 0 and selcc == 0 then
  SelAllInTsCut()
end