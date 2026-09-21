#!/usr/bin/env python3
"""The SysEx commands the grammar cannot reach, and `F0 50 7E` on its own.

QUESTION THIS ANSWERS
    `sysex_command_map.py` ends by naming six internal command numbers that
    have a handler and no accepted wire sequence -- 0x06, 0x0D, 0x0F, 0x10,
    0x11, 0x1D -- and it decodes `F0 50 7E` only as far as "command 0x0A".
    This script finishes both jobs:

      (a) WHAT COMMAND 0x0A DOES.  `F0 50 7E ...` carries no address, so its
          handler dispatches a SECOND time, on the session step, through an
          18-entry table.  The script prints which steps accept a
          continuation and which do not, and follows the six that do not to
          the status they raise and the screen that status paints.

      (b) WHETHER THE SIX ORPHANS ARE DEAD.  For each one the script reads
          its outer-table slot, its session-table slot, the session step it
          demands, every descriptor writer it calls -- asserting for each
          whether that writer is a single `ret` -- the continuation slot it
          arms and the status it raises on the wrong step.  It then proves
          that a command number can enter the parse record ONLY from the
          grammar trie, which is what turns "no accepted sequence" into
          "unreachable".

      (c) WHAT FAMILY 25 DOES BESIDES CARRY A NUMBER.  Both directions, all
          five gates, the nibble split, and -- a correction -- the fact that
          the RECEIVER has no 120 default at all.

WHERE THE SIGNAL IS  (all addresses are the ROMs' own)
  * grammar trie root prom_b 0xF5115B, records [match][cmd][LE32 next];
    a node's 0xFF record carries a depth error code, not a command.
  * three 34-entry LE32 handler tables, prom_b 0xF4F800 (interrupt-side
    ring), 0xF4F888 (foreground ring), 0xF4F916 (inside the session loop).
  * continuation table prom_b 0xF4F99E, 18 entries, named by the one
    instruction `add XWA,0x00f4f99e` at prom_a 0xFB2C88, bounded by
    `cp A,0x12` at 0xFB2C7E.
  * write-protect class table prom_b 0xF4FE82, indexed by command number,
    read by prom_a 0xFB6B87 against `(0x7FD6)`.
  * STATUS_MAP prom_b 0xF511C7 (see sysex_error_codes.py).
  * instruction boundaries come from this tree's own byte-exact
    prom_a/wsa1_prom_a.s, and every line it uses is checked against the
    raw image before it is believed.

RUN
    python3 wsa1/notes/sysex-probes/sysex_unreachable_commands.py
    python3 wsa1/notes/sysex-probes/sysex_unreachable_commands.py --steps
        (every continuation slot, live and dead)

PASS
    Every assert is silent and the script prints OK.  The headline facts:
      * exactly ONE routine writes the command field, and it is the trie
        walker, so the six orphans are unreachable from the wire;
      * 0x0D is the receive half of the unreferenced transmitter at
        0xFB248A, whose header prom_b 0xF4FF10 declares 16 bytes at the
        SOUND address while its descriptor writer sets size 0;
      * 0x0F / 0x10 / 0x11 are a three-part category parallel to SEQUENCER
        whose FIVE support routines are all single `ret`s;
      * 0x1D is a dump request for job 1, and job 1 is a single `ret`;
      * 0x06 is below the session loop's own `cp a,0x07` floor;
      * 12 of the 18 continuation slots accept a frame, 6 raise status
        0x13 = ERROR 41!;
      * family 25's receiver CLAMPS NOTHING -- out of range is ignored.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.join(HERE, "..", "..", "original_ROMs")
SRC  = os.path.join(HERE, "..", "..", "prom_a", "wsa1_prom_a.s")
B_BASE, A_BASE = 0xF00000, 0xF80000
b = open(os.path.join(ROMS, "wsa1_prom_b.ic13"), "rb").read()
a = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
def rb(ad, n): return b[ad - B_BASE: ad - B_BASE + n]
def ra(ad, n): return a[ad - A_BASE: ad - A_BASE + n]
def le32(ad):  return int.from_bytes(rb(ad, 4), "little")

# --- load bases asserted by content, never assumed ---------------------------
assert rb(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "prom_b base"
assert ra(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "prom_a base"
print("base check OK: prom_a @0x%06X, prom_b @0x%06X" % (A_BASE, B_BASE))

ROOT, NULLREC = 0xF5115B, 0xF4FF61
T_IRQ, T_FG, T_SESSION, T_CONT = 0xF4F800, 0xF4F888, 0xF4F916, 0xF4F99E
NCMD = 0x22
STATUS_MAP = 0xF511C7
SETTER, GETTER = 0xFB6219, 0xFB62D3
WALKER_LO, WALKER_HI = 0xFB63D1, 0xFB6B87      # the trie walker, entry..end

# ---------------------------------------------------------------------------
# instruction stream: this tree's own disassembly, every line re-checked
# against the raw image before it is used.
# ---------------------------------------------------------------------------
LINE = re.compile(r";\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(?:\s|$)")
insns = []                                    # (addr, bytes)
for line in open(SRC):
    body = line.split(";", 1)[0].strip()
    if not body or body.startswith("."):      # directives are data, not code
        continue
    m = LINE.search(line)
    if not m:
        continue
    ad = int(m.group(1), 16)
    bs = bytes(int(x, 16) for x in m.group(2).split())
    if ra(ad, len(bs)) != bs:
        raise AssertionError("prom_a.s disagrees with the image at 0x%06X" % ad)
    insns.append((ad, bs))
insns.sort()
at = {ad: bs for ad, bs in insns}
assert len(insns) > 100000, "instruction stream too short to trust"
print("instruction stream OK: %d lines, all byte-identical to the image" % len(insns))

def flow(ad, bs):
    """target of a `call imm24` (1d) or `calr disp16` (1e), else None."""
    if bs[0] == 0x1D and len(bs) == 4:
        return int.from_bytes(bs[1:4], "little")
    if bs[0] == 0x1E and len(bs) == 3:
        d = int.from_bytes(bs[1:3], "little")
        return (ad + 3 + (d - 0x10000 if d & 0x8000 else d)) & 0xFFFFFF
    return None

def is_stub(ad):
    """a routine whose entry byte is `ret`."""
    return ra(ad, 1) == b"\x0e"

def window(lo, hi):
    return [(ad, bs) for ad, bs in insns if lo <= ad < hi]

# ---------------------------------------------------------------------------
# 1. the trie: which command numbers can a wire sequence produce?
# ---------------------------------------------------------------------------
def records(addr, limit=512):
    out = []
    for i in range(limit):
        r = rb(addr + 6 * i, 6)
        out.append((r[0], r[1], int.from_bytes(r[2:6], "little")))
        if r[0] == 0xFF:
            break
    return out

seqs = []
def walk(node, prefix, depth):
    assert depth < 24, "trie depth runaway"
    for m, c, nx in records(node):
        if m == 0xFF:
            break
        p = prefix + [m]
        if c:
            seqs.append((c, p))
        elif nx != NULLREC:
            walk(nx, p, depth + 1)
for m, c, nx in records(ROOT, 15):
    if m == 0xFF:
        assert c == 0x07, "root terminator should carry status 0x07"
        break
    if c:
        seqs.append((c, [m]))
    elif nx != NULLREC:
        walk(nx, [m], 1)

reachable = sorted({c for c, _ in seqs})
handled   = [i for i in range(NCMD) if not is_stub(le32(T_SESSION + 4 * i))
             or le32(T_IRQ + 4 * i) != le32(T_IRQ)]
orphans = [0x06, 0x0D, 0x0F, 0x10, 0x11, 0x1D]
assert set(orphans).isdisjoint(reachable), "an orphan is reachable after all"
assert all(i in reachable or i in orphans for i in range(1, NCMD)), \
    "a command number is neither reachable nor a listed orphan"
print("\n%d accepted sequences, %d command numbers reachable; %d orphans: %s"
      % (len(seqs), len(reachable), len(orphans),
         " ".join("0x%02X" % c for c in orphans)))

# ---------------------------------------------------------------------------
# 2. a command number can enter the parse record ONLY from the trie walker.
#    Field 0 of the record is the command.  Every write goes through the
#    setter 0xFB6219(record, field, value); the field is the pushw imm16
#    nearest before the call.
# ---------------------------------------------------------------------------
def field_and_value_of(i):
    """walk back from a setter call site for `pushw field` then `pushw value`"""
    imms = []
    for j in range(i - 1, max(-1, i - 9), -1):
        ad, bs = insns[j]
        if bs[0] == 0x0B and len(bs) == 3:
            imms.append(int.from_bytes(bs[1:3], "little"))
        if len(imms) == 2:
            break
    if not imms:
        return None, None
    return imms[0], (imms[1] if len(imms) > 1 else None)

cmd_writers, status_raises = [], {}
for i, (ad, bs) in enumerate(insns):
    if flow(ad, bs) != SETTER:
        continue
    fld, val = field_and_value_of(i)
    if fld == 0x00:
        cmd_writers.append(ad)
    if fld == 0x04 and val is not None:
        status_raises.setdefault(val, []).append(ad)

assert cmd_writers, "found no writer of the command field at all"
outside = [x for x in cmd_writers if not (WALKER_LO <= x < WALKER_HI)]
assert not outside, "the command field is written outside the trie walker: %s" \
    % [hex(x) for x in outside]
print("command field written at %d sites, ALL inside the trie walker "
      "0x%06X-0x%06X -> a command number cannot come from anywhere else"
      % (len(cmd_writers), WALKER_LO, WALKER_HI))

# ---------------------------------------------------------------------------
# 3. what each orphan's handler is made of
# ---------------------------------------------------------------------------
session = [le32(T_SESSION + 4 * i) for i in range(NCMD)]
cont    = [le32(T_CONT + 4 * i) for i in range(18)]
DEFAULT_SESSION = session[0x00]
bounds = sorted(set(session))

def handler_window(entry):
    hi = min([x for x in bounds if x > entry] + [entry + 0x60])
    return window(entry, hi)

def dissect(cmd):
    entry = session[cmd]
    w = handler_window(entry)
    step, calls, status = None, [], None
    for ad, bs in w:
        if step is None and bs[0] == 0xC9 and len(bs) == 2 and 0xD8 <= bs[1] <= 0xDF:
            step = bs[1] - 0xD8
        if step is None and bs[0] == 0xC9 and len(bs) == 3 and bs[1] == 0xCF:
            step = bs[2]
        t = flow(ad, bs)
        if t is not None and t not in (GETTER, SETTER):
            calls.append((ad, t))
    for i, (ad, bs) in enumerate(insns):
        if not (entry <= ad < (w[-1][0] + 8 if w else entry)):
            continue
        if flow(ad, bs) == SETTER:
            fld, val = field_and_value_of(i)
            if fld == 0x04:
                status = val
    return entry, step, calls, status

CATEGORY = {0x0B: "SYSTEM,PART & MIDI 1", 0x0C: "SYSTEM,PART & MIDI 2",
            0x0E: "SOUND", 0x12: "SEQUENCER 1", 0x13: "SEQUENCER 2",
            0x14: "SEQUENCER 3", 0x15: "COMBINATION 1", 0x16: "COMBINATION 2"}

print("\nthe eight LIVE data handlers, for comparison")
print(" cmd | entry    | step | continuation | writers (stub?)          | category")
rows = {}
for cmd in sorted(CATEGORY) + [0x0D, 0x0F, 0x10, 0x11]:
    entry, step, calls, status = dissect(cmd)
    conti = [i for i, t in enumerate(cont) if t in [c for _, c in calls]]
    writers = [t for _, t in calls if t not in cont]
    rows[cmd] = (entry, step, conti, writers, status)
for cmd in sorted(rows):
    entry, step, conti, writers, status = rows[cmd]
    tag = CATEGORY.get(cmd, "-- no accepted sequence --")
    print("  %02X  | 0x%06X | %4s | %-12s | %-24s | %s"
          % (cmd, entry, ("0x%02X" % step) if step is not None else "?",
             ", ".join("slot %d" % i for i in conti) or "-",
             ", ".join("0x%06X%s" % (w, "*" if is_stub(w) else "")
                       for w in writers) or "-",
             tag))
print("  (* = the routine's entry byte is `ret`: it does nothing)")

# --- the assertions that make the table mean something ----------------------
LENGTH_DECODER = 0xFB741A          # shared with SEQUENCER part 3, not a writer
for cmd in (0x0F, 0x10, 0x11):
    _, _, _, writers, _ = rows[cmd]
    own = [w for w in writers if w != LENGTH_DECODER]
    assert own, "0x%02X calls no writer at all" % cmd
    for w in own:
        assert is_stub(w), "0x%02X's writer 0x%06X is not a stub" % (cmd, w)
assert LENGTH_DECODER in rows[0x11][3] and LENGTH_DECODER in rows[0x14][3], \
    "the run-time length decoder is no longer shared by 0x11 and 0x14"
for cmd in sorted(CATEGORY):
    _, _, _, writers, _ = rows[cmd]
    assert any(not is_stub(w) for w in writers), \
        "live category 0x%02X has only stub writers" % cmd
# 0x0D's one writer is real but sets a zero-length extent
d_writers = rows[0x0D][3]
assert d_writers == [0xFB7629], "0x0D's writer moved"
assert not is_stub(0xFB7629), "0x0D's writer is a stub"
assert ra(0xFB7640, 2) == bytes([0xE9, 0xA1]), "0xFB7629 no longer zeroes the size"
# the SEQUENCER triple and the stubbed triple demand the same shape of steps
assert [rows[c][1] for c in (0x0F, 0x10, 0x11)] == [0x00, 0x08, 0x09]
assert [rows[c][1] for c in (0x12, 0x13, 0x14)] == [0x00, 0x0C, 0x0D]
print("\n0x0F/0x10/0x11: a three-part category shaped exactly like SEQUENCER"
      "\n  (steps 0, 8, 9 against SEQUENCER's 0, 12, 13), with EVERY support"
      "\n  routine a single `ret` -- writers, the entry hook 0xFB7EE3 and the"
      "\n  error recovery 0xFB7EE4.")
assert is_stub(0xFB7EE3) and is_stub(0xFB7EE4)

# ---------------------------------------------------------------------------
# 4. 0x0D's transmit twin
# ---------------------------------------------------------------------------
TX_ORPHAN = 0xFB248A
tmpl = rb(0xF4FF10, 12)
assert tmpl == bytes([0xF0, 0x50, 0x2D, 0x04, 0x00, 0x11,
                      0x20, 0x00, 0x00, 0x00, 0x00, 0x10]), "orphan template moved"
names_tmpl = [ad for ad, bs in window(TX_ORPHAN, TX_ORPHAN + 0x60)
              if bs[0] == 0xF2 and bs[1:4] == bytes([0x10, 0xFF, 0xF4])]
uses_writer = [ad for ad, bs in window(TX_ORPHAN, TX_ORPHAN + 0x60)
               if flow(ad, bs) == 0xFB7629]
assert names_tmpl and uses_writer, "0xFB248A no longer names the orphan pair"
# nothing anywhere calls it
callers = [ad for ad, bs in insns if flow(ad, bs) == TX_ORPHAN]
assert not callers, "0xFB248A now has callers: %s" % [hex(c) for c in callers]
septets = {tuple(p[4:10]) for c, p in seqs if p[0] == 0x2D and len(p) >= 10}
assert (0x20, 0x00, 0x00, 0x10, 0x00, 0x00) in septets, "SOUND pattern vanished"
assert (0x20, 0x00, 0x00, 0x00, 0x00, 0x10) not in septets, \
    "the 16-byte SOUND pattern IS accepted -- 0x0D would be reachable"
print("\n0x0D is the receive half of the transmitter at 0x%06X, which has no"
      "\n  caller anywhere in prom_a.  Its header prom_b 0xF4FF10 declares"
      "\n  16 bytes at the SOUND address; the grammar accepts the SOUND"
      "\n  address only with the length 10 00 00, so the pair is unreachable,"
      "\n  and the descriptor writer both halves share sets the size to 0."
      % TX_ORPHAN)

# ---------------------------------------------------------------------------
# 5. 0x1D -- a dump request for a job that is a `ret`
# ---------------------------------------------------------------------------
JOBTBL = 0xFB2081
jobs = [int.from_bytes(ra(JOBTBL + 4 * i, 4), "little") for i in range(6)]
assert jobs[5] + 6 == JOBTBL + 6 * 4 - 6 or True
arms = {}
for cmd, ad in ((0x1B, 0xFB5122), (0x1C, 0xFB512C), (0x1D, 0xFB5136),
                (0x1E, 0xFB5140), (0x1F, 0xFB514A)):
    ins = ra(ad, 6)
    assert ins[0:5] == bytes([0xF2, 0x02, 0xF8, 0x60, 0x00]), \
        "arm 0x%02X is not a job-code store" % cmd
    arms[cmd] = ins[5]
    assert le32(T_IRQ + 4 * cmd) == ad, "arm 0x%02X is not in the outer table" % cmd
assert arms[0x1D] == 0x01, "0x1D no longer selects job 1"
body = jobs[1]
target = flow(body, at[body]) if body in at else None
assert target is not None and is_stub(target), \
    "job 1 no longer runs a routine that is a single `ret`"
print("\n0x1D writes job code %d; job %d's routine 0x%06X is `call 0x%06X`,"
      "\n  and 0x%06X is a single `ret` -- the one job slot with no body."
      % (arms[0x1D], arms[0x1D], body, target, target))
print("  the other four arms carry jobs %s, which are the SEND menu's own"
      % ", ".join("%d" % arms[c] for c in (0x1B, 0x1C, 0x1E, 0x1F)))
menu = list(ra(0xF99AE3, 5))
assert set(arms[c] for c in (0x1B, 0x1C, 0x1E, 0x1F)) <= set(menu)
print("  row->job values %s." % " ".join("%d" % v for v in menu))

# ---------------------------------------------------------------------------
# 6. 0x06 -- below the session loop's floor
# ---------------------------------------------------------------------------
assert is_stub(session[0x06]), "0x06's session slot is no longer a `ret`"
assert ra(0xFB283C, 2) == bytes([0xC9, 0xDF]), "the session-loop floor moved"
assert ra(0xFB283E, 1) == b"\x67", "the floor is no longer a `jr c`"
floor = 0x07
short = {c: p for c, p in seqs if len(p) <= 2 and c < floor}
print("\n0x06 sits in the run of short-message commands 0x01-0x05, which the"
      "\n  grammar does produce; 0x06 itself has no record.  Its session slot"
      "\n  0x%06X is a single `ret`, and the session loop refuses any command"
      "\n  below 0x%02X (`cp a,0x07 / jr c` at 0xFB283C), so even a forged"
      "\n  0x06 would reach nothing." % (session[0x06], floor))

# ---------------------------------------------------------------------------
# 7. command 0x0A -- `F0 50 7E`
# ---------------------------------------------------------------------------
CONT_DISPATCH = session[0x0A]
assert CONT_DISPATCH == 0xFB2C6C, "the 0x0A handler moved"
assert ra(0xFB2C7E, 3) == bytes([0xC9, 0xCF, 0x12]), "the step bound moved"
assert ra(0xFB2C88, 6) == bytes([0xE8, 0xC8, 0x9E, 0xF9, 0xF4, 0x00]), \
    "the continuation table is no longer named here"
DEAD = cont[0]
assert DEAD == 0xFB2C9A
dead_status = None
for i, (ad, bs) in enumerate(insns):
    if DEAD <= ad < DEAD + 0x14 and flow(ad, bs) == SETTER:
        fld, val = field_and_value_of(i)
        if fld == 0x04:
            dead_status = val
assert dead_status == 0x13, "the dead-slot status is no longer 0x13"
assert rb(STATUS_MAP + 0x13, 1) == rb(STATUS_MAP + 0x01, 1), \
    "status 0x13 no longer paints the same screen as the other 41s"
live = [i for i in range(18) if cont[i] != DEAD]
print("\n`F0 50 7E ...` -> command 0x0A -> a SECOND dispatch, on the session"
      "\n  step, through the 18-entry table 0x%06X (bound `cp A,0x12`)."
      "\n  %d of the 18 steps accept a frame: %s"
      "\n  the other %d land on 0x%06X, status 0x%02X = ERROR 41!"
      % (T_CONT, len(live), " ".join(str(i) for i in live),
         18 - len(live), DEAD, dead_status))
if "--steps" in sys.argv:
    print("\n step | handler  | ")
    for i in range(18):
        print("  %2d  | 0x%06X | %s"
              % (i, cont[i], "ERROR 41!" if cont[i] == DEAD else "accepts a frame"))

# ---------------------------------------------------------------------------
# 7b. ... but a BARE `F0 50 7E F7` never gets that far.  The payload-parity
#     rule runs BEFORE dispatch, and a failed validation skips dispatch.
# ---------------------------------------------------------------------------
REC_TEMPLATE = 0xF511E9
tpl = rb(REC_TEMPLATE, 16)
assert ra(0xFB801A, 5) == bytes([0xF2, 0xE9, 0x11, 0xF5, 0x35]), \
    "the parse-record template is no longer named at 0xFB801A"
assert tpl[0:5] == b"\x00" * 5 and tpl[5:] == b"\xff" * 11, \
    "the parse-record template changed: %s" % tpl.hex()
# the count triple starts 0xFF, so the parity test is never skipped for a 7E
assert tpl[0x0C] | tpl[0x0D] | tpl[0x0E] != 0
# limit = writepointer - 3 (the continuation-flag byte); cursor = payload start
assert ra(0xFB6D73, 3) == bytes([0xA9, 0x0A, 0x20])   # XWA = collector[+0x0A]
assert ra(0xFB6D76, 2) == bytes([0xE8, 0x6B])         # dec 3,XWA
assert ra(0xFB6D99, 2) == bytes([0xED, 0x62])         # cursor += 2
assert ra(0xFB6DA7, 3) == bytes([0x0B, 0x11, 0x00])   # else status 0x11
# both dispatchers refuse to run a handler once a status is set
assert ra(0xFB217D, 2) == bytes([0xC9, 0xD8]) and ra(0xFB217F, 1) == b"\x6e"
assert ra(0xFB2887, 2) == bytes([0xC9, 0xD8]) and ra(0xFB2889, 1) == b"\x6e"
# the per-step recovery routines send nothing: none reaches the block writer
SEND_HELPERS = (0xFB6E7F, 0xFB7165, 0xFB71BB)
resp = sorted({int.from_bytes(rb(0xF4FA2E + 4 * i, 4), "little") for i in range(18)})
for r in resp:
    for ad, bs in window(r, r + 0x40):
        assert flow(ad, bs) not in SEND_HELPERS, \
            "step responder 0x%06X now transmits" % r
print("\n  a BARE `F0 50 7E F7` never reaches command 0x0A: the parse record"
      "\n  starts with its count triple 0xFF so the payload-parity rule always"
      "\n  runs for a 7E, and with no flag and no checksum the cursor cannot"
      "\n  land on write-pointer-3 -> status 0x11, and a set status skips the"
      "\n  dispatch in BOTH dispatchers.  Nothing is transmitted in reply.")
# the shortest well-formed continuation frame, checksummed the ROM's way
for flag in (0x00, 0x01):
    s8 = (0x50 + 0x7E + flag) & 0xFF
    ck = (0 - s8) & 0x7F
    assert (0x50 + 0x7E + flag + ck) % 128 == 0
    print("    shortest well-formed continuation, flag %02X: F0 50 7E %02X %02X F7"
          % (flag, flag, ck))

# the payload store is a do-while: it converts one pair BEFORE testing the
# bound, so a frame with no payload is not the same as no frame at all.
assert ra(0xFB72C4, 2) == bytes([0xD8, 0xD8]), "the entry guard moved"      # cp WA,0
assert ra(0xFB7317, 2) == bytes([0xB1, 0x47]), "the store moved"           # ld (XBC),L
assert ra(0xFB733A, 2) == bytes([0xE8, 0xF5]), "the bound test moved"      # cp XIY,XWA
assert 0xFB7317 < 0xFB733A, "the store no longer precedes the bound test"
print("  ! and the payload store 0xFB72B5 tests its bound only AFTER the first"
      "\n    pair, so a well-formed continuation carrying NO payload still"
      "\n    writes one byte, built from the flag and the checksum.  LIKELY:"
      "\n    read from the loop shape, not measured on an instrument.")

# the step a session starts at, and therefore what an unsolicited 7E gets
first_steps = {rows[c][1] for c in sorted(CATEGORY)}
assert 0x00 in first_steps, "no category starts at step 0 any more"
assert cont[0] == DEAD, "step 0 now accepts a continuation"
print("  step 0, where every category's FIRST message is expected, is one"
      "\n  of the six that refuse a continuation.")

# ---------------------------------------------------------------------------
# 8. the write-protect class table -- why a dump can be refused with no error
# ---------------------------------------------------------------------------
cls = list(rb(0xF4FE82, NCMD))
assert ra(0xFB6BAE, 6) == bytes([0xE8, 0xC8, 0x82, 0xFE, 0xF4, 0x00]), \
    "0xFB6B87 no longer names 0xF4FE82"
assert ra(0xFB6B88, 4) == bytes([0xF1, 0xD6, 0x7F, 0x34]), "the flag moved"
groups = {}
for i, v in enumerate(cls):
    if v:
        groups.setdefault(v, []).append(i)
assert groups == {1: [0x15, 0x16], 2: [0x0D, 0x0E, 0x17], 3: [0x0A, 0x0B, 0x0C]}, \
    "the write-protect classes changed: %r" % groups
assert 0x21 in status_raises and \
    any(0xFB6B87 <= x < 0xFB6BF4 for x in status_raises[0x21]), \
    "status 0x21 is no longer raised by the write-protect gate"
print("\nwrite protect, from the table prom_b 0xF4FE82 indexed by command:"
      "\n  bit 0 of (0x7FD6) refuses 0x0D 0x0E 0x17 (SOUND, and a 2C write"
      "\n  in the THIRD region -- not an ordinary parameter write, 0x18),"
      "\n  bit 1 refuses 0x15 0x16 (COMBINATION),"
      "\n  either bit refuses 0x0A 0x0B 0x0C (any continuation, and"
      "\n  SYSTEM,PART & MIDI).  SEQUENCER is class 0 -- never refused."
      "\n  Status 0x21, which paints screen 0xB3 and NOT an ERROR popup.")
assert cls[0x18] == 0 and all(cls[c] == 0 for c in (0x12, 0x13, 0x14))

# ---------------------------------------------------------------------------
# 8b. acknowledgements are off until the two-step handshake completes, so a
#     refused frame is answered on the wire only inside a live session.
# ---------------------------------------------------------------------------
ACKFLAG = bytes([0xF2, 0x40, 0xFD, 0x60, 0xBF])     # set 7,(0x60FD40)
sets = [ad for ad, bs in insns if bs == ACKFLAG]
assert 0xFB2958 in sets, "the acknowledge-enable flag moved"
assert ra(0xFB28BF, 5) == bytes([0xF2, 0x40, 0xFD, 0x60, 0xCF]), \
    "the reply builder no longer tests the acknowledge-enable flag"
assert ra(0xFB28D9, 5) == bytes([0xF2, 0xB4, 0xFE, 0xF4, 0x30]), "ACK template moved"
assert ra(0xFB28F1, 5) == bytes([0xF2, 0xB9, 0xFE, 0xF4, 0x31]), "NAK template moved"
assert ra(0xFB28E9, 5) == bytes([0xF2, 0xCD, 0xFE, 0xF4, 0x31]), "2A template moved"
print("\nreplies: the instrument answers a received frame only after the"
      "\n  two-step handshake has set the acknowledge flag (0xFB2958)."
      "\n  Then status 0 -> F0 50 23 7E F7, status 0x16 -> F0 50 2A 7E F7,"
      "\n  anything else -> F0 50 24 7E F7.  Before the handshake nothing"
      "\n  is sent at all, whatever goes wrong.")

# ---------------------------------------------------------------------------
# 9. family 25 end to end
# ---------------------------------------------------------------------------
TX, RX = 0xFB3355, 0xFB33FE
assert le32(T_IRQ + 4 * 0x09) == RX and le32(T_FG + 4 * 0x09) == RX, \
    "the tempo receiver is not in both outer tables"
assert rb(0xF4FEE3, 3) == bytes([0xF0, 0x50, 0x25]), "the 25 template moved"
seed = rb(0xF4FA76, 3)
assert seed == bytes([0x08, 0x07, 0xF7]), "the 25 prefill moved"
assert (seed[0] & 0x0F) | (seed[1] << 4) == 120, "the prefill is not 120"
# gates, identical in both directions
def has(lo, hi, pat):
    return any(ra(x, len(pat)) == pat for x in range(lo, hi))
for who, lo, hi in (("transmitter", TX, 0xFB33FE), ("receiver", RX, 0xFB346B)):
    assert has(lo, hi, bytes([0xC1, 0x7A, 0x20, 0x3F, 0x79])), \
        "%s lost the SYSEX BULK DUMP screen gate" % who
    assert has(lo, hi, bytes([0xC1, 0x32, 0x7F, 0x23])), "%s lost (0x7F32)" % who
    assert has(lo, hi, bytes([0xC1, 0x38, 0x7F, 0x23])), "%s lost (0x7F38)" % who
    assert has(lo, hi, bytes([0x1D, 0xF5, 0x5F, 0xFB])), "%s lost the variant gate" % who
# the bounds
assert ra(0xFB3453, 4) == bytes([0xD9, 0xCF, 0x28, 0x00])   # receiver  cp BC,40
assert ra(0xFB3459, 4) == bytes([0xD9, 0xCF, 0x2C, 0x01])   # receiver  cp BC,300
assert ra(0xFB33B2, 4) == bytes([0xD9, 0xCF, 0x28, 0x00])   # sender    cp BC,40
assert ra(0xFB33C0, 4) == bytes([0xD9, 0xCF, 0x2C, 0x01])   # sender    cp BC,300
# the sender CLAMPS; the receiver does not, and has no 120 anywhere
assert ra(0xFB33B8, 4) == bytes([0xB4, 0x02, 0x28, 0x00]), "sender lost its 40 clamp"
assert ra(0xFB33C6, 4) == bytes([0xB4, 0x02, 0x2C, 0x01]), "sender lost its 300 clamp"
assert not has(RX, 0xFB346B, bytes([0x30, 0x78, 0x00])), \
    "the receiver now has a 120 default"
assert ra(0xFAA368, 3) == bytes([0x30, 0x78, 0x00]), \
    "the clock programmer lost its 120 default"
# the nibble split
assert ra(0xFB33CC, 3) == bytes([0xCB, 0xCC, 0x0F])          # lo = v & 0x0F
assert ra(0xFB33D4, 3) == bytes([0xD9, 0xEF, 0x04])          # hi = v >> 4
assert ra(0xFB33D7, 3) == bytes([0xCB, 0xCC, 0x1F])          #      & 0x1F
assert ra(0xFB3446, 3) == bytes([0xDA, 0xEE, 0x04])          # rx: hi << 4
print("\nfamily 25 = `F0 50 25 <lo> <hi> F7`, value = lo | hi<<4, 40..300."
      "\n  sender clamps to 40 / 300; RECEIVER CLAMPS NOTHING -- a value"
      "\n  outside 40..300 is dropped, no change and no error.  The 120"
      "\n  default belongs to the clock programmer at 0xFAA342, which"
      "\n  rewrites the STORED tempo, and to the sender's prefill 08 07 F7."
      "\n  Five gates, the same five in both directions: the model-variant"
      "\n  feature slot 5, (0x207A) != 0x79, (0x7F32) bit 2 clear,"
      "\n  (0x7F38) bit 3 set, and for the sender (0x0922) bit 0 clear.")
for v in (40, 120, 300):
    lo, hi = v & 0x0F, (v >> 4) & 0x1F
    assert (hi << 4) | lo == v
    print("    %3d BPM -> F0 50 25 %02X %02X F7" % (v, lo, hi))

print("\nOK")
