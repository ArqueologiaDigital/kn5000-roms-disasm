-- fx_ab.lua -- generic in-emulator A/B driver for the HLE effect-preview inserts.
--
-- Navigates the DSP EFFECT page to a chosen TYPE selector (so the firmware uploads that
-- effect's coefficients the insert reads), renders a PURE SINE (TGMODE) so the baseline is a
-- clean tone, and plays either a sustained note or a short pluck + tail. The ONE variable
-- between the two arms is the DSPHLE port (env DHLE); compare captures with fx_features.py.
--
-- Env:
--   DHLE     DSPHLE selector (0 = off = control arm; 0x10.. = the effect under test)
--   TYPEIDX  DSP EFFECT page type to navigate to (so real coefficients are uploaded)
--   DSPCFG   default 0 (keeps the LLE send/return out of the mix)
--   NOTEMODE 0 = sustained note (~3.5 s); 1 = short pluck (0.2 s) + long tail (for delays/reverb)
--   NOTE     note name in :KEY2 (default C4); set C6 etc. for high-band effects (exciter)
--
-- Run from ~/compartilhado/kn7000_mame_build (binary built -DKN5000_ENABLE_DSP1=1).
local DHLE     = tonumber(os.getenv("DHLE")     or "0")
local DSPCFG   = tonumber(os.getenv("DSPCFG")   or "0")
local TYPEIDX  = tonumber(os.getenv("TYPEIDX")  or "9")
local NOTEMODE = tonumber(os.getenv("NOTEMODE") or "0")
local NOTE     = os.getenv("NOTE") or "C4"
local TGM      = tonumber(os.getenv("TGM") or "1")   -- 1 = sine render (clean tone), 0 = real PCM
local mach = manager.machine

local function setport(tag, v)
  local d = mach.ioport.ports[tag]
  if d then for _, f in pairs(d.fields) do f.user_value = v end
  else emu.print_error("### NO PORT " .. tag) end
end
setport(":DSPCFG", DSPCFG)
setport(":DSPHLE", DHLE)
setport(":TGMODE", TGM)

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end
local function keys(v)
  local p = mach.ioport.ports[":KEY2"]; if not p then return end
  for k, f in pairs(p.fields) do
    if k == NOTE or f.name == NOTE then
      if v == 1 then f:set_value(1) else f:clear_value() end
    end
  end
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end
local function tap(tag, mk, dt)
  add(dt, function() setbtn(tag, mk, 1) end)
  add(dt, function() setbtn(tag, mk, 0) end)
end

add(0.0, function() emu.print_error(string.format("### fx_ab DHLE=%d TYPEIDX=%d NOTEMODE=%d NOTE=%s", DHLE, TYPEIDX, NOTEMODE, NOTE)) end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function() end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> CHORUS (idx 0)
add(1.2, function() end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to target type
add(1.5, function() emu.print_error("### LANDED") end)
if NOTEMODE == 0 then
  add(0.5, function() emu.print_error(string.format("### NOTE ON t=%.3f", mach.time.seconds)); keys(1) end)
  add(3.5, function() emu.print_error("### NOTE OFF"); keys(0) end)
  add(0.5, function() emu.print_error("### exiting"); mach:exit() end)
else
  add(0.5, function() emu.print_error(string.format("### PLUCK t=%.3f", mach.time.seconds)); keys(1) end)
  add(0.2, function() keys(0) end)
  add(3.5, function() emu.print_error("### exiting"); mach:exit() end)
end

local phase, idx, next_t = 0, 1, nil
_G._n = emu.register_frame_done(function()
  local ok, e = pcall(function()
    local t = mach.time.seconds + mach.time.attoseconds / 1e18
    if phase == 0 then
      if t >= 19.0 then phase = 1; next_t = t + steps[1][1] end
      return
    end
    if next_t and t >= next_t then
      steps[idx][2](); idx = idx + 1
      if idx > #steps then _G._n = nil; return end
      next_t = t + steps[idx][1]
    end
  end)
  if not ok then emu.print_error("### LUA ERR " .. tostring(e)) end
end)
