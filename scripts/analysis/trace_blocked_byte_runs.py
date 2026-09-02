#!/usr/bin/env python3
"""trace_blocked_byte_runs.py -- WHY does each blocked .byte run resist?

QUESTION ANSWERED
  For every `.byte` run in the v1.42 sub-CPU payload that will not convert:
  where exactly does llvm-mc's disassembler first fail, and what does MAME's
  unidasm say at that same address? The output is a per-site CAUSE MAP --
  form to blocking gap -- not a byte count.

  That map is worth more than a few converted bytes, because it tells the
  LLVM work exactly which decoder families to implement. Before it existed,
  a ~407-byte figure was attributed wholesale to one cause; only 14 B of it
  turned out to be that cause, and the rest was untraced.

★ WHY unidasm IS THE LEVER: llvm-mc and unidasm disagree about what they can
  decode. The disassembler has NO case at all for the register-indexed
  SriRR* family, and decodeERPPrefix() is a stub returning Fail for ~20
  mnemonics -- yet the ASSEMBLER encodes those forms correctly. So unidasm
  frequently succeeds where llvm-mc fails, and its framing can be
  hand-assembled and diffed against the ROM. That is how 312 bytes were
  recovered from regions every automated audit had walked past for months.

RUN
  python3 scripts/analysis/trace_blocked_byte_runs.py

⚠ A decoder failing is not evidence the bytes are data, and a decoder
  succeeding is not evidence they are code. Decoder failures here are
  SILENT -- a tool that cannot disassemble a region reports nothing rather
  than reporting a problem -- which is exactly why these sites went
  unnoticed. Corroborate any conversion with call targets landing on
  routines already named in the tree.
"""
import re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'v142/subcpu/kn5000_subprogram_v142.s'
MC = Path.home() / 'compartilhado/llvm-project/build/bin/llvm-mc'
UNIDASM = Path.home() / 'compartilhado/tools/unidasm'

lines = SRC.read_text(encoding='latin-1').splitlines()

def bytes_of_line(l):
    m = re.match(r'\s*\.byte\s+(.+?)\s*(;.*)?$', l)
    if m:
        return [int(v,16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
    m = re.match(r'\s*\.ascii\s+"((?:[^"\\]|\\.)*)"\s*(;.*)?$', l)
    if m:
        s = m.group(1).encode().decode('unicode_escape')
        return [b for b in s.encode('latin-1')]
    return None

def extract_run(start_line, end_line):
    raw = []
    for i in range(start_line, end_line+1):
        bs = bytes_of_line(lines[i-1])
        if bs is not None:
            raw.extend(bs)
    return bytes(raw)

def disasm_stream(raw):
    hex_str = (' '.join(f'0x{b:02x}' for b in raw) + '\n').encode()
    r = subprocess.run([str(MC), '--triple=tlcs900', '--disassemble', '--show-encoding', '-'],
                        input=hex_str, capture_output=True, timeout=30)
    return r.stdout.decode(errors='replace'), r.stderr.decode(errors='replace')

ENC_RE = re.compile(rb'encoding: \[([^\]]+)\]')
def parse(out):
    res=[]
    for l in out.strip().split('\n'):
        l=l.strip()
        if not l or l.startswith('.'): continue
        m = ENC_RE.search(l.encode())
        if not m: continue
        enc = bytes(int(h.strip(),16) for h in m.group(1).decode().split(','))
        text = l.split(';',1)[0].strip()
        res.append((text, enc))
    return res

def unidasm_at(raw, base=0):
    import tempfile, os
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(raw)
        path = f.name
    try:
        r = subprocess.run([str(UNIDASM), path, '-arch', 'tlcs900', '-basepc', hex(base)],
                            capture_output=True, timeout=30, text=True)
        return r.stdout, r.stderr
    finally:
        os.unlink(path)

RUNS = [(572,578,'DSP_ChannelConfigTable'),(710,710,'TaskSched_Init_ConfigData'),
        (796,798,'TaskSched_SoftTimer_Service_a'),(801,804,'TaskSched_SoftTimer_Service_b'),
        (811,813,'TaskSched_SoftTimer_Entry_a'),(816,818,'TaskSched_SoftTimer_Entry_b'),
        (1008,1014,'TaskQueue_Operations_Opaque'),(1028,1037,'TaskSched_Wake_Task'),
        (1047,1054,'TaskSched_Wake_Task_NoResched'),(1095,1101,'TaskEvent_Signal'),
        (1104,1111,'TaskEvent_Signal_Wake'),(1115,1120,'TaskEvent_Signal_NoResched'),
        (1131,1139,'TaskEvent_Signal_NoResched_Wake'),(1146,1150,'TaskEvent_Wait'),
        (1153,1160,'TaskEvent_Wait_Block'),(1164,1166,'TaskEvent_Clear'),
        (1749,1756,'RingBuf_Access_Opaque_A (incl misframed .ascii)'),
        (1762,1763,'Timer_Delay_Ticks (PROVEN OK)')]

for s,e,name in RUNS:
    raw = extract_run(s,e)
    out, err = disasm_stream(raw)
    decoded = parse(out)
    consumed = sum(len(b) for _,b in decoded)
    print(f"=== {name}  lines {s}-{e}  ({len(raw)} B) ===")
    print(f"  bytes: {raw.hex(' ')}")
    print(f"  llvm-mc consumed {consumed}/{len(raw)} bytes, {len(decoded)} insns")
    if consumed < len(raw):
        fail_off = consumed
        ctx = raw[fail_off:fail_off+8]
        print(f"  FIRST FAILURE at offset {fail_off} (byte 0x{raw[fail_off]:02x}): next bytes {ctx.hex(' ')}")
    print()

print("\n\n=== DETAIL: instructions decoded per run ===")
for s,e,name in RUNS:
    raw = extract_run(s,e)
    out, err = disasm_stream(raw)
    decoded = parse(out)
    print(f"--- {name} ---")
    off=0
    for text,enc in decoded:
        print(f"  +{off:3d}  {enc.hex(' '):20s}  {text}")
        off += len(enc)
    if off < len(raw):
        print(f"  +{off:3d}  UNDECODED TAIL: {raw[off:].hex(' ')}")
