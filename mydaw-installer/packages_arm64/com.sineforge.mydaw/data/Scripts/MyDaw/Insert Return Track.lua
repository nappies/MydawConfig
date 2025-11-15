

function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
 end


        reaper.Undo_BeginBlock();
        reaper.PreventUIRefresh(1);
  lasbus=0
  for i = 0, reaper.CountTracks(0) do;
                 local Track = reaper.GetTrack(0,i);
				 
            if Track then 
					local retval, number = reaper.GetSetMediaTrackInfo_String(Track, "P_EXT:ISND", "", false )
					if retval then;
					bus = reaper.GetMediaTrackInfo_Value( Track, "IP_TRACKNUMBER")
					lasbus = math.max(bus, lasbus)
		
			
				end
			end	
  
  end
  
		-----
        reaper.InsertTrackAtIndex(lasbus,false);
        local TrackFirst = reaper.GetTrack(0,lasbus);
        local order = reaper.GetMediaTrackInfo_Value( TrackFirst, "IP_TRACKNUMBER")
		reaper.GetSetMediaTrackInfo_String(TrackFirst, "P_EXT:ISND", order, true)
       
        ----- / Heigth Track / -----
    
        reaper.SetMediaTrackInfo_Value(TrackFirst,"I_HEIGHTOVERRIDE",24);
      

        reaper.GetSetMediaTrackInfo_String(TrackFirst,"P_TCP_LAYOUT","Return",1);
        reaper.GetSetMediaTrackInfo_String(TrackFirst,"P_MCP_LAYOUT","Return",1);
        ----- / Name Track / -----
        reaper.GetSetMediaTrackInfo_String(TrackFirst,"P_NAME",tostring("Return".." "..math.ceil(order)),1);
        ----- / Color / -----
        gray=127
        color =  reaper.ColorToNative( gray, gray, gray )
        reaper.SetTrackColor( TrackFirst, color)

       


        --------------------------------
        reaper.PreventUIRefresh(-1);
        reaper.Undo_EndBlock("Insert Return",-1);
        ----------------------------------------------------------------------


  
  
  
  
