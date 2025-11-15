
    -- RESET
    --reaper.ShowConsoleMsg("");

    -- COUNT SEL ITEMS
    count_sel_items = reaper.CountSelectedMediaItems(0);
    --reaper.ShowConsoleMsg("Number of selected items: " .. count_sel_items);

    for i = 0, count_sel_items - 1 do
        item = reaper.GetSelectedMediaItem(0, i);
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION");

        
        
          reaper.SetMediaItemInfo_Value(item, "D_LENGTH",reaper.TimeMap2_beatsToTime( 0, 0, 1 ));
        
        new_item_pos = item_pos + 1;

        item_id = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER");

        if item_id ~= 0 then
            track = reaper.GetMediaItemTrack(item);

            previous_item_id = item_id - 1;

            previous_item = reaper.GetTrackMediaItem(track, previous_item_id);
            previous_item_pos = reaper.GetMediaItemInfo_Value(previous_item, "D_POSITION");
            previous_item_len = reaper.GetMediaItemInfo_Value(previous_item, "D_LENGTH");
            previous_item_end = previous_item_pos + previous_item_len;

            --reaper.ShowConsoleMsg("Previous item end: " .. previous_item_end);

            reaper.SetMediaItemInfo_Value(item, "D_POSITION", previous_item_end);
        end
    end -- END of loop through selected items



reaper.UpdateArrange()
