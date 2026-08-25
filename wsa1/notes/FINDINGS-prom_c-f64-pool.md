# The math library's 77 double constants, each attributed to the routine that loads it

Wave 5, 2026-08-25.  Reproduce everything with

```
python3 notes/gen_prom_c_f64_pool.py --verify   # asserts every boundary and every claim
python3 notes/gen_prom_c_f64_pool.py --table    # the 77 constants with their consumers
python3 scripts/analysis/assert_byte_identical.py
```

`0xFCB27E-0xFCC53E` (4,801 bytes) was one `.incbin` whose header decoded six constants by
eye.  It is now three labelled objects in `prom_c/wsa1_prom_c.s`, and the image still
rebuilds byte-identically.

| range | bytes | what |
|---|---:|---|
| `0xFCB27E-0xFCB4E5` | 616 | `Float64_ConstantPool` — 77 IEEE-754 doubles |
| `0xFCB4E6-0xFCB4E9` | 4 | `Float32_One` — IEEE-754 float32 1.0 |
| `0xFCB4EA-0xFCC53E` | 4,181 | `BootRamImage_Head` — the start of the 4,312-byte block RESET copies to RAM `0x00E2DF` |

---

## 1. The boundaries are derived, not chosen

* The pool STARTS where `Shift8_Left`'s `retd` ends, at `0xFCB27E` — already established.
* 77 doubles at a stride of 8 land exactly on `0xFCB4E6`, and those four bytes decode as
  float32 1.0.  `0xFCB4E6` is the ONLY address in the whole range prom_c loads as a
  32-bit rather than a 64-bit quantity (from `0xFCB00A`, the site the tone-generator note
  already quotes for "`Float32_Multiply` is really `a / (1/b)`").
* `0xFCB4E6 + 4 = 0xFCB4EA`, with no gap, and `0xFCB4EA` is the SOURCE OPERAND of the boot
  RAM copy — `lda XIY,0xFCB4EA` at `0xF989EF`, read out of the instruction bytes by
  `notes/prom_c_ram_image.py`.  So the pool's end and the RAM image's start are one fact
  approached from two sides.
* **And the decode is its own evidence.**  At this base and this stride the 77 values come
  out as a textbook libm coefficient set.  One wrong byte in the base, or any stride but
  8, turns every one of them into a denormal.

## 2. What is in it

Recognisable constants, by pool index:

| entries | value |
|---|---|
| 0, 23 | pi/2 |
| 4 | pi |
| 6 | 1/pi |
| 27 | 2/pi |
| 45, 63 | ln 2 |
| 47 | 1/ln 2 = log2(e) |
| 65 | 1/sqrt 2 |
| 19, 42 | 2147483647.0 = INT32_MAX |
| 50, 68 | 8.988465674311579e+307 = DBL_MAX/2 |
| 53 | 2.2250738585072014e-308 = DBL_MIN |
| 40, 51 | 709.782712893384 = ln(DBL_MAX), the exp overflow bound |
| 39, 54 | -709.7827, its mirror |

**Entries [24] and [25] SUM to pi/2 bit-exactly** (`1.57080078125 + -4.454455103380769e-06`).
That is a two-word Cody-Waite split of one constant, not two constants, and `--verify`
checks the sum rather than describing it.

**The eight entries at `0xFCB2CE` alternate in sign and, read from the HIGH address
downwards, are 1/3!, 1/5!, 1/7! … 1/17!** — bit-exact at 1/3! and drifting to 3.2e-2
relative at the 1/17! end.  So it is a FITTED odd polynomial, not the Taylor series, and
`--verify` measures the drift instead of asserting "Taylor".

## 3. Every constant is named by its consumer

Each double is loaded as two 32-bit halves, so it appears in the image as a 24-bit address
operand at X and again at X+4.  **149** such sites exist across the whole 512 KiB; 147 are
inside the math library at `0xFC8000-0xFCB27D` and the other two are at `0xFBAA80` and
`0xFBBF53`.  The emitted source prints, beside every entry, the routine labels those sites
fall under — so a constant is documented by what loads it, not by my recognising the
number.

**54 of the 77 entries are loaded by a located site.  The other 23 are not unexplained:**
every one of them sits immediately after a loaded entry, in seven runs — the shape of a
coefficient ARRAY walked with a pointer from its first element.

| array | entries | head loaded by |
|---|---:|---|
| `0xFCB2CE` | 8 | `sub_FC8C45__FC8DDF` |
| `0xFCB376` | 3 | `sub_FBB793__FBBE57`, `sub_FC9140__FC93E4` |
| `0xFCB38E` | 5 | `sub_FC9140__FC9411` |
| `0xFCB436` | 3 | `sub_FC9844__FC9A68` |
| `0xFCB44E` | 4 | `sub_FC9ACB` |
| `0xFCB4A6` | 3 | `sub_FC9D12__FC9DD5` |
| `0xFCB4BE` | 4 | `sub_FC9D12__FC9E5E` |

The arrays at `0xFCB38E` and `0xFCB4BE` both END on exactly 1.0 — the shape of the
denominator of a rational approximation with a monic leading term.

## 4. ⚠ No routine is renamed on the strength of this

It is very tempting.  `sub_FC9844` loads ln 2, 1/ln 2, DBL_MIN, DBL_MAX/2 and both
±709.78 bounds; `sub_FC9D12` loads ln 2, 1/sqrt 2, DBL_MAX/2 and two rational-approximation
arrays; `sub_FC8C45` loads pi, pi/2, 1/pi and the eight-term odd polynomial; `sub_FC9140`
loads 2/pi, the Cody-Waite pi/2 pair and a 3+5 rational pair.  Those are the constant sets
of `exp`, `log`, a sine and a tangent respectively.

**But a constant set is not a routine body.**  `exp` and `pow` share the same bounds;
`sin` and `cos` share the same polynomial.  This tree's rule is `sub_XXXXXX` plus a stated
gap over a plausible guess, so the names stay and the gap is stated here: *reading five
routine bodies in `0xFC8BB2-0xFCA0B9` would settle it, and the constants say exactly where
to look.*

## 5. The RAM-image half

`BootRamImage_Head` is emitted as `.byte` rows with the DESTINATION RAM ADDRESS in each
row's comment and nothing else claimed.  Its internal layout is open;
`notes/FINDINGS-prom_c-ram-image.md` carries the individual defaults that have been pinned
down, and its own warning still applies: the copy runs on past `0xFCC53F` into the table
zone, which is why four objects there are relocated to RAM and patchable at run time.

## 6. ⚠ Converting this pool ADDED two phantoms to `notes/prom_c_frontier.py`

Recorded 2026-08-25 (wave-5 audit, finding 9), because it is a cost of the conversion and
the next wave will otherwise re-discover it.

`prom_c_frontier.py` disassembles every CONVERTED span linearly.  While `0xFCB27E-0xFCB4E5`
was one `.incbin` the tool skipped it; now that it is `.long`/`.byte` data inside a
converted span, unidasm decodes those bytes as instructions and emits **two new phantom
call sites, `0xFCB390` and `0xFCB4D4`**, whose "targets" are meaningless.

Neither is a defect in the pool decode — the byte gate is untouched — but it means the
frontier tool's from-site list for this image is now 110 real + 2 pool-induced phantoms,
and **the tool must not be used to rank targets inside `0xFCB27E-0xFCC53E`**.  The general
form of the warning is already in the tool's own LIMITS section; this is the concrete
instance.
