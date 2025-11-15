package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")

function m(s)
reaper.ShowConsoleMsg(tostring(s) .. "\n")

end


reaper.Main_OnCommand(42406,0)

function GetMinNonSelItem(tr,sitem)

R_itemStart = reaper.GetMediaItemInfo_Value(sitem, "D_POSITION")
R_itemEnd = R_itemStart + reaper.GetMediaItemInfo_Value(sitem, "D_LENGTH")
nonselected_min = 2000
for i = 0, reaper.GetTrackNumMediaItems(tr)-1 do
local item = reaper.GetTrackMediaItem(tr, i) 
isselected = reaper.GetMediaItemInfo_Value(item, "B_UISEL")
if isselected == 0 then
start_time, end_time = R_itemStart, R_itemEnd
if start_time ~= end_time then -- if there is a time selection
item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

item_end = item_pos + item_len -- Calculate the item end position

if (item_pos >= start_time and item_pos <= end_time) or (item_end >= start_time and item_end <= end_time) 
or (item_pos <= start_time and item_end >= end_time) then -- check if item is in time selection
item_top = reaper.GetMediaItemInfo_Value( item, "I_LASTY")  
nonselected_min= math.min(item_top, nonselected_min)                          
end 
end
end
end
return nonselected_min
end

function IsItemVisible(vitem)
item_in_lane=0
local itwidth=reaper.GetMediaItemInfo_Value( vitem, "I_LASTH")
local tr = reaper.GetMediaItem_Track(vitem)
local trwidth = reaper.GetMediaTrackInfo_Value( tr, "I_WNDH")

local count  = (trwidth/itwidth)


local R_itemStart = reaper.GetMediaItemInfo_Value(vitem, "D_POSITION")
local R_itemEnd = R_itemStart + reaper.GetMediaItemInfo_Value(vitem, "D_LENGTH")
for i = 0, reaper.GetTrackNumMediaItems(tr)-1 do
local item = reaper.GetTrackMediaItem(tr, i) 
local start_time, end_time = R_itemStart, R_itemEnd
if start_time ~= end_time then -- if there is a time selection
item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

item_end = item_pos + item_len -- Calculate the item end position

if (item_pos >= start_time and item_pos <= end_time) or (item_end >= start_time and item_end <= end_time) 
or (item_pos <= start_time and item_end >= end_time) then -- check if item is in time selection

item_in_lane=(item_in_lane+1)
                      
end 
end
end
if count > item_in_lane then return true else return false  end
end



function movetrackup()

------------------------------------------------------------------------------
local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end;
------------------------------------------------------------------------------



local SaveSelTracksGuid = function(up); 
for i = 1, reaper.CountSelectedTracks(0) do; 
local track = reaper.GetSelectedTrack(0, i - 1)
up[i] = reaper.GetTrackGUID( track )
end 
end
--- 


local RestoreSelTracksGuid = function(up) 
local tr = reaper.GetTrack(0,0) 
reaper.SetOnlyTrackSelected(tr) 
reaper.SetTrackSelected(tr, 0) 
for i = 1, #up do
local track = GuidToTrack(up[i])
if track then
reaper.SetTrackSelected(track,1) 
end
end  
end

local count_sel = reaper.CountSelectedTracks(0)
if count_sel == 0 then no_undo() return end


local sel_tracks = {}  
SaveSelTracksGuid(sel_tracks) 

reaper.PreventUIRefresh(1) 

local track_number,un_track,fold,un_track2,penultimate_in_folder,tr,tr2,fol,fol2
---
reaper.InsertTrackAtIndex(0,false)
local intrack = reaper.GetTrack(0,0)
local guid = reaper.GetTrackGUID(intrack)
---
local count_tracks = reaper.CountTracks(0)
for i = 1, count_tracks do
local intrack = reaper.GetTrack(0, i-1)
local selected = reaper.GetMediaTrackInfo_Value(intrack,"I_SELECTED")
if selected == 1 then
fold = reaper.GetMediaTrackInfo_Value( intrack, "I_FOLDERDEPTH")
track_number = reaper.GetMediaTrackInfo_Value( intrack, "IP_TRACKNUMBER")
for i2 = track_number, reaper.CountTracks(0)-1 do
un_track = reaper.GetTrack(0, i2)
reaper.SetTrackSelected(un_track,0)
end     
tr = reaper.GetTrack(0, track_number-3)
if tr then
fol = reaper.GetMediaTrackInfo_Value( tr, "I_FOLDERDEPTH")
after_next_tr_depth = reaper.GetTrackDepth(tr)
local _, after_next_tr = reaper.GetTrackName( tr, '' )

--------------------------------------------------------- 
tr2 = reaper.GetTrack(0, track_number-2)
fol2 = reaper.GetMediaTrackInfo_Value( tr2, "I_FOLDERDEPTH")
next_tr_depth = reaper.GetTrackDepth(tr)
local _, next_tr = reaper.GetTrackName( tr2, '' )   






if fol2 == -1 then

folder_of_track =  reaper.GetParentTrack(tr2)
reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )

elseif fol2 == -2 then

folder_of_track =  reaper.GetParentTrack(tr2)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
elseif fol2 == -3 then

folder_of_track =  reaper.GetParentTrack(tr2)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )


elseif fol2 == -4 then

folder_of_track =  reaper.GetParentTrack(tr2)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)
folder_folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )






elseif fol2 > 0 then 

--reaper.SetMediaTrackInfo_Value( tr2 , 'I_FOLDERCOMPACT', 2 )
end
-------------------------------------------------------------------------------------  







if fol < 0 then
-------------


penultimate_in_folder = 0  
numb_x = track_number - 2    
---------------   
else
tr2 = reaper.GetTrack(0, track_number-2)
fol2 = reaper.GetMediaTrackInfo_Value( tr2, "I_FOLDERDEPTH")
next_tr_depth = reaper.GetTrackDepth(tr)
local _, next_tr = reaper.GetTrackName( tr2, '' )




if fol2 < 0 then


numb_x = track_number - 1 penultimate_in_folder = 2  

end
end
end  
if fold == 1 then 
depth = reaper.GetTrackDepth(intrack)
for i = track_number, reaper.CountTracks(0)-1 do
track_depth = reaper.GetTrack(0, i)
if track_depth then
depth2 = reaper.GetTrackDepth(track_depth)
if depth2 <= depth then
numb_j = (reaper.GetMediaTrackInfo_Value( track_depth, "IP_TRACKNUMBER")-1)
break
end



end

if not Numb_j then Numb_j = reaper.CountTracks(0)-1 end;           

end
else
numb_j = track_number       
end
if not penultimate_in_folder then penultimate_in_folder = 0 end
if not numb_x then numb_x = track_number-2 end

if track_number > 1 then
reaper.ReorderSelectedTracks(numb_x,penultimate_in_folder)
end

RestoreSelTracksGuid(sel_tracks)   
for ij = numb_j-1, 0,-1 do
un_track2 = reaper.GetTrack(0, ij)
reaper.SetTrackSelected(un_track2,0)
end 
end
numb_j,numb_x = nil,nil 
end

local track = GuidToTrack(guid)
reaper.SetOnlyTrackSelected(track)
reaper.ReorderSelectedTracks(reaper.CountTracks(0),0)
reaper.DeleteTrack( track )

RestoreSelTracksGuid(sel_tracks) 

reaper.PreventUIRefresh(-1) 


DoSelectLastOfSelectedTracks() --reaper.Main_OnCommand(reaper.NamedCommandLookup('_XENAKIOS_SELFIRSTOFSELTRAX'), 0) ----select last
--reaper.Main_OnCommand(40696,0)-- rename
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_TRACKS'),0)


RestoreSelTracksGuid(sel_tracks)  





end



function moveitem()

MoveWithMI = 40070

MoveWithMIOff = 0


MoveWithMI_State = reaper.GetToggleCommandState(MoveWithMI)

if (MoveWithMI_State == 1) then

reaper.Main_OnCommand(MoveWithMI, 0)

MoveWithMIOff = 1


end


reaper.Main_OnCommand(40117, 0)   -----move

if (MoveWithMIOff == 1) then

reaper.Main_OnCommand(MoveWithMI, 0)

end






SelTracksWItems()

for i = 1, reaper.CountSelectedMediaItems(0) do 
moveitem =  reaper.GetSelectedMediaItem( 0, i-1 )
current_track = reaper.GetMediaItem_Track(moveitem)
current_track_fold = reaper.GetMediaTrackInfo_Value(current_track,"I_FOLDERDEPTH")
number = reaper.GetMediaTrackInfo_Value( current_track, "IP_TRACKNUMBER")


local next_track = reaper.GetTrack(0,number+2)
if next_track then
number_next  = reaper.GetMediaTrackInfo_Value( next_track, "IP_TRACKNUMBER")
next_fold = reaper.GetMediaTrackInfo_Value(next_track,"I_FOLDERDEPTH") end

if current_track_fold == -1 then

folder_of_track =  reaper.GetParentTrack(current_track)
reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )

elseif current_track_fold == -2 then

folder_of_track =  reaper.GetParentTrack(current_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
elseif current_track_fold == -3 then

folder_of_track =  reaper.GetParentTrack(current_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )


elseif current_track_fold == -4 then

folder_of_track =  reaper.GetParentTrack(current_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)
folder_folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_folder_of_track)


reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 0 )






elseif current_track_fold > 0 then 


end
-------------------------------------------------------------------------------------  







end




DoSelectLastOfSelectedTracks() --reaper.Main_OnCommand(reaper.NamedCommandLookup('_XENAKIOS_SELFIRSTOFSELTRAX'), 0) ----select last
--reaper.Main_OnCommand(40696,0)-- rename
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)

end


focus = reaper.GetCursorContext2(true) --  Берём переменную значения где сейчас фокус?

if focus == 0 then 
reaper.Undo_BeginBlock();

movetrackup()
reaper.Undo_EndBlock('Move Track Up', -1)

elseif focus == 1 or 2 or -1 then 

reaper.Undo_BeginBlock(); 

local function SaveSelectedItemsToTable (table)
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
table[i+1] = reaper.GetSelectedMediaItem(0, i)
end
end

local function RestoreSelectedItemsFromTable (table)
for _, item in ipairs(table) do
reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
end
end





SaveSelectedItemsToTable (table)




local show_over = reaper.GetToggleCommandState(40507)
if show_over == 1 then 

notyet = 0 

for _, citem in ipairs(table) do
local tr = reaper.GetMediaItem_Track(citem)


if GetMinNonSelItem(tr,citem) < (reaper.GetMediaItemInfo_Value( citem, "I_LASTY")+(reaper.GetMediaItemInfo_Value( citem, "I_LASTH")/2))and IsItemVisible(citem)==true  then 
notyet = 1
end
end  



if notyet == 1   then


for _, it in ipairs(table) do
local tr = reaper.GetMediaItem_Track(it)
if GetMinNonSelItem(tr,it) < (reaper.GetMediaItemInfo_Value( it, "I_LASTY")+(reaper.GetMediaItemInfo_Value( it, "I_LASTH")/2))  then
reaper.SelectAllMediaItems( 0, 0 )
reaper.SetMediaItemSelected( it, true )
reaper.Main_OnCommand(40068,0)  ---move UP
RestoreSelectedItemsFromTable (table)
end
end
else

moveitem()

end

else 

moveitem()

end

reaper.UpdateTimeline()

reaper.Undo_EndBlock('Move Item Up', -1)
end
