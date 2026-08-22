#!/usr/bin/env python3
"""Do the `ld (r32+r),r` sites still stuck in `.byte` blobs really convert?

QUESTION ANSWERED
-----------------
`tools/spelling-probes/verify_ld_regreg_store.py` proved the spelling rule
against every site in the *ROM listings*.  This script asks the narrower
question a converter actually cares about:

    for every `ld (r32+r),<register>` that is still sitting inside a `.byte`
    blob in the v7 / v9 disassembly sources -- i.e. every instance that is
    blocking conversion right now -- does the rule reproduce the exact bytes,
    and are those blob bytes genuinely present in the ROM image?

It is an INDEPENDENT re-implementation: it harvests from the sources rather
than from the listing, it re-derives the spelling from the raw bytes, and it
adds a provenance gate the listing-based probe does not need (a blob is only
counted once its byte string has been located in the ROM file itself, which
also yields the site's real address).

THE RULE UNDER TEST (a function of the raw bytes, never of the printed text)
---------------------------------------------------------------------------
    f3 <m> <base> <index> <sub>        m = 0x03 -> index byte is an 8-bit reg
                                       m = 0x07 -> index byte is a 16-bit reg
    sub = 0x40|r  ->  lda_dri  GPR[r],  m, base, index    ; stores an  8-bit reg
    sub = 0x50|r  ->  stw_dri  GR16[r], m, base, index    ; stores a 16-bit reg
    sub = 0x60|r  ->  stl_dri  GPR[r],  m, base, index    ; stores a 32-bit reg
    GPR[r]  = xwa xbc xde xhl xix xiy xiz xsp
    GR16[r] = wa  bc  de  hl  ix  iy  iz          (GR16 has no SP -> sub 0x57
                                                   is unspellable; 0 sites)
The mnemonic comes from the sub-opcode's HIGH nibble; the register operand
only supplies the low nibble.  So an 8-bit store is written with a 32-BIT
register name of the same encoding: `ld (XIY+HL),A` = `lda_dri xbc, ...`,
because A and XBC are both register 1.  The backend's `lda_dri` is misnamed:
sub 0x40|r is `ld (mem),r8`, not `lda`.  MAME's own dst table agrees --
src/devices/cpu/tlcs900/dasm900.cpp, `mnemonic_f0[]`: 0x20|r LDA r16,
0x30|r LDA r32, 0x40|r LD (mem),r8, 0x50|r LD (mem),r16, 0x60|r LD (mem),r32.

COMMAND
-------
    python3 tools/spelling-probes/verify_ld_regreg_store_from_blobs.py

RESULT WHEN WRITTEN (2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b,
unidasm from ~/compartilhado/tools/unidasm)
-----------------------------------------------------------------
    v7 sources: 948 `.byte` blobs containing an 0xF3 scanned -> 239 sites
    v9 sources:  34 `.byte` blobs containing an 0xF3 scanned ->   2 sites
    TEST 1 blob byte-string found in the matching ROM image : 241/241
    TEST 2 assembled bytes == blob bytes                    : 241/241
    TEST 3 assembled bytes re-disassemble to identical text : 241/241
    TEST 4 negative controls produced DIFFERENT bytes       :   4/4
    sub-opcodes seen: 0x40 0x41 0x42 0x43 0x44 0x45 0x46 0x47
                      0x50 0x51 0x52 0x53 0x55
    (12 of the 241 sit in a blob whose byte string is not unique in the ROM;
     only the reported ADDRESS is ambiguous there, never the bytes.)
    Negative controls, all four of which ASSEMBLE cleanly:
      ld (XIY+HL),A                 -> f3 f5 A A 41  ((XIY+d16), HL relocated)
      stb_dri a, 0x07,0xf4,0xec     -> f3 07 f4 ec 31   (that is `lda XBC,mem`)
      ldb_dri a, 0x07,0xf4,0xec     -> c3 07 f4 ec 21   (the load direction)
      stl_dri xbc, 0x07,0xf4,0xec   -> f3 07 f4 ec 61   (32-bit store)
    against ROM f3 07 f4 ec 41.
WHAT WOULD FALSIFY IT: any site where llvm-mc emits bytes other than the
blob's.  TEST 2 prints and counts every mismatch; it reported none.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

SOURCES = [("v7", "v7/maincpu", "original_ROMs/kn5000_v7_program.rom"),
           ("v9", "v9/maincpu", "original_ROMs/kn5000_v9_program.rom")]
LOAD_BASE = 0xE00000

GPR  = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
GR16 = ["wa",  "bc",  "de",  "hl",  "ix",  "iy",  "iz",  None]   # no SP

BYTE_LINE = re.compile(r"^\s*\.byte\s+(.*?)\s*(?:;.*)?$")
DASM_LINE = re.compile(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*?)\s*$")
FORM      = re.compile(r"^ld \(X[A-Z]{2}\+[A-Z]{1,2}\),[A-Z]")


def spell(b):
    """Derive the llvm-mc spelling from the five raw bytes, or None."""
    if len(b) != 5 or b[0] != 0xF3 or b[1] not in (0x03, 0x07):
        return None
    sub, r = b[4] & 0xF0, b[4] & 0x07
    if b[4] & 0x08:
        return None
    reg = {0x40: GPR, 0x50: GR16, 0x60: GPR}.get(sub, [None] * 8)[r]
    mnem = {0x40: "lda_dri", 0x50: "stw_dri", 0x60: "stl_dri"}.get(sub)
    if reg is None or mnem is None:
        return None
    return "%s %s, 0x%02x, 0x%02x, 0x%02x" % (mnem, reg, b[1], b[2], b[3])


def unidasm(blob, basepc=0):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as t:
        t.write(blob)
        name = t.name
    try:
        out = subprocess.run([UNIDASM, name, "-arch", "tlcs900",
                              "-basepc", hex(basepc)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(name)
    return out


def assemble(lines):
    src = "".join("\t%s\n" % l for l in lines)
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False) as t:
        t.write(src)
        name = t.name
    try:
        r = subprocess.run([LLVM_MC, "-triple=tlcs900", "--show-encoding", name],
                           capture_output=True, text=True)
    finally:
        os.unlink(name)
    encs = []
    for m in re.finditer(r"encoding: \[([^\]]*)\]", r.stdout):
        vals = []
        for tok in m.group(1).split(","):
            tok = tok.strip()
            vals.append(int(tok, 16) if tok.startswith("0x") else None)
        encs.append(vals)
    return encs, r.stdout, r.stderr


def blobs_of(path):
    out, cur, start = [], [], None
    for lineno, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        m = BYTE_LINE.match(line)
        vals = None
        if m:
            vals = []
            for tok in m.group(1).split(","):
                tok = tok.strip()
                try:
                    vals.append(int(tok, 0) & 0xFF)
                except ValueError:
                    vals = None
                    break
        if vals:
            if not cur:
                start = lineno
            cur.extend(vals)
        elif cur:
            out.append((start, bytes(cur)))
            cur = []
    if cur:
        out.append((start, bytes(cur)))
    return out


def main():
    sites, nblobs = [], {}
    for tag, srcdir, rompath in SOURCES:
        rom = open(os.path.join(ROOT, rompath), "rb").read()
        n = 0
        for dirpath, _, files in os.walk(os.path.join(ROOT, srcdir)):
            for fn in sorted(files):
                if not fn.endswith(".s"):
                    continue
                for lineno, blob in blobs_of(os.path.join(dirpath, fn)):
                    if len(blob) < 5 or b"\xf3" not in blob:
                        continue
                    n += 1
                    hits = []
                    for line in unidasm(blob).splitlines():
                        m = DASM_LINE.match(line)
                        if m and FORM.match(m.group(3)):
                            off = int(m.group(1), 16)
                            hits.append((off, blob[off:off + 5], m.group(3)))
                    if not hits:
                        continue
                    # provenance: the blob's bytes must live in the ROM image
                    at = rom.find(blob)
                    uniq = (at >= 0 and rom.find(blob, at + 1) < 0)
                    for off, ib, txt in hits:
                        sites.append(dict(tag=tag, file=os.path.relpath(
                            os.path.join(dirpath, fn), ROOT), line=lineno,
                            addr=(LOAD_BASE + at + off) if at >= 0 else None,
                            uniq=uniq, bytes=ib, text=txt))
        nblobs[tag] = n

    print("blobs scanned: " + ", ".join("%s:%d" % (k, v) for k, v in nblobs.items()))
    print("sites of the form: " + ", ".join(
        "%s:%d" % (t, sum(1 for s in sites if s["tag"] == t)) for t, _, _ in SOURCES))

    # TEST 1 -- provenance
    found = sum(1 for s in sites if s["addr"] is not None)
    print("TEST 1 blob located in the ROM image      : %d/%d" % (found, len(sites)))
    for s in sites:
        if s["addr"] is None:
            print("   NOT IN ROM: %s:%d %s" % (s["file"], s["line"], s["bytes"].hex()))

    # TEST 2 -- bytes
    spells = []
    for s in sites:
        sp = spell(s["bytes"])
        s["spell"] = sp
        if sp is None:
            print("   NO SPELLING: %s  %s" % (s["bytes"].hex(), s["text"]))
    todo = [s for s in sites if s["spell"]]
    encs, _, err = assemble([s["spell"] for s in todo])
    if len(encs) != len(todo):
        print("!! llvm-mc emitted %d encodings for %d lines" % (len(encs), len(todo)))
        print(err[:2000])
        return 1
    ok = 0
    for s, e in zip(todo, encs):
        got = bytes(x for x in e if x is not None) if all(
            x is not None for x in e) else None
        s["got"] = got
        if got == s["bytes"]:
            ok += 1
        else:
            print("   MISMATCH %s  %-28s -> %s  (ROM %s)" % (
                hex(s["addr"] or 0), s["spell"], e, s["bytes"].hex()))
    print("TEST 2 assembled bytes == blob bytes      : %d/%d" % (ok, len(sites)))

    # TEST 3 -- round-trip through unidasm
    rt = 0
    for s in todo:
        if s.get("got") != s["bytes"]:
            continue
        out = unidasm(s["got"]).splitlines()
        m = DASM_LINE.match(out[0]) if out else None
        if m and m.group(3) == s["text"]:
            rt += 1
        else:
            print("   ROUNDTRIP %s: %r != %r" % (
                hex(s["addr"] or 0), m.group(3) if m else None, s["text"]))
    print("TEST 3 round-trip text identical          : %d/%d" % (rt, len(sites)))

    # TEST 4 -- negative controls: these ASSEMBLE and are WRONG
    ctrl = [("ld (XIY+HL),A",                 bytes.fromhex("f307f4ec41")),
            ("stb_dri a, 0x07, 0xf4, 0xec",   bytes.fromhex("f307f4ec41")),
            ("ldb_dri a, 0x07, 0xf4, 0xec",   bytes.fromhex("f307f4ec41")),
            ("stl_dri xbc, 0x07, 0xf4, 0xec", bytes.fromhex("f307f4ec41"))]
    encs, _, _ = assemble([c[0] for c in ctrl])
    diff = 0
    for (txt, romb), e in zip(ctrl, encs):
        got = bytes(x for x in e if x is not None) if all(
            x is not None for x in e) else None
        flag = "DIFFERS" if got != romb else "*** SAME -- control failed ***"
        if got != romb:
            diff += 1
        shown = "[" + ",".join("0x%02x" % x if x is not None else "A"
                               for x in e) + "]"
        print("   %-30s -> %s  %s (ROM %s)" % (txt, shown, flag, romb.hex()))
    print("TEST 4 negative controls differ           : %d/%d" % (diff, len(ctrl)))

    subs = sorted({s["bytes"][4] for s in sites})
    print("sub-opcodes seen: " + " ".join("0x%02x" % x for x in subs))
    nonuniq = sum(1 for s in sites if s["addr"] is not None and not s["uniq"])
    print("(sites whose blob byte-string is not unique in the ROM: %d -- the "
          "address shown is the first match)" % nonuniq)
    return 0 if (ok == len(sites) and rt == len(sites)
                 and found == len(sites) and diff == len(ctrl)) else 1


if __name__ == "__main__":
    sys.exit(main())
