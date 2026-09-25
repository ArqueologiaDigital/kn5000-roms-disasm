#!/usr/bin/env python3
r"""ARE THE SOUND EDITOR'S 17 `SeGfx_*` WRAPPERS WHAT THEIR NAMES SAY?

QUESTION ANSWERED
-----------------
`audio/sound_editor_ui.s` carries 17 four-to-ten-instruction routines that were
named `SeMenu_NameEditor_Setup`, `_Draw`, `_HandleInput`, `_InsertChar`,
`_DeleteChar`, ... although none of them touches the name editor: each one
loads a ScreenData record pointer and calls ONE entry point of the ScreenData
record interpreter in display/graphics_text_vga.s.  Lane seui renamed them
after the entry point they call.  This probe re-derives every name from the
ROM, so the names can be checked rather than trusted.

WHAT IT READS (per image: v10, v9, v7)
  * the two handler tables, read out of the ROM at the address the interpreter
    itself loads with `ld xiy, imm32` (opcode 0x45) at its start:
      GraphicsRender_ProcessEntries -> 36 entries (ops 0x00-0x23), copied with
                                       `ldirw` count 0x48 words = 144 bytes
      GraphicsRender_Start          -> 12 entries (ops 0x00-0x0B), count 0x18
  * each wrapper's body, [its address, the next wrapper's address), decoded
    with MAME unidasm (a decoder independent of the tree's own assembler): it
    must contain exactly one `call`, and it must mention the RAM record buffer
    0x6CA if and only if the name says so (`_FromBuf`, `_BlitAtCell`).
  Addresses of the wrappers and interpreter entry points come from the linked
  ELF (`rebuilt_ROMs/kn5000_<v>_program.llvm.elf`); bytes come from the dump.

WHAT PASSES
  Every wrapper's call target equals the entry its name claims:
    SeGfx_DrawStaticList  -> GraphicsRender_ProcessEntries        (XIY..XIX)
    SeGfx_DrawBoundList   -> GraphicsRender_Start                 (XIY..XIX)
    SeGfx_DrawBoundRecord -> GraphicsRender_ShortByteBlock + 5    (one record)
    SeGfx_StaticOpNN*     -> 36-table[NN]
    SeGfx_BoundOpNN       -> 12-table[NN]
  and every `_FromBuf` wrapper passes 0x6CA, every other single-record wrapper
  passes XIY.

RUN
    make rebuilt_ROMs/kn5000_v10_program.llvm.elf   (and v9, v7)
    python3 scripts/lanes/seui/se_gfx_wrappers_probe.py
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

# name -> (kind, op)   kind: list36 / list12 / one12 / s36 / b12
WRAPPERS = {
    "SeGfx_DrawStaticList": ("list36", None),
    "SeGfx_DrawBoundList": ("list12", None),
    "SeGfx_DrawBoundRecord": ("one12", None),
    "SeGfx_StaticOp00_FromBuf": ("s36", 0x00),
    "SeGfx_StaticOp02_FromBuf": ("s36", 0x02),
    "SeGfx_StaticOp03_BlitAtCell": ("s36", 0x03),
    "SeGfx_StaticOp05_FromBuf": ("s36", 0x05),
    "SeGfx_StaticOp06_Text": ("s36", 0x06),
    "SeGfx_StaticOp07_Text": ("s36", 0x07),
    "SeGfx_StaticOp09_FromBuf": ("s36", 0x09),
    "SeGfx_StaticOp0E": ("s36", 0x0E),
    "SeGfx_StaticOp15_FromBuf": ("s36", 0x15),
    "SeGfx_StaticOp1B_FromBuf": ("s36", 0x1B),
    "SeGfx_BoundOp00": ("b12", 0x00),
    "SeGfx_BoundOp02": ("b12", 0x02),
    "SeGfx_BoundOp03": ("b12", 0x03),
    "SeGfx_BoundOp06": ("b12", 0x06),
}


def symbols(v):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True,
                         text=True, check=True).stdout
    s = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3:
            s.setdefault(p[2], int(p[0], 16))
    return s


def ld_xiy_imm(rom, a, n=16):
    """first `ld xiy, imm32` (0x45 + LE32) in [a, a+n)"""
    for i in range(n):
        if rom[a - BASE + i] == 0x45:
            return struct.unpack_from("<I", rom, a - BASE + i + 1)[0]
    raise SystemExit("no ld xiy,imm32 near %06x" % a)


def body_calls(rom, a, e):
    """decode [a, e) with MAME unidasm; -> (list of call targets, text)"""
    import tempfile
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(rom[a - BASE:e - BASE])
        f.flush()
        out = subprocess.run([UNIDASM, f.name, "-arch", "tlcs900", "-basepc", "%x" % a],
                             capture_output=True, text=True, check=True).stdout
    calls = [int(m, 16) for m in re.findall(r"\bcall 0x([0-9a-f]+)", out)]
    return calls, out


def main():
    bad = 0
    for v in ("v10", "v9", "v7"):
        rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
        s = symbols(v)
        pe, st, sb = (s["GraphicsRender_ProcessEntries"], s["GraphicsRender_Start"],
                      s["GraphicsRender_ShortByteBlock"])
        t36, t12 = ld_xiy_imm(rom, pe), ld_xiy_imm(rom, st)
        h36 = [struct.unpack_from("<I", rom, t36 - BASE + 4 * k)[0] for k in range(36)]
        h12 = [struct.unpack_from("<I", rom, t12 - BASE + 4 * k)[0] for k in range(12)]
        print("%s: 36-op table at %06x, 12-op table at %06x" % (v, t36, t12))
        order = sorted(s[n] for n in WRAPPERS if n in s)
        for name, (kind, op) in WRAPPERS.items():
            if name not in s:
                print("  MISSING  %s" % name)
                bad += 1
                continue
            a = s[name]
            nxt = [x for x in order if x > a]
            e = nxt[0] if nxt else a + 24
            calls, text = body_calls(rom, a, e)
            tgt = calls[0] if len(calls) == 1 else None
            if kind == "list36":
                want = pe
            elif kind == "list12":
                want = st
            elif kind == "one12":
                want = sb + 5
            elif kind == "s36":
                want = h36[op]
            else:
                want = h12[op]
            buf = "0x000006ca" in text.lower() or "0x6ca" in text.lower()
            ok = tgt == want and (buf == (name.endswith("_FromBuf") or name.endswith("_BlitAtCell")))
            bad += not ok
            print("  %-4s %-28s %06x -> call %06x (want %06x)%s"
                  % ("ok" if ok else "BAD", name, a, tgt or 0, want or 0,
                     "  [record buffer 0x6CA]" if buf else ""))
    print("\nVERDICT: %s" % ("all wrapper names agree with the ROM" if not bad
                             else "%d disagreements" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
