package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

red = reaper.ColorToNative(255,0,0)|0x1000000
green = reaper.ColorToNative(0,255,0)|0x1000000

name = "Good"  --write good or bad here....or leave blank like name=""  
color = green  -- change this to red for "bad" version of this script 

-----------code



function Insert_Colored_Take_Marker(item)   
  cursorPosition = reaper.GetCursorPosition()
  playPosition = reaper.GetPlayPosition()--use this instead of cursorPosition if you want to add marker at the playhead rather than where you clicked (only works while playing)
  activeTakeNumber= reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
  itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  take = reaper.GetMediaItemTake(item, activeTakeNumber);
  startOffset =  reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  reaper.SetTakeMarker(take, -1, name, cursorPosition+startOffset-itemPosition, color)
end

function Main()
  reaper.Undo_BeginBlock()
  lastitem = reaper.GetExtState("MyDaw", "Click On Bottom Half")
    if not lastitem or lastitem == "" then
        return
    end
  
    item = GuidToItem(lastitem)
  
    if not item then
        return
    end
  
  Insert_Colored_Take_Marker(item)
  reaper.Undo_EndBlock("Insert_Colored_Take_Marker", 0)
end  

Main()
