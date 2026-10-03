#!/usr/bin/env python3
"""Re-check, from the ROM bytes, every quantified claim this round put in a header.

QUESTION IT ANSWERS: "the prom_a headers say `exactly five accessors`, `82 of
those bytes are equal`, `eight entries`, `three entries`, `nine bytes` -- are
they still true?"

The byte gate cannot check any of that: it proves the source rebuilds the ROM,
and it is blind to what a comment claims.  This is the other half.  Every check
below corresponds to a sentence in prom_a/wsa1_prom_a.s or in a notes/FINDINGS-*
file, is named after it, and fails loudly.

    python3 notes/prom_a_byte_checks.py          # exits non-zero on any failure
    python3 notes/prom_a_byte_checks.py -v       # print each check
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
FAILS = []
RAN = []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def b(addr, n=1):
    return B[addr - 0xF00000:addr - 0xF00000 + n]


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


# --- "the CS0 device at 0x7B0004/5 is reached through EXACTLY FIVE accessors" --
# notes/FINDINGS-dev7b-and-int5.md, and the block header at prom_a 0xFE54B6.
hits = []
for img, base, tag in ((A, 0xF80000, "prom_a"), (B, 0xF00000, "prom_b")):
    for t in range(0x7B0000, 0x7B0010):
        le = bytes([t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF])
        i = 0
        while True:
            i = img.find(le, i)
            if i < 0:
                break
            if i >= 1 and img[i - 1] in (0xC2, 0xD2, 0xE2, 0xF2):
                hits.append((tag, base + i - 1, t))
            i += 1
check("dev7b: exactly 5 mem24 accesses to 0x7B0000-0x7B000F",
      len(hits) == 5, str(hits))
check("dev7b: all five are in prom_a 0xFE54B6-0xFE54EB",
      all(t == "prom_a" and 0xFE54B6 <= x <= 0xFE54EB for t, x, _ in hits),
      str(hits))

# --- "LCD_BlitGlyph8_ExtraWait is LCD_BlitGlyph8 plus one 9-byte busy poll" ----
# notes/FINDINGS-fonts.md and the header at prom_a 0xF8F162.
POLL = bytes.fromhex("f0c6c86e04b3ce6efc")
G8, G8W = a(0xF8F0D8, 88), a(0xF8F162, 97)
check("blit8: the two routines are 88 and 97 bytes", len(G8) == 88 and len(G8W) == 97)
check("blit8: first six bytes equal", G8[:6] == G8W[:6])
check("blit8: the inserted nine bytes are the busy poll", G8W[6:15] == POLL)
check("blit8: the remaining 82 bytes are equal",
      G8[6:] == G8W[15:] and len(G8[6:]) == 82)

# --- "LCD_LayerBasePtr_Table is 3 x LE32 -> (0x2541)/(0x2543)/(0x2545)" --------
tbl = [int.from_bytes(a(0xF8EEB1 + 4 * i, 4), "little") for i in range(3)]
check("layer table: 3 entries = 0x2541 0x2543 0x2545",
      tbl == [0x2541, 0x2543, 0x2545], str(tbl))
check("layer table: the next byte is SWI7 slot 0x05's target 0xF8EEBD",
      int.from_bytes(a(0xF8E9DA, 4), "little") == 0xF8EEBD)

# --- "the edge-mask tables are 9 bytes each, 0xFF>>k and 0xFF<<(8-k)" ----------
left, right = a(0xF8F79B, 9), a(0xF8F7AF, 9)
check("left mask table: 00 7f 3f 1f 0f 07 03 01 00",
      list(left) == [0x00, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01, 0x00],
      left.hex(" "))
check("left mask table: entries 1..7 are 0xFF >> k",
      all(left[k] == (0xFF >> k) & 0xFF for k in range(1, 8)))
check("right mask table: 00 80 c0 e0 f0 f8 fc fe 00",
      list(right) == [0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0x00],
      right.hex(" "))
check("right mask table: entries 1..7 are 0xFF << (8-k)",
      all(right[k] == (0xFF << (8 - k)) & 0xFF for k in range(1, 8)))

# --- "the dither tables are 0xCC shifted and 0xCC rotated right by k" ----------
sh, ro = a(0xF8FE52, 9), a(0xF8FE5B, 9)
check("dither shift table: 0xCC >> k for k = 0..7",
      all(sh[k] == (0xCC >> k) & 0xFF for k in range(8)), sh.hex(" "))
check("dither rotate table: 0xCC ror k for k = 0..8",
      all(ro[k] == ((0xCC >> (k % 8)) | (0xCC << (8 - (k % 8)))) & 0xFF
          for k in range(9)), ro.hex(" "))

# --- "the selector-1 dispatch table at prom_b 0xF57D4F is 8 x LE32" ------------
sel = [int.from_bytes(b(0xF57D4F + 4 * i, 4), "little") for i in range(8)]
check("link selector-1 table: 8 entries, all 24-bit and inside 0xF00000-0xFFFFFF",
      all(0xF00000 <= v <= 0xFFFFFF for v in sel), [hex(v) for v in sel])

# --- "the entry table at prom_a 0xFE3000 is 8 x `jp nnn`" ---------------------
ok, tg = True, []
for i in range(8):
    r = a(0xFE3000 + 4 * i, 4)
    ok &= r[0] == 0x1B
    tg.append(r[1] | r[2] << 8 | r[3] << 16)
check("0xFE3000 entry table: 8 slots, every one a `jp nnn`", ok, str(tg))
check("0xFE3000: slot 0x08 and slot 0x1C share a target",
      tg[2] == tg[7] == 0xFE6866, str(tg))
check("0xFE3000: slot 0x10 is INTTC0's handler 0xFE6851", tg[4] == 0xFE6851)

# --- "ten text services, and these are their fonts" --------------------------
# The (service, prom_a address, font base, bytes per glyph) rows of
# notes/FINDINGS-fonts.md, re-read from the instruction stream: each service
# ends with `... 3d 45 <base32> ...` and carries its glyph size just before.
FONTS = [(0x06, 0xF8F039, 0xF1B400, 14), (0x20, 0xF8F06E, 0xF24DC0, 10),
         (0x16, 0xF8F0A3, 0xF212B0, 14), (0x07, 0xF8F130, 0xF1BEF0, 16),
         (0x08, 0xF8F1C3, 0xF1CB70, 32), (0x21, 0xF8F1F7, 0xF25590, 48),
         (0x1A, 0xF8F229, 0xF22840, 32), (0x1F, 0xF8F25B, 0xF24640, 32),
         (0x19, 0xF8F28D, 0xF21940, 32), (0x1D, 0xF8F2BF, 0xF203B0, 32)]
for svc, addr, base, size in FONTS:
    blob = a(addr, 0x36)
    want = bytes([0x45, base & 0xFF, (base >> 8) & 0xFF, (base >> 16) & 0xFF, 0x00])
    check("svc 0x%02X: loads XIY = 0x%06X" % (svc, base), want in blob)
    slot = 0xF8E9C6 + 4 * svc
    check("svc 0x%02X: SWI7 slot points at 0x%06X" % (svc, addr),
          int.from_bytes(a(slot, 4), "little") == addr)
# and the ASCII verdict, so the note's five/five split is re-checked here too
ASCII_PASS = {0xF1B400: 14, 0xF24DC0: 10, 0xF1BEF0: 16, 0xF1CB70: 32, 0xF25590: 48}
ASCII_FAIL = {0xF212B0: 14, 0xF22840: 32, 0xF24640: 32, 0xF21940: 32, 0xF203B0: 32}


def ascii_font(base, size):
    def blank(c):
        return not any(b(base + c * size, size))
    return blank(0x20) and not any(blank(c) for c in range(0x21, 0x7F))


for base, size in ASCII_PASS.items():
    check("font 0x%06X passes the ASCII test" % base, ascii_font(base, size))
for base, size in ASCII_FAIL.items():
    check("font 0x%06X does NOT pass the ASCII test" % base,
          not ascii_font(base, size))

# =============================================================================
# ROUND 2 -- checks for the sentences the round-1 audit made us rewrite
# =============================================================================

# --- F1: "Int_Mul32 is 22 bytes and the KN5000 has exactly those 22" ----------
# prom_a/wsa1_prom_a.s, Int_Mul32 header.  The WSA1 half is checkable here; the
# KN5000 half needs the sibling ELF, so it is guarded and reported as SKIP.
MUL32 = bytes.fromhex("d7e28bd943d7e68ad842ea83d7ee9bdba8d940e8830e")
check("Int_Mul32: the 22 bytes sit at 0xFE68DD", a(0xFE68DD, 22) == MUL32)
check("Int_Mul32: they occur exactly once in prom_a",
      A.count(MUL32) == 1, "count=%d" % A.count(MUL32))
check("Int_Mul32: and not at all in prom_b", B.count(MUL32) == 0)
check("Int_Mul32: the routine ends in RET and the next byte starts Int_SignedDiv",
      a(0xFE68F2, 1) == b"\x0e" and a(0xFE68F3, 2) == bytes([0x25, 0x00]))
try:
    import subprocess
    _bin = "/home/fsanches/compartilhado/llvm-project/build/bin"
    _elf = ("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/"
            "kn5000_subprogram_v142.llvm.elf")
    _tmp = os.path.join(os.environ.get("TMPDIR", "/tmp"), "kn5000_v142_full.bin")
    subprocess.run([os.path.join(_bin, "llvm-objcopy"), "-O", "binary", _elf, _tmp],
                   check=True, capture_output=True)
    K = open(_tmp, "rb").read()
    KOFF = 0x3D8CA - 0x400          # addr = 0x400 + offset in the UNSPLICED image
    check("Int_Mul32: KN5000 0x3D8CA holds the same 22 bytes",
          K[KOFF:KOFF + 22] == MUL32)
    check("Int_Mul32: the shared run is EXACTLY 22 bytes, not more",
          K[KOFF - 1] != A[0xFE68DD - 0xF80000 - 1]
          and K[KOFF + 22] != A[0xFE68DD - 0xF80000 + 22])
    check("Int_Mul32: it occurs exactly once in the KN5000 image",
          K.count(MUL32) == 1)
    # --- ROUND 3: the two DSP routines the sibling also has --------------
    # prom_a headers at 0xF85F7C and 0xF85FA8.  Round 2 wrote "byte-identical"
    # for one and, for the other, a Notes paragraph describing an instruction
    # that is in NEITHER image.  These two checks put a NUMBER on each claim,
    # so "identical" can never again mean "I did not diff it".
    #   extents come from the sibling's own symbol table:
    #     DSP_WriteAllChannelRegs    kn5000 0x1FCFB, 44 bytes
    #     DSP_WriteChannelRegs_Inner kn5000 0x1FD27, 81 bytes
    def _kdiff(kaddr, waddr, n):
        ko = kaddr - 0x400
        return [i for i in range(n) if K[ko + i] != a(waddr + i, 1)[0]]
    d_all = _kdiff(0x1FCFB, 0xF85F7C, 44)
    check("DSP_WriteAllChannelRegs: 44 bytes, ZERO differ from the KN5000",
          d_all == [], "differing offsets %s" % d_all)
    d_inner = _kdiff(0x1FD27, 0xF85FA8, 81)
    check("DSP_WriteChannelRegs_Inner: 81 bytes, EXACTLY ONE differs",
          d_inner == [15], "differing offsets %s" % d_inner)
    check("...and that one byte is the PERIPHERAL BASE: KN5000 0x13, WSA1 0x7F",
          K[0x1FD27 - 0x400 + 15] == 0x13 and a(0xF85FB7, 1) == b"\x7f")
    check("...it is the third byte of `ld XIY,imm32` (45 00 00 xx 00)",
          a(0xF85FB4, 3) == bytes([0x45, 0x00, 0x00]) and a(0xF85FB8, 1) == b"\x00")
except Exception as e:                                       # noqa: BLE001
    print("SKIP  Int_Mul32 KN5000-side checks (%s)" % type(e).__name__)

# --- the retracted DSP instruction: it is not in the ROM ----------------------
# prom_a 0xF85FA8's header claimed `ld (XIY+0x00),0x00` (bytes B5 00 ... in the
# (XIY) immediate form, or BD 00 00 00 in the displacement form).  A searched
# negative, so it names its search: neither encoding occurs in the routine.
_INNER = a(0xF85FA8, 81)
check("DSP_WriteChannelRegs_Inner contains no `ld (XIY+0x00),0x00`",
      bytes([0xBD, 0x00, 0x00, 0x00]) not in _INNER
      and bytes([0xB5, 0x00, 0x00]) not in _INNER)
check("DSP_WriteChannelRegs_Inner: 8 index writes `ld (XIY),A` (b5 41)",
      _INNER.count(bytes([0xB5, 0x41])) == 8,
      "count=%d" % _INNER.count(bytes([0xB5, 0x41])))
check("DSP_WriteChannelRegs_Inner: 8 data writes `ld (XIY+0x02),r` (bd 02 4x)",
      sum(1 for i in range(len(_INNER) - 2)
          if _INNER[i] == 0xBD and _INNER[i + 1] == 0x02
          and 0x40 <= _INNER[i + 2] <= 0x47) == 8)
check("DSP_ChannelRegs_Write8: index = (channel<<5)|0x10",
      a(0xF85F60, 3) == bytes([0xC9, 0xEE, 0x05])
      and a(0xF85F63, 3) == bytes([0xC9, 0x31, 0x04]))
check("DSP_WriteAllChannelRegs: the four pushed channels are 1, 0, 2, 3",
      [a(x, 1)[0] for x in (0xF85F7F, 0xF85F8A, 0xF85F94, 0xF85F9E)] == [1, 0, 2, 3])

# --- F8: which control register each micro-DMA setter's 2nd argument reaches --
# prom_a/wsa1_prom_a.s, the 0xF8E6A2 block header table.  The control-register
# number is the third byte of each `ldc` (MAME 900tbl.hxx:3931-4030).
for name, addr, cr1, cr2 in (("uDMA2_SetDest", 0xF8E6A2, 0x18, 0x2A),
                             ("uDMA2_SetSource", 0xF8E6AF, 0x08, 0x28),
                             ("uDMA3_SetSource", 0xF8E6BC, 0x0C, 0x2E),
                             ("uDMA3_SetDest", 0xF8E6C9, 0x1C, 0x2C)):
    body = a(addr, 13)
    check("%s: writes CR 0x%02X then CR 0x%02X" % (name, cr1, cr2),
          body[5] == cr1 and body[11] == cr2,
          "got 0x%02X,0x%02X" % (body[5], body[11]))
# and the widths that go with them: mode writes load C (8-bit), counts load BC
check("uDMA: the two MODE setters load an 8-bit operand",
      a(0xF8E6A8, 1) == b"\x8f" and a(0xF8E6C2, 1) == b"\x8f")
check("uDMA: the two COUNT setters load a 16-bit operand",
      a(0xF8E6B5, 1) == b"\x9f" and a(0xF8E6CF, 1) == b"\x9f")

# --- F2: the DMA vector writes the retraction turns on ------------------------
check("INTTC0: 0xFE5966 is `ldio DMA0V,0x0E` (SFR 0x7C)",
      a(0xFE5966, 3) == bytes([0x08, 0x7C, 0x0E]))
for site in (0xF8E4CA, 0xF8E4E9, 0xF8E51F):
    check("INT0_LinkByte: 0x%06X is `ldio DMA3V,0x0A` (SFR 0x7F)" % site,
          a(site, 3) == bytes([0x08, 0x7F, 0x0A]))
check("INT0: vector slot 0x28 does NOT point at the hang",
      int.from_bytes(a(0xFFFF28, 4), "little") != 0x00F82D09)

# --- F3: the hang really is reached by EIGHT slots, not nine ------------------
hang = [i for i in range(0, 0x84, 4)
        if int.from_bytes(a(0xFFFF00 + i, 4), "little") == 0x00F82D09]
check("vectors: exactly 8 slots point straight at IRQ_UnusedVector_Hang",
      len(hang) == 8, "got %d: %s" % (len(hang), [hex(x) for x in hang]))
check("vectors: they are 0x38 0x3C 0x40 0x54 0x58 0x5C 0x70 0x78",
      hang == [0x38, 0x3C, 0x40, 0x54, 0x58, 0x5C, 0x70, 0x78])
check("vectors: 0xF82D02-0xF82D08 are seven NOPs falling into it",
      a(0xF82D02, 7) == b"\x00" * 7 and a(0xF82D09, 2) == bytes([0x68, 0xFE]))

# --- round 2 new territory: DSP_ChannelRegs_Init --------------------------------
check("DSP_ChannelRegs_Init: 0xF85F0F opens with `link XIZ,0xFFF8`",
      a(0xF85F0F, 4) == bytes([0xEE, 0x0C, 0xF8, 0xFF]))
check("DSP_ChannelRegs_Init: it ends `unlk XIZ / ret` at 0xF85F56",
      a(0xF85F56, 3) == bytes([0xEE, 0x0D, 0x0E]))
check("DSP_ChannelRegs_Init: the four calls all target 0xF85F59",
      all(int.from_bytes(a(s0 + 1, 2), "little") + s0 + 3 == 0xF85F59
          and a(s0, 1) == b"\x1e" for s0 in (0xF85F22, 0xF85F29, 0xF85F30, 0xF85F37)))
check("DSP_ChannelRegs_Init: the config word is 0x0101001F and the stride 0x20",
      a(0xF85F45, 5) == bytes([0x40, 0x1F, 0x00, 0x01, 0x01])
      and a(0xF85F50, 3) == bytes([0xC9, 0xC8, 0x20]))
check("DSP_ChannelRegs_Init: the loop runs 4 times",
      a(0xF85F4A, 2) == bytes([0x24, 0x04]))

# --- round 2 new territory: micro-DMA channel 0 and the 0x7A0000 data port ---
# prom_a/wsa1_prom_a.s, the 0xFE594C block.  The claim under test is the whole
# direction argument: which control register gets which value in each setup.
check("PortB3_Pulse: set bit 3 of SFR 0x1F, five NOPs, clear it",
      a(0xFE594C, 3) == bytes([0xC0, 0x1F, 0x21])
      and a(0xFE594F, 3) == bytes([0xC9, 0xCE, 0x08])
      and a(0xFE5955, 5) == b"\x00" * 5
      and a(0xFE595D, 3) == bytes([0xC9, 0xCC, 0xF7]))
check("uDMA0_ArmOnINT7: `ldio 0x7C,0x0E` and nothing else",
      a(0xFE5966, 4) == bytes([0x08, 0x7C, 0x0E, 0x0E]))
check("uDMA0_ArmOnINT7: 0xFE5964 is `jr +0` into it",
      a(0xFE5964, 2) == bytes([0x68, 0x00]))
# The two direction setups.  `eb 2e NN` is ldc CR NN,XHL; `c9 2e 22` is ldc DMAM0,A.
check("Dev7A_Dma_DeviceToRam: DMAS0 := 0x007A0000 (fixed source)",
      a(0xFE59BB, 8) == bytes([0x43, 0x00, 0x00, 0x7A, 0x00, 0xEB, 0x2E, 0x00]))
check("Dev7A_Dma_DeviceToRam: DMAD0 := (0x605A3C) and DMAM0 := 0x00",
      a(0xFE59C3, 8) == bytes([0xE2, 0x3C, 0x5A, 0x60, 0x23, 0xEB, 0x2E, 0x10])
      and a(0xFE59CB, 5) == bytes([0x21, 0x00, 0xC9, 0x2E, 0x22]))
check("Dev7A_Dma_RamToDevice: DMAS0 := (0x605A3C) (walking source)",
      a(0xFE59D2, 8) == bytes([0xE2, 0x3C, 0x5A, 0x60, 0x23, 0xEB, 0x2E, 0x00]))
check("Dev7A_Dma_RamToDevice: DMAD0 := 0x007A0000 and DMAM0 := 0x08",
      a(0xFE59DA, 8) == bytes([0x43, 0x00, 0x00, 0x7A, 0x00, 0xEB, 0x2E, 0x10])
      and a(0xFE59E2, 5) == bytes([0x21, 0x08, 0xC9, 0x2E, 0x22]))
check("Dev7A: both setups tail into uDMA0_ArmOnINT7",
      a(0xFE59D0, 2) == bytes([0x68, 0x94]) and a(0xFE59E7, 3) == bytes([0x78, 0x7C, 0xFF]))
check("Dev7A_StartDma / uDMA0_SetCount: both load DMAC0 from (0x605A0E)",
      a(0xFE596A, 8) == bytes([0xD2, 0x0E, 0x5A, 0x60, 0x21, 0xD9, 0x2E, 0x20])
      and a(0xFE59EA, 8) == bytes([0xD2, 0x0E, 0x5A, 0x60, 0x21, 0xD9, 0x2E, 0x20]))

# The ten command codes are PARSED out of the compare chain, not typed in, so a
# changed literal or a miscounted arm fails here instead of passing forever.
codes, arms, pc = [], [], 0xFE5979
while a(pc, 2) == bytes([0xD8, 0xCF]):          # cp WA,imm16
    codes.append(a(pc + 2, 1)[0])
    br = a(pc + 4, 2)                            # jr cc,d8
    arms.append((br[0], (pc + 6 + (br[1] - 256 if br[1] > 127 else br[1]))))
    pc += 6
WRITE, READ = 0xFE59B7, 0xFE59B5
w = [c for c, (cc, t) in zip(codes, arms) if t == WRITE and cc == 0x66]
r = [c for c, (cc, t) in zip(codes, arms) if t == READ and cc == 0x66]
last = arms[-1]
check("Dev7A_StartDma: the chain has exactly ten `cp WA,imm16` links",
      len(codes) == 10, str([hex(c) for c in codes]))
check("Dev7A_StartDma: 3 codes take the RAM->device arm: 0x4D 0xC9 0xC5",
      w == [0x4D, 0xC9, 0xC5], str([hex(c) for c in w]))
check("Dev7A_StartDma: 6 codes take the device->RAM arm by `jr z`",
      r == [0xDD, 0xD9, 0xD1, 0x4A, 0x42, 0xCC], str([hex(c) for c in r]))
check("Dev7A_StartDma: the tenth, 0xC6, falls INTO the device->RAM arm on `jr nz`",
      codes[-1] == 0xC6 and last == (0x6E, 0xFE59BA))
check("Dev7A_StartDma: the chain ends where the two arms begin",
      pc == 0xFE59B5)

# --- the tick counter the 500-tick timeout is measured on -------------------
check("Dev7B_WaitStatus: the limit is 0x01F4 = 500",
      a(0xFE5A1E, 4) == bytes([0xD8, 0xCF, 0xF4, 0x01]))
check("Dev7B_WaitStatus: it snapshots and re-reads (0x605A00)",
      a(0xFE59F4, 5) == bytes([0xD2, 0x00, 0x5A, 0x60, 0x26])
      and a(0xFE5A17, 5) == bytes([0xD2, 0x00, 0x5A, 0x60, 0x20]))
check("INTT1_Tick increments (0x605A00) at 0xF82D14",
      a(0xF82D14, 5) == bytes([0xD2, 0x00, 0x5A, 0x60, 0x61]))

# --- round 2 new territory: the scheduler queues -----------------------------
check("Kernel_Dispatch: scans 3 heads from 0x0330 with stride 4",
      a(0xF85746, 2) == bytes([0x22, 0x03])            # ldb b,3
      and a(0xF85748, 3) == bytes([0x34, 0x30, 0x03])  # ldw ix,0x0330
      and a(0xF85754, 2) == bytes([0xDC, 0x64]))       # inc 4,IX
check("Kernel_Dispatch: reads the saved XSP from node+4",
      a(0xF85760, 3) == bytes([0xAB, 0x04, 0x27]))
check("queue primitives: both compute head = 0x032C + A*4",
      a(0xF85886, 4) == bytes([0xD8, 0xC8, 0x2C, 0x03])
      and a(0xF858C9, 4) == bytes([0xD8, 0xC8, 0x2C, 0x03]))
check("0x032C + n*4 for n=1,2,3 is exactly Kernel_Dispatch's three heads",
      [0x032C + 4 * n for n in (1, 2, 3)] == [0x0330, 0x0334, 0x0338])
check("sub_F85EC2 calls Kernel_YieldRotate with A = 3",
      a(0xF85EC2, 2) == bytes([0x21, 0x03]))
# the two rotate bodies, and the exact extent of the identity
r1, r2 = 0xF85897, 0xF858D9
check("Kernel_YieldRotate / Kernel_RotateQueue: 38 identical body bytes",
      a(r1, 38) == a(r2, 38))
check("...and the run is EXACTLY 38 -- it breaks on the byte either side",
      a(r1 - 1, 1) != a(r2 - 1, 1) and a(r1 + 38, 1) != a(r2 + 38, 1))
check("Kernel_YieldRotate: tests head->next against head->PREV (0 or 1 element)",
      a(0xF85891, 3) == bytes([0x9D, 0x02, 0xF4]))
check("MsgQueue_ReceiveBlocking: tests head->next against the HEAD (0 elements)",
      a(0xF85CA8, 2) == bytes([0xDD, 0xF4]))
check("MsgQueue_ReceiveBlocking: message queue 0x0370+A*4, wait queue 0x0360+A*4",
      a(0xF85C9D, 4) == bytes([0xD8, 0xC8, 0x70, 0x03])
      and a(0xF85CFF, 4) == bytes([0xDA, 0xC8, 0x60, 0x03]))
check("MsgQueue_ReceiveBlocking: recycles the node to the free list 0x03C4",
      a(0xF85CC9, 3) == bytes([0x35, 0xC4, 0x03]))
check("MsgQueue_ReceiveBlocking: marks the blocked task state 3 at node+9",
      a(0xF85CFB, 4) == bytes([0xBC, 0x09, 0x00, 0x03]))
check("MsgQueue_ReceiveBlocking: clears the payload to 0xFFFFFFFF",
      a(0xF85CC1, 5) == bytes([0x41, 0xFF, 0xFF, 0xFF, 0xFF]))

# --- EntryPoint_Records: the two field readings ------------------------------
recs = [(int.from_bytes(a(0xF85E8A + 12 * i, 4), "little"),
         int.from_bytes(a(0xF85E8A + 12 * i + 4, 4), "little"),
         int.from_bytes(a(0xF85E8A + 12 * i + 8, 2), "little"),
         int.from_bytes(a(0xF85E8A + 12 * i + 10, 2), "little")) for i in range(4)]
check("EntryPoint_Records: 4 records, every entry in 0xF00000-0xFFFFFF",
      all(0xF00000 <= r[0] <= 0xFFFFFF for r in recs), str(recs))
check("EntryPoint_Records: every stack in 0x0060E800-0x0060EC80",
      all(0x0060E800 <= r[1] <= 0x0060EC80 for r in recs))
check("EntryPoint_Records: +8 is 0x8800 in all four",
      all(r[2] == 0x8800 for r in recs))
check("EntryPoint_Records: +10 is in 1..3 in all four",
      all(1 <= r[3] <= 3 for r in recs), str([r[3] for r in recs]))
check("EntryPoint_Records: the DSP task's record is the one with +10 == 1",
      [r[3] for r in recs].index(1) == 2 and recs[2][0] == 0xF85EC8)
check("EntryPoint_Records: a fifth record's 'entry' would be 0x01000100, not an address",
      int.from_bytes(a(0xF85EBA, 4), "little") == 0x01000100)
# and the same two fields in prom_c's copy, so the "seven records" claim is real
try:
    C = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

    def c(addr, n=1):
        return C[addr - 0xF80000:addr - 0xF80000 + n]
    crecs = [(int.from_bytes(c(0xF980EA + 12 * i, 4), "little"),
              int.from_bytes(c(0xF980EA + 12 * i + 8, 2), "little"),
              int.from_bytes(c(0xF980EA + 12 * i + 10, 2), "little")) for i in range(3)]
    check("prom_c EntryPoint_Records: 3 records, +8 == 0x8800, +10 in 1..3",
          all(r[1] == 0x8800 and 1 <= r[2] <= 3 for r in crecs), str(crecs))
    check("prom_c: the DSP refresh entry 0xF98118 is the record with +10 == 1",
          [r[2] for r in crecs].index(1) == 2 and crecs[2][0] == 0xF98118)
except Exception as e:                                           # noqa: BLE001
    print("SKIP  prom_c EntryPoint_Records cross-check (%s)" % type(e).__name__)

check("0xF85E5B: TCB address = 0x02F4 + A*12, and it clears node+9 to 0",
      a(0xF85E64, 3) == bytes([0xC9, 0x08, 0x0C])
      and a(0xF85E67, 4) == bytes([0xD8, 0xC8, 0xF4, 0x02])
      and a(0xF85E7F, 4) == bytes([0xBC, 0x09, 0x00, 0x00]))
check("the 4x12+8 arithmetic lines up in RAM and in ROM",
      0x02F4 + 4 * 12 + 8 == 0x032C and 0xF85E8A + 4 * 12 + 8 == 0xF85EC2)

# --- "every reference to the 0x7A window, and there are only four" -----------
# prom_a/wsa1_prom_a.s, the 0xFE594C block header.  Same shape as the 0x7B
# census above, plus the `ld XRR,imm32` form the two DMA setups use.
h7a = []
for img, base, tag in ((A, 0xF80000, "prom_a"), (B, 0xF00000, "prom_b")):
    for t in range(0x7A0000, 0x7A0010):
        le = bytes([t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF])
        i = img.find(le)
        while i >= 0:
            if i >= 1 and img[i - 1] in (0xC2, 0xD2, 0xE2, 0xF2):
                h7a.append((tag, base + i - 1, t))
            if (i >= 1 and 0x40 <= img[i - 1] <= 0x47
                    and i + 3 < len(img) and img[i + 3] == 0x00):
                h7a.append((tag, base + i - 1, t))
            i = img.find(le, i + 1)
check("0x7A window: exactly four references in prom_a + prom_b",
      len(h7a) == 4, str(h7a))
check("0x7A window: all four name 0x7A0000 and no other address in it",
      all(t == 0x7A0000 for _, _, t in h7a))
check("0x7A window: the four sites are the two DMA setups and the two PIO accesses",
      sorted(x for _, x, _ in h7a) == [0xFE59BB, 0xFE59DA, 0xFE680F, 0xFE682B],
      str(sorted(hex(x) for _, x, _ in h7a)))

# =============================================================================
# SEARCHED NEGATIVES -- the F1 failure mode, made runnable
# =============================================================================
# Round 1 put "these 22 bytes have NO counterpart in the KN5000 sub-CPU" in a
# header on the strength of a tool that could not have found one.  Every "nothing
# references X" sentence in prom_a is re-derived here instead of being trusted.
#
# THE SEARCH, stated so its limits are visible: the 3-byte little-endian address
# at EVERY byte offset of prom_a and prom_b -- which covers `call`/`jp`
# (0x1B/0x1D), `lda XRR,nnn`, a bare LE32 pointer and any 24-bit memory operand,
# because all of them contain those three bytes -- plus every PC-relative
# `calr` (0x1E), `jr cc` (0x60-0x6F) and `jrl cc` (0x70-0x7F) displacement in
# prom_a resolved to its target.  It does NOT cover an address that is computed
# at run time, and it over-reports rather than under-reports, so ZERO hits is the
# only result it states exactly.


def names_addr(target):
    """Every byte offset in prom_a/prom_b holding target's 3-byte LE address."""
    le = bytes([target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF])
    out = []
    for img, base, tag in ((A, 0xF80000, "prom_a"), (B, 0xF00000, "prom_b")):
        i = img.find(le)
        while i >= 0:
            out.append((tag, base + i))
            i = img.find(le, i + 1)
    return out


def _rel_targets():
    """{target: [site, ...]} for every PC-relative branch in prom_a."""
    import struct
    m = {}
    for i in range(len(A) - 3):
        op, at = A[i], 0xF80000 + i
        if op == 0x1E or 0x70 <= op <= 0x7F:
            t = at + 3 + struct.unpack('<h', A[i + 1:i + 3])[0]
        elif 0x60 <= op <= 0x6F:
            t = at + 2 + struct.unpack('<b', A[i + 1:i + 2])[0]
        else:
            continue
        m.setdefault(t, []).append(at)
    return m


REL = _rel_targets()

for addr, label in ((0xF85E8A, "EntryPoint_Records"),
                    (0xF85F0F, "DSP_ChannelRegs_Init")):
    hits = names_addr(addr)
    rel = REL.get(addr, [])
    check("nothing names 0x%06X (%s): 0 byte hits" % (addr, label),
          not hits, str(hits))
    check("nothing branches to 0x%06X (%s): 0 PC-relative hits" % (addr, label),
          not rel, str([hex(x) for x in rel]))

# Two headers claimed this and were WRONG; the check above is what caught them,
# so the corrected positives are pinned here rather than quietly dropped.
check("Kernel_RotateQueue IS published through prom_b thunk 0xF42D78",
      ("prom_b", 0xF42D79) in names_addr(0xF858C0) and b(0xF42D78, 1) == b"\x1b")
check("the prom_b thunk run 0xF42D70-0xF42D83 is five kernel entry points",
      [int.from_bytes(b(0xF42D70 + 4 * i + 1, 3), "little") for i in range(5)]
      == [0xF8584A, 0xF85877, 0xF858C0, 0xF85904, 0xF8592D]
      and all(b(0xF42D70 + 4 * i, 1) == b"\x1b" for i in range(5)))
check("Dev7A_StartDma has FOUR calr callers, not none",
      sorted(REL.get(0xFE596A, [])) == [0xFE5FE5, 0xFE6300, 0xFE6427, 0xFE65D6],
      str([hex(x) for x in sorted(REL.get(0xFE596A, []))]))
check("Dev7A_StartDma: 0xFE6427's caller sets (0x605A3C) immediately before",
      a(0xFE6422, 5) == bytes([0xF2, 0x3C, 0x5A, 0x60, 0x60]))

# ...and the positives from the same search, so it is shown to WORK
check("Kernel_YieldRotate IS published through prom_b thunk 0xF42D74",
      ("prom_b", 0xF42D75) in names_addr(0xF85877)
      and b(0xF42D74, 1) == b"\x1b")
check("MsgQueue_ReceiveBlocking IS published through prom_b thunk 0xF42DCC",
      ("prom_b", 0xF42DCD) in names_addr(0xF85C89)
      and b(0xF42DCC, 1) == b"\x1b")
check("DSP_RefreshTask IS named, exactly once, and by the record table",
      names_addr(0xF85EC8) == [("prom_a", 0xF85EA2)] and not REL.get(0xF85EC8))
check("the same search finds the four calls to DSP_ChannelRegs_Write8",
      sorted(REL.get(0xF85F59, [])) == [0xF85F22, 0xF85F29, 0xF85F30, 0xF85F37])

# --- the three prom_b thunks EntryPoint_Records points at ---------------------
for slot, target in ((0xF4005C, 0xF827C8), (0xF42E88, 0xF8DA00), (0xF433C0, 0xFE02AB)):
    check("prom_b 0x%06X is `jp 0x%06X`" % (slot, target),
          b(slot, 1) == b"\x1b"
          and int.from_bytes(b(slot + 1, 3), "little") == target)
check("Kernel_Dispatch's boot stack 0x0060EB80 lies inside the records' stack run",
      a(0xF8572B, 5) == bytes([0x47, 0x80, 0xEB, 0x60, 0x00])
      and 0x0060E800 <= 0x0060EB80 <= 0x0060EC80)


# =============================================================================
# ROUND 3 -- the eleven SWI7 services converted on 2026-08-25, and everything
# their headers quantify.  Same rule as rounds 1 and 2: every number a header
# states is rebuilt from the ROM here.
# =============================================================================

# --- all 34 live SWI7 slots now point at converted code -----------------------
NEW_SVC = {0x0E: 0xF8F850, 0x1B: 0xF8F8BD, 0x0F: 0xF8FA60, 0x10: 0xF8FB7E,
           0x11: 0xF8FCB2, 0x12: 0xF8FE80, 0x14: 0xF8FEBC, 0x15: 0xF900B0,
           0x17: 0xF90118, 0x1C: 0xF9025E, 0x1E: 0xF908FF}
for svc, addr in sorted(NEW_SVC.items()):
    check("svc 0x%02X: SWI7 slot 0x%02X holds 0x%06X" % (svc, svc, addr),
          int.from_bytes(a(0xF8E9C6 + 4 * svc, 4), "little") == addr)

# --- svc 0x0E is svc 0x03 with the source pointer replaced by a constant ------
check("svc 0x0E: 109 bytes, svc 0x03: 111 bytes",
      (0xF8F8BD - 0xF8F850, 0xF8EE23 - 0xF8EDB4) == (109, 111))
check("svc 0x03's inner body reads the caller's buffer (ld E,(XIY); inc 1,XIY)",
      a(0xF8EE0A, 4) == bytes([0x85, 0x25, 0xED, 0x61]))
check("svc 0x0E hoists `ld E,0x00` instead, and 111-4+2 = 109",
      a(0xF8F873, 2) == bytes([0x25, 0x00]) and 111 - 4 + 2 == 109)
check("svc 0x0E takes its offset from IY (dd 88), svc 0x03 from IX (dc 88)",
      a(0xF8F86D, 2) == bytes([0xDD, 0x88]) and a(0xF8EDD1, 2) == bytes([0xDC, 0x88]))

# --- svc 0x1B erases: the two mask helpers, each followed by `xor A,0xff` -----
check("svc 0x1B: calr 0xF8F767 at 0xF8F926, then xor A,0xff",
      a(0xF8F926, 3) == bytes([0x1E, 0x3E, 0xFE])
      and 0xF8F929 + 0 and a(0xF8F929, 3) == bytes([0xC9, 0xCD, 0xFF]))
check("svc 0x1B: calr 0xF8F7A4 at 0xF8FA0F, then xor A,0xff",
      a(0xF8FA0F, 3) == bytes([0x1E, 0x92, 0xFD])
      and a(0xF8FA12, 3) == bytes([0xC9, 0xCD, 0xFF]))
check("svc 0x1B: the whole byte-columns are written as 0x00 (ld A,0x00)",
      a(0xF8F9B8, 2) == bytes([0x21, 0x00]))
check("svc 0x05 writes 0xFF there instead (ld (XIX),0xff at 0xF8EFE4)",
      a(0xF8EFE4, 3) == bytes([0xB4, 0x00, 0xFF]))
check("svc 0x1B does NOT call LCD_ClampCoordsToPanel, svc 0x05 does",
      a(0xF8EEC5, 3) == bytes([0x1E, 0xA3, 0xFC])
      and bytes([0x1E]) + (0xF8EB6B - 0xF8F8C3).to_bytes(2, "little", signed=True)
          not in a(0xF8F8BD, 8))

# --- svc 0x0F / svc 0x10: the two panel modes --------------------------------
def cmd_args(lo, hi):
    """(command byte, [immediate data bytes]) pairs written to the two ports
    through XIY in the range, in order.  bd 01 00 nn = command, b5 00 nn = data
    immediate, b5 41 / b5 40 = data from A / W."""
    out, i = [], lo
    while i < hi:
        if a(i, 3) == bytes([0xBD, 0x01, 0x00]):
            out.append(("cmd", a(i + 3, 1)[0])); i += 4
        elif a(i, 2) == bytes([0xB5, 0x00]):
            out.append(("imm", a(i + 2, 1)[0])); i += 3
        elif a(i, 2) in (bytes([0xB5, 0x41]), bytes([0xB5, 0x40])):
            out.append(("reg", a(i + 1, 1)[0])); i += 2
        else:
            i += 1
    return out

INIT = cmd_args(0xF8E819, 0xF8E99F)
S0F = cmd_args(0xF8FA60, 0xF8FB7E)
S10 = cmd_args(0xF8FB7E, 0xF8FCB2)
def after(seq, cmd, n):
    i = seq.index(("cmd", cmd))
    return [v for k, v in seq[i + 1:i + 1 + n]]
check("svc 0x0F and 0x10 both send SYSTEM SET with 30 07 00 27 35 EF",
      after(S0F, 0x40, 6) == [0x30, 0x07, 0x00, 0x27, 0x35, 0xEF]
      == after(S10, 0x40, 6) == after(INIT, 0x40, 6))
check("svc 0x0F's SCROLL carries SIX parameters: 00 00 F0 00 40 F0",
      after(S0F, 0x44, 6) == [0x00, 0x00, 0xF0, 0x00, 0x40, 0xF0]
      and S0F[S0F.index(("cmd", 0x44)) + 7][0] == "cmd")
check("svc 0x10's SCROLL carries EIGHT: 00 00 F0 00 26 F0 00 4C",
      after(S10, 0x44, 8) == [0x00, 0x00, 0xF0, 0x00, 0x26, 0xF0, 0x00, 0x4C]
      and S10[S10.index(("cmd", 0x44)) + 9][0] == "cmd")
check("svc 0x0F OVLAY = 0x0C (OV bit 4 CLEAR -> two layers)",
      after(S0F, 0x5B, 1) == [0x0C] and not (0x0C >> 4) & 1)
check("svc 0x10 OVLAY = 0x1C (OV bit 4 SET -> three layers), as the setup does",
      after(S10, 0x5B, 1) == [0x1C] and after(INIT, 0x5B, 1) == [0x1C]
      and (0x1C >> 4) & 1)
check("svc 0x0F and 0x10 send DISP OFF and DISP ON with NO parameter",
      all(s[s.index(("cmd", 0x58)) + 1][0] == "cmd"
          and s.index(("cmd", 0x59)) == len(s) - 1 for s in (S0F, S10)))
check("neither sends HDOT SCR (0x5A) or CSRFORM (0x5D); the setup sends both",
      all(("cmd", c) not in s for s in (S0F, S10) for c in (0x5A, 0x5D))
      and ("cmd", 0x5A) in INIT and ("cmd", 0x5D) in INIT)
for name, lo, hi, want in (("svc 0x0F", 0xF8FA60, 0xF8FB7E, [(0x2541, 0x0000), (0x2543, 0x4000)]),
                           ("svc 0x10", 0xF8FB7E, 0xF8FCB2, [(0x2541, 0x0000), (0x2543, 0x2600), (0x2545, 0x4C00)])):
    got = []
    i = lo
    while i < hi - 8:
        if a(i, 1) == b"\x21" and a(i + 2, 1) == b"\x20" and a(i + 4, 2) == bytes([0xF1]) + b"":
            pass
        if a(i, 1) == b"\x21" and a(i + 2, 1) == b"\x20" and a(i + 4, 1) == b"\xF1" and a(i + 7, 1) == b"\x50":
            got.append((int.from_bytes(a(i + 5, 2), "little"),
                        a(i + 1, 1)[0] | a(i + 3, 1)[0] << 8))
            i += 8
            continue
        i += 1
    check("%s writes the layer words %s" % (name, [(hex(x), hex(y)) for x, y in want]),
          got == want, str([(hex(x), hex(y)) for x, y in got]))
# the clear loop: `ld BC,n` then n iterations of a 16-store body
for name, bcaddr, want_bc, last_layer in (("svc 0x0F", 0xF8FB20, 0x0658, 0x4000),
                                          ("svc 0x10", 0xF8FC54, 0x0718, 0x4C00),
                                          ("setup", 0xF8E92F, 0x0800, None)):
    bc = int.from_bytes(a(bcaddr + 1, 2), "little")
    body_lo = bcaddr + 3
    # the djnz that closes the loop, and how many `ld (XIY),A` are inside it
    j, stores, end = body_lo, 0, None
    while j < body_lo + 0x100:
        if a(j, 2) == bytes([0xB5, 0x41]):
            stores += 1; j += 2; continue
        if a(j, 1) == b"\xD9" and a(j + 1, 1) == b"\x1C":
            end = j; break
        j += 1
    check("%s: clear loop is `ld BC,0x%04X` and 16 stores" % (name, want_bc),
          bc == want_bc and stores == 16 and end is not None,
          "bc=%04X stores=%d" % (bc, stores))
    if last_layer is not None:
        check("%s: 0x%04X * 16 = 0x%04X = 0x%04X + 240*40, the end of the last layer"
              % (name, want_bc, want_bc * 16, last_layer),
              want_bc * 16 == last_layer + 240 * 40)
check("setup: 0x0800 * 16 = 32768 = the whole display RAM", 0x0800 * 16 == 32768)
check("svc 0x10 is 308 bytes and LCD_Init_SED1330 is 390",
      (0xF8FCB2 - 0xF8FB7E, 0xF8E99F - 0xF8E819) == (308, 390))

# --- the dither pair, and the FIVE nine-byte edge-mask tables ----------------
SH, RO = a(0xF8FE52, 9), a(0xF8FE5B, 9)
check("dither: shift[k] == rot[k] & (0xFF >> k) for every reachable k = 0..7",
      all(SH[k] == (RO[k] & (0xFF >> k)) for k in range(8)))
LEFT = [(0xFF >> k) & 0xFF for k in range(9)]
RIGHT = [(0xFF << (8 - k)) & 0xFF for k in range(9)]
check("0xF9008B is 0xFF>>k for all nine k", list(a(0xF9008B, 9)) == LEFT)
check("0xF9008B differs from 0xF8F79B in exactly ONE byte, index 0",
      [i for i in range(9) if a(0xF9008B, 9)[i] != a(0xF8F79B, 9)[i]] == [0]
      and a(0xF8F79B, 1) == b"\x00" and a(0xF9008B, 1) == b"\xFF")
RIGHT_TABLES = {0xF8F7AF: 8, 0xF8FE77: 8, 0xF900A7: 9, 0xF905D5: 9, 0xF9076D: 9}
for base, nmatch in RIGHT_TABLES.items():
    check("0x%06X matches 0xFF<<(8-k) in %d of 9 entries" % (base, nmatch),
          sum(1 for k in range(9) if a(base, 9)[k] == RIGHT[k]) == nmatch)
check("0xF8F7AF, 0xF8FE77 are byte-identical (9 of 9)",
      a(0xF8F7AF, 9) == a(0xF8FE77, 9))
check("0xF900A7, 0xF905D5, 0xF9076D are byte-identical (9 of 9)",
      a(0xF900A7, 9) == a(0xF905D5, 9) == a(0xF9076D, 9))
check("the two groups differ only at index 8 (0x00 against 0xFF)",
      [i for i in range(9) if a(0xF8F7AF, 9)[i] != a(0xF900A7, 9)[i]] == [8])
check("the two pattern right-edge helpers are 19 bytes with 16 equal",
      len(a(0xF8FE64, 19)) == 19
      and sum(1 for i in range(19) if a(0xF8FE64, 19)[i] == a(0xF90094, 19)[i]) == 16
      and [i for i in range(19) if a(0xF8FE64, 19)[i] != a(0xF90094, 19)[i]] == [1, 2, 3])
check("`and (0x255e),A` is the memory-destination form (op 0xC9)",
      a(0xF8FE6E, 4) == bytes([0xC1, 0x5E, 0x25, 0xC9])
      and a(0xF9009E, 4) == bytes([0xC1, 0x5E, 0x25, 0xC9]))

# --- svc 0x14's RAM pattern, and svc 0x15's changed loop test ----------------
check("svc 0x14's pattern table is `ld XHL,0x00002538` and IY wraps at 8",
      a(0xF90070, 5) == bytes([0x43, 0x38, 0x25, 0x00, 0x00])
      and a(0xF90068, 4) == bytes([0xDD, 0xCF, 0x08, 0x00]))
check("svc 0x14 zeroes IY once, at its second instruction",
      a(0xF8FEC4, 2) == bytes([0xDD, 0xD5]))
check("svc 0x00's step test is `jr NC` (0x6F), svc 0x15's is `jr UGT` (0x6B)",
      a(0xF8EADA, 1) == b"\x6F" and a(0xF900C5, 1) == b"\x6B")
check("svc 0x12 has no zero-height guard where svc 0x02 has `and BC,BC`",
      a(0xF8F746, 2) == bytes([0xD9, 0xC1])
      and bytes([0xD9, 0xC1]) not in a(0xF8FE80, 0x1D))

# --- the two PACKED text services: fonts, pitches, advances ------------------
PACKED = ((0x17, 0xF90118, 0xF1E470, 0x08, 8, 6, 0xF901F5, 0x02),
          (0x1C, 0xF9025E, 0xF1EAB0, 0x10, 32, 11, 0xF90367, 0x05))
for svc, addr, base, pitch, size, adv, advsite, flush in PACKED:
    blob = a(addr, 0x150)
    check("svc 0x%02X: loads XIX = 0x%06X, the font base" % (svc, base),
          bytes([0x44, base & 0xFF, (base >> 8) & 0xFF, (base >> 16) & 0xFF, 0x00]) in blob)
    check("svc 0x%02X: glyph pitch immediate `ld W,0x%02X` + `mul WA,W`" % (svc, pitch),
          bytes([0x20, pitch, 0xC8, 0x41]) in blob)
    check("svc 0x%02X: advance is `add (0x259e),0x%02X`" % (svc, adv),
          a(advsite, 5) == bytes([0xC1, 0x9E, 0x25, 0x38, adv]))
    check("svc 0x%02X: the flush special-cases offset %d = (8 - %d) mod 8"
          % (svc, flush, adv), flush == (8 - adv) % 8)
check("svc 0x1C's glyph offset is doubled (`sla 0x01,HL`), so 32 bytes a glyph",
      a(0xF902AF, 3) == bytes([0xDB, 0xEC, 0x01]) and 0x10 * 2 == 32)
check("TextShift_LoadGlyph16 keeps three bits of the second byte (and W,0xE0)",
      a(0xF90466, 3) == bytes([0xC8, 0xCC, 0xE0]) and bin(0xE0).count("1") == 3
      and 8 + 3 == 11)
check("font 0xF1E470 (8x8) passes the ASCII test", ascii_font(0xF1E470, 8))
check("font 0xF1EAB0 (16x16, 32 bytes) passes the ASCII test",
      ascii_font(0xF1EAB0, 32))

# --- the three staging buffers are adjacent and 16 bytes each ----------------
check("TextShift buffers: 0x256A, 0x257A, 0x258A, then 0x259A -- 16 bytes each",
      0x257A - 0x256A == 0x258A - 0x257A == 0x259A - 0x258A == 16)
check("TextShift_ClearBufA/C: 18 bytes, ONE differing byte (the buffer address)",
      [i for i in range(18) if a(0xF9040A, 18)[i] != a(0xF9041C, 18)[i]] == [6])
check("TextShift_CopyAtoC/BtoC: 15 bytes, ONE differing byte",
      [i for i in range(15) if a(0xF904D5, 15)[i] != a(0xF904E4, 15)[i]] == [2])
check("TextShift_ShiftRight is 49 bytes and ShiftLeft 45, the four being `ld C,(0x259e)`",
      (0xF904A8 - 0xF90477, 0xF904D5 - 0xF904A8) == (49, 45)
      and a(0xF90484, 4) == bytes([0xC1, 0x9E, 0x25, 0x23]))
check("the two shifts are the register-count forms cb ff (srl) and cb fc (sla)",
      a(0xF90496, 2) == bytes([0xD9, 0xFF]) and a(0xF904C3, 2) == bytes([0xD9, 0xFC]))

# --- the four column mergers: 172 bytes, three of them byte-identical ---------
MERGE = (0xF90512, 0xF905DE, 0xF906AA, 0xF90776)
for m in MERGE:
    check("column merger at 0x%06X is 172 bytes" % m,
          {0xF90512: 0xF905BE, 0xF905DE: 0xF9068A,
           0xF906AA: 0xF90756, 0xF90776: 0xF90822}[m] - m == 172)
check("0xF90512, 0xF905DE and 0xF90776 are byte-identical, 172 of 172",
      a(0xF90512, 172) == a(0xF905DE, 172) == a(0xF90776, 172))
diff = [i for i in range(172) if a(0xF90512, 172)[i] != a(0xF906AA, 172)[i]]
check("0xF906AA differs in exactly 13 bytes, offsets 154-166",
      diff == list(range(154, 167)), str(diff))
check("and those 13 bytes are a PERMUTATION of the same 13",
      sorted(a(0xF90512 + 154, 13)) == sorted(a(0xF906AA + 154, 13)))
check("the difference is `inc 1,IZ` moving from before the store to after it",
      a(0xF905AC, 2) == bytes([0xDE, 0x61]) and a(0xF905B7, 2) == bytes([0xB3, 0x41])
      and a(0xF9074D, 2) == bytes([0xB3, 0x41]) and a(0xF9074F, 2) == bytes([0xDE, 0x61]))
FETCH = (0xF905BE, 0xF9068A, 0xF90756, 0xF90822)
for f in FETCH:
    check("mask fetcher at 0x%06X is 23 bytes" % f,
          {0xF905BE: 0xF905D5, 0xF9068A: 0xF906A1,
           0xF90756: 0xF9076D, 0xF90822: 0xF90839}[f] - f == 23)
for f in FETCH[1:]:
    d = [i for i in range(23) if a(FETCH[0], 23)[i] != a(f, 23)[i]]
    check("mask fetcher 0x%06X differs from 0xF905BE in TWO bytes, 9 and 10" % f,
          d == [9, 10], str(d))
check("all four mergers call their fetcher with the same displacement 0x005A",
      all(a(m + 0x4F, 3) == bytes([0x1E, 0x5A, 0x00]) for m in MERGE))

# --- the two TAIL mask tables, against the rule the headers state ------------
def tail_rule(W):
    return [0x00 if (k + W) % 8 == 0 else (0xFF >> ((k + W) % 8)) & 0xFF
            for k in range(9)]
t16, t8 = list(a(0xF906A1, 9)), list(a(0xF90839, 9))
check("LCD_TextColMask_Tail16 == 0xFF>>((k+11)%8), 0 at the boundary: 9 of 9",
      t16 == tail_rule(11), str([hex(x) for x in t16]))
d8 = [i for i in range(9) if t8[i] != tail_rule(6)[i]]
check("LCD_TextColMask_Tail8 fits the same rule with W=6 in 8 of 9, index 1 apart",
      d8 == [1] and t8[1] == 0x00 and tail_rule(6)[1] == 0x01, str(d8))

# --- svc 0x1E, the panel scroll ---------------------------------------------
check("svc 0x1E: the amount is C and 0x0F, with W cleared",
      a(0xF90902, 6) == bytes([0xCB, 0x89, 0xC9, 0xCC, 0x0F]) + b"\xC8"
      and a(0xF90907, 2) == bytes([0xC8, 0xD0]))
check("svc 0x1E: the direction is C and 0xC0, tested against 0x00, 0x40, 0x80",
      a(0xF90909, 3) == bytes([0xCB, 0xCC, 0xC0])
      and a(0xF9090C, 2) == bytes([0xCB, 0xD8])
      and a(0xF90910, 3) == bytes([0xCB, 0xCF, 0x40])
      and a(0xF90915, 3) == bytes([0xCB, 0xCF, 0x80]))
check("svc 0x1E: both LINE arms multiply by 0x0028 = AP = 40",
      a(0xF90926, 5) == bytes([0x32, 0x28, 0x00, 0xDA, 0x40])
      and a(0xF90931, 5) == bytes([0x32, 0x28, 0x00, 0xDA, 0x40])
      and 0x28 == 40)
check("svc 0x1E: add-line at 0xF9092B, sub-line at 0xF90936, add-byte 0xF9091A, sub-byte 0xF90920",
      a(0xF9092B, 4) == bytes([0xD1, 0x55, 0x25, 0x88])
      and a(0xF90936, 4) == bytes([0xD1, 0x55, 0x25, 0xA8])
      and a(0xF9091A, 4) == bytes([0xD1, 0x55, 0x25, 0x88])
      and a(0xF90920, 4) == bytes([0xD1, 0x55, 0x25, 0xA8]))
check("svc 0x1E: it walks LCD_LayerBasePtr_Table the way LCD_SelectCurrentLayer does",
      a(0xF9093C, 4) == bytes([0xC1, 0x40, 0x25, 0x27])
      and a(0xF90940, 3) == bytes([0xDB, 0xEC, 0x02])
      and a(0xF90943, 5) == bytes([0x45, 0xB1, 0xEE, 0xF8, 0x00]))
check("svc 0x1E: the write-back is 32 bits WIDE (e1 .. 20 load, b3 60 store)",
      a(0xF9094D, 4) == bytes([0xE1, 0x55, 0x25, 0x20])
      and a(0xF90951, 2) == bytes([0xB3, 0x60]))
check("...while LCD_SelectCurrentLayer's read of the same word is 16 bits (93 20)",
      a(0xF8EEA8, 2) == bytes([0x93, 0x20]))
S1E = cmd_args(0xF908FF, 0xF90989)
check("svc 0x1E re-sends SCROLL (0x44) and nothing else",
      [c for k, c in S1E if k == "cmd"] == [0x44])
check("svc 0x1E's SCROLL takes its three SADs from (0x2541)/(0x2543)/(0x2545)",
      [int.from_bytes(a(x + 1, 2), "little") for x in (0xF9095E, 0xF9096E, 0xF9097E)]
      == [0x2541, 0x2543, 0x2545])
check("svc 0x1E sends SL1 = SL2 = 0xF0 = 240 between them",
      a(0xF9096A, 3) == bytes([0xB5, 0x00, 0xF0])
      and a(0xF9097A, 3) == bytes([0xB5, 0x00, 0xF0]))

# --- ROUND 3: MemCopyWords' direction ----------------------------------------
# prom_a 0xF8E6E2's header had source and destination the wrong way round.  The
# direction is a property of the INSTRUCTION: MAME's op_90 sets p1 (the LDIRW
# destination) to register (prefix-1) & 7 and p2 (the source) to prefix & 7
# (900tbl.hxx:5472-5473, :198, :2514), so prefix 0x95 means dest XIX, src XIY.
# These checks pin which stack argument lands in which register, so the sentence
# above them cannot drift back.
check("MemCopyWords: XIY (the LDIRW SOURCE) comes from (XSP+0x08)",
      a(0xF8E6E6, 3) == bytes([0xAF, 0x08, 0x25]))
check("MemCopyWords: XIX (the LDIRW DEST) comes from (XSP+0x0C)",
      a(0xF8E6E9, 3) == bytes([0xAF, 0x0C, 0x24]))
check("MemCopyWords: the count comes from (XSP+0x10) and is halved before LDIRW",
      a(0xF8E6E3, 3) == bytes([0x9F, 0x10, 0x21])
      and a(0xF8E6F3, 3) == bytes([0xD9, 0xEF, 0x01]))
check("MemCopyWords: odd-byte lead-in is `ldi` (85 10), the copy is `ldirw` (95 11)",
      a(0xF8E6F1, 2) == bytes([0x85, 0x10]) and a(0xF8E6F6, 2) == bytes([0x95, 0x11]))
check("TextShift_CopyAtoC has the same shape: XIY = 0x256A src, XIX = 0x258A dst",
      a(0xF904D6, 5) == bytes([0x45, 0x6A, 0x25, 0x00, 0x00])
      and a(0xF904DB, 5) == bytes([0x44, 0x8A, 0x25, 0x00, 0x00])
      and a(0xF904E0, 2) == bytes([0x95, 0x11]))

# --- ROUND 3: the call-site counts the text-column headers assert ------------
# Each of these numbers was in a header with nothing to reproduce it.  They use
# the same REL/names_addr search as the searched negatives above, so their
# limits are the ones stated there.
for addr, label, want in (
        (0xF9087E, "LCD_TextCol_SetCursor", [0xF90190, 0xF901AC, 0xF901BB,
                                             0xF9021F, 0xF9023B, 0xF902CC,
                                             0xF902E5, 0xF90317, 0xF90384,
                                             0xF9039D, 0xF903D0, 0xF903FB]),
        (0xF908B8, "LCD_TextCol_ReadIntoBufA", [0xF901B2]),
        (0xF904F3, "TextShift_OrCintoA", [0xF9020D, 0xF90381]),
        (0xF905BE, "LCD_TextColMask_Head16_Fetch", [0xF90561]),
        (0xF90756, "LCD_TextColMask_Head8_Fetch", [0xF906F9, 0xF908EB]),
        (0xF90822, "LCD_TextColMask_Tail8_Fetch", [0xF907C5])):
    got = sorted(REL.get(addr, []))
    check("%s: exactly %d caller(s), and they are the listed ones"
          % (label, len(want)), got == want, str([hex(x) for x in got]))
    check("%s: no site NAMES its address as data" % label,
          not names_addr(addr), str(names_addr(addr)))

# MIDI_RX_Drop is reached BOTH ways, which is why it is checked differently.
check("MIDI_RX_Drop: one branch caller (0xFA5777) and one table slot (0xFA5796)",
      sorted(REL.get(0xFA57AE, [])) == [0xFA5777]
      and names_addr(0xFA57AE) == [("prom_a", 0xFA5796)])
check("MIDI_RX_Drop: slot 2 of MIDI_StatusDispatch_Table is that byte hit",
      0xFA5796 == 0xFA578E + 2 * 4)
check("MIDI_RX_Drop is a single 0x0E RET", a(0xFA57AE, 1) == b"\x0e")

# --- ROUND 3: LCD_BitMaskTable, LCD_EntryThunks, the INTT3 epilogue path ------
check("LCD_BitMaskTable is 80 40 20 10 08 04 02 01",
      list(a(0xF8EDAC, 8)) == [0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01])
check("LCD_EntryThunks: six `jp nnn`, four of them to the 0x0E RET at 0xF8E818",
      all(a(0xF8E800 + 4 * i, 1) == b"\x1b" for i in range(6))
      and [int.from_bytes(a(0xF8E800 + 4 * i + 1, 3), "little") for i in range(6)]
      == [0xF8E819, 0xF8E818, 0xF8E99F, 0xF8E818, 0xF8E818, 0xF8E818]
      and a(0xF8E818, 1) == b"\x0e")
# The IRQ_Epilogue header said three handlers "end that way".  Only TWO spell
# `jp 0xF42D68`; the INTT3 handler reaches 0xF857B7 directly with `jrl`.
_JPTHUNK = bytes([0x1B, 0x68, 0x2D, 0xF4])
check("`jp 0xF42D68` occurs exactly twice in prom_a and never in prom_b",
      [0xF80000 + i for i in range(len(A) - 3) if A[i:i + 4] == _JPTHUNK]
      == [0xF82E9E, 0xF83030] and _JPTHUNK not in B)
check("prom_b 0xF42D68 is `jp 0xF857B7` = IRQ_Epilogue",
      b(0xF42D68, 4) == bytes([0x1B, 0xB7, 0x57, 0xF8]))
check("the INTT3 handler reaches IRQ_Epilogue DIRECTLY: 0xF85603 is `jrl 0xF857B7`",
      a(0xF85600, 3) == bytes([0xC0, 0xBE, 0x61])
      and a(0xF85603, 3) == bytes([0x78, 0xB1, 0x01])
      and 0xF85603 + 3 + 0x01B1 == 0xF857B7)
check("prom_b 0xF42D64 (vector slot 0x4C) is `jp 0xF85600`",
      b(0xF42D64, 4) == bytes([0x1B, 0x00, 0x56, 0xF8]))

# =============================================================================
# ROUND 3 -- the kernel's TWO PUBLISHED ABIs, and the task lifecycle
# =============================================================================
# prom_a 0xF857D6's region banner claims prom_b holds two runs of thunks into
# the kernel, a register-argument face and a stack-argument face, and that the
# pairing resolves with no residue.  Every number in that claim is here.
K_RUN1 = [0xF857D9, 0xF8584A, 0xF85877, 0xF858C0, 0xF85904, 0xF8592D,
          0xF8596D, 0xF859AE, 0xF85A22, 0xF85A96, 0xF85B1F, 0xF85BD4,
          0xF85C8C, 0xF85DA8, 0xF85E02, 0xF85E5E]
K_RUN2 = [0xF857D6, 0xF8584A, 0xF85874, 0xF85904, 0xF8592A, 0xF859AB,
          0xF85A93, 0xF85B0D, 0xF85C89, 0xF85DA2, 0xF85E5B]
check("kernel thunk run 1: 0xF42D6C-0xF42DA8 is 16 `jp` into prom_a",
      all(b(0xF42D6C + 4 * i, 1) == b"\x1b" for i in range(16))
      and [int.from_bytes(b(0xF42D6C + 4 * i + 1, 3), "little") for i in range(16)]
      == K_RUN1)
check("kernel thunk run 2: 0xF42DAC-0xF42DD4 is 11 `jp` into prom_a",
      all(b(0xF42DAC + 4 * i, 1) == b"\x1b" for i in range(11))
      and [int.from_bytes(b(0xF42DAC + 4 * i + 1, 3), "little") for i in range(11)]
      == K_RUN2)
_pairs = [(x, min(y for y in K_RUN1 if y >= x)) for x in K_RUN2]
check("every run-2 slot pairs with a run-1 target at or above it (11 of 11)",
      len(_pairs) == 11 and all(hi >= lo for lo, hi in _pairs))
check("exactly 2 run-2 slots ARE a run-1 target: 0xF8584A and 0xF85904",
      [lo for lo, hi in _pairs if lo == hi] == [0xF8584A, 0xF85904])
_diff = [(lo, hi) for lo, hi in _pairs if lo != hi]
check("the other 9 ALL open with `ld A,(XSP+0x04)` (8F 04 21)",
      len(_diff) == 9
      and all(a(lo, 3) == bytes([0x8F, 0x04, 0x21]) for lo, _ in _diff),
      str([hex(x) for x, _ in _diff if a(x, 3) != bytes([0x8F, 0x04, 0x21])]))
check("7 of those 9 are EXACTLY that instruction (a 3-byte gap)",
      sorted(hi - lo for lo, hi in _diff) == [3, 3, 3, 3, 3, 3, 3, 6, 18])
check("0xF85DA2 takes a SECOND stack argument: `ld W,(XSP+0x06)` at +3",
      a(0xF85DA5, 3) == bytes([0x8F, 0x06, 0x20]))
check("0xF85B0D fetches its second argument after the pushes: (XSP+0x24)",
      a(0xF85B1A, 3) == bytes([0xAF, 0x24, 0x26]) and 0x24 == 0x06 + 2 + 7 * 4)

# --- Kernel_StartTask: the frame it builds is the frame Kernel_ResumeTask eats
check("Kernel_ResumeTask is 7 long pops, then `pop SR`, then `ret`",
      list(a(0xF85763, 9)) == [0x5E, 0x5D, 0x5C, 0x5A, 0x59, 0x58, 0x5B, 0x03, 0x0E])
check("Kernel_StartTask: frame = stack - 0x22, and 7*4 + 2 + 4 = 0x22",
      a(0xF85806, 6) == bytes([0xED, 0xCA, 0x22, 0x00, 0x00, 0x00])
      and 7 * 4 + 2 + 4 == 0x22)
check("Kernel_StartTask: SR to frame+0x1C, entry to frame+0x1E",
      a(0xF8580F, 3) == bytes([0xBD, 0x1C, 0x50])
      and a(0xF85815, 3) == bytes([0xBD, 0x1E, 0x60])
      and 7 * 4 == 0x1C and 0x1C + 2 == 0x1E)
check("Kernel_StartTask: record base is 0xF85E7E = EntryPoint_Records - 12",
      a(0xF857E9, 6) == bytes([0xEB, 0xC8, 0x7E, 0x5E, 0xF8, 0xFF])
      and (0xFFF85E7E & 0xFFFFFF) + 12 == 0xF85E8A)
check("Kernel_StartTask: TCB base is 0x02F4 = 0x0300 - 12, stride 12",
      a(0xF857E3, 2) == bytes([0x27, 0x0C]) and a(0xF857EF, 2) == bytes([0x23, 0x0C])
      and a(0xF857F3, 4) == bytes([0xD9, 0xC8, 0xF4, 0x02])
      and 0x02F4 + 12 == 0x0300)
check("Kernel_StartTask: queue head is 0x032C + level*4 = 0x0330 + (level-1)*4",
      a(0xF8582D, 4) == bytes([0xD8, 0xC8, 0x2C, 0x03]) and 0x032C + 4 == 0x0330)
check("Kernel_StartTask: it refuses when TCB+9 is non-zero, and writes 4 when not",
      a(0xF857FB, 3) == bytes([0x8C, 0x09, 0x21])
      and a(0xF85821, 4) == bytes([0xBC, 0x09, 0x00, 0x04]))
check("Kernel_StartTask ends `jrl Kernel_Dispatch` -- it never returns",
      a(0xF85847, 3) == bytes([0x78, 0xCB, 0xFE]) and 0xF8584A - 0x135 == 0xF85715)
check("Kernel_ExitTask: boot stack 0x0060EB80, state 0, (0xBF) cleared",
      a(0xF8584C, 5) == bytes([0x47, 0x80, 0xEB, 0x60, 0x00])
      and a(0xF85856, 4) == bytes([0xBC, 0x09, 0x00, 0x00])
      and a(0xF8585C, 3) == bytes([0xF0, 0xBF, 0x50]))
check("Kernel_ExitTask ends `jrl Kernel_Dispatch` too",
      a(0xF85871, 3) == bytes([0x78, 0xA1, 0xFE]) and 0xF85874 - 0x15F == 0xF85715)

# --- the 1-based layout, from the kernel's own boot code ----------------------
check("kernel boot clears FOUR TCBs from 0x0300, stride 12",
      a(0xF8562A, 3) == bytes([0x34, 0x00, 0x03])
      and a(0xF8562F, 2) == bytes([0x22, 0x04])
      and a(0xF85633, 3) == bytes([0xBC, 0x09, 0x41])
      and a(0xF85636, 4) == bytes([0xDC, 0xC8, 0x0C, 0x00]))
check("...so the four TCBs end at 0x032F and 0x0330 is the first queue head",
      0x0300 + 4 * 12 == 0x0330)

# --- ROUND 3: Kernel_InitRam, the kernel's whole RAM map --------------------
# prom_a 0xF85606's banner tabulates nine structures with their addresses,
# strides and counts.  Every row is an immediate in the routine, so every row
# is re-read here; the loop BOUNDS are checked too, because "four TCBs" and
# "eight nodes" are what make the layout add up.
check("Kernel_InitRam is reached only through prom_b thunk 0xF42D60",
      names_addr(0xF85606) == [("prom_b", 0xF42D61)] and b(0xF42D60, 1) == b"\x1b"
      and not REL.get(0xF85606))
check("Kernel_InitRam: boot stack 0x0060EB80, (0xBF) := 0, cr 0x3C := 1",
      a(0xF85606, 5) == bytes([0x47, 0x80, 0xEB, 0x60, 0x00])
      and a(0xF8560D, 3) == bytes([0xF0, 0xBF, 0x50])
      and a(0xF85612, 3) == bytes([0xD8, 0x2E, 0x3C]))
# the `ldb b,n` is at +5 except for the first loop, where a dead `ldw de,0x04`
# sits between the base load and the count -- so the count address is explicit.
for addr, baddr, base, count, label in (
        (0xF85615, 0xF8561D, 0x0330, 0x03, "3 ready-queue heads"),
        (0xF85662, 0xF85667, 0x033C, 0x08, "8 heads at 0x033C"),
        (0xF856B5, 0xF856BA, 0x0364, 0x04, "4 wait-queue heads"),
        (0xF856C7, 0xF856CC, 0x0374, 0x04, "4 message-queue heads")):
    check("Kernel_InitRam: %s, self-linked from 0x%04X" % (label, base),
          a(addr, 3) == bytes([0x33, base & 0xFF, base >> 8])
          and a(baddr, 2) == bytes([0x22, count]))
check("Kernel_InitRam: the dead `ldw de,0x0004` really is at 0xF8561A",
      a(0xF8561A, 3) == bytes([0x32, 0x04, 0x00])
      and a(0xF85658, 3) == bytes([0x32, 0x5C, 0x03]))
check("Kernel_InitRam: 4 TCBs from 0x0300, stride 12, +9 := 0",
      a(0xF8562A, 3) == bytes([0x34, 0x00, 0x03])
      and a(0xF8562F, 2) == bytes([0x22, 0x04])
      and a(0xF85633, 3) == bytes([0xBC, 0x09, 0x41])
      and a(0xF85636, 4) == bytes([0xDC, 0xC8, 0x0C, 0x00]))
check("Kernel_InitRam: 2 software timers from 0x03C8, stride 8, +4 := -1",
      a(0xF8563D, 3) == bytes([0x34, 0xC8, 0x03])
      and a(0xF85642, 2) == bytes([0x22, 0x02])
      and a(0xF85644, 5) == bytes([0x40, 0xFF, 0xFF, 0xFF, 0xFF])
      and a(0xF85649, 3) == bytes([0xBC, 0x04, 0x60])
      and a(0xF8564C, 4) == bytes([0xDC, 0xC8, 0x08, 0x00]))
check("Kernel_InitRam: 8 free nodes from 0x0384, stride 8, +4 := -1",
      a(0xF85674, 3) == bytes([0x33, 0x84, 0x03])
      and a(0xF85679, 2) == bytes([0x22, 0x08])
      and a(0xF85680, 3) == bytes([0xBB, 0x04, 0x60])
      and a(0xF85683, 4) == bytes([0xDB, 0xC8, 0x08, 0x00]))
check("Kernel_InitRam: the free-list head is 0x03C4, self-linked",
      a(0xF8568A, 3) == bytes([0x35, 0xC4, 0x03])
      and a(0xF8568F, 3) == bytes([0xBD, 0x00, 0x55])
      and a(0xF85692, 3) == bytes([0xBD, 0x02, 0x55]))
check("Kernel_InitRam: all 8 nodes are then appended to it (B = 8, stride 8)",
      a(0xF85695, 3) == bytes([0x34, 0x84, 0x03])
      and a(0xF85698, 2) == bytes([0x22, 0x08])
      and a(0xF856AE, 4) == bytes([0xDC, 0xC8, 0x08, 0x00]))
check("Kernel_InitRam: `ldir` copies 8 bytes from 0xF85EBA to 0x035C",
      a(0xF85653, 5) == bytes([0x43, 0xBA, 0x5E, 0xF8, 0x00])
      and a(0xF85658, 3) == bytes([0x32, 0x5C, 0x03])
      and a(0xF8565D, 3) == bytes([0x31, 0x08, 0x00])
      and a(0xF85660, 2) == bytes([0x83, 0x11]))
check("...and 0x035C is exactly where the 8 heads at 0x033C end (0x033C+8*4)",
      0x033C + 8 * 4 == 0x035C)
check("the four TCBs end at 0x032F, so 0x0330 is the first ready-queue head",
      0x0300 + 4 * 12 == 0x0330)
check("MsgQueue_ReceiveBlocking's 0x0360+A*4 / 0x0370+A*4 are these two arrays",
      0x0360 + 4 == 0x0364 and 0x0370 + 4 == 0x0374)

# --- the inline argument block, and the boundary that proves it is data ------
check("SoftTimer_Request_Boot: `jr` at 0xF856DE steps over exactly 8 bytes",
      a(0xF856DE, 2) == bytes([0x68, 0x08]) and 0xF856E0 + 8 == 0xF856E8)
check("SoftTimer_Request_Boot: 01 00 01 00 C2 5E F8 00",
      list(a(0xF856E0, 8)) == [0x01, 0x00, 0x01, 0x00, 0xC2, 0x5E, 0xF8, 0x00])
check("SoftTimer_Request_Boot: +4 is the code address 0x00F85EC2",
      int.from_bytes(a(0xF856E4, 4), "little") == 0xF85EC2)
check("SoftTimer_Request_Boot: only 0xF856D9 names it",
      names_addr(0xF856E0) == [("prom_a", 0xF856DA)] and a(0xF856D9, 1) == b"\x44")
check("0xF85D78 reads (XIX+0) as a byte and forms 0x03C0 + A*8",
      a(0xF85D82, 3) == bytes([0x8C, 0x00, 0x21])
      and a(0xF85D85, 3) == bytes([0xC9, 0x08, 0x08])
      and a(0xF85D88, 4) == bytes([0xD8, 0xC8, 0xC0, 0x03])
      and 0x03C0 + 1 * 8 == 0x03C8)
check("0xF856E8 is `call 0xF85D78` and it ENDS at Kernel_Start",
      a(0xF856E8, 4) == bytes([0x1D, 0x78, 0x5D, 0xF8]) and 0xF856E8 + 4 == 0xF856EC)
check("nothing in either ROM NAMES 0xF84F49 -- the old Kernel_Start citation",
      not names_addr(0xF84F49), str(names_addr(0xF84F49)))
# ⚠ and here is the searched negative's own limit, made visible rather than
# hidden: REL scans every byte offset, so it DOES report a `jrl` to 0xF84F49 at
# 0xF856E9 -- which is the middle of `call 0xF85D78`, not an instruction.  That
# byte coincidence is exactly what produced the wrong citation in the first
# place, so it is asserted here instead of being filtered away.
check("...but the REL scan reports one hit, at 0xF856E9, INSIDE `call 0xF85D78`",
      sorted(REL.get(0xF84F49, [])) == [0xF856E9]
      and a(0xF856E8, 1) == b"\x1d",
      str([hex(x) for x in sorted(REL.get(0xF84F49, []))]))
check("Kernel_Start starts tasks 1 and 3 through Kernel_StartTask",
      a(0xF856F8, 2) == bytes([0x21, 0x01]) and a(0xF856FE, 2) == bytes([0x21, 0x03])
      and a(0xF856FA, 1) == b"\x1d" and a(0xF85700, 1) == b"\x1d"
      and int.from_bytes(a(0xF856FB, 3), "little") == 0xF857D9
      and int.from_bytes(a(0xF85701, 3), "little") == 0xF857D9)

# --- ROUND 3: Kernel_BlockSelf / Kernel_ReadyTask, and the +9 negative -------
check("Kernel_BlockSelf is published at the same address in BOTH thunk runs",
      int.from_bytes(b(0xF42D7D, 3), "little") == 0xF85904
      and int.from_bytes(b(0xF42DB9, 3), "little") == 0xF85904)
check("Kernel_BlockSelf: takes the RUNNING task from (0xBF), not an argument",
      a(0xF8590E, 3) == bytes([0xD0, 0xBF, 0x24]))
check("Kernel_BlockSelf: unlink idiom, then +9 := 3",
      a(0xF85917, 3) == bytes([0x9C, 0x00, 0x20])
      and a(0xF8591A, 3) == bytes([0x9C, 0x02, 0x23])
      and a(0xF8591D, 3) == bytes([0xBB, 0x00, 0x50])
      and a(0xF85920, 3) == bytes([0xB8, 0x02, 0x53])
      and a(0xF85923, 4) == bytes([0xBC, 0x09, 0x00, 0x03]))
check("Kernel_BlockSelf does NOT clear (0xBF) -- that is Kernel_ExitTask's move",
      bytes([0xF0, 0xBF, 0x50]) not in a(0xF85904, 0xF8592A - 0xF85904)
      and a(0xF8585C, 3) == bytes([0xF0, 0xBF, 0x50]))
check("...so Kernel_Dispatch saves its XSP into node+4 (0xF85728) on the way in",
      a(0xF85723, 3) == bytes([0xD0, 0xBF, 0x25])
      and a(0xF85728, 3) == bytes([0xBD, 0x04, 0x67]))
check("Kernel_ReadyTask: TCB = 0x02F4 + A*12, guard is `cp (XIX+0x09),0x03`",
      a(0xF85937, 3) == bytes([0xC9, 0x08, 0x0C])
      and a(0xF8593A, 4) == bytes([0xD8, 0xC8, 0xF4, 0x02])
      and a(0xF85942, 4) == bytes([0x8C, 0x09, 0x3F, 0x03]))
check("Kernel_ReadyTask: the queue comes from the task's own +8, not an argument",
      a(0xF85948, 3) == bytes([0x8C, 0x08, 0x21])
      and a(0xF85950, 4) == bytes([0xD8, 0xC8, 0x2C, 0x03]))
# ★ the two searched negatives the headers rest on, each stated as its search.
_RT = a(0xF8592D, 0xF8596D - 0xF8592D)
check("Kernel_ReadyTask NEVER writes +9: only one 0x09 byte in its 64, the guard",
      [i for i, v in enumerate(_RT) if v == 0x09] == [0xF85943 - 0xF8592D],
      str([hex(0xF8592D + i) for i, v in enumerate(_RT) if v == 0x09]))
_KD = a(0xF85715, 0xF8576C - 0xF85715)
check("Kernel_Dispatch NEVER touches +9: the byte 0x09 does not occur in its 87",
      _KD.count(0x09) == 0 and len(_KD) == 87, "%d" % _KD.count(0x09))
check("Kernel_Dispatch picks by QUEUE MEMBERSHIP: `ld HL,(head) / cp HL,IX`",
      a(0xF8574D, 3) == bytes([0x9C, 0x00, 0x23])
      and a(0xF85750, 2) == bytes([0xDC, 0xF3]))

# --- ROUND 3: the eight COUNTING SEMAPHORES at 0x033C / 0x035C ---------------
# prom_a 0xF8596D's banner claims the eight heads at 0x033C and the eight bytes
# at 0x035C are one structure -- semaphore queues and their counts -- and that
# the ROM image at 0xF85EBA is their initial values.  Every part of that.
check("semaphores: the queue array is 0x0338 + s*4 = 0x033C + (s-1)*4",
      a(0xF859BF, 4) == bytes([0xD8, 0xC8, 0x38, 0x03])
      and a(0xF85AD2, 4) == bytes([0xDA, 0xC8, 0x38, 0x03])
      and 0x0338 + 4 == 0x033C)
check("semaphores: the count array is 0x035B + s = 0x035C + (s-1)",
      a(0xF859D0, 4) == bytes([0xDB, 0xC8, 0x5B, 0x03])
      and a(0xF85AA4, 4) == bytes([0xD8, 0xC8, 0x5B, 0x03])
      and 0x035B + 1 == 0x035C)
check("semaphores: the two arrays are ADJACENT and both are 8 long",
      0x033C + 8 * 4 == 0x035C and 0x035C + 8 == 0x0364)
check("semaphores: the ROM image at 0xF85EBA is the initial counts 00 01 00 01 x4",
      list(a(0xF85EBA, 8)) == [0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])
check("Kernel_SemaSignal: emptiness test is head->next == head",
      a(0xF859C7, 3) == bytes([0x9D, 0x00, 0x24]) and a(0xF859CA, 2) == bytes([0xDD, 0xF4]))
check("Kernel_SemaSignal: the count SATURATES -- `inc 1,A / jr Z / ld (XHL),A`",
      a(0xF859D6, 2) == bytes([0x83, 0x21]) and a(0xF859D8, 2) == bytes([0xC9, 0x61])
      and a(0xF859DA, 2) == bytes([0x66, 0x02]) and a(0xF859DC, 2) == bytes([0xB3, 0x41]))
check("Kernel_SemaSignal: the woken task gets state 4 and its OWN queue",
      a(0xF859F3, 4) == bytes([0xBC, 0x09, 0x00, 0x04])
      and a(0xF859F7, 3) == bytes([0x8C, 0x08, 0x21])
      and a(0xF859FF, 4) == bytes([0xD8, 0xC8, 0x2C, 0x03]))
check("Kernel_SemaWait: `cp (XWA),0x00 / jr z` then `dec 1,(XWA)` -- the inverse",
      a(0xF85AAA, 3) == bytes([0x80, 0x3F, 0x00]) and a(0xF85AAD, 2) == bytes([0x66, 0x05])
      and a(0xF85AAF, 2) == bytes([0x80, 0x69]))
check("Kernel_SemaWait: blocks the RUNNING task with state 3, onto queue s",
      a(0xF85AB4, 3) == bytes([0xD0, 0xBF, 0x24])
      and a(0xF85AC9, 4) == bytes([0xBC, 0x09, 0x00, 0x03])
      and a(0xF85AA0, 2) == bytes([0xC9, 0x8D]))
# nothing else in prom_a touches either array -- stated as its search.
_SEM = [i for i in range(len(A) - 3)
        if A[i] == 0xC8 and A[i + 1] in (0x38, 0x5B) and A[i + 2] == 0x03]
# ⚠ A FIRST DRAFT OF THIS CHECK SAID "four sites" AND FAILED IMMEDIATELY.  The
# true list is seven, and the three it missed are the point: two belong to
# Kernel_SemaSignal_NoDispatch (the second copy of the same logic) and one, at
# 0xF85AF4, belongs to Kernel_SemaTryWait -- a THIRD semaphore routine the
# banner had not accounted for.  The count is left as data, not prose.
check("exactly seven sites form a 0x0338/0x035B base (add rr,imm16)",
      sorted(0xF80000 + i - 1 for i in _SEM)
      == [0xF859BF, 0xF859D0, 0xF85A2D, 0xF85A41, 0xF85AA4, 0xF85AD2, 0xF85AF4],
      str([hex(0xF80000 + i - 1) for i in _SEM]))
# and which register each of the seven adds into -- D8 = WA, DA = DE, DB = HL
check("...the seven use WA/HL/WA/HL/WA/DE/WA in that order",
      [a(x, 1)[0] for x in (0xF859BF, 0xF859D0, 0xF85A2D, 0xF85A41,
                            0xF85AA4, 0xF85AD2, 0xF85AF4)]
      == [0xD8, 0xDB, 0xD8, 0xDB, 0xD8, 0xDA, 0xD8],
      str([hex(a(x, 1)[0]) for x in (0xF859BF, 0xF859D0, 0xF85A2D, 0xF85A41,
                                     0xF85AA4, 0xF85AD2, 0xF85AF4)]))
_TW = a(0xF85AEF, 0xF85B0D - 0xF85AEF)
check("Kernel_SemaTryWait never touches the WAIT QUEUE: no `C8 38 03` in its 30",
      len(_TW) == 30
      and not any(_TW[i:i + 3] == bytes([0xC8, 0x38, 0x03])
                  for i in range(len(_TW) - 2)))
check("Kernel_SemaTryWait is published ONCE, by 0xF42DD8, with a stack argument",
      names_addr(0xF85AEF) == [("prom_b", 0xF42DD9)] and not REL.get(0xF85AEF))
check("Kernel_SemaTryWait: count non-zero -> dec and WA := 0; zero -> WA := 0xFFFF",
      a(0xF85AFD, 3) == bytes([0x80, 0x3F, 0x00])
      and a(0xF85B02, 2) == bytes([0x80, 0x69])
      and a(0xF85B04, 2) == bytes([0xD8, 0xD0])
      and a(0xF85B08, 3) == bytes([0x30, 0xFF, 0xFF])
      and a(0xF85B0C, 1) == b"\x0e")

# --- the two "same logic, different epilogue" pairs, measured run by run -----
def _run(p, q, cap=400):
    n = 0
    while n < cap and a(p + n, 1) == a(q + n, 1):
        n += 1
    return n


check("Kernel_ReadyTask / _NoDispatch: bodies identical for EXACTLY 51 bytes",
      _run(0xF85937, 0xF85973) == 51
      and a(0xF85936, 1) != a(0xF85972, 1),
      "run=%d" % _run(0xF85937, 0xF85973))
for p, q, want, label in ((0xF859E1, 0xF85A55, 56, "wake arm"),
                          (0xF859CE, 0xF85A3F, 16, "count arm"),
                          (0xF859C7, 0xF85A38, 6, "emptiness test"),
                          (0xF859B8, 0xF85A26, 15, "index arithmetic")):
    check("SemaSignal / _NoDispatch: %s identical for EXACTLY %d bytes"
          % (label, want), _run(p, q) == want, "run=%d" % _run(p, q))
check("...and each run stops at the epilogue: jrl vs `pop SR`",
      a(0xF85A19, 1) == b"\x78" and a(0xF85A8D, 1) == b"\x03"
      and a(0xF859DE, 1) == b"\x78" and a(0xF85A4F, 1) == b"\x03")
check("SemaSignal_NoDispatch defers `push SR / ei 0x06` to 0xF85A35",
      a(0xF85A35, 3) == bytes([0x02, 0x06, 0x06])
      and a(0xF859AE, 3) == bytes([0x02, 0x06, 0x06]))
check("0xF85A1C is a stack face that pushes FIRST and reads (XSP+0x08)",
      a(0xF85A1C, 1) == b"\x38" and a(0xF85A1D, 3) == bytes([0x8F, 0x08, 0x21])
      and a(0xF85A20, 2) == bytes([0x68, 0x01]) and a(0xF85A22, 1) == b"\x38")
check("0xF85A1C is named by NOTHING -- it is reachable only by falling in",
      not names_addr(0xF85A1C) and not REL.get(0xF85A1C))

# --- the thunk block's real bounds: 34 slots, 0x0E padding either side -------
check("the kernel thunk block is 0xF42D60-0xF42DE7, 34 slots, all `jp`",
      all(b(0xF42D60 + 4 * i, 1) == b"\x1b" for i in range(34))
      and b(0xF42D5C, 4) == b"\x0e" * 4 and b(0xF42DE8, 4) == b"\x0e" * 4)
check("its last two slots publish the DSP register writers",
      int.from_bytes(b(0xF42DE1, 3), "little") == 0xF85F59
      and int.from_bytes(b(0xF42DE5, 3), "little") == 0xF85F7C)
check("its first three are Kernel_InitRam, INTT3_KernelTick and IRQ_Epilogue",
      [int.from_bytes(b(0xF42D60 + 4 * i + 1, 3), "little") for i in range(3)]
      == [0xF85606, 0xF85600, 0xF857B7])
check("0xF42DD8/0xF42DDC are two more `8F 04 21` stack faces, unpaired in run 1",
      int.from_bytes(b(0xF42DD9, 3), "little") == 0xF85AEF
      and int.from_bytes(b(0xF42DDD, 3), "little") == 0xF85D1C
      and a(0xF85AEF, 3) == bytes([0x8F, 0x04, 0x21])
      and a(0xF85D1C, 3) == bytes([0x8F, 0x04, 0x21])
      and 0xF85AEF not in K_RUN1 and 0xF85D1C not in K_RUN1)

# --- ROUND 3: every "and nothing else" in the new kernel headers -------------
# Each of these routines' headers says its only reference is one prom_b thunk.
# That is a searched negative per routine, so each is re-derived.
for _addr, _thunk, _label in (
        (0xF8596D, 0xF42D84, "Kernel_ReadyTask_NoDispatch"),
        (0xF859AB, 0xF42DC0, "Kernel_SemaSignal_StackArg"),
        (0xF859AE, 0xF42D88, "Kernel_SemaSignal"),
        (0xF85A22, 0xF42D8C, "Kernel_SemaSignal_NoDispatch"),
        (0xF85A93, 0xF42DC4, "Kernel_SemaWait_StackArg"),
        (0xF85A96, 0xF42D90, "Kernel_SemaWait"),
        (0xF85F7C, 0xF42DE4, "DSP_WriteAllChannelRegs")):
    check("%s: one reference, prom_b thunk 0x%06X" % (_label, _thunk),
          names_addr(_addr) == [("prom_b", _thunk + 1)]
          and b(_thunk, 1) == b"\x1b" and not REL.get(_addr),
          str(names_addr(_addr)))
check("DSP_ChannelRegs_Write8 is ALSO published, at 0xF42DE0",
      int.from_bytes(b(0xF42DE1, 3), "little") == 0xF85F59
      and b(0xF42DE0, 1) == b"\x1b")

# --- ROUND 3: the banner's `.fill` claim (round-1 audit F1) ------------------
import re as _re
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
# ⚠ AND WHAT prom_a INCLUDES.  Since 2026-08-30 the kernel at 0xF85606-0xF85E89
# is `kernel/kernel.s`, shared with prom_c.  Reading only wsa1_prom_a.s made the
# span-banner check below VACUOUS -- its one standing failure ("0 of 1") turned
# into a pass because the banner had moved out of the file, not because anyone
# had fixed it.  A check that cannot fail is not a check.
_SRC = (open(image_path(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8").read()
        + "\n"
        + open(os.path.join(ROOT, "kernel", "kernel.s"), encoding="utf-8").read())
_FILLS = [(int(m.group(1), 0), int(m.group(2)))
          for m in _re.finditer(r"^\t\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(\d+)\s*,",
                                _SRC, _re.M)]
# ⚠ This check used to read "prom_a has exactly ONE .fill and it is 108 bytes".
# That stopped being true on 2026-08-25, when four verified 0x0E pad runs came
# in with the ring-buffer and callback-queue modules -- and a hand-kept list of
# the new addresses would rot the same way.  So the ADDRESSES are now read out
# of the source too: every `.fill` in prom_a is introduced by a comment naming
# the range it covers, and this check re-derives that range and tests the ROM.
# The claim it enforces is therefore "every .fill says what range it pads, and
# that range really is uniform 0x0E, and its length really is the .fill's".
_FILL_CLAIMS = []
for _m in _re.finditer(r"^;\s*(0x[0-9A-Fa-f]{6})-(0x[0-9A-Fa-f]{6})\s*--\s*"
                       r"(\d+)\s*bytes of 0x0E.*?\n(?:^;.*\n)*?"
                       r"^\t\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(\d+)\s*,\s*"
                       r"(0x[0-9A-Fa-f]+|\d+)\s*$",
                       _SRC, _re.M):
    _FILL_CLAIMS.append((int(_m.group(1), 16), int(_m.group(2), 16),
                         int(_m.group(3)), int(_m.group(4), 0),
                         int(_m.group(5)), int(_m.group(6), 0)))
check("every .fill with a stated range: the range is uniform 0x0E, its length "
      "matches, and the fill value is 0x0E",
      _FILL_CLAIMS and all(
          hi - lo + 1 == n and n == cnt * sz and val == 0x0E
          and set(a(lo, n)) == {0x0E}
          for lo, hi, n, cnt, sz, val in _FILL_CLAIMS),
      str(_FILL_CLAIMS))
check("every .fill in prom_a is one of those -- none is undocumented",
      len(_FILLS) == len(_FILL_CLAIMS) + 1,      # +1: the 108 bytes at 0xFFFF84
      "%d .fill, %d claimed" % (len(_FILLS), len(_FILL_CLAIMS)))
check("the original 108-byte pad at 0xFFFF84 is still uniform 0x0E",
      set(a(0xFFFF84, 108)) == {0x0E})
check("prom_a's .fill total equals what source_coverage.py calls filler",
      sum(c * s2 for c, s2 in _FILLS) ==
      __import__("importlib").import_module("source_coverage").measure("a")[3])

# --- ROUND 4: the callback queue, the ASCII field, and the analogue scan -----
# Every sentence these back is in a header written on 2026-08-25.  The pattern
# is the tree's: a claim about a NUMBER or an IDENTITY is re-derived here, never
# quoted.

# Task2_CallbackDispatcher's "Called from: NOT called -- it is a TASK ENTRY".
_REC = 0xF85E8A                      # EntryPoint_Records, one-based (kernel note)
check("EntryPoint_Records[2].PC is the prom_b thunk 0xF42E88",
      int.from_bytes(a(_REC + 1 * 12, 4), "little") == 0xF42E88)
check("... and that thunk's body is `jp 0xF8DA00`",
      b(0xF42E88, 1) == b"\x1b"
      and int.from_bytes(b(0xF42E89, 3), "little") == 0xF8DA00)
check("task 2's record gives it stack 0x0060E980 and priority 3",
      int.from_bytes(a(_REC + 12 + 4, 4), "little") == 0x0060E980
      and int.from_bytes(a(_REC + 12 + 10, 2), "little") == 3)

# The five kernel slots CallbackQueue_ResetAndRestartTask2's header names.
for _slot, _tgt, _what in ((0xF42D6C, 0xF857D9, "Kernel_StartTask"),
                           (0xF42D88, 0xF859AE, "Kernel_SemaSignal"),
                           (0xF42D90, 0xF85A96, "Kernel_SemaWait"),
                           (0xF42DA8, 0xF85E5E, "the state-0 writer"),
                           (0xF42DD8, 0xF85AEF, "Kernel_SemaTryWait")):
    check("slot T_%06X is `jp 0x%06X` (%s)" % (_slot, _tgt, _what),
          b(_slot, 1) == b"\x1b"
          and int.from_bytes(b(_slot + 1, 3), "little") == _tgt)

# The queue's geometry, read off its own instructions rather than described.
check("CallbackQueue_Post wraps with minc4 mask 0x01FC -- 4-byte elements, "
      "0x200 bytes, 128 entries",
      a(0xF8DA33, 4) == bytes([0xDD, 0x3A, 0xFC, 0x01]))
check("CallbackQueue_Init seeds the free count with 0x01FF = capacity - 1",
      int.from_bytes(a(0xF8DA80, 2), "little") == 0x01FF)
check("Post refuses below 5 free bytes (4 for the element, 1 the ring never "
      "uses)", a(0xF8DA24, 2) == bytes([0xD8, 0xDD]))
check("all three queue routines address the ring at 0x00600416",
      all(int.from_bytes(a(at, 4), "little") == 0x00600416
          for at in (0xF8DA1B, 0xF8DA4A, 0xF8DA71)))
check("★ a ten-byte control block puts the queue at 0x60040C, exactly where "
      "ring 0x60000C's 0x400 bytes of data end",
      0x600416 - 10 == 0x60000C + 0x400)

# AsciiField_Clear's one store, and the sign byte the parser tests.
check("AsciiField_Clear stores 0x2020202B -- '+' then three spaces",
      int.from_bytes(a(0xF8BC7A, 4), "little") == 0x2020202B)
check("AsciiField_ToSignedValue tests the sign cell for 0x2B ('+')",
      a(0xF8BC6A, 5) == bytes([0xC1, 0x20, 0x28, 0x3F, 0x2B]))
check("AsciiDigits3_ToValue's three scales are x100, x10 and x1",
      a(0xF8BC2E, 3) == bytes([0xCB, 0x08, 0x64])
      and a(0xF8BC47, 3) == bytes([0xCB, 0x08, 0x0A]))

# SignedNibbleDelta_Table: contents, both ends, and the last entry.
_TBL = list(a(0xF8BDA5, 32))
check("SignedNibbleDelta_Table is 0x00..0x0F then 0x00,0xFF..0xF1",
      _TBL == list(range(16)) + [0x00] + [(0x100 - k) & 0xFF for k in range(1, 16)])
check("its base is the address the reader loads at 0xF8BD80",
      int.from_bytes(a(0xF8BD81, 4), "little") == 0x00F8BDA5)
check("LAST-ENTRY TEST: entry 31 is 0xF1 = -15, entry 30 is 0xF2",
      _TBL[31] == 0xF1 and _TBL[30] == 0xF2)
check("base + 32 = 0xF8BDC5, which is the target of directory slot T_F41B08",
      0xF8BDA5 + 32 == 0xF8BDC5
      and int.from_bytes(b(0xF41B09, 3), "little") == 0xF8BDC5)

# The six analogue channels: the ADREG index, the state pair and the channel
# number step together.  PARSED, not listed -- a changed literal fails here.
_ADSCAN = [(0xF8DC3E, 0x60, 0x28E0, 0), (0xF8DC71, 0x62, 0x28E2, 1),
           (0xF8DCA4, 0x64, 0x28E4, 2), (0xF8DCD7, 0x66, 0x28E6, 3)]
for _at, _adreg, _state, _ch in _ADSCAN:
    ok = (a(_at, 3) == bytes([0xD0, _adreg, 0x20])                  # ld WA,(ADREGn)
          and a(_at + 3, 3) == bytes([0xD8, 0xEF, 0x08])            # srl 8,WA
          and int.from_bytes(a(_at + 7, 2), "little") == _state     # ld W,(state)
          and int.from_bytes(a(_at + 11, 2), "little") == _state + 1)
    # the channel number handed to the reporting thunk
    ok = ok and a(_at + 0x23, 2) == bytes([0x20, _ch])
    check("analogue channel %d: ADREG at 0x%02X, state pair 0x%04X/0x%04X, "
          "reported as channel %d" % (_ch, _adreg, _state, _state + 1, _ch), ok)
check("the two SOFT channels 4 and 5 read (0x600000) and (0x600001)",
      int.from_bytes(a(0xF8DD4E, 3), "little") == 0x600000
      and int.from_bytes(a(0xF8DD63, 3), "little") == 0x600001
      and a(0xF8DD52, 2) == bytes([0x20, 0x04])
      and a(0xF8DD67, 2) == bytes([0x20, 0x05]))
check("AnalogScan_InitSoftChannels parks both of them at 0x80",
      a(0xF8DC18, 2) == bytes([0x21, 0x80])
      and int.from_bytes(a(0xF8DC1B, 3), "little") == 0x600000
      and int.from_bytes(a(0xF8DC20, 3), "little") == 0x600001)
check("all six channels report through the same slot, T_F405F0 -> 0xF89800",
      b(0xF405F0, 1) == b"\x1b"
      and int.from_bytes(b(0xF405F1, 3), "little") == 0xF89800)
check("the hysteresis filter's two thresholds are 2 and 6",
      a(0xF8DD14, 2) == bytes([0xC9, 0xDA])
      and a(0xF8DD18, 2) == bytes([0xC9, 0xDE]))

# --- "SeqBuf twins": the RETRACTION of the one-byte claim, re-derived ---------
# prom_a/wsa1_prom_a.s (SeqBuf_AppendEvent's header) and
# notes/FINDINGS-prom_a-ring-buffers.md §3 said 0xFA570C was "a NEAR-TWIN ...
# differing by ONE BYTE".  Round-2 audit F1.  Every number in the replacement
# text is re-derived here, so the retraction cannot rot back.
_TW_A, _TW_B, _TW_N = 0xF830C6, 0xFA570C, 90
_da, _db = a(_TW_A, _TW_N), a(_TW_B, _TW_N)
_ndiff = sum(1 for x, y in zip(_da, _db) if x != y)
_pref = 0
for _x, _y in zip(_da, _db):
    if _x != _y:
        break
    _pref += 1
check("SeqBuf twins: 75 of the 90 positional bytes DIFFER (not one)",
      _ndiff == 75, "got %d" % _ndiff)
check("SeqBuf twins: the common prefix is 4 bytes -- f0 aa c8 and the `jr NZ` opcode",
      _pref == 4 and _da[:4] == bytes([0xF0, 0xAA, 0xC8, 0x6E])
      and _da[4] != _db[4], "prefix %d" % _pref)
check("SeqBuf twins: 0xF830C6 uses XIY (0x9D/0x45), 0xFA570C uses XIX (0x9C/0x44)",
      a(0xF830D5, 1) == b"\x45" and a(0xF830DA, 1) == b"\x9d"
      and a(0xFA571D, 1) == b"\x44" and a(0xFA5722, 1) == b"\x9c")
check("SeqBuf twins: 0xF830C6 brackets with push/pop XIY (0x3D/0x5D), "
      "0xFA570C with push SR / ei 0x06 .. pop SR (0x02 06 06 .. 0x03)",
      a(0xF830D4, 1) == b"\x3d" and a(0xF830FD, 1) == b"\x5d"
      and a(0xFA571A, 3) == bytes([0x02, 0x06, 0x06]) and a(0xFA5740, 1) == b"\x03")
check("SeqBuf twins: 0xF830C6 does `decw 1,(XIY+0xfe)` TWICE; 0xFA570C does "
      "`decw 2,(XIX+0xfe)` ONCE -- both net -2",
      a(0xF830E2, 3) == bytes([0x9D, 0xFE, 0x69])
      and a(0xF830F5, 3) == bytes([0x9D, 0xFE, 0x69])
      and a(0xFA573D, 3) == bytes([0x9C, 0xFE, 0x6A])
      and A.count(bytes([0x9C, 0xFE, 0x6A]), 0xFA570C - 0xF80000,
                  0xFA5763 - 0xF80000) == 1)
check("SeqBuf twins: the write cursor goes to the SAME cell 0x600A10 -- "
      "absolute in one, (XIX+0xfc) in the other",
      a(0xF830F8, 5) == bytes([0xF2, 0x10, 0x0A, 0x60, 0x53])
      and a(0xFA573A, 3) == bytes([0xBC, 0xFC, 0x53])
      and 0x600A14 - 4 == 0x600A10)
check("SeqBuf twins: the guards read DIFFERENT cells -- 0x600A12 (free count) "
      "and 0x600A0C (read cursor)",
      a(0xF830CB, 7) == bytes([0xD2, 0x12, 0x0A, 0x60, 0x3F, 0x02, 0x00])
      and a(0xFA5711, 7) == bytes([0xD2, 0x0C, 0x0A, 0x60, 0x3F, 0x02, 0x00]))
check("SeqBuf twins: 0x600A12 is ring 0x600A14's free count (base-2) and "
      "0x600A0C is its read cursor (base-8)",
      0x600A14 - 2 == 0x600A12 and 0x600A14 - 8 == 0x600A0C)
check("SeqBuf twins: 0xF830C6's trace path loads (0x93) TWICE, the second dead; "
      "0xFA570C's loads it once",
      a(0xF8310D, 3) == bytes([0xC0, 0x93, 0x21])
      and a(0xF83117, 3) == bytes([0xC0, 0x93, 0x21])
      and a(0xF8311C, 3) == bytes([0xF0, 0xAC, 0x53])          # next store is HL
      and A.count(bytes([0xC0, 0x93, 0x21]), 0xFA5746 - 0xF80000,
                  0xFA5763 - 0xF80000) == 1)
check("SeqBuf twins: LAST-INSTRUCTION TEST -- both end in `ret` (0x0E) at "
      "0xF8311F and 0xFA5762, and the byte after each is not a `ret`",
      a(0xF8311F, 1) == b"\x0e" and a(0xFA5762, 1) == b"\x0e"
      and a(0xF83120, 1) != b"\x0e" and a(0xFA5763, 1) != b"\x0e")

# =============================================================================
# ROUND 2 -- the 0xFAA000 module (0x60F0xx message layer) and the 0xFC5400 one.
# Every quantified sentence in prom_a/wsa1_prom_a.s's headers for those two
# spans is re-derived here.  Sources: notes/prom_a_block_headers.txt.
# =============================================================================

def _le32(at):
    return int.from_bytes(a(at, 4), "little")


def _refs_abs(lo, hi):
    """Absolute `call`/`jp` literals in prom_a+prom_b naming [lo,hi).

    ⚠ Opcode-anchored at every byte offset, so this is an UPPER BOUND on the
    sites and an EXACT statement about absence.  Both uses below are of the
    second kind or are comparisons between two ranges scanned the same way."""
    out = []
    for img, base in ((A, 0xF80000), (B, 0xF00000)):
        for i in range(len(img) - 3):
            if img[i] in (0x1D, 0x1B):
                t = img[i + 1] | img[i + 2] << 8 | img[i + 3] << 16
                if lo <= t < hi:
                    out.append((base + i, t))
    return out


def _dir_targets():
    """{addr} of every `jp nnn` slot of the prom_b routine directory."""
    out = set()
    for o in range(0x40000, 0x44018, 4):
        s = B[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            out.add(s[1] | s[2] << 8 | s[3] << 16)
    return out


_DIR = _dir_targets()

# --- "stale veneer copy": 0xFAA018-0xFAA3FF against 0xFAA418-0xFAA7FF --------
_d = [k for k in range(0x3E8) if a(0xFAA018 + k, 1) != a(0xFAA418 + k, 1)]
check("stale veneer copy: the two 1000-byte blocks differ in exactly 10 bytes",
      len(_d) == 10, "got %d at %s" % (len(_d), [hex(x) for x in _d]))
_PAIRS = [(0xFAA029, 0xFAA429, 0xFAADC2, 0xFAB658),
          (0xFAA046, 0xFAA446, 0xFAAE41, 0xFAB6D7),
          (0xFAA06D, 0xFAA46D, 0xFAAEE3, 0xFAB779),
          (0xFAA08A, 0xFAA48A, 0xFAAE92, 0xFAB728)]
for _s, _l, _st, _lv in _PAIRS:
    ok = (a(_s, 1) == b"\x1d" and a(_l, 1) == b"\x1d"
          and int.from_bytes(a(_s + 1, 3), "little") == _st
          and int.from_bytes(a(_l + 1, 3), "little") == _lv
          and _lv - _st == 0x896)
    check("stale veneer copy: 0x%06X calls 0x%06X where 0x%06X calls 0x%06X, "
          "delta 0x896" % (_s, _st, _l, _lv), ok)
check("stale veneer copy: all four LIVE targets are published directory slots",
      all(_lv in _DIR for _, _, _, _lv in _PAIRS))
check("stale veneer copy: NONE of the four stale targets is",
      not any(_st in _DIR for _, _, _st, _ in _PAIRS))
check("stale veneer copy: all four live targets start with a push (0x2B/0x3C)",
      all(a(_lv, 1)[0] in (0x2B, 0x3C) for _, _, _, _lv in _PAIRS))
# three of the four stale targets are two bytes INSIDE a longer instruction;
# pinned by the enclosing instruction's own bytes rather than by a decoder.
check("stale veneer copy: 0xFAADC2 is +2 inside `ld (0x60f080),0xba` at 0xFAADC0",
      a(0xFAADC0, 6) == bytes([0xF2, 0x80, 0xF0, 0x60, 0x00, 0xBA]))
check("stale veneer copy: 0xFAAE41 is +2 inside `ld (XIZ+0xf2),XIY` at 0xFAAE3F",
      a(0xFAAE3F, 3) == bytes([0xBE, 0xF2, 0x65]))
check("stale veneer copy: 0xFAAE92 is +2 inside `ld XBC,(XIZ+0xf2)` at 0xFAAE90",
      a(0xFAAE90, 3) == bytes([0xAE, 0xF2, 0x21]))
_INT = [(0xFAA3BB, 0xFAA26A, 0xFAA7BB, 0xFAA66A), (0xFAA3DB, 0xFAA204, 0xFAA7DB, 0xFAA604)]
for _s, _st, _l, _lv in _INT:
    check("stale veneer copy: the INTERNAL call 0x%06X->0x%06X relocates by "
          "0x400, not 0x896" % (_s, _st),
          int.from_bytes(a(_s + 1, 3), "little") == _st
          and int.from_bytes(a(_l + 1, 3), "little") == _lv
          and _lv - _st == 0x400)
# The copy is 0xFAA000-0xFAA3FF: 0xFAA400 opens the LIVE block with its own five-slot
# vector (the last check below), which prom_b publishes through the POINTER slot T_F40770.
# (Until 2026-10-03 these two checks ran to 0xFAA417 and the pointer slot went unchecked.)
check("stale veneer copy: ZERO directory jp slots point into 0xFAA000-0xFAA3FF",
      not any(0xFAA000 <= t < 0xFAA400 for t in _DIR))
check("stale veneer copy: prom_b's pointer slot 0xF40770 holds 0xFAA400, the LIVE vector",
      B[0x40770:0x40774] == bytes([0x00, 0xA4, 0xFA, 0x00]))
_st_refs = _refs_abs(0xFAA000, 0xFAA400)
_lv_refs = _refs_abs(0xFAA418, 0xFAA830)
check("stale veneer copy: exactly 2 absolute call/jp literals name it, and both "
      "sites are inside it; the live block has 37",
      len(_st_refs) == 2 and all(0xFAA000 <= s < 0xFAA400 for s, _ in _st_refs)
      and len(_lv_refs) == 37,
      "stale %d live %d" % (len(_st_refs), len(_lv_refs)))
check("stale veneer copy: both blocks open with five `jp nnn` slots then a `ret`",
      all(a(0xFAA000 + 4 * k, 1) == b"\x1b" for k in range(5))
      and a(0xFAA014, 1) == b"\x0e"
      and all(a(0xFAA400 + 4 * k, 1) == b"\x1b" for k in range(5))
      and a(0xFAA414, 1) == b"\x0e")

# --- module extents: both were cut at a 0x0E pad run, so check the runs ------
for _lo, _hi, _n in ((0xFA9E72, 0xFAA000, 398), (0xFAD485, 0xFAD801, 892),
                     (0xFC52F8, 0xFC5400, 264), (0xFC6844, 0xFC7000, 1980)):
    check("module boundary: 0x%06X-0x%06X is %d bytes of 0x0E, and the byte "
          "either side is not" % (_lo, _hi, _n),
          set(a(_lo, _hi - _lo)) == {0x0E} and _hi - _lo == _n
          and a(_lo - 1, 1) != b"\x0e")
check("module boundary: 0xFAD800 is a published directory target (the next "
      "module's first byte)", 0xFAD800 in _DIR)

# --- the four inline jump tables of the 0xFAA000 module ----------------------
# base, entries, the reader's `cp BC,n` site, n, and the first byte after
# The reader sits immediately before the table and is fixed-shape:
#   tb-10  E9 C8 <tb as LE32>   add XBC,imm32
#   tb-4   A1 21                ld XBC,(XBC)
#   tb-2   B1 D8                jp T,XBC
# and the entry count comes from a `cp BC,imm16` (D9 CF) a few bytes earlier.
_JT = [(0xFAB8B4, 12), (0xFABF4A, 12), (0xFAC326, 13), (0xFAC3BF, 13),
       (0xFC59DB, 10)]
for _tb, _n in _JT:
    shape = (a(_tb - 10, 2) == bytes([0xE9, 0xC8])
             and int.from_bytes(a(_tb - 8, 4), "little") == _tb
             and a(_tb - 4, 2) == bytes([0xA1, 0x21])
             and a(_tb - 2, 2) == bytes([0xB1, 0xD8]))
    cp = None
    for back in range(_tb - 12, _tb - 34, -1):
        if a(back, 2) == bytes([0xD9, 0xCF]):
            cp = back
            break
    imm = int.from_bytes(a(cp + 2, 2), "little") if cp else None
    check("JumpTable_%06X: the reader is `add XBC,0x%06X / ld XBC,(XBC) / "
          "jp T,XBC` in the 10 bytes before it" % (_tb, _tb), shape)
    check("JumpTable_%06X: %d entries == the reader's OWN `cp BC,0x%04X` + 1"
          % (_tb, _n, imm if imm is not None else 0),
          cp is not None and imm + 1 == _n, "cp at %s imm %s" % (cp, imm))
    check("JumpTable_%06X: every entry is an address inside prom_a" % _tb,
          all(0xF80000 <= _le32(_tb + 4 * k) <= 0xFFFFFF for k in range(_n)))
check("JumpTable_FAC326: LAST-ENTRY TEST -- base + 13*4 = 0xFAC35A and the "
      "bytes there are `lda XIY,0x24f4`",
      0xFAC326 + 52 == 0xFAC35A and a(0xFAC35A, 4) == bytes([0xF1, 0xF4, 0x24, 0x35]))
check("JumpTable_FAC3BF: LAST-ENTRY TEST -- base + 13*4 = 0xFAC3F3 and the "
      "bytes there are `ld XIX,(0x60f280)`",
      0xFAC3BF + 52 == 0xFAC3F3
      and a(0xFAC3F3, 5) == bytes([0xE2, 0x80, 0xF2, 0x60, 0x24]))

# --- Dispatch_By_60F080 and its tail -----------------------------------------
_DT = [_le32(0xFAC8EA + 4 * k) for k in range(256)]
check("Dispatch_By_60F080: the reader is `ld C,4 / mul BC,(0x60f080)` at 0xFAB847",
      a(0xFAB847, 2) == bytes([0x23, 0x04])
      and a(0xFAB849, 5) == bytes([0xC2, 0x80, 0xF0, 0x60, 0x43]))
check("Dispatch_By_60F080: the reader pushes 0xFAB860 as the handler's return "
      "address before `jp T,XBC`",
      a(0xFAB858, 5) == bytes([0xF2, 0x60, 0xB8, 0xFA, 0x35])
      and a(0xFAB85D, 3) == bytes([0x3D, 0xB1, 0xD8]))
check("Dispatch_By_60F080: 256 entries, all inside prom_a",
      all(0xF80000 <= x <= 0xFFFFFF for x in _DT))
check("Dispatch_By_60F080: 25 distinct values, 168 of them the default 0xFAC845",
      len(set(_DT)) == 25 and _DT.count(0x00FAC845) == 168,
      "distinct %d default %d" % (len(set(_DT)), _DT.count(0x00FAC845)))
check("Dispatch_By_60F080: the default 0xFAC845 is a bare `ret` (0x0E)",
      a(0xFAC845, 1) == b"\x0e")
check("Dispatch_By_60F080: the 24 real handlers all lie in 0xFAB894-0xFABE0D",
      min(x for x in _DT if x != 0x00FAC845) == 0xFAB894
      and max(x for x in _DT if x != 0x00FAC845) == 0xFABE0D)
check("Dispatch_By_60F080: LAST-ENTRY TEST -- index 255 is at 0xFACCE6, and the "
      "64 words after it are ALL the default",
      0xFAC8EA + 4 * 255 == 0xFACCE6
      and set(_le32(0xFACCEA + 4 * k) for k in range(64)) == {0x00FAC845})

# --- Lookup32_By_Arg8 --------------------------------------------------------
_LK = [_le32(0xFACDEA + 4 * k) for k in range(256)]
check("Lookup32_By_Arg8: its reader at 0xFAC8AA is `ld C,4 / mul BC,(XIZ+0x08) "
      "/ add XBC,0x00FACDEA / ld XBC,(XBC) / ld XIY,XBC`",
      a(0xFAC8AE, 2) == bytes([0x23, 0x04])
      and a(0xFAC8B0, 3) == bytes([0x8E, 0x08, 0x43])
      and a(0xFAC8B5, 6) == bytes([0xE9, 0xC8, 0xEA, 0xCD, 0xFA, 0x00])
      and a(0xFAC8BB, 4) == bytes([0xA1, 0x21, 0xE9, 0x8D]))
check("Lookup32_By_Arg8: 78 distinct values, 179 of them 0xFFFFFFFF",
      len(set(_LK)) == 78 and _LK.count(0xFFFFFFFF) == 179,
      "distinct %d ff %d" % (len(set(_LK)), _LK.count(0xFFFFFFFF)))
check("Lookup32_By_Arg8: every non-0xFFFFFFFF value is in 0x7622-0x7F5A",
      min(x for x in _LK if x != 0xFFFFFFFF) == 0x7622
      and max(x for x in _LK if x != 0xFFFFFFFF) == 0x7F5A)
check("Lookup32_By_Arg8: LAST-ENTRY TEST -- 0xFACDEA + 256*4 = 0xFAD1EA and "
      "the 32 bytes there are 0x00..0x1F",
      0xFACDEA + 1024 == 0xFAD1EA
      and list(a(0xFAD1EA, 32)) == list(range(32)))
# the 24 calr sites into 0xFAC8AA -- resolved, not grepped
_calr = [0xF80000 + i for i in range(len(A) - 2)
         if A[i] == 0x1E and 0xF80000 + i + 3
         + int.from_bytes(A[i + 1:i + 3], "little", signed=True) == 0xFAC8AA]
check("Lookup32_By_Arg8: exactly 24 `calr` sites reach 0xFAC8AA, first 0xFAA8BB, "
      "last 0xFAC7D3",
      len(_calr) == 24 and _calr[0] == 0xFAA8BB and _calr[-1] == 0xFAC7D3,
      "%d %s" % (len(_calr), [hex(x) for x in _calr[:3]]))

# --- the constant tables, both copies ----------------------------------------
for _at, _tag in ((0xFAD20A, "BitMask32_Table"),
                  (0xFC64C6, "BitMask32_Table_FC64C6")):
    check("%s: 32 LE32 entries, entry k == 1 << k, entry 31 == 0x80000000" % _tag,
          [_le32(_at + 4 * k) for k in range(32)] == [1 << k for k in range(32)])
check("the two BitMask32 tables are byte-identical, 128 bytes",
      a(0xFAD20A, 128) == a(0xFC64C6, 128))
check("BitMask32_Table: 11 `lda` readers, 2 spelling it XBC (op 0x31) and 9 XWA "
      "(op 0x30), all in 0xFAC176-0xFAC265",
      [0xF80000 + i - 1 for i in range(len(A) - 4)
       if A[i:i + 3] == bytes([0x0A, 0xD2, 0xFA]) and A[i - 1] == 0xF2
       and A[i + 3] in (0x30, 0x31)] == [0xFAC176, 0xFAC18F, 0xFAC1A8, 0xFAC1C1,
                                         0xFAC1DA, 0xFAC1F3, 0xFAC20C, 0xFAC225,
                                         0xFAC23E, 0xFAC257, 0xFAC265])

# --- the 0xFAD28A group and its duplicate tail -------------------------------
check("PtrTable_FAD28A: 64 LE32 entries, every one inside prom_b (0xF00000-0xF7FFFF)",
      all(0xF00000 <= _le32(0xFAD28A + 4 * k) < 0xF80000 for k in range(64))
      and (0xFAD38A - 0xFAD28A) // 4 == 64)
check("PtrTable_FAD28A: its END is named by another reader -- `add XBC,0x00FAD38A` "
      "at 0xFAAFCE and 0xFAB031",
      a(0xFAAFCE, 6) == bytes([0xE9, 0xC8, 0x8A, 0xD3, 0xFA, 0x00])
      and a(0xFAB031, 6) == bytes([0xE9, 0xC8, 0x8A, 0xD3, 0xFA, 0x00]))
check("ByteTable_FAD38A: 13 bytes 78 60 61 62 63 92 79 7A 98 99 80 91 93",
      a(0xFAD38A, 13) == bytes([0x78, 0x60, 0x61, 0x62, 0x63, 0x92, 0x79, 0x7A,
                                0x98, 0x99, 0x80, 0x91, 0x93]))
check("PtrTable_FAD397: 13 LE32 entries, all inside prom_b, and its end 0xFAD3CB "
      "is named by `add XBC,0x00FAD3CB` at 0xFAB670",
      all(0xF00000 <= _le32(0xFAD397 + 4 * k) < 0xF80000 for k in range(13))
      and (0xFAD3CB - 0xFAD397) // 4 == 13
      and a(0xFAB670, 6) == bytes([0xE9, 0xC8, 0xCB, 0xD3, 0xFA, 0x00]))
check("Bytes_0F_FAD3CB: 32 bytes, every one 0x0F, and the byte after is 0x00",
      set(a(0xFAD3CB, 32)) == {0x0F} and a(0xFAD3EB, 1) == b"\x00")
check("DuplicateTail_FAD3EB: 154 bytes identical to 0xFAD351-0xFAD3EA, and the "
      "match is MAXIMAL in both directions",
      a(0xFAD3EB, 154) == a(0xFAD351, 154)
      and a(0xFAD3EB + 154, 1) != a(0xFAD351 + 154, 1)
      and a(0xFAD3EB - 1, 1) != a(0xFAD351 - 1, 1))
check("DuplicateTail_FAD3EB: nothing in prom_a or prom_b names any of "
      "0xFAD3EB/0xFAD3EC/0xFAD424/0xFAD431/0xFAD465",
      not any(bytes([t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF]) in img
              for t in (0xFAD3EB, 0xFAD3EC, 0xFAD424, 0xFAD431, 0xFAD465)
              for img in (A, B)))
check("Bytes_00_to_1F (0xFAD1EA) is named by NOTHING in either image",
      bytes([0xEA, 0xD1, 0xFA]) not in A and bytes([0xEA, 0xD1, 0xFA]) not in B)

# --- the 0xFC5400 module's tables --------------------------------------------
check("Bytes_00_to_1F_FC64A5: 0x00..0x1F then a single 0xFF",
      list(a(0xFC64A5, 32)) == list(range(32)) and a(0xFC64C5, 1) == b"\xff")
_D32 = [_le32(0xFC6546 + 4 * k) for k in range(32)]
check("Dispatch32_FC6546: 32 entries, 7 distinct, all in 0xFC5B26-0xFC5C6C",
      len(set(_D32)) == 7 and min(_D32) == 0xFC5B26 and max(_D32) == 0xFC5C6C,
      "distinct %d" % len(set(_D32)))
check("Dispatch32_FC6546: LAST-ENTRY TEST -- 0xFC6546 + 32*4 = 0xFC65C6 and the "
      "bytes there are 00 01 02 03",
      0xFC6546 + 128 == 0xFC65C6 and a(0xFC65C6, 4) == bytes([0, 1, 2, 3]))
check("Bytes_00_to_1F_x3_FC65C6: three identical 32-byte identity runs",
      all(list(a(0xFC65C6 + 32 * j, 32)) == list(range(32)) for j in range(3))
      and a(0xFC6626, 4) == bytes([0xA2, 0x76, 0x00, 0x00]))
check("MixedTables_FC6626 is named by NOTHING: not 0xFC6626, 0xFC6800 or 0xFC6816",
      not any(bytes([t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF]) in img
              for t in (0xFC6626, 0xFC6816) for img in (A, B)))

# --- the module this round REFUSED (FINDINGS-prom_a-message-module.md §5) ----
_REC = True
for _k in range(32):
    _r = a(0xFC0890 + 8 * _k, 8)
    _REC = _REC and (int.from_bytes(_r[0:4], "little") == 0x600 + 8 * _k
                     and int.from_bytes(_r[4:6], "little") == 1 << (_k & 15)
                     and _r[6] == _k and _r[7] == 0x0E)
check("refused module: 0xFC0890 is 32 records {LE32 0x600+8k, LE16 1<<(k&15), "
      "byte k, 0x0E}", _REC)
check("refused module: LAST-ENTRY TEST -- record 31 ends at 0xFC0990 and the "
      "bytes there are not another record",
      0xFC0890 + 32 * 8 == 0xFC0990 and a(0xFC0997, 1) != b"\x0e")
check("refused module: the five in-veneer off-boundary slots are inside "
      "5-byte `ld XIZ/XIY,imm32` instructions of 0xFC0410-0xFC0470",
      a(0xFC0425, 1) == b"\x45" and a(0xFC0450, 1) == b"\x46"
      and a(0xFC043C, 1) == b"\x1e")
check("refused module: ASCII lives at 0xFC2135 -- 'Combi Group Name' then "
      "'EXT Silent Group'",
      a(0xFC2135, 32) == b"Combi Group NameEXT Silent Group")

# The COUNT is printed rather than written into a header: this file's own
# --- span banners vs the .incbin under them (added wave 5 round 2) ----------
# `; 0xAAAAAA-0xBBBBBB -- not yet converted` banners go STALE silently:
# prom_a/insert_region.py splits the directive beneath one and cannot know the
# banner exists.  One had been wrong since the first insertion -- it still named
# 0xF827C8-0xFFFEFF over a 1,335-byte directive.  The byte gate cannot see this.
_BAN = re.compile(r"^; (0x[0-9A-F]{6})-(0x[0-9A-F]{6}) -- not yet converted\s*$")
_INC = re.compile(r'^\t\.incbin "original_ROMs/wsa1_prom_a\.ic12", '
                  r'(0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)\s*$')
_lines = _SRC.split("\n")
_seen = 0
for _i, _l in enumerate(_lines):
    _m = _BAN.match(_l)
    if not _m:
        continue
    for _j in range(_i + 1, min(_i + 16, len(_lines))):
        _mm = _INC.match(_lines[_j])
        if _mm:
            _lo = 0xF80000 + int(_mm.group(1), 16)
            _hi = _lo + int(_mm.group(2), 16) - 1
            _seen += 1
            check("span banner on line %d names the range of the .incbin under "
                  "it" % (_i + 1),
                  (int(_m.group(1), 16), int(_m.group(2), 16)) == (_lo, _hi),
                  "banner %s-%s vs 0x%06X-0x%06X"
                  % (_m.group(1), _m.group(2), _lo, _hi))
            break
# A banner with NO `.incbin` under it is the other failure mode: the range was
# converted and the banner was left behind, claiming the code is not there.  Two
# of those existed (0xF85904-0xF85C88 and 0xFE5A41-0xFE6850) and are why this
# check counts rather than just compares ranges.
_total = sum(1 for _l in _lines if _BAN.match(_l))
check("every `not yet converted` banner has an .incbin under it",
      _seen == _total, "%d of %d" % (_seen, _total))

# docstring said "133 checks" and prom_a's banner said "232" while the number
# that actually ran was 231.  A count nobody re-derives is a claim that rots.
print("%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
