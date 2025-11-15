function m(s)
  reaper.ShowConsoleMsg(tostring(s).."\n")
end


prompt = true -- User input dialog box
selected = false -- new notes are selected
length = 0.3 -- in seconds
chanmsg = 1
chan = 1
pitch = 36





function insert_notes_at(user_track) 
reaper.Undo_BeginBlock() 
take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())

if take ~= nil then

track_items_count = reaper.CountTrackMediaItems(user_track)

 for i = 0, track_items_count-1  do
 
    local item = reaper.GetTrackMediaItem(user_track, i) 
    local curtake = reaper.GetActiveTake(item)
    if curtake ~= nil and not reaper.TakeIsMIDI(curtake) then -- at least one audio item is selected
    local tk_volume = reaper.NF_GetMediaItemMaxPeak(item)
    reaper.SetMediaItemSelected( item, true )
  
  
    item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
		  
		
		
					
				end_time = item_pos+length
				
				if tk_volume > 0 then tk_volume = 0  
				elseif tk_volume < -60 then tk_volume = -60 
				end
				
				
				
				vel = math.floor((tk_volume+60)/(0.4724409448818898))+1
			   
				
				iPosOut = reaper.MIDI_GetPPQPosFromProjTime(take, item_pos)
				end_time = reaper.MIDI_GetPPQPosFromProjTime(take, end_time)                   
				retval = reaper.MIDI_InsertNote(take, selected, false, iPosOut, end_time, chan, pitch, vel, true)
			   
		    
		    
 end
 end
	
 reaper.MIDI_Sort(take)
	
else

reaper.ShowMessageBox( "Please select a MIDI item in the Midi Editor.", "No Midi Item", 0)
	
	end 

reaper.Undo_EndBlock("Insert MIDI notes at start of items", -1)

end

if prompt == true then

pitch =36
track = 0

retval, string = reaper.GetUserInputs("Insert Notes at Track Items start", 2, "From Track:,Notes Row (0-127):", track..","..pitch)
track,pitch = string.match(string, "([^,]+),([^,]*)")

end



if retval or prompt == false then

pitch = tonumber(pitch)

tr = reaper.CSurf_TrackFromID(tonumber(track), 0)

if pitch ~= nil then

    pitch = math.floor(pitch)
	if pitch < 0 then pitch = 0 end
	if pitch > 127 then pitch = 127 end

    insert_notes_at(tr) -- Execute your main function
    reaper.UpdateArrange()

  end

end
