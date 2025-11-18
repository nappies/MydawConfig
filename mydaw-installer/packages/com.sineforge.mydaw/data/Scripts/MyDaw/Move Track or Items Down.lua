package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")

function m(s)
reaper.ShowConsoleMsg(tostring(s) .. "\n")

end



reaper.Main_OnCommand(42406,0)


function movetrackdown()

------------------------------------------------------------------------------
local function No_Undo()end local function no_undo()reaper.defer(No_Undo)end
------------------------------------------------------------------------------




local SaveSelTracksGuid = function(down) 
for i = 1, reaper.CountSelectedTracks(0) do 
local track = reaper.GetSelectedTrack(0, i - 1)
down[i] = reaper.GetTrackGUID( track )
end 
end
--- 


local RestoreSelTracksGuid = function(down) 
local tr = reaper.GetTrack(0,0) 
reaper.SetOnlyTrackSelected(tr) 
reaper.SetTrackSelected(tr, 0) 
for i = 1, #down do
local track = GuidToTrack(down[i])
if track then
reaper.SetTrackSelected(track,1) 
end
end  
end
---



local count_sel = reaper.CountSelectedTracks(0)
if count_sel == 0 then no_undo() return end



local sel_tracks = {}  
SaveSelTracksGuid(sel_tracks) 

reaper.PreventUIRefresh(1) 

local depth,track_number,penultimate_in_folder,fol,fold
---
reaper.InsertTrackAtIndex(reaper.CountTracks(0),false)
local track = reaper.GetTrack(0,reaper.CountTracks(0)-1)
local GUID = reaper.GetTrackGUID(track)
---
local CountTracks = reaper.CountTracks(0)
for i = CountTracks-1,0,-1 do    
local track = reaper.GetTrack(0, i)
local SEL = reaper.GetMediaTrackInfo_Value(track,"I_SELECTED")
if SEL == 1 then 
fold = reaper.GetMediaTrackInfo_Value( track, "I_FOLDERDEPTH")
track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
depth = reaper.GetTrackDepth(track)
-- Get relocatable track 
if depth > 0 then 
if fold ~= 1 then 
for i2 = track_number-1,0,-1 do        
local Tr = reaper.GetTrack(0, i2)
local fol = reaper.GetMediaTrackInfo_Value( Tr, "I_FOLDERDEPTH")
if fol == 1 then 
local SEL_fol = reaper.GetMediaTrackInfo_Value(Tr,"I_SELECTED")
if SEL_fol == 1 then
track_number = reaper.GetMediaTrackInfo_Value( Tr, "IP_TRACKNUMBER") 
end
break
end
end
end
end
local track = reaper.GetTrack(0,track_number-1)
reaper.SetOnlyTrackSelected(track)
fol = reaper.GetMediaTrackInfo_Value(track,"I_FOLDERDEPTH")
---
-- Get last track in folder 
if fol == 1 then 
local depth = reaper.GetTrackDepth(track)
for i2 = track_number, reaper.CountTracks(0)-1 do
local track = reaper.GetTrack(0,i2)
local depth2 = reaper.GetTrackDepth(track)
if depth >= depth2 then 
track_number = (reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")-1) 
break
end
end
end
---
-- Get values from the user
local track_f_pre_last = reaper.GetTrack(0,track_number-1)
local fol_pre_last = reaper.GetMediaTrackInfo_Value(track_f_pre_last,"I_FOLDERDEPTH")
local track_f_pre_last_depth = reaper.GetTrackDepth(track_f_pre_last)
local sel_pre_last = reaper.GetMediaTrackInfo_Value(track_f_pre_last,"I_SELECTED")
local track_fold_last = reaper.GetTrack(0,track_number)
if track_fold_last then
local fol_last = reaper.GetMediaTrackInfo_Value(track_fold_last,"I_FOLDERDEPTH")

local _, next_tr = reaper.GetTrackName( track_fold_last, '' )    
--------------------------------------------------------- 




if fol_pre_last == -1.0  then

folder_of_track =  reaper.GetParentTrack(track_f_pre_last)
reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 2 )

elseif fol_last == 1.0 then 

reaper.SetMediaTrackInfo_Value( track_fold_last , 'I_FOLDERCOMPACT', 0 )

elseif fol_pre_last == -2.0   then



folder_of_track =  reaper.GetParentTrack(track_f_pre_last)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)

reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )


elseif fol_pre_last == -3.0 then



folder_of_track =  reaper.GetParentTrack(track_f_pre_last)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)

reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )



elseif fol_pre_last == -4.0  then



folder_of_track =  reaper.GetParentTrack(track_f_pre_last)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)
folder_folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_folder_of_track)

reaper.SetMediaTrackInfo_Value( folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )
reaper.SetMediaTrackInfo_Value( folder_folder_folder_folder_of_track , 'I_FOLDERCOMPACT', 2 )





-------------------------------------------------------------------------------------  
end






---
if fol_last < 0 and fol_pre_last == 0 and sel_pre_last == 1 then 
penultimate_in_folder = 2




end
---
if fol_pre_last < 0 and sel_pre_last == 1 then

track_number = track_number - 1 penultimate_in_folder = 0 

end
end
---

if not penultimate_in_folder then penultimate_in_folder = 0 end
reaper.ReorderSelectedTracks( track_number+1,penultimate_in_folder) 

RestoreSelTracksGuid(sel_tracks)

for i = track_number, reaper.CountTracks(0)-1 do
local track = reaper.GetTrack(0,i)
reaper.SetTrackSelected(track,0)
end
end
end

local track = GuidToTrack(GUID)
reaper.SetOnlyTrackSelected(track)
reaper.ReorderSelectedTracks(reaper.CountTracks(0),0)
reaper.DeleteTrack(track)

RestoreSelTracksGuid(sel_tracks)


local SelTr = reaper.GetSelectedTrack(0,reaper.CountSelectedTracks(0)-1)
local track_number = reaper.GetMediaTrackInfo_Value(SelTr,"IP_TRACKNUMBER")
if track_number == reaper.CountTracks(0) then Scrol = 0 end
---

reaper.PreventUIRefresh(-1)
DoSelectLastOfSelectedTracks() ----select last reaper.Main_OnCommand(reaper.NamedCommandLookup('_XENAKIOS_SELLASTOFSELTRAX'), 0) 
--reaper.Main_OnCommand(40696,0)-- rename
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_TRACKS'),0)
RestoreSelTracksGuid(sel_tracks)

---

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





function GetMaxNonSelItem(tr,sitem)
R_itemStart = reaper.GetMediaItemInfo_Value(sitem, "D_POSITION")
R_itemEnd = R_itemStart + reaper.GetMediaItemInfo_Value(sitem, "D_LENGTH")
nonselected_max = 0
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
item_bottom = reaper.GetMediaItemInfo_Value( item, "I_LASTY")+reaper.GetMediaItemInfo_Value( item, "I_LASTH")  
nonselected_max= math.max(item_bottom, nonselected_max)                          
end 
end
end
end
return nonselected_max
end





function moveitem()




MoveWithMI = 40070
MoveWithMIOff = 0
MoveWithMI_State = reaper.GetToggleCommandState(MoveWithMI)
if (MoveWithMI_State == 1) then
reaper.Main_OnCommand(MoveWithMI, 0)
MoveWithMIOff = 1
end


reaper.Main_OnCommand(40118, 0) --- Item edit: Move items/envelope points down one track/a bit

if (MoveWithMIOff == 1) then

reaper.Main_OnCommand(MoveWithMI, 0)

end





SelTracksWItems()


for i = 1, reaper.CountSelectedMediaItems(0) do 
imoveitem =  reaper.GetSelectedMediaItem( 0, i-1 )
current_track = reaper.GetMediaItem_Track(imoveitem)
current_track_fold = reaper.GetMediaTrackInfo_Value(current_track,"I_FOLDERDEPTH")
number = reaper.GetMediaTrackInfo_Value( current_track, "IP_TRACKNUMBER")



local next_track = reaper.GetTrack(0,number-2)
if next_track then
number_next  = reaper.GetMediaTrackInfo_Value( next_track, "IP_TRACKNUMBER")
next_fold = reaper.GetMediaTrackInfo_Value(next_track,"I_FOLDERDEPTH") end





if next_fold == -1.0   then

folder_of_track =  reaper.GetParentTrack(next_track)


elseif next_fold == 1.0 then 

reaper.SetMediaTrackInfo_Value( next_track , 'I_FOLDERCOMPACT', 0 )

elseif next_fold == -2.0  then



folder_of_track =  reaper.GetParentTrack(next_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)

elseif next_fold == -3.0  then

folder_of_track =  reaper.GetParentTrack(next_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)



elseif next_fold == -4.0  then



folder_of_track =  reaper.GetParentTrack(next_track)
folder_folder_of_track =  reaper.GetParentTrack(folder_of_track)
folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_of_track)
folder_folder_folder_folder_of_track =  reaper.GetParentTrack(folder_folder_folder_of_track)





-------------------------------------------------------------------------------------  
end






end









DoSelectLastOfSelectedTracks() --reaper.Main_OnCommand(reaper.NamedCommandLookup('_XENAKIOS_SELLASTOFSELTRAX'), 0) ----select last
--reaper.Main_OnCommand(40696,0)-- rename
--reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)







end


focus = reaper.GetCursorContext2(true) --  Берём переменную значения где сейчас фокус?
if focus == 0 then 

reaper.Undo_BeginBlock(); 
movetrackdown()
reaper.Undo_EndBlock('Move Track Down', -1)

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




if GetMaxNonSelItem(tr,citem) > (reaper.GetMediaItemInfo_Value( citem, "I_LASTY")+(reaper.GetMediaItemInfo_Value( citem, "I_LASTH")/2)) and IsItemVisible(citem)==true then 
notyet = 1
end
end  



if notyet == 1 then
  


for _, it in ipairs(table) do
local tr = reaper.GetMediaItem_Track(it)




if GetMaxNonSelItem(tr,it)  > (reaper.GetMediaItemInfo_Value( it, "I_LASTY")+(reaper.GetMediaItemInfo_Value( it, "I_LASTH")/2)) then
  
reaper.SelectAllMediaItems( 0, 0 )
reaper.SetMediaItemSelected( it, true )
reaper.Main_OnCommand(40107,0)  ---move down
RestoreSelectedItemsFromTable (table)
end ----


end 


else

moveitem()

end-------

else 

moveitem()

end

reaper.UpdateTimeline()

reaper.Undo_EndBlock('Move Item Down', -1)
end
