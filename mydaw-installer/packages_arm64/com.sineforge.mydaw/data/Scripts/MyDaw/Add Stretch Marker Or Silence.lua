package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")





function InsertSilenceBeats()
    -- Get user input for beats.ticks format
    local retval, retvals_csv = reaper.GetUserInputs(
        "Insert Silence", 
        1, 
        "Measures.Beats:", 
        "1.0"
    )
    
    if not retval then
        return -- User cancelled
    end
    
    -- Parse the input
    local val = retvals_csv
    if val == "" then
        return
    end
    
    -- Get current cursor position
    local pos = reaper.GetCursorPosition()
    
    -- Check if position is valid
    local proj_len = reaper.GetProjectLength(0)
    if pos < 0 or pos >= proj_len then
        reaper.ShowMessageBox("Invalid cursor position", "Error", 0)
        return
    end
    
    -- Parse measures and beats
    local in_meas = 0
    local in_beats = 0
    local dot_pos = val:find("%.")
    
    if dot_pos then
        in_meas = tonumber(val:sub(1, dot_pos - 1)) or 0
        in_beats = tonumber(val:sub(dot_pos + 1)) or 0
    else
        in_meas = tonumber(val) or 0
    end
    
    -- Get time signature at cursor position
    local  num, den,bpm = reaper.TimeMap_GetTimeSigAtTime(0, pos)
    
    
    -- Calculate length in seconds
    -- Formula: beats_duration + measures_duration
    local len = in_beats * (60.0 / bpm) + in_meas * ((240.0 * num / den) / bpm)
    
    if len <= 0 then
        reaper.ShowMessageBox("Invalid length", "Error", 0)
        return
    end
    
    -- Begin undo block
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    -- Get current time selection
    local timeSel1, timeSel2 = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
    
    -- Set time selection for insertion
    local end_pos = pos + len
    reaper.GetSet_LoopTimeRange2(0, true, false, pos, end_pos, false)
    
    -- Insert space at time selection
    reaper.Main_OnCommand(40200, 0)
    
    -- Restore time selection, enlarge if needed (mimic native behavior)
    if timeSel1 > pos then
        timeSel1 = timeSel1 + len
    end
    if pos < timeSel2 then
        timeSel2 = timeSel2 + len
    end
    reaper.GetSet_LoopTimeRange2(0, true, false, timeSel1, timeSel2, false)
    
    -- End undo block
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Insert Silence", -1)
end





function AddStretchMarkersAtRazorEdges()
  local track_count = reaper.CountTracks(0)
  local earliest, latest = math.huge, -math.huge
  
  -- Find earliest and latest razor edit points across all tracks
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local _, razor_str = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
    
    if razor_str ~= '' then
      for start_str, end_str in razor_str:gmatch('([%d%.]+) ([%d%.]+)') do
        local start_time = tonumber(start_str)
        local end_time = tonumber(end_str)
        
        if start_time < earliest then earliest = start_time end
        if end_time > latest then latest = end_time end
      end
    end
  end
  
  -- Add stretch markers if valid range found
  if earliest < latest then
    local item_count = reaper.CountMediaItems(0)
    
    for i = 0, item_count - 1 do
      local item = reaper.GetMediaItem(0, i)
      local take = reaper.GetActiveTake(item)
      
      if take then
        local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local item_end = item_pos + item_len
        
        -- Only add markers to items that overlap the razor edit range
        if item_pos <= latest and item_end >= earliest then
          -- Add stretch marker at earliest point
          if earliest >= item_pos and earliest <= item_end then
            local pos_in_item = earliest - item_pos
            reaper.SetTakeStretchMarker(take, -1, pos_in_item)
          end
          
          -- Add stretch marker at latest point
          if latest >= item_pos and latest <= item_end then
            local pos_in_item = latest - item_pos
            reaper.SetTakeStretchMarker(take, -1, pos_in_item)
          end
        end
      end
    end
    
    reaper.UpdateArrange()
    reaper.Undo_OnStateChange('Add stretch markers at razor edges')
  end
end




israzor = IsRazorEdits()


function getitems()
    lastitem = reaper.GetExtState("MyDaw", "Click On Bottom Half")
    if not lastitem or lastitem == "" then
        return
    end

    item = GuidToItem(lastitem)

    if not item then
        return
    end

    reaper.SetMediaItemSelected(item, true)

    reaper.Main_OnCommand(41842, 0) -----add strech

    reaper.SetMediaItemSelected(item, false)
end



function justinserttoitems()
 

    local items = reaper.CountSelectedMediaItems()

    if items == 0 then
        getitems()
    else
        reaper.Main_OnCommand(41842, 0) -----add strech
    end
end

local lastit = reaper.GetExtState("MyDaw", "Click On Bottom Half")
    

if reaper.GetCursorContext()== 1 and  lastit and lastit ~= ""  then



if not israzor then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    justinserttoitems()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Insert Marker", -1)
else
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    AddStretchMarkersAtRazorEdges()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Insert Marker", -1)
end

else
InsertSilenceBeats()

end



