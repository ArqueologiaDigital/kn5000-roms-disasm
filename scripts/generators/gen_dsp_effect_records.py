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


# ---------------------------------------------------------------------------
# 0xEE6048-0xEE63B9: the tail of the parameter-range pointer table, the
# settings-block pointer table and seven small DSPCfg arrays.
# ---------------------------------------------------------------------------
SET_TAB = 0xEE61D4        # 100 x u32 -> 24-byte settings block per effect
TAB_LO, TAB_HI = 0xEE6048, 0xEE63BA


def nm_symbols(v="v10"):
    import subprocess
    nm = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)
    out = subprocess.run([nm, "--defined-only", elf], capture_output=True, text=True,
                         check=True).stdout
    by = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not (TAB_LO <= int(p[0], 16) < TAB_HI):
            by.setdefault(int(p[0], 16), []).append(p[2])
    for a in by:
        by[a].sort(key=lambda n: ("_0x" in n, len(n)))
    return by


def u16(d, a):
    return struct.unpack_from("<H", d, a - B)[0]


def probe_tables(d):
    """Assertions behind the part-2 header."""
    tabB = [u32(d, SET_TAB + 4 * i) for i in range(N)]
    rec = [u32(d, REC_TAB + 4 * i) for i in range(N)]
    for fx in range(N):
        if rec[fx]:
            assert d[tabB[fx] - B] == fx, ("settings block does not start with its effect", fx)
    assert d[0xEE636C - B:0xEE6372 - B] == b"acefd\xff"
    return sum(1 for r in rec if r)


def emit_tables(d):
    syms = nm_symbols("v10")
    names = effect_names(d)
    ndef = probe_tables(d)
    L = []
    w = L.append
    w("; =============================================================================")
    w("; DSP EFFECT TABLES, indexed by DSP effect number 0..99 (names from")
    w("; DspEffectName_PtrTable 0xE32A7A), and seven small DSPCfg arrays")
    w("; =============================================================================")
    w("; Parameter-range pointer table, base 0xEE6044 (= ToneKit_ParamBlock_116_0x7C:")
    w("; entry 0 is the last 4 bytes of the ToneKit C blob, so the label below is")
    w("; ENTRY 1).  Entry n -> the effect's {min,max,param_id} u16 x3 records, one per")
    w("; parameter; DSPCfg_LookupAndExtract (0xFDC41D) indexes it `sll xbc,2` from")
    w("; ToneKit_ParamBlock_116_0x7C and steps records with `mul wa,6`.  The")
    w("; parameter count is the byte table at 0xEE5FE0 (DSPCfg_GetSlotCount).")
    w("; ToneKit_VoiceDispatch_Table keeps its name: shared/positional_labels.s")
    w("; derives the DSPCfg arrays below from it (+0x18C .. +0x348).")
    w("; -----------------------------------------------------------------------------")
    w("ToneKit_VoiceDispatch_Table:")
    for fx in range(1, N):
        t = u32(d, RANGE_TAB + 4 * fx)
        w("\t.long %s\t; %d %s" % (syms[t][0], fx, names[fx]))
    w("")
    w("; -----------------------------------------------------------------------------")
    w("; DspFxSettingsPtrTable -- 100 x u32: effect n -> its 24-byte settings block")
    w("; (the ToneKit_* C blocks it points at).  Readers: DSPCfg_ResolveWithFallback")
    w("; (0xFDC710) and DSPCfg_WriteAllSlots_Direct (0xFDCB40) load entry n as")
    w("; `ToneKit_VoiceDispatch_Table_0x18C + 4*n`, then DSPCfg_ReadViaTableLookup")
    w("; (0xFDC364) reads block+0 with DSPCfg_GetParamCount (0xFDC35F, `ld l,(xwa)`)")
    w("; and uses it to index DspFxRecListPtrTable, and hands block+1 plus that")
    w("; record list to DSPCfg_ReadMultiField (0xFDC2E8).  So +0 is the EFFECT")
    w("; NUMBER -- true for all %d effects that have a record list (gen_dsp_effect" % ndef)
    w("; _records.py) -- and +1.. are the parameter bytes, laid out by the effect's")
    w("; record list ('p'/'v' records pack bitfields).  Effects without a list point")
    w("; at ToneKit_DefaultParams.")
    w("; -----------------------------------------------------------------------------")
    w("DspFxSettingsPtrTable:")
    for fx in range(N):
        t = u32(d, SET_TAB + 4 * fx)
        w("\t.long %s\t; %d %s" % (syms[t][0], fx, names[fx]))
    w("")
    w("; -----------------------------------------------------------------------------")
    w("; Seven small arrays read by audio/dsp_config_sysex.s through positional")
    w("; names (ToneKit_VoiceDispatch_Table_0x31C .. _0x348).")
    w("; -----------------------------------------------------------------------------")
    w("; byte[n], read by DSPCfg_Data_001 (0xFDC448: `add xbc,xwa / ld l,(xbc)`).  No")
    w("; call of DSPCfg_Data_001 was found (call/calr/jp/jr target scan of the v10")
    w("; ELF disassembly), so the index range and purpose are not established.")
    w("DspCfg_Data001_ByteTable:\t.byte 0, 0, 0, 0")
    w("; byte[n], read by DSPCfg_Data_002 (0xFDC464), same shape; no caller found")
    w("; by the same scan; purpose not established.")
    w("DspCfg_Data002_ByteTable:\t.byte 1, 1, 1, 1")
    w("; DSP block index 0..5 -> object code.  DSPCfg_LookupMidiMap (0xFDBFC6) passes")
    w("; byte[block] to VoiceData_LookupPtrByIndex; DSPCfg_ResolveParamToSlot_Range49..4E")
    w("; call it with the block of the 0x49xx..0x4Exx parameter id; and")
    w("; DSPCfg_WriteParamFull / DSPCfg_WriteAllSlots_Direct post byte[block] as the")
    w("; SwbtWr event code through AssswbWr.  The SwbtWr bank-2 lists of exactly")
    w("; these five codes (0x61, 0x63, 0x64, 0x65, 0x66) contain EffEdit_DSPConfigBlock;")
    w("; code 0x62's list does not.  The values happen to be ASCII 'a','c','e','f','d';")
    w("; they are codes, not text.  0xFF = no object.")
    w("DspBlock_ObjectCode_Table:\t.byte 0x61, 0x63, 0x65, 0x66, 0x64, 0xff")
    w("; parameter id 0x4900+i (i = 0..7) -> signed byte, stored through the caller's")
    w("; pointer by DSPCfg_DecodeParamIdRange (0xFDC504: `sub xwa,0x4900`, `cp xwa,7`,")
    w("; `add xwa,<this>`, `ld c,(xwa) / exts bc`).")
    w("DspParamId4900_ByteMap:\t.byte 0, 2, 6, 3, 8, 5, 9, 7")
    w("; u16[i], read by DSPCfg_ResolveWithFallback (0xFDC710) as `add xwa,xwa` index")
    w("; then `sll bc,8`; purpose of the resulting value not established.")
    w("DspCfg_ResolveFallback_WordTable:\t.short 0, 2, 4, 5, 3")
    w("; switch table: u16 offset per op letter 'a'..'f' (`sub wa,97`, `cp wa,5`),")
    w("; jumped to as 0xFDCCD3 + offset by the code after DSPCfg_Data_ParamDispatch")
    w("; (`jp_rr 8, xix, wa`).  The targets have no labels yet, so the offsets stay")
    w("; numeric: 0xFDCCD3, 0xFDCCDC, 0xFDCCE3, 0xFDCCEC, 0xFDCCF5, 0xFDCCFE (v10).")
    w("DspCfg_OpLetter_JumpOffsets:\t.short %s" % ", ".join(
        str(u16(d, 0xEE6384 + 2 * i)) for i in range(6)))
    w("; switch table: u16 offset from AssSwb_SwapEntriesAndDispatch, 21 entries,")
    w("; used by DspConfig_EventDispatch (0xFDD29D: index = type-1 for 0..8, or")
    w("; type-1-0x12 for 9..20; `add bc,bc`, `ldw_sri`, `jp_ind`).  Offset 0 is the")
    w("; default (AssSwb_SwapEntriesAndDispatch itself); the other targets have no")
    w("; labels yet.")
    offs = [u16(d, 0xEE6390 + 2 * i) for i in range(21)]
    for i in range(0, 21, 7):
        chunk = offs[i:i + 7]
        lab = "DspConfig_EventDispatch_JumpOffsets:" if i == 0 else ""
        w("%s\t.short %s" % (lab, ", ".join(str(o) for o in chunk)))
    return "\n".join(L) + "\n"


def apply_tables(path):
    raw = open(path, "rb").read()
    lines = raw.split(b"\n")
    s = next(i for i, l in enumerate(lines) if l == b"ToneKit_VoiceDispatch_Table:")
    e = next(i for i, l in enumerate(lines)
             if l.startswith(b"; DSP EFFECT PARAMETER-WRITE RECORDS")) - 1
    assert lines[e].startswith(b"; ====="), lines[e]
    for l in lines[s:e]:
        assert b";" not in l, ("comment inside replaced block", l)
    new = emit_tables(rom("v10")).encode("latin-1").rstrip(b"\n").split(b"\n")
    out = lines[:s] + new + lines[e:]
    open(path, "wb").write(b"\n".join(out))
    print("%s: replaced lines %d..%d (%d lines) with %d lines" % (path, s + 1, e, e - s, len(new)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--apply", nargs="+")
    ap.add_argument("--emit-tables", action="store_true")
    ap.add_argument("--apply-tables", nargs="+")
    a = ap.parse_args()
    if a.emit_tables:
        sys.stdout.write(emit_tables(rom("v10")))
        return 0
    if a.apply_tables:
        for p in a.apply_tables:
            apply_tables(p)
        return 0
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
