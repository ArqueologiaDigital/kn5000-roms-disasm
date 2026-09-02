# prom_a 0xFC4000-0xFC52F7: what is known, and why it stays `.incbin`

**Status: refused four times, by four independent passes.** This note exists so the
fifth does not start from zero, and so the refusal is not mistaken for absence of
analysis.

## What the span contains — established, not inferred

Two real mechanisms, both proven by content:

* **`op,len` text/coordinate records**, tiling 154 deep. They spell the DSP-effect
  and Sound-Edit parameter vocabulary: `INTENSITY`, `DIGITAL EFFECT`, `DEPTH`,
  `SPEED`, `DETUNE`, `DELAY`, `BALANCE`, `WAVE`, `KEY SHIFT`, `DECAY`, `SUSTAIN`,
  `RELEASE`, `DISTORTION` — and further in, effect names: `CELESTE`, `CHORUS`,
  `ENSEMBLE`, `TREMOLO`, `SOLO EFFECT`, `MONO`, `STEREO`.
* **A self-referential pointer-quad array** indexing back into those records, with
  a null rate below 0.1%.

A scan proving the vocabulary is committed as
`wsa1/notes/prom_a_fc40f4_strings_scan.py` (95 ASCII runs, all 12 of a checked
vocabulary).

## Why it is not converted

**The records stop and 1bpp icon bitmap data begins, and nobody has derived where.**

`wsa1/notes/prom_a_fc4000_record_framing_probe.py --greedy` DEMONSTRATES the
failure: a naive `op,len` walk sails straight through the bitmap, misreading it as
records. This is not a worry, it is a reproduced defect.

A later pass built a **non-resyncing** combined walker (records + pointer quads, no
failure recovery) and got further — cleanly past the earlier 0.051%-calibrated
stopping point at `0xFC4574`, all the way to `0xFC48FC`. Then the last record
over-consumed: its declared length swallowed **37 bytes of real bitmap** — a
diagonal edge (`88 88 f8 ...`) followed by `55 aa ff ff` dither runs — starting
just after `"...STEREO"` ends.

So the text/bitmap boundary is **almost certainly ~`0xFC48D7`**, immediately after
`STEREO`, and two independent passes now agree on that figure.

⚠ **That agreement is not sufficient, and this is the whole point.** Both estimates
come from the same class of argument — *where the walk stops looking plausible* —
and this tree has an explicit rule against that standard, written after a walk
tiled 4,807 bytes of padding as records. A boundary is worth converting when it is
fixed by something external: an interpreter call site, a length or count held
elsewhere, a reader's loop bound, or a pointer that must land on it.

There is no interpreter call site for this span, and `reachability.py` reports
**zero reachable bytes** in it.

## What would settle it

Any one of these, in rough order of likelihood:

1. **A reader.** Something must walk these records at runtime. Find the routine
   that consumes them and its termination condition is the boundary. The
   fixed-stride table at `0xF96CA6` was converted on exactly this basis — its
   reader's loop count of 80 proved the layout.
2. **A count or extent stored elsewhere**, in the manner of the prom_b records
   whose own `+0x07`/`+0x0B` fields name and size their string tables.
3. **A pointer into the bitmap region** from anywhere else in the image, which
   would bound the text region from above.
4. **The bitmap's own structure** — if the icons are fixed-size, their start must
   be congruent to a stride, which constrains the boundary from the other side.

Until one of those lands, the span stays `.incbin` with this note attached.
Converting it on the current evidence would ship a plausible extent, which is the
specific failure mode this tree exists to catch.
