#!/usr/bin/env python3
"""Split prom_c/wsa1_prom_c.s into per-subject sources -- and PROVE nothing was lost.

WHAT QUESTION THIS ANSWERS
--------------------------
  "Did the reorganisation of the sub-CPU listing move lines, or did it change
   them?"  A split that drops one comment, reorders one routine or reflows one
   header is not a split -- it is an edit wearing a split's clothes, and this
   tree's prose is the product of months of work.

  The BYTE gate (scripts/analysis/assert_byte_identical.py) proves the ROM is
  unchanged.  It cannot see a lost comment: comments assemble to nothing.  This
  script is the other half.

HOW THE SPLIT IS SHAPED, and why it cannot change a byte
--------------------------------------------------------
  prom_c/wsa1_prom_c.s has no `.org` and one section: the ORDER OF EMISSION IS
  THE ADDRESS ORDER.  So every extracted file is a CONTIGUOUS RANGE of the
  original's lines, and the master `.include`s it AT THE LINE THE RANGE STARTED
  ON.  llvm-mc's `.include` is textual, so the assembler sees exactly the token
  stream it saw before -- same order, same offsets, same branch displacements.
  ⚠ Any split that reordered ranges WOULD move code, and TLCS-900 `jr` has a
  short reach; the byte gate is what would catch it.

  Each extracted file may carry a NEW documentation header above the moved
  block.  Nothing else is added, and nothing at all is removed or reworded.

COMMANDS
--------
  python3 notes/prom_c_split.py --plan      what would move where, with sizes
  python3 notes/prom_c_split.py --emit      perform the split (reads BASE from git)
  python3 notes/prom_c_split.py --verify    ★ the preservation proof (see below)
  python3 notes/prom_c_split.py --counts    comment/label census, before vs after
  python3 notes/prom_c_split.py --selftest  the instrument's own controls

★ WHAT --verify PROVES
  It reconstructs the pre-split listing from the tree on disk -- master, with
  every `.include "prom_c/..."` line replaced by that file's moved block -- and
  aligns it against the listing as it stood at BASE_COMMIT.  It requires the
  alignment to contain INSERTIONS ONLY: no line deleted, no line reordered, no
  line altered by a character.  Every inserted line is printed.

  ⚠ It is PINNED to BASE_COMMIT on purpose.  It answers "did THE SPLIT preserve
  the text", which is a question about one commit and stays true forever.  It is
  not a coverage metric and must not be read as one: once later rounds edit an
  extracted file it will report those edits as insertions/deletions, which is
  correct and is the signal to retire it.

★ --selftest DOES NOT PIN TODAY'S NUMBERS.  It builds a synthetic listing, splits
  it, and checks two things that are true of any correct splitter: a faithful
  split verifies, and a split with ONE COMMENT LINE DELETED FAILS.  A checker
  that cannot fail is not a check.
"""
import difflib
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = "prom_c/wsa1_prom_c.s"

# The listing as it stood before the split.  `git show BASE_COMMIT:MASTER`.
BASE_COMMIT = "df84060a8d9cb95561d363597bfa90172107d42c"

INCLUDE_RE = re.compile(r'^\t\.include "(prom_c/[^"]+)"')
LABEL_RE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')

# ★ The line that separates a file's NEW header from its MOVED block.  `; >>>`
# occurs zero times in the pre-split listing, which is why it can be trusted as a
# boundary -- see body_of().
SENTINEL_PREFIX = "; >>> END OF EXTRACTION HEADER"
SENTINEL = SENTINEL_PREFIX + " -- everything below is verbatim from the master"

# ---------------------------------------------------------------------------
# THE SPEC.  (path, first line, last line, title, rationale)
#
# Lines are 1-based, inclusive, into the BASE_COMMIT listing.  Ranges must be
# disjoint and sorted; whatever they do not cover STAYS in the master, and that
# is deliberate -- a subject nobody can defend belongs in the residual, not in a
# file whose name asserts one.
#
# ★ ALMOST EVERY BOUNDARY BELOW IS ONE THE TREE ALREADY DREW: the `; ====` block
#   banners of the listing itself.  The spec merges adjacent banners that share a
#   subject; it does not invent a cut inside a block.
# ---------------------------------------------------------------------------
SPEC = [
    ("prom_c/data_tables/preset_bank.s", 244, 9553,
     "0xF80000-0xF97FFF  THE PRESET BANK",
     ["One generated data object: 32-byte header, 16 category names, 129 fixed",
      "704-byte records.  Its own banner states the geometry and the four",
      "independent facts it rests on.  No consumer has been located, so this is",
      "filed as DATA, not under a subsystem that would claim to read it."]),

    ("prom_c/boot/boot_and_main.s", 9554, 10671,
     "0xF98000-0xF98CB8  power-on: the task table, the kernel, the RAM image, MAIN",
     ["Five adjacent banners that are one subject -- what CPU 2 is when it starts",
      "and what it does forever after: the four channel-register writers for the",
      "device at 0x00E00000, EntryPoint_Records (the THREE TASKS), the semaphore",
      "power-on image, the DSP refresh entry and INTT3, the `.include` of the",
      "SHARED kernel, RamImage_Copy, ADC_Init, the two A/D inputs and their",
      "deadband, and MAIN's loop with its four helpers."]),

    ("prom_c/link/link_key_events.s", 10672, 11314,
     "0xF98CB9-0xF99062  key events become MIDI, and the four link-channel handlers",
     ["Banner-declared.  The keyboard leaves this CPU as MIDI note-on messages",
      "over the inter-processor link, and the four Link_ChN_* ring handlers are",
      "the other direction."]),

    ("prom_c/boot/scheduler_intt1.s", 11315, 11450,
     "0xF99063-0xF990F9  INTT1, the six-phase scheduler tick",
     ["Banner-declared.  The timer-1 interrupt that posts the work bits MAIN's",
      "loop consumes; it belongs beside MAIN, not beside the kernel (the kernel",
      "is CPU-shared source and lives in kernel/kernel.s)."]),

    ("prom_c/midi/midi_serial_port.s", 11451, 12439,
     "0xF990FA-0xF99597  the SC0 serial port that is MIDI: init, ISRs, queues, TX",
     ["Three adjacent banners, one subject: timer 1 and the 0x108000 preload and",
      "the UART init that configures SC0; INTRX0/INTTX0, SC0's two interrupt",
      "handlers; and the ring-queue runtime plus the MIDI transmit path they",
      "feed.  ⚠ The first banner also covers Timer1_Init and",
      "Dev108000_Preload_80toBF, which are not MIDI; they are here because they",
      "are inside the banner that documents the UART init and moving a banner's",
      "body away from its banner would be worse."]),

    ("prom_c/keyscan/touch_to_velocity.s", 12440, 12787,
     "0xF99598-0xF9973C  the TOUCH-to-VELOCITY path, and its two setters",
     ["Banner-declared.  ⚠ This is what the ToneGen_* labels are: a key-strike",
      "to velocity-byte converter and its curves.  It never touches 0x0010C000 --",
      "its output goes into a MIDI note-on handed to the link.  Filed under the",
      "keybed, NOT under the register devices."]),

    ("prom_c/keyscan/keyboard_scanner.s", 12788, 13763,
     "0xF9973D-0xF99BBD  the keyboard scanner at 0x00108000, and the per-note trim",
     ["Banner-declared.  KeyScan_*, NoteTrim_* and the Link_* senders that carry",
      "each key event out."]),

    ("prom_c/link/link_interrupts.s", 13764, 14301,
     "0xF99BBE-0xF99E5D  INT0 and INTTC2/INTTC3: the link's whole receive half",
     ["Four adjacent banners: INT0's command dispatcher, its jump table and seven",
      "arms; the micro-DMA completion handlers; INTTC3's nine state arms.  The",
      "banners themselves say these are one machine."]),

    ("prom_c/link/link_service.s", 14302, 14849,
     "0xF99E5F-0xF9A04F  Link_ServiceTask, the link wait, uDMA and the block move",
     ["Two adjacent banners: the DEFERRED half of the link (the task that runs the",
      "three flash jobs INT0 queues) and the transfer primitives under it.  The",
      "last eight are byte-identical to prom_a's, which is where their names come",
      "from."]),

    ("prom_c/p7/p7_module.s", 14850, 34011,
     "0xF9A050-0xFA5948  THE PORT-P7 MODULE: the byte transport, the streams, the units",
     ["TWO banners, and filing them together is the one judgement call in this",
      "spec.  The evidence, all of it already in the tree:",
      "  1. ONE MODULE by the listing's own boundary test -- `ret`/`link XIZ` at",
      "     both cuts (0xF9A04F/0xF9A050 and 0xFA5948/0xFA5949).",
      "  2. 94.3% SELF-CONTAINED -- 624 of 662 call sites are inside it (the",
      "     census printed in its own banner, from notes/prom_c_module_map.py).",
      "  3. Its HEAD is the port-P7 byte transport: P7Byte_SendCmd/SendData/",
      "     SendArg, the three P7Byte_Trace* helpers and P7Stream_Run.",
      "  4. Its TAIL, 0xFA2784-0xFA5948, is the banner-declared PORT-P7 UNIT",
      "     MODULE -- three units, their PROGRAMS and the parameter diff.",
      "  5. 44 of its 75 top-level objects name a P7 routine or port address in",
      "     their own instruction stream (notes/prom_c_split.py --p7census).",
      "⚠ AND WHAT IS NOT CLAIMED: 465 of its 739 labels are still sub_XXXXXX, and",
      "  31 of the 75 objects do not reference P7 directly.  The FILE is named",
      "  for the module; no ROUTINE in 0xF9A050-0xFA2783 is named for what it",
      "  does, and this move does not change that.",
      "⚠ The head banner's line `NO ROUTINE HERE IS NAMED FOR WHAT IT DOES` is",
      "  STALE -- it was generated before the P7Byte_/P7Stream_/Format_ naming",
      "  round -- but it is left exactly as written: this pass moves text, it does",
      "  not reword it."]),

    ("prom_c/voice/voice_leaf_helpers.s", 34012, 39947,
     "0xFA5949-0xFA7E2B  the leaf helpers the voice-parameter module calls",
     ["Banner-declared.  EGEnv_* envelope evaluators, Clamp_*, DetuneCurve_*,",
      "KeyZone_*, VoiceSubsystem_Init and the voice allocator."]),

    ("prom_c/voice/voice_parameters.s", 39948, 48960,
     "0xFA7E2C-0xFABE2F  the VOICE-PARAMETER HELPER MODULE",
     ["Banner-declared.  267 Voice_* labels: pitch, key-zone selection and the",
      "Voice_Stage*/Dev10C_StageRegs_* register stagers."]),

    ("prom_c/devices/dev10c_reg_writers.s", 51184, 51935,
     "0xFACE67-0xFAD141  the register writers for the device at 0x0010C000",
     ["Banner-declared: 17 routines that establish the port's shape",
      "{select, write data, read data} and the `channel + K*0x40` register map.",
      "★ This banner also carries the round-4 NAMING RETRACTION that fixes the",
      "Dev10C_ prefix; keeping it with the driver it governs is the point."]),

    ("prom_c/midi/midi_controllers.s", 51936, 60551,
     "0xFAD142-0xFB0503  the MIDI controllers, the part record and the global setup",
     ["Its top banner is a routine census with no title, but the block is",
      "majority-NAMED and the names agree: 105 MidiCtrl_*, 131 Voice_*,",
      "31 GlobalSetup_*, 19 PartRec_* against 150 sub_XXXXXX.  It carries two of",
      "its own sub-banners -- `THE GLOBAL SETUP RECORD` and `THE PART RECORD, AND",
      "THE CONTROLLERS THAT WRITE IT` -- which is the subject stated by the tree,",
      "not by this pass."]),

    ("prom_c/voice/note_engine.s", 60552, 73024,
     "0xFB0504-0xFB6E09  the MIDI message path and the 64-VOICE NOTE ENGINE",
     ["Two banners the tree itself joins: the second opens `Continues the same",
      "module ... what is left here is the rest of the note engine`.  MidiIn_*,",
      "MidiNote_*, VoiceParams_Compute_A..D, VoiceList_*, Voice_Retire_* and the",
      "68-byte voice record."]),

    ("prom_c/devices/dev10c_dev104_drivers.s", 73025, 76512,
     "0xFB6E0A-0xFB828D  the three register-device drivers, 0x0010C000 and 0x00104000",
     ["Four adjacent banners, one subject: the FULL per-channel register map of",
      "0x0010C000 and the round-7 table of what those registers MEAN; nine helper",
      "routines; the 0x00104000 driver with its 19-register per-channel map; and",
      "the second 0x0010C000 driver with Dev10C_ResetAllChannels, which fixes the",
      "channel count at 64 with a literal loop counter.",
      "⚠ The names stay Dev10C_/Dev104_.  See the header of this file."]),

    ("prom_c/tone_db/tone_db_module.s", 76513, 96679,
     "0xFB828E-0xFC3406  the tone/drum database and the query responders",
     ["Filed on the same three-part test as p7/p7_module.s, and with the same",
      "reservation:",
      "  1. ONE MODULE -- `ret`/`link XIZ` at both cuts.",
      "  2. 97.4% self-contained -- 298 of 306 call sites are inside it.",
      "  3. Its named routines at both ends are one subject: ToneDB_* source- and",
      "     drum-name list selectors near the head, and the ToneQuery_Reply* /",
      "     ToneQuery_Dispatch / LinkQuery_* responders that answer CPU 1 near the",
      "     tail (217 ToneQuery_, 49 ToneDB_, 9 LinkQuery_).",
      "⚠ 1,166 of its 1,490 labels are still sub_XXXXXX.  The FILE is named for",
      "  the module; the routines inside it are not renamed by this pass."]),

    ("prom_c/field_accessors.s", 96680, 107195,
     "0xFC3407-0xFC856B  the field accessors and their callers",
     ["Banner-declared, and kept at the top level BECAUSE it is a grab-bag rather",
      "than a subsystem: Dev104_PackStagingStruct (the sole producer for the",
      "0x00104000 device), the eight-slot note pool, the Q11 fixed-point math",
      "helpers, SoundRam_ClearFourBanks and 511 sub_XXXXXX.  Giving it a",
      "subject directory would assert a cohesion it does not have; the tree's own",
      "title is kept instead."]),

    ("prom_c/storage/flash.s", 107196, 108086,
     "0xFC856C-0xFC89C4  THE FLASH DRIVER, 512 KiB at 0x00E80000",
     ["Banner-declared: 16 routines, the JEDEC command sequences, the two",
      "boot-block sector maps, the 64 KiB staging buffer, and the six routines",
      "the link's three deferred jobs call."]),

    ("prom_c/storage/eeprom.s", 108087, 108560,
     "0xFC89C5-0xFC8BB1  THE SERIAL EEPROM, a Microwire 64 x 16 bit-banged on port pins",
     ["Banner-declared, and the storage behind the key-touch calibration."]),

    ("prom_c/mathlib/mathlib.s", 108561, 114303,
     "0xFC8BB2-0xFCC53E  the math library: double routines, the runtime, the pools",
     ["Three adjacent banners, one subject, and the top one says so: the block at",
      "0xFC8BB2 is `the DOUBLE-PRECISION MATH LIBRARY that sits on top of the",
      "runtime converted just below`.  Then the compiler runtime itself (the",
      "complete IEEE-754 single and double set, 32-bit multiply/divide, the",
      "variable shifts) and the 77-entry f64 coefficient pool those routines",
      "load from.",
      "★ This runtime is sub-CPU-ONLY -- prom_a/b/d define no Float32_/Double_",
      "label -- so unlike kernel/kernel.s it is NOT a shared-source candidate."]),

    ("prom_c/data_tables/touch_eq_mixer.s", 114304, 114985,
     "0xFCC53F-0xFCD0F6  touch / EQ / mixer-gain / descriptor-string zone",
     ["Banner-declared: 15 data objects, including the four ToneGen_ velocity",
      "curves and the 616-byte floating-point constant pool at 0xFCC81A."]),

    ("prom_c/p7/p7_stream_pool.s", 114986, 123837,
     "0xFCD0F7-0xFDD2AA  THE RELOCATABLE BYTE-STREAM POOL, 65,972 bytes",
     ["Banner-declared: 297 length-prefixed streams that P7Stream_Run sends out",
      "port P7 one byte at a time, six data tables and four directory objects.",
      "Framing proved four ways; NO STREAM'S MEANING IS NAMED, and this move does",
      "not change that.  It sits under p7/ beside the code that plays it."]),

    ("prom_c/data_tables/voice_dsp_tables.s", 123838, 125138,
     "0xFDD2AB-0xFDF7DF  the voice / DSP data-table zone, 43 tables",
     ["Banner-declared.  36 of the 43 are byte-identical to a NAMED table in the",
      "KN5000 sub-CPU payload, which is where their names come from."]),

    ("prom_c/data_tables/tail_data_zone.s", 125139, 127418,
     "0xFDF7E0-0xFFEFFF  the tail data zone, copy B of the initialiser, and the pad",
     ["Its umbrella banner plus its three part-banners: the five 256-entry math",
      "tables, the four flash banks named in the ROM, copy B of the initialiser",
      "image emitted as its twin's objects with `_B`, and the 118,298-byte 0x0E",
      "pad that closes the range."]),

    ("prom_c/boot/reset_and_vectors.s", 127419, 127731,
     "0xFFF000-0xFFFFFF  RESET, the trampolines, the vector table and the build tag",
     ["Banner-declared, and the other end of boot/boot_and_main.s: the reset",
      "block that programs the memory controller, the interrupt trampolines every",
      "vector lands on, the 33-entry vector table, the fc-in-MHz configuration",
      "byte and the build tag."]),
]

RESIDUAL_NOTE = """\
WHAT IS LEFT IN THIS FILE, AND WHY

  Two ranges are NOT filed under a subject, on purpose:

    0xFABE30-0xFACE66   23 routines, 4,151 bytes.  Its banner is a routine
                        census with no title; 105 of its 118 labels are
                        sub_XXXXXX; and its callers are a mix -- MidiCtrl_CC120,
                        MidiCtrl_Dispatch, MidiNote_OnByPartMode and four
                        unnamed routines.  Nothing here names a subject, so
                        nothing here gets one.

    the file header     the round-12 inventory and the address map, which is
                        about the WHOLE image and belongs with the whole image.

  A smaller honest split beats a complete dishonest one.  When a later round
  names what 0xFABE30-0xFACE66 is for, moving it is one more line range.
"""


# --------------------------------------------------------------------- helpers
def base_lines():
    """The listing as it stood at BASE_COMMIT, as a list of lines (no newlines)."""
    out = subprocess.run(["git", "show", f"{BASE_COMMIT}:{MASTER}"],
                         cwd=ROOT, capture_output=True, check=True)
    return out.stdout.decode("utf-8").split("\n")


def disk(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as fh:
        return fh.read().split("\n")


def check_spec(lines):
    """Ranges disjoint, sorted, inside the file.  An INVARIANT, not a value."""
    prev = 0
    for path, a, b, _t, _r in SPEC:
        assert 1 <= a <= b <= len(lines), f"{path}: range {a}-{b} outside 1-{len(lines)}"
        assert a > prev, f"{path}: range {a}-{b} overlaps or precedes the one before"
        prev = b


def header_for(path, a, b, title, rationale, lines):
    """The documentation header a moved block gets.  New text; nothing replaced."""
    n = b - a + 1
    out = [
        "; " + "=" * 78,
        f"; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- {title}",
        "; " + "=" * 78,
        ";",
        f"; {n:,} lines moved out of {MASTER} by notes/prom_c_split.py.  The master",
        f"; `.include`s this file at the line the block started on, so the assembler",
        "; sees the same token stream in the same order and the ROM is unchanged:",
        ";",
        ";     python3 scripts/analysis/assert_byte_identical.py    <- the bytes",
        ";     python3 notes/prom_c_split.py --verify               <- the text",
        ";",
        "; ★ EVERY LINE BELOW THIS HEADER IS VERBATIM.  Nothing was reworded, and",
        ";   --verify fails on a single changed character.",
        ";",
        "; WHY THIS IS ONE SUBJECT:",
    ]
    out += ["; " + r for r in rationale]
    out += [
        ";",
        SENTINEL,
        "",
    ]
    return out


# ------------------------------------------------------------------------ emit
def emit():
    lines = base_lines()
    check_spec(lines)
    master, pos = [], 1
    for path, a, b, title, rationale, in SPEC:
        master += lines[pos - 1:a - 1]
        master.append(f'\t.include "{path}"\t; {title}')
        body = lines[a - 1:b]
        full = header_for(path, a, b, title, rationale, lines) + body
        dst = os.path.join(ROOT, path)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8") as fh:
            fh.write("\n".join(full))
        print(f"  wrote {path:44s} {b - a + 1:7,} lines  ({title})")
        pos = b + 1
    master += lines[pos - 1:]
    with open(os.path.join(ROOT, MASTER), "w", encoding="utf-8") as fh:
        fh.write("\n".join(master))
    print(f"  wrote {MASTER:44s} {len(master):7,} lines  (residual + header)")


# ---------------------------------------------------------------------- verify
def body_of(path):
    """The moved block inside an extracted file: everything after its header.

    The boundary is a SENTINEL line, not a stored line count, so editing the
    header prose later cannot silently shift it.  The sentinel's `; >>>` opener
    appears nowhere in the pre-split listing (checked: 0 occurrences), so it
    cannot be confused with a banner the file itself carries -- the first version
    of this function looked for the header's `; ====` rule and found the moved
    block's OWN banner instead, and --verify reported 24 deleted hunks.
    """
    ls = disk(path)
    end = None
    for i, l in enumerate(ls):
        if l.startswith(SENTINEL_PREFIX):
            end = i
            break
    if end is None:
        return ls
    j = end + 1
    while j < len(ls) and ls[j] == "":
        j += 1
    return ls[j:]


def reconstruct():
    out = []
    for l in disk(MASTER):
        m = INCLUDE_RE.match(l)
        if m:
            out += body_of(m.group(1))
        else:
            out.append(l)
    return out


def verify():
    ref, got = base_lines(), reconstruct()
    sm = difflib.SequenceMatcher(None, ref, got, autojunk=False)
    bad, ins = [], []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        if tag == "insert":
            ins += got[j1:j2]
        else:
            bad.append((tag, i1, i2, j1, j2))
    print(f"  reference  {BASE_COMMIT[:7]}:{MASTER}   {len(ref):,} lines")
    print(f"  on disk    master + {len(SPEC)} included files   {len(got):,} lines")
    print(f"  inserted   {len(ins):,} line(s)  (the new per-file headers)")
    if bad:
        print("\n  ★ NOT A PURE MOVE.  These are not insertions:")
        for tag, i1, i2, j1, j2 in bad[:20]:
            print(f"    {tag:7s} reference[{i1}:{i2}] -> reconstruction[{j1}:{j2}]")
            for l in ref[i1:min(i2, i1 + 4)]:
                print(f"      - {l[:110]}")
            for l in got[j1:min(j2, j1 + 4)]:
                print(f"      + {l[:110]}")
        print(f"\nFAIL: {len(bad)} non-insertion hunk(s).")
        return 1
    print("\nPASS: every line of the pre-split listing survives, in order, unaltered.")
    return 0


# ---------------------------------------------------------------------- counts
def census(lines):
    comments = [l for l in lines if l.lstrip().startswith(";")]
    labels = [m.group(1) for m in (LABEL_RE.match(l) for l in lines) if m]
    return comments, labels


def counts():
    ref, got = base_lines(), reconstruct()
    import collections
    rc, rl = census(ref)
    gc, gl = census(got)
    print(f"  comment lines   before {len(rc):7,}   after {len(gc):7,}   "
          f"delta {len(gc) - len(rc):+,}")
    print(f"  label defs      before {len(rl):7,}   after {len(gl):7,}   "
          f"delta {len(gl) - len(rl):+,}")
    lost = collections.Counter(rc) - collections.Counter(gc)
    print(f"  comment lines LOST: {sum(lost.values())}")
    for l, n in list(lost.items())[:10]:
        print(f"    x{n}  {l[:100]}")
    lostl = collections.Counter(rl) - collections.Counter(gl)
    print(f"  labels LOST:        {sum(lostl.values())}")
    for l, n in list(lostl.items())[:10]:
        print(f"    x{n}  {l}")
    dup = [l for l, n in collections.Counter(gl).items() if n > 1]
    print(f"  labels defined more than once after the split: {len(dup)}  {dup[:8]}")
    return 1 if (sum(lost.values()) or sum(lostl.values())) else 0


# -------------------------------------------------------------------- p7census
def p7census():
    """The measurement quoted in p7/p7_module.s's header: how much of the
    0xF9A050-0xFA5948 module names a P7 routine or the port's own send
    addresses in ITS OWN instruction stream, trailing comments stripped."""
    lines = base_lines()
    a, b = 14850, 34011
    tops, lab = [], re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
    for n in range(a, b + 1):
        m = lab.match(lines[n - 1])
        if m and "__" not in m.group(1):
            tops.append((n, m.group(1)))
    tops.append((b + 1, "<end>"))
    keys = ("0xF9A163", "0xF9A31A", "0xF9A4B0",   # P7Byte_SendCmd/SendData/SendArg
            "P7Byte_", "P7Stream_", "P7Unit", "P7Mixer_")
    hit = [n for k in range(len(tops) - 1)
           for n in [tops[k][1]]
           if any(t in "\n".join(l.split(";")[0]
                                 for l in lines[tops[k][0] - 1:tops[k + 1][0] - 1])
                  for t in keys)]
    print(f"  top-level objects in 0xF9A050-0xFA5948 : {len(tops) - 1}")
    print(f"  naming a P7 routine / send address     : {len(hit)}")
    print(f"  not                                    : {len(tops) - 1 - len(hit)}")
    return 0


# -------------------------------------------------------------------- selftest
def selftest():
    """Positive and NEGATIVE controls on a synthetic listing.

    ⚠ Neither check pins a number from prom_c.  They assert what must be true of
    ANY correct splitter, and the negative one is the important half: a probe
    that cannot report a loss is not evidence that there was none.
    """
    import tempfile
    ok = True
    src = [f"line {i}" if i % 7 else f"; comment {i}" for i in range(1, 61)]
    src[19] = "Label_A:"
    src[39] = "Label_B:"

    def split_and_check(mutate):
        with tempfile.TemporaryDirectory() as d:
            body1, body2 = src[9:20], src[29:45]
            os.makedirs(os.path.join(d, "sub"))
            for name, body in (("sub/one.s", body1), ("sub/two.s", body2)):
                # ⚠ the synthetic header ends with the REAL sentinel, and also
                # carries a `; ====` rule -- so this control exercises the exact
                # confusion that broke the first version of body_of().
                hdr = ["; " + "=" * 78, "; synthetic", "; " + "=" * 78,
                       SENTINEL, ""]
                if mutate and name == "sub/one.s":
                    body = body[:3] + body[4:]        # DELETE ONE LINE
                open(os.path.join(d, name), "w").write("\n".join(hdr + body))
            master = (src[:9] + ['\t.include "prom_c/sub/one.s"\t; x'] + src[20:29]
                      + ['\t.include "prom_c/sub/two.s"\t; y'] + src[45:])
            open(os.path.join(d, "master.s"), "w").write("\n".join(master))
            g = globals()
            old_root, old_master, old_inc = ROOT, MASTER, INCLUDE_RE
            g["ROOT"], g["MASTER"] = d, "master.s"
            g["INCLUDE_RE"] = re.compile(r'^\t\.include "prom_c/([^"]+)"')
            try:
                got = reconstruct()
            finally:
                g["ROOT"], g["MASTER"], g["INCLUDE_RE"] = old_root, old_master, old_inc
            sm = difflib.SequenceMatcher(None, src, got, autojunk=False)
            # ⚠ EXACT equality for the synthetic case: the sentinel means the
            # headers are stripped, so a faithful split reconstructs the original
            # with NOTHING inserted.  "insertions only" would pass even if
            # body_of() returned each file's header too, which is the bug the
            # first version had.
            return got == src and all(t == "equal" for t, *_ in sm.get_opcodes())

    if split_and_check(mutate=False):
        print("  ok    a faithful split reconstructs the original exactly")
    else:
        print("  FAIL  a faithful split did NOT reconstruct the original"); ok = False
    if not split_and_check(mutate=True):
        print("  ok    a split with ONE LINE DELETED is DETECTED")
    else:
        print("  FAIL  a deleted line went unnoticed -- the check is vacuous"); ok = False

    # the spec's own invariants
    try:
        check_spec(base_lines())
        print(f"  ok    the {len(SPEC)} spec ranges are sorted, disjoint and in range")
    except AssertionError as e:
        print(f"  FAIL  {e}"); ok = False
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


def plan():
    lines = base_lines()
    check_spec(lines)
    cov, prev = 0, 1
    for path, a, b, title, _r in SPEC:
        if a > prev:
            print(f"  {'':44s} {a - prev:7,} lines  <-- RESIDUAL, stays in the master")
        print(f"  {path:44s} {b - a + 1:7,} lines  {title}")
        cov += b - a + 1
        prev = b + 1
    if prev <= len(lines):
        print(f"  {'':44s} {len(lines) - prev + 1:7,} lines  <-- RESIDUAL")
    print(f"\n  {len(SPEC)} files, {cov:,} of {len(lines):,} lines moved "
          f"({100.0 * cov / len(lines):.1f}%)")
    return 0


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "--plan"
    fn = {"--plan": plan, "--emit": emit, "--verify": verify, "--counts": counts,
          "--selftest": selftest, "--p7census": p7census}.get(arg)
    if fn is None:
        print(__doc__)
        sys.exit(2)
    sys.exit(fn() or 0)
