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
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def b(addr, n=1):
    return B[addr - 0xF00000:addr - 0xF00000 + n]


def check(name, cond, detail=""):
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
except Exception as e:                                       # noqa: BLE001
    print("SKIP  Int_Mul32 KN5000-side checks (%s)" % type(e).__name__)

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

print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
