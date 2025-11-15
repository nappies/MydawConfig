-----------------------------------------------------------------------------
    local function No_Undo()end; local function no_undo()reaper.defer(No_Undo)end
    -----------------------------------------------------------------------------



function action(id) reaper.Main_OnCommand(id, 0) end
local _,_,_,_,_,_,val = reaper.get_action_context()


if val > 0 then  reaper.Main_OnCommand(40155, 0) else reaper.Main_OnCommand(40156, 0) end


    reaper.UpdateArrange()
    no_undo()


