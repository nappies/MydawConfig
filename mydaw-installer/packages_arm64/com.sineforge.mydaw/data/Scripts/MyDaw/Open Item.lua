function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
 end
 
package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("SetMidiEditorGrid")  
 
 
 function Post_LMouseDownUp(hwnd, x, y) -- x,y = location to click inside the window
   reaper.JS_WindowMessage_Post(hwnd, "WM_LBUTTONDOWN", 1, 0, x, y)
   reaper.JS_WindowMessage_Post(hwnd, "WM_LBUTTONUP", 0, 0, x, y)
 end
 
 
function ResizeDock(hwnd, height)
local function JS_LMouseDownUp(hWnd) 
  reaper.JS_WindowMessage_Post(hWnd, "WM_LBUTTONDOWN", 0, 0, 0, 0)
  reaper.JS_WindowMessage_Post(hWnd, "WM_LBUTTONUP", 0, 0, 0, 0)
end
local _, left, top, right, bottom = reaper.JS_Window_GetClientRect(hwnd)
local  w = (right-left)
reaper.JS_Window_SetPosition(hwnd, left, top, w, height)
JS_LMouseDownUp(hwnd)
end 
 
 
 
function ResizeMidiToolbar()
local function Delay()
 midiview = reaper.JS_Window_FindChildByID( reaper.MIDIEditor_GetActive(), 1001) 
 midi_filter = reaper.JS_Window_FindChildByID( reaper.MIDIEditor_GetActive(), 1293)  
 midi_toolbar = reaper.JS_Window_GetRelated(midi_filter, "NEXT")
 if not  midi_toolbar then reaper.defer(Delay) else
 reaper.MIDIEditor_LastFocused_OnCommand(reaper.NamedCommandLookup("_S&M_HIDECCLANES_ME"), false) 
 retval, twidth, theight = reaper.JS_Window_GetClientSize( midi_toolbar)  
reaper.JS_Window_Resize( midi_toolbar, twidth, 30 )
Post_LMouseDownUp( reaper.JS_Window_GetParent(midiview), 1, 34)
SetMidiGrid(Take_ID) 
end
end
Delay()
end
 

function OpenMidi()
local x, y = reaper.GetMousePosition()
Item_ID, Take_ID = reaper.GetItemFromPoint(x, y, true )
reaper.Main_OnCommand(40153 , 0) ---open in midi
ResizeMidiToolbar()

local function Delay()  ----------------------------------

local hwnd  = reaper.JS_Window_GetParent(reaper.MIDIEditor_GetActive())
if not  hwnd then  reaper.defer(Delay) else
local isdock,_ = reaper.DockIsChildOfDock(reaper.MIDIEditor_GetActive())
if isdock ~= -1 then ResizeDock(hwnd,600)end
end
end--------------------------------------------------------
Delay()

end
 
function OpenAudio()
reaper.Main_OnCommandEx(40009,0, 0)
local function Delay()  ----------------------------------
local MediaItemProperties =reaper.JS_Window_Find( "Media Item Properties", false )
local take_button = reaper.JS_Window_FindChildByID( MediaItemProperties, 1105)
local hwnd  = reaper.JS_Window_GetParent(MediaItemProperties)
if not (take_button and  hwnd) then  reaper.defer(Delay) else
local isdock,_ = reaper.DockIsChildOfDock(MediaItemProperties)
if isdock ~= -1 then ResizeDock(hwnd,217)end
end
end--------------------------------------------------------
Delay()

end

function OpenVideo()
reaper.Main_OnCommandEx(50125,0, 0)
end 
 
function OpenRPP()
reaper.Main_OnCommandEx(41816,0, 0)
end 
 
function OpenNotes()
reaper.Main_OnCommandEx(40850,0, 0)
end  

function OpenItemSourceProp()
reaper.Main_OnCommandEx(40011,0, 0)
end  
 
 

 
---------------------------------
---------------------------------
-- SourceType   =    Action ID -- 
---------------------------------
  -- Midi Source ---------
  MIDI          =    OpenMidi
  -- Audio Source --------
  WAVE          =    OpenAudio
  REX           =    OpenAudio
  FLAC          =    OpenAudio
  MP3           =    OpenAudio
  VORBIS        =    OpenAudio
  OPUS          =    OpenAudio
  -- Video Source --------
  VIDEO         =    OpenVideo  
  -- Special Source ------
  RPP_PROJECT   =    OpenRPP
  EMPTY         =    OpenNotes
  CLICK         =    OpenItemSourceProp
  LTC           =    OpenItemSourceProp

---------------------------------------------------------------------
---------------------------------------------------------------------
function Get_Source_Type(Item_ID)
    if Item_ID then
      Take_ID = reaper.GetActiveTake(Item_ID)-- Get Active Take(from Item)
      if Take_ID then
         PCM_source = reaper.GetMediaItemTake_Source(Take_ID)
         S_Type = reaper.GetMediaSourceType(PCM_source,"")
         if S_Type == "SECTION" then
            PCM_source = reaper.GetMediaSourceParent(PCM_source)
            S_Type = reaper.GetMediaSourceType(PCM_source,"")
         end
      else S_Type = "EMPTY" 
      end
    end    
  return S_Type
end

----------------------
function Set_ID(S_Type)
    -- Midi Source --------- 
    if     S_Type == "MIDI"          then ID = MIDI
    -- Audio Source -------- 
    elseif S_Type == "WAVE"          then ID = WAVE
    elseif S_Type == "REX"           then ID = REX
    elseif S_Type == "FLAC"          then ID = FLAC
    elseif S_Type == "MP3"           then ID = MP3
    elseif S_Type == "VORBIS"        then ID = VORBIS
    elseif S_Type == "OPUS"          then ID = OPUS
    -- Video Source -------- 
    elseif S_Type == "VIDEO"         then ID = VIDEO
    -- Special Source ------
    elseif S_Type == "RPP_PROJECT"   then ID = RPP_PROJECT
    elseif S_Type == "EMPTY"         then ID = EMPTY
    elseif S_Type == "CLICK"         then ID = CLICK
    elseif S_Type == "LTC"           then ID = LTC
    end
    
    -- if non-native Action ID --
    if ID and type(ID) == "string" then 
      ID = reaper.NamedCommandLookup(ID)
    end
    -- if Action no assigned ----
    if not S_Type or not ID or ID == 0 then 
      return
    end 
  
  return ID
end



----------------------------------------
----------------------------------------
local x, y = reaper.GetMousePosition()
Item_ID, Take_ID = reaper.GetItemFromPoint(x, y, true )

if Item_ID then
Get_Source_Type(Item_ID)
Set_ID(S_Type)
reaper.Main_OnCommand(40289, 0) ---Item: Unselect all items
reaper.Main_OnCommand(40331, 0)---Envelope: Unselect all points
reaper.Main_OnCommand(40635 , 0) ----remove time selection
reaper.Main_OnCommand(40528 , 0)---- Item: Select item under mouse cursor
reaper.defer(ID)
end
