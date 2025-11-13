function ShowHidetracks(show)
    --------------record to notes-------

    for i = 0, reaper.CountTracks(0)-1 do
        local Track = reaper.GetTrack(0, i)

        if Track then
            local retval, number = reaper.GetSetMediaTrackInfo_String(Track, "P_EXT:ISND", "", false)
            if retval then
                reaper.SetMediaTrackInfo_Value(Track, "B_SHOWINMIXER", show)
                reaper.SetMediaTrackInfo_Value(Track, "B_SHOWINTCP", show)
            end
        end
    end

    reaper.TrackList_AdjustWindows(0)
end



function GetReturnsState()
    local retval, state = reaper.GetProjExtState(0, "MyDaw", "Returns")

    toggleState = -1

    if not state or state == "" then
       
	   for i = 0, reaper.CountTracks(0)-1 do
            getrack = reaper.GetTrack(0, i)

            retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String(getrack, "P_TCP_LAYOUT", 0, 0)

            if (stringNeedBig == "Return") then
                if (reaper.GetMediaTrackInfo_Value(getrack, "B_SHOWINTCP") == 1) then
                    toggleState = 0
                    reaper.SetProjExtState(0, "MyDaw", "Returns", "0")
                    ShowHidetracks(0)
                else
                    toggleState = 1
                    reaper.SetProjExtState(0, "MyDaw", "Returns", "1")
                    ShowHidetracks(1)
                end
            end
        end
    else
        if (tonumber(state) == 1) then
            toggleState = 0
            reaper.SetProjExtState(0, "MyDaw", "Returns", "0")
            ShowHidetracks(0)
        else
            toggleState = 1
            reaper.SetProjExtState(0, "MyDaw", "Returns", "1")
            ShowHidetracks(1)
        end
    end

    is_new, name, sec, cmd, rel, res, val = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, toggleState)
    reaper.RefreshToolbar2(sec, cmd)
end




GetReturnsState()
