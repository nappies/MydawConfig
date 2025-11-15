-- USER CONFIG AREA -----------------------------------------------------------
reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', 0, true) -- Master

reaper.set_action_options(1)

add_queue = false -- Toggle to render right away
render = true -- true/false: Toggle to render the queue if queue has been chosen

-- Render action for the instant render
render_action = 42230 -- File: Render project, using the most recent render settings, auto-close render dialog

console = true -- display console messages

-- Add Leading Zeros to A Number
function AddZeros(number, zeros)
  number = tostring(number)
  number = string.format('%0' .. zeros .. 'd', number)
  return number
end

------------------------------------------------------- END OF USER CONFIG AREA

-- Display a message in the console for debugging
function Msg(value)
  if console then
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

-- Check if a track is a bus (has receives from other tracks)
function IsBus(track)
  local num_receives = reaper.GetTrackNumSends(track, -1) -- -1 for receives
  return num_receives > 0
end

-- Get all returns (source tracks) for a bus with non-zero volume
function GetBusReturns(bus_track)
  local returns = {}
  local num_receives = reaper.GetTrackNumSends(bus_track, -1)
  
  for i = 0, num_receives - 1 do
    local source_track = reaper.GetTrackSendInfo_Value(bus_track, -1, i, "P_SRCTRACK")
    local volume = reaper.GetTrackSendInfo_Value(bus_track, -1, i, "D_VOL")
    local is_muted = reaper.GetTrackSendInfo_Value(bus_track, -1, i, "B_MUTE")
    
    if source_track and volume > 0 and is_muted == 0 then
      table.insert(returns, source_track)
    end
  end
  
  return returns
end

-- Get all parent tracks (folders) up the hierarchy
function GetParentTracks(track)
  local parents = {}
  local current_parent = reaper.GetParentTrack(track)
  
  while current_parent do
    table.insert(parents, current_parent)
    current_parent = reaper.GetParentTrack(current_parent)
  end
  
  return parents
end

-- Mute all tracks except specified ones
function MuteAllExcept(keep_tracks)
  local total_tracks = reaper.CountTracks(0)
  
  for i = 0, total_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    local should_keep = false
    
    -- Check if this track should be kept unmuted
    for _, keep_track in ipairs(keep_tracks) do
      if track == keep_track then
        should_keep = true
        break
      end
    end
    
    if should_keep then
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0) -- Unmute
    else
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1) -- Mute
    end
  end
end

-- Restore original mute states
function RestoreMuteStates(original_mute_states)
  for track, mute_state in pairs(original_mute_states) do
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", mute_state)
  end
end

-- Save original mute states
function SaveMuteStates()
  local mute_states = {}
  local total_tracks = reaper.CountTracks(0)
  
  for i = 0, total_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    mute_states[track] = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
  end
  
  return mute_states
end

-- UNSELECT ALL TRACKS
function UnselectAllTracks()
  local first_track = reaper.GetTrack(0, 0)
  if first_track then
    reaper.SetOnlyTrackSelected(first_track)
    reaper.SetTrackSelected(first_track, false)
  end
end

-- SAVE INITIAL TRACKS SELECTION
function SaveSelectedTracks(table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

-- RESTORE INITIAL TRACKS SELECTION
function RestoreSelectedTracks(table)
  UnselectAllTracks()
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track, true)
  end
end

-- Filter selected tracks to only include buses
function FilterBusesFromSelection(selected_tracks)
  local buses = {}
  
  for _, track in ipairs(selected_tracks) do
    if IsBus(track) then
      table.insert(buses, track)
    end
  end
  
  return buses
end

-- Main rendering function
function main()
  local retval, pattern = reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)
  local original_mute_states = SaveMuteStates()
  
  local buses = FilterBusesFromSelection(init_sel_tracks)
  
  if #buses == 0 then
    Msg("No buses found in selection!")
    return
  end
  
  local total_renders = 0
  
  -- Calculate total renders for progress
  for _, bus in ipairs(buses) do
    local returns = GetBusReturns(bus)
    total_renders = total_renders + #returns
  end
  
  if total_renders == 0 then
    Msg("No returns with non-zero volume found!")
    RestoreMuteStates(original_mute_states)
    return
  end
  
  -- Show confirmation dialog
  local result = reaper.ShowMessageBox(
    "Found " .. #buses .. " buses with " .. total_renders .. " total renders.\n\n" ..
    "This will render each return track individually with its bus.\n\n" ..
    "Continue?", 
    "Render Buses with Returns", 
    4 -- Yes/No buttons
  )
  
  if result ~= 6 then -- 6 = Yes
    Msg("Rendering cancelled by user")
    RestoreMuteStates(original_mute_states)
    return
  end
  
  -- Get prefix from user
  local retval, prefix = reaper.GetUserInputs("Render Filename Prefix", 1, "Prefix (optional):", "")
  
  if not retval then -- User cancelled
    Msg("Rendering cancelled by user")
    RestoreMuteStates(original_mute_states)
    return
  end
  
  dialog_result=-1
  -- Clean up prefix (trim whitespace and add separator if needed)
  if prefix and prefix ~= "" then
    prefix = prefix:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
    if not prefix:match("%s$") and not prefix:match("_$") and not prefix:match("%-$") then
      prefix = prefix .. " " -- add space separator if none exists
    end
    Msg("Using prefix: '" .. prefix .. "'")
  else
    prefix = ""
    Msg("No prefix specified")
  end
  
  local render_count = 0
  
  -- Process each bus
  for _, bus in ipairs(buses) do
    local retval, bus_name = reaper.GetSetMediaTrackInfo_String(bus, "P_NAME", "", false)
    if bus_name == "" then
      bus_name = "Bus"
    end
    
    local returns = GetBusReturns(bus)
    Msg("Processing bus: " .. bus_name .. " with " .. #returns .. " returns")
    
    -- Solo the bus
    reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
    reaper.SetMediaTrackInfo_Value(bus, "I_SOLO", 1)
    
    -- Process each return for this bus
    for _, return_track in ipairs(returns) do
      local retval, return_name = reaper.GetSetMediaTrackInfo_String(return_track, "P_NAME", "", false)
      if return_name == "" then
        return_name = "Return"
      end
      
      -- Get parent tracks for both return and bus
      local return_parents = GetParentTracks(return_track)
      local bus_parents = GetParentTracks(bus)
      
      -- Create list of tracks to keep unmuted
      local keep_tracks = {return_track, bus}
      
      -- Add parent tracks to keep list
      for _, parent in ipairs(return_parents) do
        table.insert(keep_tracks, parent)
      end
      for _, parent in ipairs(bus_parents) do
        table.insert(keep_tracks, parent)
      end
      
      -- Mute all tracks except the ones we want to keep
      MuteAllExcept(keep_tracks)
      
      -- Set render filename: "Prefix Return Name * Bus Name"
      local new_pattern = prefix .. return_name .. " * " .. bus_name
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", new_pattern, true)
      
      -- Show confirmation dialog before rendering with 3-second timeout
      local confirm_message = "About to render:\n\n" .. 
                             "Return: " .. return_name .. "\n" ..
                             "Bus: " .. bus_name .. "\n" ..
                             "File: " .. new_pattern .. "\n\n" ..
                             "Progress: " .. (render_count + 1) .. "/" .. total_renders .. "\n\n" ..
                             "Click 'No' to stop the process.\n" ..
                             "This dialog will auto-close in 3 seconds."
      

      
      -- Check if user clicked No or if there was an error
      if dialog_result == 1 then -- 7 = No
        Msg("Rendering stopped by user at: " .. new_pattern)
        -- Restore states and exit
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", pattern, true)
        RestoreMuteStates(original_mute_states)
        reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
        return
      end
      
     
      
      -- Render or add to queue
      if add_queue then
        reaper.Main_OnCommand(41823, 0) -- Add to render queue
      else
        reaper.Main_OnCommand(render_action, 0)
      end
      
      render_count = render_count + 1
      Msg("Completed: " .. new_pattern .. " (" .. render_count .. "/" .. total_renders .. ")")
    end
    
    -- Unsolo the bus
    reaper.SetMediaTrackInfo_Value(bus, "I_SOLO", 0)
  end
  
  -- Restore original pattern and mute states
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", pattern, true)
  RestoreMuteStates(original_mute_states)
  reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
  
  Msg("Completed " .. render_count .. " renders!")
end

--------------------------------------------------------- INIT

sel_tracks_count = reaper.CountSelectedTracks(0)

if sel_tracks_count > 0 then
  
  reaper.Undo_BeginBlock() -- Beginning of the undo block
  
  
  reaper.ClearConsole()
  
  init_sel_tracks = {}
  SaveSelectedTracks(init_sel_tracks)
  
  main() -- Execute main function
  
  reaper.UpdateArrange() -- Update the arrangement
  reaper.UpdateTimeline()
  
  if render and not add_queue then
    reaper.Main_OnCommand(41207, 0) -- Process render queue if not adding to queue
  end
  
  RestoreSelectedTracks(init_sel_tracks)
  
  

  
  reaper.Undo_EndBlock("Render buses with individual returns", -1) -- End of the undo block
  
else
  reaper.ShowMessageBox("No tracks selected! Please select bus tracks to render.", "Error", 0)
end
