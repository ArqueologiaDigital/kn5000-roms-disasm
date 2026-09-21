#!/usr/bin/env python3
"""WHICH work-RAM bytes does the WSA1 menu system let the user edit, and under
which printed label?  (the SEARCH half of `sysex_param_screen_names.py`)

QUESTION IT ANSWERS

A menu screen is a stream of compact records.  A caption is
   [len][x][y][ASCII...]         (len = 3 + length of the text)
An editable field is
   [kind][len][addr lo][addr hi][mask][shift] ... [col][row]{[digits]}
with `addr` a 16-bit work-RAM address and `shift` the bit position of the
lowest set bit of `mask`.  Caption and field carry the SAME row, so the caption
on a field's row is the label the instrument prints for that RAM byte.

This script SEARCHES; it proves nothing on its own.  Every pairing it turns up
has to be pinned as a literal byte string in `sysex_param_screen_names.py`
before it may be called ESTABLISHED.  It finds only the fields that name their
RAM byte as a 16-bit LITERAL: a per-part screen addresses the part record
through an index register instead, and does not show up here at all.

SIGNAL BEING READ
  Both program images, scanned exhaustively for the field-record shape above
  with `addr` inside 0x7600..0x7FFF and `shift` equal to `mask`'s low bit.

RUN
  python3 wsa1/notes/sysex-probes/sysex_screen_fields.py

PASS CRITERION
  It is a search, so there is no pass/fail -- it prints what it finds.  The
  rows worth keeping are the ones whose `y=` column is not None, because those
  are the ones a caption on the same row actually names.
"""
import os, sys
HERE=os.path.dirname(os.path.abspath(__file__))
ROMS=os.path.join(HERE,"..","..","original_ROMs")
IMG={"prom_b":(0xF00000,open(os.path.join(ROMS,"wsa1_prom_b.ic13"),"rb").read()),
     "prom_a":(0xF80000,open(os.path.join(ROMS,"wsa1_prom_a.ic12"),"rb").read())}
LO,HI=0x7600,0x8000
def low_bit(m):
    b=0
    while not (m>>b)&1: b+=1
    return b
def captions(img,base,lo,hi):
    out=[];j=lo
    while j<hi:
        ln=img[j]
        if 5<=ln<=0x30 and j+ln<=len(img):
            x,y=img[j+1],img[j+2]; t=img[j+3:j+ln]
            if y<0x24 and len(t)==ln-3 and t and all(0x20<=c<0x7f for c in t) \
               and sum(1 for c in t if c!=0x20)>=2:
                out.append((base+j,x,y,t.decode("latin1"))); j+=ln; continue
        j+=1
    return out
FIELDS=[]
for nm,(base,img) in IMG.items():
    for i in range(len(img)-0x20):
        k=img[i]
        if k>3: continue
        ln=img[i+1]
        if not (8<=ln<=0x20) or i+ln>len(img): continue
        a=int.from_bytes(img[i+2:i+4],"little")
        if not (LO<=a<HI): continue
        mask,sh=img[i+4],img[i+5]
        if mask==0 or sh!=low_bit(mask): continue
        FIELDS.append((nm,base+i,k,ln,a,mask,sh,img[i+ln-3],img[i+ln-2],img[i+ln-1]))
print("%d candidate field records"%len(FIELDS))
prev=None
for nm,ad,k,ln,a,mask,sh,p3,p2,p1 in FIELDS:
    base,img=IMG[nm]; off=ad-base
    caps=captions(img,base,max(0,off-0x400),off+0x40)
    ys={}
    for c in caps: ys.setdefault(c[2],[]).append(c)
    y=None
    for cand in (p1,p2):
        if cand in ys: y=cand; break
    lab="-"
    if y is not None:
        row=sorted(ys[y],key=lambda c:c[1])
        lab=" | ".join("%r@x%d"%(c[3],c[1]) for c in row)
    if prev is None or ad-prev>0x80:
        print("\n---- screen near 0x%06X (%s)"%(ad,nm))
        hdr=[c for c in caps if c[2]<6]
        print("     header: %s"%("; ".join(repr(c[3]) for c in hdr[-4:])))
    print("  0x%06X k=%d len=%2d addr=0x%04X mask=0x%02X sh=%d y=%s :: %s"%(
        ad,k,ln,a,mask,sh,y,lab))
    prev=ad
