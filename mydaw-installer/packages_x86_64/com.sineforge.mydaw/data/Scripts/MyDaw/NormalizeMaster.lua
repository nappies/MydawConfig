function GetLoudnessData()
 local stats_table = {}
    local ret, stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42440", false)
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




_,peak,_,_,_,_,_ = GetLoudnessData()

local db = peak
db = tonumber(db)

if db>0 then db=-db 
else
if db<0 then db=math.abs(db) end
end 


 
local CountTrack = reaper.CountTracks(0);
  
for i = 1, CountTrack do
  local tr = reaper.GetTrack(0, i-1)
  local vol = reaper.GetMediaTrackInfo_Value(tr, 'D_VOL')
  local fdepth = reaper.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH')
   if reaper.GetTrackDepth(tr)==0 then reaper.SetMediaTrackInfo_Value(tr, 'D_VOL', vol*10^(0.05*db)) end
end
