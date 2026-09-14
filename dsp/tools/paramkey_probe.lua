-- paramkey_probe.lua -- WHICH panel key is PARAMETER, and which is VALUE?
--
-- N-INPUT-GATE-OPENED sect. 172.  `kn5000-dsp-paramlist.md' sect.1.3 names the editor's three
-- bottom soft-key pairs "TYPE / PARAMETER / VALUE" and MEASURED ONLY TYPE (up = UP-1 =
-- CPL_SEG10 0x20).  PARAMETER = UP-2 and VALUE = UP-3 were INFERRED from the naming, and
-- `peq_gain.lua' has carried that inference ever since.
--
-- ★ THE INFERENCE IS WRONG, and the instrument that shows it is already in the note:
-- RAM[0x29AA] is the parameter SLOT COUNT, a property of the selected EFFECT.  A PARAMETER-cursor
-- move must NOT change it; a TYPE step must.  MEASURED on the corrected peq_gain run:
--
--     ### LANDED ON PEQ    type=0x0B cnt=17     <- PARAMETRIC EQ, 17 slots.  TYPE stepping works.
--     ### PARAMETER moved  type=0x0B cnt=6      <- pressing UP-2 CHANGED THE EFFECT.
--
-- So UP-2 steps the effect, not the cursor.  This probe finds the real pair by pressing each
-- candidate ONCE and reporting, after each, the two things that discriminate:
--
--     cnt   = RAM[0x29AA]        changes  => the key changed the EFFECT      (a TYPE-like key)
--     sig   = checksum of RAM[0x2980..0x2A20]   changes while cnt does NOT
--                                          => the key moved a CURSOR or a VALUE  ★ the target
--     both unchanged             => the key does nothing on this page
--
-- ⚠ The LCD text at 0x30AE5 is GARBAGE in this build (project memory), so the screen cannot be
-- read back -- which is exactly why this probe reads RAM instead.
-- ⚠ emu.print_error goes to STDOUT, not error.log (project memory).  Capture stdout.
--
-- Env:  TYPEIDX (default 15 = PARAMETRIC EQ, which has 17 slots so a cursor has somewhere to go)
local TYPEIDX = tonumber(os.getenv("TYPEIDX") or "15")
local mach = manager.machine
local sp = mach.devices[":maincpu"].spaces["program"]

do local d = mach.ioport.ports[":DSPCFG"]
   if d then for _, f in pairs(d.fields) do f.user_value = 3 end end end

local function setbtn(tag, mk, v)
  local port = mach.ioport.ports[":cpanel:" .. tag]
  if not port then emu.print_error("### NO PORT " .. tag); return end
  for _, f in pairs(port.fields) do if f.mask == mk then f:set_value(v) end end
end
--  ⚠ v1 hashed ONLY 0x2980..0x2A20 (chosen because RAM[0x29AA] lives there) and reported
--  "nothing changes" for twelve of the sixteen keys.  A cursor stored anywhere else would be
--  invisible to that, and "twelve dead keys" is not what a real instrument looks like.  So the
--  window is now BROAD and the report LOCALISES: how many bytes changed, and where.
local LO, HI = 0x2000, 0x9200
local base = {}
local function snap()
  local t = {}
  for a = LO, HI do t[a] = sp:read_u8(a) end
  return t
end
local function diff(t)
  local n, first = 0, {}
  for a = LO, HI do
    if base[a] ~= t[a] then
      n = n + 1
      if #first < 6 then first[#first + 1] = string.format("%04X:%02X->%02X", a, base[a], t[a]) end
    end
  end
  return n, table.concat(first, " ")
end
local function cnt() return sp:read_u8(0x29AA) end

--  Every up/down soft-key pair the kn5000_cpanel driver defines, by its PORT_NAME.
--  UP 1 / DOWN 1 are TYPE and are the known-good positive control.
local CAND = {
  { "UP 1",   "CPL_SEG10", 0x20 }, { "DOWN 1", "CPL_SEG10", 0x10 },
  { "UP 2",   "CPL_SEG10", 0x80 }, { "DOWN 2", "CPL_SEG10", 0x40 },
  { "UP 3",   "CPL_SEG9",  0x20 }, { "DOWN 3", "CPL_SEG9",  0x10 },
  { "UP 4",   "CPL_SEG9",  0x80 }, { "DOWN 4", "CPL_SEG9",  0x40 },
  { "UP 5",   "CPL_SEG8",  0x20 }, { "DOWN 5", "CPL_SEG8",  0x10 },
  { "UP 6",   "CPL_SEG8",  0x80 }, { "DOWN 6", "CPL_SEG8",  0x40 },
  { "UP 7",   "CPL_SEG7",  0x20 }, { "DOWN 7", "CPL_SEG7",  0x10 },
  { "UP 8",   "CPL_SEG7",  0x80 }, { "DOWN 8", "CPL_SEG7",  0x40 },
}

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
tap("CPL_SEG7", 0x02, 0.4)                               -- DSP EFFECT editor
add(1.5, function()
  emu.print_error(string.format("### editor  type=0x%02X cnt=%d", sp:read_u8(0x8D38), cnt())) end)
for _ = 1, 40 do tap("CPL_SEG10", 0x10, 0.08) end        -- saturate DOWN
add(1.0, function() end)
for _ = 1, TYPEIDX do tap("CPL_SEG10", 0x20, 0.10) end   -- UP to the target effect
add(1.5, function()
  base = snap()
  emu.print_error(string.format("### LANDED  cnt=%d  baseline snapshot 0x%04X..0x%04X", cnt(), LO, HI)) end)

--  Press each candidate ONCE and report.  DOWN 1 / UP 1 are included as the positive control:
--  they MUST change cnt, and if they do not the probe itself is broken.
for _, c in ipairs(CAND) do
  local nm, tag, mk = c[1], c[2], c[3]
  tap(tag, mk, 0.30)
  add(0.9, function()
    local n, where = diff(snap())
    emu.print_error(string.format("### KEY %-7s %s 0x%02X -> cnt=%-3d changed=%-4d %s",
        nm, tag, mk, cnt(), n, where))
  end)
  --  re-baseline so each candidate is measured against the page as the PREVIOUS key left it
  add(0.3, function() base = snap() end)
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
emu.print_error(string.format("### paramkey_probe loaded TYPEIDX=%d candidates=%d steps=%d",
    TYPEIDX, #CAND, #steps))
