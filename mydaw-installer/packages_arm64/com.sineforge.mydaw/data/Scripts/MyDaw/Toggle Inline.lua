-----------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end
    -----------------------------------------------------------------------------


local function nothing() end; local function no_action() reaper.defer(nothing) end

local function SaveSelItems()
  sel_items = {}
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    sel_items[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

local function RestoreSelItems()
  reaper.Main_OnCommand(40289,0) -- Unselect all items
  for _, item in ipairs(sel_items) do
    if item then reaper.SetMediaItemSelected(item, 1) end
  end
end

x, y = reaper.GetMousePosition()

item, take = reaper.GetItemFromPoint( x, y , true)


if not item then no_action() return end

local take = reaper.GetActiveTake(item)
if not reaper.TakeIsMIDI(take) then return end

reaper.PreventUIRefresh(1)
SaveSelItems()
reaper.Main_OnCommand(40289,0) -- Unselect all items
reaper.SetMediaItemSelected(item,1)

if not inline then
  reaper.Main_OnCommand(40847,0) --Item: Open item inline editors
else
  reaper.Main_OnCommand(41887,0) --Item: Close item inline editors
end

RestoreSelItems()
reaper.PreventUIRefresh(-1) 
no_undo()
