import os,sys
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
sys.path.insert(0, os.path.join(ROOT,"notes"))
sys.path.insert(0, os.path.join(ROOT,"scripts","analysis"))
import prom_b_f0ea9f_layout as LY
import prom_b_f65000_layout as L
import prom_b_module_trace as MT
d=L.rom()
TRIM=8
def trimmed_end(s,e,trim=TRIM):
    """largest e'<=e with e-e'<=trim, decode exact from s to e', ends in flow end"""
    best=None
    p,bounds=s,[]
    while p<e:
        dec=MT.decode_at(p)
        if dec is None: return None
        bounds.append((p,dec[0],dec[1]))
        p+=dec[0]
    # walk backwards over boundaries
    ends=[]
    q=s
    for a,n,t in bounds:
        q=a+n
        ends.append((q,t))
    for q,t in reversed(ends):
        if e-q>trim: break
        if L.is_ok if False else True:
            import trace_code as TC
            if TC.is_flow_end(t) and L.decode_bounds(s,q) is not None:
                return q
    return None
spans=LY.dl_spans()
print("DL corpus spans",len(spans),"bytes",sum(e-s for s,e in spans))
for target in (16,24,32,48,64):
    tot=fp0=fp1=0
    for (s,e),starts in spans.items():
        i=0
        while i<len(starts):
            j=i
            while j<len(starts) and (starts[j]-starts[i])<target: j+=1
            cs,ce=starts[i],(starts[j] if j<len(starts) else e)
            i=j
            if ce-cs<4: continue
            tot+=1
            good,_=L.selfconsistent(d,cs,ce,set())
            if good and L.ends_in_flow_end(cs,ce): fp0+=1
            # trimmed variant
            te=trimmed_end(cs,ce)
            if te is not None and te>cs:
                g2,_=L.selfconsistent(d,cs,te,set())
                if g2: fp1+=1
    print("  chunk>=%3d  whole-run rule %4d/%4d (%.1f%%)   with <=%d-byte trim %4d/%4d (%.1f%%)"%(
        target,fp0,tot,100.0*fp0/tot,TRIM,fp1,tot,100.0*fp1/tot))
