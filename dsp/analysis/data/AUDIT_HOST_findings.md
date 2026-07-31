# AUDIT_HOST — the four host-side notes against the CURRENT `upd6383` device

**Date 2026-07-31. Offline, read-only.** Scope: every claim graded **PROVEN BY CONSTRUCTION**
or **FORCED** (k5's `DETERMINED` = "forced by a constraint system" is counted as FORCED, per
that note's own preamble) with **operational content**, in

* `dsp/analysis/k5-output-stage.md`
* `dsp/analysis/k3-pointers.md`
* `dsp/analysis/host-side.md`
* `dsp/analysis/register-space.md`

checked against `/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383/upd6383.cpp`
and `upd6383d.h` **as they stand today** (`upd6383.cpp` mtime 2026-07-31 03:25), not against any
note's description of them. Nothing in `kn7000_mame` was modified; no build, no MAME run.

Shipped speculative mask: `m_specmask = 0xb910e446a39b440f` (`upd6383.h:911`). Bit states quoted
below were computed from that literal, not read from a comment.

New tool (mine, in this repo): `dsp/tools/audit_host_packets.py` — replays both uC-IF captures
through the device's decode and through the notes' decode and diffs the three address spaces.
Every number in findings **H-1** and **H-2** comes out of it.

---

## 0. Headline

| rank | finding | class | control? |
|---:|---|---|---|
| **1** | **`0x0B` poke packets are thrown away** — `if (m_poke[0] == 0x0a)` rejects the sixth host word form, so 4 of the cold boot's 119 tag-`0x15` packets are lost **and the auto-increment stalls**, shifting everything after them | **MISMATCH** | ★ **YES — bit-exact and independent** |
| **2** | **The delay-descriptor cursor has no per-unit base** — the unit-1 reverb walks unit-0's descriptor cells `0x26..`, i.e. CHORUS's tap addresses, all of which are in the *other* unit's DRAM half | **ABSENT** | ★ **YES — 30 of 32 cells ≥ `0x8000`** |
| **3** | **The per-unit CALL VECTOR is stored and not used** — `m_vec[]` is written by `setvec`, the sequencer jumps to hard-wired `UNIT0_ENTRY`/`UNIT1_ENTRY`, so DISCONNECT is a no-op | **MISMATCH** | partial (live, not static) |
| **4** | **uC-IF command `0x04` (the chip's real MUTE) is ignored** | **ABSENT** | ⚠ **incomplete** — the capture holds only the mute half |
| **5** | **K3's FORCED "`0x821` is NOT the cursor" is violated by default** — mask bit 12 is **CLEAR**, so `is_ldptr` *does* seed `m_cursor` | **IMPLEMENTED-BUT-OFF (bit 12)** | yes (K3 §4.2, already in the file's own ⛔ comment) |
| 6 | The READY pin is a constant `0x01` in the driver | **ABSENT** | yes (the firmware's own two error paths) |
| 7 | `is_rstcur` resets the cursor to `0`, not to the per-unit base | latent MISMATCH | n/a today (only corpus site is unit-0) |
| 8 | An `801.0.NN.821` word inside an **I-RAM upload** moves the host's C-RAM write pointer | MISMATCH (harmless today) | no |

---

## 1. The full table

Legend — **IMPLEMENTED** / **MISMATCH** (device does something the note contradicts) /
**ABSENT** (nothing in the device implements it) / **N-A** (the claim is about Sub-CPU firmware
that MAME executes from the real ROM, so the device is not the place it lives) /
**IMPLEMENTED-BUT-OFF** (present behind a `m_specmask` bit; bit number given).

### 1.1 `k5-output-stage.md`

| id | claim (operational content only) | grade | device | code | control |
|---|---|---|---|---|---|
| K5-1 | uC-IF script bytecode: `op = b0>>4`, `len = (((b0&0x0F)<<8)\|b1) − 2`, `0xF0` = END | PROVEN BY CONSTRUCTION | **N-A** | interpreted by the emulated TLCS-900 out of the real ROM | — |
| K5-2 | the 83-word resident kernel is two literal canned blobs; **no kernel word is constructed** | PROVEN BY CONSTRUCTION | **N-A** (consistent: I-RAM is written only by `host_w`) | `upd6383.cpp:1030-1044` | — |
| K5-3 | I-RAM **64** = unit 0, I-RAM **71** = unit 1; units 2/3/4 are DSP2 registers | PROVEN BY CONSTRUCTION | **IMPLEMENTED** | `upd6383d.h:785-787` `is_vector_lo12(lo)= lo==0x445\|\|lo==0x446`, `vector_unit(lo)=(lo==0x446)?1:0` | — |
| K5-5 | the `C40/C41` immediate is `A = bits[24:17]`, `B = bits[16:12]`, family predicate `(hi12 & 0xFFE) == 0xC40` | MEASURED 61/61 (= RS-B2 FORCED) | **IMPLEMENTED** | `upd6383d.h:74-77` `is_c40(w){return (hi12(w)&0xffe)==0xc40;}` / `c_a(w){return u8((w>>17)&0xff);}` | — |
| **K5-6** | **I-RAM 64/71 load the per-unit CALL VECTOR**; LINK = 84/200, DISCONNECT = 42/50 | **DETERMINED** (= FORCED) | ★ **MISMATCH** | `upd6383.cpp:3607-3617` stores `m_vec[…] = c_a(word)` with *"deliberately NOT wired to the call sequencer"*; `upd6383.cpp:4352-4354` `m_pc = (unit1 ? UNIT1_ENTRY : UNIT0_ENTRY) * WORD_BYTES;` (`upd6383.h:227-228`, 84 / 200) | partial — see §2.3 |
| **K5-7** | **the DSP's real mute is uC-IF `cmd 0x04`, data byte 3 = `0x3F` mute / `0x00` unmute** (and "disconnect" is *not* attenuation) | PROVEN BY CONSTRUCTION | ★ **ABSENT** | `upd6383.cpp:861-865` `if (m_host_cmd != 0x01) { m_host_pos++; return; }` | ⚠ incomplete — see §2.4 |
| K5-9 | packet decode `V = ((aa&0x7F)<<17)\|(bb<<9)\|(cc<<1)\|(dd>>7)`, `tag = dd & 0x7F` | PROVEN BY CONSTRUCTION | **IMPLEMENTED** (§111 bit 31 **ON**, §188 bit 63 **ON**) | `upd6383.cpp:888-932`. `(v<<1)&0xffffff` makes the `aa&0x7F` mask redundant — the bit that would survive is masked off — so the two forms are algebraically identical | shipped §188 |
| K5-§1.2 | `addr8` is exactly bits `[19:12]`; the writer hard-zeroes `class4` | PROVEN BY CONSTRUCTION | **IMPLEMENTED** | `upd6383d.h:39-42`; `is_regload()` at `:757` requires `class4(w) != 0 → false` | — |
| K5-§1.3 | tag `0x26` ↔ `…821`, tag `0x4C` ↔ `…825`, tag `0x15` ↔ `000.1.NN.000` | PROVEN BY CONSTRUCTION | **IMPLEMENTED** | `upd6383.cpp:934-987` | — |
| K5-§7 | `cmd 0x01` target `0x0160` carries 5-byte host packets; `cmd 0x02` target `0x0161` carries **raw 3-byte** coefficients at the current pointer | decoded | **IMPLEMENTED**, and verified correct here | `upd6383.cpp:832-859`; no `×2` is applied on this path, which is right: cold-boot transfers 6/8 decode raw to `0x008000 + 1024·k` (TABLE A) and `1214·k` (TABLE B), k3 §2.1's two laws, exactly | ★ my replay |

### 1.2 `k3-pointers.md`

| id | claim | grade | device | code | control |
|---|---|---|---|---|---|
| K3-A | reg-load word = `hi12 0x801, class4 0, addr8 = 8-bit payload, lo12 = 0x8**`; **`lo12` bit 11 is a separate FLAG on a low byte** | PROVEN BY CONSTRUCTION | **IMPLEMENTED** | `upd6383d.h:178-180` `lo_sel = lo12&0xff`, `lo_imm = BIT(w,11)`, `lo_mid`; `is_ldptr` / `is_rstcur` differ **only** in `lo_imm` (`:769-772`) | — |
| K3-C | the host uses **exactly three** register-set forms; there is no fourth | PBC + MEASURED | **IMPLEMENTED** | `upd6383.cpp:983-987` | but see **H-1**: the `else` arm is also the dumping ground for anything that is not one of the three |
| K3-D | the three tags are **three distinct memory spaces** | **FORCED** | **IMPLEMENTED** (tag `0x15` → `m_rf` gated on bit 23, which is **ON**) | `upd6383.cpp:953-956` `if (m_specmask & 0x800000) m_rf[…] = v; else m_dram.write_dword(…)`; `:961` `m_dscbank[…]`; `:968` `m_cram.write_dword(…)` | — |
| **K3-F** | **`0x821` is NOT the implicit coefficient cursor** — the C-RAM has ≥ 2 independent pointers | **FORCED** | ★ **IMPLEMENTED-BUT-OFF, bit 12** | `upd6383.cpp:3667-3668` `if (!(m_specmask & 0x1000)) m_cursor = ad;` — bit 12 = **0**, so the K3-violating coupling is **live**. The file's own comment says *"⛔ STILL AGAINST K3"* | yes — see §2.5 |
| K3-J | ≥ 3 pointer registers, ≥ 2 of them per-unit live (`0x821`, `0x827`, `0x825`) | **FORCED** | **PARTIAL** — `0x821`→`m_cp`, `0x825`→`m_dsc`; **`0x827` is not decoded** | `upd6383d.h:761` accepts selector `0x27` in `is_regload` but no `is_ldptr*` claims it | n/a — K3 §5.1 leaves `0x827`'s space **OPEN**, so refusing it is honest |
| K3-§4.2 | the C-RAM cursor **must be reset to its per-unit base every frame** by a word that is *not* a pointer-load word (22 measured advances before the unit-0 call, and the body must read `0x00`) | **FORCED** | **IMPLEMENTED**, bit 38 **ON** | `upd6383.cpp:4473-4477` `if (m_specmask & 0x4000000000ull) { m_cursor = unit1 ? 0x90 : 0x00; }` — placed at the CALL, which K3 lists as candidate 1 of 3 | — |
| K3-§1 | all five word forms are **uPD6383-only**; the `IZ==1` arm emits `cmd 0x30` + a 16-bit value (DSP2) | PROVEN BY CONSTRUCTION | **IMPLEMENTED** (`0x30` ignored) | `upd6383.cpp:861-865` | — |
| K3-§3.3 | the payload is an **8-bit absolute address** in that register's own space; no relative/bank reading | PBC (width) | **IMPLEMENTED** | `m_cp = ad` (`:3660`), `m_dsc = ad` (`:3676`), `m_dram_wp = ad` (`:986`) | — |
| K3-§1.1.3 | = K5-9 | PBC | IMPLEMENTED | | |
| **K3-§7.6** | **a sixth host word form exists: `0B .. .. .. 15`** — the leading nibble `0xA`/`0xB` is a **flag on the packet**, not part of the 24-bit value; 12 occurrences across the two captures | MEASURED, meaning OPEN | ★ **MISMATCH** | `upd6383.cpp:886` `if (m_poke[0] == 0x0a)`; everything else falls to `:976-988`, where it matches no pointer form and is counted `m_pk_other++` — **the value is dropped AND the write pointer does not advance** | ★ **YES** — §2.1 |
| K3-§7.7 | the host injects `000.2.00.000` (the `nop` form) **three times** in the PEQ stream, matching no known form | MEASURED | **IMPLEMENTED** (counted as `m_pk_other`) | — | ★ my replay finds exactly **3**, word `0000200000`, 3/3 |
| K3-L | `A = imm13>>5` is a `0xC40`-family rule (57/57 in, 2/11 out) | MEASURED | **MISMATCH (display only)** | `upd6383d.cpp:936` prints `{C-fmt A=%d B=%d}` for **every** `c_format(word)` | — |

### 1.3 `host-side.md`

| id | claim | grade | device | code | control |
|---|---|---|---|---|---|
| HS-A1 | opcode → evaluator → writer → space, 28 of 28; exactly four writers | PROVEN BY CONSTRUCTION | **N-A** (host firmware) | — | — |
| HS-A2 | the relocation base is **zero** ⇒ `cell = T1[opcode][operand]` | **FORCED** | **N-A** | — | — |
| HS-A3 | opcode `0x74` uploads a **36- or 32-entry table** into the tag-`0x15` space at base cell **`0x1D`** | PBC + MEASURED | **IMPLEMENTED** | select `000.1.1D.000` → `m_dram_wp = 0x1D` (`:986`), then 36 auto-incrementing packets → `m_rf[0x1D..0x40]` | ★ already discharged: `LEDGER-HEAD` §161 measures the resident table as `0.95·2²³·sin(2πk/24+0.1)` to 2 LSB, period 24 |
| HS-A4 | **the write port auto-increments, `\|step\| = 1`** (writer `0x038606` emits a datum with **no address word**) | **PROVEN BY CONSTRUCTION** | **IMPLEMENTED** for all three spaces | `:957` `m_dram_wp = u8(m_dram_wp + 1)`; `:962` `m_dsc_wp = u8(m_dsc_wp + 1)`; `:969` `m_cram_wp = u8(m_cram_wp + 1)` | — |
| HS-C5 | `MALFORMED {79,88,89,90,91}` are **DSP2** programs (`cmd 0x30`, load addr `0x05F0`/`0x0D30`) | PROVEN BY CONSTRUCTION | **IMPLEMENTED** | `cmd 0x30` ignored (`:861`); out-of-range I-RAM writes refused with `logerror` (`:1046-1050`) | — |
| HS-C4 | command census; **`0x0160` is a poke PORT, not an I-RAM address** | MEASURED | **IMPLEMENTED** | `upd6383.h:1126` `POKE_PORT = 0x0160`; `upd6383.cpp:877` | — |
| HS-C1 | the chip has a **READY output register**, polled twice per byte, 8000-poll timeout, two distinct error returns; the firmware then **silently drops the record** | MEASURED | ★ **ABSENT** | `src/mame/matsushita/kn5000.cpp:1175` `m_subcpu->porth_read().set_constant(0x01);` — the note names this line itself | yes (the firmware's own error paths) — but it is a **driver** change, outside `upd6383/` |
| HS-C3a | `/RD` has **zero call sites**; the host stream is a pure write log | MEASURED | **IMPLEMENTED by construction** (device exposes no read path) | — | — |
| **HS-§2** | the three spaces are unit-partitioned with **opposite polarity**: D-RAM u0 `<0x80` / u1 `≥0x80`; C-RAM u0 `<0x80` / u1 `≥0x90`; **DESCRIPTOR u1 `0x00..0x1F` / u0 `0x26..0x39` — INVERTED** | MEASURED, 403 sites, and the *sharpest* control in the note (`ms` 38/38 vs 2/100 vs 2/265) | D-RAM **IMPLEMENTED** (`DRAM_UNIT_BASE \| unit<<7`, `:4450`); C-RAM **IMPLEMENTED** (`:4475`); ★ **DESCRIPTOR: ABSENT** | `upd6383.cpp:3676` `m_dsc = ad` (only source, = `0x25` from *both* header blocks); `:1852` `m_dscbank[u8(m_dsc + m_delay_ix)]`; `:4569` `m_delay_ix = 0` **per frame, not per unit** | ★ **YES** — §2.2 |

### 1.4 `register-space.md`

| id | claim | grade | device | code | control |
|---|---|---|---|---|---|
| RS-A2 | VOLUME = 24-bit **unsigned Q0.23 linear gain** at D-RAM `0x06`/`0x86`, `TABLE[sel][0..99]`, `TABLE[*][0] = 0` (v = 0 exact mute) | **FORCED** | **IMPLEMENTED** (value + cell). The *point of application* is guessed and gated on bit 23 (**ON**) | `upd6383.cpp:1600-1607` `const u32 lvl = (m_specmask & 0x800000) ? m_rf[unit ? 0x86 : 0x06] : …; if (lvl) scaled = (scaled * sext(lvl,24)) >> 23;` | — |
| RS-B2 | the `is_c40` immediate is **8 bits**; `B == 0` in 7/7 forms, 57/57 words, 2/2 host words | **FORCED** | **IMPLEMENTED** | `upd6383d.h:74-77` | — |
| RS-D1 | the host write port's auto-increment is **+1** (enumeration `{0,+1,+2,+4,−1}`; tiling leaves `{+1,−1}`; algo-39 abutment breaks it) | **FORCED** | **IMPLEMENTED** | as HS-A4 | — |
| RS-D2 | the datum's byte 1 is `(v>>17)&0x7F`, **not** `(v>>1)&0x7F` (shift count 0 = 16 on TLCS-900) | **FORCED** | **IMPLEMENTED** (device reconstructs `v` directly; equivalent) | `:888` + `:906-931` | 1751/1751 vs 938/1751 |
| RS-§9 | `w72`/`w77`'s cell is a Q0.23 gain from a dB curve table, **cleared at load** | **FORCED** | **IMPLEMENTED** | as RS-A2 | — |
| RS-E2 | the descriptor space is **partitioned by unit**: u1 `0x00..0x1F` (12/12), u0 `0x26..0x39` (79/79) | MEASURED | ★ **ABSENT** — same defect as HS-§2 | `:1852` | ★ **YES** — §2.2 |
| RS-§1.1 | **44 of 1751 canned packets carry byte 0 = `0x0B`**, all targeting **even** cells of the `0x50…` state block (the cells that hold delay lengths) | MEASURED, meaning OPEN | ★ **MISMATCH** — same defect as K3-§7.6 | `:886` | ★ **YES** — §2.1 |
| RS-B3 | the five `lo12 = 0x820` words are the register-load family with a **wide** immediate | CONSISTENT | honest: `is_regload` admits selector `0x20`, no `is_ldptr*` claims it, the words trap | `upd6383d.h:761` | — |
| RS-C2 | the mode-1 space splits host-primed / never-primed | MEASURED — **but FALSIFIED by `host-side.md` B1/B3** (`0x0E` is both; the split is at chance) | **correctly not implemented** | — | ★ this is the note-staleness trap in this set: do **not** build on RS-C2 |

---

## 2. The findings that matter, with their controls and falsifiers

### 2.1 ★ H-1 — the `0x0B` poke packet is discarded, and the pointer stalls with it

**The note.** `k3-pointers.md` §7 item 6 and `register-space.md` §1.1 both record a **sixth host
word form**: a tag-`0x15` packet whose leading byte is `0x0B` instead of `0x0A`. k3: *"the leading
nibble `0xA` vs `0xB` is a real flag on the packet, **not part of the 24-bit value**"*.
register-space: *"the writer emits byte 0 as a literal `0x0A`, but **44 of the 1751 canned packets
carry `0x0B`**. All 44 target **even** cells of the `0x50…` state block (the cells that hold delay
lengths)."*

**The device.** `upd6383.cpp:886`

```cpp
if (m_poke[0] == 0x0a)
{   // DATA packet: 0A | dd dd dd | TAG
```

with the `else` arm at `:976-988` treating the five bytes as an instruction word. A `0x0B` packet
decodes there to `class4 = 0`, `lo12 = 0x815` — none of the three pointer forms — so it falls to
`m_pk_other++`. **The value is lost and `m_dram_wp` does not advance**, so every packet after it in
the run lands one cell low.

**The measurement** (`python3 dsp/tools/audit_host_packets.py`, cold-boot capture):

```
  poke byte0 histogram : {0x00: 23, 0x08: 19, 0x0a: 115, 0x0b: 4}
  DEVICE  packets 115  ptr 42  other 4
  NOTES   packets 119  ptr 42  other 0
  tag 15 : device 55 cells, notes 59 cells, 6 cells DIFFER
        50: 0x000000 -> 0x000190
        52: 0x000000 -> 0x0005A0
        54: --       -> 0x0009B0
        55: --       -> 0x000000
        56: --       -> 0x000DC0
        57: --       -> 0x000000
```

Four values lost, two more cells never written at all, and the run truncated by two cells — from a
**two-character** difference in one predicate.

**★ THE CONTROL — bit-exact, independent, and in the same capture.** The four numbers the `0x0B`
packets carry are `400 / 1440 / 2480 / 3520`. The **delay-descriptor space** — tag `0x4C`, a
different writer, a different pointer register (`…825`), a different memory — holds the same four
numbers at cells `0x26 / 0x28 / 0x2A / 0x2C`:

```
  tag-4C 26..2D :  26=400  27=4161  28=1440  29=0  2A=2480  2B=1040  2C=3520  2D=2080
```

which is `register-space.md` §6.2's canned CHORUS descriptor image **exactly**, and its own
sentence: *"CHORUS writes the same four tap lengths **twice** — into descriptor `26/28/2A/2C`
**and** into D-RAM `50/52/54/56`, with `51/53/55/57 = 0`."* Under the notes' decode the device
reproduces `(400,0),(1440,0),(2480,0),(3520,0)` at `0x50..0x57`; under the current decode it
produces `0,0,0,0` and two unwritten cells. This is the same shape of control as §188's LFO sine —
a quantity derived somewhere else that the change must reproduce, not a score.

**Two-sided falsifiers.**
* **F1 — the gate fires, and its count is pinned.** Exactly **4** in a cold boot and **18** in the
  PEQ vehicle. Zero ⇒ unreached. A count equal to *all* packets ⇒ mis-aimed.
* **F2 — ★ bit-exact.** `m_rf[0x50..0x57]` must read `000190 000000 0005A0 000000 0009B0 000000
  000DC0 000000`, and must equal `m_dscbank[0x26] / [0x28] / [0x2A] / [0x2C]` value-for-value.
  Any other outcome refutes it — including "some cells move but not to those numbers".
* **F3 — the null half.** Every tag-`0x15` cell outside `0x50..0x57` must be **bit-identical**
  (only 6 of 59 cells may move), and the tag-`0x26` and tag-`0x4C` maps must not move at all
  (my replay: 0 cells differ in both).
* **F4 — standing rule 1.** `§70 ACCA` min vs max before any output claim. A delay-length
  correction is not predicted to break the silence on its own.

**The diff.** One predicate: `if (m_poke[0] == 0x0a || m_poke[0] == 0x0b)`. ⚠ Keep the flag —
record `m_poke[0] == 0x0b` in a counter rather than discarding it; both notes label its *meaning*
OPEN, and this change asserts only that the packet is a packet, which is what "not part of the
24-bit value" says.

---

### 2.2 ★ H-2 — the delay-descriptor cursor has no per-unit base

**The notes.** `register-space.md` **E2** (MEASURED, read off the host's own 100 canned streams):
*"the descriptor space is PARTITIONED BY UNIT … unit-1 owns `0x00..0x1F` (12 of 12 reverbs,
identical extent), unit-0 owns `0x26..0x39` (79 of 79)."* `host-side.md` §2 states the same and
calls out that this polarity is **inverted** relative to C-RAM and D-RAM, and §3 names the cell:
*"the reverbs' PRE DELAY lives at descriptor cell `0x00`, a LOW address."* `k3-pointers.md` §2.3
independently derives the boundary set of that space as exactly `{0x00, 0x26}`.

**The device.** The descriptor cursor is `m_dsc + m_delay_ix`:

```cpp
:1852   : u32(m_dscbank[u8(m_dsc + m_delay_ix)]);
:3676   m_dsc = ad;                      // the ONLY writer -- in-program ldptr.d
:4569   m_delay_ix = 0;                  // reset per FRAME, not per unit
```

`m_dsc` can only come from an in-program `801.0.NN.825`, and the kernel loads **`0x25` for both
units** (`w44` and `w52`, k3 §3.2). So the unit-1 body continues walking from wherever unit 0 left
off, inside unit-0's block. Nothing in the device ever addresses `0x00..0x1F`.

**★ THE CONTROL — the cold-boot capture, decoded and split by the notes' partition:**

```
  tag-4C 00..1F (unit 1, ROOM REVERB 1)
     00=33255 01=0 02=41925 03=32768 04=42494 05=41590 06=43201 07=41925
     08=44451 09=42494 0A=46125 0B=43201 0C=46605 0D=44451 0E=47117 0F=46125
     10=47987 11=46605 12=48665 13=47117 14=49565 15=47987 16=50405 17=48665
     18=34634 19=35886 1A=36847 1B=34326 1C=35573 1D=35882 1E=32767 1F=49565
        -> 30 of 32 cells are >= 0x8000

  tag-4C 26..2F (unit 0, CHORUS)
     26=400 27=4161 28=1440 29=0 2A=2480 2B=1040 2C=3520 2D=2080 2E=32768 2F=3120
        ->  9 of 10 cells are <  0x8000
```

That is `k3-pointers.md` §7 item 1 / `r3-delaydram.md` P5's **region allocation** — unit 0 owns
external DRAM `[0x0000, 0x8000)`, unit 1 owns `[0x8000, 0x10000)` — reproduced from the live
capture, and it is the sharpest possible statement of the defect: **the emulated reverb is
currently fetching tap addresses that lie in the other unit's half of the delay RAM**, i.e.
CHORUS's four chorus taps.

**Is the fix forced?** The *defect* is; the *site* is not, and this must be said. K3 §4.2's
argument transfers verbatim: the two header loads are **identical** (`0x25` both times) yet the
two units must reach **disjoint** blocks, so the base cannot be carried by a pointer-load word —
exactly the elimination that forced the C-RAM cursor's per-unit reload, which this device already
implements at the CALL (mask bit 38, `:4473`). The parallel change is one line beside it, plus
`m_delay_ix = 0` at the call rather than only at frame end.

**Two-sided falsifiers.**
* **F1** — the device already prints the first 8 distinct descriptor cells consumed and their
  values (`m_dly_dsc` / `m_dly_val` / `m_dly_dir`, `:1858-1873`). Under the fix the unit-1 body's
  cells must fall in `0x00..0x1F` and the unit-0 body's in `0x26..0x39`. If either escapes its
  window, the reading is wrong.
* **F2 — ★ the quantitative half.** Every descriptor value the unit-1 body consumes must have
  **bit 15 set** (30/32 of that block do; the two exceptions are `01 = 0` and `1E = 32767`, and
  `1E` is k3 §7's *clamp*). Values below `0x8000` arriving at unit 1 refute it.
* **F3 — the null half.** Unit 0's delay path must be **bit-identical** — same cells, same values,
  same `m_dly_*` census.
* **F4** — `§70 ACCA` min vs max before any output claim.

---

### 2.3 H-3 — the per-unit CALL VECTOR is stored and never used

`k5-output-stage.md` item 6 / §2.4 (**DETERMINED**, and §6 hands it to K1 explicitly: *"An
emulation can implement the tagged word as 'empty stack ⇒ push, PC ← vec[tag]; non-empty ⇒ pop'
and get the disconnect no-op for free"*). The device:

```cpp
:3607   if (upd6383_disassembler::is_setvec(word))
:3615       m_vec[vector_unit(lo12(word))] = c_a(word);     // "deliberately NOT wired"
:4352   m_pc = (unit1 ? UNIT1_ENTRY : UNIT0_ENTRY) * WORD_BYTES;   // 84 / 200, hard-wired
```

**Consequence:** DISCONNECT (42 / 50) is unobservable. `k5` §2.1's dispatcher order shows
`EFF_DisconnectLoop` running at *every* algorithm change and `EFF_SecondaryLinkPath` disconnecting
*every unit whose enable flag is 0* — so in the emulator a disabled effect unit still executes its
body every frame, and the reload window is not silent.

**Control:** partial. It is a live control, not a static one: the host's own `cmd 0x01 / 0x0040`
and `/0x0047` writes carry the value, and the device already logs I-RAM writes. There is no
capture in the repo showing a *disconnect* value, so the 42/50 half is unwitnessed here.
**Two-sided falsifier:** after the wiring, `m_vec[0]` must read 84 whenever a unit-0 body is
linked, and the frame's slot count must drop by the body length exactly during a reload; if
`m_vec[]` is ever 0 at a call, the wiring is wrong — ⚠ note the **canned boot default**
`011.9.0E.445` is *not* `is_c40`, so `m_vec[]` is 0 until the host writes, and any wiring must fall
back to 84/200 while unset (k5 §2.2's "third state", MEASURED).

### 2.4 H-4 — uC-IF `cmd 0x04` (the real mute) is ignored

`k5-output-stage.md` item 7, **PROVEN BY CONSTRUCTION**: *"the DSP's real mute is a different
mechanism entirely (uC-IF cmd `0x04`, data byte 3 = `0x3F` mute / `0x00` unmute)"*, scripts at
`0x01F3D0` (mute) / `0x01F3E0` (antimute). The device drops every command but `0x01`/`0x02`.

⚠ **The control is incomplete and this is why it must not ship blind.** The only capture in the
repo (`host-side.md` §6.3) contains `cmd 0x04 payload FB DA 3F A0 1A ×2` — **both the mute half**,
never `FB DA 00 A0 1A`. Implementing mute from the capture alone would leave the emulated chip
muted forever. **Before implementing:** read the two scripts out of the Sub CPU ROM and confirm
which payload byte carries it and that `DSP_UnmuteLoop` is on the live path. That is static work
and cheap; it is not done here.

### 2.5 H-5 — K3's FORCED "`0x821` is NOT the cursor" is violated by the shipped default

```cpp
:3667   if (!(m_specmask & 0x1000))
:3668       m_cursor = ad;              // ldptr seeds the coefficient cursor
```

Mask bit 12 = **0** in `0xb910e446a39b440f`, so this fires. `k3-pointers.md` item **F** is
**FORCED** against it. The file records the conflict itself (*"⛔ STILL AGAINST K3"*). In practice
the damage is bounded: the per-unit rebase at the CALL (bit 38, ON) overwrites the seed before
either body runs, so the violation only affects kernel words 43–49 / 51–59 and the epilogue from
`iw69`. Reported here as the **IMPLEMENTED-BUT-OFF** category the brief asks for: the K3-compliant
behaviour exists and is one bit away (`m_specmask |= 0x1000`).

### 2.6 Minor

* **H-7** `:3687` `m_cursor = 0;` in `is_rstcur` — K4/K3 give the base as **per-unit** (`0x00` /
  `0x90`); the comment says so and calls 0 a placeholder. The only corpus site is `algo39 w58`, a
  unit-0 body, so nothing is wrong today. One-liner: `m_cursor = m_cur_unit1 ? 0x90 : 0x00;`.
* **H-8** `:1010-1028` — a `801.0.NN.821` word arriving inside an ordinary **I-RAM upload** sets
  `m_cram_wp`. No note says an upload has that side effect; K3 A/E say the word does it when
  **executed**. Sites are kernel `w42`/`w50` and epilogue `iw69` (bodies are 0/2974, K3 item K),
  all uploaded before the coefficient stream, so the impact today is nil. Flagged because the
  comment justifying it cites *"captured transfer 26: `01 60 | 08 01 09 78 21`"*, which now takes
  the **poke** branch — i.e. the comment describes a path this block no longer serves.
* **H-6** `kn5000.cpp:1175` `porth_read().set_constant(0x01)` — `host-side.md` C1/C2 (MEASURED)
  and its own §10 item 6 name this line. Driver-side, outside `upd6383/`.
* `upd6383d.cpp:936` prints `{C-fmt A=… B=…}` for every `c_format` word; K3 item L measures the
  split at 57/57 inside `(hi12&0xFFE)==0xC40` and 2/11 outside. Display only.

---

## 3. Note-staleness check (the brief's ★ caveat), performed

Three places where a note would have sent this pass backwards, all resolved against the **current**
source:

1. **`host-side.md` §10 item 6 and `register-space.md` §1** both describe the host poke port as
   unreached / "the host's only write path reaches C-RAM". **Both are stale.** `upd6383.cpp:872-877`
   implements `POKE_PORT`, and `:1590-1600` records the correction in the past tense. The
   tag-`0x15`, `0x4C` and `0x26` routes all exist today.
2. **`register-space.md` C2** ("host-primed = RAM state, never-primed = a hardware register") is
   **falsified inside this very set** by `host-side.md` B1/B3. It is *correctly* not implemented.
   Anyone mining `register-space.md` for leads must read `host-side.md` §5 first.
3. **`k5-output-stage.md` §7** says *"nothing here was synced to MAME"*. Items 2 and 5 of its §5
   **have** been synced since (`is_c40`, `c_a`, `c_b`, `is_setvec`, the C-format guard on
   `coeff_consumer`). Only item 3's *use* of the vector (§2.3 above) has not.

Grades used above: **MEASURED** where a number was produced by the replay tool in this pass;
**FORCED** where the note's own elimination is reproduced; **INFERRED** nowhere in §2's
conclusions. What I **cannot** verify offline: whether H-1 and H-2 change the emulated audio — both
are parameter-path corrections and neither is predicted to break the standing silence on its own.

## 4. Reproduce

```
python3 dsp/tools/audit_host_packets.py
# needs ~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_{coldboot,parametriceq}.txt
```
