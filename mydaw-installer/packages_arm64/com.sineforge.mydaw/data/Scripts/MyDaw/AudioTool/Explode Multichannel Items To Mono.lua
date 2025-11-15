--_MwAs
function explode()
   for i = 1, reaper.CountSelectedMediaItems(0) do
    local Item_ID = reaper.GetSelectedMediaItem(0,i-1)
 if Item_ID then Take_ID = reaper.GetActiveTake(Item_ID)
    if Take_ID and reaper.TakeIsMIDI(Take_ID)==false then 
       _, Item_Chunk = reaper.GetItemStateChunk(Item_ID , "", false)  -- Get Item Chunk
       PCM_source = reaper.GetMediaItemTake_Source(Take_ID)           -- Get Item Source
       SourceNChan = reaper.GetMediaSourceNumChannels(PCM_source)     -- Num Chan in source
      if SourceNChan > 1  then
       Item_Track = reaper.GetMediaItem_Track(Item_ID)                -- Get Item Track
       Track_Num = reaper.GetMediaTrackInfo_Value(Item_Track, "IP_TRACKNUMBER") -- Track number(1-based)
       index = Track_Num-1                                            -- Original Item_Track index 

         -- For each Source Channeel -- 
         for i=1, SourceNChan, 1 do
             reaper.InsertTrackAtIndex(index+i, 0)                    -- New_Track
             New_Track_ID = reaper.GetTrack(0, index+i)               -- Get New_Track ID
            
             New_Item = reaper.AddMediaItemToTrack(New_Track_ID)      -- New_Item
             reaper.SetItemStateChunk(New_Item, Item_Chunk, true)     -- Set Item Chunk
             New_Take = reaper.GetActiveTake(New_Item)                -- Get Acive take
             reaper.SetMediaItemTakeInfo_Value(New_Take, "I_CHANMODE", i+2) -- Set channel mode
         end
       
       -- Mute orig Item,Set folder states -- 
       reaper.SetMediaItemInfo_Value(Item_ID, "B_MUTE", 1)            -- Mute Original Item
     
       reaper.TrackList_AdjustWindows(0) 
       end
      end                            -- update tracklist
    end
  end
end

-----------------------
-----------------------
reaper.Undo_BeginBlock()
explode()
reaper.Undo_EndBlock("Explode multichannel Audio", -1)
reaper.UpdateArrange()
