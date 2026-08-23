import pickle, os, sys
S = os.environ["SCRATCH"]
d = pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))
cases = d["cases"]
cases.sort(key=lambda r: r["entry"])
tot = 0
for r in cases:
    tot += r["span"]
    print(f"0x{r['entry']:06X}  span={r['span']:4}  lead={r.get('lead')}  tail={r.get('tail')}  "
          f"insns={len(r['insns'])}  file={os.path.basename(r.get('path','?'))}")
    print(f"    blocks: " + " | ".join(f"{nm or '(unlab)'}@0x{a:06X}+{n}" for nm,a,n,s,e in r["blocks"]))
    print(f"    off-boundary labels ({len(r['off_boundary'])}): " +
          ", ".join(f"{nm}@0x{a:06X}" for a,nm in r["off_boundary"]))
    if r["raw_unknown_labels"]:
        print(f"    raw-unknown labels in span: {r['raw_unknown_labels']}")
print(f"\n{len(cases)} ranges, {tot} bytes")
