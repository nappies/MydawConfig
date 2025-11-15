function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end




ItemsForTune = {}


function InsertWavesTune()

all_items = reaper.CountSelectedMediaItems(0)

for i = 0, all_items-1 do
local pop = #ItemsForTune+1
local titem =  reaper.GetSelectedMediaItem(0,i)
addplug=0
takecount = reaper.CountTakes(titem)
       for j = 1, takecount do
 take = reaper.GetTake(titem, j - 1)        
        if reaper.TakeFX_GetCount(take) ~= 0 then
          fx_count = reaper.TakeFX_GetCount(take)
          for fx = 1, fx_count do           
            _, fx_name = reaper.TakeFX_GetFXName(take, fx-1, '')
            if  string.find(fx_name,"WavesTune")  then  addplug=1

end
end
end
end

if addplug==0 then ItemsForTune[pop] = titem end
end


for i=1, #ItemsForTune do


item = ItemsForTune[i]

tunetrack =  reaper.GetMediaItem_Track(item)

 reaper.SetMediaTrackInfo_Value( tunetrack, 'I_PERFFLAGS', 2 )


 MediaItem_Take = reaper.GetTake(item, 0)

 ismidi = reaper.TakeIsMIDI(MediaItem_Take)
 
 if not ismidi then


reaper.TakeFX_AddByName(MediaItem_Take, "WavesTune", 1)


 
 
end

end

end














function RenderWavesTune()


for i=1, #ItemsForTune do


ritem = ItemsForTune[i]

RMediaItem_Take = reaper.GetTake(ritem, 0)

ismidi = reaper.TakeIsMIDI(RMediaItem_Take)
 


reaper.TakeFX_SetOpen( RMediaItem_Take, 0, 1 )

reaper.SelectAllMediaItems( 0, 0 )

reaper.SetMediaItemSelected( ritem, 1 )


reaper.Main_OnCommand(40361,0) ---render 
    
 



function waitrender()

counttakes = reaper.CountTakes(ritem)

  
  if counttakes < 1 then reaper.defer(waitrender) else goto next    end
::next::

end

waitrender()





take = reaper.GetActiveTake(ritem)
src = reaper.GetMediaItemTake_Source(take)
in_path = reaper.GetMediaSourceFileName(src, "")
    
    
reaper.Main_OnCommand(40440, 0)-----set offline
   
    
os.remove(in_path)
    
reaper.Main_OnCommand(40129, 0) ----delete active take


reaper.Main_OnCommand(40439, 0)-----Online
    
 

if all_items > 1 then reaper.TakeFX_SetOpen(RMediaItem_Take, 0, 0 ) end


 
 
end

end






  






reaper.Undo_BeginBlock()

InsertWavesTune()


t0 = os.clock()
function run()
  t = os.clock()
  if t - t0 < 0.9 then reaper.defer(run) else RenderWavesTune()    end
end
run()






reaper.Undo_EndBlock('Add WavesTune', -1)  

