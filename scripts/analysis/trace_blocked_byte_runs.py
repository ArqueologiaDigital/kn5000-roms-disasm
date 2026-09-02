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
#!/usr/bin/env python3
import re, subprocess
from pathlib import Path

ROOT = Path.home() / 'compartilhado/disasm-lanes/v142block'
SRC = ROOT / 'v142/subcpu/kn5000_subprogram_v142.s'
MC = str(Path.home() / 'compartilhado/llvm-project/build/bin/llvm-mc')

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

def extract_run(s,e):
    raw=[]
    for i in range(s,e+1):
        bs = bytes_of_line(lines[i-1])
        if bs: raw.extend(bs)
    return bytes(raw)

WARN_RE = re.compile(r'^<stdin>:1:(\d+): warning: invalid instruction encoding$')

def analyze(raw):
    hex_str = ' '.join(f'0x{b:02x}' for b in raw) + '\n'
    r = subprocess.run([MC, '--triple=tlcs900', '--disassemble', '--show-encoding', '-'],
                        input=hex_str.encode(), capture_output=True, timeout=30)
    err = r.stderr.decode(errors='replace')
    fail_idx = []
    for l in err.splitlines():
        m = WARN_RE.match(l.strip())
        if m:
            col = int(m.group(1))
            idx = (col - 1) // 5
            fail_idx.append(idx)
    return sorted(set(fail_idx)), r.stdout.decode(errors='replace')

RUNS = [(572,578,'DSP_ChannelConfigTable [DATA TABLE]'),
        (710,710,'TaskSched_Init_ConfigData [DATA, addr-loaded]'),
        (796,798,'TaskSched_SoftTimer_Service'),
        (801,804,'TaskSched_SoftTimer_Entry'),
        (811,813,'TaskSched_SoftTimer_Unlock'),
        (816,818,'TaskSched_SoftTimer_Fire'),
        (1008,1014,'TaskQueue_Operations_Opaque'),
        (1028,1037,'TaskSched_Wake_Task'),
        (1047,1054,'TaskSched_Wake_Task_NoResched'),
        (1095,1101,'TaskEvent_Signal'),
        (1104,1111,'TaskEvent_Signal_Wake'),
        (1115,1120,'TaskEvent_Signal_NoResched'),
        (1131,1139,'TaskEvent_Signal_NoResched_Wake'),
        (1146,1150,'TaskEvent_Wait'),
        (1153,1160,'TaskEvent_Wait_Block'),
        (1164,1166,'TaskEvent_Clear'),
        (1749,1756,'RingBuf_Access_Opaque_A'),
        (1762,1763,'Timer_Delay_Ticks [PROVEN OK]')]

total_bytes = 0
total_fail_bytes = 0
for s,e,name in RUNS:
    raw = extract_run(s,e)
    fail_idx, out = analyze(raw)
    total_bytes += len(raw)
    total_fail_bytes += len(fail_idx)
    print(f"=== {name}  lines {s}-{e}  ({len(raw)} B) ===")
    if not fail_idx:
        print(f"  NO STRUCTURAL FAILURE -- llvm-mc decodes the entire {len(raw)}-byte stream (0 warnings)")
    else:
        for idx in fail_idx:
            ctx = raw[max(0,idx-2):idx+6]
            print(f"  FAIL at byte offset {idx}: 0x{raw[idx]:02x}  (context @{max(0,idx-2)}: {ctx.hex(' ')})")
    print()
print(f"TOTAL bytes examined: {total_bytes}, TOTAL byte-offsets with hard decode FAILURE: {total_fail_bytes}")
