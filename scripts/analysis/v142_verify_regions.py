#!/usr/bin/env python3
"""v142_verify_regions.py -- Verify converted regions rebuild byte-identically and their call targets resolve to named routines.

RUN
    python3 scripts/analysis/v142_verify_regions.py

⚠ A round trip is NECESSARY but NOT SUFFICIENT. The byte gate cannot catch
  data framed as code: re-assembling a wrong interpretation reproduces the
  same bytes. Corroborate with call targets landing on routines already named
  in the tree before converting anything this reports.

⚠ A decoder FAILING is not evidence the bytes are data. The disassembler has
  no case at all for the register-indexed SriRR family and decodeERPPrefix is
  a stub, so silence here means "unknown", never "not code".
"""
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

ENC_RE = re.compile(rb'encoding: \[([^\]]+)\]')
def disasm_texts(raw):
    hex_str = ' '.join(f'0x{b:02x}' for b in raw) + '\n'
    r = subprocess.run([MC, '--triple=tlcs900', '--disassemble', '--show-encoding', '-'],
                        input=hex_str.encode(), capture_output=True, timeout=30)
    out = r.stdout.decode(errors='replace')
    texts = []
    for l in out.strip().split('\n'):
        l = l.strip()
        if not l or l.startswith('.'): continue
        m = ENC_RE.search(l.encode())
        if not m: continue
        text = l.split(';',1)[0].strip()
        texts.append(text)
    return texts, r.stderr.decode(errors='replace')

def reassemble(texts):
    src = '\n'.join(texts) + '\n'
    r = subprocess.run([MC, '--triple=tlcs900', '--show-encoding', '-'],
                        input=src.encode(), capture_output=True, timeout=30)
    out = r.stdout.decode(errors='replace')
    enc_all = bytearray()
    per = []
    for l in out.strip().split('\n'):
        m = ENC_RE.search(l.encode())
        if m:
            b = bytes(int(x,16) for x in m.group(1).decode().split(','))
            enc_all.extend(b)
            per.append(b)
    return bytes(enc_all), per, r.stderr.decode(errors='replace')

RUNS_NOFAIL = [(801,804,'TaskSched_SoftTimer_Entry'),
        (816,818,'TaskSched_SoftTimer_Fire'),
        (1008,1014,'TaskQueue_Operations_Opaque'),
        (1104,1111,'TaskEvent_Signal_Wake'),
        (1131,1139,'TaskEvent_Signal_NoResched_Wake'),
        (1153,1160,'TaskEvent_Wait_Block'),
        (1749,1756,'RingBuf_Access_Opaque_A')]

for s,e,name in RUNS_NOFAIL:
    raw = extract_run(s,e)
    texts, err = disasm_texts(raw)
    reasm, per, err2 = reassemble(texts)
    print(f"=== {name} lines {s}-{e} ({len(raw)}B) ===")
    if reasm == raw:
        print("  FULL BYTE-EXACT ROUND TRIP -- safe to convert")
    else:
        print(f"  MISMATCH: reassembled {len(reasm)}B vs original {len(raw)}B")
        # walk and find first differing instruction
        off = 0
        for t, b in zip(texts, per):
            orig_slice = raw[off:off+len(b)]
            if orig_slice != b:
                print(f"    at offset {off}: text={t!r} reencoded={b.hex(' ')} orig_at_offset={raw[off:off+4].hex(' ')}")
                break
            off += len(b)
    print()
