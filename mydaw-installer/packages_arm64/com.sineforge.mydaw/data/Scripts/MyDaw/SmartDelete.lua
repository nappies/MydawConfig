function msg(m)
    reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function DeleteEnvelopesOfItems()
    -------------------------------------------ADD SELCETED ITEMS---------------------------

    -- LOOP THROUGH SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)

    -- INITIALIZE loop through selected items
    -- Select tracks with selected items

    for i = 0, selected_items_count - 1 do
        -- GET ITEMS
        item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i

        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        track = reaper.GetMediaItem_Track(item)
        --Here we select envelope points

        env_count = reaper.CountTrackEnvelopes(track)

        for m = 0, env_count - 1 do
            -- GET THE ENVELOPE
            env = reaper.GetTrackEnvelope(track, m)

            _, visible = reaper.GetSetEnvelopeInfo_String(env, "VISIBLE", "", false)

            if visible == true then
                -- GET LAST POINT TIME OF DEST TRACKS AND DELETE ALL
                env_points_count = reaper.CountEnvelopePoints(env)

                reaper.DeleteEnvelopePointRange(env, itemStart, itemEnd)
            end -- END LOOP THROUGH SAVED POINTS
        end
    end
    reaper.UpdateArrange()
end

startOut, endOut = reaper.GetSet_LoopTimeRange2(0, 0, 0, 0, 0, 0) --  Даем переменную "Time selection"
focus = reaper.GetCursorContext() --  Даем переменную значения где сейчас фокус?

if focus == 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    reaper.DeleteExtState("MyDaw", "focus_on_volume", false)
    reaper.Main_OnCommand(40005, 0) --если фокус на треках то даем команду стереть трек

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Delete", -1)
elseif endOut == 0 and focus == 1 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    MoveWithMI = 40070

    MoveWithMI_State = reaper.GetToggleCommandState(MoveWithMI)

    if (MoveWithMI_State == 1) then
        DeleteEnvelopesOfItems()
    end

    reaper.Main_OnCommand(40697, 0) -- если нет "Time selection" и фокус на "Items" стираем выделеные "Items"

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Delete", -1)
elseif endOut == 0 and focus == 2 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    reaper.Main_OnCommand(40697, 0) -- если нет "Time selection" и фокус на "Envelope" стираем выделенную точку

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Delete", -1)
elseif endOut > 0 and focus == 2 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    reaper.Main_OnCommand(40089, 0) --Если есть "Time selection" и фокус на "Envelopes стираем группу точек в "Time selection""

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Delete", -1)
end
