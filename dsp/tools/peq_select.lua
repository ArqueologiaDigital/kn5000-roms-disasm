-- peq_select.lua -- select PARAMETRIC EQ (DSP EFFECT type 15) on the KN5000 panel
-- with the uPD6383 core LIVE, then play notes so the chip executes algo 39.
--
-- Navigation is MEASURED, taken verbatim from tools/kn5000_dsp_origincap.lua
-- (notes/kn5000-dsp-origin-capture.md, snapshot+RAM verified 2026-07-23):
--   SOUND menu = CPR_SEG10 0x04 ; DSP EFFECT editor = CPL_SEG7 0x02
--   TYPE up/down = CPL_SEG10 0x20 / 0x10 ; DSP EFFECT front-panel = CPR_SEG3 0x04
-- The TYPE list does NOT wrap, so saturate DOWN to index 0 (CHORUS) first.
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "15")   -- 15 = PARAMETRIC EQ
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
local function keys(v)
  local p = mach.ioport.ports[":KEY2"]; if not p then emu.print_error("### NO :KEY2"); return end
  for _, nm in ipairs({ "C4", "E4", "G4" }) do
    for k, f in pairs(p.fields) do
      if k == nm or f.name == nm then
        if v == 1 then f:set_value(1) else f:clear_value() end
      end
    end
  end
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
  emu.print_error(string.format("### %s title='%s' type=0x%02X cnt=%d idx=[%s]",
      tag, title(), sp:read_u8(0x8D38), cnt, s))
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end

add(0.0, function() emu.print_error("### boot settle done"); report("at boot") end)
add(0.4, function() setbtn("CPR_SEG3", 0x04, 1) end)          -- DSP EFFECT on
add(0.3, function() setbtn("CPR_SEG3", 0x04, 0); report("after DSP-EFFECT toggle") end)
add(0.8, function() setbtn("CPR_SEG10", 0x04, 1) end)         -- SOUND menu
add(0.4, function() setbtn("CPR_SEG10", 0x04, 0) end)
add(1.5, function() setbtn("CPL_SEG7", 0x02, 1) end)          -- DSP EFFECT editor
add(0.4, function() setbtn("CPL_SEG7", 0x02, 0) end)
add(1.5, function() report("editor opened"); mach.video:snapshot() end)
for _ = 1, 40 do                                              -- saturate DOWN -> CHORUS
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 1) end)
  add(0.08, function() setbtn("CPL_SEG10", 0x10, 0) end)
end
add(1.2, function() report("saturated DOWN -> CHORUS") end)
for _ = 1, TYPEIDX do                                         -- step UP to the target
  add(0.10, function() setbtn("CPL_SEG10", 0x20, 1) end)
  add(0.10, function() setbtn("CPL_SEG10", 0x20, 0) end)
end
add(1.5, function() report("LANDED ON TARGET"); mach.video:snapshot() end)
add(1.5, function()
  report("settled")
  emu.print_error(string.format("### PEQ-SELECTED-AT-TIME %.3f", mach.time.seconds))
end)
add(0.5, function() emu.print_error("### NOTES ON"); keys(1) end)
add(6.0, function() emu.print_error("### NOTES OFF"); keys(0) end)
add(2.0, function() emu.print_error("### exiting"); mach.video:snapshot(); mach:exit() end)

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
emu.print_error(string.format("### peq_select loaded TYPEIDX=%d steps=%d", TYPEIDX, #steps))
