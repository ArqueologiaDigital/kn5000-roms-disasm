#!/usr/bin/env python3
"""L1: is EVERY byte of the rebuilt ROM classified as CODE, DATA or PADDING?

docs/IS-IT-DONE.md scored L1 as PARTIAL with the reason "no UNKNOWN bytes remain
in the audited ROMs, but the classification is not itself mechanised". This is
the mechanisation. It asks llvm-mc to flatten a target's whole source tree
(-show-encoding expands every .include and .incbin), walks the emitted stream,
and assigns every byte to a territory:

    CODE     an instruction, size taken from its `; encoding: [..]` bytes
    DATA     .byte .hword .word .dword .ascii .asciz
    PADDING  .zero .fill .p2align fill, and .org gaps

The check that makes this a test rather than a tally: the classified total must
equal the rebuilt ROM's size EXACTLY. Any directive we size wrongly, any escape
sequence we mis-decode, any construct we do not know about, shows up as a
mismatch. It cannot silently pass.

Directive widths were MEASURED, not assumed, by assembling one of each and
running llvm-objcopy -O binary:
    .byte 1  .hword 2  .word 4  .dword 8  .zero n  .fill n  .ascii len

Note .incbin does NOT survive flattening -- llvm-mc expands it to .byte, so
included binaries land in DATA here. Their separate justification is the job of
scripts/analysis/audit_incbin_legitimacy.py (spec section 3), not of this script.

Run:  python3 scripts/analysis/l1_territory_map.py [target ...]
      targets: v7 v9 v10   (default: all three)
Exits non-zero if any target's classified total != its rebuilt ROM size.
"""
import os, re, subprocess, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

TARGETS = {
    "v7":  ("v7/maincpu/kn5000_v7_program.s",  "v7/maincpu",  "rebuilt_ROMs/kn5000_v7_program.llvm.rom"),
    "v9":  ("v9/maincpu/kn5000_v9_program.s",  "v9/maincpu",  "rebuilt_ROMs/kn5000_v9_program.llvm.rom"),
    "v10": ("v10/maincpu/kn5000_v10_program.s", "v10/maincpu", "rebuilt_ROMs/kn5000_v10_program.llvm.rom"),
}

WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')


def ascii_len(operand):
    """Byte length of an .ascii/.asciz operand, decoding escapes exactly."""
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        body = m.group(1)
        total += len(ESCAPE.sub("X", body))
    return total


def classify(root_s, incdir):
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", "-I", incdir, root_s],
                         capture_output=True, text=True, cwd=ROOT)
    if out.returncode != 0:
        sys.exit(f"llvm-mc failed on {root_s}:\n{out.stderr[:400]}")
    pos = 0
    terr = {"CODE": 0, "DATA": 0, "PADDING": 0}
    unknown = []
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            terr["CODE"] += n; pos += n
            continue
        if s.endswith(":") or s.startswith(";"):
            continue            # a label, dot-prefixed ones (.Ltmp0:) included
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            unknown.append(s)
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
            terr["DATA"] += n; pos += n
        elif d in ("ascii", "asciz"):
            n = ascii_len(rest) + (1 if d == "asciz" else 0)
            terr["DATA"] += n; pos += n
        elif d in ("zero", "fill", "space"):
            parts = [p.strip() for p in rest.split(",")]
            n = int(parts[0], 0)
            if d == "fill" and len(parts) >= 2:
                n *= int(parts[1], 0)
            terr["PADDING"] += n; pos += n
        elif d == "p2align":
            a = 1 << int(rest.split(",")[0].strip(), 0)
            pad = (-pos) % a
            terr["PADDING"] += pad; pos += pad
        elif d == "org":
            target = int(rest.split(",")[0].strip(), 0)
            if target > pos:
                terr["PADDING"] += target - pos; pos = target
        elif d in ("set", "equ", "text", "globl", "global", "type", "size",
                   "section", "file", "ident", "weak", "local", "hidden",
                   "reloc"):        # .reloc emits no bytes, it annotates them
            continue
        else:
            unknown.append(s)
    return terr, pos, unknown


def main():
    names = sys.argv[1:] or ["v7", "v9", "v10"]
    ok = True
    for name in names:
        root_s, incdir, rom = TARGETS[name]
        rom_path = os.path.join(ROOT, rom)
        if not os.path.exists(rom_path):
            print(f"{name}: rebuilt ROM missing ({rom}) -- run `make all` first"); ok = False; continue
        size = os.path.getsize(rom_path)
        terr, pos, unknown = classify(root_s, incdir)
        total = sum(terr.values())
        print(f"--- {name}  rebuilt ROM {size:,} B")
        for k in ("CODE", "DATA", "PADDING"):
            print(f"      {k:8} {terr[k]:>10,}  {100.0*terr[k]/max(total,1):5.2f}%")
        print(f"      {'TOTAL':8} {total:>10,}   vs ROM {size:,}  "
              f"{'MATCH' if total == size else 'MISMATCH by %+d' % (total - size)}")
        if unknown:
            print(f"      UNCLASSIFIED constructs: {len(unknown)}  e.g. {unknown[:3]}")
        ok &= (total == size and not unknown)
    print("\nPASS: every byte classified, totals match the ROMs." if ok
          else "\nFAIL: classification does not account for every byte.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
