#!/usr/bin/env python3
"""Does every address a prom_a "Called from:" line names actually START a transfer
to that routine -- and if not, WHICH nearby address does?

WHY THIS EXISTS
  The round-2 audit's closing paragraph: "three of the four worst findings are
  address and identity claims in prose that no committed script reads.  prom_c
  has the one tool that closes that hole (notes/prom_c_audit_callsites.py) and
  prom_c is the image whose new citations came through at 148-for-149.  prom_a
  and prom_b have no such tool, and both shipped defects of exactly the kind it
  detects."  This is prom_a's.

  The defect is systematic, not careless: a reference scan matches the 24-bit
  LITERAL, and the instruction that owns the literal begins one or two bytes
  EARLIER (`1D lo mid hi` -> the `call` is at the 0x1D).  Copying a scan's
  address into a header is therefore wrong by default, and the byte gate is
  blind to it.

  ⚠ AND THE CHECKER MUST NOT KNOW THE ANSWER.  F2's checker hard-coded the +1
  values it was meant to catch, so it could never fail.  This one decodes from
  the ROM and knows nothing about any header's claim.

WHAT IT DOES
  1. parses prom_a/wsa1_prom_a.s for `; Called from:` blocks, collecting every
     0xXXXXXX address named before the block's next `; Inputs:`/`; Evidence:`
     line (the same block shape prom_c's tool uses, so the two are comparable);
  2. takes the routine's own address from the `; ADDR` comment on the first
     instruction line after its label;
  3. disassembles ONE instruction at each cited address -- in prom_a or prom_b,
     chosen by range, because prom_a routines are called from both -- and checks
     it is a call/calr/jp/jr/jrl whose target is that routine;
  4. when it is not, it RE-DECODES at addr-1 and addr-2 and says whether one of
     those is the instruction.  "cited one byte past the instruction" then
     appears in the output as a diagnosis instead of having to be noticed.

  Rows that do not check out are a list to READ, not a failure: a header may
  legitimately cite a POINTER-TABLE entry, a directory slot's data word, or a
  site that reaches the routine through a register.  Say which, in the header.

RUN
  python3 notes/prom_a_audit_callsites.py
  python3 notes/prom_a_audit_callsites.py --quiet   # only rows that did not check out
  python3 notes/prom_a_audit_callsites.py --selftest
Exit status is non-zero only for --selftest failures.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
A_BASE, B_BASE = 0xF80000, 0xF00000
IMGS = {
    "a": (A_BASE, open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()),
    "b": (B_BASE, open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()),
}

ADDR = re.compile(r'0x([0-9A-Fa-f]{6,8})(?![0-9A-Fa-f])')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
INSTR_ADDR = re.compile(r';\s*([0-9A-F]{6})\s')
SECTION = re.compile(r';\s*(Inputs|Outputs|Evidence|Unknown|Note|Packet|Dispatch|Reads|Writes):')
XFER = re.compile(r'\b(call|calr|jp|jrl|jr)\b')


def which(addr):
    for k, (base, img) in IMGS.items():
        if base <= addr < base + len(img):
            return k
    return None


def dis1(addr):
    """The single instruction starting at `addr`, as unidasm prints it."""
    k = which(addr)
    if k is None:
        return None
    base, img = IMGS[k]
    off = addr - base
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(img[off:off + 12])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    out = p.stdout.splitlines()
    return out[0] if out else None


def le(addr, n):
    """The n-byte little-endian word at `addr`, or None if outside both images."""
    k = which(addr)
    if k is None:
        return None
    base, img = IMGS[k]
    o = addr - base
    if o + n > len(img):
        return None
    return int.from_bytes(img[o:o + n], "little")


TARGET = re.compile(r'0x([0-9a-f]{6})\b')
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018


def xfer_target(text):
    """The printed target of a transfer instruction, or None."""
    if not text:
        return None
    body = text.split(":", 1)[1] if ":" in text else text
    if not XFER.search(body):
        return None
    m = TARGET.search(body)
    return int(m.group(1), 16) if m else None


def classify(at, ra):
    """Why does the cited address `at` not decode to a transfer to `ra`?

    Returns (tag, note).  The tags that are NOT defects are stated as such:
      POINTER   the 24/32-bit word AT the citation IS the routine address --
                a pointer-table or vector-table entry, legitimately cited
      THUNK     that word is an address whose instruction transfers to `ra` --
                the citation is a table slot one indirection away
      VIA-DIR   the instruction here calls a prom_b DIRECTORY slot whose own
                `jp` lands on `ra`.  This is how nearly every cross-module call
                in the machine is spelled, so it is a CORRECT citation, not a
                defect -- added 2026-08-25 after round-2 audit F9 showed the
                tool was reporting ~30 of them as unresolved
      VIA-JP    the instruction here transfers to some other address whose own
                instruction transfers to `ra` -- a two-hop veneer, also correct
      RAM SLOT  the citation is a RAM address (0x600000-0x6FFFFF): a runtime
                function-pointer slot, outside both ROM images by construction
      OFF BY n  the instruction that transfers to `ra` starts n bytes EARLIER;
                this is the defect this script exists for
      ??        none of the above: read the header
    """
    for n in (3, 4):
        if (le(at, n) or 0) & 0xFFFFFF == ra:
            return "POINTER", "the %d-byte word here IS 0x%06X" % (n, ra)
    for n in (3, 4):
        w = (le(at, n) or 0) & 0xFFFFFF
        if w and w != ra and reaches(dis1(w), ra):
            return "THUNK", "-> 0x%06X, which transfers to 0x%06X" % (w, ra)
    t = xfer_target(dis1(at))
    if t is not None and t != ra:
        if THUNK_LO <= t < THUNK_HI and reaches(dis1(t), ra):
            return "VIA-DIR", "-> directory slot T_%06X -> 0x%06X" % (t, ra)
        if reaches(dis1(t), ra):
            return "VIA-JP", "-> 0x%06X -> 0x%06X" % (t, ra)
    if which(at) is None and 0x600000 <= at < 0x700000:
        return "RAM SLOT", "runtime function-pointer slot in RAM"
    for d in (1, 2):
        if reaches(dis1(at - d), ra):
            return "OFF BY %d" % d, "the instruction is at 0x%06X" % (at - d)
    return "??", ""


def reaches(text, target):
    """Is `text` a transfer whose printed target is `target`?"""
    if not text:
        return False
    body = text.split(":", 1)[1] if ":" in text else text
    return bool(XFER.search(body)) and ("%06x" % target) in body.lower()


def cited_blocks(path):
    """[(name, routine_addr, {label_addr, ...}, [cited addresses])] from a .s file.

    ⚠ A routine's extent, not just its first label.  A header often introduces
    SEVERAL labels -- an alternate entry two bytes in, a `__jrentry`, a tail --
    and its `Called from:` line cites the callers of whichever of them they call.
    Taking only the first label turns every such citation into a false "??".  So
    every label between the header and the NEXT `; -----` header separator is
    collected, and a transfer to any of them counts.
    """
    lines = open(path, encoding="utf-8").read().splitlines()
    out, i = [], 0
    sep = re.compile(r'^;\s*-{10,}')
    while i < len(lines):
        if "; Called from:" not in lines[i]:
            i += 1
            continue
        # 1. the citations, to the end of this header field
        cites, j = [], i
        while j < len(lines) and lines[j].lstrip().startswith(";"):
            if j > i and SECTION.search(lines[j]):
                break
            cites += [int(m, 16) & 0xFFFFFF for m in ADDR.findall(lines[j])]
            j += 1
        # 2. the routine's extent: every label up to the next header separator
        labels, first, name = set(), None, None
        k = j
        while k < len(lines):
            if sep.match(lines[k]) and labels:
                break
            m = LABEL.match(lines[k])
            if m:
                for q in range(k + 1, min(k + 6, len(lines))):
                    mm = INSTR_ADDR.search(lines[q])
                    if mm:
                        at = int(mm.group(1), 16)
                        labels.add(at)
                        if first is None:
                            first, name = at, m.group(1)
                        break
            k += 1
        if first is not None:
            out.append((name, first, labels, [c for c in cites if c not in labels]))
        i = j
    return out


def selftest():
    """Negative controls: the checker must FAIL on a known-bad citation and the
    off-by-one diagnosis must FIRE on one, or it is not testing anything."""
    fails = []

    def t(msg, cond):
        print("  %-64s %s" % (msg, "ok" if cond else "FAIL"))
        if not cond:
            fails.append(msg)

    # 0xF830C6 is called by nothing; 0xF84000's Get family is called from the
    # instance bank.  Take a real `call` and its operand, from the ROM.
    a_img = IMGS["a"][1]
    site = None
    for off in range(0x42DF, 0x4C6C):                 # the ring instance bank
        if a_img[off] == 0x1D:
            tgt = a_img[off + 1] | a_img[off + 2] << 8 | a_img[off + 3] << 16
            if 0xF84000 <= tgt <= 0xF842DE:
                site = (A_BASE + off, tgt)
                break
    t("found a real `call` site inside the ring instance bank", site is not None)
    if site:
        at, tgt = site
        t("the instruction address decodes to a transfer to its target",
          reaches(dis1(at), tgt))
        t("NEGATIVE CONTROL: the SAME site cited one byte late does NOT",
          not reaches(dis1(at + 1), tgt))
        t("and the -1 re-decode diagnoses it", reaches(dis1(at + 1 - 1), tgt))
    t("an address in prom_b is routed to the prom_b image", which(0xF41CD0) == "b")
    t("an address in prom_a is routed to the prom_a image", which(0xF84000) == "a")
    t("an address in neither is rejected", which(0x001234) is None)
    print("SELFTEST %s" % ("PASS" if not fails else "FAIL: %d" % len(fails)))
    return 1 if fails else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    quiet = "--quiet" in sys.argv
    rows = cited_blocks(SRC)
    n = 0
    tally = {}
    for name, ra, labels, cites in rows:
        for at in cites:
            n += 1
            txt = dis1(at)
            hit = [x for x in sorted(labels) if reaches(txt, x)]
            if hit:
                tag = "CALL" if hit[0] == ra else "CALL-ALT"
                note = "" if hit[0] == ra else "to 0x%06X, another label of this routine" % hit[0]
            else:
                tag, note = classify(at, ra)
            tally[tag] = tally.get(tag, 0) + 1
            if tag == "CALL" and quiet:
                continue
            print("%-40s -> 0x%06X  cited 0x%06X  %-8s %s%s"
                  % (name, ra, at, tag, (txt or "<outside both images>").strip(),
                     ("   " + note) if note else ""))
    print()
    print("%d headed routine(s) with a `Called from:` block, %d cited site(s) checked"
          % (len([r for r in rows if r[3]]), n))
    for tag in sorted(tally, key=lambda t: -tally[t]):
        print("   %-10s %4d" % (tag, tally[tag]))
    off = sum(v for k, v in tally.items() if k.startswith("OFF BY"))
    print("%d citation(s) are one or two bytes PAST the instruction -- the defect "
          "this script exists for" % off)
    # ★ Round-2 audit F9: prom_a used to report only the OFF-BY-N line and stay
    # silent about the citations that do not resolve at all.  State both.
    unres = tally.get("??", 0)
    print("%d citation(s) DO NOT RESOLVE (`??`) -- %.1f%% of the %d checked.  Each "
          "is a header to read, not automatically a defect, but the number belongs "
          "in every report that quotes the OFF-BY-N line."
          % (unres, 100.0 * unres / n if n else 0.0, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
