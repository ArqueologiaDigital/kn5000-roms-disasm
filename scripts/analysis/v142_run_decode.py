#!/usr/bin/env python3
"""v142_run_decode.py -- Driver: run the decode over every blocked region in the payload and collect which succeed.

RUN
    python3 scripts/analysis/v142_run_decode.py

⚠ A round trip is NECESSARY but NOT SUFFICIENT. The byte gate cannot catch
  data framed as code: re-assembling a wrong interpretation reproduces the
  same bytes. Corroborate with call targets landing on routines already named
  in the tree before converting anything this reports.

⚠ A decoder FAILING is not evidence the bytes are data. The disassembler has
  no case at all for the register-indexed SriRR family and decodeERPPrefix is
  a stub, so silence here means "unknown", never "not code".
"""
sys.path.insert(0, '/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad')
from decode_region import decode_stream
from pathlib import Path

SRC = Path.home() / 'compartilhado/disasm-lanes/v142block/v142/subcpu/kn5000_subprogram_v142.s'
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

RUNS = [(796,798,'TaskSched_SoftTimer_Service'),
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
        (1749,1756,'RingBuf_Access_Opaque_A')]

total = 0
solved = 0
for s,e,name in RUNS:
    raw = extract_run(s,e)
    total += len(raw)
    print(f"=== {name} lines {s}-{e} ({len(raw)}B) ===")
    try:
        insns = decode_stream(raw)
        total_consumed = sum(l for _,l,_,_ in insns)
        assert total_consumed == len(raw)
        solved += len(raw)
        print(f"  FULLY DECODED: {len(insns)} instructions, byte-exact")
        for t,l,enc,c in insns:
            print(f"    {enc.hex(chr(32)):20s} {t}" + (f"  ; {c}" if c else ""))
    except ValueError as ex:
        print(f"  BLOCKED: {ex}")
    print()
print(f"TOTAL: {total}B, SOLVED: {solved}B, BLOCKED: {total-solved}B")
