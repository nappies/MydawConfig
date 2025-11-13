function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
  end


package.path    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;"      -- GET DIRECTORY FOR REQUIRE
require("Functions")


Straight = { 
              {name = "gridvis1_1024",
                beginning = 2000000,
                ending = 9170,
                divider=1024, 
               },
              {name = "gridvis1_512",
                beginning = 9170,
                ending = 8371,
                divider=512,  
               },               
              {name = "gridvis1_256",
                beginning = 8371,
                ending = 2306,
                divider=256,  
               },
              {name = "gridvis1_128",
                beginning = 2306,
                ending = 1042,
                divider=128,  
               },
              {name = "gridvis1_64",
                beginning = 1042,
                ending = 529,
                divider=64,  
               },
              {name = "gridvis1_32",
                beginning = 529 ,
                ending = 218,
                divider=32,  
               },
              {name = "gridvis1_16",
                beginning = 218,
                ending = 136,
                divider=16,  
               },
              {name = "gridvis1_8",
                beginning = 136,
                ending = 64,
                divider=8,  
               },
              {name = "gridvis1_4",
                beginning = 64,
                ending = 32,
                divider=4,  
               },
              {name = "gridvis1_2",
                beginning = 32,
                ending = 16,
                divider=2,  
               },
               
              {name = "gridvis1_1",
                beginning = 16,
                ending = 8,
                divider=1,  
               },
              {name = "gridvis2_1",
                beginning = 8,
                ending = 4,
                divider=0.5,  
               },
              {name = "gridvis4_1",
                beginning = 4,
                ending = 2,
                divider=0.25,  
               },
              {name = "gridvis8_1",
                beginning = 2,
                ending = 0,
                divider=0.125,  
               },
}


function GetMidiGrid()
local ME = reaper.MIDIEditor_GetActive()
  if not ME then return end
  local take = reaper.MIDIEditor_GetTake(ME)
local  snap_enabled = reaper.MIDIEditor_GetSetting_int(ME, "snap_enabled")
local _, arrange_division, _, _ = reaper.GetSetProjectGrid(0, 0)
local SyncArrangeMidi = 41022
local SyncArrangeMidi_State = reaper.GetToggleCommandStateEx(32060,SyncArrangeMidi)
if (SyncArrangeMidi_State == 0) then reaper.MIDIEditor_OnCommand(ME, SyncArrangeMidi) end
local _, midi_division, _, _ = reaper.GetSetProjectGrid(0, 0)
reaper.MIDIEditor_OnCommand(ME, SyncArrangeMidi)
reaper.SetProjectGrid(0, arrange_division)
return midi_division
end


function writegrid()
  
  

local zoom =  tonumber(GetMidiZoom())



if zoom > 1 then
 for i = #Straight, 1, -1 do

local name = Straight[i].name
local beginning = Straight[i].beginning
local ending = Straight[i].ending
local divider = Straight[i].divider


if (zoom < beginning) and (zoom > ending) then  curdivider = divider   end
 end




gridset= GetMidiGrid()*curdivider


if sgrid ~= gridset then


tk = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
insert=tostring("MGrid="..gridset) 
_,_,_,_,_, msg_event = reaper.MIDI_GetTextSysexEvt( tk, 0, 0, 0, 0, 1, 0 )
if string.match(msg_event, "MGrid") then
reaper.MIDI_DeleteTextSysexEvt( tk, 0 )
end
reaper.MIDI_InsertTextSysexEvt( tk, true, 0, 0, 1, insert )
end
end
end


function GetMidiZoom()
    
    function esc(str) str = str:gsub('%-', '%%-') return str end
    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
	
	
	
    --local guid = reaper.BR_GetMediaItemTakeGUID(take)
	
	local guid = TakeToGuid(take)
    
	
	local item = reaper.GetMediaItemTake_Item(take)
    local retval, item_chunk = reaper.GetItemStateChunk( item, "", false )
	local view = item_chunk:match(esc(guid)..'.-CFGEDITVIEW(.-)\n')
    
    function mysplit(inputstr, sep)
      if sep == nil then
        sep = "%s"
      end
      local t={} ; i=1
      for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
      end
      return t
    end
    
    for is = 1, 2, 1 do   
          if is == 2 then
            result = mysplit(view, "%s")
            out  = result[is]
          end
          end
return out
    
   end


function SetMidiGrid(tk)

default_index = 1



local zoom =  tonumber(GetMidiZoom())

_,_,_,_,_, msg_event = reaper.MIDI_GetTextSysexEvt( tk, 0, 0, 0, 0, 1, 0 )



if string.match(msg_event, "MGrid") then

  
extracted = string.match(msg_event, "=(.*)")

reaper.SetExtState( "item", "temp", extracted, 0 )

default_index  = reaper.GetExtState( "item", "temp" )

reaper.DeleteExtState("item", "temp", 0 )

default_index = tonumber(default_index)

if default_index == nil then default_index = 1  end  



end



    for i = #Straight, 1, -1 do

local name = Straight[i].name
local beginning = Straight[i].beginning
local ending = Straight[i].ending
local divider = Straight[i].divider


if (zoom < beginning) and (zoom > ending) then curdivider = divider    end
 end

 if curdivider then 

reaper.SetMIDIEditorGrid( 0, (default_index/curdivider) )
end
return  default_index/curdivider 
end


function SetMidiGridDrag()

default_index = 1



local zoom =  tonumber(GetMidiZoom())

if zoom > 1 then

tk = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())

_,_,_,_,_, msg_event = reaper.MIDI_GetTextSysexEvt( tk, 0, 0, 0, 0, 1, 0 )


if string.match(msg_event, "MGrid") then


extracted = string.match(msg_event, "=(.*)")

reaper.SetExtState( "item", "temp", extracted, 0 )

default_index  = reaper.GetExtState( "item", "temp" )

reaper.DeleteExtState("item", "temp", 0 )

default_index = tonumber(default_index)

if default_index == nil then default_index = 1  end  

end




    for i = #Straight, 1, -1 do

local name = Straight[i].name
local beginning = Straight[i].beginning
local ending = Straight[i].ending
local divider = Straight[i].divider


if (zoom < beginning) and (zoom > ending) then curdivider = divider   end
 end
if curdivider then 
reaper.SetMIDIEditorGrid( 0, (default_index/curdivider) )
end
end
return 
end



