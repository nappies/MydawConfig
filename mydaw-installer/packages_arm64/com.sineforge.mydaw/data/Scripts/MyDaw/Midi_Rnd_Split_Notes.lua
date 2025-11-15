-- Idea of Kawa
local SCRIPT_NAME = "Random Rhythm Split"
local SELECT_ALL_CMD = 40815
local INVERT_SELECTION_CMD = 40659
local MAX_NOTE_LIMIT = 1000
local MIN_NOTE_RATIO = 0.05


-- 1.0 = whole note, 0.5 = half note, 0.25 = quarter note, etc.
-- ========================================
local RHYTHM_DURATIONS = {
    0.25,   -- 16th note
    0.5,    -- 8th note
    1,    -- 4th note
    --0.167,  -- 16th triplet (1/6 of a quarter note)
}


local PATTERN_LENGTH = 8        
local REST_PROBABILITY = 0.3    


math.randomseed(reaper.time_precise() * os.time() / 1000)


-- Deep copy a table
local function deepcopy(obj)
    if type(obj) ~= "table" then return obj end
    
    local copy = {}
    for key, value in pairs(obj) do
        copy[deepcopy(key)] = deepcopy(value)
    end
    return setmetatable(copy, deepcopy(getmetatable(obj)))
end



local function createMIDIHandler(take)
    local handler = {
        take = take,
        editorHwnd = reaper.MIDIEditor_GetActive(),
        allNotes = {},
        selectedNotes = {},
        editingNotes = {},
        originalNotes = {},
        maxNoteIdx = 0,
        isValid = true
    }
    
    if not take then
        handler.take = reaper.MIDIEditor_GetTake(handler.editorHwnd)
    end
    
    if not handler.take then
        handler.isValid = false
        return handler
    end
    
    handler.mediaItem = reaper.GetMediaItemTake_Item(handler.take)
    handler.mediaTrack = reaper.GetMediaItemTrack(handler.mediaItem)
    
    -- Get all MIDI notes from take
    function handler:getMIDINotes()
        reaper.PreventUIRefresh(2)
        reaper.MIDIEditor_OnCommand(self.editorHwnd, SELECT_ALL_CMD)
        reaper.MIDIEditor_OnCommand(self.editorHwnd, INVERT_SELECTION_CMD)
        reaper.PreventUIRefresh(-1)
        
        local allNotes = {}
        local selectedNotes = {}
        local idx = 0
        
        while true do
            local ok, selected, muted, startPPQ, endPPQ, chan, pitch, vel = 
                reaper.MIDI_GetNote(self.take, idx)
            
            if not ok then break end
            if idx > MAX_NOTE_LIMIT then
                reaper.ShowMessageBox(
                    "Over " .. MAX_NOTE_LIMIT .. " notes. Stop processing.",
                    "Limit Reached", 0
                )
                self.isValid = false
                return {}, {}
            end
            
            local note = {
                idx = idx,
                selection = selected,
                mute = muted,
                startQn = reaper.MIDI_GetProjQNFromPPQPos(self.take, startPPQ),
                endQn = reaper.MIDI_GetProjQNFromPPQPos(self.take, endPPQ),
                chan = chan,
                pitch = pitch,
                vel = vel,
                take = self.take
            }
            note.length = note.endQn - note.startQn
            
            table.insert(allNotes, note)
            if selected then
                table.insert(selectedNotes, note)
            end
            
            idx = idx + 1
        end
        
        self.maxNoteIdx = idx
        return allNotes, selectedNotes
    end
    
    -- Get notes to edit (selected or all)
    function handler:getEditingNotes()
        if not self.isValid then return {} end
        
        self.allNotes, self.selectedNotes = self:getMIDINotes()
        local source = (#self.selectedNotes >= 1) and self.selectedNotes or self.allNotes
        
        self.originalNotes = deepcopy(source)
        self.editingNotes = deepcopy(source)
        return self.editingNotes
    end
    
    -- Insert a new note
    function handler:insertNote(pitch, vel, startQn, endQn, chan, selected, muted)
        local note = {
            idx = self.maxNoteIdx,
            selection = selected or false,
            mute = muted or false,
            startQn = startQn,
            endQn = endQn,
            chan = chan or 1,
            pitch = pitch,
            vel = vel,
            take = self.take,
            length = endQn - startQn
        }
        
        self.maxNoteIdx = self.maxNoteIdx + 1
        table.insert(self.editingNotes, note)
        return note
    end
    
    -- Delete notes from editing list
    function handler:deleteNotes(notesToDelete)
        if notesToDelete == self.editingNotes then
            self.editingNotes = {}
            return
        end
        
        for _, noteToDelete in ipairs(notesToDelete) do
            for i, note in ipairs(self.editingNotes) do
                if note.idx == noteToDelete.idx then
                    table.remove(self.editingNotes, i)
                    break
                end
            end
        end
    end
    
    -- Write notes back to MIDI item
    function handler:flush(sortNotes)
        -- Delete original notes
        for i = #self.originalNotes, 1, -1 do
            local note = self.originalNotes[i]
            reaper.MIDI_DeleteNote(note.take, note.idx)
        end
        
        -- Insert edited notes
        for _, note in ipairs(self.editingNotes) do
            local startPPQ = reaper.MIDI_GetPPQPosFromProjQN(self.take, note.startQn)
            local endPPQ = reaper.MIDI_GetPPQPosFromProjQN(self.take, note.endQn)
            
            reaper.MIDI_InsertNote(
                self.take, note.selection, note.mute,
                startPPQ, endPPQ, note.chan, note.pitch, note.vel, true
            )
        end
        
        -- Correct overlaps
        reaper.MIDIEditor_OnCommand(self.editorHwnd, INVERT_SELECTION_CMD)
        
        if sortNotes then
            reaper.MIDI_Sort(self.take)
        end
    end
    
    return handler
end


local function generateRandomRhythm(length)
    local pattern = {}
    
    for i = 1, length do
        local isRest = math.random() < REST_PROBABILITY
        
        if isRest then
            -- Pick a random rest duration
            local restIdx = math.random(1, #RHYTHM_DURATIONS)
            table.insert(pattern, -RHYTHM_DURATIONS[restIdx])
        else
            -- Pick a random note duration
            local noteIdx = math.random(1, #RHYTHM_DURATIONS)
            table.insert(pattern, RHYTHM_DURATIONS[noteIdx])
        end
    end
    
    return pattern
end


local function splitNotesByRhythm(pattern, noteRatio)
    local handler = createMIDIHandler()
    local notes = handler:getEditingNotes()
    
    if #notes < 1 or not handler.take or #pattern < 1 then
        return
    end
    
    noteRatio = (noteRatio and noteRatio >= MIN_NOTE_RATIO) and noteRatio or 0.8
    
    local newNotes = {}
    local notesToDelete = {}
    
    for _, originalNote in ipairs(notes) do
        local noteEnd = originalNote.endQn
        local currentPos = originalNote.startQn
        local continueLoop = true
        
        while continueLoop do
            for _, duration in ipairs(pattern) do
                if duration > 0 then
                    -- Positive value = note
                    local noteLength = duration * noteRatio
                    
                    local newNote = deepcopy(originalNote)
                    newNote.startQn = currentPos
                    newNote.endQn = currentPos + noteLength
                    newNote.length = noteLength
                    newNote.selection = true
                    
                    if newNote.endQn > noteEnd then
                        continueLoop = false
                        break
                    else
                        table.insert(newNotes, newNote)
                        currentPos = currentPos + duration
                    end
                else
                    -- Negative value = rest
                    currentPos = currentPos + math.abs(duration)
                    if currentPos >= noteEnd then
                        continueLoop = false
                        break
                    end
                end
            end
        end
        
        table.insert(notesToDelete, originalNote)
    end
    
    handler:deleteNotes(notesToDelete)
    
    for _, note in ipairs(newNotes) do
        handler:insertNote(note.pitch, note.vel, note.startQn, note.endQn, 
                          note.chan, note.selection, note.mute)
    end
    
    handler:flush(true)
end



local function randomRhythmSplit()




   
    local noteRatio = math.random() * 0.3 + 0.6  -- 0.6 to 0.9
    
    -- Generate random rhythm pattern
    local pattern = generateRandomRhythm(PATTERN_LENGTH)
    
    -- Apply the pattern
    splitNotesByRhythm(pattern, noteRatio)
    
    reaper.Undo_OnStateChange2(0, SCRIPT_NAME)
end


-- Handle undo if this script was just run
if SCRIPT_NAME == reaper.Undo_CanUndo2(0) then
    reaper.PreventUIRefresh(30)
    reaper.Undo_DoUndo2(0)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end


-- Execute the random split
randomRhythmSplit()