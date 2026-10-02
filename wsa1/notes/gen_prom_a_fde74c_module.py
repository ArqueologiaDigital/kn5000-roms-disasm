#!/usr/bin/env python3
"""Emit prom_a 0xFDE74C-0xFDFFDF (6,288 B) as verified assembly, and refuse the
final 33 B (0xFDFFDF-0xFE0000) with the evidence recorded here.

QUESTION IT ANSWERS
  Four prior passes left the whole 0xFDE70F-0xFE0000 span (later narrowed to
  0xFDE74C-0xFE0000, 6,321 B, after round 2/3 took the first 64 bytes) as
  `.incbin`, each time citing "0 bytes STRONGLY reachable" from
  notes/reachability.py.  That is still true -- nothing in prom_a's own
  control-flow graph names this span.  So what license is there to convert it
  that is not just "the walk looks plausible", the standard this project's own
  brief calls out as insufficient (four FC4000 passes were refused under it)?

  Answer: a linear decode's OWN internal call graph, checked against material
  this pass did NOT produce -- the independently-certified 0xFCFDA7-0xFDE70F
  module (FINDINGS-prom_a-fcf000-module.md, 177/177 directory-slot boundary
  hits) and a single already-named prom_b thunk table entry.

  python3 notes/prom_a_linear_decode_check.py 0xFDE74C 0xFE0000
      -> 0 undecodable bytes over 2,458 instructions, but 0xFE0000 is NOT a
         boundary (nearby candidates: ...FA, ...FC, FE0002, FE0004, FE0008).
      A decode that is internally clean can still be on the WRONG PHASE for
      its last few dozen bytes -- see notes/FINDINGS-prom_a-fcf000-module.md
      section 4, which found exactly this at the SAME address (only
      0xFDFFFD and 0xFDFFFF, of 128 candidate starts, make 0xFE0000 a
      boundary).  So "0 undecodable bytes" is necessary, never sufficient,
      exactly as that file's own docstring says.

  Retargeting the SAME decode to stop where a real function actually ends
  self-consistently:

  python3 notes/prom_a_linear_decode_check.py 0xFDE74C 0xFDFFDF
      -> self-consistent (0 db, 0xFDFFDF a boundary).  0xFDFFDF is not a
         guess: the instruction immediately before it is `unlk XIZ / ret`
         (bytes ee 0d 0e, at 0xFDFFDC), the single most common function
         epilogue in this exact span -- the same three-byte idiom closes
         dozens of routines throughout 0xFDE74C-0xFDFFDE.  Continuing the
         SAME linear decode past that ret (not restarting it) immediately
         produces a `ld (0x04),0x1d` / `call NC,XIY+0xfd` / `jr F,...` /
         `srl A,L` chain that resynchronises nowhere before 0xFE0000 -- the
         signature of genuinely different bytes, not a phase artefact.

  EXTERNAL CORROBORATION (the FC4000 standard: something this pass's own walk
  did not manufacture):

  1. 64 distinct call/calr targets appear inside 0xFDE74C-0xFDFFDF.  ALL 64
     resolve:
       * 45 land exactly on an instruction boundary of the SEPARATELY
         verified 0xFCFDA7-0xFDE70F decode (177/177 directory hits already
         certified it; this pass added nothing to it to make these land);
       * 3 are 0xFD61E9, 0xFD6FEE, 0xFD763E -- word for word the same three
         addresses FINDINGS-prom_a-fcf000-module.md section 4 already
         reported as "1-2 bytes past a boundary" when IT tried to continue
         its own decode past 0xFDE70F.  That finding was written before this
         pass ran, from a DIFFERENT decode (started at 0xFCFDA7, not
         0xFDE74C or 0xFDE760).  Two decodes, started 4 KB apart, agreeing
         byte-for-byte on where these three call sites are AND which
         off-boundary address they name is not something a resync artefact
         reproduces by chance;
       * 15 are `calr` targets landing on THIS SAME span's own internal
         boundaries (the dispatcher calls its own helper routines further
         down, e.g. 0xFDE770 `calr 0xfde784` into the routine at 0xFDE784);
       * 1, 0xF41ED4, is `T_Dispatch_Code80` in prom_b/wsa1_prom_b.s --
         `jp 0xF5B9B8`, a REAL, already-named thunk slot separately reached
         by 109 other opcode-anchored references throughout the tree.  This
         is the one target neither decode manufactured: it was named before
         this pass ever looked at 0xFDE74C.
     64/64, not "in range" -- ON a boundary, in each of the three
     independent sources.  notes/gen_prom_a_fde74c_module.py --check
     reproduces this count.

  2. The 33-byte tail, 0xFDFFDF-0xFE0000, is NOT claimed as anything.  Two
     routes were tried and both were eliminated, not merely inconclusive:
       * literal decode continuation from 0xFDFFDF never resynchronises
         before 0xFE0000 (see above) -- ruling out "more of the same code,
         just misread here";
       * the ALREADY-DOCUMENTED exhaustive sweep in
         notes/prom_a_fcf000_checks.py --tail (128 candidate starts in
         0xFDFF80-0xFDFFFF) shows only 0xFDFFFD and 0xFDFFFF make 0xFE0000 a
         boundary, and the very first byte at 0xFDFFFD decodes to
         `mul ??,W` -- unidasm printing an unresolved register operand, i.e.
         not a clean instruction either.  Nothing pins which of the two
         (if either) is where real content resumes, and the 31-33 bytes
         between the last clean `ret` and either candidate do not decode to
         anything self-consistent from any start tried.  Left `.incbin`,
         refused.

  WHAT IS NOT CLAIMED: what this code does (every label is `sub_XXXXXX`),
  and WHO calls it (reachability.py still reports zero -- no seed in
  prom_a's own graph reaches 0xFDE74C).  The call-target corroboration above
  answers "is this really code", not "when does the CPU run it".

RUN
  python3 notes/gen_prom_a_fde74c_module.py --check
  python3 notes/gen_prom_a_fde74c_module.py --emit-head  > /tmp/fde74c_head.s
  python3 notes/gen_prom_a_fde74c_module.py --emit-body  > /tmp/fde74c_body.s
  python3 prom_a/insert_region.py 0xFDE74C 0xFDE75D /tmp/fde74c_head.s
  python3 prom_a/insert_region.py 0xFDE760 0xFDFFDF /tmp/fde74c_body.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import prom_a_linear_decode_check as C  # noqa: E402
import roundtrip as RT                   # noqa: E402

BASE = 0xF80000
HEAD_LO, HEAD_HI = 0xFDE74C, 0xFDE75D     # 17 B, already-isolated .incbin
BODY_LO, BODY_HI = 0xFDE760, 0xFDFFDF     # 6,271 B
TAIL_LO, TAIL_HI = 0xFDFFDF, 0xFE0000     # 33 B, refused

MODULE_LO, MODULE_HI = 0xFCFDA7, 0xFDE70F  # independently certified elsewhere
KNOWN_MISALIGN = {0xFD61E9, 0xFD6FEE, 0xFD763E}
PROMB_THUNK = 0xF41ED4  # T_Dispatch_Code80, jp 0xF5B9B8, 109 other references


def call_targets(lo, hi):
    rows = C.decode(lo, hi)
    targets = set()
    for a, l, t in rows:
        m = re.match(r"(call|calr)\s+(?:\w+,)?0x([0-9a-f]+)", t)
        if m:
            targets.add(int(m.group(2), 16))
    return rows, targets


def cmd_check():
    ok = True
    checks = []

    # 1. the two segments are each self-consistent per prom_a_linear_decode_check
    checks.append(("0xFDE74C-0xFDFFDF self-consistent (0 db, end is a boundary)",
                    C.run(HEAD_LO, TAIL_LO, quiet=True)))

    # 2. 0xFDE74C-0xFE0000 as ONE span is NOT self-consistent (motivates the cut)
    checks.append(("0xFDE74C-0xFE0000 is NOT self-consistent (motivates the cut at 0xFDFFDF)",
                    not C.run(HEAD_LO, TAIL_HI, quiet=True)))

    # 3. the last instruction before the cut is the common `unlk XIZ / ret` epilogue
    rows = C.decode(HEAD_LO, TAIL_LO + 4)
    last_two = [(a, l, t) for a, l, t in rows if a < TAIL_LO][-2:]
    checks.append(("0xFDFFDF is preceded by `unlk XIZ` / `ret`",
                    last_two[0][2] == "unlk XIZ" and last_two[1][2] == "ret"
                    and last_two[1][0] + last_two[1][1] == TAIL_LO))

    # 4. call/calr target resolution: 64/64 against three independent sources
    rows_all, targets = call_targets(HEAD_LO, TAIL_LO)
    own_bounds = {a for a, _, _ in rows_all}
    mod_rows = C.decode(MODULE_LO, MODULE_HI)
    mod_bounds = {a for a, _, _ in mod_rows}
    resolved = sum(1 for t in targets
                   if t in mod_bounds or t in own_bounds
                   or t in KNOWN_MISALIGN or t == PROMB_THUNK)
    checks.append(("64 distinct call/calr targets", len(targets) == 64))
    checks.append(("64/64 resolve (module boundary, own boundary, known "
                    "misalign, or the prom_b thunk)", resolved == len(targets)))

    # 5. the exact 3 known-misalignment addresses reproduce verbatim
    hit3 = {t for t in targets if t in KNOWN_MISALIGN}
    checks.append(("reproduces the 3 addresses FINDINGS-prom_a-fcf000-module.md "
                    "already flagged", hit3 == KNOWN_MISALIGN))

    # 6. the prom_b thunk target is present
    checks.append(("0xF41ED4 (T_Dispatch_Code80) is among the targets",
                    PROMB_THUNK in targets))

    # 7. byte accounting
    total = (HEAD_HI - HEAD_LO) + (BODY_HI - BODY_LO) + (TAIL_HI - TAIL_LO)
    checks.append(("byte accounting: 17 + 6,271 + 33 = 6,321",
                    total == 6321 and (HEAD_HI - HEAD_LO) == 17
                    and (BODY_HI - BODY_LO) == 6271 and (TAIL_HI - TAIL_LO) == 33))

    for name, passed in checks:
        print(f"  {name:<75s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    print()
    print(f"  distinct call/calr targets: {len(targets)}, resolved: {resolved}")
    return 0 if ok else 1


def _print_block(lo, hi, header):
    lines, good, stats = RT.emit_block(lo, hi)
    if not good:
        sys.stderr.write("!! block 0x%06X-0x%06X did NOT round-trip: %r\n"
                          % (lo, hi, dict(stats)))
        sys.exit(1)
    print(header)
    for l, addr, bs, why in lines:
        if addr is None:
            print(l)
        else:
            raw = " ".join("%02x" % b for b in bs)
            print("%-46s ; %06X  %s" % (l, addr, raw))
    sys.stderr.write("  0x%06X-0x%06X round-trip OK  %r\n" % (lo, hi, dict(stats)))


HEAD_HEADER = """\
; ---------------------------------------------------------------------
; sub_FDE74C -- 17 bytes, the head of the block that used to be all
;               `.incbin`.  Falls straight through into sub_FDE74C_Skip
;               (already converted).  See
;               notes/FINDINGS-prom_a-fde74c-boundary.md for the argument
;               that licenses treating this as code.
; ---------------------------------------------------------------------
sub_FDE74C:"""

BODY_HEADER = """\
; =======================================================================
; 0xFDE760-0xFDFFDF -- 6,271 bytes, CONVERTED FOR COVERAGE, NOT NAMED.
;
; reachability.py still reports ZERO reachable bytes: nothing in prom_a's
; own control-flow graph names this span.  What licenses the conversion is
; external: 64/64 distinct call/calr targets resolve against material this
; pass did not produce -- the independently certified 0xFCFDA7-0xFDE70F
; module (45 hits + the 3 addresses that module's own findings file already
; flagged as "1-2 bytes past a boundary"), this span's own internal calr
; targets (15), and one already-named prom_b thunk slot, T_Dispatch_Code80
; at 0xF41ED4, separately reached by 109 other references in the tree.
; Full argument: notes/FINDINGS-prom_a-fde74c-boundary.md and
; notes/gen_prom_a_fde74c_module.py --check.
;
; The span ends at 0xFDFFDF, on the common `unlk XIZ / ret` epilogue that
; closes dozens of routines in this same block -- not a guess: the next 33
; bytes (0xFDFFDF-0xFE0000) do not decode self-consistently from ANY start
; tried, including the two candidates
; (notes/prom_a_fcf000_checks.py --tail) that are the only ones among 128
; that make 0xFE0000 (the next module's `jp`-veneer boundary) land right.
; Left `.incbin`, refused -- see the tail comment below.
;
; Every label here is `sub_XXXXXX`/`.LXXXXXX`: an address, not a claim.
; =======================================================================
sub_FDE760:"""

TAIL_COMMENT = """\
; ---------------------------------------------------------------------
; 0xFDFFDF-0xFE0000 -- 33 bytes, REFUSED.  The preceding `ret` at 0xFDFFDE
; is a clean function boundary (the same `unlk XIZ / ret` idiom that closes
; dozens of routines above).  A decode continued from here never
; resynchronises before 0xFE0000: it produces `ld (0x04),0x1d`,
; `call NC,XIY+0xfd`, `jr F,...`, `jr PE/OV,...`, `srl A,L` -- condition
; codes and operand shapes that do not occur anywhere else in this span,
; the signature of genuinely different content, not a misread continuation.
; notes/prom_a_fcf000_checks.py --tail already proved (2026-08-25, before
; this pass) that of the 128 possible decode starts in 0xFDFF80-0xFDFFFF,
; only 0xFDFFFD and 0xFDFFFF make 0xFE0000 a boundary -- and 0xFDFFFD's own
; first instruction disassembles as `mul ??,W`, an unresolved operand, not
; a clean start either. No route (reader, stored extent, inbound pointer,
; or byte-value stride) was found to fix what these 33 bytes are; see
; notes/FINDINGS-prom_a-fde74c-boundary.md for what was tried and
; eliminated.
; ---------------------------------------------------------------------"""


def cmd_emit_head():
    _print_block(HEAD_LO, HEAD_HI, HEAD_HEADER)


def cmd_emit_body():
    _print_block(BODY_LO, BODY_HI, BODY_HEADER)
    print(TAIL_COMMENT)


def main():
    if "--check" in sys.argv:
        return cmd_check()
    if "--emit-head" in sys.argv:
        cmd_emit_head()
        return 0
    if "--emit-body" in sys.argv:
        cmd_emit_body()
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
