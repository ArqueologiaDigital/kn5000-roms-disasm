#!/usr/bin/env python3
"""H0 gate: build + SELF-TEST the UI-name -> slot -> chip -> image-hash table."""
import os, re, sys, hashlib, collections

DISASM = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
sys.path.insert(0, os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
import kn5000_dsp_extract as E

MAIN = os.path.join(DISASM, "original_ROMs", "kn5000_v10_program.rom")
SUB  = os.path.join(DISASM, "original_ROMs", "kn5000_subprogram_v142.rom")
UPL  = os.path.join(DISASM, "dsp", "analysis", "data", "typewalk",
                    "kn5000_dsp1_upload.txt")
ALGO_TABLE, PARAM_TABLE, N = 0x0001ED7C, 0x0001EF0C, 100
DSPEFF_LIST, REVERB_LIST = 0x4465C, 0x4475C      # file offsets in the main ROM

main = open(MAIN, "rb").read()
fail = []; nchk = 0
def check(label, got, want):
    global nchk
    nchk += 1
    ok = (got == want)
    print(("  PASS  " if ok else "  FAIL  ") + "%-54s got=%r want=%r" % (label, got, want))
    if not ok: fail.append(label)

# ---------- names ------------------------------------------------------
src = open(os.path.join(DISASM, "v10", "maincpu", "ui_widgets",
                        "naka_widget_descriptors.c"), encoding="utf-8",
           errors="replace").read()
STRS = dict((int(n), s) for n, s in
            re.findall(r"\.str_(\d+)\s*=\s*ALIGNED_STRING\(\"((?:[^\"\\]|\\.)*)\"\)", src))
ORDER = [int(x) for x in re.findall(r"SELF\(str_(\d+)\)",
         re.search(r"\.ptrs_0\s*=\s*\{(.*?)\}", src, re.S).group(1))]
NAME = {a: STRS[ORDER[a]].strip() for a in range(len(ORDER))}

# ---------- streams ----------------------------------------------------
rom = E.Rom(SUB)
def parse(addr, limit=8192):
    recs, p, g = [], addr, 0
    while g < limit:
        g += 1
        try: b0, b1 = rom.u8(p), rom.u8(p + 1)
        except IndexError: break
        op = b0 >> 4
        if op == 0xF: break
        ln = ((b0 & 0xF) << 8) | b1
        if ln < 2 or ln > 0xFFF: break
        body = rom.slice(p + 2, ln - 2)
        r = dict(op=op, cmd=body[0] if body else None)
        if op == 3 and len(body) >= 3:
            r["iaddr"] = (body[1] << 8) | body[2]
            d = body[3:]
            r["words"] = [bytes(d[k:k+5]) for k in range(0, len(d) - 4, 5)]
        elif op == 0xE and len(body) >= 3:
            r["iaddr"] = (body[1] << 8) | body[2]
        recs.append(r); p += ln
    return recs

ALG = {}
for a in range(N):
    pr = parse(rom.u32le(ALGO_TABLE + 4*a))
    pa = parse(rom.u32le(PARAM_TABLE + 4*a))
    ic310 = any(r.get("cmd") == 0x30 for r in pr + pa)
    blocks = [r for r in pr if r["op"] == 3 and "words" in r]
    img = b"".join(w for r in blocks for w in r["words"])
    ALG[a] = dict(name=NAME.get(a), chip="IC310" if ic310 else "IC311",
                  load=blocks[0]["iaddr"] if blocks else None,
                  words=sum(len(r["words"]) for r in blocks),
                  img=img, h=hashlib.sha256(img).hexdigest()[:16] if img else None,
                  nprog=len(pr), nparam=len(pa),
                  ops=sorted(set(r["op"] for r in pr)))
NOP_H = ALG[0]["h"]

# ---------- the two front-panel TYPE lists -----------------------------
def lists(off):
    fwd, i = [], off
    while main[i] != 0xFF: fwd.append(main[i]); i += 1
    return fwd, main[off + 0x80: off + 0x100]
DSP_FWD, DSP_INV = lists(DSPEFF_LIST)
REV_FWD, REV_INV = lists(REVERB_LIST)
inv = {a: i for i, a in enumerate(DSP_FWD)}

print("=== SELF-TEST BLOCK (read this before any row) ===\n")
print("-- T1  name table: name(algo) = str_(127-algo) via ptrs_0; 40 known answers")
tsv = {}
for line in open(os.path.join(DISASM, "dsp", "programs.tsv")):
    if line.startswith("#") or not line.strip(): continue
    t = line.split("\t"); tsv[int(t[0])] = t[1]
check("programs.tsv effect_name == ptrs_0 name (40 reps)",
      [(a, NAME[a], nm) for a, nm in tsv.items() if NAME[a] != nm], [])

print("\n-- T2  the two front-panel lists are self-inverse")
check("DSP EFFECT forward length", len(DSP_FWD), 38)
check("DSP EFFECT inverse agrees at every entry",
      all(DSP_INV[a] == i for i, a in enumerate(DSP_FWD)), True)
check("DSP EFFECT inverse != 0xFF exactly on the listed algos",
      sorted(a for a in range(128) if DSP_INV[a] != 0xFF), sorted(DSP_FWD))
check("DIGITAL REVERB forward length", len(REV_FWD), 14)
check("DIGITAL REVERB inverse agrees at every entry",
      all(REV_INV[a] == i for i, a in enumerate(REV_FWD)), True)
check("DIGITAL REVERB inverse != 0xFF exactly on the listed algos",
      sorted(a for a in range(128) if REV_INV[a] != 0xFF), sorted(REV_FWD))

print("\n-- T3  the anchors the brief supplied")
check("TYPE 0 == CHORUS", NAME[DSP_FWD[0]], "CHORUS")
check("TYPE 6 == GATED REVERB", NAME[DSP_FWD[6]], "GATED REVERB")
check("a10 MULTI TAP DELAY at TYPE 8", inv[10], 8)
check("a39 PARAMETRIC EQ at TYPE 15", inv[39], 15)
check("a70 AUTO WAH+S.DELAY at TYPE 28", inv[70], 28)
print("  ---- the two the brief got WRONG (both FAIL on purpose) ----")
check("brief: a99 PEQ+OVERDR+DELAY at TYPE 36", inv[99], 36)
check("brief: TYPELAST == 36", len(DSP_FWD) - 1, 36)

print("\n-- T4  cross-version control: v7 / v9 / v10 carry identical lists")
for v in ("v7", "v9", "v10"):
    d = open(os.path.join(DISASM, "original_ROMs",
                          "kn5000_%s_program.rom" % v), "rb").read()
    check("%s DSP EFFECT list bytes" % v, d[DSPEFF_LIST:DSPEFF_LIST+38], bytes(DSP_FWD))
    check("%s DIGITAL REVERB list bytes" % v, d[REVERB_LIST:REVERB_LIST+14], bytes(REV_FWD))

print("\n-- T5  the machine's own upload walk, matched to ROM images")
xfers, cur = [], None
for ln in open(UPL):
    ln = ln.rstrip("\n")
    m = re.match(r"transfer\s+(\d+): cmd 0x(\w+)\s+(\d+) bytes.*?I-RAM\[(\d+)\.\.(\d+)\]", ln)
    if m:
        cur = dict(cmd=int(m.group(2), 16), start=int(m.group(4)), data=b""); xfers.append(cur); continue
    if re.match(r"transfer\s+\d+:", ln): cur = None; continue
    m = re.match(r"\s+[0-9A-F]{4}: ((?:[0-9A-F]{2} ?)+)$", ln)
    if m and cur is not None: cur["data"] += bytes.fromhex(m.group(1).replace(" ", ""))
bodies = [x for x in xfers if x["cmd"] == 1 and x["start"] == 84]
BYIMG = collections.defaultdict(list)
for a, d in ALG.items():
    if d["img"]: BYIMG[d["img"]].append(a)
walk = []
for x in bodies:
    pay = x["data"][2:]                       # strip the 16-bit load address
    walk.append(BYIMG.get(pay[:len(pay)//5*5], ["?"]))
check("body uploads captured at I-RAM[84..]", len(bodies), 37)
check("every upload matches a ROM image", sum(1 for w in walk if w == ["?"]), 0)
j, missing, mism = 0, [], []
for k, cands in enumerate(walk):
    while j < len(DSP_FWD) and DSP_FWD[j] not in cands: missing.append(j); j += 1
    if j >= len(DSP_FWD): mism.append(k); break
    j += 1
check("walk is a subsequence of the ROM list", mism, [])
check("ROM entries the walk never reached",
      [(i, NAME[DSP_FWD[i]]) for i in missing], [(36, "PEQ+DIST+DELAY")])

print("\n-- T6  negative controls (a census printing a clean zero must be able to fail)")
check("NO OPERATION (a00) absent from the DSP EFFECT list", 0 in DSP_FWD, False)
check("SLOW ATTACKER (a37) present in the DSP EFFECT list", 37 in DSP_FWD, True)
check("a16..a27 absent from the DSP EFFECT list",
      [a for a in range(16, 28) if a in DSP_FWD], [])
check("no IC310 algorithm on either front-panel list",
      [a for a in DSP_FWD + REV_FWD if ALG[a]["chip"] == "IC310"], [])

print("\nSELF-TEST: %d checks, %d FAILED (2 of them deliberately) -> %s\n"
      % (nchk, len(fail), fail))

# ---------- the tables --------------------------------------------------
print("=== TABLE A -- DSP EFFECT page (page type 0x0B), %d entries ===" % len(DSP_FWD))
print("TYPE algo UI name             chip  unit ld  wds image-hash(sha256/16) stub")
for i, a in enumerate(DSP_FWD):
    d = ALG[a]
    print("%4d %4d %-20s %-5s %-4s %-3s %3d %-20s %s" %
          (i, a, d["name"], d["chip"], {84: 0, 200: 1}.get(d["load"], "?"),
           d["load"], d["words"], d["h"], "STUB" if d["h"] == NOP_H else ""))

print("\n=== TABLE B -- DIGITAL REVERB page (page type 0x0A), %d entries ===" % len(REV_FWD))
for i, a in enumerate(REV_FWD):
    d = ALG[a]
    print("%4d %4d %-20s %-5s %-4s %-3s %3d %-20s" %
          (i, a, d["name"], d["chip"], {84: 0, 200: 1}.get(d["load"], "?"),
           d["load"], d["words"], d["h"]))

print("\n=== TABLE C -- IC310 (MN19413) algorithms ===")
for a in sorted(ALG):
    d = ALG[a]
    if d["chip"] != "IC310": continue
    print("  a%-3d %-16s load=%-6s words=%-4d hash=%-20s progrecs=%d paramrecs=%d ops=%s"
          % (a, d["name"], d["load"], d["words"], d["h"], d["nprog"], d["nparam"], d["ops"]))

print("\n=== TABLE D -- named algorithms shipping the NO-OPERATION image ===")
stubs = [a for a in sorted(ALG) if ALG[a]["h"] == NOP_H
         and ALG[a]["name"] and not ALG[a]["name"].startswith("---")]
for a in stubs:
    print("  a%-3d %-18s %s" % (a, ALG[a]["name"],
          "DSP EFFECT TYPE %d" % inv[a] if a in inv else "not on either front-panel list"))
print("  named: %d   unnamed '----------' slots on the same image: %d   total: %d"
      % (len(stubs),
         sum(1 for a in ALG if ALG[a]["h"] == NOP_H and (ALG[a]["name"] or "").startswith("---")),
         sum(1 for a in ALG if ALG[a]["h"] == NOP_H)))

print("\n=== census ===")
print("  named (not '----------') algorithms:",
      sum(1 for a in ALG if ALG[a]["name"] and not ALG[a]["name"].startswith("---")))
print("  IC311:", sum(1 for a in ALG if ALG[a]["chip"] == "IC311"),
      " IC310:", sum(1 for a in ALG if ALG[a]["chip"] == "IC310"))
print("  distinct IC311 images:",
      len(set(d["img"] for d in ALG.values() if d["chip"] == "IC311" and d["img"])))
print("  unit-1 (load 200) algorithms:", sorted(a for a in ALG if ALG[a]["load"] == 200))
print("  front-panel-selectable algorithms (A + B, deduped):",
      len(set(DSP_FWD) | set(REV_FWD)))
print("  named algorithms NOT on either list:",
      sorted((a, ALG[a]["name"]) for a in ALG
             if ALG[a]["name"] and not ALG[a]["name"].startswith("---")
             and a not in DSP_FWD and a not in REV_FWD))
