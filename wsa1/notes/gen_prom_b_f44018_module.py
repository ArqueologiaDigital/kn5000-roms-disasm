#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF44018-0xF477FF -- the module that opens
immediately after the thunk table.

QUESTION IT ANSWERS
    "What is the assembly text for the three thunk-table runs T_F409C0-T_F40A30,
     T_F40A3C-T_F40A64 and T_F40A6C-T_F40AC8, in a form the byte gate accepts,
     with every label and header attached to the right address?"
    This is the emitter whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK
    notes/prom_b_module_frontier.py ranks three adjacent runs into this range
    1st, 5th and 6th by contiguous unconverted extent, and their summed reference
    upper bound -- 81 + 41 + 7 = 129 -- is the highest of any group in the image.
    T_Seq_RequestRewind -> 0xF4542D (x24) and T_F40A1C -> 0xF44367 (x15) are both in
    notes/prom_b_call_graph.py's top ten unconverted targets.

WHERE THE EXTENT COMES FROM
    Both edges are pinned by something other than the decode, which is what
    notes/prom_a_linear_decode_check.py insists on:
      START 0xF44018 is the first byte AFTER the 0xF40000 thunk table, whose
            extent (0x40000-0x44018, file offsets) is fixed by
            scripts/analysis/prom_b_thunk_table.py and already converted here.
      END   0xF47800 is a thunk target (T_F40B40), i.e. an address the linker
            chose, and the 5,867 bytes in front of it are pure 0x0E.
    Between them the two code segments decode with ZERO undecodable bytes and
    each ends exactly on its segment boundary.

THE TWO DATA OBJECTS
    0xF45E9A  Dispatch_3629 -- 5 pointers, selected by (0x3629).  Its length is
              fixed twice over: entries [3] and [4] BOTH hold 0xF45EAE, the byte
              immediately after the table, and a sixth entry would read
              0xCA96F00E, which is not an address in this image.
    0xF46074  WorkspaceDefaults -- 161 bytes copied into the 0x00603400 banked
              workspace by copy loops in this module.  ⚠ Only the first two
              blocks' lengths are established; see the header the emitter writes.

RUN
    python3 notes/gen_prom_b_f44018_module.py            # the assembly
    python3 notes/gen_prom_b_f44018_module.py --layout   # the segment table
    python3 notes/gen_prom_b_f44018_module.py --checks   # the assertions only
    python3 notes/gen_prom_b_f44018_module.py --copies   # every `ld XIX,0x00F460xx` site
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF44018, 0xF47800
TBL_LO, TBL_HI = 0x40000, 0x44018

# (kind, start, length).  Contiguity, the 0xF62C00 end and the purity of both
# `fill` runs are asserted in checks() -- this table is never trusted as typed.
LAYOUT = [
    ("code", 0xF44018, 0x1E82),
    ("data", 0xF45E9A, 0x014),
    ("code", 0xF45EAE, 0x1C6),
    ("data", 0xF46074, 0x0A1),
    ("fill", 0xF46115, 0x16EB),
]

# The two data objects.  DISPATCH's entry count and WORKSPACE's extent are both
# derived in checks(), never trusted as typed here.
DISPATCH = 0xF45E9A
WORKSPACE = 0xF46074

_cache = {}


def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1):
    return rom("b")[addr - B_BASE: addr - B_BASE + n]


def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        out = subprocess.run(
            [sys.executable, AUTOFORCE, "b", hex(start), hex(length), "--quiet"],
            capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr))
        _cache[key] = out.stdout.rstrip("\n").split("\n")
    return _cache[key]


def transcribe_pairs(s, n):
    for ln in transcribe(s, n):
        m = re.search(r";\s*([0-9A-F]{6})\s", ln)
        yield int(m.group(1), 16), ln


def code_lines():
    out = []
    for kind, s, n in LAYOUT:
        if kind != "code":
            continue
        out += list(transcribe_pairs(s, n))
    return out


def text_at(a):
    for ad, ln in code_lines():
        if ad == a:
            return ln.split(";", 1)[1].strip().split("  ", 1)[-1].strip()
    return ""


def boundaries():
    return {a for a, _ in code_lines()}


def thunks():
    """{target: [slot, ...]} for `jp nnn` slots landing in this range."""
    d, out = rom("b"), {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = d[o:o + 4]
        if s[0] == 0x1B:
            t = s[1] | s[2] << 8 | s[3] << 16
            if LO <= t < HI:
                out.setdefault(t, []).append(B_BASE + o)
    return out


def slot_refs():
    """Opcode-anchored UPPER BOUND on references to each thunk SLOT address."""
    cnt = {}
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if B_BASE + TBL_LO <= t < B_BASE + TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    return cnt


def direct_refs(addr):
    """Every byte offset in prom_a+prom_b that spells `addr` as a 32-bit LE word.
    An UPPER BOUND -- the scan is at every byte, not at instruction boundaries."""
    tgt = addr.to_bytes(4, "little")
    out = []
    for nm, blob, base in (("prom_a", rom("a"), A_BASE), ("prom_b", rom("b"), B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            out.append(base + i)
            i += 1
    return out


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments.
    Exact, not a byte window: every entry comes off a decoded instruction."""
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            out.setdefault(int(m.group(2), 16), []).append(a)
    return out




# --------------------------------------------------------------- data objects
def dispatch_entries():
    n = (0xF45EAE - DISPATCH) // 4
    return [int.from_bytes(at(DISPATCH + 4 * i, 4), "little") for i in range(n)]


def copy_sites():
    """Every `ld XIX,0x00F460xx` in the transcription: (site, source).
    A fact about the decoded text, nothing more -- the LENGTH each one copies is
    NOT derived here, for the reason WorkspaceDefaults' header gives."""
    out = []
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+ld XIX,0x00(f460[0-9a-f]{2})$", ln)
        if m:
            out.append((a, int(m.group(1), 16)))
    return out


DATA_LABEL = {
    0xF45E9A: "Dispatch_3629",
    0xF46074: "WorkspaceDefaults",
}

NAMES = {}

FORCE = {
    0xF45EAE: "the address BOTH Dispatch_3629[3] and [4] hold, and the byte "
              "immediately after that table -- so it is where the table ends and "
              "the code resumes",
}


def labels():
    got = {}
    for t in thunks():
        got[t] = None
    for callee in internal_calls():
        if LO <= callee < HI:
            got[callee] = None
    for e in dispatch_entries():
        if LO <= e < HI:
            got[e] = None
    got.update({a: None for a in DATA_LABEL})
    got.update({a: None for a in FORCE})
    for a in got:
        got[a] = NAMES.get(a) or DATA_LABEL.get(a) or "sub_%06X" % a
    return got


def wrap(prefix, text, width=76):
    body = textwrap.wrap(text, width - len(prefix))
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def touched(lo, hi):
    small, big = set(), set()
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small.add(int(m, 16))
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI):
                big.add(v)
    return sorted(small), sorted(big)


def calls_out(lo, hi, lab):
    out = []
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(1), 16)
            out.append(lab.get(t) or ("T_%06X" % t if 0xF40000 <= t < 0xF44018
                                      else "0x%06X" % t))
    seen = []
    for x in out:
        if x not in seen:
            seen.append(x)
    return seen


def byte_rows(a, n, per=16):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        out.append("\t.byte\t%s\t; %06X  [%d..%d]"
                   % (", ".join("0x%02X" % x for x in at(a + off, k)),
                      a + off, off, off + k - 1))
    return out


def dispatch_block(lab):
    e = dispatch_entries()
    rd = direct_refs(DISPATCH)
    out = ["; " + "-" * 74]
    out += wrap("; Dispatch_3629 -- ",
                "%d pointers, dispatched on (0x3629)." % len(e))
    out += wrap("; Read by: ",
                "one site: the `ld XIX,0x00F45E9A` at 0x%06X (a byte scan for the "
                "address reports 0x%06X, that instruction's OPERAND field, one "
                "byte in), then `ld A,(0x3629)` / `sll 0x02,XWA` / `add XIX,XWA` "
                "/ `ld XIX,(XIX)` / `call XIX` at 0xF45E8C-0xF45E97."
                % (rd[0] - 1, rd[0]))
    out += wrap("; Entry count: ",
                "%d, and it is fixed TWICE, neither time by dividing a byte "
                "extent by a guess.  (a) entries [3] and [4] BOTH hold 0x%06X, "
                "which is the byte immediately after the table, so the table "
                "cannot reach past it.  (b) a sixth entry would read 0x%08X, "
                "which is not an address in this image."
                % (len(e), e[3], int.from_bytes(at(DISPATCH + 4 * len(e), 4), "little")))
    out += wrap("; ⚠ Entries [3] and [4] are DEAD: ",
                "they point at the instruction the reader would fall into anyway. "
                " A whole-image linear decode finds (0x3629) written only with 0, "
                "1 and 2 (at 0xF569CB, 0xF569F4, 0xF56A59 and nine more) and "
                "compared only with 2, so nothing found selects [3] or [4].  That "
                "is an upper-bound scan over a linear decode of the whole image, "
                "not a proof that no other writer exists.")
    out += wrap("; Evidence: ",
                "the five words read out of the ROM; every one of them is an "
                "instruction boundary of this transcription, re-asserted on every "
                "emit.  The reader's five instructions are quoted above from the "
                "same transcription.")
    out += wrap("; Unknown: ", "what (0x3629) means, and what its three live arms do.")
    out.append("; " + "-" * 74)
    out.append("Dispatch_3629:")
    for i, p in enumerate(e):
        out.append("\t.long\t0x00%06X\t; [%d] -> %s"
                   % (p, i, lab.get(p, "0x%06X" % p)))
    return out


def workspace_block(lab):
    cs = copy_sites()
    out = ["; " + "-" * 74]
    out += wrap("; WorkspaceDefaults -- ",
                "161 bytes, the source of the copy loops that seed the banked 3 "
                "KiB workspace at 0x00603400 -- the same workspace "
                "notes/FINDINGS-prom_b-block-store.md derives.")
    out += wrap("; Extent: ",
                "0x%06X-0x%06X.  The start is where the last code segment's decode "
                "ends; the end is where 5,867 bytes of 0x0E begin, and 0x%06X is "
                "the byte before them and is 0x%02X, NOT 0x0E -- so unlike most "
                "pad boundaries in this image there is no `ret`-versus-padding "
                "ambiguity here."
                % (WORKSPACE, 0xF46114, 0xF46114, at(0xF46114, 1)[0]))
    out += wrap("; Read by: ",
                "%d `ld XIX,0x00F460xx` sites in this module: %s."
                % (len(cs), ", ".join("0x%06X (src 0x%06X)" % (s, v)
                                      for s, v in cs)))
    out += wrap("; Two blocks are ESTABLISHED, by reading their loops verbatim: ",
                "0x%06X -> 0x00603400, EIGHT bytes (`ld A,(XIX+IY)` / "
                "`ld (XHL+IY),A` / `inc 1,IY` / `cp IY,7` / `jr ULE`, so IY takes "
                "0..7), from the sites at 0xF44319 and 0xF4436F; and 0xF4607C -> "
                "0x00603414, also EIGHT bytes but a WORD loop (`ld WA,(XIX+IY)` / "
                "`add IY,0x0002` / `cp IY,0x0008` / `jr C`), from 0xF4433C."
                % WORKSPACE)
    out += wrap("; ⚠ NOT ESTABLISHED: ",
                "how the other %d bytes are partitioned.  The loops in this module "
                "differ in stride (byte and word) and in bound form (`cp IY,n / jr "
                "ULE` and `cp IY,n / jr C`), and the two do not mean the same "
                "count; an automated read of them gave NINE bytes for the "
                "0xF4607C block where the instructions say eight.  Rather than "
                "ship a partition that a mechanical reader got wrong once, the "
                "object is emitted as one labelled run of bytes and the gap is "
                "stated." % (len(cs) - 2 if len(cs) > 2 else 0))
    out += wrap("; Evidence: ",
                "the %d `ld XIX` sites are read out of this transcription's own "
                "decoded comments, and the destination 0x00603400 comes from the "
                "`ld XHL,0x00603400` two instructions in front of the first of "
                "them.  All 161 bytes are re-read from the ROM on every emit."
                % len(cs))
    out += wrap("; Unknown: ", "what the fields mean.")
    out.append("; " + "-" * 74)
    out.append("WorkspaceDefaults:")
    out += byte_rows(WORKSPACE, 0xA1)
    return out


def data_block(a, n, lab):
    if a == DISPATCH:
        return dispatch_block(lab)
    if a == WORKSPACE:
        return workspace_block(lab)
    raise AssertionError("no data block for 0x%06X" % a)


CURATED = {}


def header(a, end, lab, th, sr, ic):
    L = ["; " + "-" * 74]
    name = lab[a]
    L.append("; %s" % name)
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    if a in dispatch_entries():
        parts.append("dispatch entry Dispatch_3629[%s]"
                     % ", ".join(str(i) for i, e in enumerate(dispatch_entries())
                                 if e == a))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot, no in-module call site and no dispatch entry -- "
              "reached only by a branch from the routine above, or by a computed "
              "transfer")
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sm[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in bg[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    ev = FORCE.get(a)
    if ev:
        L += wrap("; Evidence: ", "the label is here because it is " + ev +
                  "; the address is an instruction boundary of this "
                  "transcription (re-asserted on every emit)")
    elif a in th:
        L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                  "0x%06X is an instruction boundary of this transcription "
                  "(re-asserted on every emit).  That is ALL the name rests on -- "
                  "the name IS the address." % (th[a][0], a, a))
    elif a in dispatch_entries():
        L += wrap("; Evidence: ", "0x%06X is stored in Dispatch_3629, whose reader "
                  "ends `ld XIX,(XIX) / call XIX`, and it is an instruction "
                  "boundary of this transcription.  The name IS the address." % a)
    else:
        L += wrap("; Evidence: ", "reached by a `call`/`calr` decoded in this "
                  "transcription (the sites are listed above), so 0x%06X is an "
                  "instruction boundary.  The name IS the address." % a)
    L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX with "
              "the gap stated, per this tree's rule that a stated gap beats a "
              "plausible guess.")
    L.append("; " + "-" * 74)
    return L


# ------------------------------------------------------------------- checks
FAIL = []


def check(msg, got, want, verbose=True):
    ok = got == want
    if verbose:
        print("  %-70s %-26s %s"
              % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def checks(verbose=True):
    del FAIL[:]
    c = lambda *a: check(*a, verbose=verbose)
    pos = LO
    for kind, s, n in LAYOUT:
        c("LAYOUT: %-4s 0x%06X starts where the last segment ended" % (kind, s),
          "0x%06X" % s, "0x%06X" % pos)
        pos = s + n
    c("LAYOUT ends at the next thunk target", "0x%06X" % pos, "0x%06X" % HI)
    c("LAYOUT covers 14,312 bytes", pos - LO, 14312)
    # the START is the byte after the thunk table, not a decode artefact
    c("0xF44018 is the first byte after the thunk table",
      "0x%06X" % (B_BASE + TBL_HI), "0x%06X" % LO)
    # the END is a thunk target
    th = thunks()
    c("0xF47800 (the end) is itself a thunk target",
      any(t == HI for t in [v for v in _all_thunk_targets()]), True)
    b = boundaries()
    # ⚠ THIS CHECK CAUGHT A CONFLATION, TWICE.  The first draft asserted that 64
    #    thunk SLOTS point in here and compared it against len(thunks()), which is
    #    the number of distinct TARGETS -- 62.  The repair then guessed 66 slots
    #    and was wrong again.  The truth, derived: 64 slots, 62 distinct targets,
    #    2 slots sharing a target with another slot.  Stating the unit is the
    #    whole point; "64" was never wrong, it was never a target count.
    nslots = sum(len(v) for v in th.values())
    c("thunk SLOTS pointing into this range", nslots, 64)
    c("...resolving to distinct TARGETS", len(th), 62)
    c("...so this many slots share a target with another", nslots - len(th), 2)
    c("every thunk target is an instruction boundary of the transcription",
      sorted("0x%06X" % t for t in th if t not in b), [])
    c("the LAST thunk target (0x%06X) is on a boundary" % max(th), max(th) in b, True)
    # the padding
    c("0xF46115-0xF477FF is 5867 bytes of 0x0E",
      (len(at(0xF46115, 0x16EB)), sorted(set(at(0xF46115, 0x16EB)))), (0x16EB, [0x0E]))
    c("the byte before it (0xF46114) is NOT 0x0E -- no ret/pad ambiguity here",
      at(0xF46114, 1)[0] != 0x0E, True)
    # Dispatch_3629
    e = dispatch_entries()
    c("Dispatch_3629 has 5 entries", len(e), 5)
    c("entries [3] and [4] are both 0xF45EAE, the byte after the table",
      ["0x%06X" % x for x in e[3:]], ["0xF45EAE", "0xF45EAE"])
    c("a sixth entry would not be an address in this image",
      LO <= int.from_bytes(at(DISPATCH + 20, 4), "little") < 0x1000000
      and 0xF00000 <= int.from_bytes(at(DISPATCH + 20, 4), "little") < 0x1000000, False)
    c("every entry is an instruction boundary", sorted(x for x in e if x not in b), [])
    rd = direct_refs(DISPATCH)
    c("exactly one site spells 0xF45E9A, at its reader's operand field",
      ["0x%06X" % x for x in rd], ["0xF45E88"])
    c("and the byte one earlier is 0x44 = `ld XIX,imm32`",
      "0x%02X" % at(rd[0] - 1, 1)[0], "0x44")
    # WorkspaceDefaults
    cs = copy_sites()
    c("WorkspaceDefaults has exactly the two established copy sites",
      ["0x%06X" % x for x in sorted(set(s for s, v in cs if v == WORKSPACE))],
      ["0xF44319", "0xF4436F"])
    c("its first block's loop bound is `cp IY,7` at 0xF4432A",
      text_at(0xF4432A), "cp IY,7")
    c("the word-loop block's bound is `cp IY,0x0008` at 0xF4434F",
      text_at(0xF4434F), "cp IY,0x0008")
    c("WorkspaceDefaults is 161 bytes", 0xF46115 - WORKSPACE, 161)
    # labels
    lab_ = labels()
    for a_, why in FORCE.items():
        c("FORCE 0x%06X: boundary, reason, and IN the label set" % a_,
          (a_ in b, bool(why), a_ in lab_), (True, True, True))
    c("every DATA label is in the label set",
      sorted("0x%06X" % x for x in DATA_LABEL if x not in lab_), [])
    dataspan = [(s, s + n) for k, s, n in LAYOUT if k in ("data", "fill")]
    c("no code label falls inside a data or fill segment",
      sorted("0x%06X" % a_ for a_ in lab_ if a_ not in DATA_LABEL
             and any(s <= a_ < e_ for s, e_ in dataspan)), [])
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in lab_ if x not in DATA_LABEL and x not in b), [])
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


def _all_thunk_targets():
    d = rom("b")
    for o in range(TBL_LO, TBL_HI, 4):
        s = d[o:o + 4]
        if s[0] == 0x1B:
            yield s[1] | s[2] << 8 | s[3] << 16


BANNER = """
; ==============================================================================
; 0xF44018-0xF477FF -- THE MODULE THAT OPENS IMMEDIATELY AFTER THE THUNK TABLE
;   64 thunk slots, three adjacent runs, and the highest summed reference count
;   of any group in the image
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_module_frontier.py ranks T_F409C0-T_F40A30,
; T_F40A3C-T_F40A64 and T_F40A6C-T_F40AC8 -- three ADJACENT runs, all pointing
; into this one range -- with a summed reference upper bound of 81 + 41 + 7 = 129,
; the highest of any group in prom_b.  T_Seq_RequestRewind -> 0xF4542D (x24) and
; T_F40A1C -> 0xF44367 (x15) are both in notes/prom_b_call_graph.py's top ten
; unconverted targets.  64 SLOTS point in here, resolving to 62 distinct TARGETS
; -- two slots share a target with another.  Both numbers are derived by --checks,
; and stating which unit a number is in is not pedantry here: the first draft of
; this file compared the slot count 64 against the target count and failed, and
; the repair guessed 66 slots and failed again.
;
; ⚠ WHERE THE EDGES COME FROM.  Neither is the decode's opinion:
;   START 0xF44018 is the first byte AFTER the 0xF40000 thunk table, whose extent
;         is fixed by scripts/analysis/prom_b_thunk_table.py and which this file
;         already converts.
;   END   0xF47800 is itself a thunk target (T_F40B40) -- an address the linker
;         chose -- and the 5,867 bytes in front of it are pure 0x0E.
; Between them the two code segments decode with ZERO undecodable bytes and each
; ends exactly on its segment boundary.
;
; THE TWO DATA OBJECTS
;
;   0xF45E9A  Dispatch_3629 -- 5 pointers on (0x3629).  Length fixed twice:
;             entries [3] and [4] BOTH hold 0xF45EAE, the byte immediately after
;             the table, and a sixth entry would read a non-address.  ⚠ [3] and
;             [4] are DEAD -- a whole-image decode finds (0x3629) written only
;             with 0, 1 and 2.
;
;   0xF46074  WorkspaceDefaults -- 161 bytes seeding the banked 3 KiB workspace
;             at 0x00603400 that notes/FINDINGS-prom_b-block-store.md derives.
;             ⚠ Only the first two blocks' lengths are established (8 bytes each,
;             one a byte loop and one a WORD loop); the rest of the partition is
;             stated as unknown rather than guessed, because an automated read of
;             those loops got one of the two lengths wrong.
;
; ⚠ WHAT IS NOT ESTABLISHED.  What any of the 128 routines DO.  They are
; `sub_XXXXXX` with a computed header claiming only the entry point.
;
; REGENERATE:  python3 notes/gen_prom_b_f44018_module.py
; CHECKS:      python3 notes/gen_prom_b_f44018_module.py --checks
; ==============================================================================
"""


def emit():
    lab, th, sr, ic = labels(), thunks(), slot_refs(), internal_calls()
    keys = sorted(lab)
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else HI) for i, a in enumerate(keys)}
    out = BANNER.strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind == "data":
            out += [""] + data_block(s, n, lab) + [""]
            continue
        for a, ln in transcribe_pairs(s, n):
            if a in lab:
                out += [""] + header(a, ends[a], lab, th, sr, ic)
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in th[a]) \
                      if a in th else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def main():
    if "--checks" in sys.argv:
        return 0 if checks() else 1
    if "--layout" in sys.argv:
        for kind, s, n in LAYOUT:
            print("  %-4s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
        return 0
    if "--copies" in sys.argv:
        for s, v in copy_sites():
            print("  site 0x%06X  src 0x%06X" % (s, v))
        return 0
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
