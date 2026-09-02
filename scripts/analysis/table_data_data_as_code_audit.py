#!/usr/bin/env python3
"""table_data_data_as_code_audit.py -- is any of table_data's "code" actually DATA
disassembled into plausible instruction mnemonics?

QUESTION ANSWERED: lane TABLEDATA's brief asks for this measurement on kn5000_table_data,
which nobody has run before -- its confirmed instances elsewhere (HD-AE5000's 309-byte
version string, its 6,356-byte RECORD_TABLE) were found by accident, and the byte gate
cannot catch this class by construction: reassembling a WRONG interpretation reproduces
the same ROM bytes, because a mnemonic line looks exactly like a converted instruction to
any tool that only asks "is this still a data directive?".

METHOD, adapted from wsa1/notes/data_as_code_audit.py to a SINGLE image with (almost)
entirely symbolic branch operands:

  1. FLATTEN kn5000_table_data.s with `llvm-mc -show-encoding` (the same authority the
     byte gate itself uses; mirrors scripts/analysis/l1_territory_map.py's directive-width
     table) to get an exact address for every instruction and every data directive.
  2. Group instruction addresses into maximal contiguous CODE REGIONS -- the set of spans
     the tree currently claims are instructions (any DATA/PADDING directive breaks a run).
  3. BRIDGE decoder gaps: one instruction in this tree (boot_fdc_driver.s's mem-to-mem LDW,
     `.byte 0xbf,0x04,0x16,0x00,0x0c ; ... no assembler mnemonic`) has no mnemonic this
     backend can print, so it is a genuine machine instruction sitting in the flattened
     stream as five separate `.byte N` lines with no marker at all (the printer drops
     comments and re-splits comma lists). Left alone, this 5-byte gap would split one
     fully-reached routine into two and manufacture a false "unreached" region. The ORIGINAL
     source is scanned separately for the "no assembler mnemonic" marker, its byte VALUES
     become a signature, and any run of `.byte` lines matching that signature is folded back
     into the surrounding code region instead of breaking it.
  4. Build a REFERENCE INDEX over the WHOLE flattened stream:
       - jp/call: this backend folds an absolute-immediate operand to a literal decimal at
         parse time (`jp BOOT_ENTRY` -> `jp 16757992`), so these need reverse-mapping. Two
         address spaces alias one byte range 0x600000 apart (ROM 0x9Fxxxx == boot-time
         0xFFxxxx, confirmed via the BOOT_*_HANDLER constants at the top of the file -- they
         print as `.set NAME, <decimal>`, not `.equ ... 0x...`, once flattened); both
         directions are tried.
       - jr/jrl/calr/djnz: this backend does NOT fold a relative fixup, so the operand is
         still the bare label text (`jr z, Boot_PrepareJump`) -- used directly.
       - .word/.long table entries whose operand is `Label[+CONST]` (BootSerial_
         StateDispatchTable and similar): also unfolded here, symbol used directly. This is
         how a jump/dispatch table's targets get counted without needing a separate pointer
         scan.
  5. A code region is REACHED if its start is a hardware entry point the CPU's own
     reset/interrupt logic fetches directly -- RESET_HANDLER (the reset vector) and every
     BOOT_*_HANDLER (NMI/INT4/INTA/INTT1/INTRX1/INTTX1/INTTC3/EMPTY) -- needing no incoming
     software reference at all, OR any control-transfer/table operand targets it. Regions are
     already MAXIMAL contiguous byte runs (bridged per step 3), so two distinct regions are
     never byte-adjacent: there is no separate "fallthrough" case to reason about, and every
     region boundary needs real evidence.

  6. THE NULL: reference collection uses the SAME regex machinery whether the operand
     belongs to a real branch or not. To prove that isn't vacuous (a classifier that finds
     everything referenced regardless of the bytes), --selftest reruns the whole pipeline
     against a POISONED copy of the tree with one real routine's only caller renamed to a
     nonexistent label -- if the poisoned run does not newly flag that routine unreached,
     the method is not sensitive and the finding is not trustworthy.

RESULT (see bottom of output): kn5000_table_data.s's boot code (18,681 B across 7 regions,
6,282 instructions -- table_data's ONLY code; everything else in the image is data) has
exactly ONE region with no connection to anything: Debug_OutputChar/boot_debug.s (82 B),
already disclosed in the source as "debug character output, DISABLED in shipped firmware"
with zero callers anywhere in the tree -- an honest factory leftover, not data misframed as
code. Every other region is either a hardware-vectored entry point or the target of a real
jp/jr/calr/djnz/table reference. No UNEXPLAINED unreached region, and therefore no evidence
of data-as-code on this image.

Run:
    python3 scripts/analysis/table_data_data_as_code_audit.py            # measure
    python3 scripts/analysis/table_data_data_as_code_audit.py --selftest # prove sensitivity
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
MC = pathlib.Path.home() / "compartilhado" / "llvm-project" / "build" / "bin" / "llvm-mc"
ROOT_S = REPO / "table_data" / "kn5000_table_data.s"
INCDIR = REPO / "table_data"

WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
LABEL_OPERAND = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*)')

# Explicitly documented, pre-existing dead-CODE-REGION exceptions -- a region whose START is
# never targeted by anything and is already disclosed in the source as intentionally inert.
# (Smaller single-instruction dead islands INSIDE an otherwise fully-reached region -- e.g.
# the `popw_erp`/`ret` filler pairs before LZSS_ReadByte and after HDAE5000_
# InitializeParallelPort's handoff jump, and Boot_free_DeadTail9998's orphaned copy inside
# boot_clib.s -- are not separately flagged by a REGION-START check at all: they sit inside
# the single contiguous, heavily-cross-referenced Boot_Init blob, already documented
# instruction-by-instruction. Only a region with NO connection to anything lands here.)
KNOWN_DEAD = {
    "Debug_OutputChar",   # boot_debug.s: "debug character output, DISABLED in shipped
                          # firmware" -- no caller anywhere in table_data/*.s, confirmed by
                          # grep as well as this reachability pass; an honest factory leftover.
}

ALIAS_DELTA = 0x600000   # ROM 0x9Fxxxx <-> boot-time alias 0xFFxxxx (BOOT_*_HANDLER .equ pairs)
ROM_BASE = 0x800000      # pos (as tracked below) == ROM address - ROM_BASE


def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        total += len(ESCAPE.sub("X", m.group(1)))
    return total


def flatten(root_s=ROOT_S, incdir=INCDIR):
    out = subprocess.run([str(MC), "-triple=tlcs900", "-show-encoding", "-I", str(incdir),
                          str(root_s)], capture_output=True, text=True, cwd=REPO)
    if out.returncode != 0:
        sys.exit(f"llvm-mc failed on {root_s}:\n{out.stderr[:800]}")
    return out.stdout


NO_MNEMONIC_BYTE_LINE = re.compile(
    r'\.byte\s+((?:0x[0-9a-fA-F]+|\d+)(?:\s*,\s*(?:0x[0-9a-fA-F]+|\d+))*)\s*;.*no assembler mnemonic')


def bridge_signatures(incdir=INCDIR):
    """Byte-value sequences of every `.byte ...; ... no assembler mnemonic` line in the
    SOURCE (not the flattened stream: llvm-mc's -show-encoding printer re-splits a
    comma-list .byte directive into one bare `.byte N` line per byte and drops the original
    comment entirely, so the marker has to be read from source and matched by VALUE)."""
    sigs = []
    for s in sorted(incdir.glob("*.s")):
        for line in s.read_text(encoding="latin1").splitlines():
            m = NO_MNEMONIC_BYTE_LINE.search(line)
            if m:
                sigs.append(tuple(int(x.strip(), 0) for x in m.group(1).split(",")))
    return sigs


def analyse(text, sigs=()):
    pos = 0
    labels = {}                 # label -> pos
    code_bytes = set()          # every pos byte covered by an instruction
    bridge_bytes = set()        # .byte runs documented as ONE real instruction this backend
                                 # cannot encode (comment says "no assembler mnemonic") --
                                 # real machine code, just not decoded; bridges fallthrough
    insn_at = {}                 # pos -> (mnemonic, operand)
    insn_starts = []             # ordered list of instruction start positions
    xfer_targets = []            # list of (from_pos, target_label_or_None, target_pos_or_None)
    last_label = None
    maxlen = max((len(s) for s in sigs), default=0)
    recent_vals = []            # [(pos, value), ...] tail window, len <= maxlen

    for line in text.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.endswith(":") and not s.startswith(";"):
            lbl = s[:-1]
            labels[lbl] = pos
            last_label = lbl
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            mnem_operand = s.split(";", 1)[0].strip()
            parts = mnem_operand.split(None, 1)
            mnem = parts[0] if parts else ""
            operand = parts[1] if len(parts) > 1 else ""
            insn_at[pos] = (mnem, operand)
            insn_starts.append(pos)
            for b in range(n):
                code_bytes.add(pos + b)
            # control transfer? capture the target (symbolic if unfolded, numeric if folded)
            if mnem in ("jp", "jr", "jrl", "call", "calr", "djnz", "cald"):
                # operand may be "cc, target" or just "target"
                tail = operand.split(",")[-1].strip()
                m = LABEL_OPERAND.match(tail)
                if m and not tail[0].isdigit() and not tail.startswith("-"):
                    xfer_targets.append((pos, m.group(1), None))
                else:
                    try:
                        xfer_targets.append((pos, None, int(tail, 0)))
                    except ValueError:
                        pass
            pos += n
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            # symbolic Label[+CONST] operands in data directives are NOT folded by this
            # backend -- capture them as table-driven code references.
            for opnd in [x.strip() for x in rest.split(",") if x.strip()]:
                sm = LABEL_OPERAND.match(opnd)
                if sm and not opnd[0].isdigit() and not opnd.startswith("-"):
                    xfer_targets.append((pos, sm.group(1), None))
            n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
            if d == "byte" and maxlen:
                vals = [int(x.strip(), 0) for x in rest.split(",") if x.strip()]
                for i, v in enumerate(vals):
                    recent_vals.append((pos + i, v))
                recent_vals[:] = recent_vals[-maxlen:]
                for sig in sigs:
                    L = len(sig)
                    if len(recent_vals) >= L and tuple(v for _, v in recent_vals[-L:]) == sig:
                        # a genuine machine instruction this backend cannot encode, kept as
                        # .byte and documented as such (e.g. boot_fdc_driver.s's LDW
                        # mem-to-mem form) -- NOT data-as-code; must not fool the
                        # reachability check into treating the code right after it as a
                        # fresh, unreferenced region (see the region-bridging in run()).
                        for p, _ in recent_vals[-L:]:
                            bridge_bytes.add(p)
            pos += n
        elif d in ("ascii", "asciz"):
            pos += ascii_len(rest) + (1 if d == "asciz" else 0)
        elif d in ("zero", "fill", "space"):
            parts = [p.strip() for p in rest.split(",")]
            n = int(parts[0], 0)
            if d == "fill" and len(parts) >= 2:
                n *= int(parts[1], 0)
            pos += n
        elif d == "p2align":
            a = 1 << int(rest.split(",")[0], 0)
            pos += (-pos) % a
        elif d == "org":
            target = int(rest.split(",")[0], 0)
            if target > pos:
                pos = target
        # .set/.equ/.text/.globl/etc: no bytes
    return labels, code_bytes, bridge_bytes, insn_at, insn_starts, xfer_targets


HANDLER_EQU = re.compile(r'^\.set\s+(BOOT_\w+_HANDLER)\s*,\s*(\d+)\s*$')


def hardware_vector_entries(root_text):
    """BOOT_*_HANDLER .equ constants (top of kn5000_table_data.s) name boot-time (0xFFxxxx)
    addresses the CPU's own reset/interrupt hardware fetches directly -- they need no
    incoming jp/calr/jr in this source at all, the same way RESET_HANDLER does not.
    llvm-mc's -show-encoding printer re-emits `.equ` as `.set` with the value folded to
    decimal, so that is the form matched here (confirmed against the flattened stream, not
    assumed from the source spelling)."""
    entries = {}
    for line in root_text.split("\n"):
        m = HANDLER_EQU.match(line.strip())
        if m:
            entries[m.group(1)] = int(m.group(2)) - ROM_BASE - ALIAS_DELTA
    return entries


def resolve_pos(target_pos):
    """A numeric jp/call operand may be a ROM address or its 0x600000-away boot alias;
    both map back to the same `pos` space (pos = ROM address - ROM_BASE)."""
    candidates = [target_pos - ROM_BASE, target_pos - ROM_BASE - ALIAS_DELTA,
                  target_pos - ROM_BASE + ALIAS_DELTA]
    return candidates


def run(root_s=ROOT_S, incdir=INCDIR, verbose=True):
    text = flatten(root_s, incdir)
    sigs = bridge_signatures(incdir)
    labels, code_bytes, bridge_bytes, insn_at, insn_starts, xfer_targets = analyse(text, sigs)
    label_at = {}
    for lbl, p in labels.items():
        label_at.setdefault(p, lbl)
    pos_of_label = labels

    # --- code regions: maximal runs of contiguous instruction bytes, bridged across any
    #     documented "no assembler mnemonic" .byte run (real code, just undecoded -- see
    #     analyse()) so one decoder gap cannot masquerade as a region boundary ---
    sorted_bytes = sorted(code_bytes | bridge_bytes)
    regions = []
    if sorted_bytes:
        rs = sorted_bytes[0]
        prev = sorted_bytes[0]
        for b in sorted_bytes[1:]:
            if b != prev + 1:
                regions.append((rs, prev + 1))  # [start, end)
                rs = b
            prev = b
        regions.append((rs, prev + 1))

    # --- reference index: positions targeted by some transfer/table entry ---
    referenced = set()
    for from_pos, tgt_label, tgt_num in xfer_targets:
        if tgt_label is not None:
            if tgt_label in pos_of_label:
                referenced.add(pos_of_label[tgt_label])
        elif tgt_num is not None:
            for cand in resolve_pos(tgt_num):
                if cand in label_at or any(r[0] <= cand < r[1] for r in regions):
                    referenced.add(cand)

    # hardware entry points need no incoming jp/calr/jr: the reset vector (RESET_HANDLER)
    # and every interrupt handler named by a BOOT_*_HANDLER .equ are fetched directly by
    # the CPU's own reset/interrupt hardware.
    for name, p in hardware_vector_entries(text).items():
        referenced.add(p)
    if "RESET_HANDLER" in pos_of_label:
        referenced.add(pos_of_label["RESET_HANDLER"])

    # --- classify each region --- (regions are already maximal contiguous runs, bridged
    # across decoder-gap .byte instructions above, so two DISTINCT regions are never
    # byte-adjacent; every region boundary is a real gap and needs real evidence)
    findings = []
    for (rs, re_) in regions:
        reached = rs in referenced
        name = label_at.get(rs, f"0x{rs + ROM_BASE:06X}")
        status = "REACHED" if reached else "UNREACHED"
        findings.append((rs, re_, name, status))

    unexplained = [f for f in findings if f[3] == "UNREACHED" and f[2] not in KNOWN_DEAD]

    if verbose:
        code_total = sum(re_ - rs for rs, re_, _, _ in findings)
        print(f"kn5000_table_data.s: {len(findings)} code region(s), {code_total:,} code bytes "
              f"total, {len(insn_starts):,} instructions")
        for rs, re_, name, status in findings:
            mark = "  " if status != "UNREACHED" else ("!!" if name not in KNOWN_DEAD else "ok")
            print(f"  {mark} 0x{rs + ROM_BASE:06X}-0x{re_ + ROM_BASE - 1:06X}  "
                  f"{re_ - rs:>6,} B  {status:<12} {name}")
        print()
        if unexplained:
            print(f"*** {len(unexplained)} UNEXPLAINED unreached region(s) -- possible "
                  f"data-as-code:")
            for rs, re_, name, status in unexplained:
                print(f"    0x{rs + ROM_BASE:06X}-0x{re_ + ROM_BASE - 1:06X}  {name}")
        else:
            known_hit = [f for f in findings if f[3] == "UNREACHED" and f[2] in KNOWN_DEAD]
            print(f"NO UNEXPLAINED data-as-code found: {len(findings)} region(s) all REACHED, "
                  f"except {len(known_hit)} already-documented dead-code "
                  f"exception(s): {[f[2] for f in known_hit]}")
    return findings, unexplained


def _mirror_tree(td):
    """A temp copy of the repo where table_data/ is real (poisonable) and everything else is
    symlinked, so table_data/*.s's .incbins that reach OUTSIDE table_data/ (e.g. ui_bitmaps.s's
    "../v10/maincpu/images/*.bin", resolved relative to the -I directory's parent) still work."""
    tmproot = pathlib.Path(td)
    for entry in REPO.iterdir():
        if entry.name == "table_data":
            continue
        (tmproot / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
    mirror = tmproot / "table_data"
    mirror.mkdir()
    for entry in (REPO / "table_data").iterdir():
        (mirror / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
    return mirror


def _try_poison(victim):
    """Rename every REFERENCE to `victim` (not its own label definition) in a mirror of the
    tree, then re-run the pipeline against the mirror. Returns the newly-UNREACHED region
    names, or None if the rename touched nothing (victim text does not appear as an operand)."""
    with tempfile.TemporaryDirectory() as td:
        mirror = _mirror_tree(td)
        poisoned = False
        for s in list(mirror.glob("*.s")):
            text = s.read_text(encoding="latin1")
            new_text = re.sub(rf'(?<![\w.]){re.escape(victim)}(?!:)(?![\w.])',
                               victim + "_POISONED_UNREACHABLE_REF", text)
            if new_text != text:
                # restore the label DEFINITION line itself (the one ending in ":")
                new_text = new_text.replace(victim + "_POISONED_UNREACHABLE_REF:", victim + ":")
                s.unlink()  # was a symlink to the REAL file -- replace it, never follow-write
                s.write_text(new_text, encoding="latin1")
                poisoned = True
        if not poisoned:
            return None
        p_findings, _ = run(root_s=mirror / "kn5000_table_data.s", incdir=mirror, verbose=False)
        return {f[2] for f in p_findings if f[3] == "UNREACHED"}


def selftest():
    """Poison a copy of the tree so ONE real routine's only reference no longer names it, and
    assert the pipeline newly reports that routine UNREACHED. If none of the candidates ever
    flip, the reference collector is not actually sensitive to the source text and the main
    finding is not trustworthy."""
    findings, unexplained = run(verbose=False)
    if unexplained:
        sys.exit(f"SELFTEST ABORTED: base run already has {len(unexplained)} unexplained "
                  f"region(s) -- fix or update KNOWN_DEAD before trusting the null test")
    baseline_unreached = {f[2] for f in findings if f[3] == "UNREACHED"}

    # A sub-label mid-region has no effect on a REGION-START-only check (poisoning its one
    # caller just leaves it silently unreached-but-invisible inside an already-reached
    # region -- the same reason single dead instructions like Boot_free_DeadTail9998 don't
    # show up as their own finding). A REGION START reached via a raw numeric jp fold (e.g.
    # Boot_Init, whose only entry is `jp BOOT_ENTRY` where BOOT_ENTRY is a hardcoded hex
    # `.equ`, not the text "Boot_Init") also can't be poisoned by renaming -- the numeric
    # target doesn't care what the label text says. So this tries every REACHED region-start
    # candidate (skipping the implicit hardware entry points, which need no reference at
    # all) until one actually flips, rather than assuming the first is poisonable.
    hw_entries = set(hardware_vector_entries(flatten()).keys()) | {"RESET_HANDLER"}
    candidates = [f[2] for f in findings if f[3] == "REACHED" and f[2] not in hw_entries]

    tried = []
    for victim in candidates:
        p_unreached = _try_poison(victim)
        if p_unreached is None:
            continue
        newly_unreached = p_unreached - baseline_unreached
        tried.append(victim)
        if victim in newly_unreached:
            print(f"SELFTEST OK: poisoning {victim}'s only reference correctly flagged it as "
                  f"newly UNREACHED ({sorted(newly_unreached)}) after trying "
                  f"{len(tried)} candidate(s) -- the reachability classifier is sensitive to "
                  f"the actual source text, not vacuous.")
            return
    sys.exit(f"SELFTEST FAILED: none of {len(tried)} poisoned candidate(s) {tried} became "
              f"newly UNREACHED -- the method may not be sensitive to source text at all")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        _, unexplained = run()
        sys.exit(1 if unexplained else 0)
