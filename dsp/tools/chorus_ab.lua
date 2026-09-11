-- chorus_ab.lua -- in-emulator A/B for the MAME HLE CHORUS insert (single sustained note).
--
-- Navigates the DSP EFFECT page to CHORUS (TYPEIDX 0) and holds ONE note (C4) for 8 s, so
-- the LFO-rate modulation is not confounded by the beating of a multi-note chord (which the
-- 3-note eq_hle_ab.lua chord introduced). Audio captured by -wavwrite.
--
-- The ONE variable between arms is the DSPHLE port (env DHLE): 0 = chorus OFF (dry),
-- 3 = chorus ON. DSPCFG (env, default 2) gives the speculative descriptor with the LLE
-- return discarded, so only the HLE chorus shows.
--
-- Run (from ~/compartilhado/kn7000_mame_build):
--   DISPLAY=:0 DHLE=3 timeout 200 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo \
--     -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/chorus_ab.lua \
--     -wavwrite /tmp/cho_B.wav
-- then DHLE=0 -> /tmp/cho_A.wav, and compare with chorus_ab.py.
local DHLE    = tonumber(os.getenv("DHLE")    or "3")
local DSPCFG  = tonumber(os.getenv("DSPCFG")  or "2")
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "0")     -- 0 = CHORUS
local NPARAM  = tonumber(os.getenv("NPARAM") or "-1")     -- >=0 drives a panel PARAMETER (1 = LFO SPEED)
local NVALUE  = tonumber(os.getenv("NVALUE") or "0")      -- VALUE-up presses
local NOTE    = os.getenv("NOTE") or "C4"
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

local function setport(tag, v)
  local d = mach.ioport.ports[tag]
  if d then for _, f in pairs(d.fields) do f.user_value = v end
  else emu.print_error("### NO PORT " .. tag) end
end
setport(":DSPCFG", DSPCFG)
setport(":DSPHLE", DHLE)

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end
local function key(v)
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

add(0.0, function() emu.print_error(string.format("### chorus_ab DHLE=%d DSPCFG=%d note=%s", DHLE, DSPCFG, NOTE)) end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function() end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> CHORUS (idx 0)
add(1.2, function() end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to TYPEIDX (0 = stay on CHORUS)
add(1.5, function() emu.print_error("### LANDED (CHORUS)") end)
-- optionally drive a panel PARAMETER (e.g. LFO SPEED, NPARAM=1) before the note, to test
-- that the modulation rate scales with the knob
if NPARAM >= 0 and NVALUE > 0 then
  for _ = 1, NPARAM do tap("CPL_SEG8", 0x10, 0.30) end   -- PARAMETER up to the target
  add(1.0, function() emu.print_error(string.format("### PARAMETER moved to %d", NPARAM)) end)
  for _ = 1, NVALUE do tap("CPL_SEG7", 0x20, 0.10) end    -- VALUE up
  add(1.0, function() emu.print_error("### VALUE driven") end)
end
add(0.5, function() emu.print_error(string.format("### NOTE ON t=%.3f", mach.time.seconds)); key(1) end)
add(8.0, function() emu.print_error(string.format("### NOTE OFF t=%.3f", mach.time.seconds)); key(0) end)
add(1.5, function() emu.print_error("### exiting"); mach:exit() end)

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
emu.print_error(string.format("### chorus_ab loaded DHLE=%d steps=%d", DHLE, #steps))
