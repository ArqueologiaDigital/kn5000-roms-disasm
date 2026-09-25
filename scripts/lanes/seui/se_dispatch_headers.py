#!/usr/bin/env python3
r"""HEADERS FOR THE SOUND EDITOR'S TWO 48-ENTRY SCREEN-HANDLER TABLES.

QUESTION ANSWERED
-----------------
`SeMenu_ShowPopupDialog_Draw` and `SeMenu_ShowConfirmDialog_Data` (names kept:
shared/positional_labels.s builds aliases on them) are LE32 handler tables,
not a drawing routine or a data block.  This derives, from the ROM and the
linked ELF, each table's reader, index formula, entry count and the entries
that point at the bare `ret` SeMenu_WaveformSelect_End, and writes that as a
header above each label (existing lines untouched).

  reader SeMenu_ShowPopupDialog:   hl = (xiz+8) - 0x20; hl <<= 2;
      xiy = (table + hl); Display_DeferOrDrawWall (via
      SeMenu_WaveformSelect_Handler), call (xiy), Display_DeferOrUpdateScreen
      (via SeMenu_WaveformSelect_Process)
  reader SeMenu_ShowConfirmDialog: same index from (xiz+8); call (xiy); then
      `or (0xe3e2), 8`
  count: the table runs up to the first byte of the next routine
      (SeMenu_ShowConfirmDialog after the first table; the routine at
      SeMenu_ShowConfirmDialog_Data + 0xC0 after the second, which
      `call SeMenu_ShowConfirmDialog_Data_0xC0` sites name).

RUN
    python3 scripts/lanes/seui/se_dispatch_headers.py --image v10 [--apply]
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
import se_screendata_model as sm          # noqa: E402

REL = "audio/sound_editor_ui.s"
BASE = 0xE00000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    s = sm.symbols(a.image)
    rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % a.image), "rb").read()
    ret = s["SeMenu_WaveformSelect_End"]
    assert rom[ret - BASE] == 0x0E, "SeMenu_WaveformSelect_End is not a bare ret"
    spec = [("SeMenu_ShowPopupDialog_Draw", "SeMenu_ShowPopupDialog", s["SeMenu_ShowConfirmDialog"],
             "then Display_DeferOrDrawWall before and Display_DeferOrUpdateScreen after the\n"
             "; call (via SeMenu_WaveformSelect_Handler / _Process)"),
            ("SeMenu_ShowConfirmDialog_Data", "SeMenu_ShowConfirmDialog", s["SeMenu_ShowConfirmDialog_Data"] + 0xC0,
             "then `or (0xe3e2), 8`")]
    path = os.path.join(ROOT, a.image, "maincpu", REL)
    raw = open(path, "rb").read()
    for (lab, reader, end, tail) in spec:
        t = s[lab]
        n = (end - t) // 4
        ents = [struct.unpack_from("<I", rom, t - BASE + 4 * k)[0] for k in range(n)]
        rets = [k for k, e in enumerate(ents) if e == ret]
        runs, k = [], 0
        while k < len(rets):
            j = k
            while j + 1 < len(rets) and rets[j + 1] == rets[j] + 1:
                j += 1
            runs.append("%d" % rets[k] if j == k else "%d-%d" % (rets[k], rets[j]))
            k = j + 1
        hdr = ("; -----------------------------------------------------------------------------\n"
               "; Screen-handler table: %d LE32 entries, one per event code 0x20-0x%02X.\n"
               "; Read by %s: hl = (xiz+8) - 0x20, sla hl,2, xiy = (table+hl),\n"
               "; call (xiy); %s.  Entry count: the table ends where the next\n"
               "; routine begins.  Entries %s point at SeMenu_WaveformSelect_End, a bare\n"
               "; `ret`: codes this screen set does not handle.  (Label name historical --\n"
               "; shared/positional_labels.s builds aliases on it.)\n"
               "; -----------------------------------------------------------------------------\n"
               % (n, 0x20 + n - 1, reader, tail, ", ".join(runs)))
        anchor = ("\n%s:\n" % lab).encode()
        assert raw.count(anchor) == 1, lab
        if b"; Screen-handler table" in raw[max(0, raw.index(anchor) - 800):raw.index(anchor)]:
            continue
        raw = raw.replace(anchor, b"\n" + hdr.encode() + ("%s:\n" % lab).encode())
        print("%s: %s %d entries, ret entries %s" % (a.image, lab, n, ", ".join(runs)))
    if a.apply:
        open(path, "wb").write(raw)


if __name__ == "__main__":
    main()
