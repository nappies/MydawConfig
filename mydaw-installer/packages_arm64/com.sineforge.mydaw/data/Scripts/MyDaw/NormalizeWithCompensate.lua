function NormalizeSelectedItemsToLUFS()
    -- Get the number of selected items
    local itemCount = reaper.CountSelectedMediaItems(0)
    
    if itemCount == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end
    
    -- Target LUFS value
    local targetLUFS = -23
    
    -- Start undo block
    
    -- Loop through all selected items
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        
        if item then
            -- Get the active take
            local take = reaper.GetActiveTake(item)
            
            if take then
                -- Get the PCM source from the take
                local source = reaper.GetMediaItemTake_Source(take)
                
                if source then
                    -- Get item position and length for time bounds
                    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    
                    -- Get take offset
                    local takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                    
                    -- Calculate source start and end times
                    local sourceStart = takeOffset
                    local sourceEnd = takeOffset + itemLength
                    
                    -- Calculate normalization adjustment
                    -- normalizeTo: 0 = LUFS-I (integrated LUFS)
                    local adjustment = reaper.CalculateNormalization(
                        source,
                        0,              -- 0 = LUFS-I
                        targetLUFS,     -- -23 LUFS target
                        sourceStart,    -- start time in source
                        sourceEnd       -- end time in source
                    )
                    
                    -- Apply the adjustment to the take volume
                    if adjustment then
                        local currentVolume = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
                        local newVolume = currentVolume * adjustment
                        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", newVolume)
                    end
                end
            end
        end
    end
    

    

    
   
end







local items = reaper.CountSelectedMediaItems()
if items == 0 then return end

function DB(vol) return 20*math.log(vol, 10) end

function VOL(db) return 10^(0.05*db) end


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

-- Run the function
NormalizeSelectedItemsToLUFS()


t = {}

for i = 0,items-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  local take = reaper.GetActiveTake(item)
  if not take then goto cnt end
  local tr = reaper.GetMediaItem_Track(item)
  vol = reaper.GetMediaItemTakeInfo_Value(take, 'D_VOL')
  vol_db = DB(vol)
  tr_str = tostring(tr)
  if not t[tr_str] then t[tr_str] = {} end
  if t[tr_str][3] then
    if vol_db > t[tr_str][3] then t[tr_str] = {tr,item,vol_db} end
  else t[tr_str] = {tr,item,vol_db} end
  ::cnt::
end

for _,v in pairs(t) do
  local tr = v[1]
  local item = v[2]
  vol_db = v[3]
  tr_vol = reaper.GetMediaTrackInfo_Value(tr, 'D_VOL')
  tr_vol_db = DB(tr_vol)
  reaper.SetMediaTrackInfo_Value(tr, 'D_VOL',VOL(tr_vol_db-vol_db))
end




 


reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('normalize items + compensation', -1)
