# A serial EEPROM, and the floating-point library CPU 2 does its arithmetic in

**Established 2026-08-25**, converting prom_c `0xFC89C5-0xFC8BB1` (493 bytes) and
`0xFCA0BA-0xFCB27D` (4,548 bytes). Every number below is re-derived from the ROM
by

```
python3 notes/prom_c_runtime_check.py
```

which matches **bytes**, never a disassembly, prints every check, and exits
non-zero on any failure.

---

## 1. The 62-byte calibration block comes from a Microwire serial EEPROM

`NoteTrim_BuildFromCalibration` (`0xF997FA`) has carried this since it was
converted:

> ⚠ `0xFC8B0B` is NOT CONVERTED … a 62-byte block with a checksum and a magic is
> what a stored calibration looks like; **WHERE it is read from is not
> established here**.

It is read one bit at a time off a serial EEPROM, by ten routines at `0xFC89C5`.

### The protocol is Microwire, and the four command words prove it

Four routines shift a **nine-bit** value out MSB-first (`ldb h,9`, test `0x0100`,
shift left, repeat):

| routine | word | 9-bit frame | Microwire instruction |
|---|---|---|---|
| `0xFC89C5` | `0x130` | `1 00 110000` | **EWEN** — erase/write enable |
| `0xFC89F7` | `0x100` | `1 00 000000` | **EWDS** — erase/write disable |
| `0xFC8A29` | `0x180 \| addr` | `1 10 aaaaaa` | **READ** |
| `0xFC8A62` | `0x140 \| addr` | `1 01 aaaaaa` | **WRITE** |

1 start bit + 2 opcode bits + 6 address bits, with **16** data bits (`ldb h,0x10`
in both the write and the read-back path) is the 64 × 16 organisation. EWEN and
EWDS differ only in address bits 5..4 (`11` vs `00`), which is exactly how the
standard distinguishes them — nothing else explains two commands sharing an
opcode field and differing there.

⚠ The **part** is inferred from the protocol: a 6-bit address with 16-bit data is
a 93C46-class device. Nothing in the ROM names it and no schematic was consulted.

### The three pins, and RESET's independent corroboration

| pin | role | how the driver uses it |
|---|---|---|
| P6 bit 5 | CS | `set 5,(P6)` opens every frame, `res 5,(P6)` closes it |
| P8 bit 3 | SK | `set` / `res` once per bit |
| P8 bit 4 | DI | driven from the bit being sent, before SK rises |
| P8 bit 5 | DO | only ever `bit 5,(P8)` — **never written** |

The census is derived, not eyeballed — a first draft of the check script asserted
hand-counted totals and failed on all four. What it asserts now is the *shape*:
P6 is touched at 11 sites and **every one is bit 5**; CS, SK and DI each have
exactly one more `res` than `set`, and all three extras are `EEPROM_PortInit`'s
opening trio at `0xFC8B9D`; and there is **no** `set 5,(P8)` or `res 5,(P8)`
anywhere in the driver.

RESET says the same thing from the other side. `ldio P6FC,0x1F` leaves P6 bit 5 a
plain port pin, and `ldio P8CR,0x19` sets bits 0, 3 and 4 and leaves **bit 5
clear** — the two pins the driver drives and the one it reads.
⚠ **P8CR's bit layout is not decoded anywhere in these trees**: MAME stores the
register and never reads it (`tmp95c061_device::port_cr_w` is a bare assignment
for every port but PORT_A) and no databook is available. The agreement is offered
as corroboration of the pin roles, not as a decode of P8CR.

### The stored block: 33 words, and a boundary that meets another structure

`EEPROM_LoadCalibration` reads words 0..0x1E into RAM `0x00E2A1` (31 words, 62
bytes), sums them, requires word `0x1F` to equal that sum and word `0x20` to equal
`0x5AA5`, and returns `XIY` = the RAM address or 0. Every boundary is one of its
own comparisons.

★ `0x00E2A1 + 31*2 = 0x00E2DF`, which is exactly where `RamImage_Copy`'s
4,312-byte boot copy begins. The EEPROM shadow and the ROM-initialised variable
block are adjacent, and neither figure was chosen to make that true.

⚠ **Nothing in prom_c ever writes a valid block.** The image's only EEPROM writer,
`EEPROM_WriteIndexPattern` (`0xFC8B82`), writes word *n* with the value *n* for
n = 0..0x1E and writes neither the checksum nor the magic — so a block it produced
would fail `EEPROM_LoadCalibration`'s own test. It has no caller found. Whether it
is a production test or a deliberate erase is **not established**, and its name
says only what it does.

---

## 2. `0xFCA0BA-0xFCB27D` is the compiler's runtime library — 38 routines

They are one module by construction: **every one ends in `retd`**, and the last
one ends at `0xFCB27E`, exactly where the pool of IEEE-754 double constants
begins. `prom_c_runtime_check.py` asserts that the 38 tile the range with no gap
and that each `retd` operand matches its header.

### The ABI, read off the code

1. `retd n` is callee cleanup and **n is the argument-byte count**. The values are
   2, 4, 6, 8 and 0x10, and 0x10 is used by exactly the five routines that read
   four 32-bit slots — two 64-bit doubles.
2. A result **wider than 32 bits is returned through a pointer in XIY**. Every
   double-producing routine ends `ld XIY,(XSP) / ld (XIY+),XIX / ld (XIY),XIX`,
   and every caller sets XIY with `lda XIY,XIZ+d` first.
3. Narrower results come back in XIY, or in WA for the classify/compare routines.

### The identifications, and what each rests on

The magic numbers split cleanly into two disjoint sets — double (`0x7FF0`
exponent, `0x0010` hidden bit) and single (`0x7F80`, `0x0080`) — and **no routine
mixes them except the two conversions between the formats**, which is what a
conversion has to do. The bias constants are the proofs:

| routine | instruction | value |
|---|---|---|
| `Double_Multiply` | `sub IX,0x03FE` after **adding** exponents | 1023 − 1 |
| `Double_Divide` | `add WA,0x0434` after **subtracting** them | 1023 + 53 |
| `Float32_Divide` | `add WA,0x0097` after subtracting | 127 + 24 |
| `Double_ToFloat32` | `sub WA,0x0380` | 1023 − 127 |
| `UInt32_ToDouble` | starts at `0x0413` | 1023 + 20 |
| `UInt16_ToDouble` | starts at `0x0403` | 1023 + 4 |
| `UInt32_ToFloat32` | starts at `0x0096` | 127 + 23 |

Add and subtract are named by their *callers*: `Double_Subtract` flips the second
operand's sign halfword and calls `Double_Add`, doing nothing else at all;
`Float32_Subtract` does the same over `Float32_Add`.

★★ **And the set is complete, which is the strongest evidence of all.** One
operation per routine leaves nothing unassigned and nothing duplicated: double and
single each get add, subtract, multiply, divide, negate, compare and classify plus
every conversion; the integers get 32×32 multiply and 32/32 divide with signed
wrappers; and the shifts cover 8, 16 and 32 bits × left / logical right /
arithmetic right. A wrong name anywhere would have to leave a hole somewhere else.

The **signed/unsigned wrapper** shape repeats six times and settles six of the
names: take absolute values, remember the sign, `call` the kernel, negate the
result. In five of the six the unsigned kernel is called from nowhere else in the
image; `Multiply32` is the exception, because it doubles as the general 32×32
helper (28 call sites).

### ★★ Float32 multiply is `a / (1 / b)` — two divisions

`Float32_Multiply` (`0xFCB005`) is 38 bytes and **contains no arithmetic at all**.
It loads the float32 at `0xFCB4E6` — the four bytes `00 00 80 3F`, i.e. exactly
1.0 — calls `Float32_Divide(1.0, b)`, then calls `Float32_Divide(a, that)`.

The argument order that reading depends on is settled inside `Float32_Divide`
itself: XIX comes from `(XIZ+0x08)` and XHL from `(XIZ+0x0C)`, WA takes XIX's
exponent and BC takes XHL's, and it computes `sub WA,BC` — so the **first** slot
is the numerator, and `a / (1/b)` is `a*b`. It is also the only float32 operation
left unassigned once every other routine is accounted for.

⚠ **This is a real numerical defect, not a curiosity.** Two divisions is two
roundings where a real multiply has one, and the reciprocal of any *b* that is not
a power of two is inexact. Anyone emulating or re-implementing this firmware with
a native float multiply **will get different bits**.

### CPU 2 does its work in floating point

Every one of the 38 entries has real callers — **1,274 `1D <target>` byte sites
image-wide**, which is an *upper bound* on the call count and not a measurement of
it (★ corrected 2026-08-25, round-2 audit F12: the census runs over every byte
offset with no instruction-boundary filter, exactly the scan `prom_a_call_graph.py`
and `prom_b_call_graph.py` both label an upper bound). *Every entry has at least
one site* survives as stated; the total is a ceiling.
The busiest:

```
Double_Multiply 230   Float32_ToDouble 169   Double_ToFloat32 164
Double_Subtract  91   Int32_ToFloat32   83   Double_Add        77
```

⚠ **A first draft of these headers said "no site found in prom_c" for most of the
module.** That was asserted without running the tool — the exact failure this tree
has had to retract before — and every one of those sentences was wrong. All 38
`Called from:` lines were rewritten from a census, and the total is now a check in
`prom_c_runtime_check.py`.

---

## 3. What this leaves

* `0xFC8BB2-0xFCA0B9`, **5,384 bytes**, decodes cleanly and contiguously as about
  twenty routines: the **double-precision math library** that sits on this
  runtime. Its routines take 64-bit pairs, call `Double_Add`, `Double_Multiply`,
  `Double_Divide`, `Double_Compare` and `Double_Negate`, and read 64-bit constants
  from the pool at `0xFCB27E`. The first of them, `0xFC8BB2`, loads π/2, 1.0 and
  0.0 and has four call sites. Naming them needs the constant pool decoded first;
  that is next round's work, not a guess for this one.
* The constant pool itself, `0xFCB27E` onward. Six of its doubles are already
  decoded and checked — π/2, 1.0, 0.0, π, 0.5, 1/π — and the rest look like
  polynomial coefficients. The same range also holds `0xFCB4EA-0xFCC5C1`, the
  4,312-byte source of `RamImage_Copy`.
* `Double_Compare` and `Float32_Compare` return 0, 1 or 2; **which code means
  which ordering was not traced**, and neither was `Double_Classify`'s.
* Rounding mode, NaN handling and overflow behaviour are not decoded. The routines
  have arms that force `0x7FF0` / `0x7F80` exponents, which is what infinity
  generation looks like, but no test was run.
* ⚠ `Multiply32_Signed`'s sign handling is **redundant** — the low 32 bits of a
  two's-complement product do not depend on operand signedness. Recorded as
  observed; nothing here explains it.
