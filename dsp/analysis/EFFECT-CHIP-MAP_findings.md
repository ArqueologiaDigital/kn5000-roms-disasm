# GATE H0 — the UI-name → algorithm-slot → CHIP → image-hash table, and an executable capture protocol

Technics SX-KN5000. Two effect DSPs: **IC311 = NEC uPD6383GF-3BA**, **IC310 = Matsushita MN19413**.
Date: **2026-07-31**. **Read-only pass. No build, no MAME run, no commit, no existing file edited.**
Nothing here is an audio claim — this pass cannot produce audio and does not assert any.

Everything below is derived from the ROMs by
`scratchpad/h0_verify_effectchipmap.py` (stdlib + the research tree's own
`kn5000_dsp_extract`). Sources, all read-only:

| what | where |
|---|---|
| algorithm → effect **name** | `v10/maincpu/ui_widgets/naka_widget_descriptors.c`, widget array `ptrs_0[algo] = str_(127-algo)` |
| algorithm → **program stream** | `original_ROMs/kn5000_subprogram_v142.rom`, pointer table `0x0001ED7C` (100 × u32) |
| algorithm → **parameter stream** | same ROM, pointer table `0x0001EF0C` |
| front-panel **DSP EFFECT** list | `original_ROMs/kn5000_v10_program.rom` **file offset `0x4465C`** (forward, 0xFF-terminated) + `0x446DC` (inverse, 128 bytes) |
| front-panel **DIGITAL REVERB** list | same ROM, **`0x4475C`** (forward) + `0x447DC` (inverse) |
| the machine's own walk | `dsp/analysis/data/typewalk/kn5000_dsp1_upload.txt` |

---

## 0. Headline — six results, three of them corrections to material this pass was handed

1. ★★★ **The front-panel effect lists are TABLES IN THE MAIN ROM and they settle every open
   index question.** The DSP EFFECT page's list is 38 bytes of algorithm numbers at file offset
   `0x4465C`, followed at `+0x80` by its own **inverse** table; the DIGITAL REVERB page's list is
   the same structure at `0x4475C`. Forward and inverse agree entry-for-entry, and the byte
   sequences are **identical in v7, v9 and v10**. No emulator run is needed, ever again, to know
   which TYPE index loads which algorithm.
2. ★★★ **`TYPE_MAP.md` is wrong in three places at once, and `TYPELAST=36` is wrong.** The list
   has **38 entries, 0..37**. Row 14 is **SLOW ATTACKER (a37)**, not "NO OPERATION" — the image
   matcher saw NO OPERATION's bytes because SLOW ATTACKER *ships* that image. Rows 19/20 are
   **ROTARY SPEAKER (a53)** then **ROCK ROTARY (a15)** — two different front-panel effects sharing
   one byte-identical image, not one effect listed twice. And **`PEQ+DIST+DELAY` (a98) is missing
   from the map entirely**, at TYPE 36; the top rail is **TYPE 37 = PEQ+OVERDR+DELAY**.
3. ⛔ **The brief's anchor "`a99 PEQ+OVERDR+DELAY` at 28→36, the top rail" is FALSE, and so is
   `TYPELAST=36`.** `a99` is at **TYPE 37**. Consequence for the build lane, stated plainly:
   `type_select.lua` saturates UP to the *real* top (37) and steps down `(TYPELAST − TYPEIDX)`
   times, so with `TYPELAST=36` every landing is **`TYPEIDX + 1`** — `TYPEIDX=28` lands on
   **TYPE 29 = `a71 PEQ+CHORUS`**, not `a70`. The other four anchors the brief gave
   (`a10`@8, `a39`@15, `a70`@28, TYPE 6 = GATED REVERB) are **correct**.
4. ⛔ **The brief's "algorithms 57–60 drive BOTH chips" is FALSE** — and this repo already knew:
   `second-dsp-and-ready.md` item **B2** falsified it on 2026-07-27. Independently re-derived here:
   57–60's program streams are a *single* `op-E` record with `cmd 0x30` and **no IC311 traffic at
   all**. The chip partition is **IC311 91 / IC310 9 / both 0**, and the nine are
   **57, 58, 59, 60, 79, 88, 89, 90, 91**. `pat_corpus.MALFORMED = {79,88,89,90,91}` is not the
   IC310 set — it is the subset of IC310 streams that survives an IC311-shaped parser.
5. ⛔ **`effect-selection-recipes.json` is a KN7000 artefact and must not be used for a KN5000
   sitting.** Its port tags (`:SEG00`, `:SEG0F`, `:SEG11`…) are the *KN7000* driver's ioports as
   they existed at `kn7000_mame@8c8fda8`; the KN5000 panel has never had them (it uses
   `CPL_SEGn`/`CPR_SEGn`). The strategic review's "the raw material exists — 224 recipes" points at
   the wrong instrument. The KN5000 navigation used below comes from `kn5000-dsp-paramlist.md`
   and `dsp/tools/{type_enum,type_select,reverb_select,peq_select}.lua`, which are KN5000.
6. ★★ **The project already held the answer to gate H0 and never joined it up.**
   `kn7000_mame/notes/kn5000-dsp-paramlist.md` §2–3 is a **live, pixel-verified** capture of both
   pages — "DSP EFFECT … **38** effects", "DIGITAL REVERB … 12 reverbs + SINGLE DELAY + MULTI TAP
   DELAY", and a 38-row table whose row 14 is SLOW ATTACKER, rows 19/20 ROTARY SPEAKER / ROCK
   ROTARY, and row 37 "last entry, selector saturates here". It agrees with the ROM tables
   **entry for entry**. Two independent routes, one static and one live, and the DSP lane's
   `TYPE_MAP.md` disagrees with both.

---

## 1. SELF-TEST FIRST (★★★ RULE 20)

28 checks. **25 PASS, 3 FAIL — two of the failures are deliberate** (they are the brief's two
wrong anchors, asserted so the reader can see them fail rather than take my word), and the third
is a genuine, benign ROM anomaly reported rather than hidden.

```
-- T1  name table: name(algo) = str_(127-algo) via ptrs_0 ; 40 known answers
  PASS  programs.tsv effect_name == ptrs_0 name (40 reps)          got=[] want=[]

-- T2  the two front-panel lists are self-inverse
  PASS  DSP EFFECT forward length                                  got=38 want=38
  PASS  DSP EFFECT inverse agrees at every entry                   got=True
  FAIL  DSP EFFECT inverse != 0xFF exactly on the listed algos     extra: algo 7
  PASS  DIGITAL REVERB forward length                              got=14 want=14
  PASS  DIGITAL REVERB inverse agrees at every entry               got=True
  PASS  DIGITAL REVERB inverse != 0xFF exactly on the listed algos got=[9,10,16..27]

-- T3  the anchors the brief supplied
  PASS  TYPE 0 == CHORUS
  PASS  TYPE 6 == GATED REVERB
  PASS  a10 MULTI TAP DELAY at TYPE 8                              got=8
  PASS  a39 PARAMETRIC EQ    at TYPE 15                            got=15
  PASS  a70 AUTO WAH+S.DELAY at TYPE 28                            got=28
  ---- the two the brief got WRONG (both FAIL on purpose) ----
  FAIL  brief: a99 PEQ+OVERDR+DELAY at TYPE 36                     got=37 want=36
  FAIL  brief: TYPELAST == 36                                      got=37 want=36

-- T4  cross-version control: v7 / v9 / v10 carry identical lists   6/6 PASS

-- T5  the machine's own upload walk, matched to ROM images
  PASS  body uploads captured at I-RAM[84..]                       got=37 want=37
  PASS  every upload matches a ROM image                           got=0 unmatched
  PASS  walk is a subsequence of the ROM list                      got=[]
  PASS  ROM entries the walk never reached      got=[(36,'PEQ+DIST+DELAY')]

-- T6  negative controls (a census printing a clean zero must be able to fail)
  PASS  NO OPERATION (a00) absent from the DSP EFFECT list          got=False
  PASS  SLOW ATTACKER (a37) present in the DSP EFFECT list          got=True
  PASS  a16..a27 absent from the DSP EFFECT list                    got=[]
  PASS  no IC310 algorithm on either front-panel list               got=[]
```

**T2's real failure**, stated rather than hidden: the DSP EFFECT **inverse** table holds `0x00` at
algorithm **7**, which is not in the forward list. Algorithm 7 is an unnamed `----------` slot
carrying the NO-OPERATION image, so the stale byte would alias it to TYPE 0 if anything ever asked;
nothing does, because selection goes forward-list → algorithm. It is a firmware table artefact, and
it is the only inconsistency in 256 bytes of the two tables.

**T5 is the load-bearing control** and it earns its keep: the walk in
`data/typewalk/kn5000_dsp1_upload.txt` is a **37-of-38 subsequence** of the ROM list, in order,
with exactly one entry never reached — **TYPE 36 `PEQ+DIST+DELAY`**. That is the walk *dropping one
of its 40 UP presses*, the failure mode §193 documented. `PREDICT_S1_hi12_bench.md` §2.1 built its
reconstruction from that walk and therefore inherited the dropped press, concluding "37 entries,
0..36 ⇒ `TYPELAST=36` is correct". The ROM says 38, 0..37 — and the live paramlist capture agrees
with the ROM. **A walk that can drop a press cannot establish a list's length; a ROM table can.**

---

## 2. TABLE A — the **DSP EFFECT** page (`RAM[0x8D38]` page type `0x0B`), **38** entries

Every row: IC311, effect **unit 0**, load address I-RAM **84**. `hash` = first 16 hex of the
SHA-256 of the exact uploaded image (5-byte 36-bit words, as sent — the same bytes the capture
files carry). "STUB" = image byte-identical to NO OPERATION (`2baadb775ff5eb84`, 49 words).

| TYPE | algo | front-panel name (as displayed) | chip | unit | words | image hash | stub |
|---:|---:|---|---|---:|---:|---|---|
| 0 | 1 | `CHORUS` | IC311 | 0 | 70 | `26fb1f81b7d1fc1a` | |
| 1 | 2 | `MODULATED CHORUS` | IC311 | 0 | 85 | `767c3fa41ed788bc` | |
| 2 | 3 | `ENHANCER` | IC311 | 0 | 99 | `4a87e97d88939b5f` | |
| 3 | 4 | `FLANGER` | IC311 | 0 | 65 | `298cd2d002d09992` | |
| 4 | 5 | `PHASER` | IC311 | 0 | 106 | `b51afe0917a6ff03` | |
| 5 | 6 | `ENSEMBLE` | IC311 | 0 | 96 | `0a7e6b2a8a78744b` | |
| 6 | 8 | `GATED REVERB` | IC311 | 0 | 102 | `61cd5e3e77078d4e` | |
| 7 | 9 | `SINGLE DELAY` | IC311 | 0 | 48 | `93c49f84cf2ff34c` | |
| 8 | 10 | `MULTI TAP DELAY` | IC311 | 0 | 68 | `fb8d5fc907df5ac1` | |
| 9 | 32 | `DISTORTION` | IC311 | 0 | 42 | `94cc29d98d2637cf` | |
| 10 | 33 | `OVERDRIVE` | IC311 | 0 | 63 | `b37e72694b822d9d` | |
| 11 | 34 | `FUZZ` | IC311 | 0 | 42 | `b7c19817fdb567a4` | |
| 12 | 35 | `EXCITER` | IC311 | 0 | 69 | `6635c485e535a299` | |
| 13 | 36 | `COMPRESSOR` | IC311 | 0 | 40 | `eb855c73f3ba2529` | |
| **14** | **37** | **`SLOW ATTACKER`** | IC311 | 0 | 49 | `2baadb775ff5eb84` | ★ **STUB** |
| 15 | 39 | `PARAMETRIC EQ` | IC311 | 0 | 105 | `ef1c4c53056f87cb` | |
| 16 | 48 | `AUTO PAN` | IC311 | 0 | 50 | `8165346261e57684` | |
| 17 | 50 | `VIBRATO` | IC311 | 0 | 53 | `0501161fe58e5a73` | |
| 18 | 52 | `AUTO WAH` | IC311 | 0 | 72 | `bbc6e5016de722b8` | |
| **19** | **53** | **`ROTARY SPEAKER`** | IC311 | 0 | 86 | `338de6176e6b629e` | |
| **20** | **15** | **`ROCK ROTARY`** | IC311 | 0 | 86 | `338de6176e6b629e` | |
| 21 | 54 | `RING MODULATOR` | IC311 | 0 | 46 | `a724e214f1de9924` | |
| 22 | 56 | `MIX UP` | IC311 | 0 | 64 | `f9b776a57b4f02c7` | |
| 23 | 64 | `S.DELAY+CHORUS` | IC311 | 0 | 95 | `47c2dd0d32d4278e` | |
| 24 | 65 | `S.DELAY+S.DELAY` | IC311 | 0 | 68 | `50e5265c5bcf3589` | |
| 25 | 66 | `S.DELAY+FLANGER` | IC311 | 0 | 100 | `741aad883de12e65` | |
| 26 | 67 | `S.DELAY+VIBRATO` | IC311 | 0 | 86 | `dda918088ec486b9` | |
| 27 | 68 | `S.DELAY+PHASER` | IC311 | 0 | 110 | `774282d3dbb5ecbe` | |
| 28 | 70 | `AUTO WAH+S.DELAY` | IC311 | 0 | 105 | `9dcf538c662e480a` | |
| 29 | 71 | `PEQ+CHORUS` | IC311 | 0 | 93 | `e664b1170918011e` | |
| 30 | 72 | `PEQ+S.DELAY` | IC311 | 0 | 54 | `111bf7acba74b641` | |
| 31 | 73 | `PEQ+FLANGER` | IC311 | 0 | 91 | `b1570c165bbd099e` | |
| 32 | 74 | `PEQ+VIBRATO` | IC311 | 0 | 77 | `af9c6b7339cd08aa` | |
| 33 | 75 | `PEQ+COMPRESSOR` | IC311 | 0 | 59 | `9499e535edfaaa6e` | |
| 34 | 96 | `PEQ+COMPR+DIST` | IC311 | 0 | 90 | `6730dd3270278cd1` | |
| 35 | 97 | `PEQ+COMPR+OVERDR` | IC311 | 0 | 97 | `9556e78800563792` | |
| **36** | **98** | **`PEQ+DIST+DELAY`** | IC311 | 0 | 92 | `16fc07e39be1aa10` | (never reached by the walk) |
| **37** | **99** | `PEQ+OVERDR+DELAY` | IC311 | 0 | 104 | `1bb30a69eb2f000d` | **top rail** |

★ **`SLOW ATTACKER` is the one row that decides the review's take (c).** It is at **TYPE 14**, it
**is** front-panel selectable, and it **is** a stub: 49 words byte-identical to NO OPERATION. It
nevertheless has a **full five-parameter editor page** — `THRESHOLD, ATTACK RATE(s), RELEASE
RATE(s), VOLUME, REV SEND` (`kn5000-dsp-paramlist.md` §3 row 14, captured live off the LCD). A
named effect with a real parameter UI and a do-nothing program is exactly what the standing
prediction says, and the hardware can falsify it in ten seconds.

---

## 3. TABLE B — the **DIGITAL REVERB** page (page type `0x0A`), **14** entries

The twelve reverbs are **effect unit 1**, load address I-RAM **200**, and — as `programs.tsv:14`
says — **one single image serves all twelve**; only the coefficient payload differs. The last two
entries are the *unit-0* delays re-offered on this page with the trailing `REV SEND` slot dropped.

| TYPE | algo | front-panel name | chip | unit | load | words | image hash |
|---:|---:|---|---|---:|---:|---:|---|
| 0 | 16 | `ROOM REVERB 1` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 1 | 17 | `ROOM REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 2 | 18 | `PLATE REVERB 1` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 3 | 19 | `PLATE REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| **4** | **20** | **`CONCERT REVERB 1`** | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 5 | 21 | `CONCERT REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 6 | 22 | `DARK REVERB 1` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 7 | 23 | `DARK REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 8 | 24 | `BRIGHT REVERB 1` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 9 | 25 | `BRIGHT REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 10 | 26 | `WAVE REVERB 1` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 11 | 27 | `WAVE REVERB 2` | IC311 | 1 | 200 | 133 | `786520e880238608` |
| 12 | 9 | `SINGLE DELAY` | IC311 | **0** | 84 | 48 | `93c49f84cf2ff34c` |
| 13 | 10 | `MULTI TAP DELAY` | IC311 | **0** | 84 | 68 | `fb8d5fc907df5ac1` |

**CONCERT REVERB 1 is TYPE 4 on this page**, matching `reverb_select.lua`'s screen-verified
`REVIDX=4`. It is also the **cold-boot default** for unit 1 (§227 item G, 256-of-256 C-RAM cell
match against an independent screen-verified run) — so *doing nothing at all after power-on already
puts the machine in take (a)'s reverb state*.

---

## 4. TABLE C — **IC310 (MN19413)**: nine algorithms, none of them on either list above

⚠ **This is the table gate H0 exists for.** "ROOM" is an IC310 name (`a88`); the IC311 reverbs are
"ROOM REVERB **1**/**2**". A capture that selects "ROOM" from the wrong screen measures the wrong
chip. IC310 is also the chip **in line with the main mix** (`IC303 SDO0 → IC310 SDI`,
`IC310 SDO1/SDO2 → IC313 PCM69AU DAC`), so it colours *everything* that leaves the line outputs.

| algo | name | record framing | load addr | words | image hash | front-panel path |
|---:|---|---|---:|---:|---|---|
| 57 | `STANDARD` | `op-E`, `cmd 0x30` | — | — | (one image, 177 × 32-bit @1336, per `second-dsp-and-ready.md` B8) | **ACOUSTIC ILLUSION** page (type `0x0E`), TYPE 1 of 4 |
| 58 | `PERCUSSIVE` | `op-E`, `cmd 0x30` | — | — | same image | ACOUSTIC ILLUSION, TYPE 2 |
| 59 | `SYMPHONIC` | `op-E`, `cmd 0x30` | — | — | same image | ACOUSTIC ILLUSION, TYPE 3 |
| 60 | `DEEP SPACE` | `op-E`, `cmd 0x30` | — | — | same image | ACOUSTIC ILLUSION, TYPE 4 |
| 79 | `GEQ` | `op-3`, `cmd 0x30` | 1520 | 48 | `ae8ba70527189c3d` | **EQUALIZER** page (type `0x0C`) — INFERRED, see §6 |
| 88 | `ROOM` | `op-3`, `cmd 0x30` | 3376 | 132 | `01d328127deac265` | **UNRESOLVED** |
| 89 | `KARAOKE` | `op-3`, `cmd 0x30` | 3376 | 132 | `01d328127deac265` | **UNRESOLVED** |
| 90 | `BATH ROOM` | `op-3`, `cmd 0x30` | 3376 | 132 | `01d328127deac265` | **UNRESOLVED** |
| 91 | `STAGE` | `op-3`, `cmd 0x30` | 3376 | 132 | `01d328127deac265` | **UNRESOLVED** |

The hash column for 57–60 is deliberately empty: their program record is `op-E`, which the
project's extractor does not decode into words, so this pass has **no byte-accurate image** for
them — only `second-dsp-and-ready.md` B8's sizing. Reporting a hash I did not compute would be the
kind of relayed fact the review told us to stop producing.

**57–60 are a shared-image/four-preset family exactly like the twelve reverbs** — one program
stream pointer (`0x00183F5`) for all four, four different parameter-stream pointers.

---

## 5. TABLE D — the stubs, and which of them a human can actually reach

**42 algorithm slots share the 49-word NO-OPERATION image** (`2baadb775ff5eb84`). Thirteen of them
carry a real name; one of those thirteen *is* NO OPERATION itself, so the project's "twelve named
stub effects" is **confirmed exactly, 12/12**:

| algo | name | reachable from a front-panel list? |
|---:|---|---|
| 0 | `NO OPERATION` | no (the reference image, not a stub) |
| 11 | `MODULATION DELAY` | **no** |
| **37** | **`SLOW ATTACKER`** | ★ **YES — DSP EFFECT TYPE 14** |
| 38 | `NOISE FLANGER` | **no** |
| 44 | `CEL` | **no** |
| 45 | `CELM` | **no** |
| 49 | `PITCH SHIFTER` | **no** |
| 51 | `PEDAL WAH` | **no** |
| 55 | `HARS EFFECT` | **no** |
| 63 | `STRING` | **no** |
| 69 | `PEDAL WAH+DELAY` | **no** |
| 80 | `DS_D` | **no** |
| 81 | `OVER_D` | **no** |

★★ **Of the twelve named stubs, exactly ONE is selectable from the two array-driven editor pages,
and it is SLOW ATTACKER.** `ROADMAP §H2`'s alternative — "and PITCH SHIFTER if selectable" — is
answered: **PITCH SHIFTER is not on either list**, so H2 reduces to SLOW ATTACKER alone.
(Caveat, honestly labelled: this pass enumerated the **two array-driven editor pages**. A Sound
Memory / registration recall or a SysEx write could in principle set an arbitrary algorithm number;
that path was **not** audited. So "no" here means "not selectable by walking the TYPE list", not
"unreachable by any means".)

---

## 6. Denominators, and the rows I could not resolve

| population | count |
|---|---:|
| algorithm slots in the pointer table | 100 |
| slots with a name that is not `----------` | **71** |
| **IC311** algorithms | **91** |
| **IC310** algorithms | **9** |
| algorithms driving both chips | **0** |
| distinct IC311 program images | **38** |
| unit-1 (load 200) algorithms | 12 (all one image) |
| **rows produced with a resolved front-panel index** | **52** (38 DSP EFFECT + 14 DIGITAL REVERB) = **50 distinct algorithms** (SINGLE DELAY and MULTI TAP DELAY appear on both pages) |
| rows produced with a resolved page but **no list index** | **5** (IC310: 57–60 on ACOUSTIC ILLUSION, 79 on EQUALIZER) |
| **UNRESOLVED rows** | **4** |

**The four unresolved rows, and why** — `a88 ROOM`, `a89 KARAOKE`, `a90 BATH ROOM`, `a91 STAGE`.
Chip (IC310), load address (3376), word count (132) and image hash (`01d328127deac265`) are all
**resolved**; what is not resolved is **which screen selects them**. They are not on either
array-driven page, and no third forward/inverse list table exists in the main ROM (a scan for a
128-byte inverse table holding `0..3` at indices 88..91 returns only alignment artefacts of the two
known records). The leading candidate is the **REVERB & EQ PRESETS** page (type `0x09`,
`kn5000-dsp-paramlist.md` §2: *"preset selector, no per-param array"*), which would explain both
the absent list table and why an IC310 reverb+EQ preset family is named
ROOM/KARAOKE/BATH ROOM/STAGE — but that is a hypothesis, not a measurement, and it is filed here as
**OPEN**, not smoothed over. Two further items are **INFERRED, not measured**:
`EQUALIZER page ⇒ a79 GEQ` (the page is IC310-shaped and GEQ is IC310's only EQ, but no capture ties
them), and the ACOUSTIC ILLUSION ordering `STANDARD/PERCUSSIVE/SYMPHONIC/DEEP SPACE = 57/58/59/60`
(the LCD names and the algorithm names match in order; the binding is not captured).

---

## 7. WHERE TO RECORD FROM — settled

**Record the rear main L/R line outputs.** Signal path, from `dsp-audiopath-wiring.md` (service
manual pp. 28/35, MEASURED):

```
   IC303 (tone gen) ──SDOA/SDOB──► IC311 DI1/DI2      [IC311 = a SEND/RETURN INSERT]
   IC311 DO1/DO2 ───220Ω────────► IC303 SDIA/SDIB     [the wet return]
   IC303 SDO0 ──────470Ω────────► IC310 SDI           [IC310 = IN LINE WITH THE MIX]
   IC310 SDO1/SDO2 ─────────────► IC313 PCM69AU DAC ──► IC314A/B ──► LOUT / ROUT
   IC311 DO3 ───────220Ω────────► leaves the block ──► HD-AE5000 expansion
```

* **Do NOT try to capture DO3.** It is the HD-AE5000 feed, not the main mix, and — checked at
  `kn7000_mame` HEAD — the emulator writes `m_do[unit][…]` only at
  `src/devices/cpu/upd6383/upd6383.cpp:2618-2619` with `unit ∈ {0,1}`; the one site that could
  write `m_do[2]` (`:3136`) sits inside `if (false && …)` and is dead. So **`m_do[2]` is never
  written and a DO3 capture has no emulated comparand**, exactly as the review said. (The review's
  line numbers `2475/2476` are stale; the claim is right, the citation is not — relay the fact, not
  the line.)
* **IC310 contamination is unavoidable on the line out** and must be minimised rather than removed:
  ACOUSTIC ILLUSION **off**, master EQUALIZER **flat**, microphone **unplugged**, MIC/echo level
  **zero**. Note the setting of anything you cannot identify.
* **Standing "DO3 only" is an *emulator* measurement rule** (do not grade the DSP on the speaker
  mix), and it does not transfer to hardware, where DO3 is not even brought out unless the
  HD-AE5000 is fitted. Recording the line out is the correct hardware choice.
* ⚠ **Framing, so the take is not oversold.** IC311 currently produces **no emulated audio at all**
  — the output stage is a proven null (`OUTPUT-STAGE-NULL_findings.md`). So these recordings are
  **not** an A/B against the emulator today. Their value is as **ground truth that constrains the
  ISA**: a measured T60 gives the per-pass loop gain numerically (the number §43/§49/§53 guessed
  wrong three times), and measured early-reflection times give the delay-line lengths directly.

---

## 8. THE CAPTURE PROTOCOL, made executable

### 8.0 Navigation primitives (KN5000, MEASURED — `kn5000-dsp-paramlist.md` §1, `control-panel-protocol.md`)

| what to press | on the panel | MAME port (for an agent replaying it) |
|---|---|---|
| open the SOUND menu | the **SOUND** button in the MENU block | `CPR_SEG10` `0x04` |
| → **DSP EFFECT** editor | LCD **right-hand soft key #4** | `CPL_SEG7` `0x02` (page type `0x0B`) |
| → **REVERB** editor | LCD **right-hand soft key #2** | `CPL_SEG8` `0x02` (page type `0x0A`) |
| → EQUALIZER | LCD right soft key #3 | `CPL_SEG8` `0x01` (page type `0x0C`) |
| → ACOUSTIC ILLUSION | LCD right soft key #5 | `CPL_SEG7` `0x01` (page type `0x0E`) |
| TYPE **up / down** | bottom soft keys **UP-1 / DOWN-1** | `CPL_SEG10` `0x20` / `0x10` |
| **DSP EFFECT** on/off | the dedicated **DSP EFFECT** button | `CPR_SEG3` `0x04` |
| **DIGITAL REVERB** on/off | the dedicated **DIGITAL REVERB** button | `CPR_SEG3` `0x08` |
| **ACOUSTIC ILLUSION** on/off | the dedicated **ACOUSTIC ILLUSION** button | `CPR_SEG3` `0x10` |
| DIGITAL EFFECT on/off | the dedicated **DIGITAL EFFECT** button | `CPR_SEG3` `0x02` |

The TYPE list **does not wrap** — it saturates at both ends. So the reliable way to land on an
index is: **hold the TYPE-down key until the name stops changing (you are at TYPE 0), then press
TYPE-up exactly N times.** Felipe has already confirmed live that ~56 extra presses at the end do
nothing.

⚠ **The review's (a) is self-contradictory as written** — "CONCERT REVERB 1 … with master/panel
reverb at minimum". CONCERT REVERB 1 **is** the panel reverb (IC311 unit 1). What must be at
minimum is **IC310's** ambience. The protocol below fixes that, and fixes take (b): the toggle to
press for a *reverb* A/B is **DIGITAL REVERB**, not **DSP EFFECT**.

### 8.1 Common setup (do once, ~5 min)

1. **Power on and change nothing else.** Cold boot already loads **CHORUS on unit 0** and
   **CONCERT REVERB 1 on unit 1**.
2. Turn **OFF**, by their dedicated buttons: **DSP EFFECT**, **DIGITAL EFFECT**, **ACOUSTIC
   ILLUSION**. Leave **DIGITAL REVERB ON**. (Their LEDs are the confirmation.)
3. Unplug the microphone; MIC volume to zero.
4. SOUND menu → **EQUALIZER**: confirm all four bands at **0 dB**. Leave it.
5. Play with **one part only** (RIGHT 1); turn LEFT / RIGHT 2 / accompaniment off. No rhythm, no
   sequencer.
6. Record from the **rear L/R line outputs**, 24-bit, 44.1 or 48 kHz, one continuous file per take
   if possible, **and do not touch the gain again for the rest of the session.** A phone recording
   is better than nothing but loses the T60 tail into its noise floor — line out is worth the cable.
7. Say the take letter out loud into the recording before each take. That is the cheapest possible
   protection against mislabelled files.

### 8.2 Take (a) — CONCERT REVERB 1, the reverb ON arm  ★ mandatory

* SOUND menu → **REVERB** (right soft key #2). Display must read **`TYPE: CONCERT REVERB 1`**.
  If it does not: hold TYPE-down until it reads `ROOM REVERB 1` (TYPE 0), then press TYPE-up
  **4 times** → `ROOM REVERB 2`, `PLATE REVERB 1`, `PLATE REVERB 2`, **`CONCERT REVERB 1`**.
* **Confirm the page, not just the name.** The reverb page must show exactly five parameters:
  **`REVERB TIME` (s), `PRE DELAY` (ms), `HIGH DAMP GAIN`, `ER.LEVEL`, `VOLUME`**. If you see
  `THRESHOLD`/`RATIO`, or a `REV SEND`, you are on the DSP EFFECT page, not the reverb page.
* **Factory defaults, pre-registered before the recording exists:** `REVERB TIME` should read
  **2.0 s** (the ROM's own coefficient decodes to T = 2.000 s at the factory knob position 35) and
  `HIGH DAMP GAIN` **−4.0**. **Write down whatever it actually reads** — if it differs, the take is
  still good, we just need the number.
* Play **one short percussive note** (a hard, short staccato in the middle of the keyboard —
  a piano or a mallet sound, nothing with a slow attack or a long sustain). **Let it ring for
  ≥ 6 seconds in silence.** Do not play anything else in that window.
* **The dry note must be visible in the recording.** That is the positive control: if the dry note
  is not there, nothing was captured at all and the ring you are looking at is noise.

### 8.3 Take (b) — the same, DIGITAL REVERB OFF  ★ mandatory, the take that validates (a)

* Change **exactly one thing**: press the **DIGITAL REVERB** button so its LED goes out.
  Same sound, same key, same velocity, same gain, same session.
* **Kill condition:** if (b) is not audibly and measurably different from (a), the session is
  **void** — either the wrong output was recorded or the IC310 ambience was still on. Re-check
  §8.1 steps 2–4 and redo. Do not proceed to (c) until (a) vs (b) differ.

### 8.4 Take (c0) — SINGLE DELAY, the DSP-EFFECT positive control  ★ NEW, and mandatory

⚠ **The review's take (c) has no positive control, and without one its result is uninterpretable.**
"SLOW ATTACKER did nothing" and "the DSP EFFECT path was silent for an unrelated reason (the played
part is not routed to unit 0, the effect VOLUME is at zero, …)" produce *identical* recordings. So
before (c), prove the unit-0 path is live:

* Press **DIGITAL REVERB** off, press **DSP EFFECT** on.
* SOUND menu → **DSP EFFECT** (right soft key #4). Hold TYPE-down until the display reads
  **`CHORUS`** (that is TYPE 0), then press TYPE-up **7 times** → the display must read
  **`SINGLE DELAY`**, and the page must show **7 parameters**:
  `DELAY L(ms), DELAY R(ms), FEEDBACK L, FEEDBACK R, HIGH DAMP GAIN, VOLUME, REV SEND`.
* Set **`DELAY L` and `DELAY R` to a round number you can read off the screen** — 200 ms is ideal —
  and **write the number down**. Set `FEEDBACK` to something audible (a few repeats).
* Play the same short note. **You must hear discrete echoes.** If you do not, the DSP EFFECT path
  is not reaching the part you are playing — fix that (check the effect's `VOLUME`, and which part
  the page says it applies to) before going on.
* ★ **This take pays for itself twice:** measuring the actual echo gap in the file independently
  confirms the **44 100 Hz** sample rate the whole delay-length model rests on
  (`TODO-FOR-FELIPE.md` §1 item 2), *and* it is the control that makes (c) mean something.

### 8.5 Take (c) — SLOW ATTACKER  ★ the stub test

* Change **exactly one thing** from (c0): press TYPE-up **7 more times** from `SINGLE DELAY`
  (TYPE 7 → 14). The display must read **`SLOW ATTACKER`** and the page must show exactly **5**
  parameters: **`THRESHOLD`, `ATTACK RATE` (s), `RELEASE RATE` (s), `VOLUME`, `REV SEND`**.
  If the page shows anything else, you are not on TYPE 14 — count again from TYPE 0.
* Play the same short note. Then **turn `ATTACK RATE` to its maximum and play it again.**
* **Pre-registered prediction, in git before the recording exists:** *the note starts instantly and
  sounds identical in both, and identical to the same note with DSP EFFECT switched off.*
  `SLOW ATTACKER` uploads a 49-word program **byte-identical to NO OPERATION**
  (`2baadb775ff5eb84`), with the same coefficients and the same parameter payload, and its `ATTACK
  RATE` knob therefore cannot reach anything. If the attack *does* soften, that prediction is
  **falsified** and something outside IC311's program image is implementing it — which would be a
  bigger result than confirming it.
* A fourth 20-second take: with DSP EFFECT **off**, play the same note again, so (c) has its own
  local off-arm.

### 8.6 Photographs and part numbers (~5 min, no recording needed)

* **X301** crystal marking (the IC311 clock) — settles the master clock and therefore every
  millisecond figure in the project.
* **IC311** package marking — should read `uPD6383GF-3BA`; also the Panasonic service code
  `GGC1163`. Everything rests on this and nobody has looked.
* The **DRAM beside IC311** — its full part number. The driver currently populates the whole
  128K × 16 the chip *can* address, with a comment saying the size is unverified; the real part
  fixes the delay arena and the 2.972 s maximum.
* If it is easy: **IC310**'s marking (`MN19413`) and **X302** (its own ~20 MHz crystal).

### 8.7 Optional, if the session is going well (10 min more)

* Repeat (a) with **`ROOM REVERB 1`** (REVERB page TYPE 0) and **`PLATE REVERB 1`** (TYPE 2).
  ⚠ The strategic review pre-registers early reflections at **254 / 870 / 978 / 366 / 1044 samples
  = 5.760 / 19.728 / 22.177 / 8.299 / 23.673 ms** — but that prediction is **ROOM REVERB 1's**, not
  CONCERT REVERB 1's (`ROADMAP-2026-07-29.md:333`). As specified, take (a) records the one preset
  the prediction does *not* cover. **A ROOM REVERB 1 take is what tests it**, and the project holds
  a competing ER set (`540 650 975 1082 1084 1625`) that the same recording discriminates.

---

## 9. Paste-ready block for `TODO-FOR-FELIPE.md` §1

> Copy the block below into `TODO-FOR-FELIPE.md` under §1, replacing nothing above it.
> (This pass is read-only and did not edit that file.)

```markdown
### 1a. ★ The 30-minute sitting — exact button-by-button instructions (gate H0 is now built)

The UI-name → algorithm → chip → image-hash table is at
`kn5000-roms-disasm/dsp/analysis/EFFECT-CHIP-MAP_findings.md`. It settles which chip each
front-panel name lands on, so a recording can no longer measure the wrong one.
**Record the rear L/R LINE OUT, 24-bit, 44.1 or 48 kHz, and do not touch the gain after take (a).**
Say the take letter out loud into the recording before each take.

**Setup (once).** Power on and change nothing else — a cold boot already loads CHORUS on effect
unit 0 and CONCERT REVERB 1 on unit 1. Then:
* turn **OFF** the dedicated buttons **DSP EFFECT**, **DIGITAL EFFECT**, **ACOUSTIC ILLUSION**
  (their LEDs go out); leave **DIGITAL REVERB ON**;
* unplug the mic, MIC level to zero;
* SOUND menu → **EQUALIZER**: all four bands at 0 dB;
* play RIGHT 1 only — LEFT, RIGHT 2, accompaniment, rhythm, sequencer all off.
(This matters: the master reverb, the karaoke echo, the graphic EQ and ACOUSTIC ILLUSION all run on
the *other* DSP, IC310, which sits **in line with the main mix**. Anything left on colours the take.)

**(a) CONCERT REVERB 1 — mandatory.** SOUND → **REVERB** (right soft-key 2). The display must read
`TYPE: CONCERT REVERB 1`; if not, hold TYPE-▼ until it reads `ROOM REVERB 1`, then TYPE-▲ ×4.
Confirm the page lists exactly 5 parameters: REVERB TIME(s), PRE DELAY(ms), HIGH DAMP GAIN,
ER.LEVEL, VOLUME. **Please write down what REVERB TIME and HIGH DAMP GAIN actually read** — we
predict **2.0 s** and **−4.0** from the ROM and would like to know if the machine disagrees.
Play **one short percussive note**, let it ring **≥ 6 s in silence**. The dry note must be visible
in the file — that is the positive control.

**(b) The same with DIGITAL REVERB OFF — mandatory.** Change exactly one thing: press the
**DIGITAL REVERB** button so its LED goes out. Same sound, same key, same gain, same session.
*If (a) and (b) do not clearly differ, something else was recorded and the session is void* —
recheck the setup and redo before going further.

**(c0) SINGLE DELAY — the control that makes (c) mean anything.** DIGITAL REVERB **off**,
**DSP EFFECT on**. SOUND → **DSP EFFECT** (right soft-key 4). Hold TYPE-▼ until it reads `CHORUS`
(that is index 0), then TYPE-▲ **×7** → `SINGLE DELAY`, 7 parameters starting DELAY L(ms).
Set **DELAY L and DELAY R to 200 ms** (or any round number — **write it down**), FEEDBACK enough
for a few repeats, and play the same note. **You must hear discrete echoes.** If you do not, the
DSP effect is not reaching the part you are playing — that is worth telling us on its own.
(Bonus: measuring the echo gap in the file confirms the 44 100 Hz rate item 2 above asks about.)

**(c) SLOW ATTACKER — the prediction.** From `SINGLE DELAY`, press TYPE-▲ **×7 more** (index 7 →
14). Display must read `SLOW ATTACKER` with exactly 5 parameters: THRESHOLD, ATTACK RATE(s),
RELEASE RATE(s), VOLUME, REV SEND. Play the same note; then set **ATTACK RATE to maximum** and play
it again; then switch **DSP EFFECT off** and play it once more.
**Our prediction, filed before you record: all three sound identical and the note starts instantly.**
`SLOW ATTACKER` uploads a program byte-identical to NO OPERATION — same image, same coefficients,
same parameter payload — so its ATTACK RATE knob should reach nothing at all. It is the only one of
the twelve "named but empty" effects you can actually select from the front panel. **If the attack
really does soften, we are wrong about something important and want to know immediately.**

**(d)/(e) Photos and part numbers — 5 minutes, no recording.** The **X301** crystal marking; the
**IC311** package marking (should read `uPD6383GF-3BA`, Panasonic code `GGC1163`); and the **full
part number of the DRAM chip next to IC311** (this one changes real numbers — the driver currently
guesses 128K×16 and the reverb's 2.972 s maximum depends on it). If easy: **IC310** (`MN19413`) and
**X302**.

**Optional, 10 min more.** Repeat (a) with **ROOM REVERB 1** (REVERB page, hold TYPE-▼ to the top of
the list) and **PLATE REVERB 1** (2 more TYPE-▲). Our early-reflection prediction
(254/870/978/366/1044 samples) is **ROOM REVERB 1's**, so that take is the one that tests it.
```

---

## 10. Corrections this pass files against existing material

| file | claim | status |
|---|---|---|
| `dsp/analysis/data/typewalk/TYPE_MAP.md` | 36 rows; row 14 = NO OPERATION; rows 19/20 = one ROCK ROTARY; "add 1 above index 8" | ⛔ **38 entries**; row 14 = **SLOW ATTACKER**; 19 = **ROTARY SPEAKER**, 20 = **ROCK ROTARY**; `PEQ+DIST+DELAY` missing at 36; the +1 rule applies only to rows ≥ 20 in the map's own numbering |
| `dsp/analysis/PREDICT_S1_hi12_bench.md` §2.1 | "37 entries, 0..36 ⇒ `TYPELAST=36` is correct" | ⛔ the walk it rests on **dropped one press** (TYPE 36). ROM: 38 entries, top rail **37** |
| `dsp/tools/type_select.lua` | `TYPELAST` default 35, docs say use 36 | ⛔ with the true top at 37, every landing is `TYPEIDX+1`; `TYPELAST=37` makes `landing == TYPEIDX` |
| `dsp/analysis/STRATEGIC-REVIEW-2026-07-31.md` §4(b) | "224 recipes in `effect-selection-recipes.json`" as H0's raw material | ⛔ that file is **KN7000** (`:SEGxx` ports from `kn7000_mame@8c8fda8`); the KN5000 panel has no such ports |
| same, action 4 | "(a) CONCERT REVERB 1 … master/panel reverb at minimum"; "(b) with the DSP effect OFF" | ⚠ self-contradictory; the reverb A/B toggles **DIGITAL REVERB**, and what must be at minimum is **IC310's** ambience |
| same, action 4 kill-condition | pre-registers ER at 254/870/978/366/1044 samples for a **CONCERT REVERB 1** take | ⚠ that ER set is **ROOM REVERB 1's** (`ROADMAP-2026-07-29.md:333`); as written the take cannot test it |
| same, §4(b) | `m_do[unit][…]` written only at `upd6383.cpp:2475/2476` | ⚠ conclusion right, citation stale: HEAD is `:2618-2619`, and `:3136` is a second site that is dead (`if (false && …)`) |
| the brief for this task | "algorithms 57–60 drive BOTH" | ⛔ false, and already falsified by `second-dsp-and-ready.md` **B2** on 2026-07-27 |
| the brief for this task | "`a99 PEQ+OVERDR+DELAY` at 36 (the top rail)", "`TYPELAST=36`" | ⛔ `a99` is at **TYPE 37** |
| the brief for this task | "the duplicate is at 19/20 (`a15 ROCK ROTARY`, two slots sharing a byte-identical image)" | ⚠ half right: the *image* is shared, but the two slots are **different named effects** (`a53 ROTARY SPEAKER` at 19, `a15 ROCK ROTARY` at 20) — they are not a duplicated entry, and TYPE_MAP loses a row by treating them as one |

*(Nine items. The brief warned its errors have run to six; this pass found four in the brief and
three more in the review it quotes.)*

---

## 11. Reproduce

```
python3 <scratchpad>/h0_verify_effectchipmap.py      # prints §1's self-test, then Tables A–D
```
Inputs, all read-only: `original_ROMs/kn5000_v10_program.rom`, `..._v9_...`, `..._v7_...`,
`original_ROMs/kn5000_subprogram_v142.rom`, `v10/maincpu/ui_widgets/naka_widget_descriptors.c`,
`dsp/programs.tsv`, `dsp/analysis/data/typewalk/kn5000_dsp1_upload.txt`, and
`~/compartilhado/kn7000_mame/tools/kn5000_dsp_extract.py`.
