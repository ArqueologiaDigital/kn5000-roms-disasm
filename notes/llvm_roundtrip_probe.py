#!/usr/bin/env python3
"""llvm_roundtrip_probe.py -- can the assembler re-encode what its own
disassembler emits?

QUESTION ANSWERED
  Take real bytes from a ROM, disassemble them, feed that exact text back to
  llvm-mc, and compare the encoding against the original bytes. Three
  outcomes, and they are NOT the same problem:

    * round-trips        -- the form is fully supported
    * REJECTED           -- the assembler cannot parse a spelling its own
                            disassembler produced (e.g. `cpda16_24 D,(HL)`)
    * ENCODES DIFFERENTLY -- ⚠ the dangerous one: it is accepted and WRONG

  The third class is why this probe compares BYTES rather than checking for
  an error message. This backend has shipped three forms that assembled
  silently wrong -- `push (0x1234)` truncating its address to 8 bits,
  `mul WA,(0x1234)` multiplying by the ADDRESS not the contents, and
  `ld wa,(xix+iz)` swallowing the index register. None produced a
  diagnostic. "llvm-mc accepted it" is never evidence.

RUN
  python3 notes/llvm_roundtrip_probe.py

  LLVM_MC and ROM default to this checkout; override with the environment
  variables of the same names to point at another build or image.

WHY IT MATTERS
  The encode/decode asymmetry is not academic: it is currently forcing 976
  bytes to stay `.byte` in the v1.42 sub-CPU payload (DSP_Bytecode_Op01/02/03,
  569 B, plus ~407 B in the TaskEvent/FIFO/TaskSched family).
"""
import os, subprocess, re, sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]
LLVM_MC = os.environ.get('LLVM_MC',
    str(Path.home() / 'compartilhado/llvm-project/build/bin/llvm-mc'))
ROM = os.environ.get('ROM', str(_ROOT / 'original_ROMs/kn5000_subprogram_v142.rom'))
ENC_RE = re.compile(r'encoding: \[([^\]]+)\]')

def load(addr, size):
    with open(ROM, 'rb') as f:
        f.seek(addr)
        return f.read(size)

def run(args, inp):
    r = subprocess.run(args, input=inp, capture_output=True, timeout=30)
    return r.returncode, r.stdout, r.stderr

def disasm_stream(raw):
    hex_str = (' '.join(f'0x{b:02x}' for b in raw) + '\n').encode()
    rc, out, err = run([LLVM_MC, '--triple=tlcs900', '--disassemble', '-'], hex_str)
    return rc, out.decode(), err.decode()

def encode_one(inst):
    rc, out, err = run([LLVM_MC, '--triple=tlcs900', '--show-encoding', '-'], (inst + '\n').encode())
    out = out.decode(); err = err.decode()
    enc = None
    m = ENC_RE.search(out.encode())
    if m:
        enc = bytes(int(h.strip(), 16) for h in m.group(1).decode().split(','))
    return rc, enc, err.strip()

def probe(name, addr, size):
    print(f'=== {name}  addr=0x{addr:06x}  size={size} ===')
    raw = load(addr, size)
    rc, out, err = disasm_stream(raw)
    if err.strip():
        print('  disasm stderr:', err.strip()[:400])
    lines = [l.strip() for l in out.strip().split('\n') if l.strip() and not l.strip().startswith('.')]
    print(f'  {len(lines)} instructions decoded')
    reasm = b''
    bad = []
    for inst in lines:
        rc2, enc, err2 = encode_one(inst)
        if enc is None:
            bad.append((inst, err2[:150]))
            continue
        reasm += enc
    # ⚠ A VACUOUS PASS IS NOT A PASS.  If the disassembler decoded nothing,
    # `reasm` and `raw` can both be empty and `reasm == raw` is trivially true.
    # That is the failure this probe exists to expose, so it must never be
    # printed as OK: zero decoded instructions means the region is UNDECODABLE
    # by this toolchain, which is a finding, not a success.
    if not lines or not reasm:
        ok = False
        verdict = 'VACUOUS -- 0 instructions decoded, nothing was compared'
    elif reasm != raw:
        ok = False
        verdict = 'MISMATCH/INCOMPLETE'
    else:
        ok = True
        verdict = 'OK'
    print(f'  whole-stream roundtrip: {verdict} (reasm {len(reasm)}B vs raw {len(raw)}B)')
    if bad:
        print(f'  {len(bad)} instructions REJECTED by --show-encoding:')
        for inst, err2 in bad:
            print(f'    {inst!r:45s} {err2}')
    return raw, lines

if __name__ == '__main__':
    probe('DSP_Bytecode_Op01_Groups5_Addr12', 0x3C568, 249)
    probe('DSP_Bytecode_Op02_Groups3_Raw',     0x3C661, 167)
    probe('DSP_Bytecode_Op03_Addr16_RawTail',  0x3C708, 153)
