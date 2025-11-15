function NoUndoPoint() 




local function nothing() end; local function noaction() reaper.defer(nothing) end


------------------------------------show tracks fuction



function showtracksfromnotes()

--------------record to notes-------


function showrecordnotes()


local function esc_lite(str) str = str:gsub('%-', '%%-') return str end

local function nothing() end; local function noaction() reaper.defer(nothing) end




local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')

local a = '||showhidetracks\r\n'


local data = notes:match(a..'(.-\r\n)end||')


local new_data
local vsolo_data = data:match('vsolo'..'%d'..' (.-)\r\n')

local vsolo_mode = data:match('vsolo'..'..')


local mode = 0

new_data = data:gsub('vsolo'..'%d'..' '..esc_lite(vsolo_data),'vsolo'..mode..' '..vsolo_data,1)
 
notes = notes:gsub(esc_lite(data),new_data)

reaper.SetProjExtState( 0, 'MyDaw', 'Vsolo', notes ) 
reaper.TrackList_AdjustWindows(0)

end




------------------------record to notes end-----------








local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')
local data = notes:match'||showhidetracks\r\n(.-\r\n)end||'
if not data then noaction() return end
local sel_tracks_str = data:match('vsolo'..'%d'..' (.-)\r\n')
if not sel_tracks_str then noaction() return end

local t = {}

for guid in sel_tracks_str:gmatch'{.-}' do
  local tr = GuidToTrack(guid)
  if tr then t[#t+1] = tr end
end

if #t == 0 then noaction() return end


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

local hidetrack = reaper.GetTrack(0, 0)



for i = 1, #t do 

reaper.SetMediaTrackInfo_Value(t[i], 'B_SHOWINMIXER',1)
reaper.SetMediaTrackInfo_Value(t[i], 'B_SHOWINTCP',1)

reaper.TrackList_AdjustWindows(0)

end

showrecordnotes()

reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('Hide No Solo', -1)

end





----------------------------end of -------





















function saveoraddtracks()

local vsolo = 0

local function esc_lite(str) str = str:gsub('%-', '%%-') return str end

local function nothing() end; local function noaction() reaper.defer(nothing) end




local tracks = reaper.CountTracks()
if tracks == 0 then noaction() return end


local solo_str = ''

for i = 0, tracks-1 do 

tr = reaper.GetTrack(0, i)

soloed = reaper.GetMediaTrackInfo_Value(tr, 'I_SOLO')
hidedmix = reaper.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER')
hidedtcp = reaper.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP')


if soloed == 0 and hidedmix == 1 and hidedtcp == 1 then

solo_str = solo_str..reaper.GetTrackGUID(reaper.GetTrack(0, i)) end

end

local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')

local a = '||showhidetracks\r\n'

local data = notes:match(a..'(.-\r\n)end||')

if data then

local new_data
local vsolo_data = data:match('vsolo'..'%d'..' (.-)\r\n')


if vsolo_data then
    new_data = data:gsub('vsolo'..vsolo..' '..esc_lite(vsolo_data),'vsolo'..vsolo..' '..solo_str,1)
else new_data = data..'vsolo'..vsolo..' '..solo_str..'\r\n' end
 
notes = notes:gsub(esc_lite(data),new_data)


  
elseif notes=='' then notes = notes..a..'vsolo'..vsolo..' '..solo_str..'\r\nend||\r\n'


else notes = notes..'\r\n'..a..'vsolo'..vsolo..' '..solo_str..'\r\nend||\r\n' end


reaper.Undo_BeginBlock()
reaper.SetProjExtState( 0, 'MyDaw', 'Vsolo', notes ) 
reaper.TrackList_AdjustWindows(0)
reaper.Undo_EndBlock('Save noslsolo tracks', 2)


end










-----------------------hide Function




function hidetracksfromnotes()

--------------record to notes-------


function hiderecordnotes()


local function esc_lite(str) str = str:gsub('%-', '%%-') return str end

local function nothing() end; local function noaction() reaper.defer(nothing) end


local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')

local a = '||showhidetracks\r\n'


local data = notes:match(a..'(.-\r\n)end||')


local new_data
local vsolo_data = data:match('vsolo'..'%d'..' (.-)\r\n')

local vsolo_mode = data:match('vsolo'..'..')


local mode = 1

new_data = data:gsub('vsolo'..'%d'..' '..esc_lite(vsolo_data),'vsolo'..mode..' '..vsolo_data,1)
 
notes = notes:gsub(esc_lite(data),new_data)

reaper.SetProjExtState( 0, 'MyDaw', 'Vsolo', notes ) 
reaper.TrackList_AdjustWindows(0)

end


------------------------record to notes end-----------





local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')
local data = notes:match'||showhidetracks\r\n(.-\r\n)end||'
if not data then noaction() return end
local sel_tracks_str = data:match('vsolo'..'%d'..' (.-)\r\n')
if not sel_tracks_str then noaction() return end

local t = {}

for guid in sel_tracks_str:gmatch'{.-}' do
  local tr = GuidToTrack(guid)
  if tr then t[#t+1] = tr end
end

if #t == 0 then noaction() return end


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

local hidetrack = reaper.GetTrack(0, 0)



for i = 1, #t do 

reaper.SetMediaTrackInfo_Value(t[i], 'B_SHOWINMIXER',0)
reaper.SetMediaTrackInfo_Value(t[i], 'B_SHOWINTCP',0)

reaper.TrackList_AdjustWindows(0)

end

hiderecordnotes()

reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('Hide No Solo', -1)

end








--------------------------end of hide










local retval, notes = reaper.GetProjExtState( 0, 'MyDaw', 'Vsolo')

local a = '||showhidetracks\r\n'

local data = notes:match(a..'(.-\r\n)end||')

if not data then saveoraddtracks()
hidetracksfromnotes()
toggleState = 1
return

end



local vsolo_data = data:match('vsolo'..'%d'..' (.-)\r\n')
local vsolo_mode = data:match('vsolo'..'..')


if data and vsolo_mode == 'vsolo0 ' then saveoraddtracks()  hidetracksfromnotes()

toggleState = 1


 

elseif data and vsolo_mode == 'vsolo1 ' then showtracksfromnotes()

toggleState = 0

end


is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
reaper.SetToggleCommandState(sec, cmd, toggleState);  
reaper.RefreshToolbar2(sec, cmd);



end 

reaper.defer(NoUndoPoint)


