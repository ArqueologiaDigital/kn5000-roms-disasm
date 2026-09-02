#!/usr/bin/env python3
"""v10dac2_convert91.py -- convert the address-resolved data-as-code spans.

QUESTION ANSWERED
  For each span that v10dac2_resolve91.py placed by ADDRESS and
  v10dac2_review91.py did not reject as reachable code, rewrite the
  instruction mnemonics back into typed .byte reproducing the exact ROM bytes,
  with an evidence comment.

RUN
    python3 scripts/converters/v10dac2_convert91.py

⚠ THIS WRITES. Rebuild kn5000_v10_program and cmp against original_ROMs/
  after every run -- it MUST stay byte-identical. A span that moves a byte is a
  regression to revert, not progress.

⚠ THE BYTE GATE CANNOT VALIDATE THIS WORK IN EITHER DIRECTION. It passes
  whether the bytes are spelled as instructions or as data, which is precisely
  why this category went unmeasured for so long. The evidence that a span is
  data is the reference pattern and the byte content -- never the gate, and
  never that the conversion assembled.

⚠ RESOLVING AN ADDRESS IS NOT LICENCE TO CONVERT. These 91 were refused by an
  earlier lane for lack of a unique location; supplying the location removes
  that obstacle and adds no evidence about what the bytes are.

PROVENANCE
  Lane V10DAC2, 2026-09-02; recovered from session scratch.
"""
import json, os, sys
sys.path.insert(0, '/home/fsanches/compartilhado/disasm-lanes/v10dac2/scripts/analysis')
import v10dac2_line_probe as lp

REPO = '/home/fsanches/compartilhado/disasm-lanes/v10dac2'
SRC = os.path.join(REPO, 'v10/maincpu')
ROM_PATH = os.path.join(REPO, 'original_ROMs/kn5000_v10_program.rom')
BASE = 0xE00000
MANIFEST_PATH = os.path.join(REPO, 'notes/v10-data-as-code/v10dac_conversion_manifest.json')

EXCLUDED_LOCS = set(l.strip() for l in open(
    '/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/excluded_locs.txt') if l.strip())

EXCLUDE_REASONS = {
    'KeyScaleNoteStr_G_0x18+37': (
        'manual read: surrounding lines (extension_data.s ~1575-1610) are riddled with stray '
        '.byte escapes interleaved with valid-looking instructions (0xa2,0xb8,0xbb,0x37,0xc6,'
        '0xd5 88 ...) -- the misframed-islands signature (DEBT-INVENTORY-2026-09-02.md), not a '
        'clean data-as-code region. Left for whichever lane owns that category.'),
    'DisplayMode_Handler_3_0x612+16': (
        'manual read: contains `call VoiceSlot_ReadCurrentParams` and `call VoiceSlot_FlagCheck`, '
        'both real named routines, in an otherwise coherent conditional-branch sequence -- real '
        'code, consistent with the sibling DisplayMode_Handler_3_0x399 already excluded as real '
        'code (register-indirect dispatch target).'),
    'DisplayMode_Handler_3_0x65A+15': (
        'manual read: identical content to DisplayMode_Handler_3_0x612+16 (same two named calls '
        'VoiceSlot_ReadCurrentParams / VoiceSlot_FlagCheck) -- real code.'),
    'SubCPU_ToneParamRet_0x9D1+57': (
        'manual read: `call OscScope_RenderBlock_0x3F` then `call OscScope_RenderBlock_0x50`, '
        'bookended by ret/ret -- two real named calls, real code.'),
    'Scoop_SoundEditorData_0xEB+1539': (
        'manual read: `call SeMenu_LoadPartParam` / `call SeMenu_SetupPartDisplay_End_0x219`, '
        'real named calls -- real code. Identical template repeats at 4 other offsets in this '
        'same file (+1699,+1859,+2042,+2225), all excluded for the same reason.'),
    'Scoop_SoundEditorData_0xEB+1699': ('manual read: same real-code template as +1539 (two named calls to '
        'SeMenu_LoadPartParam / SeMenu_SetupPartDisplay_End_0x219).'),
    'Scoop_SoundEditorData_0xEB+1859': ('manual read: same real-code template as +1539.'),
    'Scoop_SoundEditorData_0xEB+2042': ('manual read: same real-code template as +1539.'),
    'Scoop_SoundEditorData_0xEB+2225': ('manual read: same real-code template as +1539.'),
    'Flash_InitBytecodeBlock+141': (
        'manual read: surrounding lines (flash_floppy_handlers.s ~1596-1650) are riddled with '
        'stray .byte escapes interleaved with a real named call (`call AccPatch_InitFromSlotIndex`) '
        '-- the misframed-islands signature, not a clean data-as-code region.'),
    'FDemoText_ByteData_LayoutEngine+754': (
        'manual read: despite the "ByteData" name, the surrounding lines (fdemotext_routines.s '
        '~1824-2140) are riddled with stray .byte escapes interleaved with instructions (0xf3, '
        '0xda, 0x52, 0xf3/reti, 0x8e, 0x37, 0xf2, 0xe6) -- the misframed-islands signature, not a '
        'clean data-as-code region.'),
    'FDC_CMD_EXEC+141': (
        'manual read: `lda_d16 xwa,(0x8a4a) / decm 1,(xwa) / ld wa,(xwa) / cps wa,0 / jr z,18 / '
        'lda_d16 xwa,(0x8a48) / incm 1,(xwa) / ld wa,(xwa)` is a coherent, meaningful '
        'decrement-one-counter/increment-another idiom over two real fixed addresses, repeated '
        'verbatim at a second offset (+448) in the same file -- reads as a real, reused inline '
        'routine, not data. No named call, but the identical repeat of meaningful multi-operand '
        'logic outweighs that.'),
    'FDC_CMD_EXEC+448': ('manual read: byte-identical to FDC_CMD_EXEC+141, same real-code evidence.'),
    'SndParam_BatchUpdate_Data+189': (
        'manual read: `call SndParam_ComputeVoiceIndex`, a real named call -- real code.'),
}


def main():
    manifest = json.load(open(MANIFEST_PATH))
    exc = manifest['excluded']
    targets = [e for e in exc if 'matches (no unique context)' in e.get('reason', '')]
    remaining_exc = [e for e in exc if 'matches (no unique context)' not in e.get('reason', '')]

    by_addr = lp.load_cache()
    rom = open(ROM_PATH, 'rb').read()

    accepted = []
    rejected = []
    for e in targets:
        loc = e.get('loc')
        lo, hi = int(e['addr_lo'], 16), int(e['addr_hi'], 16)
        if loc in EXCLUDE_REASONS or loc is None:
            reason = EXCLUDE_REASONS.get(loc, (
                'manual read: `call CtrlPanel_SetIndicatorLED`, a real named call, in a coherent '
                'reset-bit/load/call/set-bit/ret sequence -- real code.'))
            e2 = dict(e)
            e2['reason'] = ('lane V10DAC2 address-probe locate succeeded (see '
                             'scripts/analysis/v10dac2_line_probe.py), but excluded on further '
                             'evidence: ' + reason)
            rejected.append(e2)
            continue
        rows = lp.lookup(by_addr, lo, hi)
        content_rows = [(f, l, a) for f, l, a in rows if a < hi]
        files = set(f for f, l, a in content_rows)
        assert content_rows and content_rows[0][2] == lo and len(files) == 1, (loc, lo, hi)
        relfile = content_rows[0][0]
        start_line = content_rows[0][1]
        end_line = content_rows[-1][1]
        accepted.append(dict(e=e, file=relfile, start_line=start_line, end_line=end_line,
                              lo=lo, hi=hi))

    print(f"{len(accepted)} accepted, {len(rejected)} rejected (of {len(targets)} target spans)")

    # Group by file, apply edits bottom-to-top so line numbers stay valid within a file.
    by_file = {}
    for a in accepted:
        by_file.setdefault(a['file'], []).append(a)

    converted_manifest_entries = []
    total_bytes = 0
    for relfile, spans in by_file.items():
        spans.sort(key=lambda a: a['start_line'], reverse=True)
        path = os.path.join(SRC, relfile)
        lines = open(path, encoding='latin-1').read().split('\n')
        for a in spans:
            e = a['e']
            lo, hi = a['lo'], a['hi']
            size = hi - lo
            total_bytes += size
            rom_bytes = rom[lo - BASE:hi - BASE]
            assert len(rom_bytes) == size
            nlines_orig = a['end_line'] - a['start_line'] + 1
            header = (f"\t; data-as-code (v10_data_as_code_census.py, STRICT rule): "
                      f"0x{lo:06X}-0x{hi:06X} ({size} B), unreached CODE-territory, was "
                      f"disassembled as {nlines_orig} plausible-but-dead instruction lines; "
                      f"per={e['per']}% dist={e['dist']}% near {e['loc']}"
                      .replace('%%', '%'))
            # per is already a percentage value stored as e.g. "100"; dist is a count, not a
            # percent -- match the exact style used by the existing converted-span headers.
            header = (f"\t; data-as-code (v10_data_as_code_census.py, STRICT rule): "
                      f"0x{lo:06X}-0x{hi:06X} ({size} B), unreached CODE-territory, was "
                      f"disassembled as {nlines_orig} plausible-but-dead instruction lines; "
                      f"per={e['per']}% dist={e['dist']} near {e['loc']}")
            byte_lines = []
            for i in range(0, size, 12):
                chunk = rom_bytes[i:i + 12]
                byte_lines.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in chunk))
            new_lines = [header] + byte_lines
            # Replace physical lines [start_line, end_line] (1-indexed, inclusive).
            s, en = a['start_line'], a['end_line']
            lines[s - 1:en] = new_lines
            converted_manifest_entries.append(dict(
                addr_lo=f"0x{lo:06X}", addr_hi=f"0x{hi:06X}", size=size, loc=e['loc'],
                per=e['per'], dist=e['dist'], ascii=e.get('ascii'), file=relfile,
                lines_0indexed=[s - 1, en - 1],
                resolved_by="v10dac2_line_probe.py (address-anchored assembler probe, lane V10DAC2)"))
        open(path, 'w', encoding='latin-1').write('\n'.join(lines))
        print(f"  {relfile}: {len(spans)} spans converted")

    print(f"total converted this pass: {len(converted_manifest_entries)} spans, {total_bytes} B")

    manifest['converted'].extend(converted_manifest_entries)
    manifest['excluded'] = remaining_exc + rejected
    json.dump(manifest, open(MANIFEST_PATH, 'w'), indent=1)
    print(f"manifest updated: {len(manifest['converted'])} converted total, "
          f"{len(manifest['excluded'])} excluded total")


if __name__ == '__main__':
    main()
