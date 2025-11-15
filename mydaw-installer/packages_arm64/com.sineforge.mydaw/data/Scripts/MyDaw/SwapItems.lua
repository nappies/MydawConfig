function SwapItems(rotateLengths, reverse)
    -- Get selected items
    local itemCount = reaper.CountSelectedMediaItems(0)
    
    if itemCount <= 1 then
        return
    end
    
    -- Collect items and their properties
    local items = {}
    local lengths = {}
    local positions = {}
    local tracks = {}
    
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        items[i + 1] = item
        lengths[i + 1] = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        positions[i + 1] = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        tracks[i + 1] = reaper.GetMediaItemTrack(item)
    end
    
    -- Rotate the arrays
    if not reverse then
        -- Rotate forward: take last element and move to front
        local lastLen = table.remove(lengths)
        table.insert(lengths, 1, lastLen)
        
        local lastPos = table.remove(positions)
        table.insert(positions, 1, lastPos)
        
        local lastTrack = table.remove(tracks)
        table.insert(tracks, 1, lastTrack)
    else
        -- Rotate backward: take first element and move to end
        local firstLen = table.remove(lengths, 1)
        table.insert(lengths, firstLen)
        
        local firstPos = table.remove(positions, 1)
        table.insert(positions, firstPos)
        
        local firstTrack = table.remove(tracks, 1)
        table.insert(tracks, firstTrack)
    end
    
    -- Apply rotated properties to items
    reaper.Undo_BeginBlock()
    
    for i = 1, itemCount do
        reaper.SetMediaItemInfo_Value(items[i], "D_POSITION", positions[i])
        reaper.MoveMediaItemToTrack(items[i], tracks[i])
        
        if rotateLengths then
            reaper.SetMediaItemInfo_Value(items[i], "D_LENGTH", lengths[i])
        end
    end
    
    reaper.Undo_EndBlock("Swap items", -1)
    reaper.UpdateArrange()
end



SwapItems(false, false)