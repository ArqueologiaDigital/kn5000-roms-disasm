-- peq_cursor.lua -- find the PARAMETER cursor key on the DSP EFFECT editor, cleanly.
--
-- The earlier sweep was CONFOUNDED: each pair's restore-DOWN press happened between the
-- previous snapshot and the next pair's snapshot, so a cursor move seen after "PAIR 6 UP"
-- could equally have been caused by the preceding "PAIR 5 restore" (CPL_SEG8 0x10).
-- Here every single press gets its own snapshot and there are NO restores, so each image
-- is attributable to exactly one press.
--
-- MEASURED so far: VALUE-up = CPL_SEG7 0x20 (drove BAND EMPHASIS FC 125 Hz -> 16K Hz,
-- saturating the 27-entry ISO table, and moved ONLY section 0's coefficients).
-- The four CPL_SEG8 bits are the remaining candidates for the PARAMETER rocker.
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

do local d = mach.ioport.ports[":DSPCFG"]
   if d then for _, f in pairs(d.fields) do f.user_value = 3 end end end

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end

local steps = {}
local function add(dt, fn) steps[#steps + 1] = { dt, fn } end
local function tap(tag, mk, dt)
  add(dt, function() setbtn(tag, mk, 1) end)
  add(dt, function() setbtn(tag, mk, 0) end)
end

-- press these in order, ONE snapshot after each, no restores.  A long 0.30 s press in
-- case the earlier 0.14 s taps were simply too short to register.
local SEQ = {
  { "CPL_SEG8", 0x40, "SEG8 0x40 (DOWN 6)" },
  { "CPL_SEG8", 0x40, "SEG8 0x40 again" },
  { "CPL_SEG8", 0x80, "SEG8 0x80 (UP 6)" },
  { "CPL_SEG8", 0x10, "SEG8 0x10 (DOWN 5)" },
  { "CPL_SEG8", 0x10, "SEG8 0x10 again" },
  { "CPL_SEG8", 0x20, "SEG8 0x20 (UP 5)" },
  { "CPL_SEG9", 0x40, "SEG9 0x40 (DOWN 4)" },
  { "CPL_SEG9", 0x10, "SEG9 0x10 (DOWN 3)" },
}

add(0.0, function() emu.print_error("### boot settle done") end)
tap("CPR_SEG3", 0x04, 0.35)
add(0.8, function() end)
tap("CPR_SEG10", 0x04, 0.4)
add(1.5, function() end)
tap("CPL_SEG7", 0x02, 0.4)                                -- DSP EFFECT editor
add(1.5, function() end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end         -- saturate DOWN -> CHORUS
add(1.2, function() end)
for _ = 1, 15 do tap("CPL_SEG10", 0x20, 0.10) end         -- UP to PARAMETRIC EQ
add(1.5, function()
  emu.print_error(string.format("### SNAP 0 = BASELINE PEQ cnt=%d", sp:read_u8(0x29AA)))
  mach.video:snapshot()
end)

for i, s in ipairs(SEQ) do
  tap(s[1], s[2], 0.30)
  add(1.2, function()
    emu.print_error(string.format("### SNAP %d = after %s   cnt=%d", i, s[3], sp:read_u8(0x29AA)))
    mach.video:snapshot()
  end)
end
add(0.5, function() emu.print_error("### exiting"); mach:exit() end)

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
emu.print_error(string.format("### peq_cursor loaded seq=%d steps=%d", #SEQ, #steps))
