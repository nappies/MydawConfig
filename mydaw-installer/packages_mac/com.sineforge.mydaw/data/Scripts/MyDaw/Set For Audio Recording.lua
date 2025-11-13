-----------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end
    -----------------------------------------------------------------------------

-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694


  function Audio_prepare(tr)
    local tr = reaper.GetLastTouchedTrack()
    if not tr then return end

    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 0.0 ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 0) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
  end
  
  Audio_prepare()
    
    
    reaper.UpdateArrange()
    no_undo()
