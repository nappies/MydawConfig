function main() -- local (i, j, item, take, track)

  reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.


 -- LOOP THROUGH SELECTED ITEMS
  selected_items_count = reaper.CountSelectedMediaItems(0)
  
  -- INITIALIZE loop through selected items
  -- Select tracks with selected items
  for i = 0, selected_items_count - 1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i

    -- GET ITEM PARENT TRACK AND SELECT IT
    track = reaper.GetMediaItem_Track(item)
    reaper.SetTrackSelected(track, true)
        
  end -- ENDLOOP through selected tracks

  reaper.Undo_EndBlock("Select only tracks of selected items", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

-- UNSELECT ALL TRACKS
function UnselectAllTracks()
  first_track = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(first_track)
  reaper.SetTrackSelected(first_track, false)
end

--msg_start() -- Display characters in the console to show you the begining of the script execution.

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

main() -- Execute your main function

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)

--msg_end() -- Display characters in the console to show you the end of the script execution.





function noUndo()
end
reaper.defer(noUndo)

-- Is a usable time selection available?
timeSelectionStart, timeSelectionEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, true)
if timeSelectionStart >= timeSelectionEnd then  reaper.Main_OnCommand(40290, 0)
    
end

numSelTracks = reaper.CountSelectedTracks(0)
if numSelTracks == 0 then 
    return
end




reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)    



local tHiddenEnvelopeChunks = {}

reaper.SelectAllMediaItems(0, false)
for t = 0, numSelTracks-1 do 
    local track = reaper.GetSelectedTrack(0, t)
    for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if itemStart < timeSelectionEnd and itemEnd > timeSelectionStart then
            reaper.SetMediaItemSelected(item, true)
        end
    end
    local newItem = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", timeSelectionStart)
    reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", timeSelectionEnd - timeSelectionStart)
   
    reaper.ULT_SetMediaItemNote(newItem, "Area select (temporary)")
    reaper.SetMediaItemSelected(newItem, true)
    
    
    for e = 0, reaper.CountTrackEnvelopes(track)-1 do
        local env = reaper.GetTrackEnvelope(track, e)
        local chunkOK, envChunk = reaper.GetEnvelopeStateChunk(env, "", false)
        if chunkOK then
            if envChunk:match("\nVIS 0 ") then
                tHiddenEnvelopeChunks[env] = envChunk
            end
        end
    end
end




reaper.Main_OnCommand(40755, 0) 
reaper.Main_OnCommand(40754, 0) 
local cursorpos = reaper.GetCursorPosition()
local grid = cursorpos
while (grid <= cursorpos) do
    cursorpos = cursorpos + 0.05
    grid = reaper.SnapToGrid(0, cursorpos)
end
reaper.SetEditCurPos(grid,1,0)
reaper.Main_OnCommand(40756, 0) 
reaper.Main_OnCommand(41205, 0)
reaper.Main_OnCommand(40290, 0)






-------------------------
-- Delete temporary items
for t = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, t)
    local tItems = {}
    for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.ULT_GetMediaItemNote(item) == "Area select (temporary)" then
            tItems[#tItems+1] = item
        end
    end
    for _, item in ipairs(tItems) do
        reaper.DeleteTrackMediaItem(track, item)
    end
end


---------------------------------------------
-- Restore original state of hidden envelopes
for env, chunk in pairs(tHiddenEnvelopeChunks) do
    local setThisChunkOK = reaper.SetEnvelopeStateChunk(env, chunk, false)
    if not setThisChunkOK then errorSetChunks = true end
end
if errorSetChunks then
    reaper.MB("Errors resetting envelope state chunks.\n\nSome hidden envelopes may have been duplicated.", "ERROR", 0)
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Duplicate items and automation", -1)
