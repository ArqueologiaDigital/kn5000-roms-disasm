#!/usr/bin/env python3
"""SQUARING-MULTIPLY census.  READ-ONLY over dsp/disasm/*.dsm.

A class-A multiply SQUARES its own coefficient iff, at the multiply,
   coef port  = C-RAM[cursor]         (always, on class4==0xA && !c_format)
   operand L  = C-RAM[cursor] as well (iff SRC == 0x08, upd6383.cpp:3250-3256)
so the STATIC predicate is
   class4(w)==0xA && !c_format(w) && lo_src(w)==0x08
(plus the dynamic proviso that the §72 cursor relocation did not move one of them,
 and the f31 != HOLD gate that lets the multiply issue at all).
"""
import re, sys, os, collections

DIS = "/home/fsanches/compartilhado/kn5000-roms-disasm/dsp/disasm"

# --- field accessors, transcribed verbatim from upd6383d.h -------------------
hi12   = lambda w: (w >> 24) & 0xfff
class4 = lambda w: (w >> 20) & 0xf
addr8  = lambda w: (w >> 12) & 0xff
lo12   = lambda w:  w & 0xfff
c_format = lambda w: (hi12(w) & 0xf00) == 0xc00
is_c40   = lambda w: (hi12(w) & 0xffe) == 0xc40
lo_src = lambda w: (w >> 6) & 0x1f          # lo12[10:6]   RULE 18
lo_act = lambda w:  w & 0x1f                # lo12[4:0]    RULE 18
lo_ptrmode = lambda w: (w >> 5) & 1
hi_f31 = lambda w: (hi12(w) >> 1) & 7
hi_f98 = lambda w: (hi12(w) >> 8) & 3
HI_ST  = lambda w: (hi12(w) >> 4) & 1
coeff_consumer = lambda w: class4(w) == 0xa and not c_format(w)
coeff_fetch    = lambda w: (class4(w) & 8) and not c_format(w)

tsv0 = "/home/fsanches/compartilhado/kn5000-roms-disasm/dsp/programs.tsv"
WORDRE = re.compile(r'^\s*w(\d+)\s+([0-9A-Fa-f]{10})\s')

def load():
    out = {}
    for fn in sorted(os.listdir(DIS)):
        if not fn.endswith(".dsm"):
            continue
        ws = []
        for line in open(os.path.join(DIS, fn), encoding="utf-8", errors="replace"):
            m = WORDRE.match(line)
            if m:
                ws.append((int(m.group(1)), int(m.group(2), 16)))
        if ws:
            out[fn] = ws
    return out

L = load()
allw = [(f, i, w) for f, ws in L.items() for i, w in ws]
print("listings parsed: %d   words: %d" % (len(L), len(allw)))

# ===========================================================================
# RULE 20 SELF-TEST.  Every control below has a published answer that predates
# this script; a detector that cannot reproduce them is not allowed to report.
# ===========================================================================
print("\n=== SELF-TEST (known answers, all from the notes / upd6383d.h) ===")
def chk(name, got, want):
    print("  %-56s got %-8s want %-8s %s"
          % (name, got, want, "PASS" if got == want else "*** FAIL ***"))
    return got == want

ok = True
ok &= chk("total corpus words (§215: 3057 over 41 listings)", len(allw), 3057)
ok &= chk("word-bearing listings (41 files, index.dsm has no words)", len(L), 40)
ok &= chk("c_format words (upd6383d.h: 68 of 3057)",
          sum(1 for _,_,w in allw if c_format(w)), 68)
ok &= chk("is_c40 words (upd6383d.h: 57)",
          sum(1 for _,_,w in allw if is_c40(w)), 57)
ok &= chk("SRC 0x0B words (§215: 106)",
          sum(1 for _,_,w in allw if lo_src(w) == 0x0b), 106)
ok &= chk("  ...of which class-1 (§215: 99)",
          sum(1 for _,_,w in allw if lo_src(w)==0x0b and class4(w)==1 and not c_format(w)), 99)
ok &= chk("  ...of which class-2 non-cfmt (§215/§218: 7)",
          sum(1 for _,_,w in allw if lo_src(w)==0x0b and class4(w)==2 and not c_format(w)), 7)
ok &= chk("ACT 0x00 words, c_format-guarded (upd6383d.h: 820)",
          sum(1 for _,_,w in allw if lo_act(w)==0x00 and not c_format(w)), 820)
ok &= chk("ACT 0x00 distinct, c_format-guarded (upd6383d.h: 170)",
          len({w for _,_,w in allw if lo_act(w)==0x00 and not c_format(w)}), 170)
ok &= chk("lo12 bit5 ptrmode words (upd6383d.h: 96)",
          sum(1 for _,_,w in allw if lo_ptrmode(w)), 96)
ok &= chk("classes 3/7/B/E/F empty under c_format guard (upd6383d.h)",
          sum(1 for _,_,w in allw if not c_format(w) and class4(w) in (3,7,0xb,0xe,0xf)), 0)
# §146's corpus is the SLOT-EXPANDED one (91 algorithm slots), not the 41 listings.
_sl = {}
for _line in open(tsv0):
    if _line.startswith("#"): continue
    _f=_line.rstrip("\n").split("\t"); _sl[_f[10]]=int(_f[7])
def wsum(pred):
    return sum(sum(1 for _,w in L[fn] if pred(w))*s for fn,s in _sl.items())
ok &= chk("SRC 0x00 class-A, SLOT-WEIGHTED over 91 slots (§146: 111)",
          wsum(lambda w: lo_src(w)==0 and coeff_consumer(w)), 111)
_r=chk("SRC 0x00 all, slot-weighted non-cfmt (§146: 1610) -- RESIDUAL",
          wsum(lambda w: lo_src(w)==0 and not c_format(w)), 1610)
ok &= chk("092.A.xx.200 SRC-0x08 LFO family (§145: 29)",
          sum(1 for _,_,w in allw if hi12(w)==0x092 and class4(w)==0xa and lo12(w)==0x200), 29)
ok &= chk("192.A.xx.000 SRC-0x00 twin family (§145: 29)",
          sum(1 for _,_,w in allw if hi12(w)==0x192 and class4(w)==0xa and lo12(w)==0x000), 29)
ok &= chk("182.A.00.000 envelope family (§147: 12)",
          sum(1 for _,_,w in allw if hi12(w)==0x182 and class4(w)==0xa
              and addr8(w)==0 and lo12(w)==0x000), 12)
ok &= chk("frame terminator C00.A.47.407 present exactly once",
          sum(1 for _,_,w in allw if hi12(w)==0xc00 and (w>>20 & 0xf)==0xa
              and addr8(w)==0x47 and lo12(w)==0x407), 1)
ok &= chk("  ...and it is EXCLUDED by coeff_consumer (c_format guard)",
          sum(1 for _,_,w in allw if hi12(w)==0xc00 and addr8(w)==0x47
              and lo12(w)==0x407 and coeff_consumer(w)), 0)

# per-program classA counts from programs.tsv -- an independent generator's answer
tsv = tsv0
want = {}
for line in open(tsv):
    if line.startswith("#"): continue
    f = line.rstrip("\n").split("\t")
    want[f[10]] = (int(f[4]), int(f[5]))     # words, classA
bad = []
for fn,(nw,nca) in want.items():
    ws = L[fn]
    gotw = len(ws)
    gotca = sum(1 for _,w in ws if coeff_consumer(w))
    if (gotw, gotca) != (nw, nca):
        bad.append((fn, (gotw,gotca), (nw,nca)))
ok &= chk("programs.tsv words+classA reproduced for all 38 images", len(bad), 0)
if bad:
    for b in bad: print("     MISMATCH", b)

print("\n  SELF-TEST OVERALL: %s" % ("PASS -- detector validated" if ok else "FAIL -- DO NOT REPORT"))
if not ok:
    sys.exit(1)

# ===========================================================================
# 1.  THE CENSUS
# ===========================================================================
CA   = [(f,i,w) for f,i,w in allw if coeff_consumer(w)]
SQ   = [(f,i,w) for f,i,w in CA   if lo_src(w) == 0x08]
NOTSQ= [(f,i,w) for f,i,w in CA   if lo_src(w) != 0x08]
print("\n=== 2. CENSUS OF CLASS-A MULTIPLIES (coeff_consumer) ===")
print("  class-A words in corpus                : %d   (denominator)" % len(CA))
print("  ...SRC 0x08  => SQUARES its coefficient: %d  (%.2f %%)" % (len(SQ), 100*len(SQ)/len(CA)))
print("  ...other SRC => two distinct operands   : %d  (%.2f %%)" % (len(NOTSQ), 100*len(NOTSQ)/len(CA)))
print("  distinct 36-bit words that square       : %d" % len({w for _,_,w in SQ}))

# the f31 != HOLD gate: does the multiply issue at all?
sq_iss = [t for t in SQ if hi_f31(t[2]) != 2]
print("  ...of the squarers, f31 != HOLD (multiply ISSUES): %d ; f31 == HOLD (suppressed): %d"
      % (len(sq_iss), len(SQ)-len(sq_iss)))

print("\n  SRC histogram over class-A words (the L port's binding):")
h = collections.Counter(lo_src(w) for _,_,w in CA)
for s,n in sorted(h.items(), key=lambda kv:-kv[1]):
    tag = "  <== SQUARES (C-RAM[cursor])" if s==0x08 else ""
    print("     SRC 0x%02X : %5d  (%5.2f %%)%s" % (s,n,100*n/len(CA),tag))

# ===========================================================================
# 2.  THE NULL -- would this fraction arise by chance?
# ===========================================================================
print("\n=== THE NULL: is SRC 0x08 enriched, depleted or indifferent on class A? ===")
nonCA = [(f,i,w) for f,i,w in allw if not coeff_consumer(w) and not c_format(w)]
p_all = sum(1 for _,_,w in allw   if lo_src(w)==0x08)/len(allw)
p_non = sum(1 for _,_,w in nonCA  if lo_src(w)==0x08)/len(nonCA)
p_ca  = len(SQ)/len(CA)
print("  P(SRC 0x08 | any corpus word)       = %5.2f %%  (%d/%d)"
      % (100*p_all, sum(1 for _,_,w in allw if lo_src(w)==0x08), len(allw)))
print("  P(SRC 0x08 | NON-class-A, non-cfmt) = %5.2f %%  (%d/%d)   <-- THE NULL"
      % (100*p_non, sum(1 for _,_,w in nonCA if lo_src(w)==0x08), len(nonCA)))
print("  P(SRC 0x08 | class-A)               = %5.2f %%  (%d/%d)   <-- OBSERVED"
      % (100*p_ca, len(SQ), len(CA)))
# hypergeometric-ish z on the null proportion
import math
n = len(CA); k = len(SQ)
exp = n*p_non
sd  = math.sqrt(n*p_non*(1-p_non)) if 0 < p_non < 1 else float('nan')
print("  expected under the null = %.1f ; observed = %d ; sd = %.1f ; z = %+.2f"
      % (exp, k, sd, (k-exp)/sd if sd else float('nan')))
print("  uniform-over-18-observed-SRC-codes null would be %.2f %%" % (100/18))

# ===========================================================================
# 3.  BY FAMILY / BY IMAGE
# ===========================================================================
fam = {}
role = {}
for line in open(tsv):
    if line.startswith("#"): continue
    f = line.rstrip("\n").split("\t")
    fam[f[10]] = f[8]; role[f[10]] = (f[1], int(f[7]))   # name, slots
print("\n=== 2b. PER-IMAGE (denominator = that image's class-A count) ===")
print("  %-34s %-11s %5s %5s %6s   %s" % ("listing","family","clsA","sq","pct","effect"))
byfam = collections.defaultdict(lambda:[0,0])
rows=[]
for fn in sorted(L):
    ws = L[fn]
    ca = sum(1 for _,w in ws if coeff_consumer(w))
    sq = sum(1 for _,w in ws if coeff_consumer(w) and lo_src(w)==0x08)
    fm = fam.get(fn, "kernel/epi" if fn in ("kernel.dsm","epilogue.dsm") else "-")
    nm = role.get(fn,(fn,0))[0]
    if ca or sq:
        byfam[fm][0]+=ca; byfam[fm][1]+=sq
        rows.append((fn,fm,ca,sq,nm))
for fn,fm,ca,sq,nm in rows:
    print("  %-34s %-11s %5d %5d %5.1f%%   %s" % (fn,fm,ca,sq,100*sq/ca if ca else 0,nm))
print("\n=== 2c. BY FAMILY ===")
for fm,(ca,sq) in sorted(byfam.items(), key=lambda kv:-kv[1][0]):
    print("  %-14s class-A %4d   squaring %3d   %5.1f %%" % (fm,ca,sq,100*sq/ca if ca else 0))

# ===========================================================================
# 4.  THE FIVE RUNTIME SLOTS -- static identity
# ===========================================================================
print("\n=== 1b. THE FIVE SLOTS §224 COUNTED (kernel.dsm) ===")
kern = dict(L["kernel.dsm"])
for iw in (30,31,32,33,34,41,89):
    w = kern.get(iw)
    if w is None:
        print("   iw%-3d  -- not in kernel.dsm (body word)" % iw); continue
    print("   iw%-3d %010X  %03X.%X.%02X.%03X  SRC %02X ACT %02X f31 %d ST %d  classA %s  SQ %s"
          % (iw, w, hi12(w), class4(w), addr8(w), lo12(w), lo_src(w), lo_act(w),
             hi_f31(w), HI_ST(w), coeff_consumer(w),
             coeff_consumer(w) and lo_src(w)==0x08))

# where else does the exact squaring word shape occur?
print("\n=== 1c. DISTINCT SQUARING WORDS, with occurrence counts ===")
cnt = collections.Counter(w for _,_,w in SQ)
loc = collections.defaultdict(list)
for f,i,w in SQ: loc[w].append("%s:w%d" % (f.replace("prog","").replace(".dsm",""), i))
for w,c in cnt.most_common():
    print("   %010X  %03X.A.%02X.%03X  ACT %02X f31 %d ST %d  x%-3d  %s"
          % (w, hi12(w), addr8(w), lo12(w), lo_act(w), hi_f31(w), HI_ST(w), c,
             ", ".join(loc[w][:6]) + (" ..." if len(loc[w])>6 else "")))

# ===========================================================================
# 5.  ACT breakdown of the squarers -- what do they DO with the product?
# ===========================================================================
print("\n=== 2d. ACTION field of squaring words vs non-squaring class-A words ===")
ha = collections.Counter(lo_act(w) for _,_,w in SQ)
hb = collections.Counter(lo_act(w) for _,_,w in NOTSQ)
print("   ACT   squaring    non-squaring-classA")
for a in sorted(set(ha)|set(hb)):
    print("   0x%02X  %6d       %6d" % (a, ha.get(a,0), hb.get(a,0)))
print("\n   f31 of squarers:", dict(collections.Counter(hi_f31(w) for _,_,w in SQ)))
print("   f31 of non-sq classA:", dict(collections.Counter(hi_f31(w) for _,_,w in NOTSQ)))
print("   f98 of squarers:", dict(collections.Counter(hi_f98(w) for _,_,w in SQ)))
