-- REAPER Pitch Bend Glide Script
-- Creates smooth pitch bend automation between notes

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function deepcopy(obj)
    if type(obj) ~= "table" then
        return obj
    end
    
    local copy = {}
    for key, value in next, obj, nil do
        copy[deepcopy(key)] = deepcopy(value)
    end
    setmetatable(copy, deepcopy(getmetatable(obj)))
    return copy
end

function string:split(delimiter)
    delimiter = delimiter or ","
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    
    self:gsub(pattern, function(match)
        result[#result + 1] = match
    end)
    
    return result
end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local PROCESS_LIMIT = 300

-- ============================================================================
-- MIDI CLIP CLASS
-- ============================================================================

function createMIDIClip(take)
    local clip = {
        editorHwnd = nil,
        mediaItem = nil,
        take = nil,
        editingNotes = {},
        originalNotes = {},
        existMaxNoteIdx = -1,
        firstSelectionCheck = nil,
        processLimitNoteNum = PROCESS_LIMIT,
        processLimitNoteNum_min = 0,
        isSelection = false
    }
    
    -- Check if there are selected notes
    function clip:isSelectionInEditingNotes(forceCheck)
        if self.firstSelectionCheck == nil or forceCheck then
            self.isSelection = false
            for _, note in ipairs(self.editingNotes) do
                if note.selection then
                    self.isSelection = true
                    break
                end
            end
            self.firstSelectionCheck = true
        end
        return self.isSelection
    end
    
    -- Check process limits
    function clip:checkProcessLimitNum()
        if #self.editingNotes < self.processLimitNoteNum_min + 1 then
            return false
        end
        if #self.editingNotes >= self.processLimitNoteNum then
            reaper.ShowMessageBox(
                "Over " .. tostring(self.processLimitNoteNum) .. " notes.\nStopping process.",
                "Stop",
                0
            )
            return false
        end
        return true
    end
    
    -- Get target notes (selected or all)
    function clip:_detectTargetNotes()
        if self:isSelectionInEditingNotes() then
            return self:_getSelectionNotes()
        end
        return self.editingNotes
    end
    
    -- Get notes with same start position
    function clip:_getSameStartPosNotes(targetPos, notes)
        local result = {}
        notes = notes or self.editingNotes
        
        for i = 1, #notes do
            local note = notes[i]
            if note.startpos == targetPos then
                table.insert(result, note)
            end
        end
        
        table.sort(result, function(a, b)
            return a.pitch > b.pitch
        end)
        
        return result
    end
    
    -- Get table of unique start positions
    function clip:_getExistStartPosTable(notes)
        local positions = {}
        notes = notes or self.editingNotes
        
        table.sort(notes, function(a, b)
            return a.startpos < b.startpos
        end)
        
        local lastPos = -100
        for _, note in ipairs(notes) do
            if lastPos ~= note.startpos then
                table.insert(positions, note.startpos)
                lastPos = note.startpos
            end
        end
        
        return positions
    end
    
    -- Get selected notes only
    function clip:_getSelectionNotes(notes)
        local selected = {}
        notes = notes or self.editingNotes
        
        for _, note in ipairs(notes) do
            if note.selection then
                table.insert(selected, note)
            end
        end
        
        return selected
    end
    
    -- Get all notes from take
    function clip:_getNotes_(onlySelected)
        local notes = {}
        local take = self.take
        
        if not take then return notes end
        
        local idx = 0
        local exists, selected, muted, startPpq, endPpq, chan, pitch, vel = 
            reaper.MIDI_GetNote(take, 0)
        
        while exists do
            local startPos = reaper.MIDI_GetProjQNFromPPQPos(take, startPpq)
            local endPos = reaper.MIDI_GetProjQNFromPPQPos(take, endPpq)
            
            local note = {
                selection = selected,
                mute = muted,
                startpos = startPos,
                endpos = endPos,
                chan = chan,
                pitch = pitch,
                vel = vel,
                take = take,
                idx = idx
            }
            
            if (onlySelected and selected) or not onlySelected then
                table.insert(notes, note)
            end
            
            idx = idx + 1
            exists, selected, muted, startPpq, endPpq, chan, pitch, vel = 
                reaper.MIDI_GetNote(take, idx)
        end
        
        self.existMaxNoteIdx = idx
        return notes
    end
    
    function clip:_getNotes()
        local notes = self:_getNotes_(true)
        if #notes < 1 then
            notes = self:_getNotes_(false)
        end
        return notes
    end
    
    -- Initialize
    function clip:_init(inputTake)
        self.editorHwnd = reaper.MIDIEditor_GetActive()
        self.take = inputTake or reaper.MIDIEditor_GetTake(self.editorHwnd)
        
        if not self.take then return end
        
        self.mediaItem = reaper.GetMediaItemTake_Item(self.take)
        self.editingNotes = self:_getNotes()
        self.originalNotes = deepcopy(self.editingNotes)
    end
    
    clip:_init(take)
    return clip
end

-- ============================================================================
-- MIDI CC CLASS (extends MIDI Clip)
-- ============================================================================

function createMIDIClipCC()
    local clip = createMIDIClip()
    
    clip.originalCC = {}
    clip.editingCC = {}
    clip.maxCCIdx = 0
    
    -- Flush CC events
    function clip:flush()
        self:_deleteAllOriginalCCs()
        self:_editingCCToMediaItem()
        reaper.MIDI_Sort(self.take)
    end
    
    -- Insert CC event
    function clip:insertCC(cc)
        self.maxCCIdx = self.maxCCIdx + 1
        cc.idx = self.maxCCIdx
        table.insert(self.editingCC, cc)
    end
    
    -- ========================================================================
    -- PITCH BEND GLIDE - Main Function
    -- ========================================================================
    
    function clip:PitchBendGlide(semitoneRange, resolution, lengthMs)
        -- Convert milliseconds to QN (quarter notes)
        local seconds = tonumber(lengthMs) * 0.001
        local lengthQN = reaper.TimeMap2_timeToQN(0, seconds)
        
        local notes = self:_detectTargetNotes()
        local startPositions = self:_getExistStartPosTable(notes)
        
        semitoneRange = tonumber(semitoneRange) or 12
        resolution = tonumber(resolution) or 10
        
        local stepSize = lengthQN / resolution
        local topNotes = {}
        
        -- Find top note at each position
        for _, pos in ipairs(startPositions) do
            local notesAtPos = self:_getSameStartPosNotes(pos, notes)
            
            table.sort(notesAtPos, function(a, b)
                return a.pitch < b.pitch
            end)
            
            local maxPitch = -1
            for _, note in ipairs(notesAtPos) do
                maxPitch = math.max(maxPitch, note.pitch)
            end
            
            for _, note in ipairs(notesAtPos) do
                if note.pitch == maxPitch then
                    table.insert(topNotes, note)
                end
            end
        end
        
        -- Generate pitch bend for each consecutive note pair
        for i, currentNote in ipairs(topNotes) do
            if i + 1 <= #topNotes then
                local nextNote = topNotes[i + 1]
                
                -- Calculate pitch difference (limited to semitone range)
                local pitchDiff = currentNote.pitch - nextNote.pitch
                if pitchDiff > semitoneRange then
                    pitchDiff = semitoneRange
                end
                if pitchDiff < -semitoneRange then
                    pitchDiff = -semitoneRange
                end
                
                -- Calculate pitch bend values
                local bendPerSemitone = 8192 / semitoneRange
                local totalBend = bendPerSemitone * pitchDiff
                local bendStep = totalBend / resolution
                
                -- Generate pitch bend CC events
                for step = 1, resolution do
                    local bendValue = 8192 + bendStep * (resolution - step + 1)
                    local msb = math.floor(bendValue / 128)
                    local lsb = math.floor(bendValue % 128)
                    
                    -- Clamp values to valid range
                    msb = math.max(0, math.min(127, msb))
                    lsb = math.max(0, math.min(127, lsb))
                    
                    local ccPosition = nextNote.startpos + stepSize * (step - 1)
                    
                    -- Only add CC if within note bounds
                    if ccPosition < nextNote.endpos then
                        local cc = {
                            selection = false,
                            mute = false,
                            position = ccPosition,
                            chanMsg = 224,  -- Pitch bend message
                            chan = currentNote.chan,
                            ccValue = msb,
                            ccNum = lsb,
                            take = self.take
                        }
                        self:insertCC(cc)
                    end
                end
                
                -- Reset pitch bend to center after glide
                local resetPosition = nextNote.startpos + stepSize * resolution
                if resetPosition < nextNote.endpos then
                    local resetCC = {
                        selection = false,
                        mute = false,
                        position = resetPosition,
                        chanMsg = 224,
                        chan = currentNote.chan,
                        ccValue = 64,  -- Center MSB
                        ccNum = 0,     -- Center LSB
                        take = self.take
                    }
                    self:insertCC(resetCC)
                end
            end
        end
    end
    
    -- Insert CC to media item
    function clip:_insertCCToMediaItem(cc)
        local take = self.take
        if not take then return end
        
        local selected = cc.selection or false
        local muted = cc.mute
        local ppqPos = reaper.MIDI_GetPPQPosFromProjQN(take, cc.position)
        
        reaper.MIDI_InsertCC(take, selected, muted, ppqPos, cc.chanMsg, 
                            cc.chan, cc.ccNum, cc.ccValue, false)
    end
    
    -- Write all CC events to media item
    function clip:_editingCCToMediaItem()
        for _, cc in ipairs(self.editingCC) do
            self:_insertCCToMediaItem(cc)
        end
    end
    
    -- Delete all original CC events
    function clip:_deleteAllOriginalCCs()
        while #self.originalCC > 0 do
            local lastIdx = #self.originalCC
            reaper.MIDI_DeleteCC(self.originalCC[lastIdx].take, 
                                self.originalCC[lastIdx].idx)
            table.remove(self.originalCC, lastIdx)
        end
    end
    
    return clip
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local clip = createMIDIClipCC()

if clip:checkProcessLimitNum() then
    local ok, userInput = reaper.GetUserInputs(
        "Pitch Bend Glide",
        3,
        "PitchBend range (±semitone),Glide Resolution,Glide Length (ms)",
        "12,32,80"
    )
    
    if ok then
        reaper.Undo_BeginBlock()
        
        -- Clean up input
        userInput = string.gsub(userInput, " ", "")
        local params = userInput:split(",")
        
        local semitoneRange = params[1]
        local resolution = params[2]
        local lengthMs = params[3]
        
        clip:PitchBendGlide(semitoneRange, resolution, lengthMs)
        clip:flush()
        
        reaper.Undo_EndBlock("Pitch Bend Glide", -1)
        reaper.UpdateArrange()
    end
end