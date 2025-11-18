----thanks to Ilias-Timon Poulakis (FeedTheCat)

package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")


local  str = reaper.GetExtState('MyDaw', 'IsReverseSel')
local isreverse
if not str  or str  == '' then isreverse = 0 else isreverse = 1  end 




reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local has_razor_edit = false
local GetSetTrackInfo = reaper.GetSetMediaTrackInfo_String
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local _, razor_edit = GetSetTrackInfo(track, 'P_RAZOREDITS', '', false)
    if razor_edit ~= '' then
        local new_razor_edit = ''
        for edit in razor_edit:gmatch('.- .- ".-"%s*') do
            local start_pos = tonumber(edit:match('.- '))
            local end_pos = tonumber(edit:match(' .- '))
            local new_start_pos
            local new_end_pos
            
            if isreverse == 0 then
           new_start_pos = start_pos
           new_end_pos = SnapNextGridLine(end_pos)
            else
           new_start_pos = SnapNextGridLine(start_pos)
           new_end_pos = end_pos
            end
            
            if new_start_pos == new_end_pos then reaper.Main_OnCommand(42406, 0) reaper.SetEditCurPos2(0,new_start_pos, true, false) break end 
       
            local new_edit = new_start_pos .. ' ' .. new_end_pos .. edit:match(' ".-"')
            new_razor_edit = new_razor_edit .. new_edit .. ' '
        end
        if not has_razor_edit then
            has_razor_edit = true
            reaper.SetOnlyTrackSelected(track)
            local start_pos = tonumber(new_razor_edit:match('[^%s]+'))
           -- reaper.SetEditCurPos2(0, start_pos, true, false)
        end
        GetSetTrackInfo(track, 'P_RAZOREDITS', new_razor_edit, true)
    end
end


if not has_razor_edit then


reaper.DeleteExtState('MyDaw', 'IsReverseSel',false)

local raz_start_pos = reaper.GetCursorPosition()
local raz_end_pos = SnapNextGridLine(reaper.GetCursorPosition())

local raz_edit = raz_start_pos .. ' ' .. raz_end_pos .. ' ""'
reaper.GetSetMediaTrackInfo_String(reaper.GetLastTouchedTrack(), 'P_RAZOREDITS', raz_edit, true)
   
   
    reaper.UpdateArrange()
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Move razor edit right by grid size', -1)
