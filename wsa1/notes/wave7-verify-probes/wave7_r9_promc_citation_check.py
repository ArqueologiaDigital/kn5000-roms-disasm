import os
"""Check every hex address cited in the round-9 prom_c additions is an instruction
start (or a known data label) rather than an operand byte.
Instruction-start set = every `; ADDR  mnemonic` trailing comment in wsa1_prom_c.s."""
import re
S=open('/home/fsanches/compartilhado/wsa1-roms-disasm/prom_c/wsa1_prom_c.s').read().split('\n')
starts=set(); datalab={}
for ln in S:
    m=re.search(r';\s*([0-9A-F]{6})\s{2}\S', ln)
    if m and not ln.lstrip().startswith(';'): starts.add(int(m.group(1),16))
    m2=re.search(r';\s*0x([0-9A-F]{6})\s*$', ln)          # data emission lines
    if m2 and ('.short' in ln or '.byte' in ln or '.asciz' in ln): starts.add(int(m2.group(1),16))
D=open('/home/fsanches/compartilhado/wsa1-roms-disasm/original_ROMs/wsa1_prom_c.ic28','rb').read()
BASE=0xF80000
# ⚠ Self-contained: the original read a scratch 'promc.diff' that no longer
# exists. It now produces the diff itself, so the probe is re-runnable. REV is
# the commit the round-9 prom_c additions landed on top of.
import subprocess as _sp
REV = os.environ.get('REV', 'db9d8b5')
_d = _sp.run(['git', 'diff', REV, '--', 'prom_c/wsa1_prom_c.s'],
             cwd='/home/fsanches/compartilhado/wsa1-roms-disasm',
             capture_output=True, text=True).stdout
added=[l[1:] for l in _d.split('\n') if l.startswith('+') and not l.startswith('+++')]
cited={}
for l in added:
    if not l.lstrip().startswith(';'): continue
    for a in re.findall(r'0x([0-9A-Fa-f]{6})\b', l):
        v=int(a,16)
        if 0xF80000<=v<=0xFFFFFF: cited.setdefault(v,[]).append(l.strip()[:70])
print("distinct addresses cited in the added prose: %d"%len(cited))
bad=[]
for v in sorted(cited):
    if v not in starts:
        prev=D[v-1-BASE]
        bad.append((v,prev,cited[v][0]))
print("NOT an instruction/data start: %d"%len(bad))
for v,p,ctx in bad: print("  %06X  byte@cited-1=0x%02X  | %s"%(v,p,ctx))
