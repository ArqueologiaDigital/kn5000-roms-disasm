#!/usr/bin/env python3
"""convert_decoder_unblocked_islands.py -- convert CODE-flanked isolated
.byte lines that the NEW TLCS900 decoder (SriRR register-indexed family +
ERP register-direct forms, llvm-project commit 662b3929a72a, 2026-09-02
01:52) can now decode where the OLD one returned Fail unconditionally.

QUESTION ANSWERED
  v9_v10_undisassembled_census.py's --islands mode measures how many literal
  `.byte` runs sit flanked by real instructions on both sides (single
  TLCS-900 instructions llvm-mc could not spell) -- 14,724 B on v10 as of
  2026-09-01/09-02, explicitly OUT OF SCOPE for the confirmed-region lanes
  because re-framing that shape is the ISLANDS lane's territory. That
  measurement uses MAME's unidasm for its CODE-likelihood scoring, so it is
  UNCHANGED by any llvm-mc decoder fix (confirmed by re-running --judge/
  --islands after this session's decoder fix landed: same 5 rejects/348 B on
  --judge, same shape on --islands).

  What DOES change: some of those single-instruction islands are literally
  bytes from the SriRR/ERP families the decoder could not spell until today.
  This script finds every CODE-flanked isolated `.byte` line in a tag's
  maincpu tree, tries `llvm-mc --disassemble` on it, and -- only if the
  decode is warning-free AND reassembling the decoded text reproduces the
  ORIGINAL BYTES EXACTLY (never the `--show-encoding` field, which can be a
  shorter re-encode -- see the lane brief's measurement trap) -- replaces
  that one line with the decoded instruction(s).

WHY THIS DOES NOT DUPLICATE convert_region.py / convert_interrupted_region.py
  Both of those operate on a census-flagged, HAND-AUDITED >=64 B DATA region
  and decode via unidasm + a hand-written mnemonic translation table
  (convert_code_bytes.py), falling back to `llvm-mc --disassemble` only when
  that table has no rule -- see convert_code_bytes.py's unidasm_to_llvm(),
  last branch. A prior session (611d6950/353b6796) recorded "the decoder fix
  did not unblock anything here" for THAT pipeline, correctly, for the state
  of the decoder at the time (ad8129f59880, before SriRR/ERP existed) --
  this script targets the ISLANDS shape specifically, one line at a time,
  driving llvm-mc --disassemble directly with no MAME involvement at all,
  which is exactly the leg the SriRR/ERP fix touches.

SAFETY MODEL
  * "CODE-flanked" = the nearest non-blank/non-comment/non-label line above
    AND below is itself a recognizable instruction line (not a `.byte`, not
    a directive) -- i.e. the exact shape the census's --islands mode counts,
    checked independently here at the level of an individual candidate.
  * A decode that prints ANY 'warning: invalid instruction encoding' is
    rejected outright, never guessed at.
  * The candidate is applied ONLY if disassembling then reassembling the
    resulting text through llvm-mc -filetype=obj + llvm-objcopy reproduces
    the ORIGINAL raw bytes exactly (full binary compare, not the encoding
    field).
  * v9/v10 share a lockstep disassembly; before editing v9's mirror this
    script requires the SAME line number in the mirrored relative path to
    carry the IDENTICAL `.byte` directive text. A documented ~581 B of real
    v9/v10 territory divergence exists (v9_v10_undisassembled_census.py's
    docstring) -- a mismatch here is expected occasionally and is reported,
    not forced; that item is applied to the requested tag only.
  * Before writing, re-reads the target line and re-asserts its bytes still
    match what was scanned (protects against a stale line number if the
    file changed between scan and apply).
  * CASCADING: converting one island can turn a previously DATA-flanked
    neighbour into a newly CODE-flanked one. Re-run after applying to find
    the next wave; iterate until a run finds zero new candidates.

RUN
    python3 scripts/converters/convert_decoder_unblocked_islands.py v10
        (dry run: lists every candidate that would convert)
    python3 scripts/converters/convert_decoder_unblocked_islands.py v10 --apply
        (writes v10, and the v9 mirror wherever its .byte line matches)

RESULT, 2026-09-02 (lane POSTDEC10, w4/postdec10), 3 rounds to fixpoint:
    round 1: 150 islands / 668 B   (v9 mirrored except 1 divergent byte,
                                     accompaniment_engine.s:35699)
    round 2: 332 islands / 1,274 B (newly flanked once round 1's neighbours
                                     became real instructions)
    round 3: see notes/lanes/postdec10-decoder-unblocked-islands.md for the
             final count and the fixpoint confirmation (a 4th scan finding
             zero further candidates).
  Every round rebuilt kn5000_v9_program.llvm.rom / kn5000_v10_program.llvm.rom
  and `cmp`-verified byte-identical to the original dumps before committing.

PROVENANCE
  Lane POSTDEC10, 2026-09-02, exploiting llvm-project commit 662b3929a72a
  minutes after it landed. REPO derives from this file's location.
"""
import sys, os, re, subprocess, tempfile, glob
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
LLVM_MC = os.path.join(LLVM, "llvm-mc")
LLVM_OBJCOPY = os.path.join(LLVM, "llvm-objcopy")

BYTE_RE = re.compile(r'^(\s*)\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
INSN_RE = re.compile(r'^\s*[a-zA-Z_][a-zA-Z0-9_]*(\s|$)')
DIRECTIVE_OR_LABEL = re.compile(r'^\s*(\.|;|#)|:$')


def is_code_line(line):
    s = line.strip()
    if not s:
        return False
    if DIRECTIVE_OR_LABEL.match(s):
        return False
    return bool(INSN_RE.match(s))


def disasm(data):
    hexstr = ' '.join(f'0x{b:02x}' for b in data)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '--disassemble'],
                        input=hexstr, capture_output=True, text=True, timeout=10)
    warnings = p.stderr.count('warning: invalid instruction encoding')
    lines = [l for l in p.stdout.split('\n')
             if l.strip() and not l.strip().startswith('.text')]
    return lines, warnings


def reassemble(lines):
    text = '\n'.join(lines)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=10)
    if p.returncode != 0:
        return None
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath],
                         capture_output=True, timeout=10)
    ok = p2.returncode == 0
    data = open(binpath, 'rb').read() if ok else None
    os.unlink(objpath)
    if ok:
        os.unlink(binpath)
    return data


def get_byte_line(fp, lineno):
    if not os.path.exists(fp):
        return None, None, None
    lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
    if lineno - 1 >= len(lines):
        return None, None, None
    m = BYTE_RE.match(lines[lineno - 1])
    if not m:
        return None, None, None
    raw = bytes(int(x.strip(), 16) for x in m.group(2).split(','))
    return lines, m.group(1), raw


def scan(tag):
    """Find every CODE-flanked isolated .byte line in <tag>/maincpu, and test
    which ones now decode + round-trip byte-exact. Returns a list of
    dicts: relp, lineno, raw, new_lines."""
    results = []
    files = sorted(glob.glob(os.path.join(REPO, f"{tag}/maincpu/**/*.s"), recursive=True))
    for fp in files:
        lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
        for i, line in enumerate(lines):
            m = BYTE_RE.match(line)
            if not m:
                continue
            pi = i - 1
            while pi >= 0 and (not lines[pi].strip() or lines[pi].strip().startswith(';')
                                or lines[pi].strip().endswith(':')):
                pi -= 1
            ni = i + 1
            while ni < len(lines) and (not lines[ni].strip() or lines[ni].strip().startswith(';')
                                        or lines[ni].strip().endswith(':')):
                ni += 1
            if not (pi >= 0 and is_code_line(lines[pi]) and ni < len(lines) and is_code_line(lines[ni])):
                continue
            raw = bytes(int(x.strip(), 16) for x in m.group(2).split(','))
            results.append((fp, i + 1, raw))

    converted = []
    for fp, lineno, raw in results:
        dl, warn = disasm(list(raw))
        if warn > 0:
            continue
        rt = reassemble(dl)
        if rt == raw:
            relp = os.path.relpath(fp, REPO)
            new_lines = [dline.strip() for dline in dl]
            converted.append(dict(relp=relp, lineno=lineno, raw=raw, new_lines=new_lines))
    return len(results), sum(len(r[2]) for r in results), converted


def other_tag(tag):
    return {'v9': 'v10', 'v10': 'v9'}[tag]


def apply(tag, converted):
    mirror = other_tag(tag)
    by_file = defaultdict(list)
    for c in converted:
        indent_lines, _, raw_now = get_byte_line(os.path.join(REPO, c['relp']), c['lineno'])
        by_file[c['relp']].append(c)
        mrelp = c['relp'].replace(tag, mirror)
        _, _, mraw = get_byte_line(os.path.join(REPO, mrelp), c['lineno'])
        if mraw == c['raw']:
            by_file[mrelp].append(dict(c, relp=mrelp))
        else:
            print(f"  MIRROR SKIP {mrelp}:{c['lineno']} -- bytes differ or line missing "
                  f"(v9/v10 territory divergence)")

    for relp, items in by_file.items():
        fp = os.path.join(REPO, relp)
        lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
        items.sort(key=lambda c: -c['lineno'])
        n = 0
        for c in items:
            i = c['lineno'] - 1
            m = BYTE_RE.match(lines[i]) if i < len(lines) else None
            if not m:
                print(f"  ABORT {relp}:{c['lineno']} -- line changed since scan")
                continue
            indent = m.group(1)
            raw_now = bytes(int(x.strip(), 16) for x in m.group(2).split(','))
            if raw_now != c['raw']:
                print(f"  ABORT {relp}:{c['lineno']} -- bytes changed since scan")
                continue
            lines[i:i + 1] = [indent + t for t in c['new_lines']]
            n += 1
        open(fp, 'w', encoding='utf-8', errors='surrogateescape').write('\n'.join(lines))
        print(f"  wrote {relp} ({n} edits)")


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ('v9', 'v10'):
        sys.exit(__doc__)
    tag = sys.argv[1]
    do_apply = '--apply' in sys.argv

    n_islands, n_bytes, converted = scan(tag)
    conv_bytes = sum(len(c['raw']) for c in converted)
    print(f"{tag}: {n_islands:,} CODE-flanked isolated .byte lines, {n_bytes:,} B total")
    print(f"  {len(converted)} now decode+round-trip byte-exact with the current decoder, "
          f"{conv_bytes:,} B")

    if not do_apply:
        print("\nDRY RUN -- pass --apply to write changes")
        for c in converted:
            print(f"  {c['relp']}:{c['lineno']}  {len(c['raw'])}B -> "
                  f"{' / '.join(c['new_lines'])}")
        return

    apply(tag, converted)


if __name__ == '__main__':
    main()
