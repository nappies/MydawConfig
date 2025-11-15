--_MwTs


local function msg(s)
  reaper.ShowConsoleMsg(tostring(s))
  reaper.ShowConsoleMsg('\n')
end

local function GetSelectedTracks()
  local sel_tr_cnt = reaper.CountSelectedTracks(0)
  if sel_tr_cnt == 0 then return end
 
  local t = {}
 
  for i = 1, sel_tr_cnt do
    t[i] = reaper.GetSelectedTrack(0, i - 1)
  end
 
  return t
end

local function GetInstTracks(tracks)
  local t = {}
  local cnt = #tracks
 
  for i = 1, cnt do
    local inst_idx = reaper.TrackFX_GetInstrument(tracks[i])
    if inst_idx > -1 then
      t[#t + 1] = {['track'] = tracks[i], ['inst_idx'] = inst_idx}
    end
  end
 
  if #t == 0 then return end
  return t
end

local function CreateTempTracks(tracks)
  local t = {}
  local cnt = #tracks
 
  for i = 1, cnt do
    reaper.InsertTrackAtIndex(0, false)
    local buf = reaper.GetTrack(0, 0)
    t[#t + 1] = buf
  end
 
  return t
end

local function CreateFxBuffer(src_tr, dst_tr)
  local fx_count = reaper.TrackFX_GetCount(src_tr.track)
  if fx_count == src_tr.inst_idx + 1 then return end
 
  for i = fx_count - 1, src_tr.inst_idx + 1, - 1 do
    reaper.TrackFX_CopyToTrack(src_tr.track, i, dst_tr, 0, true)
  end
 
end

local function SelectOnlyTracksWithInstrument(tracks)
  reaper.SetOnlyTrackSelected(tracks[1].track)
  local cnt = #tracks
  if cnt == 1 then return end
 
  for i = 1, cnt do
    reaper.SetTrackSelected(tracks[i].track, true)
  end -- for
end -- function

local function InsertMediaItemInEmptyTracks(tracks)
  local cnt = #tracks
 
  for i = 1, cnt do
    local item = reaper.GetTrackMediaItem(tracks[i].track, 0)
    if not item then
      reaper.CreateNewMIDIItemInProj(tracks[i].track, 0, 1, false)
    end
 
  end
end

local function RestoreFxOnFrozenTrack(src_tr, dst_tr)
  local fx_count = reaper.TrackFX_GetCount(src_tr)
 
  for i = fx_count - 1, 0, - 1 do
    reaper.TrackFX_CopyToTrack(src_tr, i, dst_tr.track, 0, true)
  end

end

local function main()
  local sel_tracks = GetSelectedTracks()
  if not sel_tracks then return end
 
  local inst_tracks = GetInstTracks(sel_tracks)
  if not inst_tracks then return end
 
  local temp_tracks = CreateTempTracks(inst_tracks)
 
  for i = 1, #inst_tracks do
    CreateFxBuffer(inst_tracks[i], temp_tracks[i])
  end
 
  SelectOnlyTracksWithInstrument(inst_tracks)
  InsertMediaItemInEmptyTracks(inst_tracks) -- This ensures the track will be freezed even if it has no items
  reaper.Main_OnCommand(41223, 0) --Freeze tracks
 
  for i = 1, #inst_tracks do
    RestoreFxOnFrozenTrack(temp_tracks[i], inst_tracks[i])
    reaper.DeleteTrack(temp_tracks[i])
  end
 
  for i = 1, #sel_tracks do
    reaper.SetTrackSelected(sel_tracks[i], true)
  end
end


reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock('manup_Freeze tracks up to instrument (ignore non instrument tracks)', 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

----old code

--[[


function Freeze(track)
    local fx_count = reaper.TrackFX_GetCount(track)
    if fx_count==0 then return end 
    ----------------------------------------- 
    local online_all_fx  = 40536
    local offline_all_fx = 40535
    local freeze_track   = 41223
    -----------------------------------------
    reaper.SetOnlyTrackSelected(track) -- Select current track only
    reaper.Main_OnCommand(offline_all_fx, 0)  -- offline all fxs
  

 
    reaper.ShowConsoleMsg("fx".." "..reaper.TrackFX_GetInstrument(track))
    
      
    reaper.ShowConsoleMsg("Here")
           reaper.TrackFX_SetOffline( track, reaper.TrackFX_GetInstrument(track), true)
       
       
    
     
    -- Freeze, online all -------------------
    --reaper.Main_OnCommand(freeze_track, 0)    -- Freeze
    --reaper.Main_OnCommand(online_all_fx, 0)   -- online all fxs
end

--MAIN
local track_cnt = reaper.CountSelectedTracks(0)
local track_tb = {}
-- Get sel tracks ------
for i=1, track_cnt do  
    track_tb[i] = reaper.GetSelectedTrack(0, i-1)
end
-- Freeze tracks -------
reaper.Undo_BeginBlock()
for i=1, track_cnt do 
   Freeze(track_tb[i])
end
-- Restore sel state ---
for i=1, track_cnt do 
    reaper.SetTrackSelected(track_tb[i], true)
end
reaper.Undo_EndBlock("Freeze selected tracks instruments)", -1)
]]
