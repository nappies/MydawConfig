function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
 end

function def()
end

  local transpose = 0
  local r_start = 0
  local r_end = 127

items = reaper.CountSelectedMediaItems(0)
if items > 0 then
  retval, string = reaper.GetUserInputs("Transpose items except keyswitches", 3, "Transpose:,Lower limit(0-127):,Upper limit(0-127):", transpose..","..r_start..","..r_end)
  transpose, r_start, r_end = string.match(string, "([^,]+),([^,]*),([^,]*)")
  
 transpose =  tonumber(transpose)
 r_start =  tonumber(r_start)
 r_end = tonumber(r_end)
 
 if (r_start < 0 or r_start > 127)or (r_end < 0 or r_end > 127) then reaper.ShowMessageBox( "Some Numbers is out of range ", "Error",0 ) return end
 if r_start > r_end then  reaper.ShowMessageBox( "Lower limit is greater than Upper limit ", "Error",0 ) return end 
  
  
  if retval == true then 
  
    script_title = "Transpose items except keyswitches"
    reaper.Undo_BeginBlock()
    
    for i = 0, items-1 do
      it = reaper.GetSelectedMediaItem(0, i)
      takes = reaper.CountTakes(it)
      for t = 0, takes-1 do
        take = reaper.GetTake(it, t)
        midi = reaper.TakeIsMIDI(take)
        if midi == true then
          _, notes = reaper.MIDI_CountEvts(take)
          for n = 0, notes-1 do
            retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
            if pitch > r_start and pitch < r_end then
            reaper.MIDI_SetNote(take, n, sel, muted, startppq, endppq, chan, pitch + transpose, vel)
          end
          end
        else
          t_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
          reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH', t_pitch + transpose)
        end
      end
      reaper.UpdateItemInProject(it)
    end

    reaper.Undo_EndBlock(script_title, -1)
  else
    reaper.defer(def)
  end
else
  reaper.defer(def)
end
