# K5 — the OUTPUT STAGE, I-RAM 60..82, decoded statically

**NEC uPD6383GF (Technics SX-KN5000 IC311).** Roadmap item **K5** from
`kn7000_mame/notes/dsp-next-steps-roadmap.md` (commit `a888065`): decode the resident
kernel's output stage from the **Sub CPU code that assembles and ships it**, rather than
from the microcode alone.

No hardware was used and none is needed for anything claimed here. Everything below is
either PROVEN BY CONSTRUCTION (read out of the Sub CPU code that emits the bytes),
MEASURED (counted over the ROM corpus), DETERMINED (forced by a constraint system),
INFERRED, or explicitly OPEN. The reproduction recipe for each measurement is given.

Companion listing: [`dsp/disasm/epilogue.dsm`](../disasm/epilogue.dsm) — **new**; the
output stage was not in the disassembly tree at all before this pass. It is byte-match
verified by `dsp/verify.py` like every other listing.

---

## 0. Executive summary — what is new

| # | finding | status |
|---|---|---|
| 1 | The **uC-IF script bytecode** the Sub CPU interprets is fully decoded: record = `<b0> <b1> <payload>`, `op = b0 >> 4`, `len = (((b0 & 0x0F) << 8) | b1) − 2`, `op 0xF` = END. | **PROVEN BY CONSTRUCTION** |
| 2 | The **whole 83-word resident kernel is two literal canned blobs**, `0x01E496` (I-RAM 0..59) and `0x01E63C` (I-RAM 60..82). **No kernel word is constructed by the firmware.** | **PROVEN BY CONSTRUCTION** |
| 3 | I-RAM 64 / 71 are written by exactly two routines, **`EFF_Disconnect`** and **`EFF_Link`**, indexed by *effect unit*: unit 0 → I-RAM 64, unit 1 → I-RAM 71, units 2/3/4 → DSP2 registers. The firmware's own debug strings are `"EFF n disconnect."` / `"EFF n link."`. | **PROVEN BY CONSTRUCTION** |
| 4 | Those two slots have a **third, previously unrecorded state**: the value in the canned image, `011.9.0E.445` / `011.9.0F.446`, which carries the **unit tag** (0x0E/0x0F) in `addr8`. | **MEASURED** |
| 5 | The `0xC40/0xC41` immediate is **13 bits at [24:12] and always a multiple of 32** (11/11 distinct values, 61/61 occurrences) ⇒ the payload is the 8-bit field **[24:17]**, `imm13 = payload × 32`. | **MEASURED** |
| 6 | Decoded that way, the four host-written values are **84, 42** (unit 0) and **200, 50** (unit 1). 84 and 200 are the I-RAM load addresses of every unit-0 / unit-1 body (91/91 well-formed algorithm streams). 42 and 50 are the first words of the header's own unit-0 / unit-1 setup blocks, and the return-tag constraint confines the unit-0 vector to 0..49 and the unit-1 vector to 50..59 — which 42 and 50 satisfy, exactly on the block boundaries. **I-RAM 64/71 load the per-unit CALL VECTOR.** | **DETERMINED** |
| 7 | The **`×2` / `×4` "linear level" reading of §1.4/§3.3 is falsified**: 84 = 2·42 and 200 = 4·50 are arithmetic accidents of the I-RAM layout, and "disconnect" is not attenuation — the DSP's real mute is a different mechanism entirely (uC-IF cmd `0x04`, data byte 3 = `0x3F` mute / `0x00` unmute). | **PROVEN BY CONSTRUCTION** |
| 8 | The frame terminator **`C00.A.47.407` @ I-RAM 82** encodes **its own address**: `imm13 = 0xA47 = 82×32 + 7`. The only other `C00` word in the corpus, `C00.9.84.000` @ I-RAM 76, does the same: `0x984 = 76×32 + 4`. | **MEASURED (2/2)**, semantics INFERRED |
| 9 | The host-poke coefficient packet is decoded: `0A aa bb cc dd` = 24-bit `V = ((aa&0x7F)<<17)|(bb<<9)|(cc<<1)|(dd>>7)`, tag `dd & 0x7F` selecting the destination pointer register (0x26 ↔ `…821`, 0x4C ↔ `…825`). | **PROVEN BY CONSTRUCTION** |
| 10 | **MISS reported:** `instruction-set.md` attributes the `nop` form `000.2.00.000` to writer `LABEL_038922`. That routine does not emit it; it emits `801.0.NN.825` plus a tag-`0x4C` coefficient packet. | correction |

---

## 1. The Sub CPU script machine (K5-E1) — PROVEN BY CONSTRUCTION

The roadmap's K5-E1 asked for "the code that walks that blob and what selects A over B".
Both are now read out of the code.

### 1.1 The bytecode

`DSP_BytecodeInterpreter_Init` / `…_Loop` / `…_CheckEnd`
(`archive/asl/subcpu/kn5000_subprogram_v142.asm`). Transcribed from the TLCS-900 source:

```
loop:   b0 = p[0] ;  b1 = p[1]
        op  = b0 >> 4
        len = (((b0 & 0x0F) << 8) | b1) - 2      ; payload byte count
        p  += 2
        if op == 0xE: goto op_send                ; payload[0]=CMD, payload[1..]=DATA
        if op == 0xD: notify_state_change()       ; len is always 0
        if op  >  5 : goto check_end              ; (payload NOT consumed)
        else        : jump  0x03C32E + OFFSETS_14739[op]      ; op 0..5 handlers
op_send: c = *p++ ; DSP_DispatchCommand(unit, c)
         for i in 1 .. len-1: DSP_DispatchData(unit, *p++)
check_end: if (p[0] & 0xF0) != 0xF0: goto loop
           return
```

* `0xF0` is the **END marker**, not a record separator — which is why every script
  pointer in the ROM points at the byte *after* an `F0`.
* `DSP_DispatchCommand`/`Data` fan out on the *chip* index: **0 → `DSP_Send_Command`
  /`DSP_Send_Data` (DSP1 = the uPD6383)**, 1 → `DSP2_Send_*`.
* Handlers for `op 0..5` live at `0x03C32E + {0, 0x23A, 0x333, 0x3DA, 0x473, 0x48D}`
  (table `OFFSETS_14739`). They are **not disassembled** in the ASL source — it renders
  them as `DSP_Bytecode_Programs: db …`. Empirically (matched against the live capture)
  ops 0/1/2/3 all send `payload[0]` as a command and the rest as data, exactly like op E,
  and `op 4` with a 1-byte payload produces **no bus traffic at all** — it is a delay/wait.
  **Decoding those six handlers is the obvious follow-up; it is pure static work.**

**Predict-then-check (passed).** Decoding `0x01E496` with the rule above predicts a
record `op 3, len 303, payload = 01 00 00 <300 bytes>`. The cold-boot capture
`notes/data/kn5000_dsp1_upload_coldboot.txt` transfer 11 reads *"cmd 0x01, 302 bytes,
00 00 00 92 20 12 0D …"* — the same bytes, split exactly as the rule says. The same
check passes on `0x01E63C` (transfer 3), `0x01E5C8` (transfer 13), `0x01E5D3`
(transfer 12) and the whole of `0x01E6BE` (transfers 4..10).

### 1.2 Where the kernel lives, and that it is literal

| block | Sub CPU ROM (CPU addr) | file offset | record | uC-IF | target | words |
|---|---|---|---|---|---|---|
| header | `0x01E496` | `0x00F596` | op 3, len 303 | cmd `0x01` | I-RAM `0x0000` | 60 |
| **output stage** | **`0x01E63C`** | **`0x00F73C`** | **op 3, len 118** | **cmd `0x01`** | **I-RAM `0x003C` = 60** | **23** |

`0x00EF00` is the CPU↔file offset for this ROM (confirmed on two independent anchors).

The header is shipped by **`EFF_WriteHeader`** (`LDA XWA, 01E496h`), the output stage by
**`DSP_AlgorithmChange`** (`LDA XWA, 01E63Ch`, its first action). **The two blocks are
shipped by different routines at different times** — which is why the output stage was
never included in `kernel.dsm`, and why the roadmap called it "the algorithm-change stub".
It is not a stub: it is the second half of the resident kernel and it is byte-for-byte
constant.

**No kernel word is computed.** The only DSP words the firmware ever *constructs* are:

* `LABEL_0387E6` → emits `08 01 <P>>4> <((P&0xF)<<4)|8> 21`, i.e. the word
  `hi12=0x801, class4=0, addr8=P, lo12=0x821` with `P = arg + WA` — then a 24-bit
  coefficient packet with tag `0x26`.
* `LABEL_038922` → the same shape but `lo12 = 0x825` and coefficient tag `0x4C`.
* `LABEL_0388B3` → the coefficient packet alone, tag `0x26`.

This is a **direct construction proof of the `class4|addr8` byte boundary**: the firmware
literally writes `(P >> 4) & 0x0F` into the low nibble of byte 2 (leaving `class4 = 0` in
its high nibble) and `(P & 0x0F) << 4` into the high nibble of byte 3. `addr8` is exactly
bits [19:12]. It also shows the *host-stream* meaning of `801.0.NN.821`: it sets the
destination pointer for the coefficient pokes that follow. Whether the identical word
*inside I-RAM* does the same thing is INFERRED, not proven — `instruction-set.md`
currently conflates the two.

### 1.3 The coefficient poke — decoded

```
0A aa bb cc dd    ->   V(24-bit) = ((aa & 0x7F) << 17) | (bb << 9) | (cc << 1) | (dd >> 7)
                       tag       = dd & 0x7F
```
Equivalently the 36-bit container is `0xA_00000000 | (V << 7) | tag`. Tags observed:
`0x26` (destination register `…821`), `0x4C` (`…825`), `0x15` (the register set by
`000.1.06.000` / `000.1.86.000`). **PROVEN BY CONSTRUCTION** from the three writers above;
cross-checked against cold-boot transfers 20/26/27 (`08 01 00 08 25` then tag-`0x4C`
values; `08 01 09 78 21` then tag-`0x26` values).

---

## 2. I-RAM 64 and I-RAM 71 — what they are

### 2.1 What writes them (PROVEN BY CONSTRUCTION)

Two script-pointer tables, both indexed by the **effect unit number** (0..4):

```
EFF_Disconnect  table @ 0x01F3F0 : 01E5C8  01E5D3  01E5DE  01E5EA  01E5F6
EFF_Link        table @ 0x01F404 : 01E602  01E60D  01E618  01E624  01E630
unit -> chip    table @ 0x01ED6D :   00      00      01      01      01
```

(One contiguous 10-entry array at `0x01F3F0`: five disconnect scripts then five link
scripts, `EFF_Link`'s base being `0x01F3F0 + 5*4`. Entry 10 is not a valid pointer, so the
array is exactly 10 long. Both routines compute their index as `arg2*12 + unit*4`; the
array size forces `arg2 == 0` on every live call — any other value would index across the
disconnect/link boundary or off the end. That secondary term is the one part of the
indexing not independently confirmed, and it does not affect anything below, because a
ROM-wide scan finds **exactly four** well-formed writes to I-RAM 64/71 in the whole
192 KB image and they are these four scripts.)

| unit | chip | what the disconnect script does | what the link script does |
|---|---|---|---|
| 0 | 0 (uPD6383) | I-RAM **64** ← `C40.5.40.445` | I-RAM **64** ← `C40.A.80.445` |
| 1 | 0 (uPD6383) | I-RAM **71** ← `C40.6.40.446` | I-RAM **71** ← `C41.9.00.446` |
| 2 | 1 (DSP2) | reg `0x051B` ← `0x03B16A` | reg `0x051B` ← `0x00716A` |
| 3 | 1 (DSP2) | reg `0x051F` ← `0x03CD42` | reg `0x051F` ← `0x026142` |
| 4 | 1 (DSP2) | reg `0x051D` ← `0x03F156` | reg `0x051D` ← `0x01E156` |

The unit→chip table and the two script tables line up **exactly**: the two units that live
on the uPD6383 are the two that are configured by an I-RAM word write, and they are I-RAM
**64** and **71**. The firmware's own `Debug_Print_String` texts are `"\nEFF "`,
`" disconnect."` and `" link."`.

**This answers the roadmap's open question "what binary condition selects script A or B".**
From `DSP_State_Dispatcher`:

```
  if reset:  DSP_ResetLoop                 else: EFF_MuteLoop
  DSP_MuteLoop                             ; cmd 0x04, data byte 3 = 0x3F  (REAL mute)
  DSP_AlgorithmChangeCheck                 ; -> ships the OUTPUT STAGE + C-RAM init
  if reset or algo-changed:
      EFF_WriteHeader(chip 0)              ; ships I-RAM 0..59
      EFF_DisconnectLoop                   ; units 4,1,0  -> "A"
  DSP_UnmuteLoop                           ; cmd 0x04, data byte 3 = 0x00
  EFF_HeaderChangeDataLoop                 ; per-unit body uploads + coefficient pokes
  EFF_LinkLoop                             ; units whose enable flag is 1 -> "B"
  EFF_VolumeLoop
  EFF_SecondaryLinkPath                    ; units whose enable flag is 0 -> "A" again
```

So **A = "this effect unit is not in the chain"** and **B = "it is"**. It is a per-unit
boolean (`+0x36` in the per-unit parameter struct, and the enable word at
`0x495E + unit*0x32 + 0x10`), *not* a level, and *not* a function of any user parameter.
A is also the safe state during a body reload, which is what the live capture saw.

### 2.2 The third state — MEASURED, new

The value shipped in the canned output-stage image is neither A nor B:

```
  I-RAM 64 :  011.9.0E.445        I-RAM 71 :  011.9.0F.446
```

`class4 = 9`, `addr8 = 0x0E` / `0x0F` — the **unit tags** (the same 0x0E/0x0F that mark
the unit-tagged transfers 91/91). `lo12` is `0x445` / `0x446` in **all three** states, so
`lo12` names the destination and everything above it names the source. Corpus counts:
`lo12 = 0x445` and `0x446` occur **0 times** in the 2974-word body corpus; `hi12 = 0x011`
occurs **0 times**; `class4 == 9 && addr8 ∈ {0x0E,0x0F}` occurs **0 times** outside these
two words. They are unique to the output stage.

*The roadmap's "the output stage has exactly two states" is right about the host and
wrong about the slot: there are three, and the third is the boot default.*

### 2.3 How the immediate is encoded — MEASURED

Every `hi12 ∈ {0xC40, 0xC41}` word in the whole corpus (kernel + epilogue + 38 images +
the four host-written words): **61 occurrences, 11 distinct `imm13` values, every one a
multiple of 32.**

```
  imm13 (bits [24:12]) :  0x0000 0x0180 0x01E0 0x02C0 0x0320 0x03A0 0x0500
                          0x0540 0x0640 0x0A80 0x1900
  imm13 / 32           :       0     12     15     22     25     29     40
                               42     50     84    200
```

Under a null in which the field were an arbitrary 13-bit number, P(all 11 distinct values
≡ 0 mod 32) ≈ 32⁻¹⁰ ≈ 1e-15. **The low five bits are structurally zero.** The payload is
therefore the 8-bit field **[24:17]** (bit 24 is `hi12` bit 0 — which is exactly why slot
71's link value carries `0xC41` rather than `0xC40`), and

```
   C40/C41 form :   opcode = bits[35:25] = 0x620
                    A = bits[24:17]   (the payload)
                    B = bits[16:12]   (always 0 in this family, 13/13)
                    lo12 = the destination
```

Reproduce: `python3 - <<'EOF'` over `dsp/disasm/*.dsm`, select `(w>>24)&0xF00 == 0xC00`
and `((w>>24)&0xFFF) in (0xC40,0xC41)`, print `(w>>12)&0x1FFF`.

### 2.4 What the payload IS — DETERMINED

Decoded, the four host-written values are

| slot | disconnect (A) | link (B) |
|---|---|---|
| I-RAM 64 (unit 0) | **42** | **84** |
| I-RAM 71 (unit 1) | **50** | **200** |

Four independent structural matches, all four exact:

1. **84 is the I-RAM load address of every unit-0 body.** Checked by walking the
   100-entry algorithm table at `0x0001ED7C` and parsing each stream's upload record:
   of the **91** streams that yield a valid I-RAM image, **79 target I-RAM `0x0054` = 84
   and 12 target `0x00C8` = 200 — nothing else** (91/91). (The other 9 entries are the
   malformed/empty streams; they "target" 1520 and 3376, both outside the 384-word I-RAM,
   which is what makes them malformed.) This is a genuine predict-then-check: the
   hypothesis says one constant must serve every effect, and it does.
2. **200 is the I-RAM load address of the unit-1 body** (the single 133-word reverb image,
   shared by all 12 reverb presets).
3. **42 is the first word of the header's unit-0 setup block** (`w42 ldptr #$70`,
   `w43 …827←$6C`, `w44 …825←$25`, …) and the first unit-tagged word at or after 42 is
   **w49 `400.1.0E.000`, tag 0x0E = unit 0**.
4. **50 is the first word of the header's unit-1 setup block** (`w50 ldptr #$50`, …) and
   the first unit-tagged word at or after 50 is **w59 `400.1.0F.007`, tag 0x0F = unit 1**.

Points 3 and 4 are the load-bearing ones, because they are *constrained*, not merely
matched. Under K1's mechanism (a unit-tagged word calls when the stack is empty and returns
when it is not), a "disconnect" vector must point at a stretch of code that (a) is harmless
and (b) terminates on a word carrying **that unit's own tag**, or the return will not
happen. The kernel contains exactly two tagged words, at 49 (tag 0x0E) and 59 (tag 0x0F)
— so (b) confines the unit-0 vector to **0..49** and the unit-1 vector to **50..59**. The
observed 42 and 50 fall in the right window each, and land exactly on the first word of
that unit's own setup block. **Honest limit:** (b) narrows the choice to a range, it does
not single out one address; what makes the reading strong is that both values land in the
correct (and *different*) window, and both on a structural boundary. So:

> **I-RAM 64 and I-RAM 71 load the CALL VECTOR of unit 0 and unit 1.**
> LINK points the vector at the unit's real body; DISCONNECT points it at that unit's own
> header setup block, so the call re-runs eight or ten words of register setup and returns
> — the unit's body never executes and contributes nothing. That is what "disconnect"
> means, and it is what a hand-written DSP kernel with a two-level stack and no branch
> instruction would have to do.

This also supplies the answer K1 flagged as unknown ("2-entry vector table **vs** host-loaded
entry registers"): **host-loaded entry registers, loaded by the output stage.** Note the
vector loaded in frame *n* is the one used in frame *n+1*, since the output stage runs
after both calls.

**Independent corroboration from the other chip.** The three DSP2 units use the same
link/disconnect pattern with a different protocol (`cmd 0x30`, 24-bit values split as
`<16-bit value><8-bit destination tag>`):

```
   unit 2  tag 0x6A :  disconnect 0x03B1   link 0x0071
   unit 3  tag 0x42 :  disconnect 0x03CD   link 0x0261
   unit 4  tag 0x56 :  disconnect 0x03F1   link 0x01E1
```

The three **disconnect** values are clustered within 96 of each other (945/973/1009) while
the three **link** values are scattered (113/609/481) — exactly the signature of "park all
of them in one common idle region / point each at its own body". Same shape, different
silicon. (SUGGESTIVE only: DSP2's ISA is unknown.)

### 2.5 What is thereby falsified

* **"The immediate is a linear level and A is the reduced one"** (`-roadmap.md` §1.4,
  INFERRED, n = 2) — **FALSIFIED**. 84 = 2·42 and 200 = 4·50 are accidents: 84 is the first
  usable word after the 83-word kernel (83 rounded up), 200 is a round layout boundary, and
  42/50 are fixed by the header's own structure. The ×2/×4 relation was a coincidence, and
  the "level" reading existed only to explain it.
* **"The output stage's level is a constant, therefore the depth control acts elsewhere"**
  (§1.4 consequence 1) — the *conclusion* survives and is strengthened: these two words
  carry no level at all, so the DSP-depth control certainly acts elsewhere (C-RAM
  coefficients, or IC303's return mix). K5-E2 is still the right experiment for O-4.
* **"K5-E3 (hardware): expect a −6 dB / −12 dB step in the wet level during a reload"** —
  **the prediction should be withdrawn.** The predicted effect of a disconnect is that the
  unit's *body stops executing*, i.e. the wet return goes to **silence** for the duration
  of the reload (and the DSP is separately muted around it anyway, cmd `0x04` byte 3 =
  `0x3F`). The roadmap explicitly said "if the wet return instead goes fully silent, the
  immediate is not a linear level" — that is now the *prediction*, not the falsifier.
* `hi12 == 0xC40` is **not** an "envelope detector". The disassembler still emits that
  label and it is wrong on all 61 sites (B §6.2 already argued this; the multiple-of-32 law
  is independent new evidence). See §5.

---

## 3. What the epilogue does — structure

Execution order in a frame (PROVEN by the register-reuse argument plus the two tagged
words): `I-RAM 0..49` → unit-0 body @84 → `50..59` → unit-1 body @200 → **`60..82`** →
frame wait. The output stage is the last thing that runs.

It is visibly **two symmetric per-unit blocks followed by a common tail**:

```
 60  092.1.8D.15B  \
 61  012.1.8D.05B   |
 62  801.0.26.825   |  UNIT-0 BLOCK        (addr8 0x8D / 0x8F / 0x8C, ptr reg 0x825 <- 0x26)
 63  2A7.9.05.1C3   |
 64  011.9.0E.445   |  <-- unit-0 CALL VECTOR (host-written)
 65  200.1.8F.1C1   |
 66  000.1.8C.107  /
 67  980.5.20.402  --  hinge between the two blocks
 68  092.1.8C.19B  \
 69  801.0.90.821   |  UNIT-1 BLOCK        (ptr reg 0x821 <- 0x90)
 70  2A6.1.85.0C7   |
 71  011.9.0F.446   |  <-- unit-1 CALL VECTOR (host-written)
 72  000.1.06.087  /
 73  E30.C.00.404  \
 74  C16.9.AB.000   |  COMMON TAIL: the machine's only class-C and class-D words,
 75  82E.8.0F.000   |  one class-8 post-sum step, one WAIT, one pointer load
 76  C00.9.84.000   |
 77  859.0.86.822   |
 78  A3C.D.9F.287  /
 79  012.2.FF.1CE  \
 80  104.2.00.1CE   |  I/O BLOCK — ordinary body vocabulary; w79 is byte-identical to
 81  102.2.00.000  /   header w3, and lo12 0x1CE has 140 uses across the body corpus
 82  C00.A.47.407  --  FRAME WAIT
```

Pairing evidence (MEASURED): `w60 ↔ w68` share `hi12 = 0x092, class4 = 1` and differ only
in `addr8` (0x8D/0x8C) and one `lo12` bit; `w63 ↔ w70` share `hi12 ≈ 0x2A6/0x2A7`;
`w64 ↔ w71` are the two vector words. The three pointer loads are `0x825 ← 0x26`,
`0x821 ← 0x90`, `0x822 ← 0x86`.

### 3.1 The frame terminator `C00.A.47.407` @ I-RAM 82 (K2)

`hi12 = 0xC00`, so under the same C-format split `imm13 = 0x0A47 = 2631 = 82 × 32 + 7`.
**The word encodes its own I-RAM address.** In the whole 3057-word corpus (60 header + 23
epilogue + 2974 body words) there are exactly **two** `C00` words and both are in the
epilogue: this one and `C00.9.84.000` at I-RAM 76, where `0x984 = 2436 = 76 × 32 + 4` —
**also its own address**, with a different 5-bit `B` field (4 vs 7). Two words, two exact
self-matches; under a uniform null P ≈ 1.5e-5.

**INFERRED:** `C00` is a WAIT/SYNC form — "hold at *A* until event *B*" — and I-RAM 82's
event 7 is the frame restart. This is a positive explanation for the fact the roadmap
noted but could not explain: *the epilogue contains no end-of-block word at all.* A block
that ends by waiting does not need one. It also removes K2's ambiguity defect: the word's
`class4 == 0xA` is **immediate data**, not a cursor advance, so it does **not** shift the
C-RAM addresses after it.

What I-RAM 76 waits for is **OPEN**. Its `B = 4` differs from 82's `B = 7`, and the natural
candidates (DO-port ready, DRAM refresh, a DSP2 handshake) cannot be separated statically.

### 3.2 The DO write itself — still OPEN

The roadmap put the DO write in I-RAM 73..78 (the class-C/class-D words). Nothing found
here settles it. What can be said:

* w79/w80/w81 are **not** kernel-only: `104.2.00.1CE` occurs 22× and `102.2.00.000` 34×
  inside effect bodies, and w79 is byte-identical to header w3. If `lo12 = 0x1CE` is a port,
  the same port appears in the input stage and in the output stage. That is consistent with
  a single bidirectional serial codec interface and inconsistent with "0x1CE is *the* DO
  write" (a body would not write the DAC 140 times per frame).
* w73 `E30.C.00.404` and w78 `A3C.D.9F.287` remain the only class-C and class-D words in
  the machine (0 of 2974 body words each), which keeps them the best DO candidates on
  positional grounds alone. **No decode is claimed.**
* w74 `C16.9.AB.000` decodes under the same A/B split to `A = 77, B = 11`, and I-RAM 77 is
  the next pointer load. Suggestive of a short forward transfer; **OPEN**.

---

## 4. Word-by-word verdict, I-RAM 60..82

| I-RAM | word | verdict | what is claimed |
|---|---|---|---|
| 60 | `092.1.8D.15B` | **OPEN** | start of the unit-0 output block; pairs with w68 (MEASURED) |
| 61 | `012.1.8D.05B` | **OPEN** | same `addr8 = 0x8D` as w60 |
| 62 | `801.0.26.825` | **INFERRED** | pointer-register load, reg `0x825 ← 0x26`; *which* register is OPEN (K3) |
| 63 | `2A7.9.05.1C3` | **OPEN** | pairs with w70 (MEASURED) |
| **64** | `011.9.0E.445` → `C40.{5.40,A.80}.445` | **DETERMINED** | **unit-0 CALL VECTOR**; host writes 84 (link) / 42 (disconnect); canned default carries unit tag 0x0E |
| 65 | `200.1.8F.1C1` | **OPEN** | `addr8 = 0x8F` |
| 66 | `000.1.8C.107` | **OPEN** | ends the unit-0 block |
| 67 | `980.5.20.402` | **OPEN** | hinge; only occurrence in the machine |
| 68 | `092.1.8C.19B` | **OPEN** | start of the unit-1 output block; pairs with w60 |
| 69 | `801.0.90.821` | **INFERRED** | pointer-register load, reg `0x821 ← 0x90`. `0x90` is also the MEASURED unit-1 C-RAM bank base — see §6 |
| 70 | `2A6.1.85.0C7` | **OPEN** | pairs with w63 |
| **71** | `011.9.0F.446` → `C40.6.40.446` / `C41.9.00.446` | **DETERMINED** | **unit-1 CALL VECTOR**; host writes 200 (link) / 50 (disconnect); `0xC41` proves the immediate reaches bit 24 |
| 72 | `000.1.06.087` | **OPEN** | ends the unit-1 block |
| 73 | `E30.C.00.404` | **OPEN** | only class-C word in the machine; DO-write candidate |
| 74 | `C16.9.AB.000` | **INFERRED (weak)** | C-format; `A = 77, B = 11` under the §2.3 split |
| 75 | `82E.8.0F.000` | **OPEN** | class 8 = post-sum step, operation unknown |
| 76 | `C00.9.84.000` | **INFERRED** | WAIT/SYNC at its own address 76, event 4 (MEASURED: `0x984 = 76×32+4`) |
| 77 | `859.0.86.822` | **INFERRED** | pointer-register load, reg `0x822 ← 0x86` |
| 78 | `A3C.D.9F.287` | **OPEN** | only class-D word in the machine; DO-write candidate |
| 79 | `012.2.FF.1CE` | **OPEN** | byte-identical to header w3 (input stage) |
| 80 | `104.2.00.1CE` | **OPEN** | ordinary body vocabulary (22 exact matches) |
| 81 | `102.2.00.000` | **OPEN** | ordinary body vocabulary (34 exact matches) |
| **82** | `C00.A.47.407` | **INFERRED** | **FRAME WAIT** at its own address 82, event 7 (MEASURED: `0xA47 = 82×32+7`) |

Coverage change for the output stage: **0/23 → 2 DETERMINED + 5 INFERRED**, and the two
DETERMINED ones are the two that gate control flow.

---

## 5. Forms the disassembler should adopt

These are stated in the form `dsp_disasm.py` (and, later, MAME's `upd6383d.cpp`) can take.
**Nothing here has been synced to MAME** — that is a deliberate follow-up, listed in §7.

1. **Demote the `hi12 == 0xC40 → "envelope detector"` annotation** below the C-format rule.
   It fires on all 61 `C40/C41` sites and is wrong on every one of them (it labels the
   reverb tank, the chorus and the frame terminator as level detectors). One-line reorder
   in `annotate()`.
2. **`C40/C41` immediate-load form.** Render as
   `ldimm  #<A>,r<lo12>   ; imm13 = A*32` with `A = (w >> 17) & 0xFF`. Assert `B = (w >> 12)
   & 0x1F == 0` (13/13) and print the residue if it is ever non-zero.
3. **`lo12 = 0x445 / 0x446` destinations** are the unit-0 / unit-1 **call vector**. When the
   `C40/C41` form hits those, print `setvec unit0,#84   ; LINK` / `setvec unit0,#42   ;
   DISCONNECT` etc.
4. **`C00` wait form.** `hi12 == 0xC00` → `wait  #<B>` and *check* that `A` equals the
   word's own I-RAM index (2/2 today); print a loud residue if it does not.
5. **The C-format `A`/`B` split is `[24:17]` / `[16:12]`,** and `hi12` bit 0 is part of the
   immediate — so the family predicate must be `(hi12 & 0xFFE) == …`, not `hi12 == …`.
   **Caveat, stated as a limit:** the split is MEASURED for `C40/C41` and matches the two
   `C00` words, but the `lo12 = 0x820` pointer-load family (`C0A/C04/C42/C4A`, 5 words in
   the header) yields `B ∈ {0,17,18,23}`, so it is **not** established as universal. Do not
   apply it there.
6. **Host-poke packets are not instructions.** The `0A aa bb cc dd` coefficient form (§1.3)
   should be decoded in the *host-stream* view only; the current annotation
   `[hi12[11:8]==A: host-poke data form]` fires on genuine in-program words such as
   `A00.0.00.041` in CHORUS and `A3C.D.9F.287` at I-RAM 78, where it is meaningless.
7. **Correct the provenance of `nop`.** `instruction-set.md` says `000.2.00.000` is
   PROVEN BY CONSTRUCTION with writer `LABEL_038922`. It is not: `LABEL_038922` emits
   `801.0.NN.825` followed by a tag-`0x4C` coefficient packet (`ADD XWA, 0000004ch`), and
   `000.2.00.000` appears nowhere in it. The `nop` reading rests on position only
   (the `nop nop` pairs in the reverb) — it should be relabelled **INFERRED**.
   `ldptr`'s attribution to `LABEL_0387E6` **is** correct, with the nuance in §1.2.

---

## 6. New constraints handed to other roadmap items

* **K1 (unit-tagged transfer).** The mechanism is **host-loaded entry registers**, not a
  fixed vector table: the two registers are written by the output stage at I-RAM 64/71, and
  their values are `{84, 42}` and `{200, 50}`. An emulation can implement the tagged word as
  "empty stack ⇒ push, PC ← vec[tag]; non-empty ⇒ pop" and get the disconnect no-op for free.
* **K2 (frame terminator).** Resolved as far as static evidence goes (§3.1), and its
  `class4 == 0xA` is immediate data, so the "does it advance the cursor / does it
  post-increment the pointer by +0x47" discriminator is **moot**: there is no `addr8` field
  in a C-format word. The `0xCC..0xD3` landing-zone story in §6.D of the roadmap loses its
  premise.
* **K3 (pointer register file).** The output stage adds `0x825 ← 0x26`, `0x821 ← 0x90`,
  `0x822 ← 0x86`. New constraint: **`0x821` cannot be the C-RAM cursor base.** Frame order
  gives `0x821 = 0x70` during the unit-0 body and `0x50` during the unit-1 body, whereas the
  MEASURED cursor bases are `0x00` and `0x90`. Separately, the host stream's tag→register
  binding (`0x26 ↔ …821`, `0x4C ↔ …825`, §1.3) is a new, independent handle on the register
  file that does not depend on any microcode reading.
* **K6 (input stage).** Header w1 `C0A.0.E0.000` decodes under §2.3 to `A = 7, B = 0`, and
  **I-RAM 7 is exactly the start of the second input block** (blocks are 0..6 and 7..11).
  Consistent with, and independent of, K6's own block split. Marked INFERRED — the `C0A`
  opcode is not the `C40` opcode.
* **Effect-chain model.** The KN5000 has **five effect units on two chips** (units 0,1 on
  the uPD6383; 2,3,4 on DSP2), with per-unit enable flags and per-unit link/disconnect.
  Any driver-level model of the effects block needs that shape.

---

## 7. Follow-ups (nothing here was synced to MAME)

Per the scope restriction for this pass, `src/devices/cpu/upd6383/*` was not touched.
To sync later, in this order:

1. `upd6383d.cpp::annotate()` — the six items in §5 (the annotation reorder is a one-liner
   and removes 61 wrong labels).
2. `upd6383.cpp` — call-vector registers for the tagged transfer (K1), fed from I-RAM 64/71.
3. `dsp_disasm.py` — same six items; then re-run `gen_dsp_disasm.py` and `verify.py`.

Static work that follows directly from this pass and needs no hardware:

* **Disassemble the six `op 0..5` handlers** at `0x03C32E + OFFSETS_14739[op]`. The ASL
  source renders them as `DSP_Bytecode_Programs: db …`; they are the definition of the
  uC-IF commands `0x01/0x02/0x04/0x09/0x0C/0x30` and of the `op 4` delay.
* **Decode `cmd 0x04`** (`FB DA 3F A0 1A` mute / `FB DA 00 A0 1A` unmute) and `cmd 0x09`
  (`00 3C`), `cmd 0x0C` (`00 55 55`) — five bytes of global chip configuration, one of which
  is a proven mute control.
* **The `01 60` / `01 61` host windows.** cmd `0x01` with target `0x0160` carries 5-byte host
  packets, cmd `0x02` with `0x0161` carries raw 3-byte coefficients at the current pointer.
  Both are decoded enough to name; neither is in `instruction-set.md`.

---

## 8. Reproduction

```
# the listing (byte-match verified)
python3 dsp/tools/gen_dsp_disasm.py && python3 dsp/verify.py

# the script walk that produced §1 and §2.1
#   op = b0>>4 ; len = (((b0&0x0F)<<8)|b1)-2 ; 0xF0 = END
#   scripts: 0x01E496 header, 0x01E63C output stage,
#            0x01F3F0[unit] disconnect, 0x01F404[unit] link,
#            0x01F3D0[chip] mute, 0x01F3E0[chip] antimute
#   (file offset = CPU address - 0x00EF00 in kn5000_subprogram_v142.rom)

# the 100-algorithm upload-address check of §2.4
#   walk 0x0001ED7C[0..99] -> stream -> first op-1/3 record -> addr16
#   result: 79 x I-RAM 84, 12 x I-RAM 200, nothing else   (= the 91 valid streams)
```

**CORRECTION, 2026-07-26 (re-measured).** This block previously said "88 x I-RAM
84". The ROM says **79**, which is what §2.4 says and what makes the arithmetic
close: 79 + 12 = the **91** valid streams. The remaining 9 of the 100 table
entries split two ways, which §2.4's parenthetical also blurred: **5** are the
`MALFORMED` set {79, 88, 89, 90, 91} and do target 1520 / 3376 (one and four
respectively), and **4** — algos 57, 58, 59, 60 — parse to **no I-RAM image at
all**. Nothing in §2.4's argument depends on the difference.

Sub CPU source: `archive/asl/subcpu/kn5000_subprogram_v142.asm`
(`DSP_BytecodeInterpreter_Loop`, `DSP_Bytecode_Op0E_SendCommand`,
`DSP_BytecodeInterpreter_CheckEnd`, `EFF_Link`, `EFF_Disconnect`, `EFF_WriteHeader`,
`DSP_AlgorithmChange`, `DSP_State_Dispatcher`, `LABEL_0387E6`, `LABEL_038922`,
`LABEL_0388B3`).
