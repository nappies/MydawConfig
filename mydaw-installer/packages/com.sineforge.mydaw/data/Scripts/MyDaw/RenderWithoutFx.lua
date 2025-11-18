-----_MwMs

---------------------------------------------
function Main(item)
    local track = reaper.GetMediaItemTrack(item)
    local fx_count = reaper.TrackFX_GetCount(track) 
    local mute_pos = 0
    local state_tb = {}
    
    -----------------------------------------
    -- Find mute_pos and get FX states ------
    ----------------------------------------- 
    for fx=1, fx_count do 
        local retval, fx_name = reaper.TrackFX_GetFXName(track, fx-1, "")
        if fx_name:match("VSTi") or fx_name:match("AUi") then mute_pos = fx end
        state_tb[fx] = reaper.TrackFX_GetEnabled(track, fx-1) -- get state
    end
    
    -----------------------------------------
    -- Mute all FXs after mute_pos ----------
    -----------------------------------------   
    for fx=mute_pos+1, fx_count do 
        reaper.TrackFX_SetEnabled(track, fx-1, false) -- mute
    end
        
    -----------------------------------------
    -- Apply track/take FX(as new take)  ----
    -----------------------------------------
        -- Select only first item -- 
        reaper.SelectAllMediaItems(0, false)    -- unsel all
        reaper.SetMediaItemSelected(item, true) -- sel first
        ----------------------------
        reaper.Main_OnCommand(40209, 0)         -- Apply track/take FX to item
    -----------------------------------------
    -- Restore FX states --------------------
    -----------------------------------------
    for fx=mute_pos+1, fx_count do 
        reaper.TrackFX_SetEnabled(track, fx-1, state_tb[fx])
       -- reaper.Main_OnCommand(40642, 0)
    end   
end

---------------------------------------------
-- Start ------------------------------------
---------------------------------------------
local item = reaper.GetSelectedMediaItem(0, 0)
if item then 
    reaper.Undo_BeginBlock()
    Main(item)
    reaper.Main_OnCommand(40642, 0) 
    reaper.Undo_EndBlock("Render selected item as new take, up to last VSTi", -1)
end
