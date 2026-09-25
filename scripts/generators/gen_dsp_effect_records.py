#!/usr/bin/env python3
r"""DSP EFFECT PARAMETER-WRITE RECORDS (maincpu 0xEE63BA-0xEE7786): prove, emit, apply.

QUESTION ANSWERED
-----------------
What are the bytes the tree used to call `WidgetParam_Config_000..058` plus the
seven "dispatch tables" after them (`PerfMode_SetupDispatch_Table` ..
`Naka_DisplayMode_Table`)?  They were half decoded as instructions (`nop / reti
/ jr lt,0 ...`).  They are ONE 100-entry pointer table indexed by the DSP
EFFECT NUMBER, and 59 variable-length record lists it points at -- one record
per effect parameter, describing how that parameter is written to the DSP.

THE READERS (all in audio/dsp_config_sysex.s, v10 addresses)
  DSPCfg_ValidateSlotForWrite 0xFDC883  `cp wa,0x63 / jr ugt` then
      `ld xhl,<0xEE75F6>; add xhl,idx*4; ld xde,(xhl); or xde,xde; jr z,invalid`
      -> 100 entries (effect 0..99), a NULL entry = effect has no list.
  DSPCfg_FindSlot63           0xFDC472  count = DSPCfg_GetSlotCount(effect)
      (byte table 0xEE5FE0), list = (0xEE75F6 + 4*effect), then walks `count`
      records testing `cp (xwa+2),0x63` -> +2 is the record's op letter.
  DSPCfg_PackAddress          0xFDC14A  next = rec + ((rec[0]<<8)|rec[1]),
      unless rec[0]==0xF0 -> +0 is a BIG-ENDIAN u16 total length, 0xF0 ends
      the list.
  DSPCfg_WriteParam           0xFDC013  reads op `(xde+2)` and special-cases
      'v' (0x76), 'p' (0x70), 'g' (0x67), 'd' (0x64); DSPCfg_ExtractFieldSingle
      (0xFDBFFC) / DSPCfg_ExtractFieldPair (0xFDBFD5) read operand bytes +4/+5.

WHAT --probe MEASURES (each is an assertion; any failure exits non-zero)
  1. every non-NULL list walks with rec[len-1] == 0x7A ('z') on every record
     and ends on a 0xF0 byte;
  2. records per list == the count byte at 0xEE5FE0+effect (DSPCfg_GetSlotCount);
  3. the lists, their 0xF0 terminators and 0xFF even-alignment pads PARTITION
     0xEE63BA..0xEE75F6 exactly -- no byte unexplained, none claimed twice;
  4. the region 0xEE5FE0..0xEE7786 is byte-identical in v10, v9 and v7;
  5. concordance with the ToneKit range records (pointer table 0xEE6044, one
     6-byte {min,max,param_id} record per parameter, same count byte): prints,
     per op letter, the multiset of param_id>>8 it pairs with -- e.g. '!'
     pairs only with 0x03 (REV SEND in DspParamName_Table), 'c' with
     0x01/0x02 (the two VOLUME names) in 54 of its 59 records.
  6. effect names from DspEffectName_PtrTable (0xE32A7A) for each list.

RUN
    python3 scripts/generators/gen_dsp_effect_records.py --probe
    python3 scripts/generators/gen_dsp_effect_records.py --emit > out.s
    python3 scripts/generators/gen_dsp_effect_records.py --apply v10/maincpu/ui_widgets/widget_dispatch.s
      (replaces the lines from `WidgetParam_Config_000:` through the
       `.long WidgetParam_Config_046` entry under `Naka_DisplayMode_Table:`;
       latin-1 byte-exact I/O.  Then `make gate`.)

The emitted text is identical for v10/v9/v7 (probe 4), so one generator serves
all three trees.
"""
import argparse
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = 0xE00000
COUNT_TAB = 0xEE5FE0      # 100 x u8   records per effect (DSPCfg_GetSlotCount)
RANGE_TAB = 0xEE6044      # 100 x u32  -> {min,max,param_id} x count (ToneKit blocks)
REC_TAB = 0xEE75F6        # 100 x u32  -> record list (this file)
SPAN_LO, SPAN_HI = 0xEE63BA, 0xEE75F6
NAME_PTRS = 0xE32A7A      # DspEffectName_PtrTable, 128 x u32
N = 100

# Labels other files still reference by name (shared/positional_labels.s):
#   .set WidgetParam_Config_058_0x36, WidgetParam_Config_058 + 54
#   .set Naka_DisplayMode_Table_0x10, Naka_DisplayMode_Table + 16
KEEP_LABEL = {0xEE75C0: "WidgetParam_Config_058"}


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def effect_names(d):
    out = []
    for i in range(N):
        p = u32(d, NAME_PTRS + 4 * i)
        s = d[p - B:p - B + 16].decode("latin-1").strip()
        out.append(s)
    return out


def camel(name):
    keep = []
    for w in name.replace("+", " ").replace(".", " ").replace("_", " ").split():
        keep.append(w[:1].upper() + w[1:].lower())
    return "".join(keep)


def walk(d):
    cnt = d[COUNT_TAB - B:COUNT_TAB - B + N]
    lists = _walk(d, cnt)
    STRIDES.clear()
    STRIDES.update(letter_strides(lists))
    return cnt, [u32(d, REC_TAB + 4 * i) for i in range(N)], lists


def _walk(d, cnt):
    tab = [u32(d, REC_TAB + 4 * i) for i in range(N)]
    lists = {}
    for fx, p in enumerate(tab):
        if not p:
            continue
        a, recs = p, []
        while d[a - B] != 0xF0:
            ln = (d[a - B] << 8) | d[a - B + 1]
            assert 4 <= ln < 0x100, ("bad length", fx, hex(a), ln)
            assert d[a - B + ln - 1] == 0x7A, ("record not 'z'-terminated", fx, hex(a))
            recs.append((a, d[a - B:a - B + ln]))
            a += ln
        assert len(recs) == cnt[fx], ("count mismatch", fx, len(recs), cnt[fx])
        lists[fx] = (p, recs, a)          # a = address of the 0xF0 terminator
    return lists


def partition(d, lists):
    owner = {}
    for fx, (p, recs, end) in lists.items():
        for a in range(p, end + 1):
            assert a not in owner, ("byte claimed twice", hex(a))
            owner[a] = fx
    pads = []
    for a in range(SPAN_LO, SPAN_HI):
        if a in owner:
            continue
        assert d[a - B] == 0xFF and (a + 1) % 2 == 0, ("unexplained byte", hex(a), hex(d[a - B]))
        pads.append(a)
    starts = sorted(p for p, _, _ in lists.values())
    assert starts[0] == SPAN_LO
    return pads


def probe():
    d = rom("v10")
    for v in ("v9", "v7"):
        o = rom(v)
        assert o[COUNT_TAB - B:0xEE7786 - B] == d[COUNT_TAB - B:0xEE7786 - B], v
    print("4. 0xEE5FE0..0xEE7786 byte-identical in v10, v9, v7")
    cnt, tab, lists = walk(d)
    print("1-2. %d non-NULL lists walk cleanly; record count == count byte for every one"
          % len(lists))
    pads = partition(d, lists)
    print("3. span 0x%06X..0x%06X partitioned: %d list bytes, %d 0xFF pad bytes"
          % (SPAN_LO, SPAN_HI, SPAN_HI - SPAN_LO - len(pads), len(pads)))
    names = effect_names(d)
    conc = {}
    for fx, (p, recs, end) in sorted(lists.items(), key=lambda t: t[1][0]):
        rng = u32(d, RANGE_TAB + 4 * fx)
        ids = [struct.unpack_from("<H", d, rng - B + 6 * k + 4)[0] >> 8 for k in range(len(recs))]
        ops = "".join(chr(r[2]) for _, r in recs)
        for (a, r), pid in zip(recs, ids):
            conc.setdefault(chr(r[2]), []).append(pid)
        print("   fx%02d %-17s @%06X %2d recs  ops=%-16s  param ids=%s"
              % (fx, names[fx], p, len(recs), ops, " ".join("%02x" % i for i in ids)))
    strides = {}
    for fx, (p, recs, end) in lists.items():
        for a, r in recs:
            subs = split_body(r)
            strides.setdefault(chr(r[2]), set()).add((len(subs[0]), len(subs)))
    print("7. every record body = n equal sub-entries headed by the op letter;"
          " (sub-entry bytes, n) per letter:")
    print("   " + "  ".join("%r:%s" % (k, sorted(v)) for k, v in sorted(strides.items())))
    print("5. op letter -> param_id>>8 it pairs with (count):")
    for op in sorted(conc):
        hist = {}
        for i in conc[op]:
            hist[i] = hist.get(i, 0) + 1
        print("   %r: %s" % (op, ", ".join("%02x x%d" % kv for kv in sorted(hist.items()))))
    return 0


def _stride_ok(body, op, st):
    return len(body) % st == 0 and all(body[i] == op for i in range(0, len(body), st))


def letter_strides(lists):
    """Per op letter, the smallest stride valid for EVERY record of that letter
    (a per-record choice would split 0x66 'f' records at coefficient bytes
    0x266666 that happen to hold 0x66).  None when no common stride exists
    ('v' has 3-byte single and 4-byte repeated forms)."""
    bodies = {}
    for fx, (p, recs, end) in lists.items():
        for a, r in recs:
            bodies.setdefault(r[2], []).append(r[2:-1])
    out = {}
    for op, bl in bodies.items():
        out[op] = next((st for st in range(2, max(map(len, bl)) + 1)
                        if all(_stride_ok(b, op, st) for b in bl)), None)
    return out


STRIDES = {}


def split_body(r):
    """Split a record body into sub-entries headed by the op letter."""
    body, op = r[2:-1], r[2]
    st = STRIDES.get(op)
    if st is None or not _stride_ok(body, op, st):
        st = next(s for s in range(2, len(body) + 1) if _stride_ok(body, op, s))
    return [body[i:i + st] for i in range(0, len(body), st)]


def fmt_rec(r):
    """One line per sub-entry; the u16 length leads the first, 'z' ends the last."""
    subs = split_body(r)
    out = []
    for k, sub in enumerate(subs):
        parts = ["'%s'" % chr(sub[0])] + ["0x%02x" % b for b in sub[1:]]
        if k == len(subs) - 1:
            parts.append("'z'")
        head = "0x%02x, %d,\t" % (r[0], r[1]) if k == 0 else "\t\t"
        out.append("\t.byte " + head + ", ".join(parts) if k == 0 else "\t.byte\t\t" + ", ".join(parts))
    return "\n".join(out)


def label_for(fx, names, addr):
    if addr in KEEP_LABEL:
        return KEEP_LABEL[addr]
    return "DspFxRecs_%02d_%s" % (fx, camel(names[fx]))


def emit(d):
    cnt, tab, lists = walk(d)
    pads = set(partition(d, lists))
    names = effect_names(d)
    L = []
    w = L.append
    w("; =============================================================================")
    w("; DSP EFFECT PARAMETER-WRITE RECORDS  (0xEE63BA-0xEE75F5, 59 lists, 4668 bytes)")
    w("; =============================================================================")
    w("; One list per DSP EFFECT NUMBER (the index of DspEffectName_PtrTable, 0xE32A7A;")
    w("; names below come from that table).  Record k of a list describes how")
    w("; parameter k of the effect is written to the DSP; the same effect number")
    w("; indexes three parallel 100-entry tables:")
    w(";   0xEE5FE0  u8 x100   parameter count  (DSPCfg_GetSlotCount 0xFDC456)")
    w(";   0xEE6044  u32 x100  -> {min,max,param_id} u16 x3 per parameter")
    w(";                        (DSPCfg_LookupAndExtract 0xFDC41D, `mul wa,6`)")
    w(";   0xEE75F6  u32 x100  -> the record list below (DspFxRecListPtrTable)")
    w(";")
    w("; Record layout, from the readers in audio/dsp_config_sysex.s:")
    w(";   +0  u16 BIG-endian total length, header and terminator included")
    w(";       (DSPCfg_PackAddress 0xFDC14A: next = rec + (rec[0]<<8 | rec[1]))")
    w(";   +2  op letter            (DSPCfg_FindSlot63 0xFDC472 `cp (xwa+2),0x63`;")
    w(";                             DSPCfg_WriteParam 0xFDC013 special-cases")
    w(";                             'v' 'p' 'g' 'd')")
    w(";   +3  op operands          (DSPCfg_ExtractFieldSingle 0xFDBFFC reads +4,")
    w(";                             DSPCfg_ExtractFieldPair 0xFDBFD5 reads +4/+5)")
    w(";       The body +2..len-2 is 1..8 equal-sized sub-entries, EACH headed by")
    w(";       the same op letter (measured; one line per sub-entry below).")
    w(";   +len-1  0x7A 'z'         terminator")
    w("; A list ends with one 0xF0 byte (DSPCfg_PackAddress stops on rec[0]==0xF0)")
    w("; and is padded with 0xFF to an even address.")
    w(";")
    w("; Pinned by scripts/generators/gen_dsp_effect_records.py --probe: every list")
    w("; walks with 'z' on every record, its record count equals the count byte,")
    w("; and lists + terminators + pads partition this span with no byte left over.")
    w("; [INFERENCE] The op letter names the kind of DSP write, not the parameter:")
    w("; paired with the range records, '!' falls on param id 0x03 in 38 of 38")
    w("; records and 'c' on 0x01/0x02 in 54 of 59 -- DspParamName_Table's REV SEND")
    w("; and VOLUME names (the probe prints the full letter/id concordance; ids")
    w("; read as DspParamName_Table indexes is the inference).  Effects that share an")
    w("; algorithm share a letter string: ROCK ROTARY (15) and ROTARY SPEAKER (53)")
    w("; are both 'abfjjiifjjiicf!t', the 12 reverbs 16-27 are all 'ugvfc'.")
    w("; The operand bytes include 24-bit big-endian coefficients (e.g. 0x266666,")
    w("; 0x400000); their DSP-side meaning is not established here.")
    w("; Byte-identical in v7, v9 and v10.")
    w("; =============================================================================")
    order = sorted(lists.items(), key=lambda t: t[1][0])
    for fx, (p, recs, end) in order:
        lab = label_for(fx, names, p)
        w("; effect %d %s: %d parameters" % (fx, names[fx], len(recs)))
        if lab in KEEP_LABEL.values():
            w("; (label name kept: shared/positional_labels.s derives")
            w(";  WidgetParam_Config_058_0x36 = DspFxRecListPtrTable from it)")
        w("%s:" % lab)
        for a, r in recs:
            w(fmt_rec(r))
        tail = ["0xf0"]
        a = end + 1
        while a in pads:
            tail.append("0xff")
            a += 1
        w("\t.byte " + ", ".join(tail) + "\t; end of list" + (", even-address pad" if len(tail) > 1 else ""))
    # --- the pointer table
    w("")
    w("; -----------------------------------------------------------------------------")
    w("; DspFxRecListPtrTable -- 100 x u32, indexed by DSP effect number 0..99.")
    w("; Readers: DSPCfg_ValidateSlotForWrite (0xFDC883) bounds the index with")
    w("; `cp wa,0x63 / jr ugt` and treats a 0 entry as \"no such effect\";")
    w("; DSPCfg_FindSlot63 (0xFDC472) and six further DSPCfg_* routines load it as")
    w("; `ld xbc,WidgetParam_Config_058_0x36` (the positional name of this address).")
    w("; The tree used to split it into eight invented tables (PerfMode_Setup..,")
    w("; VoiceEdit_Param.., AccompStyle_Config.., RhythmKit_Select..,")
    w("; ChordMode_Config.., RecordMode_Setup.., ControlPanel_Button..,")
    w("; Naka_DisplayMode_Table); the entry offsets show it is one table.")
    w("; -----------------------------------------------------------------------------")
    w("DspFxRecListPtrTable:")
    for fx in range(N):
        p = tab[fx]
        if fx == 96:
            w("; Naka_DisplayMode_Table is kept only because shared/positional_labels.s")
            w("; defines Naka_DisplayMode_Table_0x10 (= the SwbtWr bank-1 table that")
            w("; follows) relative to it; it is entry 96 of this table, not a table.")
            w("Naka_DisplayMode_Table:")
        if p:
            w("\t.long %s\t; %d %s" % (label_for(fx, names, p), fx, names[fx]))
        else:
            w("\t.long 0\t\t\t\t; %d %s" % (fx, names[fx]))
    return "\n".join(L) + "\n"


def apply(path):
    raw = open(path, "rb").read()
    lines = raw.split(b"\n")
    s = next(i for i, l in enumerate(lines) if l == b"WidgetParam_Config_000:")
    nd = next(i for i, l in enumerate(lines) if l == b"Naka_DisplayMode_Table:")
    e = nd + 4
    assert lines[e].strip() == b".long WidgetParam_Config_046", lines[e]
    # every line in the replaced block must be code/data/label/blank -- no comments
    for l in lines[s:e + 1]:
        assert b";" not in l, ("comment inside replaced block", l)
    new = emit(rom("v10")).encode("latin-1").rstrip(b"\n").split(b"\n")
    out = lines[:s] + new + lines[e + 1:]
    open(path, "wb").write(b"\n".join(out))
    print("%s: replaced lines %d..%d (%d lines) with %d lines" % (path, s + 1, e + 1, e - s + 1, len(new)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.probe:
        return probe()
    if a.emit:
        sys.stdout.write(emit(rom("v10")))
        return 0
    if a.apply:
        for p in a.apply:
            apply(p)
        return 0
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
