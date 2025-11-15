package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")


reaper.DeleteExtState("MyDaw_copy-paste", "take_envelopes",0)
focus = reaper.GetCursorContext() --  Даем переменную значения где сейчас фокус?


if focus == 0 then


reaper.Main_OnCommand(40337, 0)  ---cut track

else

 reaper.PreventUIRefresh(1)
 
 
 local sst = {}
 
 SaveSelectedTracks(sst)

    reaper.Undo_BeginBlock()

    if reaper.GetToggleCommandState(42459) == 0 then --Options: Razor edits in media item lane affect all track envelopes
        
        local savedRazorEdits = {}
        
        savedRazorEdits = GetRazorWithoutEnv()

        reaper.Main_OnCommand(42406, 0) --Clear Razors

        RestoreRazorEdits(savedRazorEdits)
    end

   local razor_edits = {}
  
    razor_edits = SaveRazorEdits() -- Global table to store razor edits 

   reaper.Main_OnCommand(42406, 0) --Clear Razors

    reaper.Mydaw_DeleteGhostEnv()

    RestoreRazorEdits(razor_edits)

    reaper.Main_OnCommand(40699, 0) ---cut all

    SetFirstRazorEditTrackAsLastTouched()

    reaper.Undo_EndBlock("Copy Clear", -1)
    
    RestoreSelectedTracks(sst)
    
    reaper.PreventUIRefresh(-1)
    
     reaper.UpdateArrange()






end















