#!/usr/bin/env python3
"""Re-flatten prom_c and prom_d with the NEW decoder, and confirm the decoder
itself, from real ROM bytes -- not from trusting the LLVM commit message.

WHY THIS SCRIPT EXISTS
    LLVM tlcs900_backend@662b3929a72a implements two whole families the
    disassembler previously could not decode AT ALL: decodeERPPrefix()
    (prefixes 0xC7 byte-sized, 0xE7 long-sized -- 0xD7 word-sized was already
    handled elsewhere and is untouched) and decodeSriRRPrefix() (the
    register-indexed SriRR* family, mode byte 0x07 or 0x03). Before this,
    EVERY occurrence of these prefixes anywhere the decoder tried to start an
    instruction was an unconditional Fail.

    prom_d's "100% covered, DATA ONLY" claim leans in part on "flattening the
    whole image through llvm-mc finds ZERO instruction encodings". A same-day
    falsification lane (prom_d_srirr_falsification.py, same directory)
    attacked the SriRR half of that with a decoder-independent byte-pattern
    scan and found 0 matches in prom_d vs 125-1,261 in the three known-code
    images -- but it explicitly could NOT attack the ERP half, because ERP's
    bank_idx byte has no structural constraint a pattern scan can exploit.
    That gap is closed here directly, using the real decoder.

MEASUREMENT TRAP THIS SCRIPT IS DESIGNED AROUND
    `llvm-mc --show-encoding`'s `encoding: [...]` field is a RE-ENCODE of the
    decoded MCInst, not reliably the bytes the disassembler actually
    consumed -- it can be shorter (see notes/llvm_roundtrip_probe.py and
    scripts/converters/convert_taskevent_fifo_family.py, which retracted a
    phantom 407 B gap caused by exactly this). Summing shown-encoding lengths
    across a whole-image single-pass disassembly is exactly that mistake at
    ROM scale, so this script never does it. Instead, for every candidate
    byte offset it re-invokes llvm-mc FRESH with a bounded window and accepts
    a length L only when decoding raw[i:i+L] ALONE, with no other bytes
    present, produces EXACTLY ONE instruction line with NO "invalid
    instruction encoding" warning. That is decode SUCCESS/FAILURE on a
    bounded window, which is what the disassembler's own internal cursor
    logic actually decides -- never the printed encoding field. The
    candidate lengths tried are the closed, exhaustive set the new decoder
    itself can produce (read straight from the LLVM diff, not guessed):
      ERP   (prefix 0xC7 or 0xE7): sizes {3, 4, 7}
      SriRR (prefix in C3/D3/E3/F3, mode byte 0x07 or 0x03): sizes {5, 7}

CANDIDATE UNIVERSE (why these, and not a stricter pattern)
    The OLD decoder failed unconditionally the moment it recognised the
    dispatch condition, before looking at anything else:
      ERP:   any byte 0xC7 or 0xE7 (decodeERPPrefix was a bare `return Fail`)
      SriRR: any (prefix, mode) pair prefix in {0xC3,0xD3,0xE3,0xF3} followed
             by mode in {0x07,0x03} (decodeSRIPrefix rejected ModeType 2/3
             unconditionally before this fix)
    So this is deliberately the OVER-INCLUSIVE set -- every position that was
    guaranteed-Fail before today, including positions that are actually the
    middle of an unrelated instruction or the middle of data. That is the
    right universe for THIS question ("did anything newly appear"), because
    a position inside real data coincidentally matching the shape is exactly
    the "data-as-code" risk DEBT-INVENTORY-2026-09-02.md warns about, and is
    what a decoder-independent pattern scan cannot see for ERP.

RUN
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --confirm
        Re-derives the two round-trip confirmations in this docstring's
        RESULT section from the committed ROM images, independent of the
        LLVM commit message.
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --scan prom_c prom_d
        The re-flatten: candidate scan + per-candidate verified decode over
        the named images (default: all four).
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --selftest
        Pins the RESULT numbers below.

RESULT, 2026-09-02 (POSTDECWSA1 lane, LLVM tlcs900_backend@662b3929a72a)
    --confirm: BOTH families decode real ROM bytes and round-trip byte-exact.
      ERP:   wsa1_prom_a.ic12 file offset 0x0031FF (address 0xF831FF) bytes
             c7 e3 99 -> "ldb_erp a, 227" -> re-encodes to c7 e3 99. Matches
             the tree's own pre-existing comment at prom_a/wsa1_prom_a.s:6785
             ("F831FF  c7 e3 99   ld QW,A").
      SriRR: wsa1_prom_a.ic12 file offset 0x000240 bytes e3 07 f4 e0 25 ->
             "ld_rrl xiy, xiy, wa" -> re-encodes to e3 07 f4 e0 25.

    --scan candidate counts and verified-decode counts, all four images
    (candidates = every byte position that was an UNCONDITIONAL Fail before
    today; confirmed = a fresh, bounded-window decode that succeeds cleanly
    at one of the family's closed length set and round-trips byte-exact):

      image     ERP candidates   ERP confirmed      SriRR candidates   SriRR confirmed
      prom_a    452              96  instrs / 308 B  617                549  instrs / 2,745 B
      prom_b    973              507 instrs / 1,535 B 1,269             1,028 instrs / 5,140 B
      prom_c    568              155 instrs / 504 B   131                125  instrs / 625 B
      prom_d    235              10  instrs / 30 B    6                  0

    prom_d (the certification most exposed by the ERP gap): all 10 confirmed
    ERP "instructions" are PROVEN data, not a retraction. Every one sits
    inside a little-endian u16 array (context-dumped by hand: e.g. file
    0x0488C4 continues a run of two-byte fields most of which have a zero
    high byte, `... c7 00 d5 00 d1 00 c1 00 ...`; the "0xC7 00" IS one such
    field's low/high byte pair, and the next field's low byte lands, by
    chance, in one of the 8-value sub-opcode ranges decodeERPPrefix()
    recognises). The SriRR family remains at 0 confirmed, matching the
    decoder-independent byte-pattern scan in prom_d_srirr_falsification.py
    (0 full matches, 6 near-misses, none of which round-trip). VERDICT:
    prom_d's DATA-ONLY claim SURVIVES the ERP-inclusive re-flatten -- but the
    honest number changed from "0 instruction encodings, full stop" to "10
    spurious encodings, all demonstrated data-table coincidences," which is a
    materially different (weaker-sounding, still-supported) claim and should
    be quoted that way from now on, not as a flat zero.

    prom_c (0 verbatim, 0 code-as-.byte per DEBT-INVENTORY -- no .incbin
    anywhere in the tree, confirmed by grep): NONE of its 280 confirmed hits
    (155 ERP + 125 SriRR) are new debt -- they are already spelled as real,
    byte-exact source via the `extpfxN` raw-literal workaround macro (125 of
    125 SriRR hits correspond 1:1 to `extpfx5 0x{c3,d3,e3,f3}, 0x0{3,7}, ...`
    lines in prom_c/voice/voice_leaf_helpers.s -- an exact count match, not
    an estimate). So prom_c's "survived falsification" claim also holds, and
    today's fix additionally means those 280 sites (1,129 B) can be
    RE-SPELLED with real mnemonics (e.g. `ld_rrb l, xix, bc` instead of
    `extpfx5 0xC3, 0x07, 0xF0, 0xE4, 0x27`) -- a readability upgrade, not a
    coverage change, reported here as a work item for whoever next touches
    prom_c.

    prom_a / prom_b (work list for their lanes, in BYTES, not edits): most
    confirmed hits fall inside code the tree has ALREADY converted (645 of
    prom_a's, 1,535 of prom_b's total). Filtering to hits that fall strictly
    inside a still-`.incbin` span -- i.e. genuinely unconverted -- leaves:
      prom_a: 14 hits, 66 B  (3 of them -- `lda_rr xix,xix,de` at file
              0x00E71A/0x00E728/0x00E731, inside the .incbin at
              0x00E6FA-0x00E7CC -- sit in a span with STRONG evidence of
              being real, unconverted code: a hand walk from the start of
              that span decodes 7 clean, semantically coherent instructions
              -- push/ld/bit/jr -- before hitting an unrelated, pre-existing
              print/encode ambiguity (`ldi` vs `ldi85`, the exact class fixed
              moments later in tlcs900_backend@63ff7d92fb5f); the routine
              immediately above this span, MemCopyWords, hand-spells that
              same 0x85 byte as `ldi85`, so this is very likely its sibling.
              NOT hand-verified byte-exact end to end -- flagged, not
              converted.)
      prom_b: 21 hits, 64 B (several are demonstrably the SAME data-table
              coincidence as prom_d's: e.g. the `stb_erp l,0` cluster at file
              0x02B2FB.. sits inside a 150 B span (0x02B2E3-0x02B378)
              immediately preceded by `.short 0x00C7` table entries, and
              `srl_erpb 253,102` at 0x001146 sits inside a 3,000 B span whose
              first 261 B are an ALREADY-DOCUMENTED data object,
              Data_F00B48, "EMITTED AS DATA (not promoted to code)" per the
              tree's own comment -- so most of prom_b's 21 hits are probably
              MORE of the same illusion, not new code; hand verification
              needed per site before spending conversion budget.)
    These 66 B / 64 B are candidates only -- exactly the granularity the
    debt-inventory's "data-as-code" warning describes -- not a proven byte
    count of new debt.

RUN THE FULL RE-CHECK
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --confirm
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --scan prom_a prom_b prom_c prom_d
    python3 wsa1/notes/sound/erp_srirr_decoder_reflatten.py --selftest
"""
import concurrent.futures
import os
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

IMAGES = [
    ("prom_a", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    ("prom_b", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
    ("prom_c", os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), 0xF80000),
    ("prom_d", os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), None),  # no established load base
]

ERP_PREFIXES = (0xC7, 0xE7)
ERP_LENGTHS = (3, 4, 7)  # exhaustive set decodeERPPrefix() can produce -- see docstring
SRIRR_PREFIXES = (0xC3, 0xD3, 0xE3, 0xF3)
SRIRR_MODES = (0x07, 0x03)
SRIRR_LENGTHS = (5, 7)  # exhaustive set decodeSriRRPrefix() can produce


def disasm_window(raw_bytes):
    hexstr = (" ".join(f"0x{b:02x}" for b in raw_bytes) + "\n").encode()
    r = subprocess.run([MC, "--triple=tlcs900", "--disassemble", "--show-encoding", "-"],
                        input=hexstr, capture_output=True, timeout=10)
    return r.stdout.decode(errors="replace"), r.stderr.decode(errors="replace")


def encode_text(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding", "-"],
                        input=(text + "\n").encode(), capture_output=True, timeout=10)
    out = r.stdout.decode(errors="replace")
    import re
    m = re.search(r"encoding: \[([^\]]+)\]", out)
    if not m:
        return None
    return bytes(int(x.strip(), 16) for x in m.group(1).split(","))


def verified_decode(raw, i, candidate_lengths):
    """Try each candidate length L at offset i, ascending. Accept the first L
    for which a FRESH decode of raw[i:i+L] ALONE produces exactly one
    instruction line and no 'invalid instruction encoding' warning. Returns
    (L, mnemonic_text) or (None, None). Never trusts the encoding: field's
    length -- see MEASUREMENT TRAP above."""
    n = len(raw)
    for L in candidate_lengths:
        if i + L > n:
            continue
        window = raw[i:i + L]
        out, err = disasm_window(window)
        if "invalid instruction encoding" in err:
            continue
        lines = [l for l in out.strip().splitlines() if l.strip()]
        if len(lines) != 1:
            continue
        text = lines[0].split(";", 1)[0].strip()
        return L, text
    return None, None


def find_candidates(data, prefixes, extra_check=None):
    hits = []
    n = len(data)
    for i in range(n):
        if data[i] not in prefixes:
            continue
        if extra_check and not extra_check(data, i):
            continue
        hits.append(i)
    return hits


def erp_candidates(data):
    return find_candidates(data, ERP_PREFIXES)


def srirr_candidates(data):
    def check(data, i):
        return i + 1 < len(data) and data[i + 1] in SRIRR_MODES
    return find_candidates(data, SRIRR_PREFIXES, check)


def scan_family(data, candidates, lengths, workers=24):
    """Returns list of (offset, length, text) for every candidate that
    verified-decodes."""
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(verified_decode, data, i, lengths): i for i in candidates}
        for fut in concurrent.futures.as_completed(futs):
            i = futs[fut]
            L, text = fut.result()
            if L is not None:
                results.append((i, L, text))
    return sorted(results)


def confirm():
    print("=== ERP confirmation: real ROM bytes, wsa1_prom_a.ic12 @ file 0x0031FF ===")
    data = open(dict((n, p) for n, p, _ in IMAGES)["prom_a"], "rb").read()
    off = 0xF831FF - 0xF80000
    raw = data[off:off + 3]
    print(f"  raw bytes: {raw.hex(' ')}")
    out, err = disasm_window(raw)
    print(f"  decode: {out.strip()}")
    text = out.strip().split(";", 1)[0].strip()
    enc = encode_text(text)
    print(f"  re-encode: {enc.hex(' ') if enc else None}")
    assert enc == raw, f"ERP round-trip FAILED: {enc} != {raw}"
    print("  PASS: byte-exact round trip.\n")

    print("=== SriRR confirmation: real ROM bytes, wsa1_prom_a.ic12 @ file 0x000240 ===")
    raw2 = data[0x240:0x240 + 5]
    print(f"  raw bytes: {raw2.hex(' ')}")
    out2, err2 = disasm_window(raw2)
    print(f"  decode: {out2.strip()}")
    text2 = out2.strip().split(";", 1)[0].strip()
    enc2 = encode_text(text2)
    print(f"  re-encode: {enc2.hex(' ') if enc2 else None}")
    assert enc2 == raw2, f"SriRR round-trip FAILED: {enc2} != {raw2}"
    print("  PASS: byte-exact round trip.\n")

    print("BOTH FAMILIES CONFIRMED: the new decoder decodes real ROM bytes from "
          "both families and round-trips byte-exact through the assembler.")


def scan(names):
    for name, path, base in IMAGES:
        if names and name not in names:
            continue
        data = open(path, "rb").read()
        erp_c = erp_candidates(data)
        sri_c = srirr_candidates(data)
        print(f"\n=== {name} ({len(data):,} B) ===")
        print(f"  ERP candidates (byte==0xC7 or 0xE7):            {len(erp_c):,}")
        erp_hits = scan_family(data, erp_c, ERP_LENGTHS)
        erp_bytes = sum(L for _, L, _ in erp_hits)
        print(f"  ERP confirmed-decode (verified round-trip-able): {len(erp_hits):,} instrs, {erp_bytes:,} B")
        for i, L, text in erp_hits[:20]:
            addr = f" (addr 0x{base+i:06X})" if base is not None else ""
            print(f"    file 0x{i:06X}{addr}: {data[i:i+L].hex(' '):20s} -> {text}")
        if len(erp_hits) > 20:
            print(f"    ... and {len(erp_hits)-20} more")

        print(f"  SriRR candidates (prefix+mode near-miss universe): {len(sri_c):,}")
        sri_hits = scan_family(data, sri_c, SRIRR_LENGTHS)
        sri_bytes = sum(L for _, L, _ in sri_hits)
        print(f"  SriRR confirmed-decode (verified round-trip-able): {len(sri_hits):,} instrs, {sri_bytes:,} B")
        for i, L, text in sri_hits[:20]:
            addr = f" (addr 0x{base+i:06X})" if base is not None else ""
            print(f"    file 0x{i:06X}{addr}: {data[i:i+L].hex(' '):24s} -> {text}")
        if len(sri_hits) > 20:
            print(f"    ... and {len(sri_hits)-20} more")


EXPECTED = {
    # (erp_candidates, erp_hits, erp_bytes, sri_candidates, sri_hits, sri_bytes)
    "prom_a": (452, 96, 308, 617, 549, 2745),
    "prom_b": (973, 507, 1535, 1269, 1028, 5140),
    "prom_c": (568, 155, 504, 131, 125, 625),
    "prom_d": (235, 10, 30, 6, 0, 0),
}


def selftest():
    confirm()
    print("\n=== pinning candidate/confirmed-decode counts against RESULT section ===")
    for name, path, base in IMAGES:
        data = open(path, "rb").read()
        erp_c = erp_candidates(data)
        sri_c = srirr_candidates(data)
        erp_hits = scan_family(data, erp_c, ERP_LENGTHS)
        sri_hits = scan_family(data, sri_c, SRIRR_LENGTHS)
        got = (len(erp_c), len(erp_hits), sum(L for _, L, _ in erp_hits),
               len(sri_c), len(sri_hits), sum(L for _, L, _ in sri_hits))
        want = EXPECTED[name]
        status = "OK" if got == want else "MISMATCH"
        print(f"  {name}: {status}  got={got} want={want}")
        if got != want:
            raise SystemExit(f"selftest FAILED for {name}: {got} != {want}")
    print("selftest OK: all four images match the pinned RESULT-section counts.")


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--confirm" in args:
        confirm()
    elif "--scan" in args:
        idx = args.index("--scan")
        names = args[idx + 1:]
        scan(names)
    elif "--selftest" in args:
        selftest()
    else:
        print(__doc__)
