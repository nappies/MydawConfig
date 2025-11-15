

    reaper.PreventUIRefresh(1)

    local tr = reaper.GetSelectedTrack(0,0)
    if not tr then return end

    local numb = reaper.GetMediaTrackInfo_Value(tr,"IP_TRACKNUMBER")
    reaper.InsertTrackAtIndex(numb-1,true)
    reaper.ReorderSelectedTracks(numb,1)
    local tr = reaper.GetTrack(0,numb-1)
    reaper.SetMediaTrackInfo_Value(tr,"I_SELECTED",1)
    reaper.SetOnlyTrackSelected(tr)


    reaper.PreventUIRefresh(-1)
    reaper.Main_OnCommand(40696,0)
