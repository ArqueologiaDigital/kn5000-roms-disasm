# Technics SX-WSA1R — fc = 28,000,000 Hz

Both TMP95C061AF run at the same fc. The number is **derived from the firmware**;
the service-manual parts list happens to contain a 28 MHz oscillator, but the
manual does not tie it to either processor and this document does not claim it
does.

Reproduce:

    python3 scripts/analysis/derive_system_clock.py

which re-reads every byte quoted below out of `original_ROMs/` and prints
PASS/FAIL per claim.

This is the value `mame-pr-wsa1/src/mame/matsushita/wsa1.cpp:117-118` is blocked
on: both `TMP95C061(config, ...)` lines are commented out with `<unknown>` for
the clock.

---

## The three levers, in order of strength

### Lever A (primary) — the ROM states fc in MHz, in one byte

prom_c does not hard-code a baud divisor. At **0xF991A2** it computes one:

    f9919f: 08 20 80        ldio TRUN,0x80
    f991a2: c2 ef ff ff 23  ld C,(0xFFFFEF)     ; M
    f991a7: cb ef 01        srl 1,C
    f991aa: cb cc 0f        and C,0x0F
    f991ad: f0 53 43        ld (BR0CR),C
    f991b0: 08 51 00        ldio SC0CR,0x00
    f991b3: 08 52 29        ldio SC0MOD,0x29    ; 8-bit UART, baud-rate generator

So `BR0CR = (M >> 1) & 0x0F`, i.e. divisor N = M/2 with tap select 0 (fc/4).
With the UART's own /16 oversampling:

    bit rate = fc / (N << 2) / 16 = fc / (32 * M)

**The scaling cancels.** 31250 comes out for *any* M provided
`fc = 1,000,000 * M`. The firmware's own rule therefore says M is fc in MHz.

`prom_c[0xFFFFEF] = 0x1C = 28`  ⇒  **fc = 28 MHz, asserted by the ROM.**

That byte is real configuration, not padding: it is the **only** value in the
0x6C-byte run of 0x0E (RET) between the vector table and the build tag that is
not 0x0E, and the same address is read again at `0xF98BA0 ld BC,(0xFFFFEF)`,
zero-extended and pushed as an argument to the call at 0xF98BA8. It is
converted, with this reasoning, as
`CLOCK_CONFIG_MHZ` in `prom_c/wsa1_prom_c.s`.

Note also that M = 0x18 (24) would give BR0CR = 0x0C, which is exactly prom_a's
boot value. The two constants in the images are the two members of one family.

This lever needs no decision about which of several BR0CR writes is "the
operative one", which is what makes it the primary one.

### Lever B — the sequencer tempo constant, 5·fc = 140,000,000

Independent of MIDI, of the UART and of the /16 oversampling.

prom_a's boot block programs 16-bit timer 4: `0xF82703 ldio T4MOD,0x05`
(bits[1:0] = 01 ⇒ φT1), `TREG4 = 0x0001`, `TREG5 = 0x3D09` = 15625,
`0xF8272A ldio TRUN,0xB7`. Vector 0x50 (INTTR4, 0xFFFF50) = **0xF82EA2**, a
musical clock that wraps its tick counter at **0x60 = 96 ticks per beat**
(`0xF82EB1 cp (XHL),0x60`), then counts beats into bars using the
beats-per-bar value at (0x605000) and the bar number at (0x605002).

The tempo setter at 0xFAA350:

    faa350: 9a 00 20        ld WA,(XDE+0x00)
    faa353: d8 cc ff 01     and WA,0x01FF
    faa357: d8 cf 28 00     cp WA,0x0028        ; BPM >= 40 ?
    faa35d: d8 cf 2c 01     cp WA,0x012C        ; BPM <= 300 ?
    faa368: 30 78 00        ld WA,0x0078        ; else default 120
    faa373: 32 40 00        ld DE,0x0040        ; 64
    faa376: da 40           mul XWA,DE          ; BPM * 64
    faa378: 42 00 3b 58 08  ld XDE,0x08583B00   ; 140,000,000
    faa37d: d8 52           div XDE,WA
    faa37f..faa38b:                             ; round half up
    faa38d: f0 32 52        ld (TREG5),DE

The range check is what pins the divide's operand as a BPM: 40 to 300, default
120. With φT1 = fc/8 and 96 PPQN,

    BPM = 60*fc / (768 * TREG5)   ⇒   TREG5 = 5*fc / (64 * BPM)

so the firmware's constant **must** be 5·fc:

    fc = 140,000,000 / 5 = 28,000,000 Hz

Self-checks inside this lever: boot TREG5 = 15625 → 140.0 BPM;
`0xFA5559 ld WA,0x4735` → 120.00 BPM fallback; `0xFA554A ld WA,0x1C7B` → 300.0
BPM clamp, and 140e6/(64·300) = 7291.67, exactly that constant.

Sensitivity: φT4 would give 112 MHz and φT16 448 MHz. Only φT1 is possible.

Uniqueness of the constant: the bytes `42 00 3b 58 08` occur **twice** in
prom_a, at 0xFAA378 and 0xFAA778 — and 0xFAA350-0xFAA39F and 0xFAA750-0xFAA79F
are byte-identical duplicates of the same routine — and nowhere in prom_b,
prom_c or prom_d. There is no competing constant.

### Lever C (corroboration only) — the MIDI bit rate

**SC0 of prom_a is the MIDI port**, proven by traffic: it writes the MIDI System
Real-Time status bytes straight into SC0BUF —

| addr | bytes | |
|---|---|---|
| 0xFA544F | `08 50 fc` | Stop |
| 0xFA5457 | `08 50 f8` | Timing Clock |
| 0xFA545F | `08 50 fe` | Active Sensing |
| 0xFA5467 | `08 50 fa` | Start |
| 0xFA546F | `08 50 fb` | Continue |
| 0xFA7D76 | `08 50 f6` | Tune Request |

A byte scan for `08 50 F0..FF` across all four images yields exactly those six
plus one false positive inside `ld XIY,0x00F95008` at 0xF94E4D, and nothing at
all in prom_b, prom_c or prom_d. The RX side reads SC0CR and masks 0x1C at
0xFA5497 — `sc0cr_r()` (`tmp95c061.cpp:1143-1149`) clears all but 0xE3 on read,
so 0x1C is exactly a read-and-clear error field — and tests the received byte
against 0xF7 (End of SysEx) at 0xFA54B6.
⚠ The names OERR/PERR/FERR and RXE appear **nowhere** in
`src/devices/cpu/tlcs900/`; they are recalled, not cited. The bit *positions*
are what is established.

The MIDI init at 0xFA58F2, quoted in full because an earlier pass silently
dropped its sixth instruction:

    fa58f2: 08 52 29           ldio SC0MOD,0x29
    fa58f5: 08 51 00           ldio SC0CR,0x00
    fa58f8: 08 53 0e           ldio BR0CR,0x0E     ; divide by 896
    fa58fb: c2 f8 ff ff 3f 24  cp (0xFFFFF8),0x24
    fa5901: 6e 03              jr NZ,0xFA5906
    fa5903: 08 53 0c           ldio BR0CR,0x0C     ; divide by 768 (not taken)
    fa5906: 08 77 5d           ldio INTES0,0x5D    ; <-- was missing
    fa5909: 08 50 fe           ldio SC0BUF,0xFE    ; Active Sensing
    fa590c: 06 00              ei 0x00
    fa590e: 0e                 ret

`prom_a[0xFFFFF8] = 0x02` — it is the byte in the build tag where a filename's
`.` would sit (`wsaa_822` + 0x02 + `ssf`; prom_d's tag is the plain filename
`wsad_54.ssf`, with `.` in that slot) — so the compare fails and BR0CR stays
0x0E. BR0CR = 0x0E gives N = 14, tap 0 = fc/4, /16 ⇒ bit rate = fc/896, and
31250 × 896 = 28,000,000.

`ldio INTES0,0x5D` immediately before pushing 0xFE is the same idiom the KN5000
sub CPU uses for *its* MIDI port (`ldio 0xEB,0x5D` then `ldio 0xD4,0xFE`), which
is worth knowing because that machine is the /16 validation below.

**Why this is corroboration and not the primary lever:** see the NULL.

---

## Where the prescaler taps come from — and why MAME is not the authority

There is no TMP95C061 databook in these trees. MAME contains **two mutually
inconsistent implementations of the same family's prescaler**, differing by 16×,
both fed by an identical `m_timer_pre += m_cycles`:

| | φT1 | φT4/φT16 … | source |
|---|---|---|---|
| `tmp94c241.cpp:1400-1403` | fc/8 | fc/32, fc/128, fc/2048 | shift constants T1=3, T4=5, T16=7, T256=11 |
| `tmp95c061.cpp:683-689` | fc/128 | fc/512, fc/2048 | `m_timer_pre >> 7 / >> 9 / >> 11` |
| `tmp95c063.cpp:263-269` | fc/128 | fc/512, fc/2048 | identical to tmp95c061 |

⚠ **Correction to an earlier pass**, which called tmp94c241 "the real
implementation" and the other two "not on the same scale". The tmp94c241 tap
constants and its `brNcr_w` formula were written **by this project** — MAME PR
#13220, "cpu/tlcs900: Added the TMP94C241 variant (used by the Technics
SX-KN5000)". Preferring them over the other two files is preferring this
project's own prior databook reading. That is not a citation; it is the same
opinion in C++.

**The firmware adjudicates instead, using a ratio that does not contain fc.**
prom_a tracks incoming MIDI tempo by counting timer-1 ticks between MIDI Timing
Clock bytes. The INTT1 handler (vector 0x44 -> 0xF82D0B) increments a saturating
counter at (0xA1):

    f82d4e: c0 a1 21  ld A,(0xA1)
    f82d51: c9 cf f1  cp A,0xF1
    f82d54: 6b 02     jr UGT,0xF82D58
    f82d56: c9 61     inc 1,A
    f82d58: f0 a1 41  ld (0xA1),A

and on each 0xF8 byte (`0xFA552F cp D,0xF8`) the tracker converts it:

    fa553e: c0 a1 21     ld A,(0xA1)
    fa5541: c9 cf 70     cp A,0x70        ; too slow -> TREG5 = 0x4735
    fa5546: c9 dc        cp A,4           ; too fast -> TREG5 = 0x1C7B
    fa5553: d8 09 d6 06  muls WA,0x06D6   ; TREG5 = 1750 * A
    fa555c: f0 32 50     ld (TREG5),WA
    fa555f: 08 a1 00     ldio (0xA1),0x00

Both TREG5 and that counter scale with fc, so the multiplier contains no fc; it
fixes only timer 4's tap against timer 1's. With 24 MIDI clocks per beat and 96
TREG5 ticks per beat,

    24 * A * TREG1 * D_T1 / fc  =  96 * 8 * TREG5 / fc
    =>  TREG5 = 24 * 28 * D_T1 / 768 * A ,   TREG1 = 0x1C = 28 (0xF826F4)
    T01MOD = 0x0D (0xF826EB) -> timer 1 clock select 3

⚠⚠ **RETRACTED 2026-08-25. LEVER B CANNOT ADJUDICATE THE TAP SCALE.**

This section used to print the table below and conclude "the ROM itself picks the
tmp94c241 scale":

| assumed scale | predicted constant | firmware uses 1750 |
|---|---|---|
| tmp94c241: select 3 = φT256, D_T1 = 2048 | **1792**·A | firmware 1750·A, 2.3% off |
| tmp95c061: select 3 = `>>15`, D_T1 = 32768 | **28672**·A | 16.4× off |

**The second row is wrong and the conclusion does not follow.** Let φT1 = fc/K.
Timer 1 runs on φT256 = fc/256K and timer 4 on φT1 = fc/K, so

    24·A·TREG1·(256K/fc) = 96·TREG5·(K/fc)   =>   TREG5 = 64·TREG1·A = 1792·A

and **K cancels**. 1792·A is the prediction under K = 8 *and* under K = 128 — the
ratio this lever measures is φT256/φT1, which is 256 on either scale. The "28672"
came from pairing THIS part's φT256 with the SIBLING TMP94C241's φT1, i.e. mixing
two devices' scales inside one equation.

What the 1750 does still say, and it is worth keeping: the ratio is 256, and the
2.3% shortfall from 1792 is the programmer rounding a 488.28 Hz tick to a nominal
500 Hz — 1750 = (fc/K)/(4·500) with fc/K = 3.5 MHz.

**WHAT REPLACES IT, and it is stronger.** The sequencer tempo divide. The firmware
computes `TREG5 = C/(64·BPM)` from a per-machine 32-bit constant, and equating
against `BPM = 60·fc/(96·K·TREG5)` gives `C = 40·fc/K`. Three machines, three
clocks, two CPU variants, K = 8 exactly with no rounding:

| machine | CPU | fc | C | address |
|---|---|---|---|---|
| SX-WSA1R | TMP95C061 | 28 MHz | 140,000,000 | prom_a `0xFAA378` |
| SX-KN1500 | TMP95C061 | 24 MHz | 120,000,000 | IC15 `0xFA6D85` |
| SX-KN5000 | TMP94C241 | 16 MHz | 80,000,000 | v10 `0xFCA34F` |

The three routines are instruction-for-instruction identical. ★ The KN5000 row is
what kills the circularity this file worried about elsewhere — that the TMP94C241
tap constants were written by this project — because that machine's clock is a
board fact (8 MHz crystal plus a documented internal doubler), so its firmware
confirms fc/8 independently of any MAME source.

Reproducer: `kn7000_mame/notes/wsa1-probes/tlcs900_prescaler_scale.py`, 42/42 checks.
Later corroborated by the TMP95C061 databook itself, found 2026-08-25.

The retraction is also carried in `kn7000_mame/src/mame/matsushita/wsa1.cpp`.

⚠ A second correction: an earlier pass listed "MAME does not implement 16-bit
timers 4-7 at all" as a gap. False for the file it leans on —
`tmp94c241.cpp:1553-1575` implements timers 4/6/8/A and decodes
`update_timer_count(4, m_t4mod & 3, T1, T4, T16)`. Only `tmp95c061.cpp` omits
them. Both halves of lever B's tap assumption are readable in code. **Upgrade to
established.**

### The UART's extra /16, validated on a machine with a known clock

`tmp94c241_serial.cpp:303-318`:

```c
const uint16_t divisor = data & 0x0f;
const uint8_t shift_amount = (((data >> 4) & 3) + 1) * 2;
m_hz = clock() / (divisor << shift_amount);
```

with `clock()` = fc (`DERIVED_CLOCK(1,1)`, `tmp94c241.cpp:819-820`). Taps fc/4,
fc/16, fc/64, fc/256. End to end, including the /16, on the KN5000:

    ldio 0xD6,0x29   ; SC1MOD = 8-bit UART
    ldio 0xD5,0x00   ; SC1CR
    ldio 0xD7,0x0A   ; BR1CR = 0x0A
    ldio 0xEB,0x5D   ; INTES1
    ldio 0xD4,0xFE   ; SC1BUF <- MIDI Active Sensing
      (../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s:11747-11751)

    20,000,000 / (10 << 2) / 16 = 31,250.000 exactly

with the sub CPU clocked at `2*10_MHz_XTAL` (`kn5000.cpp:382`).

⚠ **Correction:** an earlier pass called this "the KN5000 control-panel link".
Wrong channel. The control-panel link is on the **main** CPU's SC1
(`kn5000.cpp:367-368` wires `m_cpanel->txd()` to `m_maincpu` rxd1/sioclk1) and
runs SCLK-driven, not as a 31250-baud UART. The registers cited (0xD4-0xD7) are
the **sub** CPU's, and the line that follows them pushes MIDI Active Sensing —
so it is a MIDI port, and the validation is *stronger* than the old sentence
claimed, but the sentence naming it was wrong.

---

## The NULL — what each lever can and cannot exclude

Lever C's divisor alone does not pin fc. With bit rate = fc/896 and MIDI 1.0's
±1% tolerance:

| tolerance | fc window | catalogue parts inside |
|---|---|---|
| ±1% | 27.720 – 28.280 MHz | 28.000 (+0.00%), **28.224** (+0.80%, = 640 × 44.1 kHz) |
| ±2% | 27.440 – 28.560 MHz | as above |
| ±3% | 27.160 – 28.840 MHz | as above, plus 28.63636 (8 × NTSC fsc, +2.27%) |

Lever B excludes them exactly: the constant would have to be 141,120,000 for
28.224 MHz and 143,181,818 for 28.63636 MHz. It is 140,000,000.

**And there is a worse ambiguity that only lever B closes.** The two boot ROMs
both program a ÷768 divisor before the runtime routine corrects it — prom_a
`0xF82754 ldio BR0CR,0x0C`, prom_c `0xFFF078 ldio BR0CR,0x13`, two encodings of
the same ÷768 — and 896/768 = 28/24 exactly. **24 MHz + ÷768 is a fully
self-consistent alternative reading of the boot writes**, and the service manual
parts list contains `QSXG2F2400A CERAMIC OSCILLATOR` (OCR line 3105), a 24 MHz
part of the very same family as the 28 MHz one, physically present in this
machine's BOM. Lever C cannot choose between 28 and 24; only lever B can
(5 × 24e6 = 120,000,000 ≠ 140,000,000, and no power-of-two tap of 24 MHz gives
3.5 MHz).

⚠ This inverts an earlier pass's weighting. **Lever B is a primary lever and
lever C is corroboration**, not "lever C bounds and lever B breaks a tie between
28.000 and 28.224". Likewise, "that a 24 MHz variant physically exists is an
inference" was too weak: the oscillator is in the parts list.

**Residual ×2 risk — NOT closed.** An earlier pass said a factor-of-two error in
the whole prescaler chain (14 or 56 MHz) was "excluded by the parts list". A
parts list cannot exclude a ×2, because the candidate is an *internal clock
doubler*, downstream of the crystal — this very project models the sibling
TLCS-900 part that way (`kn5000.cpp:381-382`,
`// Note: The CPU has an internal clock doubler` / `TMP94C241(config, m_subcpu,
2*10_MHz_XTAL)`). The correct, weaker statement: no 14 MHz part appears in the
list, so the doubler hypothesis has no crystal to stand on. That is evidence,
not exclusion. It does not affect the derived **fc**, which is what every
divisor in the firmware is expressed against; it affects only what one would
write as the XTAL if a driver ever models the doubler explicitly.

---

## Every BR0CR and TREG5 writer, exhaustively

A byte scan for both store encodings across all four images:

| | real writes | false positives |
|---|---|---|
| BR0CR (`08 53 xx`, `f0 53 xx`) | prom_a **3**: 0xF82754 = 0x0C (boot), 0xFA58F8 = 0x0E, 0xFA5903 = 0x0C (conditional, not taken). prom_c **2**: 0xFFF078 = 0x13 (boot), 0xF991AD = computed | every other hit is a `ld (Xrr+0x08),HL` whose middle bytes read `08 53` — checked individually at 0xFE4411, 0xFA6DAE, 0xFA6DC9, 0xFA6F3D — or text in prom_d |
| TREG5 (`08 32/33 xx`, `f0 32 5x`) | prom_a **4**: 0xF82712/0xF82715 (boot), 0xFA555C, 0xFAA38D, 0xFAA78D | 0xF9132F and 0xFE581E are data |

No competing constant exists anywhere. The "asserted from a single write"
objection was checked and does not apply.

⚠ One thing that *is* weaker than an earlier pass claimed: **"the operative
BR0CR is 0x0E" is demonstrated for prom_c and only strongly probable for
prom_a.** prom_c's 0xF991A2 is reached from a straight-line init chain
(`0xF98B7D link XIZ,0xFFC8` then seven calls, the fifth being
`0xF98B91 call 0xF9919F`). prom_a's 0xFA58F2 is entered at 0xFA58F0 via `calr`
from 0xFA58C1, inside a routine at 0xFA58BE whose **only** reference in prom_a
or prom_b is a 4-byte thunk-table slot, `0xFA540C jp 0xFA58BE`. There is no
direct call to it. Lever A does not depend on this at all, which is the other
reason it is primary.

---

## The service manual — coincidence, not confirmation

The parts list carries `x1 QSXG2F2800A CERAMIC OSCILLATOR` (OCR line 3098), and
a lone `(28MHz)` token appears at line 1807. The derived fc coincides with it.

That is all that can be said. It carries **six** oscillators —
`EFOEC8004A5 8MHz` (3099), `QSXG1A2500A 25MHz` (3101), `QSXG113386A` (3103,
value unreadable), `QSXG2F2400A` (3105), `EFOEC4004A3 4MHz` (3812) — the
`(28MHz)` token sits on a schematic sheet whose OCR neighbourhood is scrambled
photocopy, and this project's own driver says twice that the manual "never
states which of the oscillators in the parts list clocks which device"
(`mame-pr-wsa1/src/mame/matsushita/wsa1.cpp:19-24` and `:121`).

⚠ **Correction:** an earlier pass wrote "X1 QSXG2F2800A '(28MHz)' — agrees
exactly, /1. Not /2, not ×2, the same number." Drop that. The right sentence for
anything downstream, including the MAME driver line, is:

> fc = 28.000 MHz, derived from firmware. The parts list contains a 28 MHz
> ceramic oscillator, X1, which the manual does not tie to either CPU.

---

## Stated gaps

* No TMP95C061 databook. Every tap value rests on MAME's TMP94C241 code, which
  is this project's own earlier reading, adjudicated here by the firmware's
  fc-independent 1750 ratio to within 2.3%.
* An internal clock doubler cannot be ruled out (above). It changes the XTAL a
  driver would name, not fc.
* prom_c shows no MIDI real-time traffic on SC0, so its ÷896 is evidence that
  both CPUs share fc, not a second independent 31250 proof.
* DREFCR = 0x71 on both CPUs and DMEMCR = 0x8D / 0x89 are the same family of
  value on both — further evidence of a shared clock — but neither register can
  be decoded into a refresh period. MAME stubs both.
