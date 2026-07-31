# PRE-REGISTRATION §188 — restore the host payload's LSB (`dd >> 7`)

## The claim, PROVEN BY CONSTRUCTION in two independent notes

```
   k5-output-stage.md item 9 / k3-pointers.md §1.1 item 3:
       V = ((aa & 0x7F) << 17) | (bb << 9) | (cc << 1) | (dd >> 7)     tag = dd & 0x7F

   upd6383.cpp today, with §111's bit 31 ON (it is, in the shipped default):
       v = ((aa << 16) | (bb << 8) | cc) << 1
         =  (aa << 17) | (bb << 9)  | (cc << 1)
```

They agree except the device **drops `dd >> 7`, the payload's LSB**. 32 % of all host packets carry
it set, so a third of every host-programmed quantity in this machine is 1 LSB low.

⚠ `adjudication-round4.md` item D records that this retraction *"never reached"* six downstream
documents and *"finds 7 LIVE sites"*. This is one of them.

## ★ The control — bit-exact, quantitative, and computed BEFORE the run

The host stream contains the LFO sine table. Decoding those 24 packets both ways against the
ideal `round(0.95 × 2^23 × sin(2πk/24 + 0.1))`:

```
   PROVEN decode : max err 1 LSB, RMS 0.707      <- pure rounding
   DEVICE decode : max err 2 LSB, RMS 1.291
   tag bit 7 set in 12 of 24 -- exactly half, as a sine's LSBs should be
```

## Falsifiers

* **F1 — the gate fires**, and its count must equal the number of packets whose `dd` has bit 7 set.
  Zero ⇒ unreached; a count equal to *all* packets ⇒ the gate is mis-aimed.
* **F2 — ★ THE POINT, bit-exact.** Re-dump `m_rf[0x1D..0x40]` and fit. It must go
  **`max 2 LSB / RMS 1.129` → `max 1 LSB / RMS ≈ 0.707`**, and the 24 residuals must stop being
  **24/24 negative**. Any other outcome refutes it — including "improves but not to those numbers".
* **F3 — the null half.** Cells whose packet had `dd` bit 7 **clear** must be **bit-identical**.
  If they move, the change is not confined to the LSB and something else is wrong.
* **F4 — ★ standing rule 1.** `§70 ACCA` min vs max before any output claim. Expected `min 0 max 0`;
  a 1-LSB parameter correction is not predicted to break the silence.

## ⚠ A correction to my own working, recorded before the result

Fitting the measured table with a *free* amplitude and phase gave "mean residual exactly −1.000,
24 of 24 negative", and I tested "add 1 to every value", which improved it. **That was an
artefact**: a free fit lets `A`/`phi` absorb the per-value structure. The packet-level check shows
the deficit is **per value, set in 12 of 24** — not a uniform offset. The right test is against the
**ideal formula**, not against a fit to the corrupted data.

## What this does NOT claim

It is a 1-LSB correctness fix on host parameters. It is **not** expected to make the chip audible,
and it does not touch the alternate-encoding decode (§185–§187) or the pointer-delta rule.
