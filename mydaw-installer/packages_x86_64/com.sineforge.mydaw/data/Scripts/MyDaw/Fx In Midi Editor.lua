-----------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end
    -----------------------------------------------------------------------------



local mdedtr =  reaper.MIDIEditor_GetActive()
if mdedtr then 
local take = reaper.MIDIEditor_GetTake(mdedtr)
local tr =  reaper.GetMediaItemTake_Track(take)
local fxindex = reaper.TrackFX_GetInstrument(tr)
reaper.TrackFX_Show( tr, fxindex, 3 )
end


reaper.UpdateArrange()
no_undo()
