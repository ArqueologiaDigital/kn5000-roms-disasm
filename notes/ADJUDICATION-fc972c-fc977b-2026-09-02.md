# Adjudication: 0xFC972C and 0xFC977B are NOT span starts — both are mid-instruction

Lane `v10audio` asked the integrator to settle a disagreement with lane
`V10DAC`, which had marked two 26-byte spans in v10's audio region as
data-as-code. v10audio's reading was the opposite — that they are real code —
on three observations:

* a decode from `0xFC9772` (which the tree still spells as instructions) runs
  straight through both;
* they `calr` the same routine `0xFC9DF4` from two sites;
* every `jr Z` lands on an `inc 2,XSP ; ret` epilogue.

**All three observations are true, and the conclusion does not follow.**

## The measurement

`unidasm` over the original dump, decoding from a start well before each
disputed offset so the alignment is inherited rather than assumed:

```
fc9722: 21 87              ld A,0x87
fc9724: c1 66 48 c1        and A,(0x4866)
fc9728: 30 91 21           ld WA,0x2191
fc972b: 87 c1              and A,(XSP)      <-- 0xFC972C is this instruction's SECOND byte
fc972d: 66 40              jr Z,0xfc976f
fc972f: c1 27 91 21        ld A,(0x9127)
fc9733: d8 12              extz WA
fc9735: 1e bc 06           calr 0xfc9df4
```

```
fc9776: c1 31 91 21        ld A,(0x9131)
fc977a: 87 c1              and A,(XSP)      <-- 0xFC977B is this instruction's SECOND byte
fc977c: 66 40              jr Z,0xfc97be
```

**Both disputed offsets are the `c1` of an `and A,(XSP)`.** Neither is an
instruction boundary.

## Why the wrong start looked so convincing

Decoding from the wrong offset gives:

```
fc977b: c1 66 40 c1        and A,(0x4066)
fc977f: 27 91              ld L,0x91
fc9781: 21 d8              ld A,0xd8
fc9783: 12                 ccf
fc9784: 1e 6d 06           calr 0xfc9df4    <-- RESYNCHRONISED
```

`0xC1` is a memory-operand prefix byte, so a decode starting on one produces a
perfectly plausible instruction — and four bytes later the misaligned stream
**resynchronises onto the real one**. From `calr 0xfc9df4` onward the two
alignments agree exactly.

That is the whole explanation for v10audio's three observations:

* it "runs straight through" because it rejoins the real stream;
* it `calr`s `0xFC9DF4` because **that is the real instruction there**, reached
  by both alignments;
* the `jr Z` lands on a real epilogue for the same reason.

Self-resynchronisation is the norm on a dense variable-length encoding, not
evidence of a second valid code path.

## Verdict

**Neither span is a valid framing.** The region is code — so `V10DAC`'s
`data-as-code` label is imprecise — but the correct framing is the existing one
from `0xFC9772`, and no overlapping span should be introduced at `0xFC972C` or
`0xFC977B`. v10audio was right to refuse to convert and right to escalate; its
proposed alternative is one byte late.

⚠ **The general trap, in the code direction.** This project's catalogued hazard
is "a wrong START frames fake records indefinitely" for *data*. This is the same
failure for *code*, and it is harder to spot, because a wrong start in data
keeps producing wrong records while a wrong start in code produces a few wrong
instructions and then silently agrees with the truth forever. Agreement
downstream of a resync is not evidence about the start.

**The test that settles it** is the one used above: never decode from the offset
in question. Decode from a point whose alignment is already established and see
where the instruction boundaries actually fall.

## Reproduce

    python3 - <<'PY'
    import subprocess, os, tempfile
    rom = open('original_ROMs/kn5000_v10_program.rom','rb').read(); BASE = 0xE00000
    def dis(start, end):
        seg = rom[start-BASE:end-BASE]
        f = tempfile.NamedTemporaryFile(suffix='.bin', delete=False); f.write(seg); f.close()
        o = subprocess.run([os.path.expanduser('~/compartilhado/mame/unidasm'), f.name,
                            '-arch','tlcs900','-basepc',hex(start)],
                           capture_output=True, text=True).stdout
        os.unlink(f.name); return o
    print(dis(0xFC9722, 0xFC9740))   # span 1's true alignment
    print(dis(0xFC9772, 0xFC9790))   # span 2's true alignment
    PY
