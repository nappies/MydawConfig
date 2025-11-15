    local url = [[https://raw.githubusercontent.com/ReaTeam/Extensions/master/index.xml]]
    reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", url, true, 2 )
    reaper.ReaPack_ProcessQueue( true )
    reaper.ReaPack_BrowsePackages('js_ReascriptAPI')