-- type_select.lua -- select a DSP EFFECT by TYPE index RELIABLY, then play notes.
--
-- WHY THIS EXISTS (§193): peq_select.lua saturates DOWN to index 0 and then steps
-- UP `TYPEIDX' times at 0.10 s intervals.  That works at short distances --
-- TYPEIDX 8 was verified live as prog10_multi_tap_delay -- and DROPS STEPS at
-- long ones: TYPEIDX 28 and 30 both landed on prog72_peq_s_delay, one slot from
-- the target, and voided a whole f31 experiment.
--
-- FIX: the list has 36 entries (0..35, §170's map) and does NOT wrap.  Saturate
-- UP to the END instead, then step DOWN (35 - TYPEIDX) times.  For the PEQ combi
-- targets that turns 28-30 presses into 7 and 5 -- back inside the regime that
-- was verified to work.  Press intervals are also doubled.
--
-- ⚠ THIS DOES NOT REMOVE THE OBLIGATION TO VERIFY.  §193's standing requirement:
-- fingerprint the loaded program from kn5000_dsp1_upload.txt in the SAME run, and
-- copy that file into the run directory before the next launch overwrites it.
-- A transport that is merely *more* reliable is not a transport that is correct.
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "28")
-- ★★★ CALIBRATED 2026-09-13, and the old default was WRONG BY TWO.
-- The list has 38 entries (0..37), not 36.  MEASURED by fingerprinting the uploaded program
-- (dsp/tools/type_fingerprint.py) instead of trusting the panel text:
--     TYPELAST=35, TYPEIDX=0  -> prog03_enhancer      (wanted CHORUS)
--     TYPELAST=35, TYPEIDX=15 -> prog50_vibrato       (wanted PARAMETRIC EQ)
-- Both land exactly TWO slots high, which is what "saturate UP to 37 then step down (35 - N)"
-- does: 37 - (35 - N) = N + 2.  With LAST = 37 BOTH of the map's known-answer controls pass:
--     TYPELAST=37, TYPEIDX=0  -> prog01_chorus        ✅
--     TYPELAST=37, TYPEIDX=15 -> prog39_parametric_eq ✅
-- This is also the root of TYPE_MAP.md's documented off-by-one above index 8.
-- ⚠ THE OBLIGATION TO FINGERPRINT EVERY RUN STANDS.  A calibrated transport is still a
-- transport; type_fingerprint.py on kn5000_dsp1_upload.txt is what makes a run's identity a
-- measurement.  ⚠ This script prints to stdout/stderr, NOT error.log.
local LAST    = tonumber(os.getenv("TYPELAST") or "37")
local mach = manager.machine

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

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end

--  navigation, MEASURED (peq_select.lua / origin-capture.md):
--    DSP EFFECT front panel = CPR_SEG3 0x04 ; SOUND menu = CPR_SEG10 0x04
--    DSP EFFECT editor      = CPL_SEG7 0x02 ; TYPE up/down = CPL_SEG10 0x20 / 0x10
add(0.0, function() emu.print_error("### boot settle done") end)
add(0.4, function() setbtn("CPR_SEG3", 0x04, 1) end)
add(0.3, function() setbtn("CPR_SEG3", 0x04, 0) end)
add(0.8, function() setbtn("CPR_SEG10", 0x04, 1) end)
add(0.4, function() setbtn("CPR_SEG10", 0x04, 0) end)
add(1.5, function() setbtn("CPL_SEG7", 0x02, 1) end)
add(0.4, function() setbtn("CPL_SEG7", 0x02, 0) end)
add(1.5, function() emu.print_error("### editor opened") end)
for _ = 1, 45 do                      -- saturate UP to the END of the list
  add(0.16, function() setbtn("CPL_SEG10", 0x20, 1) end)
  add(0.16, function() setbtn("CPL_SEG10", 0x20, 0) end)
end
add(1.5, function() emu.print_error(string.format("### saturated UP -> TYPE %d", LAST)) end)
for _ = 1, (LAST - TYPEIDX) do        -- then a SHORT walk down to the target
  add(0.20, function() setbtn("CPL_SEG10", 0x10, 1) end)
  add(0.20, function() setbtn("CPL_SEG10", 0x10, 0) end)
end
add(2.0, function()
  emu.print_error(string.format("### LANDED: asked TYPE %d = %d DOWN from %d",
      TYPEIDX, LAST - TYPEIDX, LAST))
  mach.video:snapshot()
end)
add(0.5, function() emu.print_error("### NOTES ON"); keys(1) end)
add(6.0, function() emu.print_error("### NOTES OFF"); keys(0) end)
add(2.0, function() emu.print_error("### exiting"); mach:exit() end)

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
emu.print_error(string.format("### type_select TYPEIDX=%d LAST=%d steps=%d", TYPEIDX, LAST, #steps))
