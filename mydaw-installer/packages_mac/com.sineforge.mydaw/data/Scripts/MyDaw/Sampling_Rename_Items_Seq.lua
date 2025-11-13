

function Msg(str)
    reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

function main()
    -- Get the total number of selected items
    local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items == 0 then
        reaper.ShowMessageBox("No items selected.", "Error", 0)
        return
    end

    -- Create a table to store items grouped by track
    local track_items = {}

    -- Iterate through selected items
    for i = 0, num_selected_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItemTrack(item)

        if not track_items[track] then
            track_items[track] = {}
        end

        table.insert(track_items[track], item)
    end

    -- Rename items sequentially for each track
    for track, items in pairs(track_items) do
        for i, item in ipairs(items) do
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:ITEMRENAMER", "", true) -- Clear existing name
            local take = reaper.GetActiveTake(item)
            if take then
                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", tostring(i-1), true)
            end
        end
    end

    -- Update the arrangement view
    reaper.UpdateArrange()
end

-- Begin Undo Block
reaper.Undo_BeginBlock()

main()

-- End Undo Block
reaper.Undo_EndBlock("Rename Selected Items on Each Track Sequentially", -1)
