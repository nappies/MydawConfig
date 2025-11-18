
local MIN_LENGTH = 0.01

-- Get time bounds of selected items
local function get_items_bounds()
  local min_pos, max_pos = math.huge, 0
  local count = reaper.CountSelectedMediaItems(0)
  
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    min_pos = math.min(min_pos, pos)
    max_pos = math.max(max_pos, pos + len)
  end
  
  return min_pos, max_pos
end

-- Select items in time range on track
local function select_items_in_range(track, start_time, end_time)
  -- Save current track selection
  local sel_tracks = {}
  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    sel_tracks[#sel_tracks + 1] = reaper.GetSelectedTrack(0, i)
  end
  
  -- Save current time selection
  local ts_start, ts_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  
  -- Set time range and select items
  reaper.GetSet_LoopTimeRange(1, 0, start_time, end_time, 0)
  reaper.SetOnlyTrackSelected(track, true)
  reaper.Main_OnCommand(40718, 0) -- Select all items on selected tracks in time selection
  
  -- Restore selections
  reaper.SetOnlyTrackSelected(reaper.GetTrack(0, 0), true)
  reaper.SetTrackSelected(reaper.GetTrack(0, 0), false)
  for _, t in ipairs(sel_tracks) do
    reaper.SetTrackSelected(t, true)
  end
  reaper.GetSet_LoopTimeRange(1, 0, ts_start, ts_end, 0)
end

-- Snap item length to nearest power-of-2 division of measure
local function snap_to_measure_division(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = pos + len
  
  -- Find measure containing item start
  local measure_start, measure_len
  for i = 0, 1000 do
    local msr = reaper.TimeMap_GetMeasureInfo(0, i)
    if msr > pos then
      measure_start = reaper.TimeMap_GetMeasureInfo(0, i - 1)
      measure_len = msr - measure_start
      break
    end
  end
  
  -- Calculate snapped length
  local new_len
  if len < measure_len then
    -- Find nearest power-of-2 division
    local divisions = math.floor(measure_len / len + 0.5)
    -- Round up to next power of 2
    local pow2_div = divisions
    for i = 0, 40 do
      if math.log(pow2_div) / math.log(2) == math.floor(math.log(pow2_div) / math.log(2)) then
        break
      end
      pow2_div = pow2_div + 1
    end
    new_len = measure_len / pow2_div
  else
    -- Snap to whole measures
    new_len = measure_len * math.floor(len / measure_len + 0.5)
  end
  
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
end

-- Main execution
local item_count = reaper.CountSelectedMediaItems(0)
if item_count == 0 then return end

local first_item = reaper.GetSelectedMediaItem(0, 0)
local track = reaper.GetMediaItem_Track(first_item)
local item_len = reaper.GetMediaItemInfo_Value(first_item, "D_LENGTH")

if item_len < MIN_LENGTH then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Special handling for single item: snap to measure divisions
if item_count == 1 then
  snap_to_measure_division(first_item)
end

local min_time, max_time = get_items_bounds()

-- Split and duplicate
reaper.ApplyNudge(0, 0, 3, 20, -0.5, 0, 0) -- Split at half
reaper.ApplyNudge(0, 0, 5, 20, 1, 0, 0)    -- Duplicate

-- Select all resulting items in the area
select_items_in_range(track, min_time, max_time)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Chop", -1)