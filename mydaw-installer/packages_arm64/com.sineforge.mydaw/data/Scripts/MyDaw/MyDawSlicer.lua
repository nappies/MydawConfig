reaper.set_action_options(1)

--_MwAs
--[[
Author of the compilation - MyDaw

https://www.facebook.com/MydawEdition/

Based on "Drums to MIDI(beta version)" script by EUGEN27771   
Author URI: http://forum.cockos.com/member.php?u=50462  

Export to ReaSamplOmatic5000 function from RS5k manager by MPL 
@website https://forum.cockos.com/showthread.php?t=207971  
]]
reaper.Main_OnCommand(40528, 0)

local function escape_lua_pattern(s)
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
  return (s:gsub(".", matches))
end



   function GuidToItem(guid)
                if guid then
                    for i = 0, reaper.CountMediaItems(0) - 1 do
                        it = reaper.GetMediaItem(0, i)
                        local retval, item_guid = reaper.GetSetMediaItemInfo_String(it, "GUID", "", false)
                        if string.match(guid, escape_lua_pattern(reaper.guidToString(item_guid, ""))) then
                            return it
                        end
                    end
                end
                return nil
            end



function getsomerms()
    local itemproc = reaper.GetSelectedMediaItem(0, 0)

    if itemproc then
        guiditemString = 0

        local retval, guiditemString = reaper.GetSetMediaItemInfo_String(itemproc, "GUID", "", false)

        local tk = reaper.GetActiveTake(itemproc)
        if tk then
            fxId_EQ = reaper.TakeFX_AddByName(tk, "ReaEQ", 1)
            reaper.TakeFX_SetParamNormalized(tk, fxId_EQ, 0, 0.4) -- ls FRQ
            reaper.TakeFX_SetParamNormalized(tk, fxId_EQ, 9, 0.9) -- hs gain
            reaper.TakeFX_SetParamNormalized(tk, fxId_EQ, 10, 0) -- hs gain
            reaper.Main_OnCommand(40209, 0) ---- apply to take fx

            tk = reaper.GetActiveTake(itemproc)

         

            function ExpandItems(amount)
                -- Ensure the input is a number to prevent errors.
                if type(amount) ~= "number" then
                    reaper.ShowConsoleMsg("Error: FNG_ExpandItems requires a numerical amount.\n")
                    return
                end

                local sel_item_count = reaper.CountSelectedMediaItems(0)

                -- The logic requires at least two items to define spacing.
                -- The C++ version also checks for (size <= 1).
                if sel_item_count <= 1 then
                    return
                end

                reaper.Undo_BeginBlock()
                reaper.PreventUIRefresh(1) -- Prevent UI flicker and improve performance with many items.

                -- Get the first selected item to use as the anchor point.
                -- In ReaScript, GetSelectedMediaItem(0, 0) reliably gets the first in the selection order.
                local first_item = reaper.GetSelectedMediaItem(0, 0)
                local start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")

                -- Loop through all selected items (including the first, though its position won't change).
                for i = 0, sel_item_count - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    local current_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

                    -- This is the core logic translated directly from the C++:
                    -- new_position = current_position + (distance_from_start * amount)
                    local new_pos = current_pos + (current_pos - start_pos) * amount

                    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
                end

                reaper.PreventUIRefresh(-1)
                reaper.UpdateArrange() -- Ensure the arrangement view is redrawn.

                -- The undo point name is made dynamic based on the action.
                local undo_str = amount > 0 and "Expand Selected Items" or "Contract Selected Items"
                reaper.Undo_EndBlock(undo_str, -1)
            end

            function get_average_rms(take, adj_for_take_vol, adj_for_item_vol, adj_for_take_pan, val_is_dB)
                local RMS_t = {}
                if take == nil then
                    return
                end

                local item = reaper.GetMediaItemTake_Item(take) -- Get parent item

                if item == nil then
                    return
                end

                local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local item_end = item_pos + item_len
                local item_loop_source = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") == 1.0 -- is "Loop source" ticked?

                -- Get media source of media item take
                local take_pcm_source = reaper.GetMediaItemTake_Source(take)
                if take_pcm_source == nil then
                    return
                end

                -- Create take audio accessor
                local aa = reaper.CreateTakeAudioAccessor(take)
                if aa == nil then
                    return
                end

                -- Get the length of the source media. If the media source is beat-based,
                -- the length will be in quarter notes, otherwise it will be in seconds.
                local take_source_len, length_is_QN = reaper.GetMediaSourceLength(take_pcm_source)
                if length_is_QN then
                    return
                end

                local take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

                -- (I'm not sure how this should be handled)

                -- Item source is looped --
                -- Get the start time of the audio that can be returned from this accessor
                local aa_start = reaper.GetAudioAccessorStartTime(aa)
                -- Get the end time of the audio that can be returned from this accessor
                local aa_end = reaper.GetAudioAccessorEndTime(aa)

                -- Item source is not looped --
                if not item_loop_source then
                    if take_start_offset <= 0 then -- item start position <= source start position
                        aa_start = -take_start_offset
                        aa_end = aa_start + take_source_len
                    elseif take_start_offset > 0 then -- item start position > source start position
                        aa_start = 0
                        aa_end = aa_start + take_source_len - take_start_offset
                    end
                    if aa_start + take_source_len > item_len then
                        --msg(aa_start + take_source_len > item_len)
                        aa_end = item_len
                    end
                end
                --aa_len = aa_end-aa_start

                -- Get the number of channels in the source media.
                local take_source_num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)

                local channel_data = {} -- channel data is collected to this table
                -- Initialize channel_data table
                for i = 1, take_source_num_channels do
                    channel_data[i] = {
                        rms = 0,
                        sum_squares = 0 -- (for calculating RMS per channel)
                    }
                end

                -- Get the sample rate. MIDI source media will return zero.
                local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
                if take_source_sample_rate == 0 then
                    return
                end

                -- How many samples are taken from audio accessor and put in the buffer
                local samples_per_channel = take_source_sample_rate / 10

                -- Samples are collected to this buffer
                local buffer = reaper.new_array(samples_per_channel * take_source_num_channels)

                --local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

                -- total_samples = math.ceil((aa_end - aa_start) * take_source_sample_rate)
                local total_samples = math.floor((aa_end - aa_start) * take_source_sample_rate + 0.5)
                --total_samples = (aa_end - aa_start) * take_source_sample_rate

                -- take source is not within item -> return
                if total_samples < 1 then
                    return
                end

                local block = 0
                local sample_count = 0
                local audio_end_reached = false
                local offs = aa_start

                local log10 = function(x)
                    return math.log(x, 10)
                end
                local abs = math.abs
                --local floor = math.floor

                -- Loop through samples
                while sample_count < total_samples do
                    if audio_end_reached then
                        break
                    end

                    -- Get a block of samples from the audio accessor.
                    -- Samples are extracted immediately pre-FX,
                    -- and returned interleaved (first sample of first channel,
                    -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
                    local aa_ret =
                        reaper.GetAudioAccessorSamples(
                        aa, -- AudioAccessor accessor
                        take_source_sample_rate, -- integer samplerate
                        take_source_num_channels, -- integer numchannels
                        offs, -- number starttime_sec
                        samples_per_channel, -- integer numsamplesperchannel
                        buffer -- reaper.array samplebuffer
                    )

                    if aa_ret == 1 then
                        for i = 1, #buffer, take_source_num_channels do
                            if sample_count == total_samples then
                                audio_end_reached = true
                                break
                            end
                            for j = 1, take_source_num_channels do
                                local buf_pos = i + j - 1
                                local spl = buffer[buf_pos]
                                channel_data[j].sum_squares = channel_data[j].sum_squares + spl * spl
                            end
                            sample_count = sample_count + 1
                        end
                    elseif aa_ret == 0 then -- no audio in current buffer
                        sample_count = sample_count + samples_per_channel
                    else
                        return
                    end

                    block = block + 1
                    offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
                end -- end of while loop

                reaper.DestroyAudioAccessor(aa)

                -- Calculate corrections for take/item volume
                local adjust_vol = 1

                if adj_for_take_vol then
                    adjust_vol = adjust_vol * reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
                end

                if adj_for_item_vol then
                    adjust_vol = adjust_vol * reaper.GetMediaItemInfo_Value(item, "D_VOL")
                end

                local adjust_pan = 1

                -- Calculate RMS for each channel
                for i = 1, take_source_num_channels do
                    -- Adjust for take pan
                    if adj_for_take_pan then
                        local take_pan = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
                        if take_pan > 0 and i % 2 == 1 then
                            adjust_pan = adjust_pan * (1 - take_pan)
                        elseif take_pan < 0 and i % 2 == 0 then
                            adjust_pan = adjust_pan * (1 + take_pan)
                        end
                    end

                    local curr_ch = channel_data[i]
                    curr_ch.rms = math.sqrt(curr_ch.sum_squares / total_samples) * adjust_vol * adjust_pan
                    adjust_pan = 1
                    RMS_t[i] = curr_ch.rms
                    if val_is_dB then -- if function param "val_is_dB" is true -> convert values to dB
                        RMS_t[i] = 20 * log10(RMS_t[i])
                    end
                end

                return RMS_t
            end

            getrms = get_average_rms(tk, 0, 0, 0, 0)

            ---------------------------------------Delete_TEMP----------------------------------
            src = reaper.GetMediaItemTake_Source(tk)
            in_path = reaper.GetMediaSourceFileName(src, "")

            reaper.Main_OnCommand(40129, 0) ---delete active take

            os.remove(in_path)

            sourceitem = GuidToItem(guiditemString)

            reaper.Main_OnCommand(40029, 0) ---undo
            reaper.Main_OnCommand(40029, 0) ---undo
            reaper.Main_OnCommand(40029, 0) ---undo

            reaper.SelectAllMediaItems(0, false)

            reaper.SetMediaItemSelected(sourceitem, true)
            reaper.UpdateItemInProject(sourceitem)
        end

        -------------------------------------------------------------------

        for i = 1, #getrms do
            rms = (getrms[i])
        end

        rmsresult = string.sub(rms, 1, string.find(rms, ".") + 5)

        foroutgain = rmsresult

        rmsoffset = (rmsresult + 3)

        boost = rmsoffset - 6

        readrmspro = (boost * -0.017543)

        readrms = (1 - readrmspro)

        out_gain_boost = (foroutgain + 6)

        out_gain = (out_gain_boost * 0.04166) * -1

        if (out_gain >= 1) then
            out_gain = 1
        end
    else
    end
end

readrms = 0.3501

out_gain = 0.625

--getsomerms()----disable

function ClearExState()
    reaper.DeleteExtState("MyDaw", "ItemToSlice", 0)
    reaper.DeleteExtState("MyDaw", "TrackForSlice", 0)
    reaper.SetExtState("MyDaw", "GetItemState", "ItemNotLoaded", 0)
end

ClearExState()

getitem = 1

MinimumItem = 0.3

exept = 1


function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end


function GetTempo()
    retrigms = 0.0555

    tempo = reaper.Master_GetTempo()

    Quarter = (60000 / tempo)

    Sixty_Fourth = (Quarter / 16)

    retoffset = (Sixty_Fourth - 20)

    retrigms = (retoffset * 0.0055)
end

GetTempo()

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x, y, w, h, r, g, b, a, lbl, fnt, fnt_sz, norm_val, norm_val2, fnt_rgba)
    local elm = {}
    elm.def_xywh = {x, y, w, h, fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz = lbl, fnt, fnt_sz
    elm.fnt_rgba = fnt_rgba or {0.1, 0.1, 0.1, 1} --0.7, 0.8, 0.4, 1
    elm.norm_val = norm_val
    elm.norm_val2 = norm_val2
    ------
    setmetatable(elm, self)
    self.__index = self
    return elm
end
--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
    setmetatable(Child, {__index = Parent})
end

--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
    if not Z_w or not Z_h then
        return
    end -- return if zoom not defined
    self.x, self.w = math.ceil(self.def_xywh[1] * Z_w), math.ceil(self.def_xywh[3] * Z_w) -- upd x,w
    self.y, self.h = math.ceil(self.def_xywh[2] * Z_h), math.ceil(self.def_xywh[4] * Z_h) -- upd y,h
    if self.fnt_sz then --fix it!--
        self.fnt_sz = math.max(9, self.def_xywh[5] * (Z_w + Z_h) / 2)
        self.fnt_sz = math.min(22, self.fnt_sz)
    end
end
------------------------
function Element:pointIN(p_x, p_y)
    return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
    return gfx.mouse_cap & 1 == 0 and self:pointIN(gfx.mouse_x, gfx.mouse_y)
end
------------------------
function Element:mouseDown()
    return gfx.mouse_cap & 1 == 1 and self:pointIN(mouse_ox, mouse_oy)
end
--------
function Element:mouseUp() -- its actual for sliders and knobs only!
    return gfx.mouse_cap & 1 == 0 and self:pointIN(mouse_ox, mouse_oy)
end
--------
function Element:mouseClick()
    return gfx.mouse_cap & 1 == 0 and last_mouse_cap & 1 == 1 and self:pointIN(gfx.mouse_x, gfx.mouse_y) and
        self:pointIN(mouse_ox, mouse_oy)
end
------------------------
function Element:mouseR_Down()
    return gfx.mouse_cap & 2 == 2 and self:pointIN(mouse_ox, mouse_oy)
end
--------
function Element:mouseM_Down()
    return gfx.mouse_cap & 64 == 64 and self:pointIN(mouse_ox, mouse_oy)
end
------------------------
function Element:draw_frame()
    local x, y, w, h = self.x, self.y, self.w, self.h
    gfx.rect(x, y, w, h, false) -- frame1
    gfx.roundrect(x, y, w - 1, h - 1, 3, true) -- frame2
end

function Element:draw_rect()
    local x, y, w, h = self.x, self.y, self.w, self.h
    gfx.set(0, 0, 0, 1)
    gfx.rect(x, y, w, h, true) -- frame1
    gfx.roundrect(x, y, w - 1, h - 1, 3, true) -- frame2
end

----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local XButton, ZButton, Button, Slider, Rng_Slider, Knob, CheckBox, Frame = {}, {}, {}, {}, {}, {}, {}, {}
extended(Button, Element)
extended(Knob, Element)
extended(Slider, Element)
extended(ZButton, Element)
extended(XButton, Element)

-- Create Slider Child Classes --
local H_Slider, V_Slider = {}, {}
extended(H_Slider, Slider)
extended(V_Slider, Slider)
---------------------------------
extended(Rng_Slider, Element)
extended(Frame, Element)
extended(CheckBox, Element)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_body()
    gfx.rect(self.x, self.y, self.w, self.h, true) -- draw btn body
end
--------
function Button:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + (h - lbl_h) / 2
    gfx.drawstr(self.lbl)
end
------------------------
function Button:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element --------
    if self:mouseIN() then
        a = a + 0.5
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.7
    end
    -- in elm L_up(released and was previously pressed) --
    if self:mouseClick() and self.onClick then
        self.onClick()
    end
    -- Draw btn body, frame ----
    gfx.set(r, g, b, a) -- set body color
    self:draw_body() -- body
    self:draw_frame() -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl() -- draw lbl
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then
        return false
    end -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then
        self.norm_val = math.min(self.norm_val + Step, 1)
    end
    if gfx.mouse_wheel < 0 then
        self.norm_val = math.max(self.norm_val - Step, 0)
    end
    return true
end
--------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL, K = 0, 10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then
        VAL = self.norm_val + ((gfx.mouse_x - last_x) / (w * K))
    else
        VAL = (gfx.mouse_x - x) / w
    end
    if VAL < 0 then
        VAL = 0
    elseif VAL > 1 then
        VAL = 1
    end
    self.norm_val = VAL
end
function V_Slider:set_norm_val()
    local y, h = self.y, self.h
    local VAL, K = 0, 10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then
        VAL = self.norm_val + ((last_y - gfx.mouse_y) / (h * K))
    else
        VAL = (h - (gfx.mouse_y - y)) / h
    end
    if VAL < 0 then
        VAL = 0
    elseif VAL > 1 then
        VAL = 1
    end
    self.norm_val = VAL
end
--------
function H_Slider:draw_body()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = w * self.norm_val
    gfx.rect(x, y, val, h, true) -- draw H_Slider body
end
function V_Slider:draw_body()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = h * self.norm_val
    gfx.rect(x, y + h - val, w, val, true) -- draw V_Slider body
end
--------
function H_Slider:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + 5
    gfx.y = y + (h - lbl_h) / 2
    gfx.drawstr(self.lbl) -- draw H_Slider label
end
function V_Slider:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + h - lbl_h - 5
    gfx.drawstr(self.lbl) -- draw V_Slider label
end
--------
function H_Slider:draw_val()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.y = y + (h - val_h) / 2
    gfx.drawstr(val) -- draw H_Slider Value
end
function V_Slider:draw_val()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + (w - val_w) / 2
    gfx.y = y + 5
    gfx.drawstr(val) -- draw V_Slider Value
end

------------------------
function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element(and get mouswheel) --
    if self:mouseIN() then
        a = a + 0.5
    --if self:set_norm_val_m_wheel() then
    --if self.onMove then self.onMove() end
    --end
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.6
        self:set_norm_val()
        if self.onMove then
            self.onMove()
        end
    end
    --in elm L_up(released and was previously pressed)--
    --if self:mouseClick() then --[[self.onClick()]] end
    -- L_up released(and was previously pressed in elm)--
    if self:mouseUp() and self.onUp then
        self.onUp()
        mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
    end
    -- Draw sldr body, frame ---
    gfx.set(r, g, b, a) -- set body,frame color
    self:draw_body() -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba)) -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Rng_Slider Class Methods   -----------------------------------------------
--------------------------------------------------------------------------------
function Rng_Slider:pointIN_Ls(p_x, p_y)
    local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
    local val = w * self.norm_val
    x = x + val - sb_w -- left sbtn x; x-10 extend mouse zone to the left(more comfortable)
    return p_x >= x - 10 and p_x <= x + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_Rs(p_x, p_y)
    local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
    local val = w * self.norm_val2
    x = x + val -- right sbtn x; x+10 extend mouse zone to the right(more comfortable)
    return p_x >= x and p_x <= x + 10 + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_rng(p_x, p_y)
    local x = self.rng_x + self.rng_w * self.norm_val -- start rng
    local x2 = self.rng_x + self.rng_w * self.norm_val2 -- end rng
    return p_x >= x + 5 and p_x <= x2 - 5 and p_y >= self.y and p_y <= self.y + self.h
end
------------------------
function Rng_Slider:mouseIN_Ls()
    return gfx.mouse_cap & 1 == 0 and self:pointIN_Ls(gfx.mouse_x, gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_Rs()
    return gfx.mouse_cap & 1 == 0 and self:pointIN_Rs(gfx.mouse_x, gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_rng()
    return gfx.mouse_cap & 1 == 0 and self:pointIN_rng(gfx.mouse_x, gfx.mouse_y)
end
------------------------
function Rng_Slider:mouseDown_Ls()
    return gfx.mouse_cap & 1 == 1 and last_mouse_cap & 1 == 0 and self:pointIN_Ls(mouse_ox, mouse_oy)
end
--------
function Rng_Slider:mouseDown_Rs()
    return gfx.mouse_cap & 1 == 1 and last_mouse_cap & 1 == 0 and self:pointIN_Rs(mouse_ox, mouse_oy)
end
--------
function Rng_Slider:mouseDown_rng()
    return gfx.mouse_cap & 1 == 1 and last_mouse_cap & 1 == 0 and self:pointIN_rng(mouse_ox, mouse_oy)
end
--------------------------------
function Rng_Slider:set_norm_val()
    local x, w = self.rng_x, self.rng_w
    local VAL, K = 0, 10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then
        VAL = self.norm_val + ((gfx.mouse_x - last_x) / (w * K))
    else
        VAL = (gfx.mouse_x - x) / w
    end
    -- valid val --
    if VAL < 0 then
        VAL = 0
    elseif VAL > self.norm_val2 then
        VAL = self.norm_val2
    end
    self.norm_val = VAL
end
--------
function Rng_Slider:set_norm_val2()
    local x, w = self.rng_x, self.rng_w
    local VAL, K = 0, 10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then
        VAL = self.norm_val2 + ((gfx.mouse_x - last_x) / (w * K))
    else
        VAL = (gfx.mouse_x - x) / w
    end
    -- valid val2 --
    if VAL < self.norm_val then
        VAL = self.norm_val
    elseif VAL > 1 then
        VAL = 1
    end
    self.norm_val2 = VAL
end
--------
function Rng_Slider:set_norm_val_both()
    local x, w = self.x, self.w
    local diff = self.norm_val2 - self.norm_val -- values difference
    local K = 1 -- K = coefficient
    if Ctrl then
        K = 10
    end -- when Ctrl pressed
    local VAL = self.norm_val + (gfx.mouse_x - last_x) / (w * K)
    -- valid values --
    if VAL < 0 then
        VAL = 0
    elseif VAL > 1 - diff then
        VAL = 1 - diff
    end
    self.norm_val = VAL
    self.norm_val2 = VAL + diff
end
--------------------------------
function Rng_Slider:draw_body()
    local x, y, w, h = self.rng_x, self.y, self.rng_w, self.h
    local sb_w = self.sb_w
    local val = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.rect(x + val - sb_w, y, val2 - val + sb_w * 2, h, true) -- draw body
end
--------
function Rng_Slider:draw_sbtns()
    local r, g, b, a = self.r, self.g, self.b, self.a
    local x, y, w, h = self.rng_x, self.y, self.rng_w, self.h
    local sb_w = self.sb_w
    local val = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.set(r, g, b, 0.06) -- sbtns body color
    gfx.rect(x + val - sb_w, y, sb_w + 1, h, true) -- sbtn1 body
    gfx.rect(x + val2 - 1, y, sb_w + 1, h, true) -- sbtn2 body
end
--------------------------------
function Rng_Slider:draw_val() -- variant 2
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.2f", self.norm_val)
    local val2 = string.format("%.2f", self.norm_val2)
    local val_w, val_h = gfx.measurestr(val)
    local val2_w, val2_h = gfx.measurestr(val2)
    local T = 0 -- set T = 0 or T = h (var1, var2 text position)
    gfx.x = x + 5
    gfx.y = y + (h - val_h) / 2 + T
    gfx.drawstr(val) -- draw value 1
    gfx.x = x + w - val2_w - 5
    gfx.y = y + (h - val2_h) / 2 + T
    gfx.drawstr(val2) -- draw value 2
end
--------
function Rng_Slider:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    local T = 0 -- set T = 0 or T = h (var1, var2 text position)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + (h - lbl_h) / 2 + T
    gfx.drawstr(self.lbl)
end
--------------------------------
function Rng_Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local x, y, w, h = self.x, self.y, self.w, self.h
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- set additional coordinates --
    self.sb_w = h - 5
    --self.sb_w  = math.floor(self.w/17) -- sidebuttons width(change it if need)
    --self.sb_w  = math.floor(self.w/40) -- sidebuttons width(change it if need)
    self.rng_x = self.x + self.sb_w -- range streak min x
    self.rng_w = self.w - self.sb_w * 2 -- range streak max w
    -- Get mouse state -------------
    -- Reset Ls,Rs states --
    if gfx.mouse_cap & 1 == 0 then
        self.Ls_state, self.Rs_state, self.rng_state = false, false, false
    end
    -- in element --
    if self:mouseIN_Ls() or self:mouseIN_Rs() then
        a = a + 0.1
    end
    -- in elm L_down --
    if self:mouseDown_Ls() then
        self.Ls_state = true
    end
    if self:mouseDown_Rs() then
        self.Rs_state = true
    end
    if self:mouseDown_rng() then
        self.rng_state = true
    end
    --------------
    if self.Ls_state == true then
        a = a + 0.2
        self:set_norm_val()
    end
    if self.Rs_state == true then
        a = a + 0.2
        self:set_norm_val2()
    end
    if self.rng_state == true then
        a = a + 0.2
        self:set_norm_val_both()
    end
    if (self.Ls_state or self.Rs_state or self.rng_state) and self.onMove then
        self.onMove()
    end
    -- in elm L_up(released and was previously pressed) --
    -- if self:mouseClick() and self.onClick then self.onClick() end
    if self:mouseUp() and self.onUp then
        self.onUp()
        mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
    end
    -- Draw sldr body, frame, sidebuttons --
    gfx.set(r, g, b, a) -- set color
    self:draw_body() -- body
    self:draw_frame() -- frame
    self:draw_sbtns() -- draw L,R sidebuttons
    -- Draw label,values --
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Knob Class Methods   -----------------------------------------------------
--------------------------------------------------------------------------------
function Knob:update_xywh() -- redefine method for Knob
    if not Z_w or not Z_h then
        return
    end -- return if zoom not defined
    local w_h = math.ceil(math.min(self.def_xywh[3] * Z_w, self.def_xywh[4] * Z_h))
    self.x = math.ceil(self.def_xywh[1] * Z_w)
    self.y = math.ceil(self.def_xywh[2] * Z_h)
    self.w, self.h = w_h, w_h
    if self.fnt_sz then --fix it!--
        self.fnt_sz = math.max(7, self.def_xywh[5] * (Z_w + Z_h) / 2)
         --fix it!
        self.fnt_sz = math.min(20, self.fnt_sz)
    end
end
--------
function Knob:set_norm_val()
    local y, h = self.y, self.h
    local VAL, K = 0, 10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then
        VAL = self.norm_val + ((last_y - gfx.mouse_y) / (h * K))
    else
        VAL = (h - (gfx.mouse_y - y)) / h
    end
    if VAL < 0 then
        VAL = 0
    elseif VAL > 1 then
        VAL = 1
    end
    self.norm_val = VAL
end
--------
function Knob:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then
        return
    end -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then
        self.norm_val = math.min(self.norm_val + Step, 1)
    end
    if gfx.mouse_wheel < 0 then
        self.norm_val = math.max(self.norm_val - Step, 0)
    end
    return true
end
--------
function Knob:draw_body()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local k_x, k_y, r = x + w / 2, y + h / 2, (w + h) / 4
    local pi = math.pi
    local offs = pi + pi / 4
    local val = 1.5 * pi * self.norm_val
    local ang1, ang2 = offs - 0.01, offs + val
    gfx.circle(k_x, k_y, r - 1, false) -- external
    for i = 1, 10 do
        gfx.arc(k_x, k_y, r - 2, ang1, ang2, true)
        r = r - 1 -- gfx.a=gfx.a+0.005 -- variant
    end
    gfx.circle(k_x, k_y, r - 1, true) -- internal
end
--------
function Knob:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + h / 2
    gfx.drawstr(self.lbl) -- draw knob label
end
--------
function Knob:draw_val()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + (w - val_w) / 2
    gfx.y = (y + h / 2) - val_h - 3
    gfx.drawstr(val) -- draw knob Value
end

------------------------
function Knob:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element(and get mouswheel) --
    if self:mouseIN() then
        a = a + 0.1
        if self:set_norm_val_m_wheel() then
            if self.onMove then
                self.onMove()
            end
        end
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.2
        self:set_norm_val()
        if self.onMove then
            self.onMove()
        end
    end
    -- in elm L_up(released and was previously pressed) --
    -- if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw knob body, frame ---
    gfx.set(r, g, b, a) -- set body,frame color
    self:draw_body() -- body
    --self:draw_frame() -- frame(if need)
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba)) -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    --self:draw_lbl()   -- draw lbl(if need)
    self:draw_val() -- draw value
end

---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function ZButton:draw_body()
    gfx.rect(self.x, self.y, self.w, self.h, true) -- draw btn body
end
--------
function ZButton:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + (h - lbl_h) / 2
    gfx.drawstr(self.lbl)
end
------------------------
function ZButton:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element --------
    if self:mouseIN() then
        a = a + 0.5
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.7
    end
    -- in elm L_up(released and was previously pressed) --
    if self:mouseClick() and self.onClick then
        self.onClick()
    end
    -- Draw btn body, frame ----
    gfx.set(r, g, b, a) -- set body color
    self:draw_body() -- body
    self:draw_frame() -- frame

    -- Draw label --------------

    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    --self:draw_lbl()             -- draw lbl

    --gfx.set(1,0,0,a)
    gfx.line(self.x + self.w / 1.89, self.y + self.h - self.h / 4, self.x + self.w / 2, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 2.11, self.y + self.h - self.h / 4, self.x + self.w / 2, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 1.899, self.y + self.h - self.h / 4.09, self.x + self.w / 2.01, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 2.119, self.y + self.h - self.h / 4.09, self.x + self.w / 2.01, self.y + self.h / 3, 1)
end

---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function XButton:draw_body()
    gfx.rect(self.x, self.y, self.w, self.h, true) -- draw btn body
end
--------
function XButton:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x + (w - lbl_w) / 2
    gfx.y = y + (h - lbl_h) / 2
    gfx.drawstr(self.lbl)
end
------------------------
function XButton:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element --------
    if self:mouseIN() then
        a = a + 0.5
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.7
    end
    -- in elm L_up(released and was previously pressed) --
    if self:mouseClick() and self.onClick then
        self.onClick()
    end
    -- Draw btn body, frame ----
    gfx.set(r, g, b, a) -- set body color
    self:draw_body() -- body
    self:draw_frame() -- frame

    -- Draw label --------------

    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    --self:draw_lbl()             -- draw lbl

    --gfx.set(1,0,0,a)
    gfx.line(self.x + self.w / 2, self.y + self.h - self.h / 4, self.x + self.w / 1.89, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 2, self.y + self.h - self.h / 4, self.x + self.w / 2.11, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 2.01, self.y + self.h - self.h / 4.09, self.x + self.w / 1.899, self.y + self.h / 3, 1)

    gfx.line(self.x + self.w / 2.01, self.y + self.h - self.h / 4.09, self.x + self.w / 2.119, self.y + self.h / 3, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   CheckBox Class Methods   -------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then
        return false
    end -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then
        self.norm_val = self.norm_val - 1
    end
    if gfx.mouse_wheel < 0 then
        self.norm_val = self.norm_val + 1
    end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val > #self.norm_val2 then
        self.norm_val = 1
    elseif self.norm_val < 1 then
        self.norm_val = #self.norm_val2
    end
    return true
end
--------
function CheckBox:set_norm_val()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = self.norm_val -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
    for i = 1, #menu_tb, 1 do
        if i ~= val then
            menu_str = menu_str .. menu_tb[i] .. "|"
        else
            menu_str = menu_str .. "!" .. menu_tb[i] .. "|" -- add check
        end
    end
    gfx.x = self.x
    gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str) -- show checkbox menu
    if new_val > 0 then
        self.norm_val = new_val
    end -- change check(!)
end
--------
function CheckBox:draw_body()
    gfx.rect(self.x, self.y, self.w, self.h, true) -- draw checkbox body
end
--------
function CheckBox:draw_lbl()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x - lbl_w - 5
    gfx.y = y + (h - lbl_h) / 2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox:draw_val()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + 5
    gfx.y = y + (h - val_h) / 2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    local fnt, fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
    -- in element --------
    if self:mouseIN() then
        a = a + 0.5
    --if self:set_norm_val_m_wheel() then -- use if need
    --if self.onMove then self.onMove() end
    --end
    end
    -- in elm L_down -----
    if self:mouseDown() then
        a = a + 0.6
    end
    -- in elm L_up(released and was previously pressed) --
    if self:mouseClick() then
        self:set_norm_val()
        if self:mouseClick() and self.onClick then
            self.onClick()
        end
    end
    -- Draw ch_box body, frame -
    gfx.set(r, g, b, a) -- set body color
    self:draw_body() -- body
    self:draw_frame() -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba)) -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw val
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r, g, b, a = self.r, self.g, self.b, self.a
    if self:mouseIN() then
        a = a + 0.1
    end
    gfx.set(0, 0, 0, a) -- set frame color
    self:draw_frame() -- draw frame
end

----------------------------------------------------------------------------------------------------
--************************************************************************************************--
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--   Some Default Values   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local srate = 44100 -- дефолтный семплрейт(не реальный, но здесь не имеет значения)
--local n_chans = 1     -- кол-во каналов(трековых), don't change it!
local block_size = 1024 * 16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 3 * 60 -- limit maximum time, change, if need.
local defPPQ = 960 -- change, if need.
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10, 10, 1024, 350)
local Gate_Gl = {}

---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
local Fltr_Frame = Frame:new(10, 370, 180, 110, 0, 0.5, 0, 0.2)
local Gate_Frame = Frame:new(200, 370, 180, 110, 0, 0.5, 0, 0.2)
local Mode_Frame = Frame:new(520, 370, 510, 110, 0, 0.5, 0, 0.2)
local Manipulate_Frame = Frame:new(390, 370, 120, 110, 0, 0.5, 0, 0.2)
local Frame_TB = {Fltr_Frame, Gate_Frame, Mode_Frame, Manipulate_Frame}

local Midi_Sampler = CheckBox:new(740, 410, 68, 18, 0.1, 0.5, 0.55, 0.6, "", "Arial", 15, 1, {"Sampler", "Trigger"})

----------------------------------------------------------------------------------------------------
---  Create controls objects(btns,sliders etc) and override some methods   -------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = H_Slider:new(20, 410, 160, 18, 0.1, 0.5, 0.55, 0.6, "Low Cut", "Arial", 15, 0.57825)
-- Filter HP_Freq --------------------------------
local LP_Freq = H_Slider:new(20, 430, 160, 18, 0.1, 0.5, 0.55, 0.6, "High Cut", "Arial", 15, 0.8261)

--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
    local sx = 16 + (self.norm_val * 100) * 1.20103
    self.form_val = math.floor(math.exp(sx * math.log(1.059)) * 8.17742) -- form val
    -------------
    local x, y, w, h = self.x, self.y, self.w, self.h
    --local val = string.format("%.1f", self.form_val)
    local val = string.format("%d", self.form_val) .. " Hz"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val) -- draw Slider Value
end
-------------------------
LP_Freq.draw_val = HP_Freq.draw_val -- Same as the previous(HP_Freq:draw_val())

-- Filter Gain -----------------------------------
local Fltr_Gain = H_Slider:new(20, 450, 160, 18, 0.1, 0.5, 0.55, 0.6, "Out Gain", "Arial", 15, out_gain)
function Fltr_Gain:draw_val()
    self.form_val = self.norm_val * 24 -- form value
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", self.form_val) .. " dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end

--------------------------------------------------
-- onUp function for Filter Freq sliders ---------
--------------------------------------------------
function Fltr_Sldrs_onUp()
    if Wave.AA then
        Wave:Processing()
        if Wave.State then
            Wave:Redraw()
            Gate_Gl:Apply_toFiltered()
        end
    end
end
----------------
HP_Freq.onUp = Fltr_Sldrs_onUp
LP_Freq.onUp = Fltr_Sldrs_onUp
--------------------------------------------------
-- onUp function for Filter Gain slider  ---------
--------------------------------------------------
Fltr_Gain.onUp = function()
    if Wave.State then
        Wave:Redraw()
        Gate_Gl:Apply_toFiltered()
    end
end

local CreateMIDIMode =
    CheckBox:new(
    590,
    410,
    250,
    18,
    0.3,
    0.5,
    0.5,
    0.3,
    "",
    "Arial",
    15,
    1,
    {
        "Insert new item on new track",
        "Insert new item on selected track",
        "Use selected item (auto-replace notes)"
    }
)

-------------------------
local VeloMode =
    CheckBox:new(
    820,
    410,
    90,
    18,
    0.1,
    0.5,
    0.55,
    0.6,
    "",
    "Arial",
    15,
    1, -------velodaw
    {"Use RMS", "Use Peak"}
)

VeloMode.onClick = function()
    if Wave.State and CreateMIDIMode.norm_val == 3 then
        Wave:Create_MIDI()
    end
end

-------------------------------------------------------------------------------------
--- Gate Sliders --------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Threshold -------------------------------------

local Gate_Thresh = H_Slider:new(210, 380, 160, 18, 0.1, 0.5, 0.55, 0.6, "Threshold", "Arial", 15, readrms)
function Gate_Thresh:draw_val()
    self.form_val = (self.norm_val - 1) * 57 - 3
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", self.form_val) .. " dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val) -- draw Slider Value
    Gate_Thresh:draw_val_line() -- Draw GATE Threshold lines !!!
end

--------------------------------------------------
-- Gate Threshold-lines function -----------------
--------------------------------------------------
function Gate_Thresh:draw_val_line()
    if Wave.State then
        gfx.set(0.8, 0.3, 0, 1)
        local val = (10 ^ (self.form_val / 20)) * Wave.Y_scale * Wave.vertZoom * Z_h -- value in gfx
        if val > Wave.h / 2 then
            return
        end -- don't draw lines if value out of range
        local val_line1 = Wave.y + Wave.h / 2 - val -- line1 y coord
        local val_line2 = Wave.y + Wave.h / 2 + val -- line2 y coord
        gfx.line(Wave.x, val_line1, Wave.x + Wave.w - 1, val_line1)
        gfx.line(Wave.x, val_line2, Wave.x + Wave.w - 1, val_line2)
    end
end
-- Sensitivity -------------------------------------
local Gate_Sensitivity = H_Slider:new(210, 400, 160, 18, 0.1, 0.5, 0.55, 0.6, "Sensitivity", "Arial", 15, 0.2)
function Gate_Sensitivity:draw_val()
    self.form_val = 2 + (self.norm_val) * 15 -- form_val
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", self.form_val) .. " dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = H_Slider:new(210, 420, 160, 18, 0.1, 0.5, 0.55, 0.6, "Retrig", "Arial", 15, retrigms)
function Gate_Retrig:draw_val()
    self.form_val = 20 + self.norm_val * 180 -- form_val
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", self.form_val) .. " ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end
-- Detect Velo time ------------------------------
local Gate_DetVelo = H_Slider:new(820, 430, 90, 18, 0.1, 0.5, 0.55, 0.6, "Look", "Arial", 15, 0.25)
 ------velodaw
function Gate_DetVelo:draw_val()
    self.form_val = 5 + self.norm_val * 20 -- form_val
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", self.form_val) .. " ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end
-- Reduce points slider --------------------------
local Gate_ReducePoints = H_Slider:new(210, 450, 160, 18, 0.1, 0.5, 0.55, 0.6, "Reduce", "Arial", 15, 1)
function Gate_ReducePoints:draw_val()
    self.cur_max = self.cur_max or 0 -- current points max
    self.form_val = math.ceil(self.norm_val * self.cur_max) -- form_val
    if self.form_val == 0 and self.cur_max > 0 then
        self.form_val = 1
    end -- надо переделать,это принудительно
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%d", self.form_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end
----------------
Gate_ReducePoints.onUp = function()
    if Wave.State then
        Gate_Gl:Reduce_Points()
    end
end
--------------------------------------------------
-- onUp function for Gate sliders(except reduce) -
--------------------------------------------------
function Gate_Sldrs_onUp()
    if Wave.State then
        Gate_Gl:Apply_toFiltered()
    end
end
----------------
Gate_Thresh.onUp = Gate_Sldrs_onUp
Gate_Sensitivity.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp = Gate_Sldrs_onUp
Gate_DetVelo.onUp = Gate_Sldrs_onUp

-- Detect Velo time ------------------------------
local Offset_Sld = H_Slider:new(530, 430, 208, 18, 0.1, 0.5, 0.55, 0.6, "Offset", "Arial", 15, 0.5)
 ------velodaw
function Offset_Sld:draw_val()
    self.form_val = (100 - self.norm_val * 200) * (-1) -- form_val
    function fixzero()
        FixMunus = self.form_val
        if (FixMunus == 0.0) then
            FixMunus = 0
        end
    end
    fixzero()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%.1f", FixMunus) .. " ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x + w - val_w - 5
    gfx.drawstr(val)
 --draw Slider Value
end
Offset_Sld.onUp = function()
    if Wave.State then
        Gate_Gl:Apply_toFiltered()
        DrawGridGuides()
        fixzero()
    end
end

-------------------------------------------------------------------------------------
--- Velo Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(820, 450, 90, 18, 0.1, 0.5, 0.55, 0.6, "Range", "Arial", 15, 0.231, 0.79)
 ---velodaw
function Gate_VeloScale:draw_val()
    self.form_val = math.floor(1 + self.norm_val * 126) -- form_val
    self.form_val2 = math.floor(1 + self.norm_val2 * 126) -- form_val2
    local x, y, w, h = self.x, self.y, self.w, self.h
    local val = string.format("%d", self.form_val)
    local val2 = string.format("%d", self.form_val2)
    local val_w, val_h = gfx.measurestr(val)
    local val2_w, val2_h = gfx.measurestr(val2)
    local T = 0 -- set T = 0 or T = h (var1, var2 text position)
    gfx.x = x + 5
    gfx.y = y + (h - val_h) / 2 + T
    gfx.drawstr(val) -- draw value 1
    gfx.x = x + w - val2_w - 5
    gfx.y = y + (h - val2_h) / 2 + T
    gfx.drawstr(val2) -- draw value 2
end

-------------------------
local OutNote =
    CheckBox:new(
    740,
    430,
    68,
    18,
    0.1,
    0.5,
    0.55,
    0.6,
    "",
    "Arial",
    15,
    1,
    --{36,37,38,39,40,41,42,43,44,45,46,47},
    {
        "C1: 36",
        "C#1: 37",
        "D1: 38",
        "D#1: 39",
        "E1: 40",
        "F1: 41",
        "F#1: 42",
        "G1: 43",
        "G#1: 44",
        "A1: 45",
        "A#1: 46",
        "B1: 47"
    }
)
-------------------------

local Velocity = Button:new(830, 380, 55, 18, 0, 0, 0, 0, "Velocity ", "Arial", 15, 3, {})

----------------------------------------

local Slider_TB = {
    HP_Freq,
    LP_Freq,
    Fltr_Gain,
    Gate_Thresh,
    Gate_Sensitivity,
    Gate_Retrig,
    Gate_ReducePoints,
    Offset_Sld
}

local Exception = {Gate_DetVelo}

local Slider_TB_Trigger = {
    HP_Freq,
    LP_Freq,
    Fltr_Gain,
    Gate_Thresh,
    Gate_Sensitivity,
    Gate_Retrig,
    Gate_DetVelo,
    Gate_ReducePoints,
    Gate_VeloScale,
    VeloMode,
    OutNote,
    Velocity,
    Offset_Sld
}

-------------------------------------------------------------------------------------
--- Buttons -------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Get Selection button --------------------------
local Get_Sel_Button = Button:new(20, 380, 160, 25, 0.7, 0.7, 0.7, 1, "Get Item", "Arial", 15)
Get_Sel_Button.onClick = function()
    --getsomerms()---disable

    Fltr_Gain.norm_val = out_gain

    Gate_Thresh.norm_val = readrms

    getitem()
end

---------------------------------------------------MANIPULATE

function Stretch(pop)
    ----------------------------------------------
    function GetItems()
        local t = {}
        local count_sel_items = reaper.CountSelectedMediaItems(0)
        min_pos = math.huge
        for i = 1, count_sel_items do
            local item = reaper.GetSelectedMediaItem(0, i - 1)
            min_pos = math.min(min_pos, reaper.GetMediaItemInfo_Value(item, "D_POSITION"))
        end
        for i = 1, count_sel_items do
            local item = reaper.GetSelectedMediaItem(0, i - 1)
            t[#t+1] = {['guid'] = GuidToItem(item), ['pos'] =reaper.GetMediaItemInfo_Value(item, 'D_POSITION')}
        end
        return t, count_sel_items
    end

    ----------------------------------------------
    function StretchItemPositions(t)
        if t == nil or #t == 0 then
            return
        end
        for i = 1, #t do
            min_pos = math.min(min_pos, t[i].pos)
        end
        for i = 1, #t do
           item = GuidToItem(t[i].guid)
            if item ~= nil then
                reaper.SetMediaItemInfo_Value(item, "D_POSITION", min_pos + (t[i].pos - min_pos) * (1 - diff))
            end
        end
    end

    ----------------------------------------------

    function run(amount)
        diff = (amount) * 0.01
        defer_sel_items = reaper.CountSelectedMediaItems(0)

        if last_defer_sel_items == nil then
            last_defer_sel_items = defer_sel_items
        end
        if last_defer_sel_items ~= defer_sel_items then
            t0, count_sel_items0 = nil, nil
        else
            StretchItemPositions(t0)
        end
        last_defer_sel_items = reaper.CountSelectedMediaItems(0)
    end

    ----------------------------------------------

    t0, count_sel_items0 = GetItems()

    run(pop)
end

local Manipulate =
    CheckBox:new(426, 380, 50, 18, 0.1, 0.5, 0.55, 0.6, "", "Arial", 13, 1, {"ItemLen", "ItemPos", "Fades"})

-- Create Slice to RX Button ----------------------------
local Rrate = Button:new(438, 430, 24, 18, 0.7, 0.7, 0.7, 1, "X", "Arial", 13)
Rrate.onClick = function()
    if (Manipulate.norm_val == 1) or (Manipulate.norm_val == 2) then
        if reaper.GetSelectedMediaItem(0, 0) then
            reaper.Main_OnCommand(40652, 0)
            reaper.Main_OnCommand(40485, 0) ------Set Timebase to position only
        end
    elseif (Manipulate.norm_val == 3) then
        local countselitems = reaper.CountSelectedMediaItems(0)

        if countselitems then
            for i = 1, reaper.CountSelectedMediaItems(0) do
                local fadeitem = reaper.GetSelectedMediaItem(0, i - 1)

                reaper.SetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE", 0)

                reaper.Main_OnCommand(41193, 0) ----delete fade in fade out

                reaper.UpdateArrange()
            end
        end
    end
end

-- Create Slice to RX Button ----------------------------
local TransposeUp = ZButton:new(400, 410, 100, 18, 0.7, 0.7, 0.7, 1, "A", "Arial", 14)
TransposeUp.onClick = function()
    if (Manipulate.norm_val == 1) then
        if reaper.GetSelectedMediaItem(0, 0) then
            reaper.Main_OnCommand(40797, 0)
        end -------Icrease rate
    elseif (Manipulate.norm_val == 2) then
        --reaper.Main_OnCommand(reaper.NamedCommandLookup('_FNG_EXPAND_BY2'), 0)  -------SWS/FNG: Expand selected media items by 2
        ExpandItems(1.0)
    elseif (Manipulate.norm_val == 3) then
        local countselitems = reaper.CountSelectedMediaItems(0)

        if countselitems then
            for i = 1, reaper.CountSelectedMediaItems(0) do
                local fadeitem = reaper.GetSelectedMediaItem(0, i - 1)

                GetFade = reaper.GetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE")

                if (GetFade ~= 6) then
                    Newfade = (GetFade + 1)

                    reaper.SetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE", Newfade)
                else
                    reaper.SetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE", 0)
                end
            end
            reaper.UpdateArrange()
        end
    end
end

-- Create Slice to RX Button ----------------------------
local TransposeDown = XButton:new(400, 450, 100, 18, 0.7, 0.7, 0.7, 1, "V", "Arial", 14)
TransposeDown.onClick = function()
    if (Manipulate.norm_val == 1) then
        if reaper.GetSelectedMediaItem(0, 0) then
            reaper.Main_OnCommand(40798, 0)
        end -------Decrease rate
    elseif (Manipulate.norm_val == 2) then
        --reaper.Main_OnCommand(reaper.NamedCommandLookup('_FNG_CONTRACT_BY_HALF'), 0) ------SWS/FNG: Contract selected media items by 1/2
        ExpandItems(-0.5)
    elseif (Manipulate.norm_val == 3) then
        local countselitems = reaper.CountSelectedMediaItems(0)

        if countselitems then
            for i = 1, reaper.CountSelectedMediaItems(0) do
                local fadeitem = reaper.GetSelectedMediaItem(0, i - 1)

                GetFade = reaper.GetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE")

                if (GetFade ~= 0) then
                    Newfade = (GetFade - 1)

                    reaper.SetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE", Newfade)
                else
                    reaper.SetMediaItemInfo_Value(fadeitem, "C_FADEOUTSHAPE", 6)
                end
            end
            reaper.UpdateArrange()
        end
    end
end

Lengt_Divider = 16

-- Create Slice to RX Button ----------------------------
local Shorten = Button:new(400, 430, 35, 18, 0.7, 0.7, 0.7, 1, "<", "Arial", 18)
Shorten.onClick = function()
    if (Manipulate.norm_val == 1) then
        local countmitems = reaper.CountSelectedMediaItems(0)

        if countmitems then
            for i = 1, countmitems do
                local lgitem = reaper.GetSelectedMediaItem(0, i - 1)

                local Lengt = reaper.GetMediaItemInfo_Value(lgitem, "D_LENGTH")

                reaper.SetMediaItemInfo_Value(lgitem, "D_LENGTH", Lengt - Lengt / Lengt_Divider)
            end
            reaper.UpdateArrange()
        end
    elseif (Manipulate.norm_val == 2) then
        Stretch(2)
    elseif (Manipulate.norm_val == 3) then
        local countmitems = reaper.CountSelectedMediaItems(0)

        if countmitems then
            for i = 1, countmitems do
                local lgitem = reaper.GetSelectedMediaItem(0, i - 1)

                local Lengt = reaper.GetMediaItemInfo_Value(lgitem, "D_FADEOUTLEN")

                ILengt = reaper.GetMediaItemInfo_Value(lgitem, "D_LENGTH")

                if Lengt < ILengt and not Lengt ~= ILengt then
                    reaper.SetMediaItemInfo_Value(lgitem, "D_FADEOUTLEN", Lengt + ILengt / Lengt_Divider)
                end
            end
            reaper.UpdateArrange()
        end
    end
end

-- Create Slice to RX Button ----------------------------
local Lengthen = Button:new(464, 430, 36, 18, 0.7, 0.7, 0.7, 1, ">", "Arial", 18)
Lengthen.onClick = function()
    if (Manipulate.norm_val == 1) then
        local countmitems = reaper.CountSelectedMediaItems(0)

        if countmitems then
            for i = 1, countmitems do
                local lgitem = reaper.GetSelectedMediaItem(0, i - 1)

                local Lengt = reaper.GetMediaItemInfo_Value(lgitem, "D_LENGTH")

                reaper.SetMediaItemInfo_Value(lgitem, "D_LENGTH", Lengt + Lengt / Lengt_Divider)
            end
            reaper.UpdateArrange()
        end
    elseif (Manipulate.norm_val == 2) then
        Stretch(-2)
    elseif (Manipulate.norm_val == 3) then
        local countmitems = reaper.CountSelectedMediaItems(0)

        if countmitems then
            for i = 1, countmitems do
                local lgitem = reaper.GetSelectedMediaItem(0, i - 1)

                local Lengt = reaper.GetMediaItemInfo_Value(lgitem, "D_FADEOUTLEN")
                ILengt = reaper.GetMediaItemInfo_Value(lgitem, "D_LENGTH")
                if Lengt > ILengt / Lengt_Divider then
                    reaper.SetMediaItemInfo_Value(lgitem, "D_FADEOUTLEN", Lengt - ILengt / Lengt_Divider)
                end
            end
            reaper.UpdateArrange()
        end
    end
end

-- Create Slice to RX Button ----------------------------
local PPicth = Button:new(478, 380, 24, 18, 0.7, 0.7, 0.7, 1, "PP", "Arial", 13)
PPicth.onClick = function()
    if reaper.GetSelectedMediaItem(0, 0) then
        reaper.Main_OnCommand(40566, 0)
        reaper.Main_OnCommand(40485, 0) ------Set Timebase to position only
    end -------Reset Rate
end

-- Create Slice to RX Button ----------------------------
local TBase = Button:new(400, 380, 24, 18, 0.7, 0.7, 0.7, 1, "TB", "Arial", 13)
TBase.onClick = function()
    countmitems = reaper.CountSelectedMediaItems(0)

    if countmitems then
        for i = 1, countmitems do
            bitem = reaper.GetSelectedMediaItem(0, i - 1)

            beatmode = reaper.GetMediaItemInfo_Value(bitem, "C_BEATATTACHMODE")

            if beatmode == -1 then
                reaper.SetMediaItemInfo_Value(bitem, "C_BEATATTACHMODE", 2)
            elseif beatmode == 0 then
                reaper.SetMediaItemInfo_Value(bitem, "C_BEATATTACHMODE", 2)
            elseif beatmode == 1 then
                reaper.SetMediaItemInfo_Value(bitem, "C_BEATATTACHMODE", 2)
            elseif beatmode == 2 then
                reaper.SetMediaItemInfo_Value(bitem, "C_BEATATTACHMODE", 1)
            end
        end
    end
end

-- Create Slice to RX Button ----------------------------
local Slice_RX = Button:new(530, 380, 68, 25, 0.7, 0.7, 0.7, 1, "Slice RX", "Arial", 15)
Slice_RX.onClick = function()
    if Wave.State then
        Wave:Slice_RX()
    end
end

-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(600, 380, 68, 25, 0.7, 0.7, 0.7, 1, "Slice", "Arial", 15)
Just_Slice.onClick = function()
    if Wave.State then
        Wave:Just_Slice()
    end
end

-- Create Add Markers Button ----------------------------
local Add_Markers = Button:new(670, 380, 68, 25, 0.7, 0.7, 0.7, 1, "Markers", "Arial", 15)
Add_Markers.onClick = function()
    if Wave.State then
        Wave:Add_Markers()
    end
end

-------------------------

-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(740, 380, 68, 25, 0.7, 0.7, 0.7, 1, "MIDI", "Arial", 15)
Create_MIDI.onClick = function()
    if (Midi_Sampler.norm_val == 1) then
        function TooSmallToLoad()
            local countselitems = reaper.CountSelectedMediaItems(0)

            if (countselitems > 0) then
                for i = 1, reaper.CountSelectedMediaItems(0) do
                    local forloaditem = reaper.GetSelectedMediaItem(0, i - 1)

                    GetLengt = reaper.GetMediaItemInfo_Value(forloaditem, "D_LENGTH")
                end
            end

            wasitem = reaper.GetExtState("MyDaw", "ItemToSlice")

            ItemState = reaper.GetExtState("MyDaw", "GetItemState")

            if GetLengt > MinimumItem and (ItemState == "ItemLoaded") then
                Wave:Just_Slice()
                Wave:Load_To_Sampler()
            elseif GetLengt < MinimumItem and (ItemState == "ItemLoaded") then
                Wave:Load_To_Sampler()
            elseif GetLengt < MinimumItem and not (ItemState == "ItemLoaded") then
                reaper.Main_OnCommand(40290, 0)
                 --- set time selection to items

                sel_start1, sel_end1 = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)

                reaper.Main_OnCommand(40635, 0) ---Remove Time selection

                local loaditem = reaper.GetSelectedMediaItem(0, 0)

                trackofitem = reaper.GetMediaItem_Track(loaditem)

                reaper.SetOnlyTrackSelected(trackofitem)

                Wave:Load_To_Sampler(sel_start1, sel_end1, trackofitem)
            end
        end

        TooSmallToLoad()
    else
        if Wave.State then
            Wave:Create_MIDI()
        end
    end
end

----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Button_TB = {
    Get_Sel_Button,
    Slice_RX,
    Just_Slice,
    Add_Markers,
    Create_MIDI,
    Midi_Sampler,
    Manipulate,
    TransposeUp,
    TransposeDown,
    Shorten,
    Lengthen,
    Rrate,
    PPicth,
    TBase
}

-------------------------------------------------------------------------------------
--- CheckBoxes ----------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table ---
-------------------------------------------------------------------------------------
--------------------------------------------------
-- MIDI Checkboxes ------------------------------- 0.3,0.5,0.3,0.3 -- green
local NoteChannel =
    CheckBox:new(
    660,
    430,
    88,
    18,
    0.3,
    0.5,
    0.5,
    0.3,
    "",
    "Arial",
    15,
    1,
    --{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    {
        "Channel: 1",
        "Channel: 2",
        "Channel: 3",
        "Channel: 4",
        "Channel: 5",
        "Channel: 6",
        "Channel: 7",
        "Channel: 8",
        "Channel: 9",
        "Channel: 10",
        "Channel: 11",
        "Channel: 12",
        "Channel: 13",
        "Channel: 14",
        "Channel: 15",
        "Channel: 16"
    }
)
-------------------------
local NoteLenghth =
    CheckBox:new(
    750,
    430,
    90,
    18,
    0.3,
    0.5,
    0.5,
    0.3,
    "",
    "Arial",
    15,
    5,
    {"Lenght: 1/4", "Lenght: 1/8", "Lenght: 1/16", "Lenght: 1/32", "Lenght: 1/64"}
)
-------------------------

local Guides =
    CheckBox:new(
    530,
    410,
    208,
    18,
    0.1,
    0.5,
    0.55,
    0.6,
    "",
    "Arial",
    15,
    1,
    {
        "Guides By Transients",
        "Guides By 1/2",
        "Guides By 1/4",
        "Guides By 1/8",
        "Guides By 1/16",
        "Guides By 1/32",
        "Guides By 1/64"
    }
)

Guides.onClick = function()
    DrawGridGuides()
end

--------------------------------------------------
-- View Checkboxes -------------------------------
local DrawMode =
    CheckBox:new(965, 380, 55, 18, 0.1, 0.5, 0.55, 0.6, "Draw: ", "Arial", 15, 3, {"Slowest", "Slow", "Medium", "Fast"})

-- DrawMode.onClick = Get_Sel_Button.onClick (Отключено(работает только при захвате))
-------------------------
local ViewMode =
    CheckBox:new(
    965,
    400,
    55,
    18,
    0.1,
    0.5,
    0.55,
    0.6,
    "Show: ",
    "Arial",
    15,
    1,
    {"All", "Original", "Filtered", "Lines"}
)
ViewMode.onClick = function()
    if Wave.State then
        Wave:Redraw()
    end
end

-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {DrawMode, ViewMode, Guides}

---[[ Перенести наверх!!!----------------------
Gate_VeloScale.onUp = function()
    if Wave.State and CreateMIDIMode.norm_val == 3 then
        Wave:Create_MIDI()
    end
end
 --]]

----------------------------------------------------------------------------------------------------------------------------------
--  **************************** **************************** **************************** ---------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Some functions(local functions work faster in big cicles(~30%)) ------------
-- R.Ierusalimschy - "lua Performance Tips" -----------------------------------
-------------------------------------------------------------------------------
local abs = math.abs
local min = math.min
local max = math.max
local sqrt = math.sqrt
local ceil = math.ceil
local floor = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
    local start_time = reaper.time_precise()
     --time test
    -----------------------------------------------------
    -------------------------------------------------
    self.State_Points = {} -- State_Points table
    -------------------------------------------------
    -- GetSet parameters ----------------------------
    -------------------------------------------------
    -- Threshold, Sensitivity ----------
    local gain_fltr = 10 ^ (Fltr_Gain.form_val / 20) -- Gain from Fltr_Gain slider(need for scaling gate Thresh!)
    local Thresh = 10 ^ (Gate_Thresh.form_val / 20) / gain_fltr -- Threshold regard gain_fltr
    Thresh = Thresh / (0.5 / block_size) -- Threshold regard fft_real scale and gain_fltr
    local Sensitivity = 10 ^ (Gate_Sensitivity.form_val / 20) -- Gate "Sensitivity", diff between - fast and slow envelopes(in dB)
    -- Attack, Release Time -----------
    -- Эти параметры нужно либо выносить в доп. настройки, либо подбирать тщательнее...
    local attTime1 = 0.001 -- Env1 attack(sec)
    local attTime2 = 0.007 -- Env2 attack(sec)
    local relTime1 = 0.010 -- Env1 release(sec)
    local relTime2 = 0.015 -- Env2 release(sec)
    -----------------------------------
    -- Init counters etc --------------
    -----------------------------------
    local retrig_smpls = floor(Gate_Retrig.form_val / 1000 * srate) -- Retrig slider to samples
    local retrig = retrig_smpls + 1 -- Retrig counter start value!

    local det_velo_smpls = floor(Gate_DetVelo.form_val / 1000 * srate) -- DetVelo slider to samples

    -----------------------------------
    local rms_sum, peak_smpl = 0, 0 -- init rms_sum,   maxRMS
    local maxRMS, maxPeak = 0, 0 -- init max-s
    local minRMS, minPeak = math.huge, math.huge -- init min-s
    -------------------
    local smpl_cnt = 0 -- Gate sample(for get velo) counter
    local st_cnt = 1 -- Gate State counter for State tables
    -----------------------------------
    local envOut1 = Wave.out_buf[1] -- Peak envelope1 follower start value
    local envOut2 = envOut1 -- Peak envelope2 follower start value
    local Trig = false -- Trigger, Trig init state
    ------------------------------------------------------------------
    -- Compute sample frequency related coeffs -----------------------
    local ga1 = math.exp(-1 / (srate * attTime1)) -- attack1 coeff
    local gr1 = math.exp(-1 / (srate * relTime1)) -- release1 coeff
    local ga2 = math.exp(-1 / (srate * attTime2)) -- attack2 coeff
    local gr2 = math.exp(-1 / (srate * relTime2)) -- release2 coeff

    -----------------------------------------------------------------
    -- Gate main for ------------------------------------------------
    -----------------------------------------------------------------
    for i = 1, Wave.selSamples, 1 do
        local input = abs(Wave.out_buf[i]) -- abs sample value(abs envelope)
        --------------------------------------------
        -- Envelope1(fast) -------------------------
        if envOut1 < input then
            envOut1 = input + ga1 * (envOut1 - input)
        else
            envOut1 = input + gr1 * (envOut1 - input)
        end
        --------------------------------------------
        -- Envelope2(slow) -------------------------
        if envOut2 < input then
            envOut2 = input + ga2 * (envOut2 - input)
        else
            envOut2 = input + gr2 * (envOut2 - input)
        end

        --------------------------------------------
        -- Trigger ---------------------------------
        if retrig > retrig_smpls then
            if envOut1 > Thresh and (envOut1 / envOut2) > Sensitivity then
                Trig = true
                smpl_cnt = 0
                retrig = 0
                rms_sum, peak_smpl = 0, 0 -- set start-values(for capture velo)
            end
        else
            envOut2 = envOut1
            retrig = retrig + 1 -- урав. огибающие,пока триггер неактивен
        end
        -------------------------------------------------------------
        -- Get samples(for velocity) --------------------------------
        -------------------------------------------------------------
        if Trig then
            if smpl_cnt <= det_velo_smpls then
                ----------------------------
                rms_sum = rms_sum + input * input -- get  rms_sum   for note-velo
                peak_smpl = max(peak_smpl, input) -- find peak_smpl for note-velo
                smpl_cnt = smpl_cnt + 1
            else
                -----------------------
                Trig = false -- reset Trig state !!!
                -----------------------
                local RMS = sqrt(rms_sum / det_velo_smpls) -- calculate RMS
                --- Trigg point -------
                self.State_Points[st_cnt] = i - det_velo_smpls -- Time point(in Samples!)
                self.State_Points[st_cnt + 1] = {RMS, peak_smpl} -- RMS, Peak values
                --------
                minRMS = min(minRMS, RMS) -- save minRMS for scaling
                minPeak = min(minPeak, peak_smpl) -- save minPeak for scaling
                maxRMS = max(maxRMS, RMS) -- save maxRMS for scaling
                maxPeak = max(maxPeak, peak_smpl) -- save maxPeak for scaling
                --------
                st_cnt = st_cnt + 2
            end
        end
        ----------------------------------
    end
    -----------------------------
    if minRMS == maxRMS then
        minRMS = 0
    end -- если только одна точка
    self.minRMS, self.minPeak = minRMS, minPeak -- minRMS, minPeak for scaling MIDI velo
    self.maxRMS, self.maxPeak = maxRMS, maxPeak -- maxRMS, maxPeak for scaling MIDI velo
    -----------------------------
    Gate_ReducePoints.cur_max = #self.State_Points / 2 -- set Gate_ReducePoints slider m factor
    Gate_Gl:normalizeState_TB() -- нормализация таблицы(0...1)
    Gate_Gl:Reduce_Points() -- Reduce Points
    -----------------------------
    if CreateMIDIMode.norm_val == 3 then
        Wave:Create_MIDI()
    end -- Auto-create MIDI, when mode == 3(use sel item)
    -----------------------------
    collectgarbage("collect") -- collectgarbage(подметает память)
    -------------------------------
    --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test
    -------------------------------
end







----------------------------------------------------------------------
---  Gate - Normalize points table  ----------------------------------
----------------------------------------------------------------------
function Gate_Gl:normalizeState_TB()
    local scaleRMS = 1 / (self.maxRMS - self.minRMS)
    local scalePeak = 1 / (self.maxPeak - self.minPeak)
    ---------------------------------
    for i = 2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        self.State_Points[i][1] = (self.State_Points[i][1] - self.minRMS) * scaleRMS
        self.State_Points[i][2] = (self.State_Points[i][2] - self.minPeak) * scalePeak
    end
    ---------------------------------
    self.minRMS, self.minPeak = 0, 0 -- норм мин
    self.maxRMS, self.maxPeak = 1, 1 -- норм макс
end




 function GetNextGrid(cursorpos)
 
 
 reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap

local grid_duration
if reaper.GetToggleCommandState( 41885 ) == 1 then -- Toggle framerate grid
  grid_duration = 0.4/reaper.TimeMap_curFrameRate( 0 )
else
  local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
  local tmsgn_cnt = reaper.CountTempoTimeSigMarkers( 0 )
  local _, tempo
  if tmsgn_cnt == 0 then
    tempo = reaper.Master_GetTempo()
  else
    local active_tmsgn = reaper.FindTempoTimeSigMarker( 0, cursorpos )
    _, _, _, _, tempo = reaper.GetTempoTimeSigMarker( 0, active_tmsgn )
  end
  grid_duration = 60/tempo * division
end


local snapped, grid = reaper.SnapToGrid(0, cursorpos)
if snapped > cursorpos then
  grid = snapped
else
  grid = cursorpos
  while (grid <= cursorpos) do
      cursorpos = cursorpos + grid_duration
      grid = reaper.SnapToGrid(0, cursorpos)
  end
end

reaper.Main_OnCommand(40756, 0) -- Snapping:
 
 return grid
 
end



----------------------------------------------------------------------
---  Gate - Reduce trig points  --------------------------------------
----------------------------------------------------------------------
function Gate_Gl:Reduce_Points() -- Надо допилить!!!
    local mode = VeloMode.norm_val
    local tmp_tb = {} -- временная таблица для сортировки и поиска нужного значения
    ---------------------------------
    for i = 2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        tmp_tb[i / 2] = self.State_Points[i][mode] -- mode - учитываются текущие настройки
    end
    ---------------------------------
    table.sort(tmp_tb) -- сортировка, default, от меньшего к большему
    ---------------------------------
    local pointN = ceil((1 - Gate_ReducePoints.norm_val) * #tmp_tb) -- здесь form_val еще не определено, поэтому так!
    local reduce_val = 0
    if #tmp_tb > 0 and pointN > 0 then
        reduce_val = tmp_tb[pointN]
    end -- искомое значение(либо 0)
    ---------------------------------

    self.Res_Points = {}
    for i = 1, #self.State_Points, 2 do
        -- В результирующую таблицу копируются значения, входящие в диапазон --
        if self.State_Points[i + 1][mode] >= reduce_val then
            local p = #self.Res_Points + 1
            self.Res_Points[p] = self.State_Points[i] + (Offset_Sld.form_val / 1000 * srate)
            self.Res_Points[p + 1] = {self.State_Points[i + 1][1], self.State_Points[i + 1][2]}
        end
    end



    item = reaper.GetSelectedMediaItem(0, 0)

    -- Дальше всегда используется результирующая таблица --
    -----------------------------
    if CreateMIDIMode.norm_val == 3 then
        Wave:Create_MIDI()
    end -- Auto-create MIDI, when mode == 3(use sel item)
    -----------------------------
end




    function DrawGridGuides()
        lastitem = reaper.GetExtState("MyDaw", "ItemToSlice")

        item = GuidToItem(lastitem)
        if item then
            local sel_start_g = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len_g = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            sel_end_g = sel_start_g + len_g

            ------------------------------------------------------------------------------
            -------------------------------SAVE GRID-----------------------------

            local _, division, swingmode, swingamt = reaper.GetSetProjectGrid(0, 0)

            local ext_sec, ext_key = "savegrid", "grid"
            reaper.SetExtState(ext_sec, ext_key, division .. "," .. swingmode .. "," .. swingamt, 0)

            ---------------------------SET NEWGRID--------------------------------------------------------------------
            ---------------------------------------------------------------------------------------
            if Guides.norm_val == 2 then
                reaper.Main_OnCommand(40780, 0)
            elseif Guides.norm_val == 3 then
                reaper.Main_OnCommand(40779, 0)
            elseif Guides.norm_val == 4 then
                reaper.Main_OnCommand(40778, 0)
            elseif Guides.norm_val == 5 then
                reaper.Main_OnCommand(40776, 0)
            elseif Guides.norm_val == 6 then
                reaper.Main_OnCommand(40775, 0)
            elseif Guides.norm_val == 7 then
                reaper.Main_OnCommand(40774, 0)
            end


            Grid_Points_r = {}
            Grid_Points = {}

   

            grinline = sel_start_g
      
      
            while (grinline <= sel_end_g) do
                grinline = GetNextGrid(grinline)

                 
                local pop = #Grid_Points + 1
                Grid_Points[pop] = math.floor(grinline * srate) + (Offset_Sld.form_val / 1000 * srate)

                local rock = #Grid_Points_r + 1
                offset_pop = (grinline - sel_start_g)
                Grid_Points_r[rock] = math.floor(offset_pop * srate) + (Offset_Sld.form_val / 1000 * srate)
                --msg(Grid_Points[pop])
            end
        end

        ------------------------------------RESTORE GRID-----------------------------------------------
        -----------------------------------------------------------------------------

        local ext_sec, ext_key = "savegrid", "grid"
        local str = reaper.GetExtState(ext_sec, ext_key)
        if not str or str == "" then
            return
        end

        local division, swingmode, swingamt = str:match "(.*),(.*),(.*)"
        if not (division and swingmode and swingamt) then
            return
        end

        reaper.GetSetProjectGrid(0, 1, division, swingmode, swingamt)
    end






------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------
function Gate_Gl:draw_Lines()
    --if not self.Res_Points or #self.Res_Points==0 then return end -- return if no lines
    if not self.Res_Points then
        return
    end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    local mode = VeloMode.norm_val
    local offset = Wave.h * Gate_VeloScale.norm_val
    self.scale = Gate_VeloScale.norm_val2 - Gate_VeloScale.norm_val
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos / Wave.X_scale -- Ñòàðòîâàÿ ïîçèöèÿ îòðèñîâêè â ñåìïëàõ!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w -- x scale(regard zoom) for trigg lines
    self.Yop = Wave.y + Wave.h - offset -- y start wave coord for velo points
    self.Ysc = Wave.h * self.scale -- y scale for velo points

    --------------------------------------------------------

    if (Guides.norm_val == 1) then
        -- Draw, capture trig lines ----------------------------
        --------------------------------------------------------
        gfx.set(1, 1, 0, 0.7) -- gate line, point color
        ----------------------------

        for i = 1, #self.Res_Points, 2 do
            local line_x = Wave.x + (self.Res_Points[i] - self.start_smpl) * self.Xsc -- line x coord
            local velo_y = self.Yop - self.Res_Points[i + 1][mode] * self.Ysc -- velo y coord

            ------------------------
            -- draw line, velo -----
            ------------------------
            if line_x >= Wave.x and line_x <= Wave.x + Wave.w then -- Verify line range
                gfx.line(line_x, Wave.y, line_x, Wave.y + Wave.h - 1) -- Draw Trig Line

                if (Midi_Sampler.norm_val == 2) then
                    gfx.circle(line_x, velo_y, 2, 1, 1) -- Draw Velocity point
                end
            end

            ------------------------
            -- Get mouse -----------
            ------------------------
            if not self.cap_ln and abs(line_x - gfx.mouse_x) < 10 then
                if Wave:mouseDown() or Wave:mouseR_Down() then
                    self.cap_ln = i
                end
            end
        end
    else
        gfx.set(0, 2, 2, 0.9) -- gate line, point color

        for i = 1, #Grid_Points_r do
            local line_x = Wave.x + (Grid_Points_r[i] - self.start_smpl) * self.Xsc -- line x coord

            ------------------------
            -- draw line 8 -----
            ------------------------

            if line_x >= Wave.x and line_x <= Wave.x + Wave.w then -- Verify line range
                gfx.line(line_x, Wave.y, line_x, Wave.y + Wave.h - 1) -- Draw Trig Line
            end

            ------------------------
            -- Get mouse -----------
            ------------------------
            if not self.cap_ln and abs(line_x - gfx.mouse_x) < 10 then
                if Wave:mouseDown() or Wave:mouseR_Down() then
                    self.cap_ln = i
                end
            end
        end
    end

    --------------------------------------------------------
    -- Operations with captured lines(if exist) ------------
    --------------------------------------------------------
    Gate_Gl:manual_Correction()
    -- Update captured state if mouse released -------------
    if self.cap_ln and Wave:mouseUp() then
        self.cap_ln = false
        if CreateMIDIMode.norm_val == 3 then
            Wave:Create_MIDI()
        end -- Auto-create MIDI, if mode == 3(use sel item)
    end
end

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:manual_Correction()
    -- Change Velo, Move, Del Line ---------------
    if self.cap_ln then
        -- Change Velo ---------------------------
        if Ctrl then
            local curs_x = Wave.x + (self.Res_Points[self.cap_ln] - self.start_smpl) * self.Xsc -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), Wave.y + Wave.h) -- y coord
            gfx.set(1, 1, 1, 1) -- cursor color
            gfx.line(curs_x - 12, curs_y, curs_x + 12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y - 12, curs_x, curs_y + 12) -- cursor line
            gfx.circle(curs_x, curs_y, 5, 0, 1) -- cursor point
            --------------------
            local newVelo = (self.Yop - curs_y) / (Wave.h * self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo, 0), 1)
            --------------------
            self.Res_Points[self.cap_ln + 1] = {newVelo, newVelo} -- veloRMS, veloPeak from mouse y
        end
        -- Move Line -----------------------------
        if Shift then
            local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), self.Yop) -- y coord
            gfx.set(1, 1, 1, 1) -- cursor color
            gfx.line(curs_x - 12, curs_y, curs_x + 12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y - 12, curs_x, curs_y + 12) -- cursor line
            gfx.circle(curs_x, curs_y, 5, 0, 1) -- cursor point
            --------------------
            self.Res_Points[self.cap_ln] = self.start_smpl + (curs_x - Wave.x) / self.Xsc -- Set New Position
        end
        -- Delete Line ---------------------------
        if Wave:mouseR_Down() then
            gfx.x, gfx.y = mouse_ox, mouse_oy
            if gfx.showmenu("Delete") == 1 then
                table.remove(self.Res_Points, self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
                table.remove(self.Res_Points, self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
            end
        end
    end

    -- Insert Line(on mouseR_Down) -------------------------
    if not self.cap_ln and Wave:mouseR_Down() then
        gfx.x, gfx.y = mouse_ox, mouse_oy
        if gfx.showmenu("Insert") == 1 then
            local line_pos = self.start_smpl + (mouse_ox - Wave.x) / self.Xsc -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy) / (Wave.h * self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo, 0), 1)
            --------------------
            table.insert(self.Res_Points, line_pos) -- В конец таблицы
            table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
---  GetSet_MIDITake  ----------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает новый айтем, либо удаляет выбранную ноту в выделленном.
function Wave:GetSet_MIDITake()
    local tracknum, midi_track, item, take
    -- New item on new track(mode 1) ------------
    if CreateMIDIMode.norm_val == 1 then
        -- New item on sel track(mode 2) ------------
        tracknum = reaper.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
        reaper.InsertTrackAtIndex(tracknum, false)
        midi_track = reaper.GetTrack(0, tracknum)
        reaper.TrackList_AdjustWindows(0)
        item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = reaper.GetActiveTake(item)
        return item, take
    elseif CreateMIDIMode.norm_val == 2 then
        -- Use selected item(mode 3) ----------------
        midi_track = reaper.GetSelectedTrack(0, 0)
        if not midi_track or midi_track == self.track then
            return
        end -- if no sel track or sel track==self.track
        item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = reaper.GetActiveTake(item)
        return item, take
    elseif CreateMIDIMode.norm_val == 3 then
        item = reaper.GetSelectedMediaItem(0, 0)
        if item then
            take = reaper.GetActiveTake(item)
        end
        if take and reaper.TakeIsMIDI(take) then
            local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
            local findpitch = 35 + OutNote.norm_val -- from checkbox
            local note = 0
            -- Del old notes with same pith --
            for i = 1, notecnt do
                local ret, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
                if pitch == findpitch then
                    reaper.MIDI_DeleteNote(take, note)
                    note = note - 1 -- del note witch findpitch and update counter
                end
                note = note + 1
            end
            reaper.MIDI_Sort(take)
            reaper.UpdateItemInProject(item)
            return item, take
        end
    end
end

function Wave:Slice_RX()
    local cursorpos = reaper.GetCursorPosition()

    AutoCrossFade = 40041
    AutoCrossFade_State = reaper.GetToggleCommandState(AutoCrossFade)
    wason = 0
    if (AutoCrossFade_State == 1) then
        reaper.Main_OnCommand(AutoCrossFade, 0)
        wason = 1
    end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    -------------------------------------------
    lastitem = reaper.GetExtState("MyDaw", "ItemToSlice")

    item = GuidToItem(lastitem)
    if item then
        sourcetrack = reaper.GetMediaItem_Track(item)

        insertidx = reaper.GetMediaTrackInfo_Value(sourcetrack, "IP_TRACKNUMBER")

        reaper.InsertTrackAtIndex(insertidx, true)
        local temptrack = reaper.GetTrack(0, insertidx)

        tempguid = reaper.GetTrackGUID(temptrack)

        reaper.DeleteExtState("MyDaw", "TrackForSlice", 0)
        reaper.SetExtState("MyDaw", "TrackForSlice", tempguid, 0)

        reaper.SetMediaItemSelected(item, 1)

        reaper.Main_OnCommand(40118, 0) ----move item down

        reaper.SetMediaItemSelected(item, 1)

        if (Guides.norm_val == 1) then
            local startppqpos, next_startppqpos
            ----------------------------
            local points_cnt = #Gate_Gl.Res_Points
            for i = 1, points_cnt, 2 do
                startppqpos = (self.sel_start + Gate_Gl.Res_Points[i] / srate)
                if i < points_cnt - 2 then
                    next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i + 2] / srate)
                end
                cutpos = (next_startppqpos - 0.002)

                reaper.SetEditCurPos(cutpos, 0, 0)

                reaper.Main_OnCommand(40757, 0) ---split

                ----------------------------
            end
        else
            for i = 1, #Grid_Points do
                reaper.SetEditCurPos(Grid_Points[i] / srate, 0, 0)

                reaper.Main_OnCommand(40757, 0) ---split

                ----------------------------

                ----------------------------
            end
        end
    end

    reaper.Main_OnCommand(40652, 0) -----rate to 1.0

    --------------------------------------------PREPARE SLICES------------------------------------
    ---------------------------------------------------------------------------------------------
    --

    reaper.Main_OnCommand(40297, 0) ---unselect all tracks

    guidetrack = reaper.GetExtState("MyDaw", "TrackForSlice")

    temptrack = reaper.GetTrackGUID(guidetrack)

    reaper.SetTrackSelected(temptrack, 1)

    for i = 0, reaper.GetTrackNumMediaItems(temptrack) do
        local item = reaper.GetTrackMediaItem(temptrack, i)

        if item then
            reaper.SelectAllMediaItems(0, false)

           
           reaper.GetSetMediaItemInfo_String( item, "P_EXT", "firstcut", true )
            
            
            
           -- reaper.ULT_SetMediaItemNote(item, "firstcut")

            reaper.SetMediaItemSelected(item, true)

            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            posend = pos + len

            reaper.ApplyNudge(
                0, --project,
                0,
                 --nudgeflag,
                5,
                 --nudgewhat,
                1,
                 --nudgeunits,
                len, --value,
                0,
                 --reverse,
                0
            )
             --copies

            reaper.Main_OnCommand(41051, 0) --reverse

            sitem = reaper.GetSelectedMediaItem(0, 0)
            sitemlen = reaper.GetMediaItemInfo_Value(sitem, "D_LENGTH")
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", sitemlen / 2)
            
            reaper.GetSetMediaItemInfo_String( item, "P_EXT", "secondcut", true )

           -- reaper.ULT_SetMediaItemNote(sitem, "secondcut")

            reaper.ApplyNudge(
                0, --project,
                0,
                 --nudgeflag,
                5,
                 --nudgewhat,
                1,
                 --nudgeunits,
                sitemlen / 2, --value,
                0,
                 --reverse,
                0
            )
             --copies

            reaper.Main_OnCommand(41051, 0) --reverse

            for i = 0, reaper.GetTrackNumMediaItems(temptrack) - 1 do
                local zitem = reaper.GetTrackMediaItem(temptrack, i)
                 
                 --if reaper.ULT_GetMediaItemNote(zitem) == "secondcut" or reaper.ULT_GetMediaItemNote(zitem) == "firstcut" then
               ret, res = reaper.GetSetMediaItemInfo_String(zitem, "P_EXT", "", false)
                if res == "secondcut" or res == "firstcut" then
                  
                    reaper.SetMediaItemSelected(zitem, true)
                end
            end

            reaper.Main_OnCommand(41588, 0) ----glue items
        end
    end

    for i = 0, reaper.GetTrackNumMediaItems(temptrack) do
        local item = reaper.GetTrackMediaItem(temptrack, i)

        if item then
            reaper.SetMediaItemSelected(item, true)
        end
    end

    loopitems = reaper.CountSelectedMediaItems(0)

    for i = 0, loopitems - 1 do
        litem = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(litem, "B_LOOPSRC", 0)
    end

    reaper.Main_OnCommand(40485, 0) ---Item properties: Set item timebase to beats (position only)

    reaper.Main_OnCommand(40921, 0) ---Item: Set item mix behavior to always replace

    reaper.Main_OnCommand(40796, 0) -----Item properties: Clear take preserve pitch

    ------------------unselelect LAST item-----------

    function Fn_Unselect_Last()
        local csi = reaper.CountSelectedMediaItems(0)
        if csi > 0 then
            reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, csi - 1), false)
            reaper.UpdateArrange()
        end
    end
    Fn_Unselect_Last()

    ------------------unselelect LAST item-----------

    reaper.Main_OnCommand(40612, 0)
     -----Item: Set items length to source media lengths

    --------------------FADE------------------

    items = reaper.CountSelectedMediaItems(0)

    for i = 0, items - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", len / 2)
        reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", 2)
    end

    -------------------------FADE-------------------

    ------------------selelect LAST item-----------

    for i = 0, reaper.GetTrackNumMediaItems(temptrack) - 1 do
        local mitem = reaper.GetTrackMediaItem(temptrack, i)

        mtitem_pos = reaper.GetMediaItemInfo_Value(mitem, "D_POSITION")
        local mtlen = reaper.GetMediaItemInfo_Value(mitem, "D_LENGTH")
        mtend = mtitem_pos + mtlen

        if mtend > self.sel_end then
            newlength = (self.sel_end - mtitem_pos)

            reaper.SetMediaItemInfo_Value(mitem, "D_LENGTH", newlength)
        end
    end

    for i = 0, reaper.GetTrackNumMediaItems(temptrack) do
        local item = reaper.GetTrackMediaItem(temptrack, i)

        if item then
            reaper.SetMediaItemSelected(item, true)
        end
    end

    reaper.Main_OnCommand(40117, 0) ---move items back

    reaper.DeleteTrack(temptrack)

    reaper.Main_OnCommand(41996, 0) ---move to subproject

    reaper.Main_OnCommand(41816, 0) ----Open project

    ------------------selelect LAST item-----------

    function Fn_Unselect_Last()
        reaper.Main_OnCommand(40296, 0) ----select all tracks

        reaper.SelectAllMediaItems(0, false)
        subtrack = reaper.GetSelectedTrack(0, 0)

        local csi = reaper.CountTrackMediaItems(subtrack)
        if csi > 0 then
            reaper.SetMediaItemSelected(reaper.GetTrackMediaItem(subtrack, csi - 1), true)
            reaper.UpdateArrange()
        end
    end
    Fn_Unselect_Last()

    ------------------selelect LAST item-----------

    reaper.Main_OnCommand(40612, 0)
     -----Item: Set items length to source media lengths

    reaper.Main_SaveProject(0, 0) ---------------Save PROJECT

    reaper.Main_OnCommand(40860, 0) -------Close Project

    reaper.Main_OnCommand(40485, 0) ---Item properties: Set item timebase to beats (position only)

    ----------------------------------------END_PREPARE---SLICES

    if (wason == 1) then
        reaper.Main_OnCommand(AutoCrossFade, 0)
    end
    reaper.SetEditCurPos(cursorpos, 0, 0)

    reaper.PreventUIRefresh(-1)

    -------------------------------------------
    reaper.Undo_EndBlock("Slice RX", -1)
end

function Wave:Just_Slice()
    local cursorpos = reaper.GetCursorPosition()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    -------------------------------------------
    lastitem = reaper.GetExtState("MyDaw", "ItemToSlice")

    item = GuidToItem(lastitem)
    if item then
        reaper.SetMediaItemSelected(item, 1)

        if (Guides.norm_val == 1) then
            local startppqpos, next_startppqpos
            ----------------------------
            local points_cnt = #Gate_Gl.Res_Points
            for i = 1, points_cnt, 2 do
                startppqpos = (self.sel_start + Gate_Gl.Res_Points[i] / srate)
                if i < points_cnt - 2 then
                    next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i + 2] / srate)
                end
                cutpos = (next_startppqpos - 0.002)

                reaper.SetEditCurPos(cutpos, 0, 0)

                reaper.Main_OnCommand(40757, 0) ---split

                ----------------------------
            end
        else
            for i = 1, #Grid_Points do
                reaper.SetEditCurPos(Grid_Points[i] / srate, 0, 0)

                reaper.Main_OnCommand(40757, 0) ---split

                ----------------------------
            end
        end
    end

    reaper.SetEditCurPos(cursorpos, 0, 0)
    reaper.PreventUIRefresh(-1)

    -------------------------------------------
    reaper.Undo_EndBlock("Slice", -1)
end

function Wave:Add_Markers()
    local cursorpos = reaper.GetCursorPosition()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    -------------------------------------------
    lastitem = reaper.GetExtState("MyDaw", "ItemToSlice")

    item = GuidToItem(lastitem)
    if item then
        reaper.SetMediaItemSelected(item, 1)

        if (Guides.norm_val == 1) then
            local startppqpos, next_startppqpos
            ----------------------------
            local points_cnt = #Gate_Gl.Res_Points
            for i = 1, points_cnt, 2 do
                startppqpos = (self.sel_start + Gate_Gl.Res_Points[i] / srate)
                if i < points_cnt - 2 then
                    next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i + 2] / srate)
                end
                cutpos = (next_startppqpos - 0.002)

                reaper.SetEditCurPos(cutpos, 0, 0)

                reaper.Main_OnCommand(41842, 0) ---Add MArker

                ----------------------------
            end
        else
            for i = 1, #Grid_Points do
                reaper.SetEditCurPos(Grid_Points[i] / srate, 0, 0)

                reaper.Main_OnCommand(41842, 0) ---Add MArker

                ----------------------------
            end
        end
    end

    reaper.SetEditCurPos(cursorpos, 0, 0)
    reaper.PreventUIRefresh(-1)

    -------------------------------------------
    reaper.Undo_EndBlock("Add Markers", -1)
end

function Wave:Load_To_Sampler(sel_start, sel_end, track)
    ItemState = reaper.GetExtState("MyDaw", "GetItemState")

    if (ItemState == "ItemLoaded") then
        reaper.SelectAllMediaItems(0, 0)

        reaper.Main_OnCommand(40297, 0) ----unselect all tracks

        lastitem = reaper.GetExtState("MyDaw", "ItemToSlice")

        item = GuidToItem(lastitem)

        track = reaper.GetMediaItem_Track(item)

        reaper.GetSet_LoopTimeRange2(0, 1, 0, self.sel_start, self.sel_end, 0)

        reaper.SetTrackSelected(track, 1)

        reaper.Main_OnCommand(40718, 0)
         ----Select all items on selected tracks in currient time selection

        reaper.Main_OnCommand(40635, 0) ---Remove Time selection
    elseif not (ItemState == "ItemLoaded") then
        self.sel_start = sel_start
        self.sel_end = sel_end
    end

    data = {}

    data.parent_track = track

    obeynoteoff_default = 1

    function ExportItemToRS5K_defaults(data, conf, refresh, note, filepath, start_offs, end_offs, track)
        local rs5k_pos = reaper.TrackFX_AddByName(track, "ReaSamplomatic5000", false, -1)
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filepath)
        reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE", "")
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 2, 0) -- gain for min vel
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 3, note / 127) -- note range start
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 4, note / 127) -- note range end
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 5, 0.5) -- pitch for start
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 6, 0.5) -- pitch for end
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 8, 0) -- max voices = 0
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 9, 0) -- attack
        reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 11, obeynoteoff_default) -- obey note offs
        if start_offs and end_offs then
            reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 13, start_offs) -- attack
            reaper.TrackFX_SetParamNormalized(track, rs5k_pos, 14, end_offs)
        end
    end

    function ExportItemToRS5K(data, conf, refresh, note, filepath, start_offs, end_offs)
        if not data.parent_track or not note or not filepath then
            return
        end

        local track = reaper.GetSelectedTrack(0, 0)
        if data[note] and data[note][1] then
            track = data[note][1].src_track
            if conf.allow_multiple_spls_per_pad == 0 then
                reaper.TrackFX_SetNamedConfigParm(track, data[note][1].rs5k_pos, "FILE0", filepath)
                reaper.TrackFX_SetNamedConfigParm(track, data[note][1].rs5k_pos, "DONE", "")
                return 1
            else
                ExportItemToRS5K_defaults(data, conf, refresh, note, filepath, start_offs, end_offs, track)
                return #data[note] + 1
            end
        else
            ExportItemToRS5K_defaults(data, conf, refresh, note, filepath, start_offs, end_offs, track)
            return 1
        end
    end

    function ExportSelItemsToRs5k_FormMIDItake_data()
        local MIDI = {}
        -- check for same track/get items info
        local item = reaper.GetSelectedMediaItem(0, 0)
        if not item then
            return
        end
        MIDI.it_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        MIDI.it_end_pos = MIDI.it_pos + 0.1
        local proceed_MIDI = true
        local it_tr0 = reaper.GetMediaItemTrack(item)
        for i = 1, reaper.CountSelectedMediaItems(0) do
            local item = reaper.GetSelectedMediaItem(0, i - 1)
            local it_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local it_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            MIDI[#MIDI + 1] = {pos = it_pos, end_pos = it_pos + it_len}
            MIDI.it_end_pos = it_pos + it_len
            local it_tr = reaper.GetMediaItemTrack(item)
            if it_tr ~= it_tr0 then
                proceed_MIDI = false
                break
            end
        end

        return proceed_MIDI, MIDI
    end
    -------------------------------------------------------------------------------
    function ExportSelItemsToRs5k_AddMIDI(track, MIDI, base_pitch)
        if not MIDI then
            return
        end
        local new_it = reaper.CreateNewMIDIItemInProj(track, MIDI.it_pos, self.sel_end --[[MIDI.it_end_pos]])
        new_tk = reaper.GetActiveTake(new_it)
        for i = 1, #MIDI do
            local startppqpos = reaper.MIDI_GetPPQPosFromProjTime(new_tk, MIDI[i].pos)
            local endppqpos = reaper.MIDI_GetPPQPosFromProjTime(new_tk, MIDI[i].end_pos)
            local ret =
                reaper.MIDI_InsertNote(
                new_tk,
                false, --selected,
                false, --muted,
                startppqpos,
                endppqpos,
                0,
                base_pitch + i - 1,
                100,
                true
            )
             --noSortInOptional )
            --if ret then reaper.ShowConsoleMsg('done') end
        end
        reaper.MIDI_Sort(new_tk)
        reaper.GetSetMediaItemTakeInfo_String(new_tk, "P_NAME", "sliced loop", 1)

        newmidiitem = reaper.GetMediaItemTake_Item(new_tk)

        reaper.SetMediaItemSelected(newmidiitem, 1)

        reaper.UpdateArrange()
    end

    function Load()
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)

        reaper.Main_OnCommand(40652, 0) ------reset rate
        -- track check
        local track = track
        if not track then
            return
        end
        -- item check
        local item = reaper.GetSelectedMediaItem(0, 0)
        if not item then
            return true
        end
        -- get base pitch

        base_pitch = 0
        -- get info for new midi take
        local proceed_MIDI, MIDI = ExportSelItemsToRs5k_FormMIDItake_data()
        -- export to RS5k
        for i = 1, reaper.CountSelectedMediaItems(0) do
            local item = reaper.GetSelectedMediaItem(0, i - 1)

            local take = reaper.GetActiveTake(item)

            reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1.0)

            local it_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            if not take or reaper.TakeIsMIDI(take) then
                goto skip_to_next_item
            end
            local tk_src = reaper.GetMediaItemTake_Source(take)
            local s_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local src_len = reaper.GetMediaSourceLength(tk_src)
            local filepath = reaper.GetMediaSourceFileName(tk_src, "")
            --msg(s_offs/src_len)
            ExportItemToRS5K(
                data,
                conf,
                refresh,
                base_pitch + i - 1,
                filepath,
                s_offs / src_len,
                (s_offs + it_len) / src_len
            )
            ::skip_to_next_item::
        end

        reaper.Main_OnCommand(40006, 0)
         --Item: Remove items
        -- add MIDI
        if proceed_MIDI then
            ExportSelItemsToRs5k_AddMIDI(track, MIDI, base_pitch)
        end

        reaper.PreventUIRefresh(-1)

        -------------------------------------------
        reaper.Undo_EndBlock("Export To Sampler", -1)
    end

    Load()
end

--------------------------------------------------------------------------------
---  Create MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает миди-ноты в соответствии с настройками и полученными из аудио данными
function Wave:Create_MIDI()
    reaper.Undo_BeginBlock()
    -------------------------------------------
    local item, take = Wave:GetSet_MIDITake()
    if not take then
        return
    end
    -- Velocity scale ----------
    local mode = VeloMode.norm_val
    local velo_scale = Gate_VeloScale.form_val2 - Gate_VeloScale.form_val
    local velo_offset = Gate_VeloScale.form_val
    -- Note parameters ---------
    local pitch = 35 + OutNote.norm_val -- pitch from checkbox
    local chan = NoteChannel.norm_val - 1 -- midi channel from checkbox
    local len = defPPQ / NoteLenghth.norm_val -- note lenght(its always use def ppq(960)!)
    local sel, mute = 1, 0
    local startppqpos, endppqpos, vel, next_startppqpos
    ----------------------------
    local points_cnt = #Gate_Gl.Res_Points
    for i = 1, points_cnt, 2 do
        startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i] / srate)
        endppqpos = startppqpos + len
        -- По идее,нет смысла по два раза считать,можно просто ставить предыдущую - переделать! --
        if i < points_cnt - 2 then
            next_startppqpos =
                reaper.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i + 2] / srate)
            -- С учетом точек добавленных вручную(но, по хорошему, их надо было добавлять не в конец таблицы, а между текущими) --
            if next_startppqpos > startppqpos then
                endppqpos = min(endppqpos, next_startppqpos)
            end -- del overlaps
        end
        -- Insert Note ---------
        vel = floor(velo_offset + Gate_Gl.Res_Points[i + 1][mode] * velo_scale)

        reaper.MIDI_InsertNote(take, sel, mute, startppqpos, endppqpos, chan, pitch, vel, true)
    end
    ----------------------------
    reaper.MIDI_Sort(take) -- sort notes
    reaper.UpdateItemInProject(item) -- update item
    -------------------------------------------
    reaper.Undo_EndBlock("Create Trigger MIDI", -1)
end

--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then
        local retval, item_to_slice = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)

        reaper.DeleteExtState("MyDaw", "ItemToSlice", 0)
        reaper.SetExtState("MyDaw", "ItemToSlice", item_to_slice, 0)
        reaper.SetExtState("MyDaw", "GetItemState", "ItemLoaded", 0)
        local tk = reaper.GetActiveTake(item)
        if tk then
            reaper.GetMediaItemTake_Track(tk)

            self.track = reaper.GetMediaItemTake_Track(tk)
            if self.track then
                self.AA = reaper.CreateTrackAudioAccessor(self.track)

                self.AA_Hash = reaper.GetAudioAccessorHash(self.AA, "")
                self.AA_start = reaper.GetAudioAccessorStartTime(self.AA)
                self.AA_end = reaper.GetAudioAccessorEndTime(self.AA)
                self.buffer = reaper.new_array(block_size)
                 -- main block-buffer
                self.buffer.clear()
                return true
            end
        end
    end
end

--------
function Wave:Validate_Accessor()
    if self.AA then
        if not reaper.AudioAccessorValidateState(self.AA) then
            return true
        end
    end
end
--------
function Wave:Destroy_Track_Accessor()
    --if (getitem ==0) then
    if self.AA then
        reaper.DestroyAudioAccessor(self.AA)
        self.buffer.clear()
    end
    -- end
end

--------
function Wave:Get_TimeSelection()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then
        local sel_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local sel_end = sel_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        local sel_len = sel_end - sel_start
        if sel_len < 0.25 then
            return
        end -- 0.25 minimum
        --------------
        self.sel_start, self.sel_end, self.sel_len = sel_start, sel_end, sel_len -- selection start, end, lenght
        return true
    end
end

----------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------
-- Filter_FFT ----------------------------------------------
------------------------------------------------------------
function Wave:Filter_FFT(lowband, hiband)
    local buf = self.buffer
    ----------------------------------------
    -- Filter(use fft_real) ----------------
    ----------------------------------------
    buf.fft_real(block_size, true) -- FFT
    -----------------------------
    -- Clear lowband bins --
    buf.clear(0, 1, lowband) -- clear low bins
    -- Clear hiband bins  --
    buf.clear(0, hiband + 1, block_size - hiband) -- clear hi bins
    -----------------------------
    buf.ifft_real(block_size, true) -- iFFT
    ----------------------------------------
end

--------------------------------------------------------------------------------------------
--- DRAW -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered -----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw()
    local x, y, w, h = self.def_xywh[1], self.def_xywh[2], self.def_xywh[3], self.def_xywh[4]
    ---------------
    gfx.dest = 1 -- set dest gfx buffer1
    gfx.a = 1 -- gfx.a - for buf
    gfx.setimgdim(1, -1, -1) -- clear buf1(Wave)
    gfx.setimgdim(1, w, h) -- set gfx buffer w,h
    ---------------
    if ViewMode.norm_val == 1 then
        self:draw_waveform(1, 0.3, 0.4, 0.7, 1) -- Draw Original(1, r,g,b,a)
        self:draw_waveform(2, 0.7, 0.1, 0.3, 1) -- Draw Filtered(2, r,g,b,a)
    elseif ViewMode.norm_val == 2 then
        self:draw_waveform(1, 0.3, 0.4, 0.7, 1) -- Only original
    elseif ViewMode.norm_val == 3 then
        self:draw_waveform(2, 0.7, 0.1, 0.3, 1) -- Only filtered
    end
    ---------------
    gfx.dest = -1 -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r, g, b, a)
    local Peak_TB, Ysc
    local Y = self.Y
    ----------------------------
    if mode == 1 then
        Peak_TB = self.in_peaks
        Ysc = self.Y_scale * self.vertZoom
    end
    if mode == 2 then
        Peak_TB = self.out_peaks
        -- Its not real Gain - но это обязательно учитывать в дальнейшем, экономит время...
        local fltr_gain = 10 ^ (Fltr_Gain.form_val / 20) -- from Fltr_Gain Sldr!
        Ysc = self.Y_scale * (0.5 / block_size) * fltr_gain * self.vertZoom -- Y_scale for filtered waveform drawing
    end
    ----------------------------
    ----------------------------
    local w = self.def_xywh[3] -- 1024 = def width
    local Zfact = self.max_Zoom / self.Zoom -- zoom factor
    local Ppos = self.Pos * self.max_Zoom -- старт. позиция в "мелкой"-Peak_TB для начала прорисовки
    local curr = ceil(Ppos + 1) -- округление
    local n_Peaks = w * self.max_Zoom -- Макс. доступное кол-во пиков
    gfx.set(r, g, b, a) -- set color
    -- уточнить, нужно сделать исправление для неориг. размера окна --
    -- next выходит за w*max_Zoom, а должен - макс. w*max_Zoom(51200) при max_Zoom=50 --
    for i = 1, w do
        local next = min(i * Zfact + Ppos, n_Peaks) -- грубоватое исправление...
        local min_peak, max_peak, peak = 0, 0, 0
        for p = curr, next do
            peak = Peak_TB[p][1]
            min_peak = min(min_peak, peak)
            peak = Peak_TB[p][2]
            max_peak = max(max_peak, peak)
        end
        curr = ceil(next)
        local y, y2 = Y - min_peak * Ysc, Y - max_peak * Ysc
        gfx.line(i, y, i, y2) -- здесь всегда x=i
    end
    ----------------------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode) -- mode = 1 for oriinal, mode = 2 for filtered
    local buf
    if mode == 1 then
        buf = self.in_buf -- for input(original)
    else
        buf = self.out_buf -- for output(filtered)
    end
    ----------------------------
    ----------------------------
    local Peak_TB = {}
    local w = self.def_xywh[3] -- 1024 = def width
    local pix_dens = self.pix_dens
    local smpl_inpix = (self.selSamples / w) / self.max_Zoom -- кол-во семплов на один пик(при макс. зуме!)
    -- норм --------------------
    local curr = 1
    for i = 1, w * self.max_Zoom do
        local next = i * smpl_inpix
        local min_smpl, max_smpl, smpl = 0, 0, 0
        for s = curr, next, pix_dens do
            smpl = buf[s]
            min_smpl = min(min_smpl, smpl)
            max_smpl = max(max_smpl, smpl)
        end
        Peak_TB[#Peak_TB + 1] = {min_smpl, max_smpl} -- min, max val to table
        curr = ceil(next)
    end
    ----------------------------
    if mode == 1 then
        self.in_peaks = Peak_TB
    else
        self.out_peaks = Peak_TB
    end
    ----------------------------
end

------------------------------------------------------------------------------------------------------------------------
-- WAVE - (Get samples(in_buf) > filtering > to out-buf > Create in, out peaks ) ---------------------------------------
------------------------------------------------------------------------------------------------------------------------
-------
function Wave:table_plus(mode, size, tmp_buf)
    local buf
    if mode == 1 then
        buf = self.in_buf
    else
        buf = self.out_buf
    end
    local j = 1
    for i = size + 1, size + #tmp_buf, 1 do
        buf[i] = tmp_buf[j]
        j = j + 1
    end
end
--------------------------------------------------------------------------------
-- Wave:Set_Values() - set main values, cordinates etc -------------------------
--------------------------------------------------------------------------------
function Wave:Set_Values()
    -- gfx buffer always used default Wave coordinates! --
    local x, y, w, h = self.def_xywh[1], self.def_xywh[2], self.def_xywh[3], self.def_xywh[4]
    -- Get Selection ----------------
    if not self:Get_TimeSelection() then
        return
    end -- Get time sel start,end,lenght
    ---------------------------------
    -- Calculate some values --------
    self.sel_len = min(self.sel_len, time_limit) -- limit lenght(deliberate restriction)
    self.selSamples = floor(self.sel_len * srate) -- time selection lenght to samples
    -- init Horizontal --------------
    self.max_Zoom = 50 -- maximum zoom level(желательно ок.150-200,но зав. от длины выдел.(нужно поправить в созд. пиков!))
    self.Zoom = self.Zoom or 1 -- init Zoom
    self.Pos = self.Pos or 0 -- init src position
    -- init Vertical ----------------
    self.max_vertZoom = 6 -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1 -- init vertical Zoom
    ---------------------------------
    -- pix_dens - нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 2 ^ (DrawMode.norm_val - 1) -- 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд.
    self.X, self.Y = x, h / 2 -- waveform position(X,Y axis)
    self.X_scale = w / self.selSamples -- X_scale = w/lenght in samples
    self.Y_scale = h / 2 -- Y_scale for waveform drawing
    ---------------------------------
    -- Some other values ------------
    self.crsx = block_size / 8 -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
    self.Xblock = block_size - self.crsx * 2 -- active part of full block(use mid-part of each block)
    -----------
    local max_size = 2 ^ 22 - 1 -- Макс. доступно(при создании из таблицы можно больше, но...)
    local div_fact = self.Xblock -- Размеры полн. и ост. буфера здесь всегда должны быть кратны Xblock --
    self.full_buf_sz = (max_size // div_fact) * div_fact -- размер полного буфера с учетом кратности div_fact
    self.n_Full_Bufs = self.selSamples // self.full_buf_sz -- кол-во полных буферов в выделении
    self.n_XBlocks_FB = self.full_buf_sz / div_fact -- кол-во X-блоков в полном буфере
    -----------
    local rest_smpls = self.selSamples - self.n_Full_Bufs * self.full_buf_sz -- остаток семплов
    self.rest_buf_sz = ceil(rest_smpls / div_fact) * div_fact -- размер остаточного(окр. вверх для захв. полн. участка)
    self.n_XBlocks_RB = self.rest_buf_sz / div_fact -- кол-во X-блоков в остаточном буфере
    -------------
    return true
end

-----------------------------------
function Wave:Processing()
    local start_time = reaper.time_precise()
     --time test
    local info_str = "Processing ."
    -------------------------------
    -- Filter values --------------
    -------------------------------
    -- LP = HiFreq, HP = LowFreq --
    local Low_Freq, Hi_Freq = HP_Freq.form_val, LP_Freq.form_val
    local bin_freq = srate / (block_size * 2) -- freq step
    local lowband = Low_Freq / bin_freq -- low bin
    local hiband = Hi_Freq / bin_freq -- hi bin
    -- lowband, hiband to valid values(need even int) ------------
    lowband = floor(lowband / 2) * 2
    hiband = ceil(hiband / 2) * 2
    -------------------------------------------------------------------------
    -- Get Original(input) samples to in_buf >> to table >> create peaks ----
    -------------------------------------------------------------------------
    if not self.State then
        if not self:Set_Values() then
            return
        end -- set main values, coordinates etc
        ------------------------------------------------------
        ------------------------------------------------------
        local size
        local buf_start = self.sel_start
        for i = 1, self.n_Full_Bufs + 1 do
            if i > self.n_Full_Bufs then
                size = self.rest_buf_sz
            else
                size = self.full_buf_sz
            end
            local tmp_buf = reaper.new_array(size)
            reaper.GetAudioAccessorSamples(self.AA, srate, 1, buf_start, size, tmp_buf) -- orig samples to in_buf for drawing
            --------
            if i == 1 then
                self.in_buf = tmp_buf.table()
            else
                self:table_plus(1, (i - 1) * self.full_buf_sz, tmp_buf.table())
            end
            --------
            buf_start = buf_start + self.full_buf_sz / srate -- to next
            ------------------------
            info_str = info_str .. "."
            self:show_info(info_str .. ".") -- show info_str
        end
        self:Create_Peaks(1) -- Create_Peaks input(Original) wave peaks
        self.in_buf = nil -- входной больше не нужен
    end

    -------------------------------------------------------------------------
    -- Filtering >> samples to out_buf >> to table >> create peaks ----------
    -------------------------------------------------------------------------
    local size, n_XBlocks
    local buf_start = self.sel_start
    for i = 1, self.n_Full_Bufs + 1 do
        if i > self.n_Full_Bufs then
            size, n_XBlocks = self.rest_buf_sz, self.n_XBlocks_RB
        else
            size, n_XBlocks = self.full_buf_sz, self.n_XBlocks_FB
        end
        ------
        local tmp_buf = reaper.new_array(size)
        ---------------------------------------------------------
        local block_start = buf_start - (self.crsx / srate) -- first block in current buf start(regard crsx)
        for block = 1, n_XBlocks do
            reaper.GetAudioAccessorSamples(self.AA, srate, 1, block_start, block_size, self.buffer)
            --------------------
            self:Filter_FFT(lowband, hiband) -- Filter(note: don't use out of range freq!)
            tmp_buf.copy(self.buffer, self.crsx + 1, self.Xblock, (block - 1) * self.Xblock + 1) -- copy block to out_buf with offset
            --------------------
            block_start = block_start + self.Xblock / srate -- next block start_time
        end
        ---------------------------------------------------------
        if i == 1 then
            self.out_buf = tmp_buf.table()
        else
            self:table_plus(2, (i - 1) * self.full_buf_sz, tmp_buf.table())
        end
        --------
        buf_start = buf_start + (self.full_buf_sz / srate) -- to next
        ------------------------
        info_str = info_str .. "."
        self:show_info(info_str .. ".") -- show info_str
    end
    -------------------------------------------------------------------------
    self:Create_Peaks(2) -- Create_Peaks output(Filtered) wave peaks
    -------------------------------------------------------------------------
    -------------------------------------------------------------------------
    self.State = true -- Change State
    -------------------------
    --reaper.ShowConsoleMsg("Filter time = " .. reaper.time_precise()-start_time .. '\n')--time test
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor()
    local E_Curs = reaper.GetCursorPosition()
    --- edit cursor ---
    local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
    self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom * Z_w -- Edit cursor
    if self.Ecx >= 0 and self.Ecx <= self.w then
        gfx.set(0.7, 0.7, 0.7, 1)
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y + self.h - 1)
    end
    --- play cursor ---
    if reaper.GetPlayState() & 1 == 1 then
        local P_Curs = reaper.GetPlayPosition()
        local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
        self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom * Z_w -- Play cursor
        if self.Pcx >= 0 and self.Pcx <= self.w then
            gfx.set(0.5, 0.5, 0.5, 1)
            gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y + self.h - 1)
        end
    --------------------------------------------
    -- Auto-scroll(Test Only !!!) --

    --------------------------------------------
    --[[
    
      --var1--
     if self.Pcx > self.w then 
     self.Pos = self.Pos + self.w/(self.Zoom*Z_w)
     self.Pos = math.max(self.Pos, 0)
     self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
     Wave:Redraw()
     end --]]
    --[[
     if (self.Pcx-512)>20 then 
     self.Pos = self.Pos + 20/(self.Zoom*Z_w)
     self.Pos = math.max(self.Pos, 0)
     self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
     Wave:Redraw()
     end --]]
    --------------------------------------------
    --------------------------------------------
    end
end
--------------------------
function Wave:Set_Cursor()
    if self:mouseDown() and not (Ctrl or Shift) then
        if self.insrc_mx then
            local New_Pos = self.sel_start + (self.insrc_mx / self.X_scale) / srate
            reaper.SetEditCurPos(New_Pos, false, true) -- true-seekplay(false-no seekplay)
        end
    end
end
----------------------------------------------------------------------------------------------------
---  Wave - Get Mouse  -----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Mouse()
    -----------------------------
    self.insrc_mx = self.Pos + (gfx.mouse_x - self.x) / (self.Zoom * Z_w) -- its current mouse position in source!
    -----------------------------
    --- Wave get-set Cursors ----
    self:Get_Cursor()
    self:Set_Cursor()
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel ~= 0 and not (Ctrl or Shift) then
        M_Wheel = gfx.mouse_wheel
        -------------------
        if M_Wheel > 0 then
            self.Zoom = min(self.Zoom * 1.25, self.max_Zoom)
        elseif M_Wheel < 0 then
            self.Zoom = max(self.Zoom * 0.75, 1)
        end
        -- correction Wave Position from src --
        self.Pos = self.insrc_mx - (gfx.mouse_x - self.x) / (self.Zoom * Z_w)
        self.Pos = max(self.Pos, 0)
        self.Pos = min(self.Pos, (self.w - self.w / self.Zoom) / Z_w)
        -------------------
        Wave:Redraw() -- redraw after horizontal zoom
    end
    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and Shift and gfx.mouse_wheel ~= 0 and not Ctrl then
        M_Wheel = gfx.mouse_wheel
        -------------------
        if M_Wheel > 0 then
            self.vertZoom = min(self.vertZoom * 1.2, self.max_vertZoom)
        elseif M_Wheel < 0 then
            self.vertZoom = max(self.vertZoom * 0.8, 1)
        end
        -------------------
        Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
    --- Wave Move ---------------------------
    if self:mouseM_Down() then
        self.Pos = self.Pos + (last_x - gfx.mouse_x) / (self.Zoom * Z_w)
        self.Pos = max(self.Pos, 0)
        self.Pos = min(self.Pos, (self.w - self.w / self.Zoom) / Z_w)
        --------------------
        Wave:Redraw() -- redraw after move view
    end
end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()
    self:update_xywh() -- update coord
    -- draw Wave frame, axis -------------
    self:draw_rect()
    gfx.set(0, 0, 0, 0.2) -- set color
    gfx.line(self.x, self.y + self.h / 2, self.x + self.w - 1, self.y + self.h / 2)
    self:draw_frame()
    -- Insert Wave from gfx buffer1 ------
    gfx.a = 1 -- gfx.a for blit
    local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values
    gfx.blit(1, 1, 0, 0, 0, srcw, srch, self.x, self.y, self.w, self.h)
    -- Get Mouse -------------------------
    self:Get_Mouse() -- get mouse(for zoom, move etc)
end

--------------------------------------------------------------------------------
---  Wave - show_help, info ----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
    local fnt_sz = 16
    fnt_sz = math.max(9, fnt_sz * (Z_w + Z_h) / 2)
    fnt_sz = math.min(20, fnt_sz)
    gfx.setfont(1, "Arial", fnt_sz)
    gfx.set(0, 0, 0, 0.7)
    gfx.x, gfx.y = self.x + 10, self.y + 10
    gfx.drawstr(
        [[
  Select item(maximum 180s).
  It is better to use not more than 60s item length.
  Press "Get Item" button.
  Use sliders for change detection setting.
  Ctrl + drag - fine tune.
  ----------------
  On Waveform Area:
  Mouswheel - Horizontal Zoom,
  Shift+Mouswheel - Vertical Zoom, 
  Middle drag - Move View(Scroll),
  Left click - Set Edit Cursor,
  Shift+Left drag - Move Marker,
  Ctrl+Left drag - Change Velocity,
  Shift+Ctrl+Left drag - Move Marker and Change Velocity,
  Right click on Marker - Delete Marker,
  Right click on Empty Space - Insert Marker,
  Space - Play. 
  ]]
    )
end

--------------------------------
function Wave:show_info(info_str)
    if self.State or self.sel_len < 15 then
        return
    end
    gfx.update()
    gfx.setfont(1, "Arial", 40)
    gfx.set(0.7, 0.7, 0.4, 1)
    gfx.x = self.x + self.w / 2 - 200
    gfx.y = self.y + (self.h) / 2
    gfx.drawstr(info_str)
    gfx.update()
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()
    if Project_Change() then
        --if not Wave:Validate_Accessor() then Wave.State = false end
        if not Wave:Verify_Project_State() then
            Wave.State = false
        end
    end
    -- Draw Wave, lines etc ------
    if Wave.State then
        --
        Wave:from_gfxBuffer() -- Wave from gfx buffer
        Gate_Gl:draw_Lines() -- Draw Gate trig-lines
    else
        Wave:show_help() -- else show help
    end
    -- Draw sldrs, btns etc ------
    draw_controls()
end

--------------------------------
-- Get Project Change ----------
--------------------------------
function Project_Change()
    local cur_cnt = reaper.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then
        proj_change_cnt = cur_cnt
        return true
    end
end
--------------------------------
-- Verify Project State --------
--------------------------------
-- проверяет только наличие трека, без проверки содержимого
-- нужно для маркеров и тп, допилить!
function Wave:Verify_Project_State() --
    if self.AA and reaper.ValidatePtr2(0, self.track, "MediaTrack*") then
        --local AA = reaper.CreateTrackAudioAccessor(self.track)
        --if self.AA_Hash == reaper.GetAudioAccessorHash(AA, "") then
        --reaper.DestroyAudioAccessor(AA) -- destroy temporary AA
        return true
    --end
    end
end
--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key, btn in pairs(Button_TB) do
        btn:draw()
    end

    if (Midi_Sampler.norm_val == 2) then
        for key, sldr in pairs(Slider_TB_Trigger) do
            sldr:draw()
        end
    else
        if (exept == 1) then
            for key, sldr in pairs(Exception) do
                sldr:draw()
            end
            exept = 0
        end
        for key, sldr in pairs(Slider_TB) do
            sldr:draw()
        end
    end

    for key, ch_box in pairs(CheckBox_TB) do
        ch_box:draw()
    end
    for key, frame in pairs(Frame_TB) do
        frame:draw()
    end
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R, G, B = 127, 127, 127 -- 0...255 format
    local Wnd_bgd = R + G * 256 + B * 65536 -- red+green*256+blue*65536
    local Wnd_Title = "MyDaw Slicer"
    local Wnd_Dock, Wnd_X, Wnd_Y = 1, 100, 320
    Wnd_W, Wnd_H = 1044, 490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd
    gfx.init(Wnd_Title, Wnd_W, Wnd_H, Wnd_Dock, Wnd_X, Wnd_Y)
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()
    -- zoom level --
    Z_w, Z_h = gfx.w / Wnd_W, gfx.h / Wnd_H
    if Z_w < 0.65 then
        Z_w = 0.65
    elseif Z_w > 1.8 then
        Z_w = 1.8
    end
    if Z_h < 0.65 then
        Z_h = 0.65
    elseif Z_h > 1.8 then
        Z_h = 1.8
    end
    -- mouse and modkeys --
    if
        gfx.mouse_cap & 1 == 1 and last_mouse_cap & 1 == 0 or -- L mouse
            gfx.mouse_cap & 2 == 2 and last_mouse_cap & 2 == 0 or -- R mouse
            gfx.mouse_cap & 64 == 64 and last_mouse_cap & 64 == 0
     then -- M mouse
        mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y
    end
    Ctrl = gfx.mouse_cap & 4 == 4 -- Ctrl  state
    Shift = gfx.mouse_cap & 8 == 8 -- Shift state
    Alt = gfx.mouse_cap & 16 == 16 -- Shift state

    -------------------------
    -- MAIN function --------
    -------------------------
    MAIN() -- main function
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset mouse_wheel
    local char = gfx.getchar()
    if char == 32 then
        reaper.Main_OnCommand(40044, 0)
    end -- play

    if char == 26 then
        reaper.Main_OnCommand(40029, 0)
    end ---undo

    if char ~= -1 then
        reaper.defer(mainloop) -- defer
    else
        --Wave:Destroy_Track_Accessor()
    end
    -----------
    gfx.update()
    -----------
end

function getitem()
    local start_time = reaper.time_precise()
    ---------------------
    Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
    Wave.State = false -- reset Wave.State
    if Wave:Create_Track_Accessor() then
        Wave:Processing()
        if Wave.State then
            Wave:Redraw()
            Gate_Gl:Apply_toFiltered()
        end
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------
--reaper.ClearConsole()
Init()
mainloop()

function TooSmall()
    local countselitems = reaper.CountSelectedMediaItems(0)

    if (countselitems > 0) then
        for i = 1, reaper.CountSelectedMediaItems(0) do
            local forgetitem = reaper.GetSelectedMediaItem(0, i - 1)

            GetLengtstart = reaper.GetMediaItemInfo_Value(forgetitem, "D_LENGTH")
        end

        if GetLengtstart > MinimumItem then
            getitem()
        end
    end
end

TooSmall()

function ClearExState()
    reaper.DeleteExtState("MyDaw", "ItemToSlice", 0)
    reaper.DeleteExtState("MyDaw", "TrackForSlice", 0)
    reaper.SetExtState("MyDaw", "GetItemState", "ItemNotLoaded", 0)
end

reaper.atexit(ClearExState)

