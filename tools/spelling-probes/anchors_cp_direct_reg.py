#!/usr/bin/env python3
"""Which v9 SOURCE LINE writes each of the six `cp (imm),r` encoding classes?

QUESTION ANSWERED
  README-cp_direct_reg.md quotes one source-anchored example per encoding class
  (c1/d1/e1/c2/d2/e2).  Those anchors must not be guessed: this script produces
  them.  It re-assembles the v9 sources with `llvm-mc -g`, ABORTS unless the
  result is still byte-identical to original_ROMs/kn5000_v9_program.rom, then
  reads the DWARF line table and reports, for each prefix, the first whole-ROM
  `cp (imm),r` sweep hit that starts a source statement -- i.e. the first one
  the sources really emit rather than the linear scan inventing.

  ⚠ The DWARF file index resolves to the master file kn5000_v9_program.s for
  every row (the assembler does not re-key .include'd files), so only the LINE
  number is usable; it is the line number WITHIN the include.  Cross-check each
  anchor by grepping the sources for the printed spelling, as the README does.

RUN
  python3 tools/spelling-probes/anchors_cp_direct_reg.py

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b
  c1 0xed37f2  c1 00 ff ff     cp (0xff00),L     line 2596
  d1 0xef1acf  d1 87 04 f8     cp (0x0487),WA    line 2140  boot/system_handlers.s:2140
                                                            `cpdm16 1159, xwa`
  e1 0xe16bae  e1 00 00 ff     cp (0x0000),XSP   line  175  ui_widgets/
                                                            naka_property_descriptors.s:175
                                                            `cpdm32 0, xsp`
  c2 0xf071af  c2 33 0c 02 f9  cp (0x020c33),A   line 1997
  d2 0xf7ba61  d2 9e e9 03 fa  cp (0x03e99e),DE  line 4494  ui/drawbar_panel_ui.s:4494
                                                            `cpdm16_24 (0x3e99e), xde`
  e2 0xf9a549  e2 6a ef 03 fa  cp (0x03ef6a),XDE line  357
  The three anchors whose include the line number alone did not identify were
  replaced in the README by grep-located siblings whose byte string occurs
  EXACTLY ONCE in the ROM:
      cpdm8    boot/system_handlers.s:759        1046, a   -> 0xEF0F4A c1 16 04 f9
      cpdm8_24 audio/note_voice_mapping.s:16412  (0xcee0), a
                                                           -> 0xFE9F8A c2 e0 ce 00 f9
      cpdm32_24 audio/note_voice_mapping.s:29285 (0x3d528), xwa
                                                           -> 0xFF0F75 e2 28 d5 03 f8
"""
import os, re, subprocess, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
os.chdir(REPO)
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
ROM  = 'original_ROMs/kn5000_v9_program.rom'

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^cp \((0x[0-9a-f]+)\),([A-Za-z]+)$')

with tempfile.TemporaryDirectory() as tmp:
    o, elf, out = (os.path.join(tmp, n) for n in ('a.o', 'a.elf', 'a.rom'))
    subprocess.run([f'{LLVM}/llvm-mc', '-triple=tlcs900', '-filetype=obj', '-g',
                    '-I', 'v9/maincpu', '-o', o,
                    'v9/maincpu/kn5000_v9_program.s'], check=True)
    subprocess.run([f'{LLVM}/ld.lld', '-e', '0', '-T', 'v9/maincpu/maincpu.ld',
                    '-o', elf, o], check=True)
    subprocess.run([f'{LLVM}/llvm-objcopy', '-O', 'binary', elf, out], check=True)
    assert open(out, 'rb').read() == open(ROM, 'rb').read(), \
        'ABORT: the -g rebuild is NOT byte-identical to the original v9 ROM'
    dl = subprocess.run([f'{LLVM}/llvm-dwarfdump', '--debug-line', elf],
                        capture_output=True, text=True).stdout

rows = {}
for line in dl.split('\n'):
    m = re.match(r'^0x([0-9a-f]{16})\s+(\d+)\s+(\d+)\s+(\d+)', line)
    if m:
        rows[int(m.group(1), 16)] = int(m.group(2))

dis = subprocess.run([UNI, ROM, '-arch', 'tlcs900', '-basepc', hex(BASE)],
                     capture_output=True, text=True).stdout
want = {k: None for k in ('c1', 'd1', 'e1', 'c2', 'd2', 'e2')}
for line in dis.split('\n'):
    m = LINE.match(line)
    if not m or not TEXT.match(m.group(3)):
        continue
    a = int(m.group(1), 16)
    by = bytes(int(x, 16) for x in m.group(2).split())
    k = f'{by[0]:02x}'
    if k in want and want[k] is None and a in rows:
        want[k] = (a, by, m.group(3), rows[a])
for k in ('c1', 'd1', 'e1', 'c2', 'd2', 'e2'):
    v = want[k]
    print(f'{k} {v[0]:#08x}  {v[1].hex(" "):16s} {v[2]:20s} line {v[3]}'
          if v else f'{k} none')
