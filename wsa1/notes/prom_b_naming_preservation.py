#!/usr/bin/env python3
"""Did this round's renames DELETE anything, or only substitute a token?

WHAT QUESTION THIS ANSWERS
    The lane rule is "you are ADDING, not destroying".  A rename cannot obey
    that literally -- the old label text is gone by definition -- so the honest
    form of the rule is:

        every comment line and every label of the BASE revision must still be
        present in the working tree, either VERBATIM or as the same line with
        one of this round's renamed tokens substituted, and nothing else.

    That is what this checks, line for line, over prom_b/wsa1_prom_b.s.  It
    reports four numbers: lines kept verbatim, lines accounted for by a rename,
    lines that were DELETED (must be zero unless each is explained on the
    command line), and lines ADDED.

    ★ IT IS NOT THE BYTE GATE.  scripts/analysis/assert_byte_identical.py
    proves the ROM still rebuilds; this proves the PROSE was not thrown away.
    Neither substitutes for the other.

RUN
    python3 notes/prom_b_naming_preservation.py
    python3 notes/prom_b_naming_preservation.py --show-deleted
Exit status is non-zero if any base line is unaccounted for.
A revision other than HEAD: `--base <rev>`.

★ IT READS THE IMAGE, NOT ONE FILE, ON BOTH SIDES.  The working side goes
through notes/asm_source.py.  The BASE side is materialised out of git into a
temp tree -- the primary and, recursively, every `.include` it names at that
revision -- and read through asm_source there too.  So a future per-subject
split of prom_b changes neither side's answer, which is the property
notes/probe_health.py exists to check for.
"""
import collections
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = "prom_b/wsa1_prom_b.s"
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines, image_files  # noqa: E402
from asm_source import git_show  # noqa: E402  (git paths are repo-relative)
from prom_b_apply_msgline_names import RENAMES, CLEARERS  # noqa: E402  the round's own table
from prom_b_apply_smf_names import RENAMES as SMF_RENAMES, DATA_RENAMES  # noqa: E402
from prom_b_apply_effect_names import RENAMES as FX_RENAMES  # noqa: E402
from prom_b_apply_diskfile_name import RENAMES as DF_RENAMES  # noqa: E402
from prom_b_apply_effect_editor_name import RENAMES as ED_RENAMES  # noqa: E402
from prom_b_apply_chordnote_names import RENAMES as CN_RENAMES  # noqa: E402
from prom_b_names_session_53b889a2 import RENAMES as S53_RENAMES  # noqa: E402  2026-10-03 passes

LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


INCLUDE = re.compile(r'^\s*\.include\s+"([^"]+)"')


def _git_show(rev, path):
    """`rev`'s copy of a ROOT-relative path.  ⚠ RAISES when it is not there.

    ★ IT USED TO RETURN None, AND THE CALLER SKIPPED IT.  When the tree moved
    into `wsa1/` every `git show HEAD:prom_b/...` started missing, the temp tree
    was left empty, and the failure surfaced only as a FileNotFoundError naming
    a RANDOM temp directory -- which made two runs of this probe differ, so
    probe_health graded it NONDET (flaky) instead of broken.  A deterministic
    failure has to look deterministic."""
    return git_show(path, rev)


def base_lines(rev):
    """The BASE revision's whole IMAGE, includes expanded, as a list of lines.

    Materialised into a temp tree so that asm_source resolves the includes the
    same way it does for the working tree -- one code path, two revisions.
    """
    tmp = tempfile.mkdtemp(prefix="preserve-base-")
    try:
        want, done = [REL], set()
        while want:
            rel = want.pop()
            if rel in done:
                continue
            done.add(rel)
            txt = _git_show(rev, rel)
            dst = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "w") as f:
                f.write(txt)
            for ln in txt.splitlines():
                m = INCLUDE.match(ln)
                if m:
                    inc = m.group(1)
                    want.append(inc if os.path.sep in inc or "/" in inc
                                else os.path.join(os.path.dirname(rel), inc))
        return list(image_lines(tmp, REL))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    rev = "HEAD"
    if "--base" in sys.argv:
        i = sys.argv.index("--base") + 1
        if i >= len(sys.argv):
            print("--base needs a revision; defaulting to HEAD")
        else:
            rev = sys.argv[i]
    ren = {"sub_%06X" % a: n for a, n, *_ in RENAMES}
    ren.update({"sub_%06X" % a: n for a, n, *_ in CLEARERS})
    ren.update({"sub_%06X" % a: n for a, n in SMF_RENAMES})
    ren.update({o: n for o, n, _k in DATA_RENAMES})
    ren.update(dict(FX_RENAMES))
    ren.update(dict(DF_RENAMES))
    ren.update(dict(ED_RENAMES))
    ren.update(dict(CN_RENAMES))
    ren.update(dict(S53_RENAMES))
    old = [l.rstrip("\n") for l in base_lines(rev)]
    new = [l.rstrip("\n") for l in image_lines(ROOT, REL)]
    have = collections.Counter(new)
    new_label_set = {LABEL.match(l).group(1) for l in new if LABEL.match(l)}

    # One alternation, applied until nothing changes (so a chain old -> mid -> new still resolves).  It used to be
    # one re.sub per rename per line: with ~10,000 declared renames that ran for hours (2026-10-06).
    alt = re.compile(r"\b(" + "|".join(sorted(map(re.escape, ren), key=len, reverse=True)) + r")\b")

    def rewrite(line):
        # a thunk slot's `(was T_F40FF0)` marker records the slot's ADDRESS name and is never renamed: protect it, or
        # a chain of declarations (T_F40FF0 -> T_Msg0716_PostOp17... -> T_Msg0716_PostClear..., 2026-10-06) rewrites it
        keep = re.findall(r"\(was T_[0-9A-F]{6}\)", line)
        out = re.sub(r"\(was T_[0-9A-F]{6}\)", "\x00", line)
        for _ in range(8):
            nxt = alt.sub(lambda m: ren[m.group(1)], out)
            if nxt == out:
                break
            out = nxt
        for k in keep:
            out = out.replace("\x00", k, 1)
        return out

    # Two more shapes this round produces on purpose, each of which REPLACES a
    # line rather than dropping it.  Both are only accepted when the text that
    # was there is still readable somewhere in the new file.
    titles = {"; sub_%06X" % a: f"; {n} -- 0x{a:06X}"
              for a, n, *_ in list(RENAMES) + list(CLEARERS) + [(a, n) for a, n in SMF_RENAMES]}
    titles.update({f"; {o}": f"; {n} -- 0x{o[4:]}"
                   for o, n in list(FX_RENAMES) + list(DF_RENAMES) + list(ED_RENAMES) + list(CN_RENAMES) + list(S53_RENAMES)
                   if o.startswith("sub_")})
    newtext = "\n".join(new)
    QUOTED = ("is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's",
              "rule that a stated gap beats a plausible guess.")

    # a `.incbin` that became assembly is not a lost line, it is a CONVERSION,
    # and the byte gate is what says the bytes did not move.
    CONVERTED = re.compile(r'^\s*\.incbin |^; --- 0x[0-9A-F]+-0x[0-9A-F]+: not converted ---$')
    stripped = "\n".join(l.strip().lstrip(";").strip() for l in new)
    flat = re.sub(r"\s+", " ", stripped)

    # a code line whose one NUMBER became the NAME of an equate with exactly that value
    # (scripts/converters/symbolize_wsa1_rom_addresses.py --apply): `.long 0x00FB22C8` ->
    # `.long SysExCmd_ResetSession`, `ld xiy, 16531727` -> `ld xiy, SoundEditDigitalEffect_Paint_DL1`,
    # `lda xix, (16579800:24)` -> `lda xix, (StepValues_FCFCD8:24)`.  The equate is read from the
    # working tree's own `.set NAME, VALUE` lines; the byte gate checks the value is the encoded one.
    EQU = re.compile(r"^\s*\.set\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*(?:;.*)?$")
    byval = collections.defaultdict(list)
    for l in new:
        m = EQU.match(l)
        if m:
            byval[int(m.group(2), 0)].append(m.group(1))
    # 2026-10-04: and the RAM equates prom_b includes -- scripts/tools/name_wsa1_ram.py turns
    # `bit 2,(148:8)` into `bit 2,(TransportA_State:8)` with a `.equ` in wsa1/include/wsa1_ram.inc.
    RAMEQU = re.compile(r"^\s*\.equ\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9A-Fa-f]+|\d+)")
    inc = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "include", "wsa1_ram.inc")
    if os.path.exists(inc):
        for l in open(inc, "rb").read().decode("latin-1").split("\n"):
            m = RAMEQU.match(l)
            if m:
                byval[int(m.group(2), 0)].append(m.group(1))
    NUM = re.compile(r"(?<![\w.$])(0x[0-9A-Fa-f]+|\d+)(?![\w.$])")

    def symbolized(line):
        if line.lstrip().startswith(";") or EQU.match(line):
            return None
        code, sep, rest = line.partition(";")
        for m in NUM.finditer(code):
            for name in byval.get(int(m.group(1), 0), ()):
                cand = code[:m.start()] + name + code[m.end():] + sep + rest
                if have[cand] > 0:
                    return cand
        return None

    old_labels = {LABEL.match(l).group(1) for l in old if LABEL.match(l)}
    newlabeled = collections.defaultdict(list)
    for l in new:
        for m in re.finditer(r"\b([A-Za-z_]\w*)\b", l.split(";")[0]):
            if m.group(1) in new_label_set and m.group(1) not in old_labels:
                newlabeled[l[:m.start()] + "@" + l[m.end():]].append(l)
    retyped = set()
    for l in new:
        m = re.match(r'^\s*\.(ascii|byte)\s+(.*?)\s*;\s*(F[0-9A-F]{5})\b', l)
        if not m:
            continue
        if m.group(1) == "ascii":
            n = len(re.sub(r'\\(.)', r'\1', m.group(2).strip()[1:-1]))
        else:
            n = len([x for x in m.group(2).split(",") if x.strip()])
        a = int(m.group(3), 16)
        retyped.update(range(a, a + n))
    newstarts = set()
    for l in new:
        m = re.search(r";\s*(F[0-9A-F]{5})\b", l)
        if m and not l.lstrip().startswith(";") and not re.match(r"^\s*\.byte\b", l):
            newstarts.add(int(m.group(1), 16))
            mw = re.match(r"^\s*\.(short|long)\s+(.*?)\s*;", l)
            if mw:                               # a word table covers all of its bytes
                w = 2 if mw.group(1) == "short" else 4
                n = len([x for x in mw.group(2).split(",") if x.strip()])
                newstarts.update(range(int(m.group(1), 16), int(m.group(1), 16) + w * n))
    equ_new = collections.defaultdict(list)
    for l in new:
        mq = re.match(r"^\s*\.equ\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9A-Fa-f]+)", l)
        if mq:
            equ_new[(mq.group(1), int(mq.group(2), 16))].append(l)
    kept = renamed = retitled = quoted = converted = deleted = symbolic = marked = 0
    missing = []
    for ln in old:
        if have[ln] > 0:
            have[ln] -= 1
            kept += 1
            continue
        r = rewrite(ln)
        if r != ln and have[r] > 0:
            have[r] -= 1
            renamed += 1
            continue
        # a RAM equate of wsa1/include/wsa1_ram.inc whose NAME is declared renamed and whose address is unchanged:
        # the include is generated from scripts/tools/name_wsa1_ram.py GROUPS, and a rename there may correct the
        # description too (2026-10-04: EditField_Note -> EditField_EventVelocity, the old text kept in the FINDINGS)
        # ... and one re-described under the SAME name (a GROUPS description corrected, 2026-10-04)
        me = re.match(r"^\s*\.equ\s+([A-Za-z_]\w*)\s*,\s*(0x[0-9A-Fa-f]+)", ln)
        if me:
            hit = next((c for c in equ_new.get((ren.get(me.group(1), me.group(1)), int(me.group(2), 16)), ()) if have[c] > 0), None)
            if hit is not None:
                have[hit] -= 1
                renamed += 1
                continue
        # a renamed thunk slot that also gained the `XXXXXX (was T_XXXXXX)` marker in its comment, exactly as
        # notes/prom_b_thunks_round6.py --mark writes it (2026-10-04); nothing else on the line may differ
        mt = re.match(r"^(T_([0-9A-F]{6})):", ln)
        if mt and r != ln and ";" in r:
            code, _sep, rest = r.partition(";")
            want = code + "; %s (was %s) %s" % (mt.group(2), mt.group(1), rest.strip())
            if have[want] > 0:
                have[want] -= 1
                marked += 1
                continue
        if ln in titles and have[titles[ln]] > 0:
            have[titles[ln]] -= 1
            retitled += 1
            continue
        # a DATA object's title: `; Data_XXXXXX -- rest` -> `; <new> -- 0xXXXXXX, rest`
        m = re.match(r"^; ([A-Za-z]\w*_([0-9A-F]{6})) -- (.*)$", ln)
        if m and m.group(1) in ren:
            want = f"; {ren[m.group(1)]} -- 0x{m.group(2)}, {m.group(3)}"
            if have[want] > 0:
                have[want] -= 1
                retitled += 1
                continue
        if ("Unknown: what the routine is FOR" in ln or
                "a stated gap beats a plausible guess" in ln or
                ln == "; Unknown: everything about it except its bytes.") and all(q in newtext for q in QUOTED):
            quoted += 1
            continue
        if CONVERTED.match(ln):
            converted += 1
            continue
        c = symbolized(ln)
        if c is not None:
            have[c] -= 1
            symbolic += 1
            continue
        # a renamed slot whose number ALSO became an equate of the same value (the rename helper, then
        # symbolize_wsa1_rom_addresses.py, on one line; 2026-10-06: T_F42250 -> T_DiskScreens_PhaseVector,
        # `.long 0x00FF75B6` -> `.long DiskScreens_PhaseVector`), with or without the `(was T_<addr>)` marker
        if r != ln:
            cands = [r]
            mt2 = re.match(r"^(T_([0-9A-F]{6})):", ln)
            if mt2 and ";" in r:
                code, _sep, rest = r.partition(";")
                cands.append(code + "; %s (was %s) %s" % (mt2.group(2), mt2.group(1), rest.strip()))
            c = next((x for x in map(symbolized, cands) if x is not None), None)
            if c is not None:
                have[c] -= 1
                symbolic += 1
                continue
        # `Label + 0xN` that became the name of a label now defined AT that address (2026-10-04: a posted painter
        # entry inside another routine's block got its own label); the byte gate checks the address
        if re.search(r"\b\w+ \+ 0x[0-9A-Fa-f]+\b", ln.split(";")[0]):
            key = re.sub(r"\b\w+ \+ 0x[0-9A-Fa-f]+\b", "@", ln)
            hit = next((c for c in newlabeled.get(key, ()) if have[c] > 0), None)
            if hit is not None:
                have[hit] -= 1
                symbolic += 1
                continue
        # an instruction line that was really data (text decoded as code) and is now inside a `.ascii` / `.byte`
        # line of the working tree that covers its address; the byte gate checks the bytes (2026-10-04)
        ma = re.search(r";\s*(F[0-9A-F]{5})\b", ln)
        if ma and not ln.lstrip().startswith((";", ".")) and int(ma.group(1), 16) in retyped:
            converted += 1
            continue
        # and the reverse: a `.byte` row that was really code (or a word table) and whose bytes now start new
        # instruction / .short / .long lines of the working tree (2026-10-04)
        mb = re.match(r"^\s*\.byte\s+(.*?)\s*;\s*(F[0-9A-F]{5})\b", ln)
        if mb:
            a0 = int(mb.group(2), 16)
            nb = len([x for x in mb.group(1).split(",") if x.strip()])
            if any(a in newstarts for a in range(a0, a0 + nb)):
                converted += 1
                continue
            # ...or whose bytes are all the tail of one new instruction that starts at most 7 bytes earlier (the
            # longest TLCS-900 encoding is 7): Data_F6D002's last row `.byte 0xE3` is the third byte of a calr
            # (2026-10-06)
            s = next((a0 - k for k in range(1, 8) if a0 - k in newstarts), None)
            if s is not None and not any(a in newstarts for a in range(a0, a0 + nb)) and \
                    any(b in newstarts for b in range(a0 + nb, a0 + nb + 8)):
                converted += 1
                continue
        # a comment line whose TEXT is quoted verbatim inside a replacement
        body = re.sub(r"\s+", " ", ln.strip().lstrip(";").strip())
        if ln.lstrip().startswith(";") and len(body) > 12 and body in flat:
            quoted += 1
            continue
        deleted += 1
        missing.append(ln)
    added = sum(v for v in have.values() if v > 0)

    old_c = sum(1 for l in old if l.lstrip().startswith(";"))
    new_c = sum(1 for l in new if l.lstrip().startswith(";"))
    old_l = {LABEL.match(l).group(1) for l in old if LABEL.match(l)}
    new_l = {LABEL.match(l).group(1) for l in new if LABEL.match(l)}
    lost = sorted(l for l in old_l if l not in new_l and ren.get(l, l) not in new_l)

    print(f"base {rev}:  {len(old)} lines, {old_c} comment lines, {len(old_l)} labels")
    print(f"working:     {len(new)} lines, {new_c} comment lines, {len(new_l)} labels")
    print(f"  kept verbatim          {kept}")
    print(f"  accounted for by a rename {renamed}")
    print(f"  header title rewritten as `; <name> -- 0x<addr>` {retitled}")
    print(f"  stanza REPLACED, its text quoted verbatim in the replacement {quoted}")
    print(f"  `.incbin` line CONVERTED to assembly, or an instruction re-typed as .ascii/.byte (byte gate is the proof) {converted}")
    print(f"  number -> equate of the same value (symbolize_wsa1_rom_addresses.py) {symbolic}")
    print(f"  renamed thunk slot that gained its `(was T_<addr>)` marker (prom_b_thunks_round6.py --mark) {marked}")
    print(f"  ADDED                  {added}")
    print(f"  UNACCOUNTED FOR        {deleted}")
    print(f"  labels lost (not renamed either): {len(lost)}  {lost[:8]}")
    if deleted and "--show-deleted" in sys.argv:
        for m in missing[:60]:
            print("    - " + m)
    return 1 if (deleted or lost) else 0


if __name__ == "__main__":
    sys.exit(main())
