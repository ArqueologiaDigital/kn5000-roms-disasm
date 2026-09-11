-- reverb_select.lua -- select a DIGITAL REVERB (page type 0x0A, CPL_SEG8 0x02),
-- so the unit-1 reverb program actually runs.  Copy of peq_gain.lua with the editor
-- key changed from DSP EFFECT (CPL_SEG7 0x02, page 0x0B) to REVERB (CPL_SEG8 0x02,
-- page 0x0A -- 12 reverbs + 2 delays; see notes/kn5000-dsp-paramlist.md).  Pair with
-- UPD6383_REVSEED + UPD6383_REVSEED_ONCE for the impulse-decay test.  TYPEIDX picks
-- the reverb from the list (0 = first).
--
-- The loaded preset is FLAT (all five sections give 0.00 dB), which cannot tell a
-- correctly-decoded filter from a pass-through.  This moves one band so the target
-- response has a sharp localised feature at a KNOWN frequency.
--
-- MEASURED navigation (kn5000-dsp-origin-capture.md / -paramlist.md sect.1):
--   SOUND = CPR_SEG10 0x04 ; DSP EFFECT editor = CPL_SEG7 0x02 ; TYPE = CPL_SEG10 0x20/0x10
-- INFERRED, and this run is the test of it (-paramlist.md sect.1.3 names the three pairs
-- "TYPE / PARAMETER / VALUE" but only measured TYPE):
--   PARAMETER = UP-2/DOWN-2 = CPL_SEG10 0x80/0x40 ; VALUE = UP-3/DOWN-3 = CPL_SEG9 0x20/0x10
-- SELF-VALIDATING: if these are the right keys the live C-RAM section coefficients move
-- off flat.  If C-RAM comes back identical to the flat capture, the inference is refuted.
--
-- gain = 0.5*user - 12.0 dB (kn5000-dsp-biquad-coeffs.md sect.1.2), so 0 dB is user 24 and
-- +24 VALUE-up steps should saturate that band at +12.0 dB.
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "15")
local NPARAM  = tonumber(os.getenv("NPARAM") or "2")    -- PARAMETER-up presses (0=FC 1=Q 2=G?)
local NVALUE  = tonumber(os.getenv("NVALUE") or "24")   -- VALUE-up presses
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
local function keys(v)
  local p = mach.ioport.ports[":KEY2"]; if not p then return end
  for _, nm in ipairs({ "C4", "E4", "G4" }) do
    for k, f in pairs(p.fields) do
      if k == nm or f.name == nm then
        if v == 1 then f:set_value(1) else f:clear_value() end
      end
    end
  end
end
local function scr(a, n)
  local s = ""
  for i = 0, n - 1 do
    local c = sp:read_u8(a + i)
    s = s .. ((c >= 32 and c < 127) and string.char(c) or ".")
  end
  return s
end
local function report(tag)
  emu.print_error(string.format("### %s type=0x%02X cnt=%d lcd='%s'",
      tag, sp:read_u8(0x8D38), sp:read_u8(0x29AA), scr(0x30AE5, 40)))
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end
local function tap(tag, mk, dt)
  add(dt, function() setbtn(tag, mk, 1) end)
  add(dt, function() setbtn(tag, mk, 0) end)
end

add(0.0, function() emu.print_error("### boot settle done") end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG8", 0x02, 0.4)                               -- REVERB editor (page type 0x0A), NOT DSP EFFECT
add(1.5, function() report("reverb editor opened") end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> first reverb
add(1.2, function() report("saturated DOWN") end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to the chosen reverb (TYPEIDX in the reverb list)
add(1.5, function() report("LANDED ON REVERB"); mach.video:snapshot() end)
-- move the PARAMETER cursor, then drive the VALUE up
for _ = 1, NPARAM do tap("CPL_SEG8", 0x10, 0.30) end    -- PARAMETER up (UP-2)
add(1.2, function() report("PARAMETER moved"); mach.video:snapshot() end)
for _ = 1, NVALUE do tap("CPL_SEG7", 0x20, 0.10) end     -- VALUE up (UP-3)
add(1.5, function() report("VALUE driven UP"); mach.video:snapshot() end)
add(1.0, function()
  emu.print_error(string.format("### EQ-EDITED-AT-TIME %.3f  NPARAM=%d NVALUE=%d",
      mach.time.seconds, NPARAM, NVALUE))
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
emu.print_error(string.format("### peq_gain loaded TYPEIDX=%d NPARAM=%d NVALUE=%d steps=%d",
    TYPEIDX, NPARAM, NVALUE, #steps))
