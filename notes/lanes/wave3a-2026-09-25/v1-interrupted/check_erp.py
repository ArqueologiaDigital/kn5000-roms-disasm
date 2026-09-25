# check_erp.py: ERP LD direction -- ldto_X r,N must be MAME "ld r,<R_N>", ldfr_X r,N must be "ld <R_N>,r";
# N must equal the register byte; the text must re-encode (asym column empty).
import csv
bad=0;n=0;ex=[];skip=0
for row in csv.reader(open('out_erp.tsv'),delimiter='\t'):
    if row[0] in ('class','MAME_ONLY'): continue
    cls,g,b,l,m,asym=row
    bs=[int(x,16) for x in b.split()]
    lm,lo=l.split(' ',1); mm,mo=m.split(' ',1)
    lops=[x.strip() for x in lo.split(',')]; mops=[x.strip() for x in mo.split(',')]
    if not (lm.startswith('ldto_') or lm.startswith('ldfr_')):
        skip+=1; continue
    n+=1; ok=True
    if lm.startswith('ldto_') and mops[0].lower()!=lops[0].lower(): ok=False
    if lm.startswith('ldfr_') and mops[1].lower()!=lops[0].lower(): ok=False
    if int(lops[1])!=bs[1] or mm!='ld' or asym: ok=False
    if not ok: bad+=1; ex.append(row)
print(n,'ldto/ldfr checked',bad,'bad',skip,'other')
for r in ex[:20]: print(r)
