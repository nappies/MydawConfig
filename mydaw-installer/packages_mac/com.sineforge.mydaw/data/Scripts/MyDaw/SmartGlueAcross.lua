package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

local function SaveSelectedItems()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local it = reaper.GetSelectedMediaItem(0, i)
    reaper.GetSetMediaItemInfo_String( it, "P_EXT", "LetsGlue", true )
        --reaper.ULT_SetMediaItemNote(it, "LetsGlue")
    end
end

SaveSelectedItems()

local function RestoreSelectedItems()
    UnselectAllItems()
    for i = 0, reaper.CountMediaItems(0) - 1 do
        local it = reaper.GetMediaItem(0, i)
    local ret, res = reaper.GetSetMediaItemInfo_String(it, "P_EXT", "", false)
        if res == "LetsGlue" then
            reaper.SetMediaItemSelected(it, true)
            --reaper.ULT_SetMediaItemNote(it, "")
      reaper.GetSetMediaItemInfo_String( it, "P_EXT", "", true )
      
        end
    end
end

function wavestune_glue()
    local itemcount = reaper.CountMediaItems(0)
    if itemcount ~= nil then
        for i = 1, itemcount do
            local item = reaper.GetMediaItem(0, i - 1)
            if item ~= nil then
      local ret, res = reaper.GetSetMediaItemInfo_String(item, "P_EXT", "", false)
                if res == "LetsGlue" then
                    takecount = reaper.CountTakes(item)
                    for j = 1, takecount do
                        take = reaper.GetTake(item, j - 1)
            
                        if reaper.TakeFX_GetCount(take) ~= 0 then
                            fx_count = reaper.TakeFX_GetCount(take)
                            for fx = 1, fx_count do
                                _, fx_name = reaper.TakeFX_GetFXName(take, fx - 1, "")
                                if string.find(fx_name, "WavesTune") then
                                    reaper.Main_OnCommand(40289, 0)
                                     ----unselect all media items
                                    reaper.SetMediaItemSelected(item, true)
                                    SelTracksWItems() ----SelectOnly with items
                                    reaper.Main_OnCommand(40535, 0) ----Set offline tracks with items
                                    reaper.Main_OnCommand(40361, 0) -----Apply to mono take
                                    reaper.Main_OnCommand(40131, 0) -----Crop to Active take
                                    deltrash = "-glued"
                                    DelNameTrash(deltrash)
                                    reaper.Main_OnCommand(40536, 0) ----set online track fx
                                end
                            end
                        end -- for fx
                    end
                end -- for
            end
        end -- for
    end
end

function audio_midi_glue()
    itemcountd = reaper.CountMediaItems(0)
    if itemcountd ~= nil then
        for i = 1, itemcountd do
            local item = reaper.GetMediaItem(0, i - 1)
            if item ~= nil then
      local ret, res = reaper.GetSetMediaItemInfo_String(item, "P_EXT", "", false)
                if res == "LetsGlue" then
                    local take = reaper.GetActiveTake(item)
                    if reaper.TakeIsMIDI(take) == true then
                        midihere = 1
                    end
                    if reaper.TakeIsMIDI(take) == false then
                        audiohere = 1
                    end
                end -- for
            end
        end -- for
    end

    if midihere == 1 and audiohere == 1 then
        itemcount = reaper.CountMediaItems(0)
        if itemcount ~= nil then
            for i = 1, itemcount do
                local item = reaper.GetMediaItem(0, i - 1)
                if item ~= nil then
        local ret, res = reaper.GetSetMediaItemInfo_String(item, "P_EXT", "", false)
                    if res == "LetsGlue" then
                        local takecount = reaper.CountTakes(item)
                        for j = 1, takecount do
                            local take = reaper.GetTake(item, j - 1)
                            if reaper.TakeIsMIDI(take) == true then
                                reaper.Main_OnCommand(40289, 0) ----Unslelct all
                                reaper.SetMediaItemSelected(item, true)
                                reaper.Main_OnCommand(40209, 0) ----apply
                                reaper.Main_OnCommand(40131, 0) -----crop to active take
                            end
                        end
                    end -- for
                end
            end -- for
        end
    end
end

function JustGlue()
    focus = reaper.GetCursorContext()
    

    if focus == 1 or focus == -1 then
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)

        wavestune_glue()

        audio_midi_glue()

        RestoreSelectedItems()
        reaper.Main_OnCommand(40644, 0) ---Item: Implode items across tracks into items on one track

        reaper.Main_OnCommand(41588, 0) ----Item: Glue items

        deltrash = "-glued"
        DelNameTrash(deltrash)

        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Glue", -1)
    elseif focus == 2 then
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)
        reaper.Main_OnCommand(42089, 0) ---Envelope: Glue automation items
         -----Envelope: Glue automation items
        deltrash = "-glued"
        DelNameTrash(deltrash)
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Glue", -1)
    end
end

JustGlue()
