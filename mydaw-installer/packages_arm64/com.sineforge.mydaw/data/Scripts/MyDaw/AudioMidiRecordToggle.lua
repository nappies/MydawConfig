-----------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end
    -----------------------------------------------------------------------------



  function MIDI_prepare(tr)
  
      if not tr then return end
    local bits_set=tonumber('111111'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
  end
  


 function Audio_prepare(tr)

    if not tr then return end
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 0.0 ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 0) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1) -- arm track
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',0) -- record MIDI out
  end





for i = 1, reaper.CountSelectedTracks(0) do
        local seltr = reaper.GetSelectedTrack(0,i-1)
        if seltr then 

 toggle = reaper.GetMediaTrackInfo_Value( seltr, 'I_RECINPUT' )
 
 
 if toggle == 0.0 then
 
 MIDI_prepare(seltr)
 
 
 
 else
 
 
 Audio_prepare(seltr) 





end


end

end

no_undo()

