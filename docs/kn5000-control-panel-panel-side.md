# The control-panel link, seen from the PANEL side

Status: derived from the ROMs, with every quoted number produced by a committed script.
Companion to `kn5000-control-panel-serial.md`, which specifies the KN5000 end of the same link.

`IS-IT-DONE.md` scores L5 as PARTIAL and gives the reason: *"Panel-side behaviour is not
[specified], and cannot be."* This document tests that sentence. The verdict is that its first
half is right and its second half is too strong: **most of the panel's wire behaviour is forced
by what the KN5000 does, and can be written down without hardware. What genuinely needs a logic
analyser is a short, specific list, and naming it is worth more than "needs hardware".**

Reproduce everything here with:

    python3 analysis/cpanel-protocol-probes/cpserial_two_implementations.py   # exits non-zero on disagreement
    python3 analysis/cpanel-protocol-probes/panel_message_space.py

Both read only `original_ROMs/*.rom`. Neither reads the disassembly, so a misreading of the
sources cannot make a check pass.

---

## 0. Method, and what would falsify it

A protocol where one endpoint's state machine is fully known constrains the other endpoint
heavily, in three separate ways:

1. **Every frame the KN5000 sends** is a frame the panel must accept. That set is closed and
   enumerable.
2. **Every frame the KN5000 decodes** is a frame the panel may send. The receive path is a total
   function of the frame's first byte, so enumerating 256 first bytes enumerates the panel's whole
   outbound message space.
3. **Every value the KN5000 tests** is a value the panel must be able to produce. Where the
   firmware branches on a received byte, it has told you the answer it recognises.

What would falsify a claim in §2 below: finding firmware that accepts a frame the claim says is
impossible, or a decode path the claim does not mention. What would falsify §3: finding, in the
ROM, code that computes the thing §3 says is invisible.

---

## 1. Finding zero: there are not two drivers, there is one

`kn5000-control-panel-serial.md` opens with a scope warning in bold: the bootloader's driver
"is INDEPENDENT of the runtime `CPanel_*` protocol stack ... nothing proven here transfers to the
runtime driver, and vice versa." That warning is prudent but, as a matter of fact, wrong, and
believing it costs a large amount of derivable panel-side detail.

`cpserial_two_implementations.py` measures the relationship instead of assuming it. Every check
is an exact byte encoding with an exact expected hit count; all pass on all four images
(`kn5000_table_data.rom`, and the v7/v9/v10 program ROMs):

| what was compared | result |
|---|---|
| the 15 host→panel control frames, as `ldb a,X / ldb w,Y` = `21 XX 20 YY` | identical multiplicity in all four ROMs |
| the frame-length rule `and a,0x3f / cp a,0x30 / jr c / and a,0x0f / add a,3` | exactly 2 sites per ROM (transmit path, receive path) |
| receive format dispatch `and l,0x38 / srl l,1` + its 8-entry table | 1 site per ROM; table shape `[A,A,B,C,C,C,D,D]` in all four |
| transmit format dispatch `and a,0x30 / srl a,2` + its 4-entry table | 1 site per ROM; table shape `[A,A,A,B]` in all four |
| the 2-byte report handler body | **byte-identical in all four ROMs except one 32-bit immediate** |
| that immediate — the base of the button-state array | boot `0x00001022`, v7 `0x00008dae`, v9/v10 `0x00008e4a` |
| the four power-on combo tests, at each ROM's OWN base: `base+20 == 0x6c`, `base+1 == 0x70`, `base+22 == 0x38`, `base+6 == 0x0f` | present exactly once in all four |
| the startup poll: read `base+11`, bit 7 → `0x0d`, bit 6 → `0x0e`, else `0x0c`, compare with `base+32` | present exactly once in all four |

So the bootloader's CP-serial driver is the runtime driver, compiled for a different RAM base.
Three consequences follow immediately, and each corrects a name or a claim standing today:

* The bootloader's anonymous **"XOR-scramble buffer at 0x1022"** is the **button-state array**.
  The XOR is not scrambling: it computes `changed = old ^ new` for an 8-button bitmap.
* **`Boot_ClassifyDeviceID` does not classify a device.** It is the boot copy of
  `CPanel_CheckSpecialCombos`: same four offsets, same four constants, same four result codes
  (3, 2, 1, 4). Its "device class 4 = flash-update service device" is combo 4 = **PM1+PM2+PM3+PM4
  held at power-on**, which is the service manual's documented Flash Memory Update entry.
  `BootSerial_ProbeSequence` is `CPanel_ReadAllButtons` (same four frames `25 01 / e2 04 / 20 10 /
  e2 11`); `BootSerial_ResetAndIdent` is `CPanel_InitButtonState` (`2b 00 / eb 00 / 20 10 /
  e3 10`); `BootSerial_WaitDeviceIdent` is `CPanel_PollStartup` (`20 0b`, same three-way code,
  same `+11` and `+32` offsets); `BootSerial_TestLoopback` is `CPanel_PanelDetection` (`20 00`
  and `e0 00`, results in bits 0 and 3).
* The two copies differ in exactly one place that matters: the bootloader's analog-report decode
  hook is a stub that always reports failure, so **during boot the panel's analog controllers are
  read off the wire and thrown away**. `panel_message_space.py` shows the analog handler table
  present in v7/v9/v10 and absent from `table_data`.

This is not two independent implementations corroborating each other — it is one implementation
shipped twice — but it does mean the runtime copy's semantics may be read back onto the boot copy,
which is where most of the panel-side information was hiding.

---

## 2. What CAN be specified without hardware

### 2.1 Electrical and clocking

TMP94C241 serial channel 1 in I/O-interface (synchronous) mode, plus two handshake lines. The
signal names are those the firmware's own port programming uses:

| line | port bit | role | evidence |
|---|---|---|---|
| SCLK1 / /CTS1 | PF6 | transfer clock **and** the line-busy indicator | read and driven explicitly by both drivers; "resting at pull-up" is a source comment, not a ROM fact |
| INTA | PE5 | panel → KN5000 attention line | tested by every idle check; `Handler_INTA` is its vector |
| TXD1 | PF4 | KN5000 → panel data | *[INFERENCE]* the transmit states set PFCR/PFFC bits `0x50` = bits 6 and 4, and bit 6 is SCLK1 |
| RXD1 | PF5 | panel → KN5000 data | *[INFERENCE]* the receive states mask PFCR with `0x9f`, clearing bits 6 and 5 |

**Clock mastership follows the data direction.** This is the single most useful derivable fact
about the panel and it is stated by three register writes:

* Transmitting, the KN5000 clears SC1CR bit 0 (IOC = 0, "input clock select = baud rate
  generator") and drives PF6/PF4 as SC1 function outputs. The panel is a **clock slave**.
* Receiving, `Handler_INTA` and the RX byte states set SC1CR bit 0 (IOC = 1, "input clock select
  = SCLK1 pin"), clear SC1CR bit 1 (SCLKS = 0, "transmit/receive at SCLK1 **rising** edge"), set
  SC1MOD bit 5 (RXE) and release PF6/PF4. The panel is the **clock master**.

So the panel must be able to be both, on the same wire pair, and must clock its data out such that
the KN5000 samples on the rising edge. Frame bit order and width are the TMP94C241's I/O-interface
mode: 8 bits, LSB first, no start/stop/parity. That is a CPU datasheet fact, not a panel
observation — which is the point: for a reimplementer it is available.

**Bit rate.** The KN5000 programs BR1CR to three different values at three different moments, and
this is derivable structure even before anyone commits to a baud figure:

| BR1CR | when |
|---|---|
| `0x28` | while requesting the line and issuing the priming/dummy `SC1BUF` writes |
| `0x24` | during the line-request state, the inter-byte gaps and the frame tail |
| `0x14` | **while an actual frame byte is shifted out** |

`kn5000-control-panel-serial.md` deliberately declines to translate these into baud figures.
The v9/v10 sources' own comments do not: they read `0x14` as φT2 ÷ 4 = 250 kHz, `0x24` as
φT8 ÷ 4 = 62 500 and `0x28` as φT8 ÷ 8 = 31 250, on fc = 16 MHz (the main CPU is an 8 MHz crystal
doubled, per the schematic and the MAME driver). **That is a contradiction between two committed
documents and it should be resolved rather than left standing** — but note that it only affects
the direction where the KN5000 is master. The rate the *panel* clocks at is not in the ROM at all
(§3.1).

### 2.2 Line arbitration, and what the panel must do to get the line

The KN5000's idle test, identical in `CPanel_WaitTXReady`, the main-loop poll and the bootloader's
`BootSerial_WaitTxIdle`, is a conjunction of four conditions:

    PF6 (SCLK1) reads HIGH   and   PE5 (INTA) reads LOW
    and TX-pending flag clear   and   RX-active flag clear

To transmit, the KN5000 then drives SCLK1 **low as a plain GPIO** (PFFC bit 6 cleared, port latch
bit 6 cleared, PFCR bit 6 set), primes the transmit chain, and in the very next state releases
SCLK1 back to an input and **reads PF6 back**. Reading LOW aborts the frame and sets a distinct
"arbitration failed" status bit.

That read-back is only meaningful if the other end can hold SCLK1 low. So:

> **[DERIVED]** The panel claims the line by pulling SCLK1 low and asserting INTA. It must release
> SCLK1 (and let the pull-up take it high) whenever it is not sending, or the KN5000 can never
> transmit — its idle test fails, its 200-retry `WaitTXReady` runs out, and the main loop gives up
> after 20 consecutive busy polls.

**INTA has two distinct meanings, selected by the KN5000's own frame countdown**, and both are
derivable from `Handler_INTA`:

* Countdown zero (no frame in flight): INTA means *"I am about to send"*. The KN5000 reconfigures
  SC1 for receive, arms the RX-first-byte state and sets the RX-active flag. The panel may then
  clock a frame in.
* Countdown non-zero (a frame is in flight): INTA is a **pacing/retraction pulse**. The KN5000
  moves its RX write pointer **back by one** (reloading it to the ring size 92 first if it is
  zero), sets a status bit, and clears the TX-pending flag. Mechanically it un-writes the byte just
  stored. *[INFERENCE]* the intended meaning is "discard that byte" or a mid-frame resync; the ROM
  shows the mechanism, not the intent.

Note for anyone modelling this: all three interrupt epilogues (INTA, INTTX1, INTRX1) write
**0x12, 0x22 and 0x23** to INTCLR, so whichever handler runs discards the other two's pending
requests. A panel model that assumes per-source interrupt latching will not reproduce this link.

### 2.3 Framing

The first byte of a frame gives its length. The rule is sharper than
`kn5000-control-panel-serial.md` states — that document gives `(first & 0x0F) + 3` without its
guard, and the guard is what makes the rule decidable:

    if (first & 0x3f) >= 0x30:      total length = (first & 0x0f) + 3
    else:                           total length = 2

`(first & 0x3f) >= 0x30` is exactly "bits 5 and 4 are both set". The same rule is coded four times
(transmit and receive, in each of the two driver copies) and `cpserial_two_implementations.py`
finds all four sites. **Both directions use it**: it is the framing of the link, not of one
endpoint.

### 2.4 The panel's complete outbound message space

Because the receive path is a total function of the first byte, the panel's message space can be
enumerated exhaustively. Bits 5:4 are the format field; the receive dispatch table's shape
`[A,A,B,C,C,C,D,D]` collapses its 8 entries onto 4 behaviours, which is why the format is really
two bits and not three.

| bits 5:4 | bit 3 | meaning | length | remaining bits |
|---|---|---|---|---|
| `00` | — | **button-segment report** | 2 | index = `(b & 0x0f) + (b & 0x40 ? 16 : 0)`; bit 7 is masked off and IGNORED |
| `01` | 0 | **analog-controller report** | 2 | encoder id = `((b >> 6) << 3) \| (b & 7)` |
| `01` | 1 | sync / ACK | 2 | payload consumed and discarded |
| `10` | — | sync / ACK | 2 | payload consumed and discarded |
| `11` | — | **run** | `(b & 0x0f) + 3` | see below |

`panel_message_space.py` counts the partition: **64 button, 32 analog, 96 sync, 64 run** first
bytes.

**Button-segment report** `[tag, bitmap]`. The KN5000 keeps a 32-byte array (`0x8e4a` in v9/v10,
`0x8dae` in v7, `0x1022` in the bootloader), stores the bitmap at the computed index, and pushes
three bytes into a 128-slot event ring: `{tag, new bitmap, old ^ new}`. Bits are active-high,
1 = pressed. Index 0..15 is one panel, 16..31 the other.

**Analog-controller report** `[tag, value]`. The value is handed to a 32-entry handler table
indexed by the encoder id. A handler returning `0xffff` means "no change" and the whole report is
dropped — the event-ring pointer is rolled back. Otherwise `{tag, decoded value, 0xff}` is queued.
Of the 32 ids, **26 share one default handler** that returns the constant 1; the six distinguished
sources are:

| encoder id | first byte | what the handler does |
|---|---|---|
| 2 | `0x12` | modulation wheel: complement, halve, LUT, suppress if unchanged |
| 5 | `0x15` | volume/expression slider: LUT, clamp to a configured minimum, scale, clamp to 127 |
| 25 | `0xd1` | breath controller |
| 26 | `0xd2` | foot controller |
| 27 | `0xd3` | expression pedal (never suppresses) |
| 31 | `0xd7` | identity passthrough |

**Run** `[header, start, payload...]`, `(header & 0x0f) + 1` payload bytes. A run is a *compressed
sequence of 2-byte reports*: the KN5000 synthesises a tag

    w = (header & 0xc0) | (start & 0x1f)

and then processes `(w, payload[0])`, `(w+1, payload[1])`, ... exactly as 2-byte reports —
`bit 4` of `w` choosing analog decode over the button array, precisely as bit 4 does in a standalone
report. Two consequences a panel implementer must respect:

* `w` is incremented per payload byte, so a run starting at index 15 with more than one payload byte
  **changes format mid-run** when the increment carries into bit 4. Runs should not straddle that
  boundary.
* With the "collapse" sentinel set, a payload byte whose XOR against the stored value is zero is
  elided from the event ring entirely. (The sentinel is never set in the shipped firmware —
  `CP_Flags_A.4` in the runtime copy — so this path is dormant, but it is in both copies.)

**Sync / ACK.** 96 of the 256 first bytes reach a handler that consumes both bytes, sets a status
bit nothing reads, and moves on. So a sync frame carries **no information beyond its own
existence** — and that turns out to be exactly what the KN5000 tests (§2.5).

### 2.5 What each host command must elicit — the acceptance tests, verbatim

This is the part that is usually assumed to need hardware. It does not: wherever the firmware acts
on an answer, it has told you what answer it will accept.

| host frame | sent by | what the KN5000 does with the answer | therefore the panel must |
|---|---|---|---|
| `1f da`, `1f 1a`, `1d 00`, `dd 03`, `1e 80` | init / handshake | **nothing is read back** | nothing. No reply is required by the firmware |
| `20 00` | panel detection | after 6 ticks, tests whether the RX **write pointer** moved | send **at least one byte**, of any value, within 6 ticks |
| `e0 00` | panel detection | same test, result recorded in a different bit | same |
| `20 0b` | startup poll, in a loop | reads array index 11, maps bit 7 → `0x0d`, else bit 6 → `0x0e`, else `0x0c`, and loops until two consecutive polls agree | produce a report landing at **index 11** whose bits 7:6 are stable between polls (a silent panel also terminates the loop, at code `0x0c`) |
| `25 01`, `e2 04`, `20 10`, `e2 11` | `CPanel_ReadAllButtons` | the four power-on combos are then tested at indices 1, 6, 20 and 22 | between them, cause reports for **at least indices 1, 6, 20, 22** |
| `2b 00`, `eb 00`, `20 10`, `e3 10` | `CPanel_InitButtonState`, also re-issued from the main loop while a two-bit flag field counts up to `0xc0` | fills the array | refresh the array |
| `e0 13` | steady state, every 42 main-loop passes | fills the array | report button state |
| LED rows `0x00`–`0x0c`, `0xc0`–`0xc8` + pattern | `CPanel_UpdateLEDs`, from a 128-slot queue | no answer is read | **not** answer with a format-`00` frame: row bytes `0x00`–`0x0c` would decode as button reports and corrupt the array |

Two derived numbers worth stating plainly, because they are the whole of the KN5000's liveness
requirement on the panel: **one byte within six timer-1 ticks after `20 00`**, and **a stable
index-11 report across two consecutive `20 0b` polls**. Nothing else in either driver blocks on a
panel answer.

### 2.6 Which half is the left panel

The array halves can be pinned without pressing a button, because the ROM anchors four of them:

* index 6 must be able to read `0x0f`, and the service manual's Flash Memory Update combo is
  PM1+PM2+PM3+PM4 — four buttons, four bits. Index 6 is therefore the panel carrying the Panel
  Memory buttons.
* index 22 must be able to read `0x38` — three bits — and the Factory Reset combo is the three
  leftmost RHYTHM GROUP buttons. Index 22 is on the rhythm/style panel.

So **indices 0..15 are the right panel and 16..31 the left**, i.e. `bit 6 of a report tag set ⇒
left panel`. This agrees with the LED row map (`0xc0`+ rows carry the rhythm-group and composer
LEDs; `0x00`+ rows carry PM1..PM8 and the tone groups) and it **disagrees with the command labels
in `cpanel_constants.s`**, which call `0x20`/`0x25`/`0x2b` "left" and `0xe0`/`0xe2`/`0xeb`
"right". The disagreement is resolvable: `CPanel_PollStartup` sends only `20 0b` and then reads
index 11, so the panel addressed by a bit-6-clear command reports into the 0..15 half, which the
combos identify as the right panel. Those `.equ` names are inverted; they were marked
"my guess" at the call sites, and the guess did not survive.

*(Caveat, stated because the ROM does state it: bits 7:6 of a host command byte are only ever
`00` (`1d 1e 1f 20 25 2b`) or `11` (`dd e0 e2 e3 eb`) — never `01` or `10`. So **the ROM cannot
tell you whether the panel selector in a command is bit 7, bit 6, or both**. In a report only
bit 6 is used: bit 7 is masked off by `and w, 0x4f`.)*

### 2.7 Flow control and burst limits

All derivable, and all constraints on the panel:

| limit | value | what happens when the panel exceeds it |
|---|---|---|
| receive byte ring | 92 bytes | with fewer than 3 free, an overflow bit latches and the write pointer stops advancing **for the rest of the frame**; bytes are silently overwritten in place |
| event ring | 128 slots, 3 per report | the parser stops when fewer than 4 are free, so **at most 42 reports** can be queued |
| transmit byte ring | 60 bytes | host side only |
| run length | 1..16 payload bytes; 3..18 bytes on the wire | longer is unrepresentable |

There is **no checksum, no sequence number and no per-frame acknowledgement anywhere in either
copy of the driver.** That is itself a derived fact about the protocol, and it means a dropped
byte desynchronises the frame parser until a first byte happens to produce a self-consistent
length. The KN5000's only recovery is to reinitialise both rings, which
`CPanel_ReadAllButtons` and `CPanel_InitButtonState` do on every call.

### 2.8 Worked example

Panel reports that the three leftmost RHYTHM GROUP buttons are down:

    wire:   0x46 0x38

    0x46 = 0100 0110
      bits 5:4 = 00        -> button-segment report
      (0x46 & 0x3f) = 0x06 -> below 0x30, so the frame is 2 bytes
      bit 6 set            -> left panel
      low nibble = 6       -> array index 16 + 6 = 22

    KN5000: old = array[22]; array[22] = 0x38; changed = old ^ 0x38
            push {0x46, 0x38, changed} into the 128-slot event ring, 3 slots
    Later:  CPanel_CheckSpecialCombos reads array[22], sees 0x38,
            and returns combo code 1 = Factory Reset.

---

## 3. What CANNOT be specified from these ROMs, and why

Each entry says what the firmware would look like if the information were there. That is the test
that keeps this list from being a list of things nobody looked for.

### 3.1 The panel's clock rate when the panel is master

Every BR1CR value in both drivers is loaded while the **KN5000** owns the clock. When the panel
sends, SC1 takes SCLK1 as an input and the ROM sets no rate at all. If the firmware cared about
the panel's rate there would be a divisor written on the receive path; there is none, on either
copy. Only an upper bound is derivable — the rate at which the INTRX1 handler can be serviced —
and computing it needs TLCS-900 cycle counts, which nobody in this project has done.

### 3.2 The meaning of the command PARAMETER byte

All 16 `CPanel_SendCommand` call sites load both bytes as immediates (`ldb a, imm8` /
`ldb w, imm8`); the census in `cpserial_two_implementations.py` is exactly that measurement.
**The firmware never computes a parameter**, never compares one against a variable, and never
uses one after sending it. So what distinguishes `20 0b` from `20 10` from `e0 13` — segment
number? scan mode? "dump everything"? — is a fact about the panel MCU's firmware and is not
present here in any form. If parameters were computed from a segment index there would be an
index variable feeding `W`; there is not.

This is the single biggest gap, because it is what a reimplementer needs in order to make a panel
*answer correctly* rather than merely *answer*.

### 3.3 Which frame the panel actually sends in reply to a given command

§2.5 gives what the KN5000 *tests*, which for most commands is nothing at all, and for the rest is
a weak predicate ("some byte arrived", "index 11 is stable"). Many different panel behaviours
satisfy those tests. The firmware contains no table of expected replies, and the four constants it
does compare against (`0x6c`, `0x70`, `0x38`, `0x0f`) are button combinations, not protocol
identifiers — that was the misreading corrected in §1.

### 3.4 The panel's own timing: scan interval, debounce, reply latency

The KN5000's timing constants (six-tick waits, 200 and 20 retry counters, the 42-pass poll
interval, the 3000/1500/300/10-iteration spins) are all *its* schedule. None is derived from a
panel property, and nothing measures a panel response time. A firmware that adapted to the panel's
latency would have to record a timestamp at the request and compare at the reply; neither driver
does.

### 3.5 The panel's error handling

There is nothing to infer from, because the protocol as implemented here has no error signalling
to handle: no CRC, no ACK, no retransmit, no sequence number (§2.7). The KN5000 never asks the
panel to repeat anything, so the panel's behaviour on a corrupted inbound frame is unconstrained
by this ROM. **A well-argued negative: the panel's error recovery cannot be derived because the
KN5000 never exercises it.**

### 3.6 The physical identity of most button bits and LED bits

The ROM pins four `(index, mask)` pairs (§2.6). Everything else in the button and LED tables in
`cpanel_constants.s` came from somewhere other than these ROMs — pressing buttons on the
instrument, or an LED sweep — and should be cited that way. Even for the four anchored segments,
the ROM fixes the *mask*, and only the service manual's naming fixes which bit is which button.

### 3.7 What the panel does with an LED write

The KN5000 emits `[row, pattern]` pairs and never reads anything back. Row-to-LED mapping,
brightness, multiplexing, and whether an unknown row is ignored or wraps, are all invisible here.

---

## 4. What this changes

**For the scorecard.** "Panel-side behaviour is not [specified], and cannot be" can be replaced
with something sharper and true:

> **L5, control-panel link:** the KN5000 side is specified. The panel side is specified for
> framing, clock mastership, line arbitration, the complete inbound message space, the array and
> encoder semantics, the flow-control limits, and the acceptance test behind every command the
> KN5000 issues (`kn5000-control-panel-panel-side.md`). **Seven** things are known to be
> underivable from these ROMs and are located rather than merely missing — §3.1–§3.7: the panel's
> clock rate as master, the meaning of the command parameter byte, **which frame it actually
> replies with**, its own scan/debounce/latency timing, its error recovery (the KN5000 never
> exercises it), **the physical identity of most button and LED bits**, and **what it does with an
> LED write**. A captured trace would close the clock rate, the parameter byte and the reply
> frames; the timing, error recovery and LED behaviour need the panel MCU's own firmware.
>
> ⚠ **This paragraph said "four" until 2026-08-23 and undercounted its own §3**, omitting §3.3,
> §3.6 and §3.7. Each of those is blocked for a stated reason — the firmware holds no table of
> expected replies, the ROM pins only four `(index, mask)` pairs, and the KN5000 never reads an
> LED write back — so they belong in the list. `IS-IT-DONE.md` inherited the same undercount.
>
> ⚠ §3.6 is a PROVENANCE case rather than an open question: the button and LED tables in
> `cpanel_constants.s` are populated, but from pressing buttons on the instrument and from an LED
> sweep, not from these ROMs. What is missing is the citation, not the data.

**For the L5 executable test.** The spec asks for a reader written from the document alone and
checked against an artefact. For this protocol there is no artefact: no capture exists, so there
is nothing to read. The executable evidence available instead is cross-implementation agreement —
`cpserial_two_implementations.py`, which exits non-zero if the bootloader and runtime copies ever
stop agreeing. That is a weaker instrument than the style-format test and should be labelled as
such, not counted as equivalent.

**Corrections owed to existing files** (recorded here rather than edited in, and each backed by a
check in `cpserial_two_implementations.py`):

1. `docs/kn5000-control-panel-serial.md` — the independence warning is false; the frame-length
   rule is missing its `(first & 0x3f) >= 0x30` guard.
2. `table_data/boot_cpserial.s` — `Boot_ClassifyDeviceID` / `BootSerial_WaitDeviceIdent` /
   `BootSerial_ProbeSequence` / `BootSerial_ResetAndIdent` / `BootSerial_TestLoopback` and the
   "device-ident", "device class" and "flash-update service device" wording all describe a device
   probe that does not exist; they are the boot copies of the panel button routines.
3. `table_data/boot_cpserial_states.s` — the "XOR-scramble state at 0x1022" is the button-state
   array; the XOR is a changed-bits mask.
4. `v*/maincpu/cpanel_constants.s` — `CPANEL_CMD_*_LEFT` / `*_RIGHT` are inverted (§2.6), and the
   "22-byte response" annotation on `0x2b`/`0xeb` has no support in these ROMs.
5. `docs/kn5000-control-panel-serial.md` versus the v9/v10 source comments — one declines to give
   a baud figure, the other asserts 250 kHz / 62 500 / 31 250. Both are committed; they should not
   both stand.
