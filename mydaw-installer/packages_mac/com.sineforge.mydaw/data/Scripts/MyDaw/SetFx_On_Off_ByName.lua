function m(value)
      reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

local fraise_string = "Fx name"
local do_string = "0"
local rv, rv_str = reaper.GetUserInputs("Offline/Online FX", 2, "Plug-in Name:, Off=1 / On = 0 :", fraise_string..",".. do_string)


if rv then
names, off_on = rv_str:match("([^,]+),([^,]+)")
else
return
end

off_on=tonumber(off_on)

names = string.lower(names)


-- Main function
function Main()

  for i = 0, count_tracks - 1 do
    local track = reaper.GetTrack(0,i)
    local count_fx = reaper.TrackFX_GetCount( track )
    for j = 0, count_fx - 1 do
      local retval, fx_name = reaper.TrackFX_GetFXName(track, j, "")
     fx_name = string.lower(fx_name)

        if fx_name:find(names) then

          
          reaper.TrackFX_SetOffline(track, j, off_on)
        
      end
    end
  end
end

-- INIT

  -- See if there is items selected
  count_tracks = reaper.CountTracks(0)

  if count_tracks > 0 then

    reaper.PreventUIRefresh(1)

    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

    Main()

    reaper.Undo_EndBlock("Set FX name offline/online", -1) -- End of the undo block. Leave it at the bottom of your main function.

    reaper.UpdateArrange()

    reaper.PreventUIRefresh(-1)

  end



