#!/usr/bin/env python3
"""Rank source files by bytes of UNCOMMENTED .byte/.short/.long data.

QUESTION THIS ANSWERS
  Which regions are still nameless data soup?  Total `.byte` volume is the
  wrong instrument for that -- several of the biggest files (style_records.s,
  hdae5000_data_tables.s, the WSA1R display lists) already document every field
  in a trailing comment on each row, and re-typing those would be churn.  This
  counts only rows with NO comment at all, which is the population a struct
  conversion can actually improve.

RUN (from the repo root)
  python3 scripts/analysis/uncommented_data_census.py

READING THE OUTPUT
  One line per file, largest first, then a tree total.  A file near the top with
  a known record shape is a conversion candidate; a file near the top with no
  known shape is a research candidate.

Measured 2026-09-02 (lane w13/census-structs), before that lane's conversions:
tree total 1,076,671 bytes.
"""
import os,re
root='.'
tot={}
for dp,dn,fn in os.walk(root):
    if '.git' in dp: continue
    for f in fn:
        if not f.endswith('.s'): continue
        p=os.path.join(dp,f)
        n=0
        for line in open(p,encoding='latin-1'):
            if ';' in line:   # has a comment -> counted as documented
                code=line.split(';')[0]
                if code.strip():
                    continue
                else:
                    continue
            l=line.strip()
            m=re.match(r'^(?:\S+:\s*)?\.(byte|hword|short|word|long|int)\b(.*)$',l)
            if not m: continue
            d,ops=m.group(1),m.group(2)
            cnt=len([x for x in ops.split(',') if x.strip()])
            n+=cnt*{'byte':1,'hword':2,'short':2,'word':4,'long':4,'int':4}[d]
        if n: tot[p]=n
for p,n in sorted(tot.items(),key=lambda kv:-kv[1])[:30]:
    print(f'{n:9d}  {p}')
print('TOTAL uncommented data bytes', sum(tot.values()))
import os,re
root='.'
tot={}
for dp,dn,fn in os.walk(root):
    if '.git' in dp: continue
    for f in fn:
        if not f.endswith('.s'): continue
        p=os.path.join(dp,f)
        n=0
        for line in open(p,encoding='latin-1'):
            if ';' in line:   # has a comment -> counted as documented
                code=line.split(';')[0]
                if code.strip():
                    continue
                else:
                    continue
            l=line.strip()
            m=re.match(r'^(?:\S+:\s*)?\.(byte|hword|short|word|long|int)\b(.*)$',l)
            if not m: continue
            d,ops=m.group(1),m.group(2)
            cnt=len([x for x in ops.split(',') if x.strip()])
            n+=cnt*{'byte':1,'hword':2,'short':2,'word':4,'long':4,'int':4}[d]
        if n: tot[p]=n
for p,n in sorted(tot.items(),key=lambda kv:-kv[1])[:30]:
    print(f'{n:9d}  {p}')
print('TOTAL uncommented data bytes', sum(tot.values()))
