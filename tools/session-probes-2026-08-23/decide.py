#!/usr/bin/env python3
"""Per range: is the DECODE mis-framed, or is the LABEL wrong?

Evidence gathered per range/label, all from the v7 ROM itself:
  E1 entry is a call/jp/jrl target read out of an already-decoded instruction
     (analysis/v7-reachability/v7_call_targets.json)
  E2 the instruction that ENDS at `entry` under the enclosing block's framing is
     a terminator -- i.e. `entry` is where the previous routine stopped
  E3 the enclosing block label's own framing puts a boundary exactly at `entry`
  L1 unidasm cannot decode ANY instruction starting at the label (`db`)
  L2 drift: label - (nearest entry-framing boundary at or below it)
  L3 nothing in the v7 tree references the label; it is not a call target; its
     address is not a 32-bit value anywhere in the ROM  (already measured 0/57)
"""
import json, os, pickle, re, subprocess, sys
ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"
S = os.environ["SCRATCH"]; BASE = 0xE00000
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
rom = open(os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
targets = set(json.load(open(os.path.join(ROOT, "analysis/v7-reachability/v7_call_targets.json")))["targets"])
cases = sorted(pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))["cases"], key=lambda c: c["entry"])
align = {r["entry"]: r for r in json.load(open(os.path.join(S, "align.json")))}
TERM = ("ret", "reti", "retd")
UNCOND = re.compile(r'^(?:jp\s+(?!(?:z|nz|c|nc|t|f|lt|ge|le|gt|ult|uge|ule|ugt|ov|nov|mi|pl)\s*,)|(?:jr|jrl)\s+t\s*,)', re.I)


def dis(start, n):
    p = os.path.join(S, "_d.bin"); open(p, "wb").write(rom[start - BASE:start - BASE + n])
    o = subprocess.run([UNI, p, "-arch", "tlcs900", "-basepc", hex(start)],
                       capture_output=True, text=True).stdout
    rows = []
    for line in o.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return rows


out = []
for c in cases:
    e, sp = c["entry"], c["span"]
    fb = c["blocks"][0][1]
    end = e + sp
    ia = {a for a, _n, _x in c["insns"]}
    # framing from the enclosing block label
    bl = dis(fb, max(end - fb, 8) + 16)
    blset = {a for a, _n, _x in bl}
    prev = [r for r in bl if r[0] + r[1] == e]
    e2 = bool(prev) and (prev[0][2].split()[0].lower() in TERM or bool(UNCOND.match(prev[0][2])))
    e2txt = prev[0][2] if prev else None
    # did the block framing hit a `db` before reaching e?
    blbad = any(r[2].split()[0].lower() == "db" and r[0] < e for r in bl)
    labs = []
    for a, nm in c["off_boundary"]:
        d = dis(a, min(32, end - a + 16))
        l1 = bool(d) and d[0][2].split()[0].lower() == "db"
        below = max((x for x in ia if x <= a), default=None)
        labs.append({"name": nm, "addr": a, "db_at_label": l1,
                     "drift": (a - below) if below is not None else None,
                     "in_block_framing": a in blset,
                     "first": d[0][2] if d else ""})
    al = align.get(e, {})
    sib = al.get("v9") if al.get("v9", {}).get("aligned") else al.get("v10", {})
    out.append({"entry": e, "span": sp, "file": c["blocks"] and os.path.basename(c["path"]),
                "n_off": len(c["off_boundary"]),
                "E1_call_target": e in targets,
                "E2_prev_terminates": e2, "E2_prev_insn": e2txt,
                "E3_block_framing_hits_entry": e in blset,
                "block_framing_hit_db_first": blbad,
                "first_block": fb, "first_block_label": c["blocks"][0][0],
                "labels": labs,
                "sib": ({"delta": sib.get("delta"), "win": sib.get("win"),
                         "entry_is_start": sib.get("entry_is_start"),
                         "insn": f"{sib.get('insn_agree')}/{sib.get('insn_total')}",
                         "code": f"{sib.get('code_bytes')}/{sp}",
                         "labels_ok": sum(1 for l in sib.get("labels", []) if l["is_start"])}
                        if sib.get("aligned") else None),
                "texts": c["texts"]})
json.dump(out, open(os.path.join(S, "decide.json"), "w"), indent=1)

nl = sum(r["n_off"] for r in out)
print(f"{len(out)} ranges, {sum(r['span'] for r in out)} B, {nl} off-boundary labels\n")
print("PER-RANGE EVIDENCE THAT THE DECODE IS RIGHT")
print(f"  E1 entry is a decoded call/jp target : {sum(r['E1_call_target'] for r in out)}/{len(out)}")
print(f"  E2 previous insn TERMINATES at entry : {sum(r['E2_prev_terminates'] for r in out)}/{len(out)}")
print(f"  E3 block framing has a boundary at e : {sum(r['E3_block_framing_hits_entry'] for r in out)}/{len(out)}")
print(f"     (block framing hit `db` before e) : {sum(r['block_framing_hit_db_first'] for r in out)}/{len(out)}")
print("\nPER-LABEL EVIDENCE THAT THE LABEL IS WRONG")
print(f"  L1 unidasm cannot start an insn there: {sum(1 for r in out for l in r['labels'] if l['db_at_label'])}/{nl}")
print(f"  L3 label in the enclosing block's own framing: "
      f"{sum(1 for r in out for l in r['labels'] if l['in_block_framing'])}/{nl}")
import collections
dr = collections.Counter(l["drift"] for r in out for l in r["labels"])
print("  L2 drift from the nearest decoded boundary below it:")
for k, v in sorted(dr.items(), key=lambda kv: (kv[0] is None, kv[0])):
    print(f"       +{k}: {v}")
