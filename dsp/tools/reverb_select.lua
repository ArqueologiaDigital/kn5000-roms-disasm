-- reverb_select.lua -- §227 TASK 2: select a DIGITAL REVERB preset on the KN5000 panel
-- so the firmware re-uploads unit 1's coefficients, and the uC-IF capture
-- (kn5000_dsp1_upload.{bin,txt}, written into the CWD at exit) contains them.
--
-- WHY.  §226 measured the header's coefficient bank C-RAM[0x90..0xB4] INVARIANT across
-- an effect change -- but on ONE capture pair in which unit 1 (ROOM REVERB 1) did NOT
-- change.  The Sub CPU ROM's per-algorithm map says a reverb preset rewrites
-- C-RAM[0x9E..0xB2], and 0x9E/0x9F/0xA0 are INSIDE the header's own 0x90..0xA3 walk.
-- This capture decides it.  `python3 dsp/tools/hdrbase.py' scores the result.
--
-- Navigation is MEASURED (notes/kn5000-dsp-paramlist.md §1, and verbatim from
-- dsp/tools/peq_select.lua which is itself verbatim from tools/kn5000_dsp_origincap.lua):
--   SOUND menu   = CPR_SEG10 0x04
--   REVERB page  = RIGHT-2  = CPL_SEG8 0x02   -> editor page type 0x0A
--   TYPE up/down = CPL_SEG10 0x20 / 0x10      (the list does NOT wrap: saturate DOWN first)
--
-- The TYPE order on that page is ROOM 1, ROOM 2, PLATE 1, PLATE 2, CONCERT 1, CONCERT 2,
-- DARK 1, DARK 2, BRIGHT 1, BRIGHT 2, WAVE 1, WAVE 2, SINGLE DELAY, MULTI TAP DELAY.
--
-- Env:
--   REVIDX : index to land on after saturating DOWN.  0 = ROOM REVERB 1 = the cold-boot
--            default, which is the MATCHED CONTROL ARM: same navigation, no preset change.
local REVIDX = tonumber(os.getenv("REVIDX") or "4")   -- 4 = CONCERT REVERB 1
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

-- the core must be ON + SPECULATIVE, exactly as the DSP harness runs it
do local d = mach.ioport.ports[":DSPCFG"]
   if d then for _, f in pairs(d.fields) do f.user_value = 3 end
   else emu.print_error("### NO :DSPCFG PORT") end end

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end
local function title()
  local s = ""
  for i = 0, 17 do
    local c = sp:read_u8(0x30AE5 + i)
    s = s .. ((c >= 32 and c < 127) and string.char(c) or " ")
  end
  return (s:gsub("%s+$", ""))
end
local function report(tag)
  local cnt = sp:read_u8(0x29AA); local s = ""
  for i = 0, 12 do s = s .. sp:read_u8(0x29AC + i) .. (i < 12 and "," or "") end
  emu.print_error(string.format("### %s title='%s' page=0x%02X cnt=%d idx=[%s]",
      tag, title(), sp:read_u8(0x8D38), cnt, s))
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end

add(0.0, function() emu.print_error("### boot settle done"); report("at boot") end)
add(0.8, function() setbtn("CPR_SEG10", 0x04, 1) end)         -- SOUND menu
add(0.4, function() setbtn("CPR_SEG10", 0x04, 0) end)
add(1.5, function() setbtn("CPL_SEG8", 0x02, 1) end)          -- REVERB editor (RIGHT-2)
add(0.4, function() setbtn("CPL_SEG8", 0x02, 0) end)
add(1.5, function() report("reverb editor opened"); mach.video:snapshot() end)
for _ = 1, 40 do                                              -- saturate DOWN -> ROOM 1
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 1) end)
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 0) end)
end
add(1.2, function() report("saturated DOWN -> ROOM REVERB 1") end)
for _ = 1, REVIDX do                                          -- step UP to the target
  add(0.12, function() setbtn("CPL_SEG10", 0x20, 1) end)
  add(0.12, function() setbtn("CPL_SEG10", 0x20, 0) end)
end
add(1.5, function()
  report("LANDED ON TARGET")
  mach.video:snapshot()
  emu.print_error(string.format("### REVERB-SELECTED REVIDX=%d AT-TIME %.3f",
      REVIDX, mach.time.seconds))
end)
add(2.0, function() report("settled"); mach.video:snapshot() end)
add(0.5, function() emu.print_error("### exiting -> capture files flush"); mach:exit() end)

local phase, next_t = 0, nil
_G._n = emu.register_frame_done(function()
  local ok, e = pcall(function()
    local t = mach.time.seconds + mach.time.attoseconds / 1e18
    if phase == 0 then
      if t >= 19.0 then phase = 1; next_t = t + steps[1][1] end
      return
    end
    if next_t and t >= next_t then
      steps[phase][2]()
      phase = phase + 1
      if phase > #steps then next_t = nil else next_t = t + steps[phase][1] end
    end
  end)
  if not ok then emu.print_error("### CB ERR " .. tostring(e)) end
end)
emu.print_error(string.format("### reverb_select loaded REVIDX=%d steps=%d", REVIDX, #steps))
