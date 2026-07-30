-- type_enum.lua -- enumerate the KN5000 DSP EFFECT TYPE list AUTHORITATIVELY,
-- by walking it on the machine and reading the display at each stop.
--
-- WHY: §169 wants a vehicle whose LFO phase-accumulate block is 6 words from its
-- class-6 lookup (AUTO PAN / VIBRATO / FLANGER / RING MODULATOR) instead of
-- cold-boot CHORUS's 24.  Selecting one needs its TYPE index, and the index
-- CANNOT be derived from dsp/programs.tsv: that manifest lists DISTINCT PROGRAMS,
-- so every TYPE slot that reuses an already-listed program is missing from it.
-- Deriving it anyway puts PARAMETRIC EQ at 16 where peq_select.lua measured 15.
--
-- Navigation is MEASURED, taken verbatim from peq_select.lua / origin-capture.md:
--   SOUND menu = CPR_SEG10 0x04 ; DSP EFFECT editor = CPL_SEG7 0x02
--   TYPE up/down = CPL_SEG10 0x20 / 0x10 ; DSP EFFECT front-panel = CPR_SEG3 0x04
-- The list does NOT wrap, so saturate DOWN to index 0 first.
--
-- ★ CONTROL WITH A KNOWN ANSWER, and it can fail: index 0 must read CHORUS and
-- index 15 must read PARAMETRIC EQ.  Both were measured before this script
-- existed.  If either disagrees the walk is mis-stepping and the whole
-- enumeration is VOID -- do not "adjust" it to fit.
local NMAX = tonumber(os.getenv("NMAX") or "40")
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

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

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end

add(0.0, function() emu.print_error("### boot settle done") end)
add(0.4, function() setbtn("CPR_SEG3", 0x04, 1) end)
add(0.3, function() setbtn("CPR_SEG3", 0x04, 0) end)
add(0.8, function() setbtn("CPR_SEG10", 0x04, 1) end)
add(0.4, function() setbtn("CPR_SEG10", 0x04, 0) end)
add(1.5, function() setbtn("CPL_SEG7", 0x02, 1) end)
add(0.4, function() setbtn("CPL_SEG7", 0x02, 0) end)
add(1.5, function() emu.print_error("### editor opened, title='" .. title() .. "'") end)
for _ = 1, 40 do                                -- saturate DOWN -> index 0
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 1) end)
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 0) end)
end
add(1.2, function()
  emu.print_error(string.format("### TYPE %2d  type=0x%02X  '%s'", 0, sp:read_u8(0x8D38), title()))
end)
for i = 1, NMAX do                              -- one step UP, then read
  add(0.10, function() setbtn("CPL_SEG10", 0x20, 1) end)
  add(0.10, function() setbtn("CPL_SEG10", 0x20, 0) end)
  add(0.45, function()
    emu.print_error(string.format("### TYPE %2d  type=0x%02X  '%s'", i, sp:read_u8(0x8D38), title()))
  end)
end
add(1.0, function() emu.print_error("### done"); mach.video:snapshot(); mach:exit() end)

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
emu.print_error(string.format("### type_enum loaded NMAX=%d steps=%d", NMAX, #steps))
