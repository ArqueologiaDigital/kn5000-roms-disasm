#!/usr/bin/env python3
"""convert_v10audio_code_runs.py -- convert the hand-adjudicated code runs of the
v10 maincpu audio engine from `.byte` to instructions, leaving as `.byte` only
what tlcs900_backend still cannot spell.

QUESTION ANSWERED
  v10audio_byte_triage.py's CODE bucket is a statistical verdict; this script
  applies the SIX runs in this lane's files that were additionally read by hand,
  in context, end to end -- each one flows from established code before it and
  terminates on `ret`.  Each is listed below with the reading that justified it.

  ⚠ EVERY ONE OF THESE IS A PARTIAL CONVERSION EXCEPT 0xFDB289.  The blockers
  are missing backend encodings (`or (nnnn),n`, `and (nnnn),n`, `res n,(XWA)`,
  `set n,(XWA)`, `cp (XWA),n`, `lda XHL,XHL+WA` -- see
  scripts/analysis/v10audio_blocked_forms.py), NOT the five blind leading bytes
  {01,04,17,1a,1c} that lane w10/missinginsns is adding.  Nothing here starts on
  a blind byte; runs that do are refused by the triage and left alone.

THE RUNS, AND WHY EACH IS CODE
  0xFDF61E  248 B  audioinit_routines.s, under the label
      `AudioInit_VoiceRoutingTable`, WHICH IS A MISNOMER AND IS REFERENCED BY
      NOTHING.  The bytes are one routine: seven `ret`, a run of
      `or (0xc2c2),0x7f` / `and (0xc2c3),0x01` pairs whose address operand steps
      by 1 from 0xc2c2 to 0xc2d5, then a loop
      `ld DE,0 ; cp DE,0x0020 ; ret NC ; ld WA,DE ; add WA,WA ;
       lda XBC,0xc2e2 ; extz XWA ; add XWA,XBC ; res 7,(XWA)`
      repeated over two arrays at 0xc2e2 and 0xc322, ending at its last byte on
      `ret` immediately before AudioInit_ConfigureVoiceRouting.  The same
      misnomer shape the census already documented for `FileIO_BytecodeData`.
      The label is NOT renamed here: semantic labeling is deferred, and the name
      is unreferenced, so a comment records the finding instead.
  0xFDB289   18 B  dsp_config_sysex.s -- three `push XIZ ; calr <near> ; pop XIZ ;
      ret` thunks.  FULLY spellable.
  0xFF1DD5   20 B  sprintf_core.s -- `ld XWA,(XSP+4) ; cp (XWA),0 ; jr NZ ;
      ld HL,1 ; ret ; cp (XWA+),0x30 ; jr Z ; ld HL,0 ; ret` -- an all-zeros /
      leading-'0' test on a string.
  0xFF28E9   32 B  sprintf_core.s -- a bounded copy loop over (XSP+0x0a) bytes.

REFUSED, and why (both were CODE-shaped to some test and are not code)
  0xFEA408   26 B  note_voice_mapping.s.  unidasm reads it as
      `max ; reti ; ld (0x00),0x0704 ; push 0x0400 ; ...`, but the bytes are
      0x00..0x0b small values in a repeating 3-4 byte shape and the whole
      neighbourhood from 0xFEA3F8 is `04 04 04 ... 04 07 00 00 04 07 0a 00`.
      It is a small-value table.  It is ALSO a run starting on 0x04, one of the
      five blind bytes -- so it is the counter-example that keeps the blind-byte
      statistic honest: enrichment is a per-IMAGE signal, never a per-run
      verdict.
  the 2,225 B of non-code-flanked `.byte` in audio_control_engine.s
      (VoiceMode_ParamConfigTables' 4-byte parameter records) -- genuine data.
  0xFC972C   26 B  and 0xFC977B 26 B, audio_control_engine.s.  ⚠ NOT refused on
      the evidence -- refused because ANOTHER LANE DELIBERATELY PUT THEM HERE.
      Both carry a comment from lane V10DAC's v10_data_as_code_census.py STRICT
      rule: "unreached CODE-territory, was disassembled as 9 plausible-but-dead
      instruction lines; per=67% dist=15".  This lane reads them the other way:
      decoding from 0xFC9772, which the tree ITSELF still spells as instructions
      (`dec 2,xsp ; ld (xsp),a ; ldb_d8 a,(0x9131)`), runs straight through both
      spans as `and A,(XSP) ; jr Z,<epilogue> ; ld A,(0x9127) ; extz WA ;
      calr 0xfc9df4 ; cp XHL,0xffffffff ; jr Z,<same epilogue> ; ...`, the two
      spans call the SAME routine 0xFC9DF4 from two sites, and every `jr Z`
      lands exactly on an `inc 2,XSP ; ret` epilogue.  Data does not do that,
      and the framing either side of the span is inconsistent with the span
      being data.  Reverting another lane's deliberate change unilaterally is
      out of bounds, so this is REPORTED, not applied.  22 of each 28 B are
      spellable if it is adjudicated back to code.

RUN
    python3 scripts/analysis/address_line_map.py --dump amap.json
    python3 scripts/converters/convert_v10audio_code_runs.py --amap amap.json
    python3 scripts/converters/convert_v10audio_code_runs.py --amap amap.json --apply

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
from convert_interrupted_region import build_replacement

BASE = 0xE00000
LABEL_RE = re.compile(r'^\s*[A-Za-z_.$][\w.$]*\s*:')
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')

# relpath under v10/maincpu/, address, size
RUNS = [
    ("audio/audioinit_routines.s",     0xFDF61E, 248),
    ("audio/dsp_config_sysex.s",       0xFDB289,  18),
    ("audio/sprintf_core.s",           0xFF1DD5,  20),
    ("audio/sprintf_core.s",           0xFF28E9,  32),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", nargs="*", default=None,
                    help="restrict to these run addresses (hex), e.g. --only 0xFDF61E")
    a = ap.parse_args()

    amap = json.load(open(a.amap))
    rom = (REPO / "original_ROMs" / "kn5000_v10_program.rom").read_bytes()

    sel = {int(x, 16) for x in a.only} if a.only else None
    per_file = {}
    for rel, addr, size in RUNS:
        if sel is not None and addr not in sel:
            continue
        per_file.setdefault(rel, []).append((addr, size))

    total_in = total_code = 0
    for rel, runs in per_file.items():
        src = "v10/maincpu/" + rel
        rows = sorted((e["addr"], e["line"]) for e in amap if e["src"] == src)
        first = {}
        for ad, ln in rows:
            first.setdefault(ln, ad)
        ordered = sorted(first.items(), key=lambda kv: (kv[1], kv[0]))
        path = REPO / "v10" / "maincpu" / rel
        lines = open(path, encoding="latin-1").read().split("\n")

        edits = []
        for addr, size in sorted(runs, reverse=True):
            l0 = next(ln for ln, ad in reversed(ordered) if ad <= addr)
            l1 = next(ln for ln, ad in reversed(ordered) if ad < addr + size)
            after = [ad for ln, ad in ordered if ad > first[l1] or (ad == first[l1] and ln > l1)]
            span_end = min(after) if after else None
            if first[l0] != addr or span_end != addr + size:
                sys.exit(f"{rel} 0x{addr:06X}: span is 0x{first[l0]:06X}..0x{span_end:06X}, "
                         f"not the requested run -- refusing")
            body = lines[l0 - 1:l1]
            for t in body:
                if LABEL_RE.match(t) or ";" in t:
                    sys.exit(f"{rel} 0x{addr:06X}: label or comment inside span: {t!r}")
                if not BYTE_RE.match(t):
                    # This already refuses `.ascii`/`.asciz`, which is the hard
                    # rule after a sibling lane re-framed 14 string literals --
                    # `"TEMPO   "` included -- into instructions, byte-exactly
                    # and invisibly to the gate.
                    sys.exit(f"{rel} 0x{addr:06X}: non-.byte line inside span: {t!r}")
            raw = list(rom[addr - BASE:addr - BASE + size])
            # ⚠ convert_code_bytes IS NOT RELIABLY DETERMINISTIC.  It shells out
            # to unidasm with timeout=10 and treats a timeout as "nothing
            # decoded", so under machine load the SAME input silently yields a
            # much worse conversion -- MEASURED 2026-09-02: 0xFDF61E gave 129 B
            # decoded on one run and 12 B on the next, 0xFDB289 gave 18 B then
            # 0 B.  It degrades safely (more `.byte`, never wrong bytes) but it
            # would quietly bank a bad result, so build it twice and require the
            # two to agree.
            new, remaining = build_replacement(raw, base_pc=addr)
            new2, remaining2 = build_replacement(raw, base_pc=addr)
            if new != new2:
                sys.exit(f"{rel} 0x{addr:06X}: build_replacement is not "
                         f"reproducing itself ({remaining} vs {remaining2} B left) "
                         f"-- rerun on an idle machine rather than banking this")
            total_in += size
            total_code += size - remaining
            print(f"{rel} 0x{addr:06X} {size:4d} B  lines {l0}..{l1} -> {len(new)} lines, "
                  f"{size - remaining} B decoded, {remaining} B still .byte")
            if not a.apply:
                for t in new[:6]:
                    print("      " + t)
                if len(new) > 6:
                    print(f"      ... ({len(new)-6} more)")
            edits.append((l0, l1, new))

        if a.apply:
            for l0, l1, new in sorted(edits, reverse=True):
                lines[l0 - 1:l1] = new
            open(path, "w", encoding="latin-1").write("\n".join(lines))
            print(f"  wrote {path}")

    print(f"\ntotal: {total_in} B addressed, {total_code} B converted to instructions, "
          f"{total_in - total_code} B still .byte (unspellable forms)")
    if not a.apply:
        print("(dry run; pass --apply)")


if __name__ == "__main__":
    main()
