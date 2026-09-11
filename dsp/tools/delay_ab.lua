-- delay_ab.lua -- in-emulator TEMPORAL A/B for the MAME HLE SINGLE-DELAY insert.
--
-- Navigates the DSP EFFECT page to SINGLE DELAY (TYPEIDX 7), then plays a SHORT note
-- followed by a long silence so the feedback echoes stand out in the envelope. Audio is
-- captured by MAME's -wavwrite; this script only drives the panel + keys.
--
-- The ONE variable between the two arms is the DSPHLE port (env DHLE):
--   DHLE=0  -> delay insert OFF (dry note, no echoes)        == control A
--   DHLE=2  -> delay insert ON  (bit 1)                       == test B
-- DSPCFG (env, default 0) keeps the LLE send/return out of the mix so only the HLE delay
-- shows; the firmware still uploads the descriptor + C-RAM the insert reads (the code
-- doubles the descriptor when DSPCFG bit 1 is off -- see kn5000_tonegen.cpp).
--
-- Run (from ~/compartilhado/kn7000_mame_build, binary built -DKN5000_ENABLE_DSP1=1):
--   DISPLAY=:0 DHLE=2 timeout 200 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo \
--     -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/delay_ab.lua \
--     -wavwrite /tmp/dly_B.wav
-- then again with DHLE=0 -> /tmp/dly_A.wav, and compare with delay_ab_echo.py.
local DHLE    = tonumber(os.getenv("DHLE")    or "2")
local DSPCFG  = tonumber(os.getenv("DSPCFG")  or "3")   -- bit1 => descriptor holds the true 44.1k count
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "7")     -- 7 = SINGLE DELAY (DSP EFFECT page)
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
local function tap(tag, mk, dt)
  add(dt, function() setbtn(tag, mk, 1) end)
  add(dt, function() setbtn(tag, mk, 0) end)
end

add(0.0, function() emu.print_error(string.format("### delay_ab DHLE=%d DSPCFG=%d TYPEIDX=%d", DHLE, DSPCFG, TYPEIDX)) end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function() end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> CHORUS (idx 0)
add(1.2, function() end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to SINGLE DELAY (idx 7)
add(1.5, function() emu.print_error("### LANDED (SINGLE DELAY)") end)
-- SHORT note then long silence, twice, so the echo train is unambiguous
add(0.5, function() emu.print_error(string.format("### PLUCK1 t=%.3f", mach.time.seconds)); keys(1) end)
add(0.20, function() keys(0) end)
add(2.60, function() emu.print_error(string.format("### PLUCK2 t=%.3f", mach.time.seconds)); keys(1) end)
add(0.20, function() keys(0) end)
add(2.60, function() emu.print_error("### exiting"); mach:exit() end)

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
emu.print_error(string.format("### delay_ab loaded DHLE=%d DSPCFG=%d TYPEIDX=%d steps=%d",
    DHLE, DSPCFG, TYPEIDX, #steps))
