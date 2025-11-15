local first_value = nil
  
  local env = reaper.GetSelectedEnvelope(0)
  if not env then return end
  local pts = reaper.CountEnvelopePoints(env)
  
  
  for i = 0, pts-1 do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, i)
        if selected then
          first_value = value
          break
        end
      end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

    local changed = false
    for i = 0, pts-1 do
      local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, i)
      if selected and value ~= first_value then
        -- keep time, shape, tension and selected state; change only value
        reaper.SetEnvelopePoint(env, i, time, first_value, shape, tension, selected, true)
        changed = true
      end
    end
    if changed then reaper.Envelope_SortPoints(env) end
    
 reaper.PreventUIRefresh(-1)
 reaper.Undo_EndBlock("Set selected envelope points to first selected value", -1)   
