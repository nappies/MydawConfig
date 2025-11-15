package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

function nothing()
end

local function StoreSelectedObjects()
    -- Store selected items
    local sel_itms_cnt = reaper.CountSelectedMediaItems(0)
    local itm_sel_t = {}
    if sel_itms_cnt > 0 then
        local i = 0
        while i < sel_itms_cnt do
            itm_sel_t[#itm_sel_t + 1] = reaper.GetSelectedMediaItem(0, i)
            i = i + 1
        end
    end

    return itm_sel_t
end

itm_sel_t = StoreSelectedObjects()

if reaper.CountMediaItems() > 0 then
    dump = 1
    if dump == 1 then
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)

        if #itm_sel_t > 0 then
            local i = 0
            while i < #itm_sel_t do
                reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
                reaper.SetMediaItemSelected(itm_sel_t[i + 1], 1)

                it = itm_sel_t[i + 1]

                take = reaper.GetActiveTake(it)

                midi = reaper.TakeIsMIDI(take)
                if midi == true then
                    reaper.Main_OnCommand(41588, 0) ---Glue
                    local trash = "-glued"
                    DelNameTrash(trash)
                elseif midi == false then
                    reaper.Main_OnCommand(41999, 0) --Render as new take

                    local strash = "render"
                    DelNameTrash(strash)

                    reaper.Main_OnCommand(40131, 0) --Crop
                end

                i = i + 1
            end
        end

        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Crop Item(s)", -1)
    else
        reaper.defer(nothing)
    end
else
    reaper.defer(nothing)
end
