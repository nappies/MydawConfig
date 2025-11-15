package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")




local change =  1  ---Increase in DB
local length =  3 * 0.001  ---Fade Length





local function eq( a, b )
  return math.abs( a - b ) < 0.00001
end


---------------------------------



function RazorEditSelectionExists()

    for i=0, reaper.CountTracks(0)-1 do

        local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end
    
    return false

end



local undo_str = "Decrease Volume"
change = 10 ^ ( change / 20 )
local undo = false
local vol_env = "\n<VOLENV\nEGUID " .. reaper.genGuid("") ..
"\nACT 1 -1\nVIS 0 1 1\nLANEHEIGHT 0 0\nARM 1\nDEFSHAPE 0 -1 -1\nVOLTYPE 1\nPT 0 1 0\n>\n"

local function EnableTakeVol(take, item)
  local takeGUID = TakeToGuid(take)
  local take_cnt = reaper.CountTakes( item )
  local fx_count = reaper.TakeFX_GetCount( take )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local t = {}
  local i = 0
  local insert
  local foundTake = take_cnt == 1
  local search_take_end = true
  for line in chunk:gmatch("[^\n]+") do
    i = i + 1
    t[i] = line
    if not foundTake then
      if line:find(takeGUID:gsub("-", "%%-")) then
      foundTake = true
      end
    end
    if foundTake then
      if (not insert) and i > 30 then
        if line:find("^<.-ENV$") then
          insert = i
        elseif fx_count > 0 then
          if line:find("^TAKE_FX_HAVE_") then
            insert = i + 1
          end
        end
      end
      if not insert and search_take_end and line == ">" then
        search_take_end = false
        insert = i + 1
      end
    end
  end
  chunk = table.concat(t, "\n", 1, insert-1 ) .. vol_env .. table.concat(t, "\n", insert )
  reaper.SetItemStateChunk( item, chunk, true )
  return reaper.GetTakeEnvelopeByName( take, "Volume" )
end

local function adjustPoints(env, id1, id2, mode, change)
  for id = id1, id2 do
    local _, time, val, shape, tens, sel = reaper.GetEnvelopePoint( env, id )
    local newval = mode == 0 and val*change or
           reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val )*change))
    reaper.SetEnvelopePoint( env, id, time, newval, shape, tens, sel, true )
  end
end

reaper.PreventUIRefresh( 1 )


razorEdits = GetRazorEdits()


      for i = 1, #razorEdits do
          local areaData = razorEdits[i]
          if not areaData.isEnvelope then
            
            local items = areaData.items
            
            for i = 1, #items do
                  local item = items[i]
                  local take = reaper.GetActiveTake( item )
                  local ST, EN = areaData.areaStart, areaData.areaEnd
          local playrate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
                  local position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                  local End = position + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                  local inside_area = true
                  if position >= EN or End <= ST then inside_area = false end
                  if inside_area then
                  if ST < position then ST = position end
                  if EN > End then EN = End end
                  local env = reaper.GetTakeEnvelopeByName( take, "Volume" )
                  if not env or not reaper.ValidatePtr2( 0, env, "TrackEnvelope*" ) then env = EnableTakeVol(take, item) end
                  local mode = reaper.GetEnvelopeScalingMode( env )
                  local ST_in_item = (ST - position+0.01)* playrate
                  local EN_in_item = (EN - position)* playrate
                  local id1 = reaper.GetEnvelopePointByTime( env, ST_in_item )
                  local id2 = reaper.GetEnvelopePointByTime( env, EN_in_item )
                  local _, time = reaper.GetEnvelopePoint( env, id1 )
                  local _, time2 = reaper.GetEnvelopePoint( env, id2 )
                  if eq(time, ST_in_item) and eq(time2, EN_in_item) then
                    adjustPoints(env, id1, id2, mode, change)
                  else
        


              if eq(time, ST_in_item) and (not eq(time2, EN_in_item)) then
          
      
              local samplerate = reaper.GetMediaSourceSampleRate( reaper.GetMediaItemTake_Source( take ) )
              local _, val2 = reaper.Envelope_Evaluate( env, EN_in_item + length, samplerate, 5 )
              local newval2 = mode == 0 and val2*change or
                 reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val2 )*change))
              local noSorted = true
              if id1 ~= id2 then
              noSorted = false
              end
              reaper.InsertEnvelopePoint( env, EN_in_item, newval2, 0, 0, 0, noSorted )
              reaper.InsertEnvelopePoint( env, EN_in_item + length, val2, 0, 0, 0, noSorted )
              if not noSorted then
              adjustPoints(env, id1 + 3, id2 + 2, mode, change)
              end

                  
              elseif (not eq(time, ST_in_item)) and eq(time2, EN_in_item) then
          
              
              local samplerate = reaper.GetMediaSourceSampleRate( reaper.GetMediaItemTake_Source( take ) )
              local _, val1 = reaper.Envelope_Evaluate( env, ST_in_item - length, samplerate, 5 )
              local newval1 = mode == 0 and val1*change or
                 reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val1 )*change))
              local noSorted = true
              if id1 ~= id2 then
              noSorted = false
              end
              reaper.InsertEnvelopePoint( env, ST_in_item - length, val1, 0, 0, 0, noSorted )
              reaper.InsertEnvelopePoint( env, ST_in_item, newval1, 0, 0, 0, noSorted )
              if not noSorted then
              adjustPoints(env, id1 + 3, id2 + 2, mode, change)
              end
      
          
               else
         
        
          
              local samplerate = reaper.GetMediaSourceSampleRate( reaper.GetMediaItemTake_Source( take ))
              local _, val1 = reaper.Envelope_Evaluate( env, ST_in_item - length, samplerate, 5 )
              local _, val2 = reaper.Envelope_Evaluate( env, EN_in_item + length, samplerate, 5 )
              local newval1 = mode == 0 and val1*change or
                 reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val1 )*change))
              local newval2 = mode == 0 and val2*change or
                 reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val2 )*change))
              local noSorted = true
              if id1 ~= id2 then
              noSorted = false
              end
              reaper.InsertEnvelopePoint( env, ST_in_item - length, val1, 0, 0, 0, noSorted )
              reaper.InsertEnvelopePoint( env, ST_in_item, newval1, 0, 0, 0, noSorted )
              reaper.InsertEnvelopePoint( env, EN_in_item, newval2, 0, 0, 0, noSorted )
              reaper.InsertEnvelopePoint( env, EN_in_item + length, val2, 0, 0, 0, noSorted )
              if not noSorted then
              adjustPoints(env, id1 + 3, id2 + 2, mode, change)
            end
 
          
          
          end
        
          
          end
                  reaper.Envelope_SortPoints( env )
                  undo = true
                  end
                end

       

        end
    end

reaper.PreventUIRefresh( -1 )

if undo then
  reaper.Undo_OnStateChangeEx( undo_str, 1, -1 )
else
  reaper.defer(function() end)
end
