#!/usr/bin/env python3
"""llvm_roundtrip_probe.py -- can the assembler re-encode what its own
disassembler emits?

QUESTION ANSWERED
  Take real bytes (from a ROM image, or from a `.byte` run already sitting in
  a disassembly `.s` file), disassemble them, feed that exact text back to
  llvm-mc, and compare the encoding against the original bytes. Three
  outcomes, and they are NOT the same problem:

    * round-trips        -- the form is fully supported
    * REJECTED           -- the assembler cannot parse a spelling its own
                            disassembler produced (e.g. `cpda16 4160, (wa)`,
                            the actual mis-print this probe caught in the
                            TaskEvent/FIFO/TaskSched family -- printed with
                            reversed operands and the wrong register width)
    * ENCODES DIFFERENTLY -- the dangerous one: it is accepted and WRONG

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

  For a diagnostic breakdown of WHERE a whole-stream mismatch first appears
  (used to isolate a single bad instruction inside a much longer block, as
  opposed to the whole-block yes/no verdict `probe()` gives), call
  `probe(..., diagnose=True)`, or run this file with `--diagnose`.

⚠ VACUOUS PASSES.  If the disassembler decodes zero instructions, a naive
  comparison of two empty byte strings reads as "roundtrip: OK" -- which is
  exactly backwards: it means the region is UNDECODABLE by this toolchain,
  not that it round-trips cleanly. `probe()` refuses to call that a pass.

⚠ ROM ADDRESS != FILE OFFSET for kn5000_subprogram_v142.rom.  The packed dump
  is addressed starting at 0x0EF00, not 0 (confirmed against
  original_ROMs/kn5000_subprogram_v142.rom.unidasm: its first line is
  `0ef00:`, its last is `3eeff:`, and 0x3eeff-0x0ef00+1 == the 196,608-byte
  file size exactly). A first version of this probe seeked a ROM *address*
  directly into the *file* with no base subtracted, read past EOF for every
  DSP_Bytecode_Op0N region (all live above 0x30000), and produced 0
  instructions decoded for every one of them -- which the vacuous-pass bug
  above then misreported as a clean round-trip. Both bugs had to be fixed
  before this script's output meant anything.

WHY IT MATTERS
  The encode/decode asymmetry is not academic: it was forcing 976 bytes to
  stay `.byte` in the v1.42 sub-CPU payload (DSP_Bytecode_Op01/02/03, 569 B,
  plus ~407 B in the TaskEvent/FIFO/TaskSched family) until the two decoder
  bugs this probe located were fixed in
  ~/compartilhado/llvm-project (tlcs900_backend):
    1. dst-mem-prefix immediate-store sub-opcode 0x02 was decoded as
       TLCS900::LD16mi_dst (mnemonic "ldmi16", real opcode 0x14) instead of
       TLCS900::LD16mi_dst_02 (mnemonic "ldw", real opcode 0x02) --
       Disassembler/TLCS900Disassembler.cpp, the `OpByte == 0x02` case in
       the dst-mem-prefix immediate-store decoder.
    2. the direct-address ALU family (addda16/subda16/.../cpda16 and their
       _24 and mem-dest siblings) decoded its register operand with
       decodeRegForSize(RegEnc, OpSize) -- giving an 8/16-bit name like "wa"
       -- when every one of those instructions' sole TableGen definition
       declares a plain 32-bit GPR operand (proven by ~20 already-shipped
       ROM sites spelling it `cpda16_24 xhl, (addr)`, never `hl, (addr)`);
       and CP's routing test `AluBase >= 0x88` wrongly caught CP's own base
       0xF0, swapping its operand order in the printed text -- both in the
       DALUOps loop of the same file.
"""
import os, re, subprocess, sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]
LLVM_MC = os.environ.get('LLVM_MC',
    str(Path.home() / 'compartilhado/llvm-project/build/bin/llvm-mc'))
ROM = os.environ.get('ROM', str(_ROOT / 'original_ROMs/kn5000_subprogram_v142.rom'))
# See "ROM ADDRESS != FILE OFFSET" above. Only valid for kn5000_subprogram_v142.rom.
ROM_BASE = int(os.environ.get('ROM_BASE', '0x0EF00'), 0)
ENC_RE = re.compile(rb'encoding: \[([^\]]+)\]')


def load(addr, size):
    off = addr - ROM_BASE
    if off < 0:
        raise ValueError(f'address 0x{addr:x} is below ROM_BASE 0x{ROM_BASE:x}')
    with open(ROM, 'rb') as f:
        f.seek(off)
        data = f.read(size)
    if len(data) < size:
        raise ValueError(f'short read at file offset 0x{off:x}: got {len(data)} of {size} bytes '
                          f'-- address 0x{addr:x} is probably outside this ROM_BASE mapping')
    return data


def load_byte_run(src_path, start_line, end_line):
    """Pull the raw bytes out of a contiguous run of `.byte 0x.., 0x..` lines
    in a disassembly .s file (1-based, inclusive line numbers). Used for
    debt that lives only in the tree (e.g. TaskEvent/FIFO/TaskSched), where
    there is no need to fight the packed-ROM addressing quirk above -- the
    bytes are read straight out of the source that will eventually replace
    them."""
    raw = bytearray()
    lines = Path(src_path).read_text(encoding='latin-1').splitlines()
    for l in lines[start_line - 1:end_line]:
        m = re.match(r'\s*\.byte\s+(.+)$', l)
        if m:
            raw.extend(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1)))
    return bytes(raw)


def run(args, inp):
    r = subprocess.run(args, input=inp, capture_output=True, timeout=30)
    return r.returncode, r.stdout, r.stderr


def disasm_stream(raw):
    """Disassemble with --show-encoding so each printed line carries the
    GROUND-TRUTH original bytes it was decoded from (not a length inferred
    later by re-encoding, which desyncs the moment one instruction mis-sizes
    and turns every later "mismatch" into noise)."""
    hex_str = (' '.join(f'0x{b:02x}' for b in raw) + '\n').encode()
    rc, out, err = run([LLVM_MC, '--triple=tlcs900', '--disassemble', '--show-encoding', '-'], hex_str)
    return rc, out.decode(errors='replace'), err.decode(errors='replace')


def parse_disasm_lines(out):
    """Yield (mnemonic_text, original_bytes) for each decoded line."""
    result = []
    for l in out.strip().split('\n'):
        l = l.strip()
        if not l or l.startswith('.'):
            continue
        m = ENC_RE.search(l.encode())
        if not m:
            continue
        enc = bytes(int(h.strip(), 16) for h in m.group(1).decode().split(','))
        text = l.split(';', 1)[0].strip()
        result.append((text, enc))
    return result


def encode_one(inst):
    rc, out, err = run([LLVM_MC, '--triple=tlcs900', '--show-encoding', '-'], (inst + '\n').encode())
    enc = None
    m = ENC_RE.search(out)
    if m:
        enc = bytes(int(h.strip(), 16) for h in m.group(1).decode().split(','))
    return rc, enc, err.decode(errors='replace').strip()


def probe(name, raw, diagnose=False):
    print(f'=== {name}  ({len(raw)} bytes) ===')
    rc, out, err = disasm_stream(raw)
    if err.strip():
        print('  disasm stderr:', err.strip()[:400])
    decoded = parse_disasm_lines(out)
    print(f'  {len(decoded)} instructions decoded')
    reasm = b''
    bad = []
    mismatches = []
    for text, orig_bytes in decoded:
        rc2, enc, err2 = encode_one(text)
        if enc is None:
            bad.append((text, err2[:150]))
            reasm += orig_bytes  # keep position tracking honest for diagnose mode
            mismatches.append((text, orig_bytes, None))
            continue
        reasm += enc
        if enc != orig_bytes:
            mismatches.append((text, orig_bytes, enc))
    consumed = sum(len(b) for _, b in decoded)
    # ⚠ A VACUOUS PASS IS NOT A PASS. See module docstring.
    if not decoded:
        verdict = 'VACUOUS -- 0 instructions decoded, nothing was compared'
    elif consumed != len(raw):
        verdict = f'PARTIAL DECODE -- only {consumed} of {len(raw)} bytes were consumed'
    elif bad or mismatches:
        verdict = 'MISMATCH -- see per-instruction detail'
    else:
        verdict = 'OK -- byte-exact round trip'
    print(f'  whole-stream roundtrip: {verdict}')
    if bad:
        print(f'  {len(bad)} instructions REJECTED by --show-encoding:')
        for inst, err2 in bad:
            print(f'    {inst!r:45s} {err2}')
    if diagnose and mismatches:
        print(f'  {len(mismatches)} instructions mismatch (original bytes vs re-encoded bytes):')
        for text, orig_bytes, enc in mismatches:
            enc_s = enc.hex(' ') if enc is not None else 'REJECTED'
            print(f'    {text!r:45s} rom={orig_bytes.hex(" ")}  reenc={enc_s}')
    return decoded


if __name__ == '__main__':
    diagnose = '--diagnose' in sys.argv
    probe('DSP_Bytecode_Op01_Groups5_Addr12', load(0x3C568, 249), diagnose=diagnose)
    probe('DSP_Bytecode_Op02_Groups3_Raw',     load(0x3C661, 167), diagnose=diagnose)
    probe('DSP_Bytecode_Op03_Addr16_RawTail',  load(0x3C708, 153), diagnose=diagnose)

    # TaskEvent/FIFO/TaskSched: still-`.byte` runs inside kn5000_subprogram_v142.s
    # (read straight from the tree; see load_byte_run() docstring above).
    v142_src = _ROOT / 'v142/subcpu/kn5000_subprogram_v142.s'
    if v142_src.exists():
        runs = [(572, 578), (710, 710), (796, 798), (801, 804), (811, 813), (816, 818),
                (1008, 1014), (1028, 1037), (1047, 1054), (1095, 1101), (1104, 1111),
                (1115, 1120), (1131, 1139), (1146, 1150), (1153, 1160), (1164, 1166),
                (1749, 1756), (1762, 1763)]
        for s, e in runs:
            raw = load_byte_run(v142_src, s, e)
            if raw:
                probe(f'kn5000_subprogram_v142.s:{s}-{e}', raw, diagnose=diagnose)
