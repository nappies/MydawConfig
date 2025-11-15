function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end

  reaper.ClearConsole()
  ----------------------------------------------------------------------------------- 
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
end
  -----------------------------------------------------------------------------------   
  function ExtractVSTName(s)
    if not s then return end
    local t = {}
    for val in s:gmatch('[^%,]+') do t[#t+1]=val end
    local out_val
    if t[3] then out_val = t[3] else return end
    if out_val:find('!!!') then out_val = out_val:sub(0, out_val:find('!!!')-1) end
    return out_val
  end
  -----------------------------------------------------------------------------------  
  function ExtractVendor(s)
    local t = {}
    local out_str = ''
    for str in s:gmatch("%((.-)%)") do 
      if not 
        (
          str:len()<2
          or str:lower():find('mono')
          or str:lower():find('stereo')
          or str:lower():find('multi')
          or str:lower():find('64')
          or str:lower():find('voice')
          or str:lower():match('v[%d]')
        ) 
       then 
        if str:len() > out_str:len() then out_str = str end
      end
    end
    return out_str
  end
  -----------------------------------------------------------------------------------
  function GetPluginsTable()
      local context = ''
      local plugins_info = reaper.GetResourcePath()..'/'..'reaper-vstplugins.ini'
      f=io.open(plugins_info, 'r')
      if f then context = f:read('a') else return end
      f:close()  
      
      local plugins_info = reaper.GetResourcePath()..'/'..'reaper-vstplugins64.ini'
      f=io.open(plugins_info, 'r')
      if f then 
        context = context..f:read('a')
        f:close() 
      end             
        
      local t = {}
      for line in context:gmatch('[^\r\n]+') do t[#t+1] = line end
      return t
  end
  -----------------------------------------------------------------------------------
  function main()
    local t = GetPluginsTable()
    -- get sorted table
      local t_sort = {}
      for i = 1, #t do
        local vend = ExtractVendor(t[i])
        local fx_name = ExtractVSTName(t[i])
        
        m(vend)
        m(fx_name)
        
        
        if not reaper.CSurf_TrackFromID( 1, false ) then reaper.InsertTrackAtIndex( 1,false ) end
         
         if fx_name ~=  nil  then
         
         
         reaper.TrackFX_AddByName(reaper.CSurf_TrackFromID( 1, false ), fx_name, false,-1) 
         
         
         -- show ok/cancel dialog
         local r = reaper.ShowMessageBox("Do you want to proceed?", "ReaScript", 1)
         if r == 1 then -- user pressed ok button in dialog
         
                 
                 track = reaper.CSurf_TrackFromID( 1, false )
                 for fx = reaper.TrackFX_GetCount( track ), 1, -1 do
                 local retval, buf = reaper.TrackFX_GetFXName( track, fx )
                  reaper.TrackFX_Delete(track, fx-1) 
                 end
                 
                 
         else 
         
         break
         
         
         
         end
        
        
        
        end

        
        
        if not vend then vend = 'Unknown' end 
        if not t_sort[vend] then t_sort[vend] = {} end
        if fx_name and vend == 'Unknown' then        
          t_sort[vend][#t_sort[vend]+1] = fx_name
        
          
        end
      end
      
      --[[local addTS = os.date():gsub('%:', '.')
      local command = 'rename "'..reaper.GetResourcePath()..'/'..'reaper-fxfolders.ini"'..'  '..'"reaper-fxfolders'..'_backup'..addTS..'.ini"'
      command = command:gsub('/', '\\')
      --msg(command)
      os.execute(command)]]
      
    -- form new reaper-fxfolders.ini
   
  end
  -----------------------------------------------------------------------------------
  main()

