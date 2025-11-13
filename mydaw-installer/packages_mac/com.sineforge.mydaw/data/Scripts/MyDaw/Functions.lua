


function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
 end


-----------------------

function GetEnvelopePointsInRange(envelopeTrack, areaStart, areaEnd)
    local envelopePoints = {}

    for i = 1, reaper.CountEnvelopePoints(envelopeTrack) do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelopeTrack, i - 1)

        if time >= areaStart and time <= areaEnd then --point is in range
            envelopePoints[#envelopePoints + 1] = {
                id = i-1 ,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
        end
    end

    return envelopePoints
end


-----------------------

function GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        
        if areaBottom ~= nil then
          itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
          itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
          --msg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
        end

        --check if item is in area bounds
        if itemEndPos > areaStart and pos < areaEnd then
        
          if areaBottom and itemTop then
            if itemTop < areaBottom - 0.001 and itemBottom > areaTop + 0.001 then
              table.insert(items,item)
            end
          else
            table.insert(items,item)
          end
          
        end

    end --end for cycle

    return items
end




-----------------------
-----------------------

function ParseAreaPerLane(RawTable, itemH) --one level metatable
  local ParsedTable = {}
  local PreParsedTable = {}
  
  local lanesN = math.floor((1/itemH)+0.5)
  local laneW = 1/lanesN
  
  for i=1, lanesN do
    PreParsedTable[i] = {}
  end
  
  ---------------
  for i=1, #RawTable do
      --area data
      local areaStart = tonumber(RawTable[i][1])
      local areaEnd = tonumber(RawTable[i][2])
      local GUID = RawTable[i][3]
      local areaTop = tonumber(RawTable[i][4])
      local areaBottom = tonumber(RawTable[i][5])
      
    if not isEnvelope then
      areaWidth = math.floor(((areaBottom - areaTop)/itemH)+0.5) -- how many lanes include
      for w=1, areaWidth do
        local areaLane = math.floor((areaBottom/(laneW*w))+0.5)
        --msg(areaLane)
        local smallRect = {
        
              areaStart,
              areaEnd,
              GUID,
              areaBottom - (laneW*w), --areaTop
              areaBottom - (laneW*(w-1)), --areaBottom
              }

        table.insert(PreParsedTable[areaLane], smallRect)
      end
    else
      table.insert(ParsedTable, RawTable[i])
    end
    
  end
  -------------
  
  for i=1, #PreParsedTable do
    local lane = PreParsedTable[i]
    local prevEnd = nil
    for r=1, #lane do
      local smallRect = lane[r]
      
      if prevEnd ~= smallRect[1] then
        table.insert(ParsedTable, smallRect)
      else
        ParsedTable[#ParsedTable][2] = smallRect[2]
      end
      
      prevEnd = smallRect[2]
    end
  end
  
  return ParsedTable
end

-----------------------
-----------------------

function GetRazorEdits()
    local NeedPerLane = true
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local mode = reaper.GetMediaTrackInfo_Value(track,"I_FREEMODE")
        if mode ~= 0 then
        ----NEW WAY----
        --reaper.ShowConsoleMsg("NEW WAY\n")
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', '', false)
          
        if area ~= '' then

            --PARSE STRING and CREATE TABLE
            local TRstr = {}
            
            for s in area:gmatch('[^,]+')do
              table.insert(TRstr, s)
            end
            
            for i=1, #TRstr do
            
              local rect = TRstr[i]
              TRstr[i] = {}
              for j in rect:gmatch("%S+") do
                table.insert(TRstr[i], j)
              end
              
            end
            
            local testItemH = reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,0), "F_FREEMODE_H")
            
            local AreaParsed = ParseAreaPerLane(TRstr, testItemH)
            
            local TRareaTable
            if NeedPerLane == true then TRareaTable = AreaParsed else TRareaTable = TRstr end
        
            --FILL AREA DATA
            local i = 1
            
            while i <= #TRareaTable do
                --area data
                local areaStart = tonumber(TRareaTable[i][1])
                local areaEnd = tonumber(TRareaTable[i][2])
                local GUID = TRareaTable[i][3]
                local areaTop = tonumber(TRareaTable[i][4])
                local areaBottom = tonumber(TRareaTable[i][5])
                local isEnvelope = GUID ~= '""'
                

                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                --reaper.ShowConsoleMsg(areaTop.." "..areaBottom.."\n\n")
                    items = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end

                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    areaTop = areaTop,
                    areaBottom = areaBottom,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }

                table.insert(areaMap, areaData)

                i=i+1
            end
          end
        else  
        
        ---OLD WAY for backward compatibility-------
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
           if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
        
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                --area data
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j+1])
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
        
                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                    items = GetItemsInRange(track, areaStart, areaEnd)
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end
        
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }
        
                table.insert(areaMap, areaData)
        
                j = j + 3
            end
          end  ---OLD WAY END
        end
    end

    return areaMap
end

--------------------------------



function IsRazorEdits()
    local israzoredit = false
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
        if area ~= "" then
            israzoredit = true
        end
    end
    return israzoredit
end


function SetFirstRazorEditTrackAsLastTouched()
    local track_count = reaper.CountTracks(0)
    if track_count == 0 then
        return
    end

    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local _, razor_edit = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

        if razor_edit and razor_edit ~= "" then
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1 - (reaper.IsTrackSelected(track) and 1 or 0))
            return
        end
    end
   
end


-- Function to save razor edits to the global table with vertical positions
function SaveRazorEdits()
    local rzr_edits = {}
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local _, razor_edit = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS_EXT", "", false)
        if razor_edit ~= "" then
            table.insert(rzr_edits, {track = track, razor_edit = razor_edit})
        end
    end
    return rzr_edits  
end

-- Function to get Razor Edits without envelopes, including vertical positions
function GetRazorWithoutEnv()
    local rzrEd = {}
    local trackCount = reaper.CountTracks(0)

    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS_EXT", "", false)

        if retval and razorStr ~= "" then
            local newRazorStr = ""
            for startPos, endPos, guid, areaTop, areaBottom in string.gmatch(razorStr, "([%d%.]+) ([%d%.]+) (.-) ([%d%.]+) ([%d%.]+)") do
                if guid == "\"\"" then -- Ensure it's not an envelope
                    newRazorStr = newRazorStr .. startPos .. " " .. endPos .. " " .. guid .. " " .. areaTop .. " " .. areaBottom .. "\n"
                end
            end

            if newRazorStr ~= "" then
                table.insert(rzrEd, {track = track, razor_edit = newRazorStr})
            end
        end
    end

    return rzrEd
end

-- Function to restore razor edits from the saved table with vertical positions
function RestoreRazorEdits(razor_edits)
    for _, data in ipairs(razor_edits) do
        reaper.GetSetMediaTrackInfo_String(data.track, "P_RAZOREDITS_EXT", data.razor_edit, true)
    end
end











function SnapNextGridLine(pos)
    reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap
local cursorpos = reaper.GetCursorPosition()
local grid_duration
if reaper.GetToggleCommandState( 41885 ) == 1 then -- Toggle framerate grid
  grid_duration = 0.4/reaper.TimeMap_curFrameRate( 0 )
else
  local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
  local tmsgn_cnt = reaper.CountTempoTimeSigMarkers( 0 )
  local _, tempo
  if tmsgn_cnt == 0 then
    tempo = reaper.Master_GetTempo()
  else
    local active_tmsgn = reaper.FindTempoTimeSigMarker( 0, cursorpos )
    _, _, _, _, tempo = reaper.GetTempoTimeSigMarker( 0, active_tmsgn )
  end
  grid_duration = 60/tempo * division
end


local snapped, grid = reaper.SnapToGrid(0, cursorpos)
if snapped > cursorpos then
  grid = snapped
else
  grid = cursorpos
  while (grid <= cursorpos) do
      cursorpos = cursorpos + grid_duration
      grid = reaper.SnapToGrid(0, cursorpos)
  end
end

reaper.Main_OnCommand(40756, 0) -- Snapping:
 
 return grid
end





function SnapNextGridLine(pos)
    reaper.Main_OnCommand(40755, 0) --Snapping: Save snap state
    reaper.Main_OnCommand(40754, 0) --- Snapping: Disable snap
    local grid = pos
    while (grid <= pos) do
        pos = pos + 0.05
        grid = reaper.SnapToGrid(0, pos)
    end
    reaper.Main_OnCommand(40756, 0) ---Snapping: Restore snap state
    return grid
end





function SnapPrevGridLine(pos)
    reaper.Main_OnCommand(40755, 0) --Snapping: Save snap state
    reaper.Main_OnCommand(40754, 0) --- Snapping: Disable snap
    local grid = pos
    if pos > 0 then
        while (grid >= pos) do
            pos = pos - 0.05
            grid = reaper.SnapToGrid(0, pos)
        end
    end
    reaper.Main_OnCommand(40756, 0) ---Snapping: Restore snap state
    return grid
end



function SetToggleAct(action, state)
    if reaper.GetToggleCommandState(action) == 1 ~= state then
    reaper.Main_OnCommand(action, 0)
end
end


function UnselectAllTracks()
   while (reaper.CountSelectedTracks(0) > 0) do
     reaper.SetTrackSelected(reaper.GetSelectedTrack(0, 0), false)
   end
 end
 

function SelTracksWItems()
lasttr = nil
  UnselectAllTracks()
   for  i = 1, reaper.CountTracks(0) do
     tr =  reaper.GetTrack(0,i-1);
     for j = 1,  reaper.CountTrackMediaItems(tr)do
    
       if  reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(tr, j-1)) then
    lasttr = tr
        reaper.SetTrackSelected( tr, true )
         break
      end
    end
  end
    return lasttr
end 

function UnselectAllItems()
  while (reaper.CountSelectedMediaItems(0) > 0) do
    reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, 0), false)
  end
end




function SaveSelectedTracks (table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

function RestoreSelectedTracks (table)
  UnselectAllTracks()
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track, true)
  end
end

function esc (str)
str = str:gsub('%(', '%%(')
str = str:gsub('%)', '%%)')
str = str:gsub('%.', '%%.')
str = str:gsub('%+', '%%+')
str = str:gsub('%-', '%%-')
str = str:gsub('%$', '%%$')
str = str:gsub('%[', '%%[')
str = str:gsub('%]', '%%]')
str = str:gsub('%*', '%%*')
str = str:gsub('%?', '%%?')
str = str:gsub('%^', '%%^')
str = str:gsub('/', '%%/')
return str end




local function escape_lua_pattern(s)
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
  return (s:gsub(".", matches))
end

function TakeToGuid(take)
 
  retval,takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, "GUID", "", false)
  return takeGUID
end


function GuidToItem(guid)

  if guid then
    for i = 0, reaper.CountMediaItems(0)-1 do
    it = reaper.GetMediaItem(0, i)
    local retval, item_guid = reaper.GetSetMediaItemInfo_String(it, "GUID", "", false)
    if string.match(guid, escape_lua_pattern(reaper.guidToString(item_guid, "" ))) then
          return it
    end  
    end
  
  end
 return nil
end



function GuidToTake(guid)
  if not guid then return nil end

  local numItems = reaper.CountMediaItems(0)
  for i = 0, numItems - 1 do
    local it = reaper.GetMediaItem(0, i)
    if it then
      local cntTakes = reaper.CountTakes(it)
      for t = 0, cntTakes - 1 do
        local take = reaper.GetTake(it, t)
        if take then
          local retval, take_guid = reaper.GetSetMediaItemTakeInfo_String(take, "GUID", "", false)
          if take_guid and string.match(guid, escape_lua_pattern(reaper.guidToString(take_guid, ""))) then
            return take
          end
        end
      end
    end
  end

  return nil
end

function GuidToTrack(guid)
  if not guid then return nil end

  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local tr = reaper.GetTrack(0, i)
    local retval, track_guid = reaper.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
    if retval and track_guid then
      local guid_str = reaper.guidToString(track_guid, "")
      if string.match(guid, escape_lua_pattern(guid_str)) then
        return tr
      end
    end
  end

  return nil
end




function SaveSelectedItems(table)

  
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
  
end
-- RESTORE INITIAL SELECTED ITEMS



function RestoreSelectedItems(table)
  UnselectAllItems() -- Unselect all items
  if table ~= nil then 
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
  end
end





function unsel_not_visible_tracks()
  local count_tracks = reaper.CountTracks(0)
  for i=0, count_tracks-1 do
    local get_track = reaper.GetTrack(0, i)
    local get_visible_TCP = reaper.GetMediaTrackInfo_Value(get_track, 'B_SHOWINTCP')
    local get_visible_MCP = reaper.GetMediaTrackInfo_Value(get_track, 'B_SHOWINMIXER')
    if get_visible_TCP == 0 and get_visible_MCP == 0 then
      reaper.SetTrackSelected(get_track, 0)
    end  
  end
end 





function GetRazorStartEnd()
    left, right = math.huge, -math.huge
    for t = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, t)
        local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
        if razorOK and #razorStr ~= 0 then
            for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
                if razorLeft < left then
                    left = razorLeft
                end
                if razorRight > right then
                    right = razorRight
                end
            end
        end
    end

  return left, right
end



function GetItemsStartEnd()
    left, right = math.huge, -math.huge
    for t = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, t)
    local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local itemEnd = itemPos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                if itemPos < left then
                    left = itemPos
                end
                if itemEnd > right then
                    right = itemEnd
                end
    end

  return left, right
end







function DelNameTrash(deltrash)
    if (reaper.CountSelectedMediaItems(0) == 0) then
        return
    end

    function string:split(e)
        local a, e = e or ":", {}
        local a = string.format("([^%s]+)", a)
        self:gsub(
            a,
            function(a)
                e[#e + 1] = a
            end
        )
        return e
    end

    if (reaper.CountSelectedMediaItems(0) > 0) then
        reaper.Undo_BeginBlock()

        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local take = reaper.GetTake(item, reaper.GetMediaItemInfo_Value(item, "I_CURTAKE"))
            if (take ~= nil) then
                local retval, tname = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                local edit = tname
                edit = string.match(edit, "(.*)%.") or edit
        strash = "(.*)"..deltrash
                edit = string.match(edit, strash) or edit
                item, tname = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", edit, true)
            else
                local ret, edit = reaper.GetItemStateChunk(item, "", false)
                local tname = edit:split("\n")
                for a, edit in ipairs(tname) do
                    if (string.match(edit, "^<NOTES")) then
                        local edit = 0
                        a = a + 1
                        while (string.match(tname[a], "^|")) do
                            if (edit > 100 or a > #tname) then
                                break
                            end
                            edit = edit + 1
                            local edit = tname[a]
                            edit = string.gsub(tname[a], "|", "") or edit
                            edit = string.match(edit, "(.*)%.") or edit
                            trash = "(.*)"..deltrash
                            edit = string.match(edit, trash) or edit
                            tname[a] = "|" .. edit
                            a = a + 1
                        end
                    end
                end
                local edit = ""
                for tname, a in ipairs(tname) do
                    edit = edit .. a .. "\n"
                end
                reaper.SetItemStateChunk(item, e, false)
            end
        end

        reaper.Undo_EndBlock("Delete Trash Name", -1)
        reaper.UpdateArrange()
    end
end

----Thanks MeoAda!!

function IsReaperRendering()

  local A,B=reaper.EnumProjects(0x40000000,"")  
  if A~=nil then 
    return true
  else return false 
  end
end


function WaitAction(count)
    count_new = reaper.GetProjectStateChangeCount(0)
    if (count + 1) ~= count_new then
        reaper.defer(WaitAction(count)) m("I am wait".." "..count_new)
    else
      m("Go ahead".." "..count_new)
  end
end


function GetLoudnessData()
 local stats_table = {}
    local ret, stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42437", false)
    if ret then
        for a,b in stats:gmatch("(%u-):([^;]+)") do
          if a ~= "FILE" then
            stats_table[a] = tonumber(b)
          end
        end

      --  for k,v in pairs(stats_table) do
     --     reaper.ShowConsoleMsg(k.." "..v.." ")
     --  end
   
    end
  return stats_table.LRA,stats_table.PEAK,stats_table.LUFSSMAX,stats_table.LUFSI,stats_table.RMSI, stats_table.CLIP,stats_table.LUFSMMAX
end


-- _,peak,_,_,_,_,_ = GetLoudnessData()






function MixdownToTrack(mono_stereo)

tail = 0 --sec

name = 'Mixdown'

time_selection = 1

pre_render_length = 0
   
trim_start = 1

---------------------------------------

local values_for_render = tostring(tail)
..","..tostring(name)
..","..tostring(time_selection)
..","..tostring(mono_stereo)
..","..tostring(pre_render_length)
..","..tostring(trim_start)


if reaper.CountSelectedMediaItems(0) == 0 then  return end

reaper.Main_OnCommand(40635,0) --remove TS


local function Create_global_folder_for_render()
  local track_for_folder = reaper.GetTrack(0,0)
    if track_for_folder then
      local numb = reaper.GetMediaTrackInfo_Value(track_for_folder,"IP_TRACKNUMBER")
      reaper.InsertTrackAtIndex(numb-1,false)
      local track_for_folder_two = reaper.GetTrack(0,numb-1)
        reaper.SetMediaTrackInfo_Value(track_for_folder_two, 'I_FOLDERDEPTH', 1)
        reaper.SetOnlyTrackSelected(track_for_folder_two)
    end
end


if reaper.CountSelectedMediaItems(0) == 0 then return end


     local val1, name1, val2, val3, val4, val5  = values_for_render:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
     local val_tail = tonumber(val1)
     local val_name = tostring(name1)
     local val_timesel = tonumber(val2)
     local val_chan = tonumber(val3)
     local val_pre = tonumber(val4)
     local val_trim = tonumber(val5)

        
        init_sel_items = {}
        
        SaveSelectedItems(init_sel_items)
        
        for i=reaper.CountSelectedMediaItems(0), 0, -1 do
          local get_sel_item = reaper.GetSelectedMediaItem(0,i)
          if get_sel_item then
            if reaper.GetMediaItemInfo_Value(get_sel_item, 'B_MUTE') == 1 then
              reaper.SetMediaItemSelected(get_sel_item, 0)
            end
          end
        end

        reaper.Main_OnCommand(41559, 0) -- solo items
        
     local lasttrack =  SelTracksWItems()

        Create_global_folder_for_render()
        
         
        local save_selection_start, save_selection_end = reaper.GetSet_LoopTimeRange(0, false, 0, 0, 0)
        local save_cursor_position = reaper.GetCursorPosition()
         
           
        local render_selection_start, render_selection_end = GetRazorStartEnd()
       reaper.GetSet_LoopTimeRange(1, false, render_selection_start-val_pre, render_selection_end+val_tail, 0)
          
          
           local count_tracks_1 = reaper.CountTracks(0)

           if val_chan == 1 then
              reaper.Main_OnCommand(41718, 0) -- Render mono
           elseif val_chan >= 2 then
              reaper.Main_OnCommand(41716, 0) -- Render stereo
           end


           local get_selected_track_render = reaper.GetSelectedTrack(0,0)
       
       
     
    
       
       
       
       
            if reaper.GetMediaTrackInfo_Value(get_selected_track_render, 'I_FOLDERDEPTH') == 1 then 
              reaper.DeleteTrack(get_selected_track_render) else
              reaper.GetSetMediaTrackInfo_String(get_selected_track_render, 'P_NAME',val_name,true)
              local get_item_item = reaper.GetTrackMediaItem(get_selected_track_render, 0)
              if get_item_item then
                local get_take_get = reaper.GetActiveTake(get_item_item)
                if get_take_get then
                reaper.GetSetMediaItemTakeInfo_String(get_take_get, 'P_NAME', val_name, true)
                local get_number_track = reaper.GetMediaTrackInfo_Value(get_selected_track_render,"IP_TRACKNUMBER")
                local get_folder_track = reaper.GetTrack(0, get_number_track)
                  reaper.DeleteTrack(get_folder_track)
                  local count_tr = reaper.CountTracks(0)
                  reaper.ReorderSelectedTracks(count_tr,0)
                end
              end
            end
            
            local count_tracks_2 = reaper.CountTracks(0)
                                
                     if val_trim > 0 and val_pre > 0 then
                          if count_tracks_1 == count_tracks_2 then
                            local get_selected_track_ren = reaper.GetSelectedTrack(0,0)
                            local get_sel_it = reaper.GetTrackMediaItem(get_selected_track_ren, 0)
                            reaper.SplitMediaItem(get_sel_it, render_selection_start)
                            local get_sel = reaper.GetTrackMediaItem(get_selected_track_ren, 0)
                            reaper.DeleteTrackMediaItem(get_selected_track_ren, get_sel)
                        end
                      end   
        
        
   reaper.GetSet_LoopTimeRange(1, false, save_selection_start, save_selection_end, 0)  
     reaper.SetEditCurPos(save_cursor_position, 0, 0)     
        
    reaper.Main_OnCommand(41560, 0) -- unsolo items
    
    
 reaper.ReorderSelectedTracks(reaper.GetMediaTrackInfo_Value(lasttrack, "IP_TRACKNUMBER"),0)
    
 if (init_sel_items) ~= nil then
RestoreSelectedItems(init_sel_items)
end

return  get_selected_track_render
  
end





function close_tr_fx(tr)
  local fx = reaper.TrackFX_GetCount(tr)
  for i = 0,fx-1 do
    if reaper.TrackFX_GetOpen(tr, i) then
      reaper.TrackFX_SetOpen(tr, i, 0)
    end
    if reaper.TrackFX_GetChainVisible(tr)~=-1 then
      reaper.TrackFX_Show(tr, 0, 0)
    end
  end

  local rec_fx = reaper.TrackFX_GetRecCount(tr)
  for i = 0,rec_fx-1 do
    i_rec = i+16777216
    if reaper.TrackFX_GetOpen(tr, i_rec) then
      reaper.TrackFX_SetOpen(tr, i_rec, 0)
    end
    if reaper.TrackFX_GetRecChainVisible(tr)~=-1 then
      reaper.TrackFX_Show(tr, i_rec, 0)
    end
  end

end

function close_tk_fx(tk)
  if not tk then return end
  local fx = reaper.TakeFX_GetCount(tk)
  for i = 0,fx-1 do
    if reaper.TakeFX_GetOpen(tk, i) then
      reaper.TakeFX_SetOpen(tk, i, 0)
    end
    if reaper.TakeFX_GetChainVisible(tk)~=-1 then
      reaper.TakeFX_Show(tk, 0, 0)
    end
  end
end



function SelTracksWItems()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- clear selection on all tracks first
  local numTracks = reaper.CountTracks(0)
  for i = 0, numTracks - 1 do
    local tr = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(tr, "I_SELECTED", 0)
  end

  -- select tracks that contain at least one UI-selected item
  for i = 0, numTracks - 1 do
    local tr = reaper.GetTrack(0, i)
    local itemCount = reaper.CountTrackMediaItems(tr)
    for j = 0, itemCount - 1 do
      local item = reaper.GetTrackMediaItem(tr, j)
      if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1.0 then
        reaper.SetMediaTrackInfo_Value(tr, "I_SELECTED", 1)
        break
      end
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Select tracks with selected items", -1)
end



function DoSelectLastOfSelectedTracks()
  local numTracks = reaper.CountTracks(0)
  local selectedTracks = {}

  -- collect selected tracks
  for i = 0, numTracks - 1 do
    local track = reaper.GetTrack(0, i)
    if reaper.IsTrackSelected(track) then
      table.insert(selectedTracks, track)
    end
  end

  if #selectedTracks > 0 then
    -- unselect all tracks
    reaper.Main_OnCommand(40297, 0)
    -- select last one from previously selected
    local lastTrack = selectedTracks[#selectedTracks]
    reaper.SetTrackSelected(lastTrack, true)
  end
end





-- Adjust takes start offset and stretch markers
function AdjustTakesStartOffset(item, adjustment)
  local numTakes = reaper.GetMediaItemNumTakes(item)
  
  for i = 0, numTakes - 1 do
    local take = reaper.GetMediaItemTake(item, i)
    local startOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local takeAdjust = adjustment * playRate
    
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", startOffset - takeAdjust)
    
    local numMarkers = reaper.GetTakeNumStretchMarkers(take)
    for j = 0, numMarkers - 1 do
      local retval, pos, srcpos = reaper.GetTakeStretchMarker(take, j)
      reaper.SetTakeStretchMarker(take, j, pos + takeAdjust)
    end
  end
  
  reaper.UpdateItemInProject(item)
end

-- Main trim/fill function
function AWTrimFill()
  local selStart, selEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  local cursorPos = reaper.GetCursorPosition()
  local numTracks = reaper.CountTracks(0)
  
  for iTrack = 0, numTracks - 1 do
    local tr = reaper.GetTrack(0, iTrack)
    local numItems = reaper.CountTrackMediaItems(tr)
    
    for iItem1 = 0, numItems - 1 do
      local item1 = reaper.GetTrackMediaItem(tr, iItem1)
      local isSelected = reaper.IsMediaItemSelected(item1)
      
      if isSelected then
        local dStart1 = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
        local dLen1 = reaper.GetMediaItemInfo_Value(item1, "D_LENGTH")
        local dEnd1 = dStart1 + dLen1
        
        local leftFlag = false
        local rightFlag = false
        
        -- If time selection crosses either edge of the item
        if (selStart < dEnd1 and selEnd > dEnd1) or (selStart < dStart1 and selEnd > dStart1) then
          
          -- Check for other selected items on the same track
          for iItem2 = 0, numItems - 1 do
            local item2 = reaper.GetTrackMediaItem(tr, iItem2)
            
            if item1 ~= item2 and reaper.IsMediaItemSelected(item2) then
              local dStart2 = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
              local dLen2 = reaper.GetMediaItemInfo_Value(item2, "D_LENGTH")
              local dEnd2 = dStart2 + dLen2
              
              -- If selection crosses right edge
              if selStart < dEnd1 and selEnd >= dEnd1 then
                if selEnd >= dStart2 and dEnd2 > dEnd1 then
                  rightFlag = true
                end
              end
              
              -- If selection crosses left edge
              if selStart <= dStart1 and selEnd > dStart1 then
                if selStart <= dEnd2 and dStart2 < dStart1 then
                  leftFlag = true
                end
              end
            end
          end
          
          if selEnd < dEnd1 then
            rightFlag = true
          end
          
          if selStart > dStart1 then
            leftFlag = true
          end
          
          -- Extend left edge to time selection start
          if not leftFlag then
            local edgeAdj = dStart1 - selStart
            local newLen = dLen1 + edgeAdj
            
            reaper.SetMediaItemInfo_Value(item1, "D_POSITION", selStart)
            reaper.SetMediaItemInfo_Value(item1, "D_LENGTH", newLen)
            AdjustTakesStartOffset(item1, edgeAdj)
          end
          
          -- Extend right edge to time selection end
          if not rightFlag then
            local edgeAdj = selEnd - dEnd1
            local newLen = dLen1 + edgeAdj
            
            reaper.SetMediaItemInfo_Value(item1, "D_LENGTH", newLen)
          end
          
        else
          -- No time selection - use cursor position
          
          -- Check for other selected items on the same track
          for iItem2 = 0, numItems - 1 do
            local item2 = reaper.GetTrackMediaItem(tr, iItem2)
            
            if item1 ~= item2 and reaper.IsMediaItemSelected(item2) then
              local dStart2 = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
              local dLen2 = reaper.GetMediaItemInfo_Value(item2, "D_LENGTH")
              local dEnd2 = dStart2 + dLen2
              
              -- If cursor is before item 1
              if cursorPos < dStart1 then
                if cursorPos < dEnd2 and dStart1 > dStart2 then
                  leftFlag = true
                end
              end
              
              -- If cursor is after item 1
              if cursorPos > dEnd1 then
                if cursorPos > dStart2 and dEnd1 < dEnd2 then
                  rightFlag = true
                end
              end
            end
          end
          
          if cursorPos >= dStart1 then
            leftFlag = true
          end
          
          if cursorPos <= dEnd1 then
            rightFlag = true
          end
          
          -- Extend left edge to cursor
          if not leftFlag then
            local edgeAdj = dStart1 - cursorPos
            local newLen = dLen1 + edgeAdj
            
            reaper.SetMediaItemInfo_Value(item1, "D_POSITION", cursorPos)
            reaper.SetMediaItemInfo_Value(item1, "D_LENGTH", newLen)
            AdjustTakesStartOffset(item1, edgeAdj)
          end
          
          -- Extend right edge to cursor
          if not rightFlag then
            local edgeAdj = cursorPos - dEnd1
            local newLen = dLen1 + edgeAdj
            
            reaper.SetMediaItemInfo_Value(item1, "D_LENGTH", newLen)
          end
        end
      end
    end
  end
  
  reaper.UpdateTimeline()
end





function MakeFolder()
  local bUndo = false
  local numTracks = reaper.CountTracks(0)
  
  local i = 0
  local tr = reaper.GetTrack(0, 0)
  
  while i < numTracks - 1 do
    i = i + 1
    local nextTr = reaper.GetTrack(0, i)
    
    local trSel = reaper.GetMediaTrackInfo_Value(tr, "I_SELECTED")
    local nextTrSel = reaper.GetMediaTrackInfo_Value(nextTr, "I_SELECTED")
    
    if trSel == 1 and nextTrSel == 1 then
      bUndo = true
      
      -- Increase folder depth of first track
      local iDepth = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
      reaper.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", iDepth + 1)
      
      -- Find the last selected track in sequence
      while i < numTracks do
        i = i + 1
        tr = nextTr
        nextTr = reaper.GetTrack(0, i)
        
        if not nextTr or reaper.GetMediaTrackInfo_Value(nextTr, "I_SELECTED") == 0 then
          break
        end
      end
      
      -- Decrease folder depth of last track
      iDepth = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
      reaper.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", iDepth - 1)
    end
    
    tr = nextTr
  end
end

function AllBlack()
  -- Check if all custom colors are black (0)
  -- This assumes g_custColors is stored globally or passed in
  -- You'll need to implement this based on your color storage
  if not g_custColors then return true end
  
  for i = 0, 15 do
    if g_custColors[i] ~= 0 then
      return false
    end
  end
  return true
end

function ItemRandomCols()
  -- Check if all colors are black
  if AllBlack() then
    return
  end
  
  local numTracks = reaper.CountTracks(0)
  
  for i = 0, numTracks - 1 do
    local tr = reaper.GetTrack(0, i)
    local numItems = reaper.CountTrackMediaItems(tr)
    
    for j = 0, numItems - 1 do
      local item = reaper.GetTrackMediaItem(tr, j)
      local isSelected = reaper.GetMediaItemInfo_Value(item, "B_UISEL")
      
      if isSelected == 1 then
        -- Get random non-zero color from custom colors
        local cr = 0
        repeat
          cr = g_custColors[math.random(0, 15)]
        until cr ~= 0
        
        -- Set custom color flag
        cr = cr | 0x1000000
        reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", cr)
      end
    end
  end
  
  reaper.UpdateTimeline()
end


-----MIDI SCRIPTS

--based on juliansader, MPL code https://forum.cockos.com/member.php?u=14710 https://forum.cockos.com/showthread.php?t=188335

function FilterMIDIData(take, exclude_msg_type)
  local tableEvents = {}
  local t = 0
  local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
  local MIDIlen = #MIDIstring  -- Use # instead of :len()
  local stringPos = 1
  
  -- Local references to functions called in loop (reduces table lookups)
  local s_unpack = string.unpack
  local s_pack = string.pack
  local s_byte = string.byte
  
  local offset, flags, msg, msgLen, msgType
  local exclude_shifted = exclude_msg_type  -- Pre-calculated if constant
              
  while stringPos < MIDIlen - 12 do
    offset, flags, msg, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
    msgLen = #msg  -- Use # operator (slightly faster)
    
    if msgLen > 1 then
      msgType = s_byte(msg, 1) >> 4  -- Direct call with index
      if msgType == exclude_shifted then
        msg = ""
      end
    end
    
    t = t + 1
    tableEvents[t] = s_pack("i4Bs4", offset, flags, msg)
  end
      reaper.MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
      reaper.MIDI_Sort(take)    
  
end




function ScaleNotes(x)
  local midieditor = reaper.MIDIEditor_GetActive()
  if not midieditor then return end
  
  local take = reaper.MIDIEditor_GetTake(midieditor)
  if not take or not reaper.TakeIsMIDI(take) then return end
  
  -- Get note count once
  local _, notecount = reaper.MIDI_CountEvts(take)
  
  -- Find first selected note's position (anchor point)
  local strtppq
  for i = 0, notecount - 1 do
    local _, selected = reaper.MIDI_GetNote(take, i)
    if selected then
      local _, _, _, startppq = reaper.MIDI_GetNote(take, i)
      strtppq = startppq
      break
    end
  end
  
  -- If no selected notes found, exit
  if not strtppq then return end
  
  -- Stretch selected notes
  for i = 0, notecount - 1 do
    local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    
    if selected then
      local note_len = endppq - startppq
      local new_start = math.floor((startppq - strtppq) * x + strtppq)
      local new_end = math.floor(new_start + note_len * x)
      
      reaper.MIDI_SetNote(take, i, 
        selected, 
        muted, 
        new_start, 
        new_end, 
        chan, 
        pitch, 
        vel, 
        true) -- noSort
    end
  end
  
  reaper.MIDI_Sort(take)
end



function ScaleMidiItems(x)
  -- Get the active MIDI editor
  local midi_editor = reaper.MIDIEditor_GetActive()
  if not midi_editor then
       return
  end
  
  -- Get the active take in the MIDI editor
  local take = reaper.MIDIEditor_GetTake(midi_editor)
  if not take then
       return
  end
  
  -- Get the item from the take
  local item = reaper.GetMediaItemTake_Item(take)
  if not item then return end
  
  -- Verify it's a MIDI take
  if not reaper.TakeIsMIDI(take) then
        return
  end
  
  -- INITIAL ITEM INFOS
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local init_take_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local item_fadein = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  local item_fadeout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
  local item_position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_snap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
  
  -- Calculate new length based on multiplier
  local new_length = item_len * x
  
  -- Calculate new playrate (inverse relationship with length)
  local take_rate = init_take_rate / x
  local take_rate_ratio = init_take_rate / take_rate
  
  -- Adjust snap offset and fades
  local new_snap_offset = item_snap * take_rate_ratio
  local new_fadein = item_fadein * take_rate_ratio
  local new_fadeout = item_fadeout * take_rate_ratio
  
  -- Apply changes
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", take_rate)
  reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", new_snap_offset)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", new_fadein)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", new_fadeout)
  
  -- Adjust position to maintain snap offset position
  local new_pos = item_position - (new_snap_offset - item_snap)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
  
  -- Set new item length
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_length)
end




-- Function to move cursor to next grid division
function MidiNextGrid(cursorPos)

  -- Get the active MIDI editor and take (if any)
  local midiEditor = reaper.MIDIEditor_GetActive()
  local gridSize
  
  if midiEditor then
    local take = reaper.MIDIEditor_GetTake(midiEditor)
    if take then
      gridSize = reaper.MIDI_GetGrid(take)
    end
  end
  
  -- If no MIDI editor is active, use the project grid
  if not gridSize then
    gridSize = reaper.GetProjectTimeSignature2(0)
    -- Use a default grid size based on the project settings
    -- This gets the grid division setting
    local _, division = reaper.GetSetProjectGrid(0, false, 0, 0, 0)
    gridSize = division
  end
  
  -- Convert cursor position to QN (quarter notes)
  local cursorQN = reaper.TimeMap2_timeToQN(0, cursorPos)
  
  -- Calculate next grid position
  local nextGridQN = math.ceil(cursorQN / gridSize) * gridSize
  
  -- Handle case where cursor is already on grid
  if math.abs(nextGridQN - cursorQN) < 0.0001 then
    nextGridQN = nextGridQN + gridSize
  end
  
  -- Convert back to time
  local nextGridTime = reaper.TimeMap2_QNToTime(0, nextGridQN)
  

  return nextGridTime
end

-- Function to move cursor to previous grid division
function MidiPrevGrid(cursorPos)

  -- Get the active MIDI editor and take (if any)
  local midiEditor = reaper.MIDIEditor_GetActive()
  local gridSize
  
  if midiEditor then
    local take = reaper.MIDIEditor_GetTake(midiEditor)
    if take then
      gridSize = reaper.MIDI_GetGrid(take)
    end
  end
  
  -- If no MIDI editor is active, use the project grid
  if not gridSize then
    gridSize = reaper.GetProjectTimeSignature2(0)
    -- Use a default grid size based on the project settings
    local _, division = reaper.GetSetProjectGrid(0, false, 0, 0, 0)
    gridSize = division
  end
  
  -- Convert cursor position to QN (quarter notes)
  local cursorQN = reaper.TimeMap2_timeToQN(0, cursorPos)
  
  -- Calculate previous grid position
  local prevGridQN = math.floor(cursorQN / gridSize) * gridSize
  
  -- Handle case where cursor is already on grid
  if math.abs(prevGridQN - cursorQN) < 0.0001 then
    prevGridQN = prevGridQN - gridSize
  end
  
  -- Convert back to time
  local prevGridTime = reaper.TimeMap2_QNToTime(0, prevGridQN)
  
 return prevGridTime
end




-- Save selected MIDI notes
function SaveSelectedNotes(take)
  local selected_notes = {}
  
  if not take or not reaper.TakeIsMIDI(take) then
    return selected_notes
  end
  
  local _, note_count = reaper.MIDI_CountEvts(take)
  
  for i = 0, note_count - 1 do
    local _, selected, _, start_pos, end_pos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    
    if selected then
      table.insert(selected_notes, {
        index = i,
        start_pos = start_pos,
        end_pos = end_pos,
        chan = chan,
        pitch = pitch,
        vel = vel
      })
    end
  end
  
  return selected_notes
end


-- Restore selected MIDI notes
function RestoreSelectedNotes(take, saved_notes)
  if not take or not reaper.TakeIsMIDI(take) then
    return false
  end
  
  -- First, deselect all notes
  local _, note_count = reaper.MIDI_CountEvts(take)
  for i = 0, note_count - 1 do
    reaper.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true)
  end
  
  -- Then restore the saved selection
  for _, note_data in ipairs(saved_notes) do
    -- Find matching note by properties (more reliable than index)
    for i = 0, note_count - 1 do
      local _, _, _, start_pos, end_pos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
      
      if start_pos == note_data.start_pos and
         end_pos == note_data.end_pos and
         chan == note_data.chan and
         pitch == note_data.pitch and
         vel == note_data.vel then
        reaper.MIDI_SetNote(take, i, true, nil, nil, nil, nil, nil, nil, true)
        break
      end
    end
  end
  
  return true
end







