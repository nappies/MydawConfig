package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")

 wait  = 0.3

function GetTail(revtail)
    tail = 0
    if revtail <= 0.3 then
        tail = 0.3
    elseif revtail <= 0.5 then
        tail = 0.6
    elseif revtail > 0.5 and revtail <= 0.8 then
        tail = 0.65
    elseif revtail >= 0.8 and revtail < 1.1 then
        tail = 0.75
    elseif revtail >= 1.1 and revtail < 2 then
        tail = 0.80
    elseif revtail >= 2 and revtail < 2.5 then
        tail = 0.85
    elseif revtail >= 2.5 and revtail < 3 then
        tail = 0.90
    elseif revtail >= 3 and revtail < 4 then
        tail = 0.94
    elseif revtail >= 4 and revtail < 5 then
        tail = 0.95
    elseif revtail >= 5 and revtail < 6 then
        tail = 0.97
    elseif revtail >= 6 and revtail < 8 then
        tail = 0.98
    elseif revtail >= 8 and revtail < 10 or revtail > 10 then
        tail = 1
    end
    return tail
end

function AddReverb(SwellTr, tail)
    SwellReverb = reaper.TrackFX_AddByName(SwellTr, "ReaVerbate", 0, 1)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 0, 0.3)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 1, 0)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 2, tail)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 3, 0.6)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 4, 1)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 5, 0)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 6, 1)
    reaper.TrackFX_SetParamNormalized(SwellTr, SwellReverb, 7, 0.005)
end

startOut, endOut = GetRazorStartEnd()
itstart, itend = GetItemsStartEnd()

function swell()
  reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    if itstart > 0 then
        mono_stereo = 2
        tr_rnd = MixdownToTrack(mono_stereo)

        reaper.Main_OnCommand(42406, 0) ----Remove Razor edit
        UnselectAllItems()

        ritem = reaper.GetTrackMediaItem(tr_rnd, 0)

      function waititem()
           ritem = reaper.GetTrackMediaItem(tr_rnd, 0)
            if not ritem then
                reaper.defer(waititem)  m("I am wait".." "..ritem)
                else
            --    m("Go".." "..ritem)
            end
        end
        waititem()



        reaper.SetMediaItemSelected(ritem, true)
        
  
        reaper.Main_OnCommand(41051, 0) --Item properties: Toggle take reverse
        
        
        t0 = os.clock()
       


        counttakes = reaper.CountTakes(ritem)

        tail = GetTail(itstart - startOut)

        reaper.SetOnlyTrackSelected(tr_rnd)
       
        AddReverb(tr_rnd, tail)
 
        close_tr_fx(tr_rnd)
      
      reaper.SetMediaItemSelected(ritem, true)


 function waitapply()
             t = os.clock()
             if t - t0 < wait  or  reaper.TrackFX_GetCount(tr_rnd) == 0 or reaper.CountSelectedMediaItems(0) == 0 then
                reaper.defer(waitapply)
             --   m("fx"..reaper.TrackFX_GetCount(tr_rnd)) 
             --   m("items".. reaper.CountSelectedMediaItems(0))
             --   m("time".." "..t.." "..t0 )
                else
                t0 = os.clock()
            --    m("yes"..reaper.TrackFX_GetCount(tr_rnd))
           --     m("ahah"..reaper.CountSelectedMediaItems(0))
               --Item: Apply track/take FX to items 
               reaper.Main_OnCommand(40209, 0)
            end
        end
 waitapply()



        

        function waitrender()
        
        tk = reaper.GetActiveTake(ritem)
          t = os.clock()
           if t - t0 < wait or  reaper.GetMediaItemTakeInfo_Value( tk, "IP_TAKENUMBER" )~= 1 then
            --    m("aha"..reaper.GetMediaItemTakeInfo_Value( tk, "IP_TAKENUMBER" ))
                reaper.defer(waitrender)
                else
                t0 = os.clock()
                reaper.Main_OnCommand(40131, 0) --Take: Crop to active take in items
          --      m("oh noo"..reaper.GetMediaItemTakeInfo_Value( tk, "IP_TAKENUMBER" ))
            end
        end
       waitrender()
       
        
     
     
     function waitreverse()
            
            tk = reaper.GetActiveTake(ritem)
              t = os.clock()
               if t - t0 < wait then
                --    m("aha"..reaper.GetMediaItemTakeInfo_Value( tk, "IP_TAKENUMBER" ))
                    reaper.defer(waitreverse)
                    else
                   reaper.Main_OnCommand(41051, 0) --Item properties: Toggle take reverse
                    reaper.TrackFX_Delete(tr_rnd, 0)
                end
            end
           waitreverse()
     
     
     
     

       

           reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Reverb Swell", -1)
    end
end


selected_items_count = reaper.CountSelectedMediaItems(0)

if endOut > 0 and selected_items_count > 0 then
    swell()
end

