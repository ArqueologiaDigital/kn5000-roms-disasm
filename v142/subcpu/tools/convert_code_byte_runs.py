#!/usr/bin/env python3
"""convert_code_byte_runs.py -- convert the v1.42 payload's remaining
code-as-`.byte` runs, using unidasm for FRAMING and a spelling search for the
instructions `llvm-mc --disassemble` refuses.

QUESTION ANSWERED: convert_arm_blocks.py could only take the four runs that
`llvm-mc --disassemble` decodes end to end -- 666 B of the 2,188 B
`scripts/analysis/tier2_byte_split_census.py --report --image v142 --list a`
reports. The other seven runs (1,522 B) each contain between one and three
byte sequences that the pinned LLVM DISASSEMBLER will not decode. Are those
sequences un-spellable, or merely un-decodable?

THE ANSWER IS "MERELY UN-DECODABLE", AND IT MATTERS. All but one ASSEMBLE
perfectly once the spelling this tree already uses is found (see
v142/subcpu/tools/spell_search.py): `cp (xwa), 0` is 80 3f 00 and
`or_sriw_rm hl, 7, 240, 232` is d3 07 f0 e8 e3. The project's rule about
untried spellings has fired nine times; a refusal written as "the toolchain
cannot express this" would have been the tenth.

METHOD, per run
  1. FRAME with unidasm (MAME's TLCS-900 core, the framing authority named in
     original_ROMs/README-unidasm.md), never with a backend refusal -- this
     tree retracted a conclusion built on one on 2026-09-02.
  2. SPELL each framed instruction: llvm-mc's own `--disassemble` text when it
     has one, else spell_search.search() over the mnemonics this tree already
     uses, else a `.byte` line carrying unidasm's decode as a comment.
  3. VERIFY. Every emitted line is re-assembled with `--show-encoding` and the
     concatenation must equal the run's original bytes EXACTLY. Nothing is
     written unless every run passes.
  4. INTERIOR LABELS. Every label or comment inside the run must land on a
     unidasm instruction boundary, or the run is refused -- a computed-jump
     arm entered mid-instruction means the linear framing is wrong. All
     interior lines are preserved where they were.

⚠ Decodability and spellability are properties of ONE LLVM BUILD. Measured
against llvm-mc 6f456a19f05b (the installed build moved from 6fe210fb0a81
mid-push). Re-run before quoting any count here against a different build.

RUN (from the lane worktree root):
    python3 v142/subcpu/tools/convert_code_byte_runs.py            # dry run
    python3 v142/subcpu/tools/convert_code_byte_runs.py --apply
    rm -f rebuilt_ROMs/kn5000_subprogram_v142.llvm.*
    make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom
    cmp rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom original_ROMs/kn5000_subprogram_v142.rom

⚠ latin-1 I/O throughout (BRIEF addendum 2026-09-02).
"""
import importlib.util
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(ROOT, "v142/subcpu/kn5000_subprogram_v142.s")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
ENC = re.compile(r'encoding: \[([^\]]*)\]')
BYTE = re.compile(r'^\s*\.byte\s+(.*)$')
UNI_LINE = re.compile(r'^\s*([0-9a-fA-F]{4,8}):\s+((?:[0-9a-fA-F]{2} )+)\s*(.*)$')

sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
_spec = importlib.util.spec_from_file_location(
    "spell_search", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                 "spell_search.py"))
SPELL = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(SPELL)

MIN_RUN = 8          # bytes; below this a run is not worth reframing


DATA_LINE = re.compile(r'^\s*(?:[A-Za-z_.$][A-Za-z0-9_.$]*:\s*)?'
                       r'\.(byte|hword|short|word|long)\s+(.*)$')
DATA_W = {"byte": 1, "hword": 2, "short": 2, "word": 4, "long": 4}


def parse_byte_line(txt):
    """Bytes emitted by one data-directive line, little-endian for the wide
    forms, or None if the line emits nothing. ⚠ A run is not all `.byte`:
    treating a `.word` inside one as a zero-size comment made five runs
    "recover" the wrong length. A label may share the line."""
    m = DATA_LINE.match(txt)
    if not m:
        return None
    w = DATA_W[m.group(1)]
    out = []
    for tok in m.group(2).split(";")[0].split(","):
        tok = tok.strip()
        if tok:
            out += list(int(tok, 0).to_bytes(w, "little"))
    return out


def unidasm_frame(raw, base):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(raw)
        t = f.name
    try:
        out = subprocess.run([UNIDASM, t, "-arch", "tlcs900", "-basepc", hex(base)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(t)
    ins = []
    for ln in out.splitlines():
        m = UNI_LINE.match(ln.rstrip())
        if m:
            ins.append((int(m.group(1), 16) - base,
                        bytes(int(x, 16) for x in m.group(2).split()),
                        m.group(3).strip()))
    return ins


def llvm_text(bs):
    hx = " ".join("0x%02x" % b for b in bs)
    r = subprocess.run([MC, "--triple=tlcs900", "--disassemble"],
                       input=hx, capture_output=True, text=True)
    if "invalid instruction encoding" in r.stderr:
        return None
    txt = [l.strip() for l in r.stdout.strip().split("\n")
           if l.strip() and not l.strip().startswith(".")]
    return txt[0] if len(txt) == 1 else None


def encode(lines):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input="\n".join(lines) + "\n", capture_output=True, text=True)
    if r.returncode:
        return None
    out = b""
    for l in r.stdout.split("\n"):
        m = ENC.search(l)
        if m:
            out += bytes(int(x, 16) for x in m.group(1).split(",") if x.strip())
    return out


def main():
    apply_ = "--apply" in sys.argv
    import tier2_byte_split_census as C
    runs, amap, _srcmap = C.collect("v142")
    lines = open(SRC, encoding="latin-1").read().split("\n")

    todo = []
    for r in runs:
        if r[0] != "kn5000_subprogram_v142.s" or r[4] < MIN_RUN:
            continue
        verdicts = C.classify_run("v142", r, _srcmap, amap)
        if any(b == "a" for _sa, _n, b, _k, _w in verdicts):
            todo.append(r)
    if not todo:
        print("no (a) runs left in kn5000_subprogram_v142.s")
        return 0

    edits, done, refused = [], 0, []
    for run in sorted(todo, key=lambda r: r[1]):
        _rel, l0, l1, start, size, _t = run
        raw, marks = bytearray(), []
        for i in range(l0, l1 + 1):
            v = parse_byte_line(lines[i - 1])
            if v is None:
                marks.append((len(raw), i))
            else:
                raw += bytes(v)
        raw = bytes(raw)
        if len(raw) != size:
            refused.append((start, size, "line parse recovered %d B" % len(raw)))
            continue

        frame = unidasm_frame(raw, start)
        if not frame or sum(len(b) for _o, b, _m in frame) != size:
            refused.append((start, size, "unidasm does not frame the run end to end"))
            continue
        bounds = {o for o, _b, _m in frame} | {size}
        bad = [(o, lines[i - 1].strip()) for o, i in marks if o not in bounds]
        if bad:
            refused.append((start, size,
                            "interior line at +0x%X (%r) is not an instruction "
                            "boundary" % bad[0]))
            continue

        body, spelled, bytes_left, ok = [], 0, 0, True
        for off, bs, mn in frame:
            t = llvm_text(bs)
            if t is None and mn and not mn.startswith("db"):
                t = SPELL.search(bs, mn)
                if t:
                    spelled += 1
            if t is None:
                body.append(("\t.byte " + ", ".join("0x%02x" % b for b in bs)
                             + "\t; %s (no llvm-mc spelling found)" % (mn or "undecoded")))
                bytes_left += len(bs)
            else:
                body.append("\t" + t)
        # re-encode check: strip comments, assemble, compare
        chk = encode([l.split("\t;")[0] for l in body])
        if chk != raw:
            refused.append((start, size, "re-encode mismatch (%s B vs %d B)"
                            % (len(chk) if chk is not None else "None", size)))
            continue

        hdr = ["\t; Converted from a %d-byte `.byte` run. Framing: unidasm; every"
               % size,
               "\t; instruction re-encoded and the whole run compared byte for byte.",
               "\t; %d instructions, of which %d needed a spelling search because"
               % (len(frame), spelled),
               "\t; llvm-mc --disassemble refuses them (it can still ASSEMBLE them)."]
        if bytes_left:
            hdr.append("\t; %d B left as .byte: no spelling found, unidasm decode in the"
                       % bytes_left)
            hdr.append("\t; comment.")
        out = []
        by_off = {}
        for o, i in marks:
            by_off.setdefault(o, []).append(i)
        for (off, _bs, _mn), text in zip(frame, body):
            for i in by_off.pop(off, []):
                out.append(lines[i - 1])
            out.append(text)
        for o in sorted(by_off):
            for i in by_off[o]:
                out.append(lines[i - 1])
        edits.append((l0, l1, hdr + out))
        done += size - bytes_left
        print("0x%06X %4d B  lines %6d..%-6d  %3d instr, %d spell-searched, "
              "%d B left as .byte" % (start, size, l0, l1, len(frame), spelled, bytes_left))

    print("converted to instructions: %d B; runs refused: %d" % (done, len(refused)))
    for st, sz, why in refused:
        print("   REFUSED 0x%06X %4d B: %s" % (st, sz, why))
    if not apply_:
        print("(dry run; pass --apply to write)")
        return 0
    for l0, l1, body in sorted(edits, reverse=True):
        lines[l0 - 1:l1] = body
    open(SRC, "w", encoding="latin-1").write("\n".join(lines))
    print("written: %s" % SRC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
