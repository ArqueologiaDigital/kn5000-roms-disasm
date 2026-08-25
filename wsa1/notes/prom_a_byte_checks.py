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
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
check("DSP_WriteChannelRegs_FromTable: index = (channel<<5)|0x10",
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

# --- round 2 new territory: DSP_Init_Channels --------------------------------
check("DSP_Init_Channels: 0xF85F0F opens with `link XIZ,0xFFF8`",
      a(0xF85F0F, 4) == bytes([0xEE, 0x0C, 0xF8, 0xFF]))
check("DSP_Init_Channels: it ends `unlk XIZ / ret` at 0xF85F56",
      a(0xF85F56, 3) == bytes([0xEE, 0x0D, 0x0E]))
check("DSP_Init_Channels: the four calls all target 0xF85F59",
      all(int.from_bytes(a(s0 + 1, 2), "little") + s0 + 3 == 0xF85F59
          and a(s0, 1) == b"\x1e" for s0 in (0xF85F22, 0xF85F29, 0xF85F30, 0xF85F37)))
check("DSP_Init_Channels: the config word is 0x0101001F and the stride 0x20",
      a(0xF85F45, 5) == bytes([0x40, 0x1F, 0x00, 0x01, 0x01])
      and a(0xF85F50, 3) == bytes([0xC9, 0xC8, 0x20]))
check("DSP_Init_Channels: the loop runs 4 times",
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
                    (0xF85F0F, "DSP_Init_Channels")):
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
check("the same search finds the four calls to DSP_WriteChannelRegs_FromTable",
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
check("DSP_WriteChannelRegs_FromTable is ALSO published, at 0xF42DE0",
      int.from_bytes(b(0xF42DE1, 3), "little") == 0xF85F59
      and b(0xF42DE0, 1) == b"\x1b")

# --- ROUND 3: the banner's `.fill` claim (round-1 audit F1) ------------------
import re as _re
_SRC = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
_FILLS = [(int(m.group(1), 0), int(m.group(2)))
          for m in _re.finditer(r"^\t\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(\d+)\s*,",
                                _SRC, _re.M)]
check("prom_a has exactly ONE .fill and it is 108 bytes of 0x0E padding",
      len(_FILLS) == 1 and _FILLS[0][0] * _FILLS[0][1] == 108
      and list(a(0xFFFF84, 108)) == [0x0E] * 108,
      str(_FILLS))

# The COUNT is printed rather than written into a header: this file's own
# docstring said "133 checks" and prom_a's banner said "232" while the number
# that actually ran was 231.  A count nobody re-derives is a claim that rots.
print("%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
