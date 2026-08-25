#!/usr/bin/env python3
"""Apply a LABEL MAP and a set of HEADER BLOCKS to a prom_c_listing_prep.py listing.

QUESTION IT ANSWERS
  "prom_c_listing_prep.py gave me a byte-verified listing with auto-generated
   KX_xxxxxx labels.  How do I get from there to this file's house style -- real
   label names and a Name/Called from/Inputs/Outputs/Evidence/Unknown block above
   every routine -- without hand-editing two thousand lines?"

  It is the mechanical step BETWEEN notes/prom_c_listing_prep.py and
  prom_c/wsa1_prom_c.s.  Round 5 used it for all four blocks it inserted
  (0xF9816B, 0xF98A0B, 0xFC89C5, 0xFCA0BA).

WHAT IT CHANGES, AND WHY IT IS SAFE
  * every `KX_xxxxxx:` label line is dropped and re-emitted under the name the
    label map gives that address;
  * every `KX_xxxxxx` REFERENCE is rewritten to that name -- the branch
    displacements are llvm-mc's problem, not this script's;
  * a header block is inserted above the instruction at each address the header
    file names;
  * `di` becomes `ei 0` (the same two bytes `06 00`; llvm-mc accepts `di` and
    assembles it to EI 0, which ENABLES interrupts -- see the note in
    DSP_ChannelRefresh_Loop's header);
  * the trailing "[llvm-mc cannot encode this]" marker is stripped, leaving the
    unidasm text as the comment.

  ⚠ It changes SPELLING and COMMENTS only.  Nothing it does is evidence for
  anything.  The proof that the result is right is
  `python3 notes/prom_c_verify_fragment.py c <addr> <file>` before insertion and
  `python3 scripts/analysis/assert_byte_identical.py` after it.

  ⚠ The label prefix is hard-coded as KX_.  Run prom_c_listing_prep.py with
  `--prefix KX`, or `sed 's/KE_/KX_/g'` first -- round 5 lost one fragment
  verification to exactly that mismatch (the label LINES were dropped while the
  references were not, so the branches assembled to the wrong bytes; the fragment
  verifier caught it immediately, which is what it is for).

INPUT FORMATS
  labels file    one per line:  `F9816B Kernel_InitRam`
  headers file   blocks separated by a line `@@ 0xF9816B`; everything until the
                 next `@@` is emitted verbatim above that address's instruction.

RUN
  python3 notes/llvm_roundtrip_autoforce.py c 0xF9816B 0x884 --quiet > /tmp/b.s
  python3 notes/prom_c_listing_prep.py /tmp/b.s --prefix KX > /tmp/b.pretty.s
  python3 notes/prom_c_apply_headers.py /tmp/b.pretty.s labels.txt headers.txt > /tmp/b.final.s
  python3 notes/prom_c_verify_fragment.py c 0xF9816B /tmp/b.final.s
"""
import re, sys

LINE = re.compile(r'^\t(?P<code>.*?)\s+; (?P<addr>[0-9A-F]{6})  (?P<txt>.*)$')

def load_labels(path):
    m = {}
    for ln in open(path):
        ln = ln.strip()
        if not ln or ln.startswith('#'):
            continue
        a, n = ln.split(None, 1)
        m[int(a, 16)] = n.strip()
    return m

def main():
    src, labels_f, headers_f = sys.argv[1], sys.argv[2], sys.argv[3]
    labels = load_labels(labels_f)
    # headers file: blocks separated by lines "@@ 0xADDR"
    headers = {}
    cur = None
    for ln in open(headers_f):
        if ln.startswith('@@ '):
            cur = int(ln.split()[1], 16)
            headers[cur] = []
        elif cur is not None:
            headers[cur].append(ln.rstrip('\n'))
    out = []
    for ln in open(src):
        ln = ln.rstrip('\n')
        m = LINE.match(ln)
        if not m:
            # a KX_ label line emitted by the prep tool -- drop it, we re-emit our own
            if re.match(r'^KX_[0-9A-F]{6}:$', ln.strip()):
                continue
            out.append(ln)
            continue
        addr = int(m.group('addr'), 16)
        if addr in headers:
            out.extend(headers[addr])
        if addr in labels:
            out.append(labels[addr] + ':')
        code = m.group('code')
        # rewrite KX_ references
        code = re.sub(r'KX_([0-9A-F]{6})',
                      lambda mm: labels.get(int(mm.group(1), 16), 'KX_' + mm.group(1)), code)
        code = re.sub(r'^di$', 'ei\t0', code)          # 06 00 ENABLES interrupts
        txt = m.group('txt').replace('   [llvm-mc cannot encode this]', '')
        out.append('\t%-42s ; %s  %s' % (code, m.group('addr'), txt))
    print('\n'.join(out))

main()
