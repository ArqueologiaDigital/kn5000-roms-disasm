#!/usr/bin/env python3
"""prom_c_p7stream_effect_names.py -- the DSP effect each record-held P7 stream belongs to, read from the ROMs.

QUESTION IT ANSWERS
  FINDINGS-prom_c-p7-is-dsp-effects.md established the chain:
    a P7 unit block's byte +0 is a DSP EFFECT NUMBER (program 0..127);
    PoolDir_RecordForUnitProgram (prom_c 0xFDC551, 128 bytes) turns it into a PoolDir_Records index;
    each of the 56 records (prom_c 0xFDBFD9, 25 bytes each) holds four stream pointers at +0 / +4 / +8 / +12;
    prom_b EffectNames_F147AC (0xF147AC, 128 x 16 ASCII) names effect k;
    fields +0 / +4 hold coefficient byte-code and +8 / +12 parameter values -- four streams are byte-identical
    to the KN5000's DSP_EffNN_Coef_Bytecode / DSP_EffNN_Param_Values for the same effect number.
  That note left the per-stream names unapplied.  This script derives them from ROM BYTES alone (not from
  the source's comments): every stream a record points at gets DspEffNN_<EffectName>_<Field>, with NN the
  effect number, <EffectName> prom_b's name in CamelCase, and <Field> CoefA / CoefB / ParamsA / ParamsB for
  +0 / +4 / +8 / +12.  A record reached from several programs (record 53: program 0 "NO OPERATION" and every
  program named "----------") takes its lowest program.  Each stream is held by exactly one record field
  (asserted); streams no record holds keep their address names.

RUN (from wsa1/)
  python3 notes/prom_c_p7stream_effect_names.py --list     # address, record, field, name
  python3 notes/prom_c_p7stream_effect_names.py --check    # every name is the label in prom_c/p7/p7_stream_pool.s
  python3 notes/prom_c_p7stream_effect_names.py --sed      # rename rules from the address spelling
"""
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_C = os.path.join(HERE, "original_ROMs", "wsa1_prom_c.ic28")
PROM_B = os.path.join(HERE, "original_ROMs", "wsa1_prom_b.ic13")
RECORDS, NREC, RECSZ = 0xFDBFD9, 56, 25
PROG2REC = 0xFDC551
EFFNAMES = 0xF147AC
FIELDS = ("CoefA", "CoefB", "ParamsA", "ParamsB")


def ident(s):
    words = re.findall(r'[A-Za-z0-9]+', s)
    return "".join(w[:1].upper() + w[1:].lower() for w in words)


def stream_names():
    c = open(PROM_C, "rb").read()
    b = open(PROM_B, "rb").read()
    prog2rec = c[PROG2REC - 0xF80000:PROG2REC - 0xF80000 + 128]
    eff = [b[EFFNAMES - 0xF00000 + 16 * k:EFFNAMES - 0xF00000 + 16 * k + 16].decode("latin-1").strip()
           for k in range(128)]
    out = {}
    for r in range(NREC):
        progs = [p for p, x in enumerate(prog2rec) if x == r]
        assert progs, "record %d is reached by no program" % r
        p = progs[0]
        o = RECORDS - 0xF80000 + RECSZ * r
        for k, a in enumerate(struct.unpack("<4I", c[o:o + 16])):
            assert 0xFCD0F7 <= a < 0xFDBFD9, (r, k, hex(a))      # inside the stream pool
            assert a not in out, "stream 0x%06X held twice" % a
            out[a] = dict(record=r, program=p, effect=eff[p], field=k * 4,
                          name="DspEff%02d_%s_%s" % (p, ident(eff[p]), FIELDS[k]))
    return out


def main():
    S = stream_names()
    if "--list" in sys.argv:
        for a, d in sorted(S.items()):
            print("0x%06X  record %2d  +%-2d  %s" % (a, d["record"], d["field"], d["name"]))
        print("%d streams named" % len(S))
    elif "--sed" in sys.argv:
        for a, d in sorted(S.items()):
            print("s/\\bP7Stream_%06X\\b/%s/g" % (a, d["name"]))
    elif "--check" in sys.argv:
        src = open(os.path.join(HERE, "prom_c", "p7", "p7_stream_pool.s"), "rb").read().decode("latin-1")
        bad = [d["name"] for d in S.values() if not re.search(r'^%s:' % re.escape(d["name"]), src, re.M)]
        print("%d of %d stream names are labels in p7_stream_pool.s" % (len(S) - len(bad), len(S)))
        sys.exit(1 if bad else 0)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
