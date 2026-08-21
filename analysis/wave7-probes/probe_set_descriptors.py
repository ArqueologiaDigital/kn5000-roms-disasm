#!/usr/bin/env python3
"""Re-derive every number in the ToneDB_EnvDescTable / ToneEnv header comments.

Run:  python3 scripts/analysis/probe_set_descriptors.py
(no arguments; reads original_ROMs/kn5000_table_data.rom relative to the repo)

Questions it answers, in order:
 1. Do the 487 15-byte records at 0x857914 own 974 distinct ToneDB_Base-relative
    offsets that exactly tile the ToneEnv region 0x85B09D-0x863078?          -> yes
 2. Is the zone-record stride derivable from flags bit 7 alone (6 vs 4)?
    Checked two ways: every B chunk length is a multiple of the derived stride,
    and every A chunk's largest index byte equals (B chunk zone count - 1).   -> 487/487
 3. Census of the flags byte, the key range +0x09/+0x0A, the root byte +0x0B,
    the base pitch +0x0C and the unidentified byte +0x0E.
 4. The bit-1 rule: which records set flags bit 1, what root/base pitch they
    carry, and how many semitones an unconditional (base pitch - pivot)
    fabricates for them.
 5. The melodic/percussion split at record 341, cross-checked against the value
    ranges of ToneIndexMapC/D and DrumToneIndexMap.
 6. Zone-record field census: selector classes, byte +0x02 (bit 7 override and
    bits 6..4), signed byte +0x03, and the stride-6 coarse trim word.
 7. Which 128-byte tables in the ToneDB_VelocityCurve_0..5 block the SET A
    chunks point at, and whether anything else in the 2 MB ROM points there.
"""
import os, struct, collections

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = open(os.path.join(REPO, "original_ROMs", "kn5000_table_data.rom"), "rb").read()

ROMBASE = 0x800000
DBB     = 0x830000          # ToneDB_Base
DESC    = 0x857914          # ToneDB_EnvDescTable
NDESC   = 487
STRIDE  = 15                # directory word +0xEC / +0xF2
ENV_LO  = 0x85B09D - DBB    # first ToneEnv chunk, ToneDB_Base-relative
ENV_HI  = 0x863079 - DBB    # one past the last

o  = lambda a: a - ROMBASE
u8 = lambda a: ROM[o(a)]
u16 = lambda a: struct.unpack_from("<H", ROM, o(a))[0]
u32 = lambda a: struct.unpack_from("<I", ROM, o(a))[0]

recs = []
for i in range(NDESC):
    a = DESC + i * STRIDE
    b = ROM[o(a):o(a) + STRIDE]
    recs.append(dict(i=i, f=b[0],
                     A=struct.unpack("<I", b[1:5])[0],
                     B=struct.unpack("<I", b[5:9])[0],
                     lo=b[9], hi=b[10], root=b[11],
                     bp=struct.unpack("<H", b[12:14])[0], e=b[14]))

# --- 1. chunk tiling -------------------------------------------------------
offs = sorted(set([r["A"] for r in recs] + [r["B"] for r in recs]))
assert len(offs) == 2 * NDESC == 974
assert offs[0] == ENV_LO and offs[-1] < ENV_HI
end = {v: (offs[k + 1] if k + 1 < len(offs) else ENV_HI) for k, v in enumerate(offs)}
print("1. 974 distinct offsets, tiling 0x%06X-0x%06X: OK" % (ENV_LO, ENV_HI - 1))

# --- 2. stride from flags bit 7 -------------------------------------------
for r in recs:
    r["s"] = 6 if r["f"] & 0x80 else 4
    r["nzone"] = (end[r["B"]] - r["B"]) // r["s"]
    r["lenA"] = end[r["A"]] - r["A"]
    r["kt"] = u32(DBB + r["A"])
    r["idx"] = list(ROM[o(DBB + r["A"]) + 4:o(DBB + r["A"]) + r["lenA"]])
    r["km"] = list(ROM[o(DBB + r["kt"]):o(DBB + r["kt"]) + 128])
bad_mult = [r["i"] for r in recs if (end[r["B"]] - r["B"]) % r["s"]]
bad_max  = [r["i"] for r in recs if not r["idx"] or max(r["idx"]) != r["nzone"] - 1]
bad_len  = [r["i"] for r in recs if len(r["idx"]) != max(r["km"]) + 1]
print("2. stride = 6 if flags bit7 else 4 -> B length multiple: %d bad; "
      "A max index == nzones-1: %d bad; A length == max(keymap)+1: %d bad"
      % (len(bad_mult), len(bad_max), len(bad_len)))
print("   stride census:", dict(sorted(collections.Counter(r["s"] for r in recs).items())))

# --- 3. field census -------------------------------------------------------
print("3. flags:", dict(sorted(collections.Counter(r["f"] for r in recs).items())))
print("   +0x09 %d..%d  +0x0A %d..%d  (lo > hi in %d records)"
      % (min(r["lo"] for r in recs), max(r["lo"] for r in recs),
         min(r["hi"] for r in recs), max(r["hi"] for r in recs),
         sum(1 for r in recs if r["lo"] > r["hi"])))
print("   root +0x0B:", dict(collections.Counter(r["root"] for r in recs)))
print("   +0x0E     :", dict(sorted(collections.Counter(r["e"] for r in recs).items())))
print("   base pitch == 0x4280 in %d records"
      % sum(1 for r in recs if r["bp"] == 0x4280))

# --- 4. the bit-1 rule -----------------------------------------------------
b1 = [r for r in recs if r["f"] & 0x02]
print("4. flags bit1 set in %d records: %s" % (len(b1), [r["i"] for r in b1]))
print("   root != 0x42 in            : %s" % [r["i"] for r in recs if r["root"] != 0x42])
print("   base pitch of those        : %s" % sorted({hex(r["bp"]) for r in b1}))
for r in recs:
    r["net"] = r["bp"] - (r["root"] * 256 + 0x80)
print("   fabricated (bp - pivot) for the 13: %s semitones"
      % sorted({round(r["net"] / 256, 3) for r in b1}))

def selectors(r):
    return [u16(DBB + r["B"] + k * r["s"]) for k in range(r["nzone"])]
all_sel = set()
for r in recs:
    all_sel |= set(selectors(r))
b1_only = set().union(*[set(selectors(r)) for r in b1])
b1_only -= set().union(*[set(selectors(r)) for r in recs if not r["f"] & 0x02])
print("   distinct selectors overall %d; reachable ONLY from the 13: %d (%.1f%%)"
      % (len(all_sel), len(b1_only), 100.0 * len(b1_only) / len(all_sel)))

# --- 5. melodic / percussion split -----------------------------------------
def maprange(addr):
    t = struct.unpack_from("<1024H", ROM, o(addr))
    return min(t), max(t)
print("5. ToneIndexMapC %s  ToneIndexMapD %s  DrumToneIndexMap %s"
      % (maprange(0x85959D), maprange(0x859D9D), maprange(0x85A59D)))
mel = [r for r in recs if r["i"] < 341]
per = [r for r in recs if r["i"] >= 341]
print("   melodic 0..340 : %d multi-zone, %d stride-6, %d with root != 0x42,"
      " %d with net != 0" % (sum(1 for r in mel if r["nzone"] > 1),
                             sum(1 for r in mel if r["s"] == 6),
                             sum(1 for r in mel if r["root"] != 0x42),
                             sum(1 for r in mel if r["net"])))
print("   perc 341..486  : %d multi-zone, %d stride-6, %d with root != 0x42,"
      " %d with net != 0, key ranges %s"
      % (sum(1 for r in per if r["nzone"] > 1), sum(1 for r in per if r["s"] == 6),
         sum(1 for r in per if r["root"] != 0x42), sum(1 for r in per if r["net"]),
         sorted({(r["lo"], r["hi"]) for r in per})))

# --- 6. zone-record fields -------------------------------------------------
cls = collections.Counter(); b2 = collections.Counter()
b3 = []; trim = []
for r in recs:
    for k in range(r["nzone"]):
        z = ROM[o(DBB + r["B"] + k * r["s"]):o(DBB + r["B"] + k * r["s"]) + r["s"]]
        cls[struct.unpack("<H", z[0:2])[0] >> 12] += 1
        b2[z[2]] += 1
        b3.append(struct.unpack("<b", z[3:4])[0])
        if r["s"] == 6:
            trim.append(struct.unpack("<h", z[4:6])[0])
print("6. %d zone records; selector class census %s"
      % (sum(cls.values()), dict(sorted(cls.items()))))
print("   +0x02 census %s" % {hex(k): v for k, v in sorted(b2.items())})
print("   +0x02 low nibble always 0: %s ; no value with bit7 clear and bits6..4 set: %s"
      % (all(k & 0x0F == 0 for k in b2), all(k == 0 or k & 0x80 for k in b2)))
print("   +0x03 signed: %d..%d, mean %.2f, negative in %d of %d"
      % (min(b3), max(b3), sum(b3) / len(b3), sum(1 for v in b3 if v < 0), len(b3)))
print("   stride-6 trim word: %d values, %.2f..%.2f semitones, %d zero"
      % (len(trim), min(trim) / 256, max(trim) / 256, sum(1 for t in trim if t == 0)))

# --- 7. the key->band tables ----------------------------------------------
use = collections.Counter(r["kt"] for r in recs)
CURVE0 = 0x85AD9D - DBB
for k in sorted(use):
    km = ROM[o(DBB + k):o(DBB + k) + 128]
    print("7. curve %d (rel 0x%05X): max %3d -> %3d bands, used by %3d SETs"
          % ((k - CURVE0) // 128, k, max(km), max(km) + 1, use[k]))
hits = collections.Counter()
for a in range(len(ROM) - 4):
    v = struct.unpack_from("<I", ROM, a)[0]
    if CURVE0 <= v < CURVE0 + 6 * 128:
        hits[v] += 1
print("   LE32 values pointing into the 768-byte curve block, whole 2 MB ROM:")
for v, c in sorted(hits.items()):
    print("     rel 0x%05X (curve %d, +%d): %d" % (v, (v - CURVE0) // 128,
                                                   (v - CURVE0) % 128, c))
