#!/usr/bin/env python3
"""§220 pre-flight: PROGRAMMATIC audit of speculative-mask bit 26.

Three checks demanded by the brief, none of them a spelling grep:
  1. enumerate EVERY mask literal in upd6383.{cpp,h} and decide whether bit 26
     is clear in the shipped default;
  2. count the SITES that test bit 26 (must be exactly 1, else confounded);
  3. decide whether the bit-26 site maintains a fired counter AND whether that
     counter is emitted by the device's report (rule 8).

Method: tokenise the C++ (strip comments and string literals FIRST, so that
prose in comments can never be mistaken for code), then find every integer
literal that participates in a bitwise-AND with the speculative mask variable.
"""
import re, sys, collections

CPP = "/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.cpp"
H   = "/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.h"

def strip_comments(src):
    """Remove // and /* */ comments and string/char literals, preserving offsets
    (replaced by spaces) so line numbers and positions stay exact."""
    out = list(src)
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '/' and i + 1 < n and src[i+1] == '/':
            j = src.find('\n', i)
            j = n if j < 0 else j
            for k in range(i, j): out[k] = ' '
            i = j
        elif c == '/' and i + 1 < n and src[i+1] == '*':
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            for k in range(i, j):
                if out[k] != '\n': out[k] = ' '
            i = j
        elif c in '"\'':
            q = c; j = i + 1
            while j < n:
                if src[j] == '\\': j += 2; continue
                if src[j] == q: j += 1; break
                j += 1
            for k in range(i, min(j, n)):
                if out[k] != '\n': out[k] = ' '
            i = j
        else:
            i += 1
    return ''.join(out)

def lineno(src, pos):
    return src.count('\n', 0, pos) + 1

def parse_int(tok):
    t = tok.replace("'", "").rstrip('uUlL')
    try:
        return int(t, 0)
    except ValueError:
        return None

src_cpp = open(CPP, encoding='utf-8', errors='replace').read()
src_h   = open(H,   encoding='utf-8', errors='replace').read()
code_cpp = strip_comments(src_cpp)
code_h   = strip_comments(src_h)

# ---------------------------------------------------------------- discover the
# mask variable and the shipped default, from the code, not from a guess.
# A "mask variable" = any identifier that appears on both sides of a bitwise AND
# with a wide integer literal.  Find candidates first.
ident_and_lit = re.compile(
    r'\b([A-Za-z_]\w*)\s*&\s*(0[xX][0-9a-fA-F\']+|\d[\d\']*)[uUlL]*'
    r'|(0[xX][0-9a-fA-F\']+|\d[\d\']*)[uUlL]*\s*&\s*\b([A-Za-z_]\w*)')

cand = collections.Counter()
for f, code in (("cpp", code_cpp), ("h", code_h)):
    for m in ident_and_lit.finditer(code):
        var = m.group(1) or m.group(4)
        lit = m.group(2) or m.group(3)
        v = parse_int(lit)
        if v is None: continue
        # a speculative-mask literal is a single bit or a wide value
        cand[var] += 1

print("=" * 78)
print("CANDIDATE mask variables (identifier AND-ed with an integer literal):")
for var, n in cand.most_common(8):
    print(f"    {var:<24} {n:4d} AND-sites")

# pick the variable with the most single-bit AND partners -- that is the spec mask
def single_bit(v):
    return v != 0 and (v & (v - 1)) == 0

bitvar = collections.Counter()
for f, code in (("cpp", code_cpp), ("h", code_h)):
    for m in ident_and_lit.finditer(code):
        var = m.group(1) or m.group(4)
        v = parse_int(m.group(2) or m.group(3))
        if v is not None and single_bit(v) and v >= 2:
            bitvar[var] += 1
print("\nCANDIDATES weighted by SINGLE-BIT partners:")
for var, n in bitvar.most_common(8):
    print(f"    {var:<24} {n:4d} single-bit AND-sites")
MASKVAR = bitvar.most_common(1)[0][0]
print(f"\n==> mask variable determined from the code: {MASKVAR}")

# ---------------------------------------------------------------- CHECK 1
# every mask literal, and the shipped default
print("\n" + "=" * 78)
print("CHECK 1 -- every mask literal, and bit 26 in the shipped default")
print("=" * 78)

# the shipped default: the widest literal assigned to something whose name
# relates to the mask var, discovered structurally (assignment / initialiser).
wide = []
lit_re = re.compile(r'0[xX][0-9a-fA-F\']{9,}[uUlL]*')
for f, code, raw in (("cpp", code_cpp, src_cpp), ("h", code_h, src_h)):
    for m in lit_re.finditer(code):
        v = parse_int(m.group(0))
        if v is None: continue
        ln = lineno(code, m.start())
        ctx = raw.split('\n')[ln - 1].strip()
        wide.append((f, ln, m.group(0), v, ctx))
print("\nWIDE literals (>=9 hex digits) anywhere in the two files:")
for f, ln, tok, v, ctx in wide:
    print(f"    {f}:{ln:<5} {tok:<22} bit26={'SET' if (v>>26)&1 else 'clear'}   {ctx[:70]}")

# the shipped default = the INITIALISER of the mask variable, found structurally
DEFAULT = None
init_re = re.compile(r'\b' + re.escape(MASKVAR) + r'\s*=\s*(0[xX][0-9a-fA-F\']+|\d[\d\']*)[uUlL]*')
for f, code, raw in (("h", code_h, src_h), ("cpp", code_cpp, src_cpp)):
    for m in init_re.finditer(code):
        v = parse_int(m.group(1))
        ln = lineno(code, m.start())
        ctx = raw.split('\n')[ln - 1].strip()
        if DEFAULT is None:
            DEFAULT = (f, ln, m.group(1), v, ctx)
        print(f"  initialiser/assignment of {MASKVAR}: {f}:{ln}  {m.group(1)}  |  {ctx[:70]}")
# every runtime write to the mask (env overrides etc.)
print("\n  ALL runtime references to the mask variable:")
for f, code, raw in (("cpp", code_cpp, src_cpp), ("h", code_h, src_h)):
    for m in re.finditer(r'\b' + re.escape(MASKVAR) + r'\b\s*(=[^=]|\+=|\|=|&=)', code):
        ln = lineno(code, m.start())
        print(f"    {f}:{ln:<5} {raw.split(chr(10))[ln-1].strip()[:90]}")

# all single-bit mask literals AND-ed against the mask var, with their bit index
site_re = re.compile(re.escape(MASKVAR) + r'\s*&\s*(0[xX][0-9a-fA-F\']+|\d[\d\']*)[uUlL]*'
                     r'|(0[xX][0-9a-fA-F\']+|\d[\d\']*)[uUlL]*\s*&\s*' + re.escape(MASKVAR))
bits = collections.defaultdict(list)
for f, code, raw in (("cpp", code_cpp, src_cpp), ("h", code_h, src_h)):
    for m in site_re.finditer(code):
        v = parse_int(m.group(1) or m.group(2))
        if v is None: continue
        ln = lineno(code, m.start())
        ctx = raw.split('\n')[ln - 1].strip()
        if single_bit(v):
            bits[v.bit_length() - 1].append((f, ln, hex(v), ctx))
        else:
            bits[('multi', hex(v))].append((f, ln, hex(v), ctx))

print(f"\nMask BITS tested against {MASKVAR}: {sorted(b for b in bits if isinstance(b,int))}")
multi = [b for b in bits if not isinstance(b, int)]
if multi:
    print(f"NON-single-bit masks tested against {MASKVAR}: {multi}")
    for b in multi:
        for f, ln, hx, ctx in bits[b]:
            print(f"    {f}:{ln}  {hx}  {ctx[:70]}")

if DEFAULT:
    f, ln, tok, v, ctx = DEFAULT
    print(f"\nSHIPPED DEFAULT literal: {tok} at {f}:{ln}")
    print(f"    context: {ctx}")
    print(f"    brief claims 0xB910E446A39B440F -> "
          f"{'MATCH' if v == 0xB910E446A39B440F else 'MISMATCH (%s)' % hex(v)}")
    print(f"    bit 26 (0x4000000) in default: "
          f"{'SET  <-- CHECK 1 FAILS' if (v >> 26) & 1 else 'CLEAR  <-- CHECK 1 PASSES'}")
    setbits = [i for i in range(64) if (v >> i) & 1]
    print(f"    bits SET in default: {setbits}")
    print(f"    bits TESTED in code but not set in default: "
          f"{sorted(b for b in bits if isinstance(b,int) and not (v>>b)&1)}")
else:
    print("\n!! no wide default literal found -- CHECK 1 INCONCLUSIVE")

# ---------------------------------------------------------------- CHECK 2
print("\n" + "=" * 78)
print("CHECK 2 -- how many SITES test bit 26 (0x4000000)?")
print("=" * 78)
TARGET = 1 << 26
# (a) sites AND-ing the mask var with exactly 0x4000000
direct = bits.get(26, [])
print(f"\n(a) `{MASKVAR} & <literal==0x4000000>` sites: {len(direct)}")
for f, ln, hx, ctx in direct:
    print(f"    {f}:{ln}  {ctx[:90]}")
# (b) ANY literal anywhere in the two files whose value has bit 26 set
print("\n(b) EVERY integer literal in the two files with bit 26 set "
      "(catches multi-bit masks that would confound the arm):")
anylit = re.compile(r'\b(0[xX][0-9a-fA-F\']+|\d[\d\']{2,})[uUlL]*')
hits = []
for f, code, raw in (("cpp", code_cpp, src_cpp), ("h", code_h, src_h)):
    for m in anylit.finditer(code):
        v = parse_int(m.group(1))
        if v is None or v == 0: continue
        if (v >> 26) & 1:
            ln = lineno(code, m.start())
            hits.append((f, ln, m.group(1), v, raw.split('\n')[ln-1].strip()))
for f, ln, tok, v, ctx in hits:
    kind = "single-bit" if single_bit(v) else f"multi-bit({bin(v).count('1')} bits)"
    print(f"    {f}:{ln:<5} {tok:<22} {kind:<20} {ctx[:60]}")
print(f"\n    total literals with bit 26 set: {len(hits)}")
print(f"    of which exactly 0x4000000: {sum(1 for h in hits if h[3]==TARGET)}")
verdict2 = (len(direct) == 1)
print(f"    CHECK 2: {'PASSES (exactly one gate site)' if verdict2 else 'FAILS -- CONFOUNDED'}")

# ---------------------------------------------------------------- CHECK 3
print("\n" + "=" * 78)
print("CHECK 3 -- does the bit-26 gate keep a FIRED COUNT, and is it REPORTED?")
print("=" * 78)
if direct:
    f, ln, hx, ctx = direct[0]
    raw = (src_cpp if f == "cpp" else src_h).split('\n')
    lo, hi = max(0, ln - 2), min(len(raw), ln + 12)
    print(f"\n  body of the gate at {f}:{ln}")
    for i in range(lo, hi):
        print(f"    {i+1:5d}| {raw[i]}")
    # find identifiers incremented inside the guarded block
    block = '\n'.join(strip_comments('\n'.join(raw[ln-1:hi])).split('\n'))
    inc = re.findall(r'\b(m_\w+)\s*\+\+', block)
    print(f"\n  counters incremented inside the guarded block: {sorted(set(inc))}")
    for cname in sorted(set(inc)):
        # is it emitted anywhere by logerror/printf-family?  find its other uses
        uses = []
        for ff, code, rw in (("cpp", code_cpp, src_cpp), ("h", code_h, src_h)):
            for m in re.finditer(r'\b' + re.escape(cname) + r'\b', code):
                l2 = lineno(code, m.start())
                uses.append((ff, l2, rw.split('\n')[l2-1].strip()))
        print(f"\n  all code uses of {cname}: {len(uses)}")
        for ff, l2, c in uses:
            print(f"    {ff}:{l2:<5} {c[:100]}")
        # a logerror() call can span lines: check a +-3 line window around each use
        emitted = False
        for ff, l2, c in uses:
            rw = (src_cpp if ff == "cpp" else src_h).split('\n')
            win = '\n'.join(rw[max(0, l2 - 4):min(len(rw), l2 + 3)])
            if 'logerror' in win or 'printf' in win:
                emitted = True
                print(f"  ==> REPORT EMISSION found near {ff}:{l2}:")
                for k in range(max(0, l2 - 3), min(len(rw), l2 + 2)):
                    print(f"      {k+1:5d}| {rw[k]}")
                break
        print(f"  ==> fired count emitted by a log/printf statement: {emitted}")
else:
    print("  no gate site found -- CHECK 3 INCONCLUSIVE")
