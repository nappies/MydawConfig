focus = reaper.GetCursorContext() --  Даем переменную значения где сейчас фокус?

if focus == 1 then

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

selItemCount = reaper.CountSelectedMediaItems(pProj)
i = 0
while i < selItemCount do
    pItem = reaper.GetSelectedMediaItem(pProj, i)
    pTake = reaper.GetMediaItemTake(pItem, 0)
    
    itemchunk = "";
    envchunk = ""
    result, itemchunk = reaper.GetItemStateChunk(pItem, itemchunk, 1)
        
    envCount = reaper.CountTakeEnvelopes(pTake)
    e = 0
    while e < envCount do
        pEnv = reaper.GetTakeEnvelope(pTake, e)          

        result, envchunk = reaper.GetEnvelopeStateChunk(pEnv, envchunk, 1)
        
        x, y = string.find(itemchunk, envchunk, 0, 0)
        
        if x and y then
            itemchunk = string.sub(itemchunk, 0, x - 1) .. string.sub(itemchunk, y , 0)
        end
        
        --reaper.ShowConsoleMsg(itemchunk)
            
        e = e + 1
    end
    
    reaper.SetItemStateChunk(pItem, itemchunk, 1);
        
    reaper.UpdateItemInProject(pItem)
    
    i = i + 1
end

reaper.Undo_EndBlock("Delete Take Envelopes", -1)

reaper.UpdateArrange()
reaper.UpdateTimeline()

reaper.PreventUIRefresh(-1)



end

