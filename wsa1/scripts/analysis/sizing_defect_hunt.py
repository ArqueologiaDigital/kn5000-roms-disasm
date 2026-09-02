#!/usr/bin/env python3
"""Hunt for the recurring "oversized reachability object" defect (lane SIZINGHUNT).

QUESTION THIS ANSWERS
    On 2026-09-02, three `Data_Fxxxxxx` objects in prom_b turned out to be
    sized 2-83 bytes too large: an earlier reachability-coverage pass drew
    each object's END past its own real structure, so the trailing bytes it
    absorbed were actually the LEADING records of the display list that
    starts right after it. The symptom is invisible in both directions -- the
    oversized object still looks like ordinary data, and the truncated list
    still looks like it simply starts a few bytes later -- so nothing fires
    and no build check can catch it (see gen_prom_b_f0d081_module.py,
    gen_prom_b_f3b3da_module.py, gen_prom_b_f036c2_module.py, and
    notes/DEBT-INVENTORY-2026-09-02.md's "recurring sizing defect" section).

    This module answers: does the SAME shape recur anywhere else -- other
    spans of prom_a/prom_b, or (structurally only, since no display-list
    walker exists for them here) other images?

THE SIGNATURE, GENERALISED FROM THE THREE KNOWN INSTANCES
    1. A labelled data object with a header comment declaring an explicit
       byte count: `; <Label> -- <N> bytes`.
    2. Its content is a RECOMPUTABLE regular structure for a clean PREFIX --
       either a repeating 8-byte (x1,y1,x2,y2) coordinate entry (x1,x2
       constant, y1,y2 stepping by a constant delta) or a repeating 4-byte
       pointer whose targets land in a plausible local neighbourhood -- and
       then some SMALL trailing remainder (the three known cases: 2, 13, 83
       bytes) that does NOT continue the pattern.
    3. Immediately after the object's declared end sits more undecided
       territory (`.incbin` of the raw ROM), and further out, a boundary
       this tree ALREADY trusts: a call-site-documented display-list end, or
       the start of an already-committed label.
    4. Shrinking the object to the clean prefix and walking the freed bytes
       plus the intervening `.incbin` as interpreter-A/B display-list
       records (the walker in prom_b_display_lists.py: op < 0x24, length
       byte, self-framing) lands with ZERO DRIFT -- not "close", exact --
       on that already-trusted boundary. That landing, not the shrink alone,
       is what makes a correction legitimate (project rule: a boundary fixed
       by nothing more than "the walk stops looking plausible" is refused).

WHAT THIS SCRIPT DOES
    --selftest   plants a known-oversized synthetic object and a correctly-
                 sized one in a fake image, and requires the detector to
                 flag the first and clear the second (the sizing hunt has
                 twice shipped a check that could not go red; this one must
                 be able to).
    --scan FILE  parses one .s file, finds every `; Label -- N bytes` object,
                 tests the structural shrink, and where a shrink is found,
                 attempts the display-list zero-drift walk against BOTH
                 prom_a and prom_b's raw bytes (the interpreter's data can
                 live in either half of the shared 0xF00000-0xFFFFFF space).
    --null N     the null-rate control: for N randomly chosen start offsets
                 within the *already load-bearing* part of the image (never
                 inside a found candidate), how often does the SAME "walk
                 lands with zero drift on a real label start" test fire by
                 chance? Reported once per session, not per candidate --
                 the walk's self-framing constraint (length bytes must sum
                 exactly to a target that is itself a real, already-placed
                 label) is what keeps this low; --null measures it rather
                 than asserting it.

RUN
    python3 wsa1/scripts/analysis/sizing_defect_hunt.py --selftest
    python3 wsa1/scripts/analysis/sizing_defect_hunt.py --scan wsa1/prom_a/wsa1_prom_a.s
    python3 wsa1/scripts/analysis/sizing_defect_hunt.py --scan wsa1/prom_b/wsa1_prom_b.s
    python3 wsa1/scripts/analysis/sizing_defect_hunt.py --null 20000
"""
import os
import random
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL  # noqa: E402

B_BASE, A_BASE, TOP = 0xF00000, 0xF80000, 0x1000000

HEADER_RE = re.compile(r'^;\s*([A-Za-z_][A-Za-z0-9_]*)\s*--\s*(\d+)\s*bytes', re.M)
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', re.M)
DATA_LINE_RE = re.compile(r'^\t\.(byte|long|short|word)\b')
INCBIN_RE = re.compile(r'^\t\.incbin\s+"([^"]+)",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')
ADDR_SUFFIX_RE = re.compile(r'_([0-9A-Fa-f]{6})$')
ADDR_COMMENT_RE = re.compile(r';\s*([0-9A-Fa-f]{6})\b')


# ----------------------------------------------------------------------------
# structural corroboration: how many bytes at the START of `data` are a clean,
# recomputable repeating structure?  Returns the byte count of the clean
# prefix (a multiple of the entry size), or 0 if even the first entry fails.
# ----------------------------------------------------------------------------

def _coord_run_at(data, header):
    n = (len(data) - header) // 8
    if n < 2:
        return 0
    entries = [struct.unpack_from("<4H", data, header + i * 8) for i in range(n)]
    x1c, x2c = entries[0][0], entries[0][2]
    run = 0
    for e in entries:
        if e[0] == x1c and e[2] == x2c:
            run += 1
        else:
            break
    if run < 2:
        return 0
    y1steps = {entries[i][1] - entries[i - 1][1] for i in range(1, run)}
    y2steps = {entries[i][3] - entries[i - 1][3] for i in range(1, run)}
    if len(y1steps) == 1 and len(y2steps) == 1 and next(iter(y1steps)) != 0:
        return run * 8
    return 0


def coord_array_clean_prefix(data):
    """Largest clean_prefix over the "coordinate array" hypothesis, trying
    both a bare array (Data_F0D061's shape: entries from byte 0) and one
    small fixed HEADER before the entries start (Data_F3B3B2's shape: an
    8-byte (0,0,1,1) header, then the array) -- both are real, already-fixed
    instances, so the detector must cover both without being told which."""
    best = 0
    for header in (0, 8):
        run_bytes = _coord_run_at(data, header)
        if run_bytes:
            best = max(best, header + run_bytes)
    return best


def ptr_table_clean_prefix(data, addr, neighborhood=0x2000):
    n = len(data) // 4
    if n < 2:
        return 0
    run = 0
    for i in range(n):
        p = int.from_bytes(data[i * 4:i * 4 + 4], "little")
        if abs(p - addr) <= neighborhood:
            run += 1
        else:
            break
    if run < 2:
        return 0
    return run * 4


def clean_prefix(data, addr):
    """Best structural shrink point: the larger of the two hypotheses."""
    return max(coord_array_clean_prefix(data), ptr_table_clean_prefix(data, addr))


# ----------------------------------------------------------------------------
# parsing one .s file for "; Label -- N bytes" objects and what follows them
# ----------------------------------------------------------------------------

class Obj:
    def __init__(self, label, size, addr, follow_kind, follow_rom, follow_off,
                 follow_len, next_label, next_addr):
        self.label, self.size, self.addr = label, size, addr
        self.follow_kind = follow_kind      # "incbin" or "label" or None
        self.follow_rom, self.follow_off, self.follow_len = follow_rom, follow_off, follow_len
        self.next_label, self.next_addr = next_label, next_addr


def guess_addr(label, lines, label_line_idx):
    m = ADDR_SUFFIX_RE.search(label)
    if m:
        return int(m.group(1), 16)
    for j in range(label_line_idx + 1, min(len(lines), label_line_idx + 3)):
        m = ADDR_COMMENT_RE.search(lines[j])
        if m:
            return int(m.group(1), 16)
    return None


def parse_objects(text):
    lines = text.split("\n")
    objs = []
    headers = {}  # label -> declared size, found scanning header comments
    for m in HEADER_RE.finditer(text):
        headers.setdefault(m.group(1), int(m.group(2)))
    for i, line in enumerate(lines):
        lm = LABEL_RE.match(line)
        if not lm:
            continue
        label = lm.group(1)
        if label not in headers:
            continue
        size = headers[label]
        addr = guess_addr(label, lines, i)
        if addr is None:
            continue
        k = i + 1
        while k < len(lines) and DATA_LINE_RE.match(lines[k]):
            k += 1
        # skip blank/comment lines to find what follows the data block
        k2 = k
        while k2 < len(lines) and (lines[k2].strip() == "" or lines[k2].startswith(";")):
            k2 += 1
        follow_kind = follow_rom = follow_off = follow_len = None
        next_label = next_addr = None
        if k2 < len(lines):
            im = INCBIN_RE.match(lines[k2])
            if im:
                follow_kind = "incbin"
                follow_rom, follow_off, follow_len = im.group(1), int(im.group(2), 16), int(im.group(3), 16)
                # find the label right after this incbin
                k3 = k2 + 1
                while k3 < len(lines):
                    nl = LABEL_RE.match(lines[k3])
                    if nl:
                        next_label = nl.group(1)
                        next_addr = guess_addr(next_label, lines, k3)
                        break
                    if lines[k3].strip() == "" or lines[k3].startswith(";"):
                        k3 += 1
                        continue
                    break
            else:
                nl = LABEL_RE.match(lines[k2])
                if nl:
                    follow_kind = "label"
                    next_label = nl.group(1)
                    next_addr = guess_addr(next_label, lines, k2)
        objs.append(Obj(label, size, addr, follow_kind, follow_rom, follow_off, follow_len,
                         next_label, next_addr))
    return objs


# ----------------------------------------------------------------------------
# zero-drift landing test
# ----------------------------------------------------------------------------

def _combined(a, b):
    """prom_b, then prom_a, concatenated: DL.walk()/HTBL always subtract
    B_BASE, and B_BASE..A_BASE..A_BASE+len(a) is exactly prom_b then prom_a
    back to back (each ROM is 0x80000 bytes and A_BASE-B_BASE == 0x80000),
    so this one buffer lets the SAME walker cover both halves of the shared
    0xF00000-0xFFFFFF address space without re-deriving offsets per branch."""
    return b + a


def try_landing(a, b, recovered_start, landing_target):
    """Does DL.walk() frame [recovered_start, landing_target) exactly, with every
    opcode a documented handler and no same-byte fill record?  Returns the
    record list on success, None on failure."""
    if landing_target <= recovered_start:
        return None
    if not (B_BASE <= recovered_start < TOP and B_BASE < landing_target <= TOP):
        return None
    combined = _combined(a, b)
    recs = DL.walk(combined, recovered_start, landing_target)
    if recs is None:
        return None
    # the handler table itself lives only in prom_b (0xF31D21); a walk whose
    # records sit in prom_a still resolves opcodes against it, exactly as the
    # real interpreter would (one kernel, shared code, per the WSA1R notes).
    htab = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    for p, op, ln in recs:
        if op >= len(htab) or htab[op] not in DL.HANDLERS:
            return None
        raw = combined[p - B_BASE:p - B_BASE + ln]
        if len(set(raw)) <= 1:
            return None
    return recs


def scan_file(path, a, b, root=ROOT):
    text = open(os.path.join(root, path), encoding="utf-8", errors="replace").read()
    objs = parse_objects(text)
    findings = []
    for o in objs:
        if o.follow_kind != "incbin":
            continue  # nothing to recover into: object already borders real source
        old_end = o.addr + o.size
        # sanity: does the incbin's own declared address match old_end?
        base = A_BASE if old_end >= A_BASE else B_BASE
        expect_off = old_end - base
        if o.follow_off != expect_off:
            continue  # our address bookkeeping disagrees with the file; skip, don't guess
        img = a if base == A_BASE else b
        data = img[o.addr - base:old_end - base]
        cp = clean_prefix(data, o.addr)
        tail = o.size - cp
        if not (0 < tail <= 200):
            continue
        recovered_start = o.addr + cp
        landing_candidates = []
        if o.next_addr is not None:
            landing_candidates.append(o.next_addr)
        landing_candidates.append(old_end + o.follow_len)  # far end of the .incbin
        hit = None
        for target in landing_candidates:
            recs = try_landing(a, b, recovered_start, target)
            if recs is not None:
                hit = (target, recs)
                break
        findings.append({
            "label": o.label, "addr": o.addr, "declared_size": o.size,
            "clean_prefix": cp, "tail": tail, "recovered_start": recovered_start,
            "old_end": old_end, "incbin_len": o.follow_len,
            "landing": hit,
        })
    return findings


# ----------------------------------------------------------------------------
# null-rate control
# ----------------------------------------------------------------------------

_INCBIN_RE_M = re.compile(INCBIN_RE.pattern, re.M)


def _incbin_spans(text, base):
    """[(addr, length), ...] for every raw-ROM .incbin directive still in a
    file, converted from file offset to address via `base`."""
    out = []
    for m in _INCBIN_RE_M.finditer(text):
        _rom, off, length = m.group(1), int(m.group(2), 16), int(m.group(3), 16)
        out.append((base + off, length))
    return out


def _all_label_addrs(text):
    lines = text.split("\n")
    addrs = set()
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if not m:
            continue
        a = guess_addr(m.group(1), lines, i)
        if a is not None:
            addrs.add(a)
    return addrs


def compute_null_rate(a, b, n, seed=0, root=ROOT):
    """How often does the SAME test a real candidate must pass -- walk from an
    arbitrary point and land with zero drift on an already-trusted boundary
    -- fire purely by chance?

    The honest control samples starts from territory a real candidate would
    actually be drawn from: bytes CURRENTLY still `.incbin` (undetermined,
    not already known to be list records), not the whole image -- most of
    the image already IS legitimate, self-framing display-list data, and
    sampling there would inflate the rate with starts that succeed only
    because they sit inside real records already, which is not the question.
    Landmarks are every already-placed label address plus every call-site-
    verified list end -- the same corpus a real candidate's landing test is
    checked against -- searched within the same local radius scan_file uses
    (the very next boundary, never an unbounded search)."""
    text_b = open(os.path.join(root, "prom_b", "wsa1_prom_b.s"), encoding="utf-8", errors="replace").read()
    text_a = open(os.path.join(root, "prom_a", "wsa1_prom_a.s"), encoding="utf-8", errors="replace").read()
    spans = _incbin_spans(text_b, B_BASE) + _incbin_spans(text_a, A_BASE)
    spans = [(addr, ln) for addr, ln in spans if ln >= 2]
    weights = [ln for _addr, ln in spans]
    total = sum(weights)
    landmarks = sorted(_all_label_addrs(text_b) | _all_label_addrs(text_a)
                        | {e for _s, e, _t in DL.call_sites(a, b)})
    rng = random.Random(seed)
    hits = tried = 0
    for _ in range(n):
        r = rng.randrange(total)
        for addr, ln in spans:
            if r < ln:
                start = addr + r
                break
            r -= ln
        import bisect
        i = bisect.bisect_right(landmarks, start)
        if i >= len(landmarks) or landmarks[i] - start > 4096:
            continue
        tried += 1
        if try_landing(a, b, start, landmarks[i]) is not None:
            hits += 1
    return hits, tried


# ----------------------------------------------------------------------------
# selftest: must go RED on a planted defect, GREEN on a correctly-sized object
# ----------------------------------------------------------------------------

def _build_fake_prom_b():
    """A minimal synthetic prom_b image, big enough to host: (1) a correctly
    sized 4-entry coordinate array immediately followed by a real 3-record
    display list with NO recoverable tail; (2) an oversized twin of the same
    array whose declared size steals the display list's first 2-byte record
    header, exactly the F0D081 shape."""
    img = bytearray(b"\x0e" * 0x32000)
    # 36-entry handler table at HTBL, pointing every slot at 0xF31A9F (a
    # HANDLERS-documented no-operand-text handler) so any op < 0x24 resolves.
    for i in range(36):
        img[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4] = (0xF31A9F).to_bytes(4, "little")

    def put(addr, bs):
        img[addr - B_BASE:addr - B_BASE + len(bs)] = bs

    # -- correctly sized object at 0xF10000: 4 clean 8-byte entries, size
    # matches exactly, list starts immediately after with no leftover.
    OK_ADDR = 0xF10000
    for i in range(4):
        put(OK_ADDR + i * 8, struct.pack("<4H", 0x31, 0x32 + i * 0x12, 0xF1, 0x3F + i * 0x12))
    OK_LIST = OK_ADDR + 32
    put(OK_LIST, bytes([0x05, 0x04, 0xAA, 0xBB]))       # 1 record, op 5, len 4
    put(OK_LIST + 4, bytes([0x06, 0x04, 0xCC, 0xDD]))   # op 6, len 4
    OK_NEXT = OK_LIST + 8
    put(OK_NEXT, bytes([0x10, 0x10] + [0x99] * 14))     # an unrelated "next label"

    # -- oversized (defective) twin at 0xF20000: same 4 entries, but the
    # declared size is 34 (2 bytes too large): the first display-list record
    # (op 0x07 len 2, a zero-operand record) got folded into the array.
    BAD_ADDR = 0xF20000
    for i in range(4):
        put(BAD_ADDR + i * 8, struct.pack("<4H", 0x31, 0x32 + i * 0x12, 0xF1, 0x3F + i * 0x12))
    put(BAD_ADDR + 32, bytes([0x07, 0x02]))             # the swallowed record: op 7 len 2
    put(BAD_ADDR + 34, bytes([0x08, 0x05, 0x01, 0x02, 0x03]))  # op 8 len 5
    put(BAD_ADDR + 39, bytes([0x09, 0x04, 0x04, 0x05]))        # op 9 len 4
    BAD_NEXT = BAD_ADDR + 43
    put(BAD_NEXT, bytes([0x10, 0x10] + [0x99] * 14))    # the already-committed neighbour

    return bytes(img), OK_ADDR, OK_NEXT, BAD_ADDR, BAD_NEXT


def _fake_object_block(label_addr, size, incbin_off, incbin_len, next_addr):
    hx = lambda n: "%06X" % n
    lines = []
    lines.append("; Data_%s -- %d bytes, EMITTED AS DATA (not promoted to code)." % (hx(label_addr), size))
    lines.append("Data_%s:" % hx(label_addr))
    for i in range(size):
        lines.append("\t.byte\t0x00\t; %s" % hx(label_addr + i))
    lines.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X' % (incbin_off, incbin_len))
    lines.append("Data_%s:" % hx(next_addr))
    lines.append("\t.byte\t0x00\t; %s" % hx(next_addr))
    return "\n".join(lines) + "\n"


def build_fake_text(ok_addr, ok_next, bad_addr, bad_next):
    ok_block = _fake_object_block(ok_addr, 32, ok_addr + 32 - B_BASE, 0x08, ok_next)
    bad_block = _fake_object_block(bad_addr, 34, bad_addr + 34 - B_BASE, 0x09, bad_next)
    return ok_block + "\n" + bad_block


def selftest():
    fail = []

    def check(msg, got, want):
        ok = got == want
        print("  %-70s %-10s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
        if not ok:
            fail.append(msg)

    fake_b, ok_addr, ok_next, bad_addr, bad_next = _build_fake_prom_b()
    fake_a = bytes(len(fake_b))
    text = build_fake_text(ok_addr, ok_next, bad_addr, bad_next)
    objs = parse_objects(text)
    check("parsed exactly 2 objects", len(objs), 2)

    # monkeypatch DL.load()-independent path: we call scan logic directly
    findings = []
    for o in objs:
        if o.follow_kind != "incbin":
            continue
        old_end = o.addr + o.size
        base = A_BASE if old_end >= A_BASE else B_BASE
        img = fake_a if base == A_BASE else fake_b
        data = img[o.addr - base:old_end - base]
        cp = clean_prefix(data, o.addr)
        tail = o.size - cp
        rec_start = o.addr + cp
        landing = None
        if o.next_addr is not None:
            landing = try_landing(fake_a, fake_b, rec_start, o.next_addr)
        findings.append((o.label, o.addr, o.size, cp, tail, landing))

    ok_row = next(f for f in findings if f[1] == ok_addr)
    bad_row = next(f for f in findings if f[1] == bad_addr)

    check("correctly-sized object: clean prefix == declared size (no tail)",
          ok_row[2] - ok_row[3], 0)
    check("correctly-sized object: NOT flagged (tail must be 0)", ok_row[4] == 0, True)

    check("oversized object: structural shrink recovers exactly 2 bytes", bad_row[4], 2)
    check("oversized object: zero-drift walk lands on the next committed label",
          bad_row[5] is not None, True)
    if bad_row[5] is not None:
        check("oversized object: recovered walk is exactly 3 records",
              len(bad_row[5]), 3)

    # the detector must ALSO clear a defect-shaped object whose tail does NOT
    # actually frame (i.e. not every 2-byte tail is a hit -- the walk, not the
    # shrink alone, is the gate)
    noise_b = bytearray(fake_b)
    # corrupt the swallowed record's opcode to something >= 0x24 (out of band)
    noise_b[bad_addr + 32 - B_BASE] = 0x30
    noise_recs = try_landing(fake_a, bytes(noise_b), bad_addr + 32, bad_next)
    check("a non-framing tail is correctly NOT landed", noise_recs is None, True)

    print("FAILURES: %d" % len(fail))
    return 1 if fail else 0


def main():
    if "--selftest" in sys.argv:
        print("sizing_defect_hunt.py --selftest")
        return selftest()

    a, b = DL.load()

    if "--null" in sys.argv:
        n = int(sys.argv[sys.argv.index("--null") + 1])
        hits, tried = compute_null_rate(a, b, n)
        rate = hits / tried if tried else float("nan")
        print("null rate: %d/%d local starts land with zero drift on a real "
              "label by chance = %.4f%%" % (hits, tried, rate * 100))
        return 0

    if "--scan" in sys.argv:
        path = sys.argv[sys.argv.index("--scan") + 1]
        findings = scan_file(path, a, b)
        print("scanned %s: %d declared-size object(s) followed by .incbin" % (path, len(findings)))
        for f in findings:
            print("  %-24s addr=0x%06X declared=%d clean_prefix=%d tail=%d"
                  % (f["label"], f["addr"], f["declared_size"], f["clean_prefix"], f["tail"]))
            if f["landing"]:
                target, recs = f["landing"]
                print("      ZERO-DRIFT LANDING at 0x%06X, %d records recovered (%d bytes)"
                      % (target, len(recs), target - f["recovered_start"]))
            elif f["tail"]:
                print("      structural tail found (%d B) but NO zero-drift walk landed -- "
                      "NOT corroborated, do not convert on this alone" % f["tail"])
        return 0

    print("usage: --selftest | --scan FILE | --null N")
    return 1


if __name__ == "__main__":
    sys.exit(main())
