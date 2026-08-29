#!/usr/bin/env python3
"""LANE REVIEW-WC3: an INDEPENDENT refutation of round 3's prom_c names.

QUESTION IT ANSWERS
  "Do the seven new prom_c semantic names and the evidence added to the Dev10C_/Dev104_
  accessors survive a check that does NOT use notes/prom_c_naming_round3.py's own decoder?"
  A checker that agrees with itself proves nothing, so every number below is re-derived
  from original_ROMs/wsa1_prom_c.ic28 and from the .s text, never from the lane's script.

  Run:  python3 review_wc3_refute.py       (from the repo root)

  R1  0xFA75BA instruction count      -- header says "fifteen"; refutes or confirms.
  R2  0xFA75BA post-shift value range -- header says [-127,0] / [-508,0] with a
                                         "NEVER POSITIVE" headline and "the clamp does
                                         nothing at all".  Exhaustive over all 256 depth
                                         bytes x 128 positions.
  R3  citation audit -- every 0xFxxxxx cited in a NEW comment line must be an instruction
                        start.  The documented bug signature is cited-1 == 0x44/0x45/0x46.
  R4  header-metric provenance -- how much of the +35 `headers` delta is new prose and how
                                  much is the blank-line artefact being removed.
"""
import re, subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent
if not (ROOT / 'prom_c').is_dir():
    ROOT = pathlib.Path('/home/fsanches/compartilhado/wsa1-roms-disasm')
BASE = 0xF80000
rom = (ROOT / 'original_ROMs' / 'wsa1_prom_c.ic28').read_bytes()
src = (ROOT / 'prom_c' / 'wsa1_prom_c.s').read_text().split('\n')
UNIDASM = pathlib.Path.home() / 'compartilhado/kn7000_mame_build/unidasm'
fails = []
def check(ok, desc, detail=''):
    print("  %-4s %s%s" % ("ok" if ok else "FAIL", desc, ("   [%s]" % detail) if detail else ''))
    if not ok: fails.append(desc)

# ---------------------------------------------------------------- R1
print("\nR1  0xFA75BA is claimed to be 'fifteen instructions'")
blob = ROOT / '_wc3.bin'; blob.write_bytes(rom[0xFA75BA-BASE:0xFA75BA-BASE+72])
out = subprocess.run([str(UNIDASM), str(blob), '-arch', 'tlcs900', '-basepc', '0xFA75BA'],
                     capture_output=True, text=True).stdout
blob.unlink()
n = len([l for l in out.split('\n') if re.match(r'^[0-9a-f]{6}:', l)])
check(n == 15, "the routine really is 15 instructions", "unidasm counts %d" % n)

# ---------------------------------------------------------------- R2
print("\nR2  0xFA75BA's value range, exhaustive (256 depths x 128 positions)")
mirror = rom[0xFDD5AB-BASE:0xFDD5AB-BASE+128]; coeff = rom[0xFDD62B-BASE:0xFDD62B-BASE+128]
s8 = lambda x: x-256 if x > 127 else x
def scale(d, p, cnt):
    L, H = s8(d), p & 0x7F
    if L < 0: H, L = mirror[H], s8((~d + 1) & 0xFF)   # `cpl A / inc 1,A` is 8-bit
    v = (coeff[H] - 256 if coeff[H] > 127 else coeff[H]) * L
    return (((v + 0x8000) & 0xFFFF) - 0x8000) >> cnt   # muls is 16-bit; the shift is arithmetic
r6 = [scale(d, p, 6) for d in range(256) for p in range(128)]
r4 = [scale(d, p, 4) for d in range(256) for p in range(128)]
check(max(r6) <= 0, "header: 'THE RESULT IS NEVER POSITIVE'", "count-6 max is %+d" % max(r6))
check((min(r6), max(r6)) == (-127, 0), "header: 'with a count of 6 the value lands in [-127, 0]'",
      "actual [%d, %d]" % (min(r6), max(r6)))
check((min(r4), max(r4)) == (-508, 0), "header: 'with the count of 4 ... spans [-508, 0]'",
      "actual [%d, %d]" % (min(r4), max(r4)))
fires = [(d, p) for d in range(256) for p in range(128) if not 0 <= scale(d, p, 6)+0x7F <= 0x7F]
check(not fires, "header: the caller's clamp 'does nothing at all'",
      "it fires for %d (depth,pos) pairs, depth bytes %s"
      % (len(fires), sorted({d for d, _ in fires})))

# ---------------------------------------------------------------- R3
print("\nR3  citation audit of the NEW comment lines (the cited-1 == 0x44/0x45/0x46 bug)")
starts = set()
for l in src:
    if l[:1] in ('\t', ' '):
        m = re.search(r';\s*([0-9A-F]{6})\s\s', l)
        if m: starts.add(int(m.group(1), 16))
diff = subprocess.run(['git', 'show', '6f6ee7e', '--', 'prom_c/wsa1_prom_c.s'],
                      cwd=ROOT, capture_output=True, text=True).stdout
cited = {int(m.group(1), 16) for l in diff.split('\n') if l.startswith('+;')
         for m in re.finditer(r'0x(F[A-F0-9]{5})\b', l)}
bad = [a for a in sorted(cited) if a not in starts]
sig = [a for a in bad if rom[a-BASE-1] in (0x44, 0x45, 0x46)]
check(not sig, "no citation lands one byte past an instruction",
      "%d of %d cited addresses are not instruction starts; %d carry the signature; "
      "the non-starts are %s (all data-table addresses cited as data)"
      % (len(bad), len(cited), len(sig), ' '.join('0x%06X' % a for a in bad)))

# ---------------------------------------------------------------- R4
print("\nR4  provenance of the +35 `headers` metric delta")
blanks = [i for i, l in enumerate(diff.split('\n')) if l == '-']
lines = diff.split('\n')
followed = sum(1 for i in blanks if i+1 < len(lines)
               and re.match(r'^ [A-Za-z_][A-Za-z0-9_]*:\s*$', lines[i+1]))
newev = sum(1 for l in lines if re.match(r'^\+;\s*Evidence:', l))
check(followed == 0, "the +35 headers are newly WRITTEN prose, not unblanked existing blocks",
      "%d removed blank lines, %d of them immediately before a label; "
      "%d genuinely new 'Evidence:' lines" % (len(blanks), followed, newev))

print("\n%d checks, %d refuted" % (4+3, len(fails)))
for f in fails: print("  refuted: %s" % f)
sys.exit(0)
