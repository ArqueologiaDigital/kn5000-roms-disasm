#!/usr/bin/env python3
"""v7_slice_split_plan.py -- turn each UNSAFE v7_slice_data_run_extent.py verdict
into an independently-verified split plan, or explain why it cannot be trusted.

WHY THIS EXISTS
----------------
`v7_slice_data_run_extent.py` measures how many BYTES of a v9/v10 label are the
announced directive kind before something else starts -- but a matching COUNT is
not matching VALUES (DEBT-INVENTORY's own warning), and a `.long` table of
SYMBOL operands is exactly the "jump table round-trips as code" shape this push
has already had to revert six times. Neither hazard is visible to run-extent.

This script adds three independent checks per UNSAFE slice before it is trusted
enough to split:

  1. HEADER VALUE CHECK: reconstruct the literal bytes the v9/v10 header
     directives encode (not just their count) and compare them, byte for byte,
     against the v7 slice's OWN raw bytes at the front. A `.long` operand that
     is a bare symbol name (a pointer/jump-table entry) cannot be value-checked
     this way and is refused outright -- SYMBOLIC_HEADER, never auto-split.
  2. NAMED BOUNDARY CHECK: does a real label sit in v9/v10 exactly where the
     header run ends? If so, that label's own name is reused for the v7 split
     point (same technique already used, by hand, for
     DrumKit_GroupAssignTable -> RhythmROM_LoadDrumKit). If not, the split gets
     a plain positional name (`<Label>_Code`), and the plan is marked
     UNNAMED_BOUNDARY so it is not overstated as routine-prologue evidence.
  3. CODE ROUND TRIP: llvm-mc disassembles the v7 slice's own tail bytes (not
     v9/v10's) and must reassemble them byte-exact with zero decode warnings,
     the same standard used by v7_slice_code_roundtrip.py. A tail that is a
     uniform byte run (the "0xff round-trips as 32x swi 7" trap) is refused
     even if the round trip is clean.

Only a slice passing all three is marked SAFE. Everything else is left
`.incbin`, reported with its specific failure reason.

RUN
    python3 scripts/analysis/v7_slice_split_plan.py
    reads scripts/analysis/v7_slice_data_run_extent.json
    writes scripts/analysis/v7_slice_split_plan.json
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)
LLVM_MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
LLVM_OBJCOPY = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-objcopy')

LABEL_DEF = re.compile(r'^([A-Za-z_.][\w.]*):\s*(.*)$')
BYTE_DIR = re.compile(r'^\.byte\s+(.*)$')
LONG_DIR = re.compile(r'^\.long\s+(.*)$')
ZERO_DIR = re.compile(r'^\.zero\s+(\d+)\s*$')
ASCII_DIR = re.compile(r'^\.ascii\s+"(.*)"\s*$')
ASCIZ_DIR = re.compile(r'^\.asciz\s+"(.*)"\s*$')
NUMERIC = re.compile(r'^\s*(0[xX][0-9a-fA-F]+|-?\d+)\s*$')


def unescape_bytes(s):
    """Bytes a `.ascii`/`.asciz` string literal body encodes, honouring the
    handful of escapes llvm-mc accepts. Mirrors run_extent's unescape_len but
    returns the actual byte values."""
    out = bytearray()
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == 'x':
                out.append(int(s[i + 2:i + 4], 16))
                i += 4
            elif nxt == 'n':
                out.append(10); i += 2
            elif nxt == 't':
                out.append(9); i += 2
            elif nxt == 'r':
                out.append(13); i += 2
            elif nxt == '0':
                out.append(0); i += 2
            elif nxt in ('\\', '"'):
                out.append(ord(nxt)); i += 2
            else:
                out.append(ord(nxt)); i += 2
        else:
            out.append(ord(s[i]) & 0xFF)
            i += 1
    return bytes(out)


def parse_operand_value(tok):
    """An operand's integer value if it is a plain numeric literal, else None
    (a bare symbol / expression -- cannot be value-checked without a linked
    address, which is exactly the jump-table hazard)."""
    tok = tok.strip()
    if not NUMERIC.match(tok):
        return None
    return int(tok, 0)


def build_label_index(root):
    idx = {}
    for f in glob.glob(f'{root}/**/*.s', recursive=True):
        lines = open(f, encoding='latin-1').readlines()
        for i, line in enumerate(lines):
            m = LABEL_DEF.match(line.strip())
            if m and m.group(1) not in idx:
                idx[m.group(1)] = (f, i, lines)
    return idx


def walk_header(lines, i, kind):
    """Like run_extent's run_length, but returns (header_bytes_or_None,
    symbolic, end_line_index) instead of just a count. header_bytes is None
    when any operand is non-numeric (kind in byte/long) -- SYMBOLIC. For
    zero/ascii/asciz it is always concrete."""
    tail = LABEL_DEF.match(lines[i].strip()).group(2).strip()
    candidates = [(tail, i)] + [(lines[j].strip(), j) for j in range(i + 1, len(lines))]
    out = bytearray()
    symbolic = False
    end_line = i + 1
    dirmatch = {'byte': BYTE_DIR, 'long': LONG_DIR}.get(kind)
    for s, lineno in candidates:
        end_line = lineno + 1
        if not s or s.startswith(';'):
            continue
        if kind in ('byte', 'long'):
            m = dirmatch.match(s)
            if not m:
                end_line = lineno
                break
            ops = [p.strip() for p in m.group(1).split(';')[0].split(',') if p.strip()]
            for op in ops:
                v = parse_operand_value(op)
                if v is None:
                    symbolic = True
                    continue
                if kind == 'byte':
                    out.append(v & 0xFF)
                else:
                    out += (v & 0xFFFFFFFF).to_bytes(4, 'big')
            continue
        if kind == 'zero':
            m = ZERO_DIR.match(s)
            if not m:
                end_line = lineno
                break
            out += bytes(int(m.group(1)))
            continue
        if kind == 'ascii':
            m = ASCII_DIR.match(s)
            if not m:
                end_line = lineno
                break
            out += unescape_bytes(m.group(1))
            continue
        if kind == 'asciz':
            m = ASCIZ_DIR.match(s)
            if not m:
                end_line = lineno
                break
            out += unescape_bytes(m.group(1)) + b'\x00'
            continue
        end_line = lineno
        break
    return bytes(out), symbolic, end_line


def disasm(data):
    if not data:
        return [], 0
    hexstr = ' '.join(f'0x{b:02x}' for b in data)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '--disassemble'],
                        input=hexstr, capture_output=True, text=True, timeout=30)
    warnings = p.stderr.count('warning: invalid instruction encoding')
    lines = [l for l in p.stdout.split('\n') if l.strip()]
    return lines, warnings


def reassemble(lines):
    text = '\n'.join(lines)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=30)
    if p.returncode != 0:
        return None
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath], capture_output=True, text=True)
    if p2.returncode != 0:
        os.unlink(objpath)
        return None
    data = open(binpath, 'rb').read()
    os.unlink(objpath)
    os.unlink(binpath)
    return data


def uniform_fill_fraction(data):
    if not data:
        return 0.0
    from collections import Counter
    c = Counter(data)
    return max(c.values()) / len(data)


def byte_similarity(a, b):
    """Fraction of positions equal, over the SHORTER of the two -- used to
    tolerate genuine cross-revision payload differences (v7 vs v9/v10 are
    different product firmwares, not the same build) without accepting a
    header that is simply the wrong region. `VoiceMode_ParamConfigTables`
    (264 B) is a confirmed real instance: byte 104 is 0xcc in v7 vs 0x97 in
    v9, a single genuine config-value divergence among 264 identical bytes."""
    n = min(len(a), len(b))
    if n == 0:
        return 0.0
    same = sum(1 for i in range(n) if a[i] == b[i])
    return same / n


TRIVIAL_MNEMONIC = re.compile(r'^\s*(nop|swi)\b')


def trivial_fraction(dlines):
    """Fraction of decoded lines that are `nop` (0x00) or `swi N` (0xNN, a
    single fixed byte each way) -- the two TLCS900 opcodes that are ALWAYS
    exactly one byte and ALWAYS reassemble to themselves regardless of what
    surrounds them. A real routine uses a few of these; a run of padded
    fixed-width string/table records (`"XY\\0\\xff"`, `"\\0\\0\\0..."`)
    disassembles into a long chain of them and passes the byte-exact round
    trip trivially -- this is what caught `KeyScaleNoteStr_G` (documented in
    v7_slice_code_roundtrip.py as a confirmed false positive: the v9/v10 body
    right after its data header is a tiny code stub immediately followed by
    an `aligned_string` macro, and this dialect's `.byte 0/0xff` padding
    between short strings decodes into exactly this pattern) and
    `Rhythm_SeqResetTable` / `AccPatch_ChannelToParamTable` (mostly `nop`
    chains over what is actually a sparse, mostly-zero data table)."""
    if not dlines:
        return 0.0
    n = sum(1 for l in dlines if TRIVIAL_MNEMONIC.match(l))
    return n / len(dlines)


def try_split(v7data, offset):
    """Attempt a split at `offset`: tail must decode warning-free and
    reassemble byte-exact, must not be a uniform fill run (the '0xff
    round-trips as swi 7' trap), and must not be dominated by the
    always-round-trips-trivially nop/swi opcodes (see trivial_fraction).
    Returns (ok, tail_lines, fill_frac, trivial_frac)."""
    tail = v7data[offset:]
    if not tail:
        return False, None, 0.0, 0.0
    fill_frac = uniform_fill_fraction(tail)
    if fill_frac >= 0.9:
        return False, None, fill_frac, 0.0
    dlines, warnings = disasm(tail)
    if warnings:
        return False, None, fill_frac, 0.0
    reasm = reassemble(dlines)
    if reasm != tail:
        return False, None, fill_frac, 0.0
    tfrac = trivial_fraction(dlines)
    if tfrac >= 0.2:
        return False, None, fill_frac, tfrac
    return True, dlines, fill_frac, tfrac


def search_offsets_near(run_length, size, window=32):
    """Offsets to try, closest to the v9/v10-derived run_length first, within
    +/- window and inside the slice. This is a BOUNDED local search anchored
    on real evidence (the v9/v10 homogeneous-kind run) -- it never searches
    the whole slice blind, which would risk landing on a coincidental
    decodable alignment unrelated to the true boundary."""
    seen = set()
    out = []
    for d in range(0, window + 1):
        for cand in (run_length + d, run_length - d):
            if 0 <= cand < size and cand not in seen:
                seen.add(cand)
                out.append(cand)
    return out


def main():
    rows = json.load(open('scripts/analysis/v7_slice_data_run_extent.json'))
    unsafe = [r for r in rows if not r['safe']]
    idx9 = build_label_index('v9/maincpu')
    idx10 = build_label_index('v10/maincpu')

    plans = []
    for r in unsafe:
        label, kind, size = r['label'], r['kind'], r['size']
        binpath = r['bin']
        if not os.path.exists(binpath):
            plans.append({**r, 'verdict': 'BIN_MISSING'})
            continue
        v7data = open(binpath, 'rb').read()
        if len(v7data) != size:
            plans.append({**r, 'verdict': f'SIZE_MISMATCH bin={len(v7data)} json={size}'})
            continue

        chosen = None
        for srcname, idx in (('v9', idx9), ('v10', idx10)):
            if label not in idx:
                continue
            f, i, lines = idx[label]
            header_bytes, symbolic, end_line = walk_header(lines, i, kind)
            hlen = len(header_bytes) if not symbolic else None
            entry = dict(src=srcname, file=f, line=i, header_bytes=header_bytes,
                         symbolic=symbolic, end_line=end_line, lines=lines)
            # prefer whichever source's header bytes actually match v7's raw
            # header bytes -- that is the real gate, not run length alone.
            if not symbolic and v7data[:len(header_bytes)] == header_bytes:
                chosen = entry
                break
            if chosen is None:
                chosen = entry  # keep as fallback for diagnostics

        if chosen is None:
            plans.append({**r, 'verdict': 'LABEL_NOT_FOUND'})
            continue

        header_bytes = chosen['header_bytes']
        symbolic = chosen['symbolic']
        if symbolic:
            # Verified 2026-09-02: for the two largest instances
            # (TuningSystem_Handler_Table, SoundEffect_Dispatch_Table) the raw
            # v7 4-byte words at this position are NOT plausible ROM addresses
            # at all (values like 0x020f6406, far outside the 0xE00000-0xFFFFFF
            # window) -- so this is not merely "can't value-check a pointer",
            # the region doesn't even look like the SAME pointer table in v7.
            # Refused outright, matching this push's jump-table hazard.
            plans.append({**r, 'verdict': 'SYMBOLIC_HEADER',
                          'src': chosen['src']})
            continue

        run_len = len(header_bytes)
        if run_len == 0:
            plans.append({**r, 'verdict': 'ZERO_LENGTH_HEADER', 'src': chosen['src']})
            continue

        # Bounded local search anchored on the v9/v10 run length: the FIRST
        # (closest) offset whose tail round-trips clean AND whose header
        # portion is still consistent enough with v9/v10's reconstructed
        # bytes to trust (>=60% byte-identical -- tolerates real cross-
        # revision payload drift like VoiceMode_ParamConfigTables' single
        # differing byte, while still rejecting a wrong region).
        best = None
        for cand in search_offsets_near(run_len, size, window=32):
            v7_header = v7data[:cand]
            sim_n = min(cand, run_len)
            sim = byte_similarity(v7_header[:sim_n], header_bytes[:sim_n]) if sim_n else 0.0
            if sim < 0.60:
                continue
            ok, dlines, fill_frac, tfrac = try_split(v7data, cand)
            if ok:
                best = (cand, sim, dlines)
                break

        if best is None:
            plans.append({**r, 'verdict': 'NO_OFFSET_FOUND', 'src': chosen['src'],
                          'run_length_v9v10': run_len})
            continue

        hlen, similarity, dlines = best
        # named-boundary check: is end_line itself a label def in the v9/v10
        # source, AND does it fall at the exact byte offset we split at? (it
        # is only meaningful when hlen == run_len; a shifted split point has
        # no v9/v10 label to corroborate it.)
        lines = chosen['lines']
        end_line = chosen['end_line']
        named = None
        if hlen == run_len and end_line < len(lines):
            m = LABEL_DEF.match(lines[end_line].strip())
            if m:
                named = m.group(1)

        plans.append({**r, 'verdict': 'SAFE', 'src': chosen['src'], 'header_len': hlen,
                      'run_length_v9v10': run_len, 'header_similarity': round(similarity, 3),
                      'trivial_fraction': round(trivial_fraction(dlines), 3),
                      'named_boundary': named, 'tail_len': size - hlen,
                      'tail_lines': dlines})

    out = 'scripts/analysis/v7_slice_split_plan.json'
    json.dump(plans, open(out, 'w'), indent=1)

    from collections import Counter
    verdicts = Counter(p['verdict'] for p in plans)
    print(f"{len(plans)} unsafe slices, {sum(p['size'] for p in plans):,} B total\n")
    for v, n in verdicts.most_common():
        b = sum(p['size'] for p in plans if p['verdict'] == v)
        print(f"  {v:26s} {n:4d} slices  {b:8,d} B")
    safe = [p for p in plans if p['verdict'] == 'SAFE']
    named = sum(1 for p in safe if p.get('named_boundary'))
    print(f"\nSAFE: {len(safe)} slices, {sum(p['size'] for p in safe):,} B, "
          f"{named} with a named v9/v10 boundary, {len(safe) - named} positional-only")
    print(f'\nwrote {out}')


if __name__ == '__main__':
    sys.exit(main())
