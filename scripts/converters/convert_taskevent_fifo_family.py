#!/usr/bin/env python3
r"""Convert the v1.42 sub-CPU TaskEvent/FIFO/TaskSched `.byte` residue,
byte-exactly, and name the exact decoder gaps behind each site.

QUESTION IT ANSWERS
    notes/DEBT-INVENTORY-2026-09-02.md carried a ~407 B estimate for "the
    backend cannot re-parse spellings its own disassembler emits" in the
    TaskEvent/FIFO/TaskSched family. A same-day decoder fix (LLVM
    tlcs900_backend@ad8129f59880) proved only 14 B of that figure and
    explicitly refused to round up; the other 18 `.byte` runs across lines
    572-1766 (672 B) still failed llvm-mc's own disassembler for a cause
    nobody had traced. This script traces every one of them.

WHAT IT FOUND (measured, not estimated)
    Of the 672 B in those 18 runs:
      * 50 B is genuine DATA, not code -- DSP_ChannelConfigTable (42 B) and
        TaskSched_Init_ConfigData (8 B) are each loaded as an ADDRESS by the
        instruction immediately before them, never jumped to. They disassemble
        into plausible-looking instructions if fed to a byte-stream decoder
        (exactly the "data disassembled as code" illusion the debt inventory
        warns about), which is why they are correctly left as `.byte`.
      * 622 B is real code, and llvm-mc's OWN disassemble+reassemble round
        trip (notes/llvm_roundtrip_probe.py) reported every one of these
        16 labelled routines as a "PARTIAL DECODE" failure. That verdict is
        an ARTIFACT of a measurement bug this script had to fix first (see
        below), not a real decode failure: once corrected, all 622 B decode
        and reassemble byte-for-byte -- 14 B were already known-good
        (Timer_Delay_Ticks); this script converts the remaining 608 B.
      * 0 B remains genuinely blocked in this family.

    So the number to replace ~407 B with is: 0 B blocked, 622 B convertible,
    of which 608 B is new (14 B was already provably clean and just hadn't
    been written back to source).

THE MEASUREMENT BUG THAT HID THIS
    `llvm-mc --disassemble --show-encoding` prints an `encoding: [...]` field
    per instruction. It is NOT reliably the bytes the disassembler consumed
    -- it is the bytes the ENCODER produces when asked to re-emit the decoded
    MCInst. When a byte sequence is genuinely ambiguous (see below), the
    disassembler consumes N bytes internally (correctly advancing the decode
    loop) but the printed `encoding:` field can show a SHORTER re-encoding of
    the same semantic instruction. Any script that tracks "bytes consumed" by
    summing shown encoding lengths (this repo's own llvm_roundtrip_probe.py
    included) silently desyncs at that point and reports a fabricated
    "PARTIAL DECODE" or "MISMATCH" for everything downstream, even though the
    disassembler processed the whole stream correctly. Proof:

        $ echo "0xbb 0x00 0x50 0xff" | llvm-mc --triple=tlcs900 --disassemble
            ld      (xhl), wa
            swi     7
        $ echo "0xbb 0x00 0x50 0xff" | llvm-mc --triple=tlcs900 --disassemble --show-encoding
            ld      (xhl), wa    ; encoding: [0xb3,0x50]      <- 2 bytes shown
            swi     7            ; encoding: [0xff]           <- but 0xff is a
                                                                  SEPARATE instr,
                                                                  so bb 00 50 (3 B)
                                                                  was truly consumed
    This script never trusts a summed encoding length. It only trusts (a) an
    explicit `warning: invalid instruction encoding` (a real, located hard
    failure) or (b) reassembling ONE decoded instruction's own text and
    checking it reproduces the exact byte slice at its true position.

PER-SITE CAUSE MAP -- every family this residue actually needed
    1. EXPLICIT-ZERO-DISPLACEMENT LD, print/encode collapse (the dominant
       cause: ~490 of the 608 B). TLCS-900 has two encodings for
       "LD r,(mem)"/"LD (mem),r": a short 2-byte no-displacement form and a
       longer 3-byte form carrying an explicit 8-bit displacement. When that
       displacement happens to be 0, the InstPrinter drops the "+0" and both
       forms print as "ld wa, (xix)" -- textually indistinguishable -- and
       llvm-mc's ASSEMBLER always re-picks the SHORTER encoding. There is no
       operand spelling ("(xix+0)") that forces the long form; this project's
       already-established fix pattern (see convert_unspellable_forms.py) is
       a forced-mnemonic alias that names the encoding directly:
       LD8_SRC_RID8/LD16_SRC_RID8 ("ld8_src_rid8"/"ld16_src_rid8", source
       direction) and LD_DST16_RID8 ("ld_dst16_rid8", store direction), plus
       LDA_RID8 ("lda_rid8") for the address-load sibling -- all four are
       already-defined TableGen instructions (TLCS900InstrInfo.td ~4664-4694)
       that ENCODE correctly; the disassembler just never emits their names.
       This is an INSTPRINTER gap, not a missing encoding.
    2. RESm/SETm/BITm bit,(mem) -- no decoder case at all. `decodeMemPrefix()`
       (TLCS900Disassembler.cpp) has branches for the ALU-on-memory family
       (ADD/SUB/AND/... at sub-opcodes 0x88/0x98/.../0xC8) but none for the
       MemDstBitOpInst family (RESm=0xB0, SETm=0xB8, BITm=0xC8 --
       TLCS900InstrInfo.td:1559-1578). RESm and SETm sub-opcodes fall through
       to Fail outright; BITm's sub-opcode 0xC8 COLLIDES with the ALU table's
       AND entry and silently misdecodes as "and (xwa), xwa" instead of
       "bitm 0, (xwa)" -- a second, independent instance of the "encodes
       differently, no diagnostic" class already documented for the
       dst-mem-prefix immediate store. Not fixed here (out of scope: this
       script hand-derives the correct mnemonic from the ROM bytes plus the
       ASSEMBLER's independent confirmation, it does not patch the C++
       decoder) -- flagged for whoever next touches decodeMemPrefix().
    3. LDC CR16, r16 ("ldc_cr16") -- no decoder case. Prefix 0xD8-0xDE
       (16-bit register, WA..IY/IZ) + sub-opcode 0x2E + a control-register
       byte has zero branches anywhere in TLCS900Disassembler.cpp; only the
       LDCF (load-carry-flag-bit) family is decoded. The mnemonic itself is
       not new to this ROM -- `ldc_cr16 wa, 0x7C`/`0x48`/`0x40` already
       appear as hand-converted instructions elsewhere in this exact file
       (grep the tree) -- this is purely a missing decoder branch.
    4. cp8_imm_rid8/and8_imm_rid8 (register-indexed 8-bit compare/AND
       immediate with displacement) already had BOTH decoder and encoder
       support and are used 14 and 2 times elsewhere in this file; these two
       sites were blocked only because a previous automated conversion pass
       worked one `.byte` LINE at a time and this 4-byte instruction happened
       to straddle a line break -- a line-grouping artifact, not a decoder
       gap. This script decodes from the CONTIGUOUS ROM byte stream instead,
       so line boundaries cannot hide an instruction.

CORROBORATION BEYOND THE ROUND TRIP
    Every one of the six `jrl` targets converted here was hand-verified
    against `symbols/subcpu_symbols_reference.txt` (addresses that predate
    this session): TaskQueue_Operations_Opaque's and TaskSched_Wake_Task's
    `jrl` both land exactly on TaskSched_Dispatch (0x01FF21); TaskEvent_Signal
    and TaskEvent_Wait both land exactly on TaskSched_ContextRestore
    (0x01FF72); TaskEvent_Wait_Block lands exactly on TaskSched_Dispatch. All
    five targets are pre-existing, independently-named routines whose own
    epilogue/dispatch shape matches what each converted routine's ALREADY-
    WRITTEN prose comment (predating this session) said it should reach --
    the same standard of evidence as the maincpu v9/v10 lane's call-target
    check, adapted here for `jrl` since this file's control flow is entirely
    PC-relative (verify_converted_call_targets.py only resolves absolute
    `call`, and is wired to the maincpu symbol table, not subcpu's).

RUN
    python3 scripts/converters/convert_taskevent_fifo_family.py --selftest
        Re-derives every region straight from the committed ROM image
        (original_ROMs/kn5000_subprogram_v142.rom) independently of the
        current state of the .s file, and asserts 622/622 B decode and
        reassemble byte-exact. This is the reproducible claim behind the
        numbers in this docstring and in the lane report.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJ = Path(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")))
MC = str(PROJ / "llvm-project" / "build" / "bin" / "llvm-mc")
ROM = ROOT / "original_ROMs" / "kn5000_subprogram_v142.rom"
ROM_BASE = 0x0EF00  # see notes/llvm_roundtrip_probe.py's docstring for the proof

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]

ENC_RE = re.compile(rb"encoding: \[([^\]]+)\]")
WARN_RE = re.compile(r"^<stdin>:1:(\d+): warning: invalid instruction encoding$")


def load(addr, size):
    with open(ROM, "rb") as f:
        f.seek(addr - ROM_BASE)
        data = f.read(size)
    assert len(data) == size, f"short read at {addr:#x}"
    return data


def asm_one(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding", "-"],
                        input=(text + "\n").encode(), capture_output=True, timeout=30)
    m = ENC_RE.search(r.stdout)
    return bytes(int(x, 16) for x in m.group(1).decode().split(",")) if m else None


def special(raw, i):
    """Forced-mnemonic families the generic disassembler cannot spell
    (explicit-zero-displacement LD, RESm/SETm/BITm, LDC CR16). See the
    per-site cause map above. Returns (text, length, natural_comment) or
    None."""
    n = len(raw) - i
    b0 = raw[i] if n > 0 else None
    if n >= 3 and 0x88 <= b0 <= 0x8F and 0x20 <= raw[i + 2] <= 0x27:
        base, disp, reg = R32[b0 - 0x88], raw[i + 1], R8[raw[i + 2] - 0x20]
        return (f"ld8_src_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld {reg},({base.upper()}+{disp:#04x})")
    if n >= 3 and 0x98 <= b0 <= 0x9F and 0x20 <= raw[i + 2] <= 0x27:
        base, disp, reg = R32[b0 - 0x98], raw[i + 1], R16[raw[i + 2] - 0x20]
        return (f"ld16_src_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld {reg},({base.upper()}+{disp:#04x})")
    if n >= 3 and 0xB8 <= b0 <= 0xBF and 0x50 <= raw[i + 2] <= 0x57:
        base, disp, reg = R32[b0 - 0xB8], raw[i + 1], R16[raw[i + 2] - 0x50]
        return (f"ld_dst16_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld ({base.upper()}+{disp:#04x}),{reg}")
    if n >= 3 and 0xB8 <= b0 <= 0xBF and 0x20 <= raw[i + 2] <= 0x27:
        base, disp, reg = R32[b0 - 0xB8], raw[i + 1], R32[raw[i + 2] - 0x20]
        return (f"lda_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"lda {reg},({base.upper()}+{disp:#04x})")
    if n >= 2 and 0xB0 <= b0 <= 0xB7:
        sub, base = raw[i + 1], R32[b0 - 0xB0]
        if 0xB0 <= sub <= 0xB7:
            return f"resm\t{sub - 0xB0}, ({base})", 2, None
        if 0xB8 <= sub <= 0xBF:
            return f"setm\t{sub - 0xB8}, ({base})", 2, None
        if 0xC8 <= sub <= 0xCF:
            return f"bitm\t{sub - 0xC8}, ({base})", 2, None
    if n >= 4 and 0x88 <= b0 <= 0x8F:
        who = {0x3C: "and8_imm_rid8", 0x3F: "cp8_imm_rid8"}.get(raw[i + 2])
        if who:
            base, disp, imm = R32[b0 - 0x88], raw[i + 1], raw[i + 3]
            return (f"{who}\t{base}, {disp:#04x}, {imm:#04x}", 4,
                    f"{who.split('8_')[0]} ({base.upper()}+{disp:#04x}),{imm:#04x}")
    if n >= 3 and 0xD8 <= b0 <= 0xDE and raw[i + 1] == 0x2E:
        return f"ldc_cr16\t{R16[b0 - 0xD8]}, {raw[i + 2]:#04x}", 3, None
    return None


def decode_stream(raw):
    """-> [(text, length, encoding, comment), ...], covering every byte of
    `raw`, or raises ValueError naming the exact offset and byte that
    resisted. Never trusts a summed --show-encoding length (see docstring);
    every accepted instruction is verified by reassembling ITS OWN text
    alone and checking the result against the true byte slice at its
    position."""
    out, i, n = [], 0, len(raw)
    while i < n:
        sp = special(raw, i)
        if sp:
            text, length, comment = sp
            enc = asm_one(text)
            if enc == bytes(raw[i:i + length]):
                out.append((text, length, enc, comment))
                i += length
                continue
            raise ValueError(f"special-case {text!r} at offset {i} did not verify: "
                              f"got {enc}, want {raw[i:i + length]!r}")
        hex_str = " ".join(f"0x{b:02x}" for b in raw[i:]) + "\n"
        r = subprocess.run([MC, "--triple=tlcs900", "--disassemble", "--show-encoding", "-"],
                            input=hex_str.encode(), capture_output=True, timeout=30)
        err = r.stderr.decode(errors="replace")
        fails_at_0 = any((int(m.group(1)) - 1) // 5 == 0
                          for l in err.splitlines() if (m := WARN_RE.match(l.strip())))
        out_txt = r.stdout.decode(errors="replace").strip().splitlines()
        if not out_txt or fails_at_0:
            raise ValueError(f"HARD DECODE FAILURE at offset {i}: byte 0x{raw[i]:02x}, "
                              f"context {bytes(raw[i:i + 8]).hex(' ')}")
        first = out_txt[0].strip()
        text = first.split(";", 1)[0].strip()
        enc = asm_one(text)
        if enc is None:
            raise ValueError(f"cannot reassemble decoded text {text!r} at offset {i}")
        if bytes(raw[i:i + len(enc)]) == enc:
            out.append((text, len(enc), enc, None))
            i += len(enc)
            continue
        raise ValueError(f"SILENT MISCOMPILE / unresolved ambiguity at offset {i}: "
                          f"decoded {text!r} claims {enc.hex(' ')} but the stream has "
                          f"{bytes(raw[i:i + 8]).hex(' ')}")
    return out


# (label, ROM address, byte length) -- every routine converted this session,
# plus Timer_Delay_Ticks, which the decoder-fix lane had already proven
# round-trips (ad8129f59880) but had not yet written back to source.
REGIONS = [
    ("TaskSched_SoftTimer_Service",      0x1FF7B, 22),
    ("TaskSched_SoftTimer_Entry",        0x1FF91, 23),
    ("TaskSched_SoftTimer_Unlock",       0x1FFAF, 16),
    ("TaskSched_SoftTimer_Fire",         0x1FFBF, 17),
    ("TaskQueue_Operations_Opaque",      0x2014D, 48),
    ("TaskSched_Wake_Task",              0x20185, 68),
    ("TaskSched_Wake_Task_NoResched",    0x201CF, 61),
    ("TaskEvent_Signal",                 0x20235, 45),
    ("TaskEvent_Signal_Wake",            0x20262, 59),
    ("TaskEvent_Signal_NoResched",       0x2029D, 39),
    ("TaskEvent_Signal_NoResched_Wake",  0x202CA, 62),
    ("TaskEvent_Wait",                   0x20308, 29),
    ("TaskEvent_Wait_Block",             0x20325, 60),
    ("TaskEvent_Clear",                  0x20361, 15),
    ("RingBuf_Access_Opaque_A",          0x2080B, 44),
    ("Timer_Delay_Ticks",                0x2083B, 14),
]

# Regions confirmed to be DATA (loaded as an address, never jumped to), left
# as `.byte` deliberately -- NOT debt. See the comment this script's finding
# added at their site in kn5000_subprogram_v142.s.
DATA_NOT_DEBT = [
    ("DSP_ChannelConfigTable",     0x1FD98, 42),
    ("TaskSched_Init_ConfigData",  0x1FEDF, 8),
]


def selftest():
    total = 0
    bad = 0
    for name, addr, length in REGIONS:
        raw = load(addr, length)
        try:
            insns = decode_stream(raw)
        except ValueError as ex:
            print(f"FAIL  {name} @ {addr:#x}: {ex}")
            bad += 1
            continue
        consumed = sum(l for _, l, _, _ in insns)
        reasm = b"".join(enc for _, _, enc, _ in insns)
        if consumed != length or reasm != raw:
            print(f"FAIL  {name} @ {addr:#x}: reassembled {len(reasm)} B of {length} B, "
                  f"match={reasm == raw}")
            bad += 1
            continue
        total += length
        print(f"OK    {name:<32s} {addr:#08x}  {length:3d} B  {len(insns)} instructions")
    print(f"\n{total} B of {sum(l for _, _, l in REGIONS)} B fully decoded and byte-verified")
    print("selftest: " + ("OK" if bad == 0 else f"{bad} FAILURE(S)"))
    return 1 if bad else 0


def main():
    if "--selftest" in sys.argv[1:]:
        return selftest()
    print(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main())
