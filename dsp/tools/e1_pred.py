words = {
 54:0x080016000B,60:0x009218D15B,61:0x001218D05B,62:0x0801026825,63:0x02A79051C3,
 64:0x0C40A80445,65:0x020018F1C1,66:0x000018C107,67:0x0980520402,68:0x009218C19B,
 69:0x0801090821,70:0x02A61850C7,71:0x0C41900446,72:0x0000106087,73:0x0E30C00404,
 74:0x0C169AB000,75:0x082E80F000,76:0x0C00984000,77:0x0859086822,78:0x0A3CD9F287,
 79:0x00122FF1CE,80:0x01042001CE,81:0x0102200000,152:0x0880160000,153:0x060210E000,
 200:0x088013000B }
hi12=lambda w:(w>>24)&0xfff
cl4 =lambda w:(w>>20)&0xf
ad8 =lambda w:(w>>12)&0xff
lo12=lambda w:w&0xfff
SRC =lambda w:(w>>6)&0x1f
ACT =lambda w:w&0x1f
cfmt=lambda w:(hi12(w)&0xf00)==0xc00
esc =lambda w:(hi12(w)&0x800)!=0
isdram=lambda w: esc(w) and cl4(w)==1 and not cfmt(w)
ptrmode=lambda w:(w>>5)&1
f31=lambda w:(hi12(w)>>1)&7
HI_ST=0x10; HI_B7=0x80
ANCH_SRC={0x07,0x10,0x19,0x1a}
ANCH_ACT={0x00,0x07,0x12,0x13,0x14,0x15,0x19}
def alu_decoded(w):
    if cfmt(w): return False
    cl=cl4(w)
    if cl not in (2,8,0xa): return False
    if lo12(w)&0x800: return False
    if ptrmode(w): return False
    if SRC(w) not in ANCH_SRC or ACT(w) not in ANCH_ACT: return False
    if (hi12(w)&HI_ST) and (cl&7)!=2: return False
    if ACT(w)==0x07 and (cl&7)!=2: return False
    if (hi12(w)&HI_ST) and (hi12(w)&HI_B7) and f31(w)!=2: return False
    f=f31(w)
    if f in (0,1): return True
    if f==2: return cl==8
    return False
def reaches(w):
    """does the word reach the operand fetch (m_last_l = L)?"""
    if alu_decoded(w): return (True,'decoded')
    # speculative branch
    if cfmt(w): return (False,'c_format')
    if lo12(w)&0x800: return (False,'bit-11 alt encoding')
    if lo12(w)==0x827: return (False,'ovc load')
    if isdram(w): return (True,'delay word -> recursive exec_alu')
    cl=cl4(w); hi_esc=(hi12(w)&0xF00)==0xA00
    if cl==0xC or cl==0xD: return (True,'presentation, deferred (mask bit 3)')
    if cl==6: return (False,'class 6 table lookup')
    if w==0 or cl==5 or (hi_esc and lo12(w) in (0x015,0x041)): return (False,'NOP/class5/escape')
    return (True,'speculative fallthrough')
print(f"{'iw':>4} {'word':>10} {'hi12':>4} {'cl':>2} {'ad8':>3} {'lo12':>4} {'SRC':>4} {'ACT':>4} {'f31':>3}  reach  why")
n=0
for iw in sorted(words):
    w=words[iw]; r,why=reaches(w)
    if 60<=iw<=81 and r: n+=1
    print(f"{iw:>4} {w:010X} {hi12(w):03X} {cl4(w):>2} {ad8(w):02X} {lo12(w):03X}  {SRC(w):02X}   {ACT(w):02X}   {f31(w):>3}   {'Y' if r else 'n'}    {why}")
print("epilogue slots reaching the fetch:",n,"of 22")
