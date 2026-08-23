import subprocess, os, sys
MC=os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
OC=os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-objcopy')
rom=open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom','rb').read()

def asm_text(src):
    """assemble to object, extract .text bytes"""
    open('in.s','w').write(src)
    r=subprocess.run([MC,'-triple=tlcs900','-filetype=obj','in.s','-o','in.o'],
                     capture_output=True,text=True)
    if r.returncode!=0:
        return None, r.stderr.strip()
    subprocess.run([OC,'-O','binary','--only-section=.text','in.o','in.bin'],
                   capture_output=True)
    return open('in.bin','rb').read(), None

sites=[(0xEF8484,0xEF8480,'djnz16 bc'),(0xEF852F,0xEF850D,'djnz16 bc'),
       (0xEF870C,0xEF86D6,'djnz16 bc'),(0xEFF455,0xEFF452,'djnz16 bc'),
       (0xF0FA00,0xF0F9AF,'djnz8 c'),(0xF50EF4,0xF50EB3,'djnz16 iz'),
       (0xF97839,0xF97833,'djnz16 iz')]
fail=0
for site,target,mn in sites:
    romb=rom[site-0xE00000:site-0xE00000+3]
    disp=target-(site+3)
    pad=-disp-3
    lbl='.Lc_%x'%target
    src='.text\n%s:\n.space %d\n%s, %s\n'%(lbl,pad,mn,lbl)
    got,err=asm_text(src)
    if got is None:
        print('0x%06X  ASM ERROR for "%s, %s": %s'%(site,mn,lbl,err)); fail+=1; continue
    ins=got[pad:pad+3]
    ok = ins==romb
    print('0x%06X  rom=%s  llvm-mc[%s, %s]=%s  %s'%(
        site,' '.join('%02x'%b for b in romb),mn,lbl,
        ' '.join('%02x'%b for b in ins),'MATCH' if ok else '*** MISMATCH ***'))
    if not ok: fail+=1
print('fails:',fail)
