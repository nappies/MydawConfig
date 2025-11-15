package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")


reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)

   local CntSelIt = reaper.CountSelectedMediaItems(0);
    if CntSelIt == 0 then  return end;

    reaper.Undo_BeginBlock();
  reaper.PreventUIRefresh(1);

    for i = CntSelIt-1,0,-1 do;
        local selIt = reaper.GetSelectedMediaItem(0,i);
        local pos = reaper.GetMediaItemInfo_Value(selIt,'D_POSITION');
        local NextGrid = SnapPrevGridLine(pos);
        reaper.SetMediaItemInfo_Value(selIt,'D_POSITION',NextGrid);
 
    end;
 ---Razor
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
 local _, razor_edit = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
         if razor_edit ~= '' then
             local new_razor_edit = ''
             for edit in razor_edit:gmatch('.- .- ".-"%s*') do
                 local start_pos = tonumber(edit:match('.- '))
                 local end_pos = tonumber(edit:match(' .- '))
                 local new_start_pos
                 local new_end_pos
                 
                new_start_pos = SnapPrevGridLine(start_pos)
                new_end_pos = SnapPrevGridLine(end_pos)
             
                 local new_edit = new_start_pos .. ' ' .. new_end_pos .. edit:match(' ".-"')
                 new_razor_edit = new_razor_edit .. new_edit .. ' '
                 reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', new_razor_edit, true)
 
end
end
end


  reaper.PreventUIRefresh(-1);
  reaper.UpdateArrange();

reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Move Item Left', -1) 






