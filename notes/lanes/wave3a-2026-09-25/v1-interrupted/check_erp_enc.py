# check_erp_enc.py: ENCODER side of the ERP LD rename. For every ldto_/ldfr_ {b,w,l}erp r, N
# (every r of the class, every N 0..255) assemble with llvm-mc, decode with unidasm, and require
# ldto r,N == MAME "ld r,<R_N>" and ldfr r,N == MAME "ld <R_N>,r", with N as the second byte.
import subprocess, os, re, tempfile
MC=os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
UD=os.path.expanduser('~/compartilhado/tools/unidasm')
regs={'b':'w a b c d e h l'.split(),'w':'wa bc de hl ix iy iz sp'.split(),'l':'xwa xbc xde xhl xix xiy xiz xsp'.split()}
lines=[]
for sz,rs in regs.items():
    for d in ('ldto','ldfr'):
        for r in rs:
            for N in range(256):
                lines.append((d,sz,r,N,'%s_%serp %s, %d'%(d,sz,r,N)))
src='\n'.join('.section .q%d,"ax"\n\t%s'%(i,l[4]) for i,l in enumerate(lines))
open('_erp.s','w').write(src+'\n')
r=subprocess.run([MC,'-triple=tlcs900','--show-encoding','_erp.s'],capture_output=True,text=True)
errs=r.stderr.count('error:')
encs={}
cur=None
for line in r.stdout.splitlines():
    s=line.strip()
    if s.startswith('.section'):
        cur=int(s.split('.q')[1].split(',')[0]); continue
    m=re.search(r'encoding: \[([^\]]*)\]',line)
    if m and cur is not None: encs[cur]=bytes(int(x,16) for x in m.group(1).split(','))
img=bytearray()
for i in range(len(lines)):
    e=encs.get(i,b'')
    img+=e+bytes(16-len(e))
open('_erp.bin','wb').write(img)
u=subprocess.run([UD,'_erp.bin','-arch','tlcs900','-basepc','0'],capture_output=True,text=True).stdout
mame={}
for line in u.splitlines():
    m=re.match(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$',line)
    if m and int(m.group(1),16)%16==0: mame[int(m.group(1),16)//16]=m.group(3).strip()
bad=0;n=0;ex=[]
for i,(d,sz,r,N,t) in enumerate(lines):
    if i not in encs: bad+=1; ex.append((t,'NOT ENCODED','')); continue
    e=encs[i]; mt=mame.get(i,'')
    n+=1
    mm,_,mo=mt.partition(' ')
    ops=[x.strip().lower() for x in mo.split(',')]
    ok = mm=='ld' and len(e)==3 and e[1]==N and len(ops)==2 and ((d=='ldto' and ops[0]==r) or (d=='ldfr' and ops[1]==r))
    if not ok: bad+=1; ex.append((t,e.hex(' '),mt))
print('assembler errors:',errs,' encoded',len(encs),'/',len(lines),' bad',bad)
for x in ex[:20]: print(x)
