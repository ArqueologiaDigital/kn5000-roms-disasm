#!/usr/bin/env python3
"""Is every address cited in round 9's new prom_a headers an INSTRUCTION START?

QUESTION IT ANSWERS
    "Does any Evidence: line cite an OPERAND byte instead of the instruction that
     owns it?" That bug hit lane a2 on 31 of 31 citations in round 1 and its
     signature is that the byte at cited-1 is an opcode (0x44/0x45/0x46).

RESULT: 188 of 192 citations are instruction starts, and ALL FOUR remaining are
adjudicated -- none carries the off-by-one signature:

  0xF863F5  IS an instruction, `ldb_d8 w,(0x2078)`. This probe's index misses it
            because it is spelled with a PRELUDE MACRO rather than a plain
            mnemonic. A false positive OF THE PROBE, not a bad citation.
  0xFC243B  a `.byte` line whose own comment decodes it as `cp BC,(XIX+WA)` --
            an instruction LLVM's backend cannot encode, so it is emitted as
            bytes. Correctly cited as an instruction.
  0xFEB330  a `.long`, "RAM record 0". A legitimate DATA citation.
  0xFFFFFF  a sentinel value, not an address.

So the probe is slightly OVER-STRICT and that is stated here rather than left
looking like four defects. Read the four lines it prints against this list.

RUN
    python3 notes/wave7-verify-probes/wave7_r9_proma_citation_check.py
"""

import re,sys
SRC="/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/prom_a/wsa1_prom_a.s"
lines=open(SRC,encoding='utf-8',errors='replace').read().split('\n')
# address -> (mnemonic text, bytes)  for every emitted instruction line
addr2ins={}
ins_re=re.compile(r'^\t(.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} ?)+)\s*$')
for ln in lines:
    m=ins_re.match(ln)
    if m:
        a=int(m.group(2),16)
        addr2ins[a]=(m.group(1).strip(),m.group(3).strip())
# also cover every byte an instruction occupies -> its start
covered={}
for a,(t,b) in addr2ins.items():
    n=len(b.split())
    for k in range(n): covered[a+k]=a
print(f"instruction lines indexed: {len(addr2ins)}  bytes covered: {len(covered)}")

NEW=["Ring601850_ServiceIfNotEmpty","Ring_InitAllFourteen","Ring601432_SpinUntilEmpty",
"Ring600C1E_InitIfPanelMode79","Ring601646_InitIrqMasked","Ring60000C_GetWithRetry",
"SoundGroup_MaxMemberIndex_Get","SoundGroup_MaxMemberIndex_GetToneCopy",
"SoundCode_FromGroupMember_ModeOffset","SoundCode_FromGroupMember_ByteGroup",
"Ring608A0A_DrainAll","Disk_FormatSelectedMedia_Veneer","MidiIn_ServiceDeferred_Veneer",
"UiEventList_Publish_Veneer","INT5_Dev7B_Receive_Alias","INTTC0_uDMA0Done_Alias",
"Fdc_ServiceDataByte_Isr","RecordNameSource_Select","DLB_Handler_StringTable_Veneer",
"DLB_Handler_Decimal_Veneer","Ring_InitTenOfFourteen"]
# collect header block for each
blocks={}
for i,ln in enumerate(lines):
    for n in NEW:
        if ln.startswith(f"; {n} --"):
            j=i
            while j>0 and not lines[j].startswith("; ---"): j-=1
            k=i
            while k<len(lines) and not lines[k].startswith("; ---",0) or k==j: k+=1
            blocks[n]=lines[j:k+1]
bad=[];ok=0;prom_a_lo=0xF80000;prom_a_hi=0xFFFFFF
for n in NEW:
    blk=blocks.get(n)
    if blk is None: print("!! no header found for",n); continue
    txt="\n".join(blk)
    for a_s in re.findall(r'0x([0-9A-Fa-f]{6})',txt):
        a=int(a_s,16)
        if not (prom_a_lo<=a<=prom_a_hi): continue   # prom_b/other-image addrs handled separately
        if a in addr2ins: ok+=1
        elif a in covered:
            start=covered[a]
            bad.append((n,a_s,"OPERAND BYTE of instruction at %06X: %s"%(start,addr2ins[start][0])))
        else:
            bad.append((n,a_s,"not an instruction line (data or unmapped)"))
print(f"\nprom_a-range citations that ARE instruction starts: {ok}")
print(f"prom_a-range citations that are NOT: {len(bad)}")
for n,a,why in bad: print(f"   {n:38s} 0x{a}  {why}")
