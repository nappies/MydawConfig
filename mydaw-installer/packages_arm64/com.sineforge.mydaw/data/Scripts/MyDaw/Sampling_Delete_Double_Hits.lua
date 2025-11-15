function m(a, s)
    reaper.ShowConsoleMsg(tostring(a) .. " " .. tostring(s).."\n")
end

percent_tresh = 99.99
searchwindow = 8
onesecond_divider = 4

function find_similarity_with_shift(arr1, arr2, max_shift)
    local best_similarity = -1
    local best_shift = 0
    for shift = -max_shift, max_shift do
        local shifted_arr2 = {}
        for i = 1, #arr2 do
            local j = i + shift
            if j >= 1 and j <= #arr2 then
                table.insert(shifted_arr2, arr2[j])
            else
                table.insert(shifted_arr2, 0)
            end
        end
        local similarity = find_similarity(arr1, shifted_arr2)
        if similarity > best_similarity then
            best_similarity = similarity
            best_shift = shift
        end
        if best_similarity >= percent_tresh then
            return true
        end
    end
    return false
end

function normalize(arr)
    local sum = 0
    for i = 1, #arr do
        sum = sum + arr[i]
    end
    local mean = sum / #arr
    local sum_sq_diff = 0
    for i = 1, #arr do
        sum_sq_diff = sum_sq_diff + (arr[i] - mean) ^ 2
    end
    local std_dev = math.sqrt(sum_sq_diff / #arr)
    for i = 1, #arr do
        arr[i] = (arr[i] - mean) / std_dev
    end
    return arr
end

function correlation(arr1, arr2)
    local sum = 0
    for i = 1, #arr1 do
        sum = sum + arr1[i] * arr2[i]
    end
    return sum / #arr1
end

function find_similarity(arr1, arr2)
    arr1 = normalize(arr1)
    arr2 = normalize(arr2)
    return correlation(arr1, arr2) * 100
end

function tableContains(table, value)
    for i = 1, #table do
        if (table[i] == value) then
            return true
        end
    end
    return false
end

function Delete_Source(item, del_sor)
    take = reaper.GetActiveTake(item)
    if take then
        -- Удалить исходный файл
        pcm_source = reaper.GetMediaItemTake_Source(take)
        filenamebuf = reaper.GetMediaSourceFileName(pcm_source, "")
        tr = reaper.GetMediaItemTrack(item)
        reaper.DeleteTrackMediaItem(tr, item)
        if del_sor then
            os.remove(filenamebuf)
        end
    end
end

function Delete_Items_And_Shift(items, delete_sor)

    for k = 1, #items do
        ditem = items[k]

        if reaper.ValidatePtr2( 0, ditem , "MediaItem*") then
            -- Найти такт, в котором расположен выделенный элемент
            local ditem_start = reaper.GetMediaItemInfo_Value(ditem, "D_POSITION")
            local ditem_start = reaper.SnapToGrid(0, ditem_start)

            local _, meas, _, _, _ = reaper.TimeMap2_timeToBeats(0, ditem_start)
            local nxt_meas_tm = reaper.TimeMap2_beatsToTime(0, 0, meas + 1)
            local _, nxt_meas, _, _, _ = reaper.TimeMap2_timeToBeats(0, nxt_meas_tm)

            local cur_take = reaper.GetActiveTake(ditem)
            local cnm = reaper.GetTakeName(cur_take)

            --m(cnm, ditem_start)
            --m("number measure",meas, nxt_meas)
            --m("time",ditem_start, nxt_meas_tm)

            -- Найти все элементы на всех треках в этом же такте и удалить их
            for i = 0, reaper.CountTracks(0) - 1 do
                track = reaper.GetTrack(0, i)
                for j = 0, reaper.CountTrackMediaItems(track) - 1 do
                    sitem = reaper.GetTrackMediaItem(track, j)
                    if sitem and sitem ~= ditem then
                        item_start = reaper.GetMediaItemInfo_Value(sitem, "D_POSITION")
                        item_start = reaper.SnapToGrid(0, item_start)
                        _, item_measure, _, _, _ = reaper.TimeMap2_timeToBeats(0, item_start)
                        if math.floor(item_measure) == math.floor(meas) then
                            --Delete_Source(sitem, delete_sor)
                        end
                    end
                end
            end

            --Delete_Source(ditem, delete_sor)

            reaper.GetSet_LoopTimeRange2(0, true, false, ditem_start, nxt_meas_tm, false)
            -- Удалить найденный такт со сдвигом всего проекта
            reaper.Main_OnCommand(40201, 0) -- Удалить время и сдвинуть позицию

            reaper.UpdateArrange()
        end
    end
end

local seltrack = reaper.GetSelectedTrack(0, 0)

if seltrack then
    local item_cnt = reaper.CountTrackMediaItems(seltrack)
    local _, _, num_regions = reaper.CountProjectMarkers(0)
    if item_cnt == 0 or num_regions == 0 then
        return reaper.defer(
            function()
            end
        )
    end

    local region_items = {}

    for i = 0, item_cnt - 1 do
        local item = reaper.GetTrackMediaItem(seltrack, i)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_pos)
        local _, _, _, _, name = reaper.EnumProjectMarkers(regionidx)
        --m(regionidx, name)
        if region_items[regionidx + 1] == nil then
            region_items[regionidx + 1] = {}
        end
        table.insert(region_items[regionidx + 1], item)
    end

    local items_to_delete = {}

    for reg_id = 1, #region_items do
        local items = region_items[reg_id]
        for i = 1, #items do
            local item_comare = items[i]
            if not tableContains(items_to_delete, item_comare) then
                local take1 = reaper.GetActiveTake(item_comare)
                local source = reaper.GetMediaItemTake_Source(take1)
                local samplerate = reaper.GetMediaSourceSampleRate(source)
                local channels = reaper.GetMediaSourceNumChannels(source)
                local start_pos = 0
                local samples = samplerate / onesecond_divider
                local buffer = reaper.new_array(samples * channels)
                local accessor1
                local tkname1 = reaper.GetTakeName(take1)
                m("   reference sample", tkname1)
                if accessor1 == nil then
                    accessor1 = reaper.CreateTakeAudioAccessor(take1)
                end
                for j = i + 1, #items do
                    local item2 = items[j]
                    local take2 = reaper.GetMediaItemTake(item2, 0)
                    local tkname2 = reaper.GetTakeName(take2)
                    m("compared sample", tkname2)
                    local accessor2 = reaper.CreateTakeAudioAccessor(take2)
                    local buffer1 = reaper.new_array(samples * channels)
                    local buffer2 = reaper.new_array(samples * channels)
                    reaper.GetAudioAccessorSamples(accessor1, samplerate, channels, start_pos, samples, buffer1)
                    reaper.GetAudioAccessorSamples(accessor2, samplerate, channels, start_pos, samples, buffer2)
                    reaper.DestroyAudioAccessor(accessor2)
                    local identical, shift = find_similarity_with_shift(buffer1, buffer2, searchwindow)
                    if identical then
                        m("Duplicate found",tkname2)
                        table.insert(items_to_delete, items[j])
                    end
                end
                reaper.DestroyAudioAccessor(accessor1)
            end
        end
    end

   
    if #items_to_delete > 0 then
    -- Сообщение для диалогового окна
    local msg =
        "Are you going to delete " ..
        #items_to_delete .. " duplicates. Yes - Delete with sources, No - Delete from Project"

    -- Заголовок диалогового окна
    local title = "Removing duplicates"

    -- Тип диалогового окна
    local type = 3 -- YESNOCANCEL

    -- Отображение диалогового окна и получение результата
    local result = reaper.MB(msg, title, type)

    -- Обработка результата
    if result == 6 then -- YES
        Delete_Items_And_Shift(items_to_delete, true)
    elseif result == 7 then -- NO
        Delete_Items_And_Shift(items_to_delete, false)
    else -- CANCEL
    end
    
    end

    reaper.UpdateArrange()
end

