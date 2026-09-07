#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""gen_wsa1_dsp_disasm.py -- generate the SX-WSA1R effects-DSP disassembly tree.

The WSA1R runs three NEC uPD6383GF effect DSPs (IC5/IC6/IC30), the SAME chip as
the KN5000's IC311, so the same ISA model (dsp/tools/dsp_disasm.py) disassembles
both.  This mirrors the KN5000 deliverable (dsp/disasm/*.dsm + dsp/programs.tsv)
for the WSA1R: it extracts every effect's I-RAM program body from the P7 stream
pool, disassembles each 36-bit word, annotates it (effect name, algorithm-family
role, per-word decode + the speculative readings, C-RAM cursor addresses), and
emits one .dsm per effect plus a programs.tsv manifest and an index.

Where each part comes from (all MEASURED this project):
  * effect NAMES: prom_b EffectNames_F147AC (0xF147AC, 128 x 16 ASCII; base 0xF00000).
  * program -> record: prom_c PoolDir_RecordForUnitProgram (0xFDC551, 128 bytes).
  * record -> I-RAM program body: prom_c PoolDir_Records (0xFDBFD9, 56 x 25 bytes),
    field +12 (little-endian, 0xFD bank) = the opcode-3 body
    (dsp/analysis/dsp_record_field_opcodes.py: +12 is op3 for 48/56; +0/+4/+8 are
    coefficient streams).  MEASURED at runtime: the body loads at I-RAM 0x6E.

    python3 gen_wsa1_dsp_disasm.py            # regenerate the tree
    python3 gen_wsa1_dsp_disasm.py --table    # just print the manifest table

Deterministic and idempotent; derived ROM bytes are not written, only the
annotated listings + manifest (matching the repo's derived-data policy).
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import wsa1_dsp_isa_crossval as X          # noqa: E402  configures POOL (prom_c) + dsp_disasm
import dsp_disasm as D                     # noqa: E402  the shared ISA model

PROM_B = os.path.join(HERE, "..", "..", "original_ROMs", "wsa1_prom_b.ic13")
PROM_B_BASE = 0xF00000
NAMES_ADDR = 0xF147AC
REC = 0xFDBFD9          # PoolDir_Records base, 25-byte stride
STRIDE = 0x19
IDX = 0xFDC551          # PoolDir_RecordForUnitProgram, 128 bytes


def effect_names():
    """128 x 16-char names from prom_b; '' for the '----------' placeholders."""
    data = open(PROM_B, "rb").read()
    off = NAMES_ADDR - PROM_B_BASE
    out = []
    for k in range(128):
        raw = data[off + 16 * k: off + 16 * k + 16]
        s = raw.decode("latin1").strip()
        out.append("" if set(s) <= {"-", " ", ""} or not s else s)
    return out


def prog_to_record():
    return [X.POOL.D[IDX - X.POOL.BASE + p] for p in range(128)]


def record_field(rec, off):
    b = X.POOL.D[REC - X.POOL.BASE + STRIDE * rec + off:
                 REC - X.POOL.BASE + STRIDE * rec + off + 2]
    return 0xFD0000 | (b[0] | (b[1] << 8))          # little-endian, 0xFD bank


def op3_body(addr):
    """(iram_load_addr, [40-bit words]) for the opcode-3 record at addr, or None."""
    D_ = X.POOL.D
    b0 = D_[addr - X.POOL.BASE]
    if (b0 >> 4) != 3:
        return None
    ln = ((b0 & 0x0F) << 8) | D_[addr - X.POOL.BASE + 1]
    body = D_[addr + 2 - X.POOL.BASE: addr + ln - X.POOL.BASE]
    data = body[3:]                                  # cmd, addr_hi, addr_lo, then words
    load = (body[1] << 8) | body[2]
    words = [int.from_bytes(data[k:k + 5], "big") for k in range(0, len(data) - 4, 5)]
    return load, words


def build():
    names = effect_names()
    p2r = prog_to_record()
    # distinct real records, each named by the lowest program that maps to it
    rec_prog = {}
    for p in range(128):
        r = p2r[p]
        if r not in rec_prog:
            rec_prog[r] = p
    progs = []
    for rec in sorted(rec_prog):
        p = rec_prog[rec]
        nm = names[p] or ("(unnamed rec %d)" % rec)
        body = op3_body(record_field(rec, 12))
        # also collect every program number that resolves here (the shared slots)
        slots = [q for q in range(128) if p2r[q] == rec]
        progs.append(dict(rec=rec, prog=p, name=nm, slots=slots, body=body))
    return progs


PROVENANCE = [
    "; Reverse-engineered disassembly of the SX-WSA1R effects-DSP microcode",
    "; (NEC uPD6383GF, three instances IC5/IC6/IC30), recovered from the original",
    "; firmware.  The microcode is the work of its original authors; this is a",
    "; disassembly for preservation and interoperability, and no claim of copyright",
    "; is made over the disassembled program.",
]


# family from the effect name, and the KN5000 cross-reference role for shared names.
def kn5000_roles():
    """effect_name -> (family, confidence, role) from the KN5000 manifest."""
    path = os.path.join(HERE, "..", "..", "..", "dsp", "programs.tsv")
    out = {}
    try:
        for ln in open(path):
            if ln.startswith("#") or not ln.strip():
                continue
            f = ln.rstrip("\n").split("\t")
            if len(f) >= 12:
                out[f[1].strip()] = (f[8], f[9], f[11])
    except OSError:
        pass
    return out


def family_of(name):
    n = name.upper()
    if "+" in n:              return "combination"
    if "REVERB" in n:         return "reverb"
    if "DELAY" in n:          return "delay"
    if "PITCH" in n:          return "pitch"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "ENSEMBLE", "VIBRATO",
                            "AUTO PAN", "ROTARY", "RING MOD", "HAAS")): return "modulation"
    if any(k in n for k in ("DISTORT", "OVERDRIVE", "FUZZ")):          return "distortion"
    if any(k in n for k in ("PARAMETRIC EQ", "ENHANCER", "WAH")):      return "eq/filter"
    if any(k in n for k in ("COMPRESS", "NO OPERATION", "SLOW ATT")):  return "dynamics"
    if any(k in n for k in ("EXCITER", "NOISE")):                      return "exciter"
    return "other"


# canonical DSP-algorithm topology, keyed by family -- what the code SHOULD look like.
TOPOLOGY = {
    "modulation": "LFO-swept delay/all-pass line: an LFO phase accumulator (class-A "
                  "step + 0x7FFFFF wrap) drives a delay-DRAM read whose tap moves, "
                  "then a wet/dry mix. Chorus/ensemble = multiple detuned taps; "
                  "flanger/phaser = feedback all-pass chain.",
    "delay":      "delay line: a DRAM write of the input at a base cell and one or "
                  "more DRAM reads at base+offset (READ_CELL-WRITE_CELL = the tap), "
                  "fed back with a gain coefficient and mixed with dry.",
    "reverb":     "reverb tank: cascaded all-pass diffusers + comb/feedback-delay "
                  "network with a damping one-pole, per the KN5000 ROOM REVERB decode.",
    "eq/filter":  "biquad chain (Direct-Form-I bilinear): per band, five coefficient "
                  "multiplies b0/b1/b2/-a1/-a2 accumulated through the f31==1 carry, "
                  "with two z^-1 state cells in C-RAM.",
    "distortion": "waveshaper: a table-lookup / rail-clip nonlinearity, often preceded "
                  "by an AGC level detector and followed by a tone one-pole.",
    "dynamics":   "level detector (rectify -> one-pole envelope) feeding a gain "
                  "computer (threshold/ratio), applied to the dry path.",
    "exciter":    "harmonic generator: nonlinearity -> band-pass -> add-to-dry.",
    "pitch":      "pitch shifter: crossfaded variable-rate delay taps (two read "
                  "pointers swept in opposite directions with a windowed crossfade).",
    "combination": "serial chain of the above blocks (name lists the stages in order).",
    "other":      "topology not yet classified; read the per-word annotations.",
}


def classA_count(words):
    return sum(1 for w in words if (D.class4(w) & 0x8) and not D.c_format(w))


def spec_decoded(words):
    dec = sum(1 for w in words if D.alu_decoded(w))
    spec = sum(1 for w in words if D.alu_decoded_spec(w))
    return dec, spec


def slug(name):
    s = "".join(c.lower() if c.isalnum() else "_" for c in name)
    while "__" in s:
        s = s.replace("__", "_")
    return s.strip("_")


def structural_records():
    """op3 records that are NOT per-effect bodies (load != 0x6E): the shared kernel(s),
    the 0x0000 header, and the 0x006A alternates.  Returns list of (load, addr, words)."""
    out = []
    for o in X.POOL.tile():
        if o["kind"] != "STREAM":
            continue
        for (addr, op, ln) in o["recs"]:
            if op != 3:
                continue
            body = X.POOL.D[addr + 2 - X.POOL.BASE: addr + ln - X.POOL.BASE]
            if len(body) < 3:
                continue
            load = (body[1] << 8) | body[2]
            if (load & 0xFF) == 0x6E:
                continue
            data = body[3:]
            words = [int.from_bytes(data[k:k + 5], "big") for k in range(0, len(data) - 4, 5)]
            out.append((load & 0xFF, addr, words))
    return out


def runtime_words():
    p = os.path.join(HERE, "runtime-resident-iram-words.txt")
    try:
        return {int(x, 16) for x in open(p) if x.strip() and not x.startswith("#")}
    except OSError:
        return set()


def emit_kernel(load, addr, words, rt_overlap, rt_total):
    L = list(PROVENANCE)
    L.append("; SX-WSA1R effects-DSP -- SHARED KERNEL (I-RAM load 0x%02X)" % load)
    L.append("; pool record @0x%06X  |  %d words  |  %d/%d of the runtime-resident words"
             % (addr, len(words), rt_overlap, rt_total))
    if rt_overlap == rt_total and rt_total:
        L.append("; ★ THIS IS THE PROGRAM THAT ACTUALLY EXECUTES AT RUNTIME.  Measured on the")
        L.append(";   emulated WSA1R (dsp/analysis/dsp_bus_program_scan.py): the ONLY DSP program")
        L.append(";   uploaded in SOUND play is this kernel, at boot, to IC30.  The 48 per-effect")
        L.append(";   bodies (disasm/eff*.dsm, I-RAM 0x6E) are NOT uploaded during normal play;")
        L.append(";   effect changes stream only C-RAM coefficients onto this resident kernel.")
    L.append(";")
    L.append("; GENERATED by wsa1/dsp/analysis/gen_wsa1_dsp_disasm.py -- DO NOT EDIT.")
    L.append(";")
    curs = D.cursor_addresses(words) if hasattr(D, "cursor_addresses") else []
    for i, w in enumerate(words):
        L.append("  w%-3d %010X  %s" % (i, w, D.text(w, load + i)))
        ca = curs[i] if i < len(curs) else None
        if ca is not None:
            L.append("        ; C-RAM[0x%02X] (coefficient cursor)" % (ca & 0xFF))
    return "\n".join(L) + "\n"


def emit_listing(e, kn):
    load, words = e["body"]
    load &= 0xFF
    fam = family_of(e["name"])
    dec, spec = spec_decoded(words)
    ca = classA_count(words)
    curs = D.cursor_addresses(words) if hasattr(D, "cursor_addresses") else []
    L = list(PROVENANCE)
    L.append("; SX-WSA1R effects-DSP program -- %s" % e["name"])
    L.append("; PoolDir record %d  |  effect program %d  |  %d slot(s)  |  I-RAM load 0x%02X"
             % (e["rec"], e["prog"], len(e["slots"]), load))
    L.append("; family %s  |  %d words  |  %d class-A multiplies  |  decode %d strict / %d speculative"
             % (fam, len(words), ca, dec, spec))
    L.append("; algorithm topology: %s" % TOPOLOGY.get(fam, TOPOLOGY["other"]))
    if e["name"] in kn:
        kfam, kconf, krole = kn[e["name"]]
        L.append("; KN5000 cross-reference (SAME effect name, same uPD6383GF ISA):")
        L.append(";   KN5000 %s [%s, confidence %s]: %s" % (e["name"], kfam, kconf, krole))
    L.append(";")
    L.append("; GENERATED by wsa1/dsp/analysis/gen_wsa1_dsp_disasm.py -- DO NOT EDIT.")
    L.append("; Per-word text (mnemonic + field breakdown + measured/SPECULATIVE readings)")
    L.append("; is the shared uPD6383 ISA model dsp/tools/dsp_disasm.py; a reading marked")
    L.append("; SPECULATIVE is a graded prospective hypothesis, not measured.")
    L.append(";")
    for i, w in enumerate(words):
        L.append("  w%-3d %010X  %s" % (i, w, D.text(w, load + i)))
        ca_addr = curs[i] if i < len(curs) else None
        if ca_addr is not None:
            L.append("        ; C-RAM[0x%02X] (coefficient cursor)" % (ca_addr & 0xFF))
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--table", action="store_true")
    ap.add_argument("--out", default=os.path.join(HERE, "..", "disasm"))
    a = ap.parse_args()
    progs = build()
    kn = kn5000_roles()

    if a.table:
        print("WSA1R effects-DSP program manifest (%d distinct records)\n" % len(progs))
        print("rec prog name                 slots  op3?  words  classA  dec/spec")
        for e in progs:
            if e["body"]:
                _, words = e["body"]
                dec, spec = spec_decoded(words)
                print("%3d %4d %-20s %5d  yes  %4d   %4d   %d/%d"
                      % (e["rec"], e["prog"], e["name"][:20], len(e["slots"]),
                         len(words), classA_count(words), dec, spec))
            else:
                print("%3d %4d %-20s %5d  no    --     --     --"
                      % (e["rec"], e["prog"], e["name"][:20], len(e["slots"])))
        return 0

    out = os.path.abspath(a.out)
    os.makedirs(out, exist_ok=True)
    idx = ["; SX-WSA1R effects-DSP -- program index (GENERATED, DO NOT EDIT)",
           "; NEC uPD6383GF x3 (IC5/IC6/IC30).  Each effect's I-RAM program body is",
           "; PoolDir_Records field +12; +0/+4/+8 are its coefficient streams.",
           ";",
           "; rec  effect                 slots words classA dec/spec  family        listing"]
    tsv = ["# SX-WSA1R effects-DSP distinct-program manifest -- GENERATED by "
           "wsa1/dsp/analysis/gen_wsa1_dsp_disasm.py",
           "# rec\teffect_name\tprog\tslots\twords\tclassA\tstrict\tspec\tfamily\tlisting\tkn5000_shared"]
    written = nobody = 0
    for e in progs:
        if not e["body"]:
            idx.append("; %3d  %-20s %5d   (no distinct op3 body: coefficient-only / shared)"
                       % (e["rec"], e["name"][:20], len(e["slots"])))
            tsv.append("%d\t%s\t%d\t%d\t0\t0\t0\t0\t%s\t-\t%s"
                       % (e["rec"], e["name"], e["prog"], len(e["slots"]),
                          family_of(e["name"]), "yes" if e["name"] in kn else "no"))
            nobody += 1
            continue
        _, words = e["body"]
        dec, spec = spec_decoded(words)
        fn = "eff%02d_%s.dsm" % (e["rec"], slug(e["name"]))
        open(os.path.join(out, fn), "w").write(emit_listing(e, kn))
        idx.append("; %3d  %-20s %5d %5d  %5d  %d/%-4d  %-12s  %s"
                   % (e["rec"], e["name"][:20], len(e["slots"]), len(words),
                      classA_count(words), dec, spec, family_of(e["name"]), fn))
        tsv.append("%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s"
                   % (e["rec"], e["name"], e["prog"], len(e["slots"]), len(words),
                      classA_count(words), dec, spec, family_of(e["name"]), fn,
                      "yes" if e["name"] in kn else "no"))
        written += 1
    # the shared kernel(s) -- the programs that actually execute at runtime.
    rt = runtime_words()
    struct = structural_records()
    # pick, per load address, the record with the most runtime-word overlap.
    best = {}
    for load, addr, words in struct:
        ov = len(set(words) & rt)
        if load not in best or ov > best[load][0]:
            best[load] = (ov, addr, words)
    idx.append(";")
    idx.append("; SHARED KERNEL / structural records (NOT per-effect bodies):")
    for load in sorted(best):
        ov, addr, words = best[load]
        tag = "  <- THE RUNTIME KERNEL (all resident words)" if ov == len(rt) and rt else ""
        idx.append("; load 0x%02X  @0x%06X  %d words  %d/%d runtime%s"
                   % (load, addr, len(words), ov, len(rt), tag))
        if load == 0x30 and ov == len(rt) and rt:
            open(os.path.join(out, "kernel.dsm"), "w").write(
                emit_kernel(load, addr, words, ov, len(rt)))
    open(os.path.join(out, "index.dsm"), "w").write("\n".join(idx) + "\n")
    open(os.path.join(os.path.dirname(out), "programs.tsv"), "w").write("\n".join(tsv) + "\n")
    print("wrote %d .dsm listings (+%d coefficient-only records) + kernel.dsm to %s"
          % (written, nobody, out))
    print("wrote index.dsm and ../programs.tsv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
