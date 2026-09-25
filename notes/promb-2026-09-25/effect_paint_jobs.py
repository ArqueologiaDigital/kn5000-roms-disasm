#!/usr/bin/env python3
r"""prom_b 0xF10D62-0xF10F08 and 0xF1173A: code the source carried as data, and the eight paint jobs.

QUESTION THIS ANSWERS
    `Data_F10D62` (158 B), `Data_F10E0F` (240 B) and `Data_F1173A` (4 B) were
    framed as bytes "the code walk never reached".  The 24-bit operand sweep
    (reader24_sweep.py) finds each one's address spelled by an instruction:

      0xF1011B  lda XBC,0xF10D62 / push XBC / call T_CallbackQueue_Post
      0xF10E07  lda XIY,0xF10E0F / push XIY / jp (XIX)      -- a return point
      0xF11732  lda XIY,0xF1173A / push XIY / jp (XBC)      -- a return point

    so the first is a routine ENTRY handed to the callback queue and the other
    two are the places a hand-made call returns to.  They are code.  Converting
    them also exposes a MISFRAME: the source's instruction at 0xF10EFF
    (`ld XIZ,0xd100170b`) and the three after it start inside the real
    instruction `ld (0x2793),H` at 0xF10EFC; the real stream resynchronises at
    0xF10F09.

    And the routine at 0xF10D62 is one of EIGHT that share a shape: each is
    posted to T_CallbackQueue_Post (`lda XBC,entry / push XBC / call 0xF42E84`)
    by a routine that first sets bit n of (0x2799), and each one's first
    instructions clear that same bit (`res n,(0x2799)`) -- so (0x2799) is the
    effect editor's set of pending paint jobs and the eight routines are the
    jobs.  This script checks all of that from the ROM bytes.

WHAT --apply DOES
    * transcribes the three islands with notes/llvm_roundtrip_autoforce.py
      (llvm-mc round trip against the ROM) and respells each line in this
      file's house forms (`lda xbc, (N:24)`, `m_res n, MD16, 0xNNNN`, ...),
      assembling every respelt line against the ROM bytes before writing;
    * replaces the three `.byte` objects and the four misframed lines;
    * names the eight jobs EffectEditor_PaintJob0..7, the hand-made return
      points <Routine>_ResumeN, and re-parents the `Data_*_Code_*` branch
      labels that sat under the old data names.

RUN (the sequence that produced commit "four paint-job routines ...")
    python3 notes/promb-2026-09-25/effect_paint_jobs.py            # checks
    python3 notes/promb-2026-09-25/effect_paint_jobs.py --apply    # write the source
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    python3 notes/promb-2026-09-25/effect_paint_jobs.py --post     # name the return points
    python3 scripts/converters/symbolize_numeric_branches.py --image prom_b \
            --only prom_b/wsa1_prom_b.s --apply --verify
    python3 notes/promb-2026-09-25/effect_paint_jobs.py --post     # re-parent branch labels
    make gate-wsa1
    (--post is idempotent: it renames only names that are still present.)
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WSA1 = os.path.join(ROOT, "wsa1")
SRC = os.path.join(WSA1, "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(WSA1, "original_ROMs", "wsa1_prom_b.ic13")
AUTOFORCE = os.path.join(WSA1, "notes", "llvm_roundtrip_autoforce.py")
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
BASE = 0xF00000
POST = 0xF42E84          # T_CallbackQueue_Post
FLAGS = 0x2799
FAIL = []

# the eight jobs: entry address -> current label
JOBS = [0xF0F820, 0xF0F91C, 0xF0F9F1, 0xF0FDCE, 0xF0FED6, 0xF10D62, 0xF10EB8, 0xF10EDA]
# islands to convert: (lo, hi) -- hi exclusive; the second one swallows the misframe
ISLANDS = [(0xF10D62, 0xF10E00), (0xF10E0F, 0xF10F09), (0xF1173A, 0xF1173E)]


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


class Rom:
    def __init__(self):
        self.b = open(ROMB, "rb").read()

    def at(self, a, n=1):
        return self.b[a - BASE:a - BASE + n]

    def find_all(self, pat):
        out, i = [], self.b.find(pat)
        while i >= 0:
            out.append(BASE + i)
            i = self.b.find(pat, i + 1)
        return out


def derive(rom):
    d = {}
    posters = {}
    for n, e in enumerate(JOBS):
        head = rom.at(e, 16)
        res = bytes([0xF1, FLAGS & 0xFF, FLAGS >> 8, 0xB0 + n])
        check("job %d at 0x%06X clears bit %d of (0x2799) within its first 16 bytes" % (n, e, n),
              res in head)
        lda = bytes([0xF2]) + e.to_bytes(3, "little") + b"\x31"
        sites = []
        for s in rom.find_all(lda):
            tail = rom.at(s + 5, 5)
            if tail[:1] == b"\x39" and tail[1:5] == b"\x1d" + POST.to_bytes(3, "little"):
                sites.append(s)
        check("job %d is posted: `lda XBC,0x%06X / push XBC / call T_CallbackQueue_Post` at %s"
              % (n, e, ", ".join("0x%06X" % s for s in sites)), len(sites) >= 1)
        # the poster sets the bit first: `or (XIX),1<<n` -- memory-operand sub-opcode 0x3E
        # (`or (mem),#8`) followed by the bit's value, in the 8 bytes before the lda
        pre = [rom.at(s - 8, 8) for s in sites]
        setbit = all(bytes([0x3E, 1 << n]) in p for p in pre)
        check("  ... each poster sets bit %d first: `or (XIX),0x%02X` (3e %02x) in the 8 bytes "
              "before its lda" % (n, 1 << n, 1 << n), setbit)
        posters[e] = sites
    d["posters"] = posters
    # the three data objects' spellings
    for a, s, kind in ((0xF10D62, 0xF1011B, "lda XBC"), (0xF10E0F, 0xF10E07, "lda XIY"),
                       (0xF1173A, 0xF11732, "lda XIY")):
        op = 0x31 if kind == "lda XBC" else 0x35
        check("0x%06X: `%s,0x%06X` (f2 .. %02x)" % (s, kind, a, op),
              rom.at(s, 5) == bytes([0xF2]) + a.to_bytes(3, "little") + bytes([op]))
    check("`push XIY / jp (XIX)` at 0xF10E0C and `push XIY / jp (XBC)` at 0xF11737 follow the "
          "two ldas: hand-made calls returning there",
          rom.at(0xF10E0C, 3).hex() == "3db4d8" and rom.at(0xF11737, 3).hex() == "3db1d8")
    check("0xF10EFC is `ld (0x2793),H` (f1 93 27 46) -- 4 bytes, so 0xF10EFF is mid-instruction",
          rom.at(0xF10EFC, 4).hex() == "f1932746")
    return d


# ------------------------------------------------------------------ transcription
def transcribe(lo, hi):
    p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(lo), hex(hi - lo), "--quiet"],
                       capture_output=True, text=True, cwd=WSA1)
    if p.returncode != 0:
        raise SystemExit("autoforce failed at 0x%06X:\n%s" % (lo, p.stderr[-2000:]))
    out = []
    for ln in p.stdout.rstrip("\n").split("\n"):
        m = re.match(r'^\t(.+?)\t; ([0-9A-F]{6})  (.*)$', ln)
        assert m, ln
        out.append((int(m.group(2), 16), m.group(1), m.group(3)))
    return out


def hx4(v):
    return "0x%04x" % v


def respell(ins):
    """autoforce's LLVM spelling -> this file's house spelling (same bytes)."""
    t = ins.strip()
    rules = [
        (r'^lda_24\s+(x\w+), \((\d+)\)$', lambda m: "lda\t%s, (%s:24)" % (m[1], m[2])),
        (r'^lda_d16\s+(x\w+), \((\d+)\)$', lambda m: "lda\t%s, (%s:16)" % (m[1], m[2])),
        (r'^resda\s+(\d), \((\d+)\)$', lambda m: "m_res %s, MD16, %s" % (m[1], hx4(int(m[2])))),
        (r'^setda\s+(\d), \((\d+)\)$', lambda m: "m_set %s, MD16, %s" % (m[1], hx4(int(m[2])))),
        (r'^stdi8\s+\((\d+)\), (\d+)$', lambda m: "ld\t(%s:16), %s" % (m[1], m[2])),
        (r'^ldw_d16\s+(\w+), \((\d+)\)$', lambda m: "ld\t%s, (%s:16)" % (m[1], m[2])),
        (r'^ldb_d8\s+(\w+), \((\d+)\)$', lambda m: "ld\t%s, (%s:16)" % (m[1], m[2])),
        (r'^stb_d8\s+\((\d+)\), (\w+)$', lambda m: "ld\t(%s:16), %s" % (m[1], m[2])),
        (r'^cpdi8\s+\((\d+)\), (\d+)$',
         lambda m: "m_cp_mi8 MB16, %s, 0x%02x" % (hx4(int(m[1])), int(m[2]))),
        (r'^ldmm8\s+(\d+), (\d+)$',
         lambda m: "m_ld_m16m MB16, %s, %s" % (hx4(int(m[2])), hx4(int(m[1])))),
        (r'^link\s+xiz, (-?\d+)$', lambda m: "link XIZ,0x%04x" % (int(m[1]) & 0xFFFF)),
    ]
    for pat, fn in rules:
        m = re.match(pat, t)
        if m:
            return fn(m)
    if re.match(r'^[a-z]\w*(\s|$)', t) and "_" not in t.split()[0]:
        return re.sub(r'\s+', "\t", t, count=1)
    raise SystemExit("no house spelling for `%s`" % t)


def assemble(lines):
    """Assemble house lines (with the macro include) -> bytes."""
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "t.s")
        o = os.path.join(td, "t.o")
        open(s, "w").write('\t.include "%s"\n' % os.path.join(WSA1, "include", "tlcs900_mem_ops.inc")
                           + "".join("\t%s\n" % x for x in lines))
        p = subprocess.run([LLVM_MC, "-triple=tlcs900", "-filetype=obj", s, "-o", o],
                           capture_output=True, text=True)
        if p.returncode != 0:
            raise SystemExit("llvm-mc: %s" % p.stderr[-1500:])
        objcopy = os.path.join(os.path.dirname(LLVM_MC), "llvm-objcopy")
        b = os.path.join(td, "t.bin")
        subprocess.run([objcopy, "-O", "binary", "--only-section=.text", o, b], check=True)
        return open(b, "rb").read()


def house_island(rom, lo, hi):
    rows = transcribe(lo, hi)
    out = []
    for i, (a, ins, text) in enumerate(rows):
        h = respell(ins)
        nxt = rows[i + 1][0] if i + 1 < len(rows) else hi
        got = assemble([h])
        if got != rom.at(a, nxt - a):
            raise SystemExit("respelling 0x%06X `%s` -> `%s` gives %s, ROM %s"
                             % (a, ins, h, got.hex(), rom.at(a, nxt - a).hex()))
        out.append((a, h, text))
    assert rows and rows[0][0] == lo
    return out


# ------------------------------------------------------------------ apply
def job_name(n):
    return "EffectEditor_PaintJob%d" % n


JOB_HEADER = """; --------------------------------------------------------------------------
; {name} -- effect-editor PAINT JOB {n}.
; Evidence: its first instructions clear bit {n} of (0x2799) (`res {n},(0x2799)`),
;          and it is only ever reached as a callback: {posters} `lda XBC,this /
;          push XBC / call T_CallbackQueue_Post` right after setting that same
;          bit.  (0x2799) is therefore the editor's set of PENDING paint jobs,
;          one bit each for EffectEditor_PaintJob0..7, and each job clears its
;          own bit and redraws with display lists.  All eight are checked by
;          python3 notes/promb-2026-09-25/effect_paint_jobs.py.
{extra}; --------------------------------------------------------------------------"""

EXTRA = {
    5: """; Body:    XIX = T_DisplayList_Run_Stack; `call 0xF42E10`; (0x2540) = 0; then a
;          `cp BC,..` ladder on (0x2076) (1, 9, 10, 22, 23) picks pairs of the
;          interpreter-A lists at 0xF13D60-0xF13F1D and runs each pair by a
;          hand-made call (`lda XIY,resume / push XIY / jp (XIX)`), then the
;          captions (DL_F143AF with (0x2640) = (0x2797), DL_F1469B/DL_F146A6
;          with (0x2640) = (0x2790)).
; ⚠ WAS `OLD<<Data@F10D62>>` + code + `OLD<<Data@F10E0F>>`: the source framed this
;          routine as
;          158 bytes of data, 15 bytes of code and 240 bytes of data (the code
;          walk had never reached it); prom_b 0xF1011B posts its address.
""",
    6: """; ⚠ WAS the middle of `OLD<<Data@F10E0F>>`.
""",
    7: """; Body:    `calr sub_F0FD2F`, `calr sub_F10EE9`, `call T_F42E14`.
; ⚠ WAS the middle of `OLD<<Data@F10E0F>>`.
""",
}


def apply(d, rom):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    addr_of = {}
    for i, t in enumerate(L):
        m = re.search(r'; ([0-9A-F]{6})  ', t)
        if m and not t.startswith(";"):
            addr_of.setdefault(i, int(m.group(1), 16))
    for lo, hi in reversed(ISLANDS):
        rows = house_island(rom, lo, hi)
        idx = [i for i, a in addr_of.items() if lo <= a < hi]
        first, last = min(idx), max(idx)
        # swallow the label line and header block directly above `first`
        s = first
        while s > 0 and (re.match(r'^[A-Za-z_]\w*:', L[s - 1]) or L[s - 1].startswith(";")
                         or not L[s - 1].strip()):
            s -= 1
            if re.match(r'^[A-Za-z_]\w*:', L[s]) and not L[s].split(":")[0].startswith("Data_F"):
                s += 1
                break
        while s < first and not L[s].strip():
            s += 1
        new = []
        for a, h, text in rows:
            if a in JOBS:
                n = JOBS.index(a)
                posters = ", ".join("0x%06X" % x for x in d["posters"][a])
                new.append("")
                new += JOB_HEADER.format(name=job_name(n), n=n, posters=posters,
                                         extra=EXTRA.get(n, "")).split("\n")
                new.append("%s:" % job_name(n))
            elif a == 0xF10EE9:
                new += ["", "; " + "-" * 74,
                        "; sub_F10EE9",
                        "; Called from: EffectEditor_PaintJob7 (`calr` at 0xF10EE1)",
                        "; Evidence: reached by that `calr`; the name IS the address.  It",
                        ";          saves (0x2793) in L and copies (0x2792) into it, tests",
                        ";          IndexedTable_GetByte(23, (0x2797)+97) -- block byte 23, the flag",
                        ";          EqGraph_Draw prints \"BYPASS\" for and sub_F1018F toggles -- and",
                        ";          runs on into the code below (it calls DspEffect_LoadParamNames at",
                        ";          0xF10F55).  What it is FOR as a whole is not decoded here.",
                        "; ⚠ WAS the tail of `OLD<<Data@F10E0F>>` plus four lines framed from",
                        ";   0xF10EFF, inside `ld (0x2793),H` at 0xF10EFC.",
                        "; " + "-" * 74, "sub_F10EE9:"]
            elif a in (0xF10E0F, 0xF1173A):
                new.append("@@RESUME@@%06X:" % a)
            new.append("\t%s\t; %06X  %s" % (h, a, text))
        new = [x.encode("utf-8").decode("latin-1") for x in new]
        L = L[:s] + new + L[last + 1:]
    txt = "\n".join(L)
    # hand-made return points inside the job-5 routine and after 0xF11732
    txt = txt.replace("@@RESUME@@F1173A:", "sub_F116C4_Resume:")
    txt = txt.replace("@@RESUME@@F10E0F:", "EffectEditor_PaintJob5_Resume3:")
    txt = re.sub(r'\bData_F1173A\b', "sub_F116C4_Resume", txt)
    txt = re.sub(r'\bData_F10E0F \+ 0xA9\b', job_name(6), txt)
    txt = re.sub(r'\bData_F10E0F \+ 0xCB\b', job_name(7), txt)
    txt = re.sub(r'\bData_F10E0F\b', "EffectEditor_PaintJob5_Resume3", txt)
    txt = re.sub(r'\bData_F10D62\b', job_name(5), txt)
    # branch labels that hung under the old data names
    for old, new in (("Data_F1173A_Code_Skip", "sub_F116C4_Skip"),
                     ("Data_F1173A_Code_Loop2", "sub_F116C4_Loop3"),
                     ("Data_F1173A_Code_Loop", "sub_F116C4_Loop2"),
                     ("Data_F1173A_Code_Join", "sub_F116C4_Join"),
                     ("EffectEditor_PaintJob5_Resume3_Code_", "sub_F10EE9_"),
                     ("Data_F10E0F_Code_", "sub_F10EE9_")):
        txt = re.sub(r'\b%s' % old, new, txt)
    # the other five jobs keep their code; only the name and a header line change
    for n, e in enumerate(JOBS[:5]):
        old = "sub_%06X" % e
        assert re.search(r'^%s:' % old, txt, re.M), old
        txt = re.sub(r'\b%s(\w*)\b' % old, lambda m, n=n: job_name(n) + m.group(1), txt)
        posters = ", ".join("0x%06X" % x for x in d["posters"][e])
        hdr = JOB_HEADER.format(name=job_name(n), n=n, posters=posters, extra="")
        # these five had no header at all: the label sat straight after the `ret` above
        txt, k = re.subn(r'(\tret\t; [0-9A-F]{6}  ret\n)(%s:)' % job_name(n),
                         lambda m: m.group(1) + "\n" + hdr.encode("utf-8").decode("latin-1")
                         + "\n" + m.group(2), txt, count=1)
        assert k == 1, job_name(n)
    txt = re.sub(r'OLD<<(\w+)@(\w+)>>', r'\1_\2', txt)   # old names, kept out of the renames
    data = txt.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


POST_RENAMES = [
    # return points the ROM-address symboliser's --arms labels as sub_<ADDR>
    ("sub_F10DE5", "EffectEditor_PaintJob5_Resume"), ("sub_F10DFB", "EffectEditor_PaintJob5_Resume2"),
    ("sub_F10E2E", "EffectEditor_PaintJob5_Resume4"), ("sub_F10E44", "EffectEditor_PaintJob5_Resume5"),
    ("sub_F10E58", "EffectEditor_PaintJob5_Resume6"), ("sub_F10E81", "EffectEditor_PaintJob5_Resume7"),
    ("sub_F10E95", "EffectEditor_PaintJob5_Resume8"),
    # branch labels the branch symboliser parents to sub_F10CC4 (the last CALLED entry above):
    # the cases of job 5's `cp BC,n` ladder on (0x2076), and its two joins
    ("sub_F10CC4_Skip3", "EffectEditor_PaintJob5_Case23"),
    ("sub_F10CC4_Skip4", "EffectEditor_PaintJob5_Case10"),
    ("sub_F10CC4_Skip5", "EffectEditor_PaintJob5_Case22"),
    ("sub_F10CC4_Skip6", "EffectEditor_PaintJob5_Case1"),
    ("sub_F10CC4_Skip7", "EffectEditor_PaintJob5_Case9"),
    ("sub_F10CC4_Join2", "EffectEditor_PaintJob5_RunPair"),
    ("sub_F10CC4_Join3", "EffectEditor_PaintJob5_Common"),
    ("sub_F10CC4_Skip8", "EffectEditor_PaintJob5_Join"),
]


def post():
    t = open(SRC, "rb").read().decode("latin-1")
    for o, n in POST_RENAMES:
        t, k = re.subn(r'\b%s\b' % o, n, t)
        print("  %-20s -> %-34s %d" % (o, n, k))
    open(SRC, "wb").write(t.encode("latin-1"))


def main():
    if "--post" in sys.argv:
        post()
        return 0
    rom = Rom()
    d = derive(rom)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d, rom)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
