# What to capture on the KN5000 panel link, and what each capture settles

`kn5000-control-panel-panel-side.md` §3 lists six things about the control panel
that these ROMs cannot answer. This document turns that list into a **capture
plan**: for each item, the probe points, the action to perform, and — the part
that matters — **what the capture must show for the answer to count**.

Written 2026-08-23 without hardware. Everything here is derived from the KN5000
side of the protocol, which IS fully specified, so the expectations below are
falsifiable: if a capture disagrees with them, the KN5000-side specification is
wrong and that is a bigger finding than the item being measured.

## Probe points

The link is the TMP94C241's **SC1**: `SCLK1`, `TXD1`, `RXD1`, plus the panel
select/strobe. Four channels at 2 MHz sampling is ample — the KN5000 clocks the
line at a rate it sets itself in `BR1CR`, and every rate the ROM loads is far
below that.

⚠ Capture the KN5000 side FIRST and check it against
`analysis/cpanel-protocol-probes/cpserial_two_implementations.py`. If the
transmitted frames do not match what that reproduces, stop — the probe setup or
the decode is wrong, and nothing measured after that is trustworthy.

## The six items

### 1. (§3.1) The panel's clock rate when the panel is master

**Capture:** idle instrument, no keys, no buttons. Trigger on the first `SCLK1`
edge that the KN5000 is not driving.
**Measure:** the period.
**Counts as an answer when:** the same period appears across at least three
separate panel-initiated transactions, and it differs from every `BR1CR` value
the ROM loads (otherwise you have captured a KN5000-mastered frame and
mislabelled it).

### 2. (§3.2) The meaning of the command PARAMETER byte

**Capture:** the KN5000 issues `20 0b` at startup (`CpanelPollStartup`). Capture
the reply, then repeat with the panel physically swapped left/right if possible.
**Measure:** what varies with the parameter byte across the commands the ROM
issues — `0x00`, `0x01`, `0x04`, `0x0b`, `0x10`, `0x11`, `0x13`.
**Counts as an answer when:** a single reading explains all seven, not one each.
A per-command explanation is a table, not a meaning.

### 3. (§3.3) Which frame the panel replies with

**Capture:** each of the commands above, with the reply.
**Counts as an answer when:** the reply is predicted by the command alone. If it
depends on panel state, capture the state too — the ROM tests almost nothing, so
any determinism found here is new information rather than a confirmation.

### 4. (§3.4) The panel's scan interval, debounce, and reply latency

**Capture:** press and release one button slowly; then press two buttons within
~1 ms of each other.
**Measure:** command→reply latency; interval between unsolicited reports; whether
a bounce produces one report or several.
**Counts as an answer when:** the debounce window is bracketed — one press short
enough to be swallowed and one long enough to report.

### 5. (§3.5) The panel's error handling

**Capture:** this one needs deliberate corruption, and the KN5000 never does it.
Drive the line externally: send a frame with a bad length, then a truncated
frame, then a frame during a panel transmission.
**Counts as an answer when:** the panel's recovery is observed for all three, and
the panel returns to normal service afterwards. ⚠ This is the only item requiring
active injection rather than passive observation — it carries a real risk to the
instrument and is the one to skip if any doubt exists.

### 6. (§3.7) What the panel does with an LED write

**Capture:** the KN5000 emits `[row, pattern]` pairs and never reads back.
**Measure:** with the panel visible, write each row `0x00`..`0x0f` and `0xc0`..
`0xcf` with pattern `0xff`, one at a time, and photograph which LEDs light.
**Counts as an answer when:** every row in both ranges has been driven, including
the ones the firmware never uses — an unused row that lights something is exactly
what the ROM cannot tell you. Also record whether an out-of-range row is ignored
or wraps.

## What NOT to spend time on

* **§3.6, the button and LED bit map — ALREADY ANSWERED**, from pressing buttons
  and an LED sweep on the instrument. It is now cited as such in
  `*/maincpu/cpanel_constants.s`. It needs no logic analyser, only the citation
  it now has.
* Re-deriving the KN5000 side. It is specified and has two agreeing
  implementations; a capture that contradicts it is a bug report, not a
  measurement of the panel.

## The falsifiable prediction this whole plan rests on

The KN5000 sends exactly 15 host→panel control frames, encoded `21 XX 20 YY`,
with identical multiplicity in all four ROM images; its receive dispatch is
`and l,0x38 / srl l,1` over an 8-entry table shaped `[A,A,B,C,C,C,D,D]`. **A
capture that shows the KN5000 sending a 16th frame, or the panel sending
something the 8-entry dispatch cannot classify, falsifies the specification** —
and that would be worth more than any of the six items above.
