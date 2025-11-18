package.path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require("Functions")


function PasteTakeEnvelope()


part = reaper.GetExtState("MyDaw_copy-paste", "take_envelopes")
if not (part and part ~= '')then return end

reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(111)
items = reaper.CountSelectedMediaItems(0)
for i = 0, items-1 do
item = reaper.GetSelectedMediaItem(0,i)
_, chunk = reaper.GetItemStateChunk(item, '', 0)
take = reaper.GetActiveTake(item)

take_guid = TakeToGuid(take)

if chunk:match(esc(take_guid)..'\n<SOURCE.->\n<TAKEFX\n') then
  before, after = chunk:match('(.*'..esc(take_guid)..'\n<SOURCE.->\n<TAKEFX.-\nWAK %d\n>)(.*)')
else before, after = chunk:match('(.*'..esc(take_guid)..'\n<SOURCE.->\n)(.*)') end
tb = {}
for env_part in after:gmatch('<.-ENV\n.->') do
  if not env_part:match('<(.-)ENV\n.->'):match('\n') then tb[#tb+1] = env_part end
end
after_new = after
for k = 1, #tb do after_new = after_new:gsub(esc(tb[k]), '', 1) end
after_new = after_new:gsub('\n+', '\n')

new_chunk = before..'\n'..part..after_new
reaper.SetItemStateChunk(item, new_chunk, 1)
end
reaper.PreventUIRefresh(-111); reaper.UpdateArrange()
reaper.Undo_EndBlock("Paste copied envelopes to active takes of sel items", -1)

end





reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)


part = reaper.GetExtState("MyDaw_copy-paste", "take_envelopes")


if (part and part ~= '') then  PasteTakeEnvelope()


else

reaper.Main_OnCommand(42398, 0)  ---paste


end 



reaper.PreventUIRefresh(-1); reaper.Undo_EndBlock('Paste', -1)  

