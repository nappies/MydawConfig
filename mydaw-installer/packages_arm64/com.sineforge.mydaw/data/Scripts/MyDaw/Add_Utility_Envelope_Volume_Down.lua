-- Utility function for debug messages (optional)
local function m(n, v)
    reaper.ShowConsoleMsg(n .. " " .. tostring(v) .. "\n")
end

-- Get envelope properties using native functions
local function GetEnvelopeProperties(env)
    local _, active = reaper.GetSetEnvelopeInfo_String(env, "ACTIVE", "", false)
    local _, visible = reaper.GetSetEnvelopeInfo_String(env, "VISIBLE", "", false)
    local _, armed = reaper.GetSetEnvelopeInfo_String(env, "ARM", "", false)
    
    return active == "1", visible == "1", armed == "1"
end

-- Set envelope properties using native functions
local function SetEnvelopeProperties(env, active, visible, armed)
    if active ~= nil then
        reaper.GetSetEnvelopeInfo_String(env, "ACTIVE", active and "1" or "0", true)
    end
    if visible ~= nil then
        reaper.GetSetEnvelopeInfo_String(env, "VISIBLE", visible and "1" or "0", true)
    end
    if armed ~= nil then
        reaper.GetSetEnvelopeInfo_String(env, "ARM", armed and "1" or "0", true)
    end
end

-- Get envelope points within a time range
local function GetEnvelopePointsInRange(env, areaStart, areaEnd)
    local points = {}
    local count = reaper.CountEnvelopePoints(env)
    
    for i = 0, count - 1 do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, i)
        if time >= areaStart and time <= areaEnd then
            points[#points + 1] = {
                id = i,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
        end
    end
    
    return points
end

-- Parse razor edits from tracks
local function GetRazorEdits()
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local _, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        
        if area ~= '' then
            local str = {}
            for token in string.gmatch(area, "%S+") do
                table.insert(str, token)
            end
            
            local j = 1
            while j <= #str do
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j + 1])
                local GUID = str[j + 2]
                local isEnvelope = GUID ~= '""'
                
                if not isEnvelope then
                    local env = AddVolumeEnvelope(track)
                    if env then
                        local env_name = reaper.GetEnvelopeName(env)
                        local env_points = GetEnvelopePointsInRange(env, areaStart, areaEnd)
                        
                        table.insert(areaMap, {
                            areaStart = areaStart,
                            areaEnd = areaEnd,
                            track = track,
                            isEnvelope = isEnvelope,
                            env_name = env_name,
                            env = env,
                            env_points = env_points,
                            GUID = GUID:sub(2, -2)
                        })
                    end
                end
                
                j = j + 3
            end
        end
    end
    
    return areaMap
end

-- Check if edge points exist at time boundaries (with tolerance)
local function CheckEdgePoints(env, areaStart, areaEnd)
    local count = reaper.CountEnvelopePoints(env)
    local tolerance = 0.002  -- Increased tolerance for edge detection
    local hasStartEdge = false
    local hasEndEdge = false
    
    for i = 0, count - 1 do
        local _, time = reaper.GetEnvelopePoint(env, i)
        
        -- Check for start edge point (just before area start)
        if math.abs(time - (areaStart - 0.001)) < tolerance then
            hasStartEdge = true
        end
        
        -- Check for end edge point (just after area end)
        if math.abs(time - (areaEnd + 0.001)) < tolerance then
            hasEndEdge = true
        end
        
        if hasStartEdge and hasEndEdge then
            return true
        end
    end
    
    return false
end

-- Add or show FX envelope
local function AddFXEnvelope(track, fxIndex, activate)
    local env = reaper.GetFXEnvelope(track, fxIndex, 7, activate)
    if env then
        reaper.Envelope_SortPoints(env)
    end
    return env
end

-- Add Volume Utility plugin and create envelope
function AddVolumeEnvelope(track)
    local utility = reaper.TrackFX_AddByName(track, "Volume Utility", false, 0)
    local utility_index
    
    if utility == -1 then
        -- Plugin already exists, get its index
        utility_index = reaper.TrackFX_GetByName(track, "Volume Utility", 1)
        reaper.TrackFX_AddByName(track, "Volume Utility", false, 1)
        utility_index = reaper.TrackFX_GetByName(track, "Volume Utility", 1)
        reaper.TrackFX_SetOpen(track, utility_index, false)
        
        -- Move to slot 0 on master track
        if track == reaper.GetMasterTrack(0) then
            while utility_index > 0 do
                --reaper.SNM_MoveOrRemoveTrackFX(track, utility_index, -1)
                utility_index = reaper.TrackFX_GetByName(track, "Volume Utility", 1)
            end
        end
        
        AddFXEnvelope(track, utility_index, true)
        
    elseif utility > -1 then
        utility_index = reaper.TrackFX_GetByName(track, "Volume Utility", 1)
        local env = reaper.GetFXEnvelope(track, utility_index, 7, false)
        
        if env and reaper.ValidatePtr(env, "TrackEnvelope*") then
            local active, visible, armed = GetEnvelopeProperties(env)
            
            if not visible then
                SetEnvelopeProperties(env, true, true, true)
            end
        else
            AddFXEnvelope(track, utility_index, true)
        end
    end
    
    utility_index = reaper.TrackFX_GetByName(track, "Volume Utility", 1)
    return reaper.GetFXEnvelope(track, utility_index, 7, false)
end

-- Main processing function
local function ProcessRazorEdits()
    local edits = GetRazorEdits()
    local move = -1  -- dB change amount
    
    if #edits == 0 then return end
    
    -- First pass: Add edge points if they don't exist
    for i = 1, #edits do
        if edits[i].env then
            local hasEdgePoints = CheckEdgePoints(edits[i].env, edits[i].areaStart, edits[i].areaEnd)
            
            if not hasEdgePoints then
                local _, startVal = reaper.Envelope_Evaluate(edits[i].env, edits[i].areaStart, 0, 0)
                local _, endVal = reaper.Envelope_Evaluate(edits[i].env, edits[i].areaEnd, 0, 0)
                
                -- Insert edge points (outer points maintain current values)
                reaper.InsertEnvelopePoint(edits[i].env, edits[i].areaStart - 0.001, startVal, 0, 0, false, false)
                reaper.InsertEnvelopePoint(edits[i].env, edits[i].areaEnd + 0.001, endVal, 0, 0, false, false)
                
                -- Insert modified points (inner points with change)
                reaper.InsertEnvelopePoint(edits[i].env, edits[i].areaStart + 0.0001, startVal + move, 0, 0, false, false)
                reaper.InsertEnvelopePoint(edits[i].env, edits[i].areaEnd - 0.0001, endVal + move, 0, 0, false, false)
                
                reaper.Envelope_SortPoints(edits[i].env)
                
                -- Show tooltip (custom API function)
                if reaper.Mydaw_ShowTooltips then
                    local y_start = reaper.GetMediaTrackInfo_Value(edits[i].track, "I_TCPY")
                    local y_end = y_start + reaper.GetMediaTrackInfo_Value(edits[i].track, "I_TCPH")
                    reaper.Mydaw_ShowTooltips(edits[i].areaStart, edits[i].areaEnd, y_start, y_end, tostring(startVal + move))
                end
            else
                -- Edge points exist, modify existing points in range
                -- Get fresh point data after edge points exist
                local env_points = GetEnvelopePointsInRange(edits[i].env, edits[i].areaStart + 0.00001, edits[i].areaEnd - 0.00001)
                
                for j = 1, #env_points do
                    local pt = env_points[j]
                    local newValue = math.ceil(pt.value)
                    
                    -- Apply change only if within range
                    if math.abs(newValue) < 10 then
                        newValue = newValue + move
                    else
                        newValue = 0
                    end
                    
                    reaper.SetEnvelopePoint(edits[i].env, pt.id, pt.time, newValue, pt.shape, pt.tension, pt.selected, true)
                    
                    -- Show tooltip
                    if reaper.Mydaw_ShowTooltips then
                        local y_start = reaper.GetMediaTrackInfo_Value(edits[i].track, "I_TCPY")
                        local y_end = y_start + reaper.GetMediaTrackInfo_Value(edits[i].track, "I_TCPH")
                        reaper.Mydaw_ShowTooltips(edits[i].areaStart, edits[i].areaEnd, y_start, y_end, tostring(newValue))
                    end
                end
                
                reaper.Envelope_SortPoints(edits[i].env)
            end
        end
    end
    
    -- Update UI once at the end
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
end

-- Execute
reaper.Undo_BeginBlock()
ProcessRazorEdits()
reaper.Undo_EndBlock("Volume envelope automation adjust", -1)
