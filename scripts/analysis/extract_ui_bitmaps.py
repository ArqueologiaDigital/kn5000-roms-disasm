#!/usr/bin/env python3
"""
Extract the DrawBitmap/DrawFrameSP graphics from the KN5000 Table Data ROM.

Two descriptor tables live inside table_data/includes/wallpaper1_to_icons.bin
(see table_data/ui_bitmaps.s for the full disassembly of the region):

- BitmapDescriptorTable @ 0x913000: 34 x {w16, h16, ptr32} + null terminator,
  indexed by DrawBitmap/DrawBitmapFast (maincpu ui/drawing_primitives.s)
- FrameDescriptorTable  @ 0x934000: 53 x {w16, h16, ptr32} + null terminator,
  indexed by DrawFrameSP

Pixel format: 8bpp indexed, rows padded to 16-bit alignment (odd widths carry
one pad byte per row).  Color 0xf7 is transparent; in frame pieces color 0xf6
is a template color replaced at draw time by DrawFrameSP's color argument
(rendered here with the palette's 0xf6 entry, a pale green).

Output file names follow the labels in table_data/ui_bitmaps.s.

Usage:
    python extract_ui_bitmaps.py [output_root]

Default output_root is table_data/images/ (creates ui_bitmaps/ and ui_frames/).
"""

import struct
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

REPO = Path(__file__).resolve().parents[2]
BLOB = REPO / "table_data/includes/wallpaper1_to_icons.bin"
PALETTE = REPO / "v10/maincpu/images/Palette_8bit_RGBA.bin"
BLOB_BASE = 0x912C00

BITMAP_TABLE = 0x913000
FRAME_TABLE = 0x934000

# Labels from table_data/ui_bitmaps.s, in table order
BITMAP_LABELS = [
    "Bitmap_WormWearingHat", "Bitmap_TechnicsLogoOutline", "Bitmap_VerticalFader",
    "Bitmap_RedBarGauge", "Bitmap_RecordDot", "Bitmap_TinyCross",
    "Bitmap_TransportFastForward", "Bitmap_TransportRewind", "Bitmap_TransportPause",
    "Bitmap_TransportPlayStop", "Bitmap_TransportSkipToStart", "Bitmap_TransportSkipToEnd",
    "Bitmap_SoundIcon_Violin", "Bitmap_SoundIcon_Trumpet", "Bitmap_SoundIcon_DrumKit",
    "Bitmap_SoundIcon_Flutes", "Bitmap_SoundIcon_ElectricGuitar", "Bitmap_SoundIcon_NoteInCloud",
    "Bitmap_SoundIcon_MalletPercussion", "Bitmap_PageIconA", "Bitmap_PageIconB",
    "Bitmap_SoundIcon_MixerModule", "Bitmap_SoundIcon_FiddleAndBanjo", "Bitmap_SoundIcon_GrandPiano",
    "Bitmap_SoundIcon_SaxAndClarinet", "Bitmap_SoundIcon_FiddleAndMandolin",
    "Bitmap_SoundIcon_SynthKeyboard", "Bitmap_SoundIcon_Drawbars", "Bitmap_SoundIcon_Accordion",
    "Bitmap_GreenLedButtonBright", "Bitmap_GreenLedButtonDim", "Bitmap_GeneralMidiSpecialLogo",
    "Bitmap_SoundIcon_Metronome", "Bitmap_SoundIcon_Microphone",
]

FRAME_LABELS = (
    [f"Frame_RoundCorner{s}_{c}" for s in (1, 2, 5, 9, 14) for c in ("TL", "TR", "BR", "BL")]
    + [f"Frame_ChevronRight_{w}x{h}" for w, h in ((5, 12), (6, 16), (8, 24), (10, 32), (15, 48))]
    + [f"Frame_ChevronLeft_{w}x{h}" for w, h in ((5, 12), (6, 16), (8, 24), (10, 32), (15, 48))]
    + [f"Frame_OnOffTabLeft_{w}x{h}" for w, h in ((20, 16), (24, 24), (29, 32), (34, 48))]
    + [f"Frame_OnOffTabRight_{w}x{h}" for w, h in ((20, 16), (24, 24), (29, 32), (34, 48))]
    + ["Frame_RedArrowLeft", "Frame_RedArrowRight"]
    + [f"Frame_BevelCorner{s}_{c}" for s in ("Raised", "Outlined", "Sunken")
       for c in ("TL", "TR", "BR", "BL")]
    + ["Frame_WideTabBar"]
)


def load_palette():
    data = PALETTE.read_bytes()
    return [tuple(data[i * 4:i * 4 + 3]) for i in range(256)]


def render(blob, pal, addr, w, h):
    """Render one 8bpp image; 0xf7 becomes transparent."""
    stride = (w + 1) // 2 * 2
    img = Image.new("RGBA", (w, h))
    px = img.load()
    off = addr - BLOB_BASE
    for y in range(h):
        for x in range(w):
            v = blob[off + y * stride + x]
            px[x, y] = (0, 0, 0, 0) if v == 0xF7 else pal[v] + (255,)
    return img


def extract_table(blob, pal, table_addr, labels, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    off = table_addr - BLOB_BASE
    for i, label in enumerate(labels):
        w, h, ptr = struct.unpack_from("<HHI", blob, off + i * 8)
        render(blob, pal, ptr, w, h).save(out_dir / f"{label}.png")
    term = struct.unpack_from("<HHI", blob, off + len(labels) * 8)
    assert term == (0, 0, 0), f"table at {table_addr:#x}: expected null terminator"
    print(f"Extracted {len(labels)} images to {out_dir}")


def main():
    out_root = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "table_data/images"
    blob = BLOB.read_bytes()
    pal = load_palette()
    extract_table(blob, pal, BITMAP_TABLE, BITMAP_LABELS, out_root / "ui_bitmaps")
    extract_table(blob, pal, FRAME_TABLE, FRAME_LABELS, out_root / "ui_frames")


if __name__ == "__main__":
    main()
