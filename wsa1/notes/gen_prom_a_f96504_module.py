#!/usr/bin/env python3
"""Emit prom_a 0xF96504-0xF96C65 (1,889 B) -- the largest `.incbin` left in
prom_a -- as real source: 8 handler routines plus three typed data objects.

QUESTION IT ANSWERS
    "The 1,889 bytes at 0xF96504 sit between two already-converted routines and
     nothing in the tree frames them.  What are they, and what typing is forced
     rather than guessed?"

★ THE READER WAS ALREADY CONVERTED, AND IT NAMES EVERY PART OF THIS SPAN

    `.LF964B9` (0xF964B9-0xF96503, converted in an earlier round, immediately
    ABOVE this span) is a small interpreter.  Read it and the whole span falls
    out; nothing here is inferred from decode plausibility.

        .LF964B9:  xor BC,BC                        ; BC = byte cursor
        .LF964BB:  ld HL,BC
                   mx_ld_rm MXL,ra_IX,ra_HL,r6      ; XIZ = *(XIX + BC)
                   cp XIZ,0xffffffff / jr z, done   ; 0xFFFFFFFF terminates
                   add XIZ,XIY                      ; XIZ = struct base + offset
                   inc 4,BC / ld HL,BC
                   push XIX
                   mx_ld_rm MXL,ra_IX,ra_HL,r4      ; XIX = *(XIX + BC)  <- script
                   inc 4,BC
        .LF964D8:  xor H,H / ld L,(XIX)             ; L = opcode byte
                   cp L,0xff / jr z, .LF96500       ; 0xFF ends the script
                   sla hl,0x02 / extz XHL
                   add XHL,0x00f969a1               ; <-- HANDLER TABLE BASE
                   ld XDE,(XHL)
                   inc 1,XIX
                   xor XHL,XHL / ld L,(XIX)         ; L = field offset byte
                   add XHL,XIZ                      ; XHL = &struct.field
                   ld A,(XHL)                       ; A = current field value
                   inc 1,XIX
                   pushw bc / call (xde) / popw bc  ; handler may consume more
                   jr .LF964D8

    So the interpreter walks an array of (u32 struct offset, u32 script pointer)
    pairs ending in 0xFFFFFFFF, and each script is a byte stream of
    (opcode, field-offset, opcode-specific immediates) records ending in 0xFF.
    Three literal addresses in already-converted code fix the three arrays:

        0x00F969A1   `add XHL,0x00f969a1` at 0xF964E6   -- handler table base
        0x00F969DD   `ld XIX,0x00f969dd` at 0xF96455 and 0xF96484
        0x00F96AA1   `ld XIX,0x00f96aa1` at 0xF96476

    All three are INSIDE this span, and all three are cited by code that was
    converted before this pass and is not being re-litigated here.

WHAT THAT BUYS, PART BY PART

  0xF96504-0xF9667A (374 B) -- CODE, 8 routines.
      The handler table's 8 non-zero slots hold exactly
      0xF96504, 0xF96512, 0xF9651E, 0xF96527, 0xF96574, 0xF965C1, 0xF9660E,
      0xF9650B.  A linear decode from 0xF96504 produces exactly 8 routines and
      their `ret`s land on exactly those 8 start addresses -- i.e. the table
      (data) and the decode (code) agree without being told about each other.
      Emitted through prom_a/roundtrip.py, so every instruction has been
      re-assembled and byte-compared.

  0xF9667A-0xF969A1 (807 B) -- DATA, the scripts.
      TYPED, NOT DISASSEMBLED.  Every byte is reached by walking the scripts the
      two tables point at, using per-opcode record widths read off the handlers:
          0x01 0x02 0x03 0x08 : 3 bytes  (op, field, imm)
          0x04 0x05           : 6 bytes  (op, field, mask, 3 more)
          0x06                : 4+n      (op, field, mask, n, n values)
          0x07                : 5+n      (op, field, mask, n, n values, 1 more)
          0xFF                : 1 byte,  end of script
      The widths come from where each handler leaves XIX: e.g. 0x01 is
      `and A,(XIX) / ld (XHL),A / inc 1,XIX / ret`, one immediate; 0x06 ends
      `add XIX,XDE / inc 1,XIX` with DE = the un-consumed part of its value
      list, which lands on the byte after the list.
      ★ The walk TILES 0xF9667A-0xF969A1 exactly: no byte unvisited, no byte
      visited twice from two scripts, no script running past 0xF969A1, and no
      opcode outside the 8 the table populates.  That is the check that could
      have failed, and it is re-run on every invocation (--audit prints it).

  0xF969A1-0xF969DD (60 B) -- DATA, the handler table: 15 LE32 slots, of which
      1-8 are the routines above and 0 and 9-14 are zero.  No script uses an
      opcode outside 1-8, so the zero slots are never called.

  0xF969DD-0xF96AA1 (196 B) -- DATA, table A: 24 (offset, script) pairs and the
      0xFFFFFFFF terminator.  Ends EXACTLY where table B begins.

  0xF96AA1-0xF96C65 (452 B) -- DATA, table B: 56 pairs and the terminator.
      Ends EXACTLY on 0xF96C65, the end of the `.incbin` this span replaces --
      a boundary this script did not choose.

WHY THE DATA IS NOT DISASSEMBLED
    Because nothing calls or jumps into it: every reference to 0xF9667A-0xF96C65
    LOADS AN ADDRESS (`ld XIX,0x00f969dd`) or reads it as an operand.  Framing it
    as instructions would re-assemble to the same bytes and pass the byte gate
    while being wrong; that failure mode is the one this push has hit most.

RUN
    python3 notes/gen_prom_a_f96504_module.py --audit    # the structure + checks
    python3 notes/gen_prom_a_f96504_module.py            # the assembly
    python3 notes/gen_prom_a_f96504_module.py --splice   # write it into the .s
"""
import importlib.util
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")

LO, HI = 0xF96504, 0xF96C65          # the whole .incbin being replaced
CODE_LO, CODE_HI = 0xF96504, 0xF9667A
SCRIPT_LO, SCRIPT_HI = 0xF9667A, 0xF969A1
HTAB = 0xF969A1                      # `add XHL,0x00f969a1` at 0xF964E6
TAB_A = 0xF969DD                     # `ld XIX,0x00f969dd`  at 0xF96455/0xF96484
TAB_B = 0xF96AA1                     # `ld XIX,0x00f96aa1`  at 0xF96476

# Per-opcode record width, read off the handler routines (see the docstring).
# n is the count byte at record offset 3 for the two variable forms.
FIXED = {0x01: 3, 0x02: 3, 0x03: 3, 0x04: 6, 0x05: 6, 0x08: 3}
VARIABLE = {0x06: 4, 0x07: 5}


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "wsa1_rt_f96504")


def rom():
    return open(ROM, "rb").read()


def u32(d, a):
    o = a - BASE
    return d[o] | d[o + 1] << 8 | d[o + 2] << 16 | d[o + 3] << 24


def handler_table(d):
    return [u32(d, HTAB + 4 * i) for i in range((TAB_A - HTAB) // 4)]


def pairs(d, base):
    """(offset, script) pairs up to the 0xFFFFFFFF terminator; also its end."""
    out, a = [], base
    while u32(d, a) != 0xFFFFFFFF:
        out.append((u32(d, a), u32(d, a + 4)))
        a += 8
    return out, a + 4


def record_len(d, a):
    op = d[a - BASE]
    if op == 0xFF:
        return 1
    if op in FIXED:
        return FIXED[op]
    if op in VARIABLE:
        return VARIABLE[op] + d[a - BASE + 3]
    return None                       # unknown opcode: the walk fails loudly


def walk_script(d, a):
    """[(addr, length, opcode)] for one script, or None if it runs off the end."""
    out = []
    while True:
        if not (SCRIPT_LO <= a < SCRIPT_HI):
            return None
        n = record_len(d, a)
        if n is None or a + n > SCRIPT_HI:
            return None
        out.append((a, n, d[a - BASE]))
        if d[a - BASE] == 0xFF:
            return out
        a += n


def structure():
    """Everything the emitter and the audit both need, plus the tiling check."""
    d = rom()
    ht = handler_table(d)
    pa, end_a = pairs(d, TAB_A)
    pb, end_b = pairs(d, TAB_B)
    scripts, cover, errs = {}, {}, []
    for tag, ps in (("A", pa), ("B", pb)):
        for i, (_off, ptr) in enumerate(ps):
            if ptr in scripts:
                continue
            w = walk_script(d, ptr)
            if w is None:
                errs.append("%s[%d] script 0x%06X does not walk" % (tag, i, ptr))
                continue
            scripts[ptr] = w
    for ptr, w in scripts.items():
        for a, n, _op in w:
            for k in range(a, a + n):
                if k in cover:
                    errs.append("byte 0x%06X covered twice" % k)
                cover[k] = ptr
    missing = [a for a in range(SCRIPT_LO, SCRIPT_HI) if a not in cover]
    used_ops = sorted({op for w in scripts.values() for _a, _n, op in w if op != 0xFF})
    return dict(rom=d, ht=ht, pa=pa, pb=pb, end_a=end_a, end_b=end_b,
                scripts=scripts, cover=cover, missing=missing,
                used_ops=used_ops, errs=errs)


def checks(S):
    d = S["rom"]
    code_ends = []
    rows, _st = RT.convert(CODE_LO, CODE_HI)
    for addr, bs, _t, _w, u in rows:
        if (u or "").strip() == "ret":
            code_ends.append(addr + len(bs))
    slots = [v for v in S["ht"] if v]
    out = [
        ("handler table has exactly 8 non-zero slots", len(slots) == 8),
        ("every non-zero slot is inside the code sub-span",
         all(CODE_LO <= v < CODE_HI for v in slots)),
        ("the 8 slots are exactly the 8 addresses a linear decode from "
         "0x%06X makes routine starts" % CODE_LO,
         sorted(slots) == sorted([CODE_LO] + code_ends[:-1])),
        ("the last `ret` of that decode ends exactly on 0x%06X" % CODE_HI,
         code_ends and code_ends[-1] == CODE_HI),
        ("scripts tile 0x%06X-0x%06X with no gap" % (SCRIPT_LO, SCRIPT_HI),
         not S["missing"]),
        ("...and no byte claimed by two scripts, and no script overruns",
         not S["errs"]),
        ("no script uses an opcode the handler table leaves zero",
         all(S["ht"][op] for op in S["used_ops"])),
        ("table A's terminator ends exactly where table B starts",
         S["end_a"] == TAB_B),
        ("table B's terminator ends exactly on the .incbin's end 0x%06X" % HI,
         S["end_b"] == HI),
        ("every script pointer in both tables lands in the script area",
         all(SCRIPT_LO <= p < SCRIPT_HI for _o, p in S["pa"] + S["pb"])),
        ("the parts add up to the .incbin's 1,889 bytes",
         (CODE_HI - CODE_LO) + (SCRIPT_HI - SCRIPT_LO) + (TAB_A - HTAB)
         + (S["end_a"] - TAB_A) + (S["end_b"] - TAB_B) == HI - LO),
    ]
    return out


def emit():
    d = S = structure()
    d = S["rom"]
    bad = [t for t, ok in checks(S) if not ok]
    if bad:
        sys.exit("REFUSING TO EMIT: failed check(s): %s" % "; ".join(bad))

    L = []
    L.append("; ==============================================================================")
    L.append("; 0x%06X-0x%06X -- a bit-field SCRIPT INTERPRETER's handlers and its three tables" % (LO, HI))
    L.append("; ==============================================================================")
    L.append(";")
    L.append("; Converted 2026-09-02 by notes/gen_prom_a_f96504_module.py, which re-derives")
    L.append("; every boundary below on each run and refuses to emit if one moves.")
    L.append("; Full argument: notes/FINDINGS-prom_a-f96504-script-tables.md.")
    L.append(";")
    L.append("; The reader is `.LF964B9` (0xF964B9, converted earlier, just above): it walks")
    L.append("; an array of (u32 struct offset, u32 script pointer) pairs terminated by")
    L.append("; 0xFFFFFFFF, and for each script executes (opcode, field offset, immediates)")
    L.append("; records until 0xFF.  Its three literal addresses -- `add XHL,0x00f969a1` at")
    L.append("; 0xF964E6, `ld XIX,0x00f969dd` at 0xF96455/0xF96484 and `ld XIX,0x00f96aa1`")
    L.append("; at 0xF96476 -- are what fix the three tables below.  Nothing here rests on")
    L.append("; decode plausibility.")
    L.append(";")
    L.append("; ★ THE CHECK THAT COULD HAVE FAILED: walking every script the two tables name,")
    L.append(";   with record widths read off the handlers, TILES 0x%06X-0x%06X exactly --" % (SCRIPT_LO, SCRIPT_HI))
    L.append(";   %d scripts, %d records, no gap, no byte claimed twice, no overrun, and no"
             % (len(S["scripts"]), sum(len(w) for w in S["scripts"].values())))
    L.append(";   opcode outside the %d the handler table populates (%s are the %d actually"
             % (len([v for v in S["ht"] if v]),
                " ".join("0x%02x" % o for o in S["used_ops"]), len(S["used_ops"])))
    L.append(";   used by these scripts).")
    L.append(";")
    L.append("; What these fields MEAN is not established -- the layout is.  The handlers are")
    L.append("; `sub_XXXXXX`: an address plus its dispatch slot, not a claim.")
    L.append("; ------------------------------------------------------------------------------")

    # --- the code
    block, ok, _cs = RT.emit_block(CODE_LO, CODE_HI)
    if not ok:
        sys.exit("REFUSING TO EMIT: 0x%06X-0x%06X did not round-trip" % (CODE_LO, CODE_HI))
    slot_of = {v: i for i, v in enumerate(S["ht"]) if v}
    for text, addr, bs, _why in block:
        if addr is None:
            L.append(text)
            continue
        if addr in slot_of:
            L.append("sub_%06X:   ; script opcode 0x%02X handler "
                     "(slot %d of ScriptOpHandlers_F969A1)"
                     % (addr, slot_of[addr], slot_of[addr]))
        raw = " ".join("%02x" % x for x in bs)
        L.append("\t%-52s ; %06X  %s" % (text.lstrip("\t"), addr, raw))

    # --- the scripts
    L.append("; ------------------------------------------------------------------------------")
    L.append("; 0x%06X-0x%06X -- the SCRIPTS.  DATA: nothing calls or jumps here; the only" % (SCRIPT_LO, SCRIPT_HI))
    L.append("; references LOAD these addresses out of the two tables below.  One line per")
    L.append("; record, `op field imm...`, widths from the handlers (0x01/0x02/0x03/0x08 = 3,")
    L.append("; 0x04/0x05 = 6, 0x06 = 4+n, 0x07 = 5+n, 0xFF = end).")
    L.append("; ------------------------------------------------------------------------------")
    named = {}
    for ptr in sorted(S["scripts"]):
        named[ptr] = "Script_%06X" % ptr
    for ptr in sorted(S["scripts"]):
        users = ["A[%d]" % i for i, (_o, p) in enumerate(S["pa"]) if p == ptr]
        users += ["B[%d]" % i for i, (_o, p) in enumerate(S["pb"]) if p == ptr]
        L.append("%s:   ; %d record(s), named by %s"
                 % (named[ptr], len(S["scripts"][ptr]) - 1, ", ".join(users)))
        for a, n, op in S["scripts"][ptr]:
            bs = S["rom"][a - BASE:a - BASE + n]
            vals = ", ".join("0x%02x" % x for x in bs)
            tag = "end" if op == 0xFF else "op 0x%02x field 0x%02x" % (bs[0], bs[1])
            L.append("\t.byte %-38s ; %06X  %s" % (vals, a, tag))

    # --- the handler table
    L.append("; ------------------------------------------------------------------------------")
    L.append("; ScriptOpHandlers_F969A1 -- %d LE32 slots indexed by the opcode byte"
             % len(S["ht"]))
    L.append("; (`sla hl,0x02 / add XHL,0x00f969a1 / ld XDE,(XHL) / call (xde)`).  Slots %s"
             % ", ".join(str(i) for i, v in enumerate(S["ht"]) if v))
    L.append("; are the routines above; the rest are zero and no script names them.")
    L.append("; ------------------------------------------------------------------------------")
    L.append("ScriptOpHandlers_F969A1:")
    for i, v in enumerate(S["ht"]):
        note = ("opcode 0x%02x" % i) if v else "unused"
        L.append("\t.long 0x%08x   ; %06X  [%2d] %s" % (v, HTAB + 4 * i, i, note))

    # --- the two pair tables
    for tag, base, ps, end in (("A", TAB_A, S["pa"], S["end_a"]),
                               ("B", TAB_B, S["pb"], S["end_b"])):
        who = ("`ld XIX,0x00f969dd` at 0xF96455 and 0xF96484" if tag == "A"
               else "`ld XIX,0x00f96aa1` at 0xF96476")
        L.append("; ------------------------------------------------------------------------------")
        L.append("; ScriptTable%s_%06X -- %d (u32 struct offset, u32 script) pairs then the"
                 % (tag, base, len(ps)))
        L.append("; 0xFFFFFFFF terminator `.LF964B9` stops on.  Named by %s." % who)
        L.append("; ------------------------------------------------------------------------------")
        L.append("ScriptTable%s_%06X:" % (tag, base))
        a = base
        for i, (off, ptr) in enumerate(ps):
            L.append("\t.long 0x%08x, 0x%08x   ; %06X  [%2d] +0x%04x -> %s"
                     % (off, ptr, a, i, off, named.get(ptr, "?")))
            a += 8
        L.append("\t.long 0xffffffff   ; %06X  end of table" % a)
    return L


def verify(lines):
    src = RT.macro_prelude() + "\n\t.text\n" + "\n".join(lines) + "\n"
    d = tempfile.mkdtemp()
    a_s, a_o, a_b = d + "/r.s", d + "/r.o", d + "/r.bin"
    open(a_s, "w").write(src)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "-filetype=obj",
                        "-I", ROOT, "-I", os.path.join(ROOT, "prom_a"),
                        "-o", a_o, a_s], capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return False, r.stderr[-2000:]
    r = subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", a_o, a_b],
                       capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return False, r.stderr[-2000:]
    got = open(a_b, "rb").read()
    want = rom()[LO - BASE:HI - BASE]
    return got == want, ("%d bytes vs %d" % (len(got), len(want)) if got != want else "")


def main():
    S = structure()
    if "--audit" in sys.argv:
        print("0x%06X-0x%06X  %d bytes" % (LO, HI, HI - LO))
        print("  code    0x%06X-0x%06X  %4d B  8 handler routines"
              % (CODE_LO, CODE_HI, CODE_HI - CODE_LO))
        print("  scripts 0x%06X-0x%06X  %4d B  %d scripts, %d records"
              % (SCRIPT_LO, SCRIPT_HI, SCRIPT_HI - SCRIPT_LO, len(S["scripts"]),
                 sum(len(w) for w in S["scripts"].values())))
        print("  handler 0x%06X-0x%06X  %4d B  %d LE32 slots, %d non-zero"
              % (HTAB, TAB_A, TAB_A - HTAB, len(S["ht"]), len([v for v in S["ht"] if v])))
        print("  table A 0x%06X-0x%06X  %4d B  %d pairs + terminator"
              % (TAB_A, S["end_a"], S["end_a"] - TAB_A, len(S["pa"])))
        print("  table B 0x%06X-0x%06X  %4d B  %d pairs + terminator"
              % (TAB_B, S["end_b"], S["end_b"] - TAB_B, len(S["pb"])))
        print("  opcodes used: %s" % " ".join("0x%02x" % o for o in S["used_ops"]))
        bad = 0
        for text, ok in checks(S):
            print("  [%s] %s" % ("ok" if ok else "FAIL", text))
            bad += not ok
        for e in S["errs"]:
            print("  !! %s" % e)
        return 1 if bad or S["errs"] else 0
    lines = emit()
    ok, why = verify(lines)
    if not ok:
        sys.exit("REFUSING TO PRINT: emitted text does not rebuild the span (%s)" % why)
    if "--splice" in sys.argv:
        tmp = tempfile.mktemp(suffix=".s")
        open(tmp, "w").write("\n".join(lines) + "\n")
        r = subprocess.run([sys.executable,
                            os.path.join(ROOT, "prom_a", "insert_region.py"),
                            hex(LO), hex(HI), tmp],
                           capture_output=True, text=True, cwd=ROOT)
        os.unlink(tmp)
        if r.returncode != 0:
            sys.exit("splice failed: %s%s" % (r.stdout, r.stderr))
        print(r.stdout.strip())
        return 0
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
