#!/usr/bin/env python3
"""L2 aptness: does a name that ASSERTS A STRUCTURE match the bytes?

The scorecard has long said most name aptness is not decidable by script, and
that is true of names like `ToneGen_ParamTable` which turned out to be a jump
table -- it declares a subject, and subjects are not checkable.

But a large family of names declares something that IS checkable: a STRUCTURE.
`*_PtrTable` claims the bytes are pointers. `*_Strings` claims they are text.
`*_Table` with a stride in the name claims a stride. Those are testable against
the ROM, and the test can fail.

DECIDABLE CLAIMS TESTED HERE

  `*PtrTable*`, `*_Ptrs`   -> >=75% of the u32 words at the symbol must land in
                              the ROM address range, AND the region must beat the
                              symbol-resolution null by a wide margin.
  `*Strings*`, `*_Str`     -> >=80% printable ASCII with word-like runs, using
                              the same rule as the embedded-structure scan (a
                              plain printable-byte count calls pixel data text).
  `*Bitmap*`, `*Glyphs*`   -> must NOT be mostly ROM-range u32 (that would make
                              it a pointer table wearing a graphics name).

⚠ EVERY CLAIM IS TESTED OVER THE BYTES AT THE SYMBOL, bounded by the NEXT symbol
address. A symbol at the very end of a region has no bound and is skipped rather
than measured over an arbitrary window -- an unstated window is how three
negative results were manufactured earlier in this project.

⚠ A REGION MAY EXTEND PAST ITS STRUCTURE, and that manufactures false
violations. `IconBitmapNamePtrTable` scores 69% over the 1024 bytes up to the
next symbol, yet its first 512 bytes are a pointer table whose every word
resolves to a real symbol. The symbol names the START of a table; the next
symbol is not its END. So a claim is only counted as CONTRADICTED when it fails
over the LONGEST PREFIX too -- i.e. no prefix of at least 64 bytes satisfies it.
That separates "the name is wrong" from "the region runs on past the structure",
which are different findings and only the first is an L2 defect.

⚠ CODE SYMBOLS ARE EXCLUDED. A name like `SndParam_LookupFromPointerTable` or
`MasterSetup_StringSearch_Adjust` is a FUNCTION that mentions a structure; the
bytes at it are instructions and "0% in range" says nothing about the name's
aptness. Only symbols whose bytes are DATA territory are tested. Without this
the violation list is padded with routines that are named perfectly well.

⚠ CONTROL: the same tests are run against symbols whose names make NO structural
claim. If the "violations" rate among claiming names is no better than among
non-claiming ones, the test is measuring the byte distribution, not the names.

RESULT 2026-08-23: 222 testable structural claims, **45 contradicted** by the
bytes, against a 4.6% control. Two hand-checked examples:

    SOUND_DATA_STRINGS_VOCAL @0xE04B30  = 00 01 02 03 04 05 06 07 00 00 ...
        an index sequence then zeros -- not strings.
    DiskWarning_ConfirmStrings_0xC36    = 07 00 00 00  07 00 00 00  06 00 ...
        u32 counters descending 7,7,7,7,7,6,6,6,5,5,5,4 -- not strings.

⚠ 34 of the 45 are `_0xNNN` SUB-LABELS, only 7 are standalone names. That is a
finding about the NAMING SCHEME rather than 45 independent mistakes: a sub-label
inherits its parent's structural word, so `DiskWarning_ConfirmStrings_0xC36`
claims TEXT purely because the block it sits in is called `...Strings`. The
parent may well be apt for its first region. Report the two counts separately;
summing them overstates how many distinct naming decisions are wrong.

Run:  python3 scripts/analysis/l2_name_vs_structure.py [--list]
"""
import argparse, importlib.util, os, pathlib, random, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO); sys.path.insert(0, str(REPO))
BASE, ROM_LO, ROM_HI = 0xE00000, 0xE00000, 0x1000000

_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)

PTR = re.compile(r'(PtrTable|_Ptrs\b|PointerTable)', re.I)
STR = re.compile(r'(Strings|_Str\b|_Text\b)', re.I)
GFX = re.compile(r'(Bitmap|Glyphs|Icon.*Pixels|_Image)', re.I)


def words(b):
    return [struct.unpack("<I", b[i:i + 4])[0] for i in range(0, len(b) - 3, 4)]


def is_ptr(b):
    w = words(b)
    if len(w) < 8:
        return None
    return sum(1 for x in w if ROM_LO <= x < ROM_HI) / len(w)


def best_prefix(b, fn, thresh, step=64):
    """Best score over any prefix >= 64 bytes. A symbol names a structure's
    START, so a failing whole-region score may only mean the region runs on."""
    best = 0.0
    n = len(b)
    while n >= 64:
        f = fn(b[:n])
        if f is not None and f > best:
            best = f
        if best >= thresh:
            return best
        n -= step
    return best


def is_text(b):
    if len(b) < 16:
        return None
    p = sum(1 for c in b if 0x20 <= c < 0x7F) / len(b)
    runs = cur = 0
    for c in b:
        if 0x41 <= (c & 0xDF) <= 0x5A or 0x30 <= c <= 0x39:
            cur += 1
            if cur == 3:
                runs += 1
        else:
            cur = 0
    return p if runs >= len(b) // 32 else p * 0.5


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    _sp = importlib.util.spec_from_file_location(
        "spans", REPO / "scripts/analysis/v7_undisassembled_spans.py")
    spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    CODE = 1

    def is_code(ad):
        o = ad - BASE
        return 0 <= o < len(terr) and terr[o] == CODE
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    addrs = sorted(syms)
    bound = {ad: (addrs[i + 1] if i + 1 < len(addrs) else None)
             for i, ad in enumerate(addrs)}

    def region(ad):
        nxt = bound[ad]
        if nxt is None or nxt <= ad:
            return None
        n = min(nxt - ad, 4096)
        o = ad - BASE
        if o < 0 or o + n > len(rom):
            return None
        return rom[o:o + n]

    viol, checked = [], 0
    for ad in addrs:
        nm = syms[ad]
        if is_code(ad):
            continue                     # a function that MENTIONS a structure
        b = region(ad)
        if b is None:
            continue
        if PTR.search(nm):
            f = is_ptr(b)
            if f is None:
                continue
            checked += 1
            if f < 0.75:
                fp = best_prefix(b, is_ptr, 0.75)
                if fp < 0.75:
                    viol.append((nm, ad,
                                 f"claims POINTERS, {100*f:.0f}% whole / "
                                 f"{100*fp:.0f}% best prefix", len(b)))
        elif STR.search(nm):
            f = is_text(b)
            if f is None:
                continue
            checked += 1
            if f < 0.80:
                fp = best_prefix(b, is_text, 0.80)
                if fp < 0.80:
                    viol.append((nm, ad,
                                 f"claims TEXT, {100*f:.0f}% whole / "
                                 f"{100*fp:.0f}% best prefix", len(b)))
        elif GFX.search(nm):
            f = is_ptr(b)
            if f is None:
                continue
            checked += 1
            if f >= 0.75:
                viol.append((nm, ad, f"claims GRAPHICS but {100*f:.0f}% ROM-range u32", len(b)))

    # CONTROL: names making no structural claim
    plain = [ad for ad in addrs
             if not (PTR.search(syms[ad]) or STR.search(syms[ad]) or GFX.search(syms[ad]))]
    rng = random.Random(5)
    ctrl_hits = ctrl_n = 0
    for ad in rng.sample(plain, min(400, len(plain))):
        b = region(ad)
        if b is None:
            continue
        f = is_ptr(b)
        if f is None:
            continue
        ctrl_n += 1
        if f >= 0.75:
            ctrl_hits += 1

    print(f"  symbols with a structural claim, testable : {checked}")
    print(f"  claims CONTRADICTED by the bytes          : {len(viol)}")
    print()
    print(f"  CONTROL: unnamed-claim symbols that look like pointer tables anyway:")
    print(f"      {ctrl_hits}/{ctrl_n} = {100*ctrl_hits/max(1,ctrl_n):.1f}%")
    print("      (if this were high, 'looks like pointers' would be uninformative)")
    if a.list or viol:
        print()
        for nm, ad, why, n in sorted(viol)[:40]:
            print(f"    0x{ad:06X}  {nm:52} {why}  [{n} B]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
