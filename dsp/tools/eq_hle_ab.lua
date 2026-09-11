-- eq_hle_ab.lua -- in-emulator spectral A/B for the MAME audible-EQ insert.
--
-- Navigates to PARAMETRIC EQ, drives band-0 gain +12 dB (NVALUE=24), then plays a
-- C4/E4/G4 chord (RULE 12) so there is signal to filter.  The audio is captured by
-- MAME's own -wavwrite; this script only drives the panel and the keys.
--
-- The ONE variable between the A and B runs is the DSPHLE port (env EQHLE):
--   EQHLE=0  -> EQ insert bypassed  (dry mix)           == control A
--   EQHLE=1  -> EQ insert active    (RBJ from C-RAM)     == test B
-- DSPCFG is held at 0 in BOTH runs, so the LLE send/return adds nothing and cannot
-- contaminate the comparison; the firmware still streams the PEQ coefficients into the
-- effects-DSP C-RAM (that upload is independent of the MAME DSPCFG run-gate), which is
-- what the eq_hle insert reads.  B/A spectrum should then show ~+12 dB at ~673 Hz.
--
-- Run (from ~/compartilhado/kn7000_mame_build, binary built -DKN5000_ENABLE_DSP1=1):
--   DISPLAY=:0 EQHLE=1 timeout 300 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo \
--     -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/eq_hle_ab.lua \
--     -wavwrite /tmp/eq_B.wav
-- then again with EQHLE=0 -> /tmp/eq_A.wav, and compare with eq_hle_ab_fft.py.
local EQHLE  = tonumber(os.getenv("EQHLE")  or "1")
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "15")   -- steps UP from CHORUS to PEQ
local NPARAM  = tonumber(os.getenv("NPARAM") or "2")     -- 2 = gain (G)
local NVALUE  = tonumber(os.getenv("NVALUE") or "24")    -- +24 steps = +12.0 dB
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

local function setport(tag, v)
  local d = mach.ioport.ports[tag]
  if d then for _, f in pairs(d.fields) do f.user_value = v end
  else emu.print_error("### NO PORT " .. tag) end
end
setport(":DSPCFG", tonumber(os.getenv("DSPCFG") or "0"))  -- LLE gate (0 = nothing added but our EQ insert)
setport(":DSPHLE", EQHLE)      -- the one variable under test

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
  emu.print_error(string.format("### %s lcd='%s'", tag, scr(0x30AE5, 40)))
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end
local function tap(tag, mk, dt)
  add(dt, function() setbtn(tag, mk, 1) end)
  add(dt, function() setbtn(tag, mk, 0) end)
end

add(0.0, function() emu.print_error(string.format("### eq_hle_ab EQHLE=%d NVALUE=%d", EQHLE, NVALUE)) end)
tap("CPR_SEG3", 0x04, 0.35)                              -- DSP EFFECT on
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)                              -- SOUND menu
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function() report("editor opened") end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN -> CHORUS
add(1.2, function() report("saturated DOWN") end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to PARAMETRIC EQ
add(1.5, function() report("LANDED ON PEQ") end)
for _ = 1, NPARAM do tap("CPL_SEG8", 0x10, 0.30) end     -- PARAMETER up to gain
add(1.2, function() report("PARAMETER moved") end)
for _ = 1, NVALUE do tap("CPL_SEG7", 0x20, 0.10) end     -- VALUE up (+12 dB)
add(1.5, function() report("VALUE driven UP") end)
add(0.5, function() emu.print_error(string.format("### NOTES ON t=%.3f", mach.time.seconds)); keys(1) end)
add(8.0, function() emu.print_error(string.format("### NOTES OFF t=%.3f", mach.time.seconds)); keys(0) end)
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
emu.print_error(string.format("### eq_hle_ab loaded EQHLE=%d TYPEIDX=%d NVALUE=%d steps=%d",
    EQHLE, TYPEIDX, NVALUE, #steps))
