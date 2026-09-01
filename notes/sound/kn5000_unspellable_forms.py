#!/usr/bin/env python3
r"""WHICH INSTRUCTION FORMS DOES THIS TREE STILL CARRY AS `.byte`, AND WHY?

QUESTION IT ANSWERS
    `kn5000_sound_boundary.py --unspellable` says HOW MANY sites and forms are
    left.  This says, per form, WHAT THE BYTES ARE and WHETHER THE ASSEMBLER
    CAN SPELL THEM -- which is the difference between "still to disassemble"
    and "a gap in the LLVM TLCS-900 backend".  It is the work list that told
    lane S3 which encodings to add, and the file that goes GREEN when there is
    nothing left to add.

    It walks a WHOLE include tree, not just a root file, so a form hiding in
    one of the ~150 included sources cannot be missed.

★ TWO THINGS MAKE IT A MEASUREMENT RATHER THAN A GREP
    1. THE COMMENT ALONE IS NOT EVIDENCE.  A data table's per-row annotation
       looks exactly like a disassembly comment; matching any commented `.byte`
       line counted 562 bytes of the boot ROM's velocity-curve tables as
       unspelt instructions.  A line counts only if the COMMITTED MAME UNIDASM
       LISTING decodes exactly those bytes as ONE instruction and the comment
       is that rendering.
    2. "SPELLABLE" MEANS THE BYTES CAME BACK.  Each form is handed to
       scripts/converters/convert_unspellable_forms.py's decoder and the result
       to llvm-mc; the form is GREEN only if the encoding is byte-for-byte what
       it came from.  "llvm-mc accepted it" is not the test.

⚠ THE WORK LIST IS SUPPOSED TO EMPTY.  --selftest asserts INVARIANTS, never a
  pinned count: a pinned "59 forms" turns green work into a red test.  What it
  asserts is that anything the census still lists is genuinely UNSPELLABLE, and
  that the census can see a form at all (positive control).

RUN:  python3 notes/sound/kn5000_unspellable_forms.py            # both images
      python3 notes/sound/kn5000_unspellable_forms.py --sites    # + file:line
      python3 notes/sound/kn5000_unspellable_forms.py --selftest
"""
import collections, importlib.util, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))      # ⚠ never hard-code this
CONV = os.path.join(ROOT, "scripts", "converters",
                    "convert_unspellable_forms.py")

_spec = importlib.util.spec_from_file_location("conv", CONV)
conv = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(conv)

# (tree to walk, committed unidasm listing for the image it builds)
TREES = [
    ("v142/subcpu", "original_ROMs/kn5000_subprogram_v142.rom.unidasm",
     "sub-CPU payload v1.42 -- the sound CPU's program"),
    ("subcpu/boot", "original_ROMs/kn5000_subcpu_boot.ic30.unidasm",
     "sub-CPU boot ROM (IC30)"),
]

UNILINE = re.compile(r'^([0-9a-f]{4,6}): ((?:[0-9a-f]{2} )+)\s+(\S.*?)\s*$')
NUM = re.compile(r'0x[0-9A-Fa-f]+')


def unidasm_forms(listing):
    out = {}
    for line in open(os.path.join(ROOT, listing), errors="replace"):
        m = UNILINE.match(line.rstrip())
        if m:
            out[" ".join(m.group(2).split())] = m.group(3)
    return out


def _norm(s):
    return "".join(s.split()).lower()


def census(tree, listing):
    """-> {form: [(path, lineno, bytes, comment), ...]}, unidasm-certified."""
    forms = unidasm_forms(listing)
    out = collections.defaultdict(list)
    for dp, dirs, files in os.walk(os.path.join(ROOT, tree)):
        # ⚠ dotfiles are expansion CACHES; counting them doubles every figure.
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in sorted(files):
            if not f.endswith(".s") or f.startswith("."):
                continue
            p = os.path.join(dp, f)
            for i, line in enumerate(open(p, errors="replace"), 1):
                m = conv.BYTELINE.match(line)
                if not m:
                    continue
                try:
                    bs = [int(x, 0) for x in m.group(2).split(",") if x.strip()]
                except ValueError:
                    continue
                if not bs or not all(0 <= b <= 0xFF for b in bs):
                    continue
                r = forms.get(" ".join(f"{b:02x}" for b in bs))
                if r is None or not _norm(m.group(3)).startswith(_norm(r)):
                    continue
                out[NUM.sub("N", m.group(3)).strip()].append(
                    (os.path.relpath(p, ROOT), i, bs, m.group(3)))
    return out


def spelling(bs):
    """-> (text, True) if llvm-mc reproduces these exact bytes, else (why, False)."""
    text = conv.decode(bs)
    if text is None:
        return "no decoder for this form", False
    got = conv.assemble([text])
    if got is None:
        return f"`{text}` did not assemble", False
    if got[0] != bs:
        return (f"`{text}` assembles to "
                + " ".join(f"{b:#04x}" for b in got[0])), False
    return text, True


def report(show_sites):
    total_sites = total_bytes = 0
    for tree, listing, what in TREES:
        c = census(tree, listing)
        sites = sum(len(v) for v in c.values())
        nb = sum(len(e[2]) for v in c.values() for e in v)
        total_sites += sites
        total_bytes += nb
        print(f"=== {tree}  ({what}) ===")
        print(f"  {sites} site(s), {nb} byte(s), {len(c)} distinct form(s) "
              f"emitted as .byte with unidasm's rendering as the comment")
        for form, hits in sorted(c.items(), key=lambda kv: -len(kv[1])):
            bs = hits[0][2]
            text, ok = spelling(bs)
            mark = "spellable" if ok else "★ NO SPELLING"
            print(f"    {len(hits):4d} x {len(bs)}B  {form}")
            print(f"           {' '.join(f'{b:02x}' for b in bs)}   "
                  f"{mark}: {text}")
            if show_sites:
                for p, i, _b, _cm in hits:
                    print(f"             {p}:{i}")
        if not c:
            print("    (none -- every instruction in this tree is spelt)")
        print()
    print(f"TOTAL {total_sites} site(s), {total_bytes} byte(s)")
    return 0


def selftest():
    """INVARIANTS.  None of them is a pinned count."""
    bad = 0

    # 1. ROOT is derived, not hard-coded, and points at this tree.
    if not os.path.isfile(os.path.join(ROOT, "Makefile")) or \
       not os.path.isdir(os.path.join(ROOT, "v142", "subcpu")):
        print(f"FAIL  ROOT derived from __file__ is wrong: {ROOT}")
        bad += 1

    # 2. POSITIVE CONTROL: the census must be able to SEE a form.  A form whose
    #    bytes and comment are both real is certified; the same bytes under a
    #    data-table comment are not.  Without this, an empty work list could
    #    just mean the matcher is broken.
    forms = unidasm_forms(TREES[0][1])
    probe = "c7 f8 89"
    if forms.get(probe) is None:
        print(f"FAIL  the committed unidasm listing has no entry for {probe}")
        bad += 1
    else:
        real = f"\t.byte 0xc7, 0xf8, 0x89\t; {forms[probe]}\n"
        fake = "\t.byte 0xc7, 0xf8, 0x89\t; velocity curve row 3\n"
        m = conv.BYTELINE.match(real)
        if not (m and _norm(m.group(3)).startswith(_norm(forms[probe]))):
            print("FAIL  a genuine unspelt line was not recognised")
            bad += 1
        m = conv.BYTELINE.match(fake)
        if m and _norm(m.group(3)).startswith(_norm(forms[probe])):
            print("FAIL  a data-table comment was accepted as a rendering")
            bad += 1

    # 3. THE WORK LIST IS THE TEST.  Anything still listed must be genuinely
    #    unspellable -- if a form has a spelling, the tree should be carrying it
    #    as an instruction, not as .byte.  An EMPTY list is the finished state
    #    and passes; it does not go red when the work succeeds.
    for tree, listing, _what in TREES:
        for form, hits in census(tree, listing).items():
            text, ok = spelling(hits[0][2])
            if ok:
                print(f"FAIL  {tree}: `{form}` is spellable as `{text}` and is "
                      f"still .byte at {hits[0][0]}:{hits[0][1]}")
                bad += 1

    # 4. NEGATIVE CONTROL for `spelling`: a byte string one bit off must NOT be
    #    reported spellable by the round-trip.
    if spelling([0xc7, 0xf8, 0x8a])[1] and conv.decode([0xc7, 0xf8, 0x89]) == \
       conv.decode([0xc7, 0xf8, 0x8a]):
        print("FAIL  two different encodings produced the same spelling")
        bad += 1

    print("selftest: " + ("OK" if bad == 0 else f"{bad} FAILURE(S)"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv
             else report("--sites" in sys.argv))
