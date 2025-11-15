--_MwAs


  function VF_SetTimeShiftPitchChange(item, get_only, pshift_mode0, timestr_mode0, stretchfadesz)
    -- 13.07.2021 - mod all takes
    if not item then return end
    local retval, str = reaper.GetItemStateChunk( item, '', false ) 
    
    -- get first take table of values
    local playratechunk = str:match('(PLAYRATE .-\n)') 
    local t = {} for val in playratechunk:gmatch('[^%s]+') do if  tonumber(val ) then  t[#t+1] = tonumber(val )end end
    if get_only==true then return t end 
     
    if pshift_mode0 and not timestr_mode0 and not stretchfadesz then 
      for takeidx = 1,  CountTakes( item ) do
        local take =  GetTake( item, takeidx-1 )
        if ValidatePtr2( 0, take, 'MediaItem_Take*' ) then SetMediaItemTakeInfo_Value( take, 'I_PITCHMODE',pshift_mode0  ) end
      end
      return
    end
    
    -- mod all takes
    local str_mod = str
    for playratechunk in str:gmatch('(PLAYRATE .-\n)') do
      local t = {} for val in playratechunk:gmatch('[^%s]+') do if  tonumber(val ) then  t[#t+1] = tonumber(val )end end
      if pshift_mode0 then t[4]=pshift_mode0 end      
      if timestr_mode0 then t[5]=timestr_mode0 end
      if stretchfadesz then t[6]=stretchfadesz end
      local playratechunk_out = 'PLAYRATE '..table.concat(t, ' ')..'\n'
      str_mod =str_mod:gsub(playratechunk:gsub("[%.%+%-]", function(c) return "%" .. c end), playratechunk_out)
      str_mod = str_mod:gsub('PLAYRATE .-\n', playratechunk_out)
    end
    --msg(str_mod)
    reaper.SetItemStateChunk( item, str_mod, false )
  end




-- Modes : -1 Project Default
-- 0 Soundtouch 2 Simple windowed 6 Elastique 2 pro 7 Elastique 2 Efficient
-- 8 Elastique 2 Soloist 9 Elastique 3 Pro 10 Elastique 3 Efficient 11 Elastique 3 Soloist
-- Too many submodes to list here but they follow the orders in the item properties drop down list
-- mode 6 and submode 2 sets algorithm to Elastique 2 with the Preserve Formants (Lower pitches) submode
local mode = 11
local submode = 2
for i=0,reaper.CountSelectedMediaItems(0)-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  local take = reaper.GetActiveTake(item)
  reaper.SetMediaItemTakeInfo_Value(take,"I_PITCHMODE",mode<<16|submode)
  --pshift_mode =   14<<16
        timestr_mode = 2
        --stretchfadesz = 0.005
        VF_SetTimeShiftPitchChange(item, false, pshift_mode, timestr_mode, stretchfadesz)
  
end

 reaper.UpdateArrange()

