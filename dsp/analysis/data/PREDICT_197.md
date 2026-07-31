# PRE-REGISTRATION §197 — accept `0x0B` poke packets (the leading nibble is a FLAG, not a constant)

`upd6383.cpp:886` tests `if (m_poke[0] == 0x0a)`. `k3-pointers.md` §7 item 6 and
`register-space.md` §1.1 both record `0B .. .. .. 15` as the **same tag-`0x15` packet with one extra
flag bit**. The device falls through to its instruction-word arm, so the value is discarded **and
the auto-increment stalls**, shifting the rest of the stream one cell low.

Measured in the TYPE-walk capture: **44 of 3456 packets (1.3 %) lead with `0x0B`**, 42 tagged `0x15`
and 2 tagged `0x95`.

## ★ The control — bit-exact, independent, and already in hand

The four lost values are `400 / 1440 / 2480 / 3520`, and §189's live descriptor-bank dump — taken
two ticks ago for an unrelated purpose — reads:

```
   0x26 = 0x0190 = 400      0x28 = 0x05A0 = 1440
   0x2A = 0x09B0 = 2480     0x2C = 0x0DC0 = 3520
```

**Cell for cell.** Written by a different writer, through a different pointer register, into a
different memory — `register-space.md` §6.2's *"CHORUS writes the same four tap lengths twice"*.

## Falsifiers

* **F1 — the gate fires**, count > 0 and ≈ 1.3 % of packets. Zero ⇒ unreached.
* **F2 — ★ the point.** §186's host-write census currently reports **59 writes over 55 cells**. It
  must rise (the auditor measures 4 values lost and **2 cells never written**), and the four values
  above must appear in the register file.
* **F3 — the null half.** Cells written only by `0x0A` packets must be **unchanged**. If the whole
  census shifts, the auto-increment fix is over-applying.
* **F4 — ★ rule 1.** `§70 ACCA` min vs max before any output claim. Expected `min 0 max 0`.

## ⚠ Not claimed

A 1.3 % packet-acceptance fix is not an audio fix. And the `0x0B` **flag's meaning** stays
undecoded — this accepts the packet; it does not interpret the bit.
