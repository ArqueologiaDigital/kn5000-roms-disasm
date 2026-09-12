-- distortion_ab.lua -- in-emulator A/B for the MAME HLE DISTORTION insert (DSPHLE == 15).
--
-- Question it answers: does the HLE AGC-waveshaper insert actually GENERATE HARMONICS
-- (the defining property of a distortion) versus the dry signal, using the DRIVE/VOLUME
-- gains the firmware computed for a real DISTORTION preset?
--
-- Method: navigate the DSP EFFECT page to DISTORTION (TYPE-selector 9) so the firmware
-- uploads the distortion coefficients the insert reads (C-RAM 0x00 DRIVE, 0x02 VOLUME); then
-- render every voice as a PURE SINE (TGMODE bit 0 = 1) so the baseline spectrum is a single
-- tone and a sustained C4 is held. The ONE variable between the two arms is DSPHLE (env DHLE):
--   DHLE=0   -> distortion insert OFF -> clean sine                     == control A
--   DHLE=15  -> distortion insert ON  -> tanh waveshaper adds harmonics == test B
-- DSPCFG=0 keeps the LLE send/return out of the mix, so only the HLE insert shows.
-- Audio is captured by MAME -wavwrite; compare with distortion_ab.py (harmonic energy).
--
-- Run (from ~/compartilhado/kn7000_mame_build, binary built -DKN5000_ENABLE_DSP1=1):
--   DISPLAY=:0 DHLE=15 timeout 160 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo \
--     -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/distortion_ab.lua \
--     -wavwrite /tmp/dist_B.wav
-- then again with DHLE=0 -> /tmp/dist_A.wav.
local DHLE    = tonumber(os.getenv("DHLE")    or "15")
local DSPCFG  = tonumber(os.getenv("DSPCFG")  or "0")    -- LLE send/return out of the mix
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "9")    -- 9 = DISTORTION (DSP EFFECT page)
local DRIVEUP = tonumber(os.getenv("DRIVEUP") or "20")   -- taps to raise the DRIVE knob
local mach = manager.machine

local function setport(tag, v)
  local d = mach.ioport.ports[tag]
  if d then for _, f in pairs(d.fields) do f.user_value = v end
  else emu.print_error("### NO PORT " .. tag) end
end
setport(":DSPCFG", DSPCFG)
setport(":DSPHLE", DHLE)
setport(":TGMODE", 1)        -- diagnostic SINE render: each voice is a pure sine

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end
local function keys(v)
  local p = mach.ioport.ports[":KEY2"]; if not p then return end
  for _, nm in ipairs({ "C4" }) do         -- a SINGLE note so the spectrum is one tone
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

add(0.0, function() emu.print_error(string.format("### distortion_ab DHLE=%d DSPCFG=%d TYPEIDX=%d DRIVEUP=%d (SINE)", DHLE, DSPCFG, TYPEIDX, DRIVEUP)) end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function() end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> CHORUS (idx 0)
add(1.2, function() end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to DISTORTION (idx 9)
add(1.5, function() emu.print_error("### LANDED (DISTORTION)") end)
-- move the cursor to the DRIVE parameter (first field) and raise it so the drive is audible
for _ = 1, DRIVEUP do tap("CPL_SEG10", 0x40, 0.06) end   -- value UP on the selected (DRIVE) field
add(1.0, function() emu.print_error("### DRIVE raised") end)
-- sustained single note for the spectrum
add(0.5, function() emu.print_error(string.format("### NOTE ON t=%.3f", mach.time.seconds)); keys(1) end)
add(3.5, function() emu.print_error("### NOTE OFF"); keys(0) end)
add(0.5, function() emu.print_error("### exiting"); mach:exit() end)

local phase, idx, next_t = 0, 1, nil
_G._n = emu.register_frame_done(function()
  local ok, e = pcall(function()
    local t = mach.time.seconds + mach.time.attoseconds / 1e18
    if phase == 0 then
      if t >= 19.0 then phase = 1; next_t = t + steps[1][1] end
      return
    end
    if next_t and t >= next_t then
      steps[idx][2]()
      idx = idx + 1
      if idx > #steps then _G._n = nil; return end
      next_t = t + steps[idx][1]
    end
  end)
  if not ok then emu.print_error("### LUA ERR " .. tostring(e)) end
end)
