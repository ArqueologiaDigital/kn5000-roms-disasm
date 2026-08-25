# The WSA1's keyboard: a 61-key scanner at 0x00108000, and where the per-note trim comes from

**Image:** `prom_c` (IC28, CPU 2, base 0xF80000).
**Converted for this note:** `0xF9973D-0xF9993D`, three routines, 513 bytes, inside the
1,153-byte block `0xF9973D-0xF99BBD`.

Everything below is reproducible from the source listing plus

```
python3 notes/prom_c_xrefs.py 0x00F329  --no-window --classify
python3 notes/prom_c_xrefs.py 0x0084DA  --no-window --classify
python3 notes/prom_c_ram_image.py
python3 scripts/analysis/assert_byte_identical.py
```

---

## 1. ★★ 0x00108000 is the key-scan port

`notes/FINDINGS-memory-map.md` lists 0x108000 as an address/data pair "of the same shape" as
the other two CS0 devices, with the note *"Three sites, not five: 0xF9914D, 0xF99776,
0xF998C6"*. Two of those three are now converted, and they settle what the port carries.

| offset | direction | contents |
|---|---|---|
| `+2` | read | status word. **Bit 0 gates everything**: `KeyScan_ReadEvent` returns "no event" unless it is set (`and BC,0x0001` at 0xF9976F). The whole word is separately compared against **2** at 0xF9979A. |
| `+0` | read | one key event, 16 bits: **low byte** = `bit 7 note-ON` \| `bits 6..0 key number`; **high byte** = the touch measurement. |

⚠ The `+0`/`+2` pair here is a *read* pair. The other two CS0 devices use `+0` as a register
selector and `+2` as data; this one is not addressed that way in either converted site.
`Dev108000_Preload_80toBF` (0xF99138) *does* write both offsets, so the port is not read-only —
what its writes select is still open, and it is the one site of the three that stays undescribed.

### Why the low/high split is not a guess

Both call sites hand the two bytes straight to `ToneGen_VelocityFromTouch` (0xF995DF), whose
converted header — written in an earlier pass, before this block existed — already says
`(XIZ+0x08)` is *"the touch measurement, index into `ToneGen_Velocity_Input_Curve`"* and
`(XIZ+0x0a)` is *"bit 7 = note ON, bits 6..0 = note number"*.

Which byte lands in which slot follows from the push widths, and those are cited:
`push #imm8` (opcode 0x09) is `op_PUSHBI` and `push (mem)` in byte size (`0x8E .. 0x04`) is
`op_PUSHBM`; both move **one** byte
(`mame/src/devices/cpu/tlcs900/900tbl.hxx:2935-2946`). So each `push 0x00 / push (XIZ+d)`
pair builds one zero-extended 16-bit argument, and the pair pushed **last** is the one the
callee reads at `(XIZ+0x08)`. The caller drops 12 bytes afterwards (`inc 8,xsp` + `inc 4,xsp`),
which is exactly `4+4+1+1+1+1`.

---

## 2. The scanner is dead for the first 1000 ticks

`KeyScan_ReadEvent` returns 0xFFFF without touching the device while `(0x00F329)` is zero, and
it sets that byte only once the INTT1 tick counter at `0x00F2F3` has passed `0x3E8 = 1000`.

`0x00F329` has exactly **two** literal-addressed references in the whole image and both are in
this routine — one `cp`, one `ld` — so it is a one-shot arming latch that nothing else can
clear.

⚠ The tick RATE is still not established (see the `INTT1_HANDLER` header and
`notes/FINDINGS-prom_c-scheduler.md`), so 1000 ticks cannot be turned into milliseconds.

---

## 3. The three outcomes of one poll

Read off the branches at 0xF99795-0xF997B4:

```
touch != 0xFF and status != 2   ->  decode normally, velocity as computed
touch == 0xFF  or  status == 2  ->  note ON  : (0x008517) |= 0x03, return -1, event dropped
                                    note OFF : decode, then FORCE the velocity byte to 0
```

⚠ "touch == 0xFF means no travel time was measured" *fits* — a note-on with no touch value
cannot be given a velocity, a note-off does not need one — but nothing here proves it, and
`0x008517` is written by that one instruction and read by nothing that names it, so what
collects the two bits is unknown. Nor is the meaning of status value 2 established.

---

## 4. ★ Sixty-one keys, and the number comes out twice

* `KeyScan_InitKeyStateBitmap` (0xF9988D) clears **eight** bytes and then folds sixteen events
  into them at `byte = (key >> 3) & 7`, `bit = key & 7` — 64 bit positions.
* `NoteTrim_BuildFromCalibration` (0xF997FA) walks note `0 .. 0x3C` inclusive
  (`cp (XIZ-2),0x003D / jr GE`) — **61** notes — and that is the same index
  `ToneGen_VelocityFromTouch` uses when it reads `0x0084DA` with `note & 0x7F`.

61 keys inside a 64-bit map. The instrument is a 61-key one and the firmware walks 61.

### Where the bitmap lives, and the collision worth recording

The base is not a literal in the code: it is the 32-bit constant **at ROM `0xFCC81A`**, and its
value is `0x0000FFF0`. All three references to `0xFCC81A` in the image are the same
instruction, `add XBC,(0xFCC81A)`, at 0xF998AA, 0xF99910 and 0xF99930.

⚠ **This corrects `notes/FINDINGS-prom_c-voice-tables.md`**, which leaves
`0xFCC81A-0xFCCA81` as a deliberate `.incbin` described as "an IEEE-754 constant pool". Its
first four bytes are not a float. The other 612 still look like one and are untouched.

⚠ `0x0000FFF0` appears as a 32-bit literal in exactly three places in prom_c: `0xF980EE`
(`EntryPoint_Records`' second column), `0xFCC81A` (here) and `0xFFF007`
(`RESET`'s `ld XSP,0x0000FFF0`). **The boot stack top and the key bitmap are the same eight
bytes at two different times** — `RESET`'s stack moves down to `0x0000FA00` at 0xF9816B before
`MAIN` runs, and the bitmap is not built until `MAIN`'s init chain reaches 0xF997FA. Recorded
because it is true, not because anything says it was intended. It does weaken the reading of
`EntryPoint_Records` column 2 as "initial stack pointer": the same value has another use.

⚠ Nothing in prom_c **reads** the bitmap through a literal address. Those three sites are its
only literal-addressed users and all three are writes. A reader through a pointer would be
invisible to that census.

### The bit mask, and a TLCS-900 detail that matters

`0xFCA0BA` is the compiler's 16-bit left-shift helper. Its two shifts are
`sll A,IY` with `A = count >> 4` and then `A = count & 0x0F`, and `A = 0` is **not** a no-op:
on this CPU a shift count of zero means **sixteen** —
`count = (s & 0x0f) ? (s & 0x0f) : 16` in
`mame/src/devices/cpu/tlcs900/900tbl.hxx:990-992`. Both call sites pass value 1 and count
`key & 7`, so `A` comes back holding `1 << (key & 7)`; the note-on arm ORs it in, the note-off
arm complements it and ANDs.

⚠ Why the scan loop runs exactly **sixteen** times, once, at boot, is not established.

---

## 5. ★★ The per-note velocity trim at 0x0084DA — origin CLOSED

`notes/FINDINGS-prom_c-voice-tables.md` §3 ended with *"what fills the signed per-note table at
`0x0084DA` … is the only term of the velocity formula whose origin is unknown"*.

`NoteTrim_BuildFromCalibration` at `0xF997FA` is the writer, called once, from `0xF98B99` in
`MAIN`'s power-on init chain. The rule, read off its instructions:

```
p = call 0xFC8B0B                      ; returns a pointer in XIY, or 0
if p == 0:   for n in 0..60:  trim[n] = 0
else:        for n in 0..60:  trim[n] = ToneGen_VelCurve_Trim51[ clamp(p[n] - 0x4B, 0, 0x32) ]
```

`python3 notes/prom_c_xrefs.py 0x0084DA --no-window --classify` finds **three**
literal-addressed sites in the whole image, and the instruction each belongs to starts two
bytes before the literal the tool prints: `0xF99829` and `0xF9987F` (both
`add XBC,0x000084DA`, each feeding a write, here) and `0xF9964D`
(`add XWA,0x000084DA`, the single read, inside `ToneGen_VelocityFromTouch`).

### ★ And it confirms `ToneGen_VelCurve_Trim51` from the code side

⚠ **Retraction, same session.** An earlier draft of this section said the table at `0xFCC5C9`
was undecoded and claimed to identify it. It was not undecoded: the zone-2 listing in
`prom_c/wsa1_prom_c.s` already emits it as **`ToneGen_VelCurve_Trim51`**, 51 bytes, sized by the
object chain. Nothing but reading catches a claim like that; the byte gate cannot.

What this pass actually adds is an **independent** confirmation and the purpose. That table 51 signed bytes, monotonically non-decreasing from −12 (0xF4) to +10, zero across
indices 22..26. The clamp in the code is `cp A,0 / jr GE` then `cp (XIZ-7),0x32 / jr LE`, so the
index range is exactly 0..0x32 — 51 values — which is the same 51 the data chain gave, from a
completely different argument. `0xFCC5C9 + 51 = 0xFCC5FC` is where
`ToneGen_VelCurve_ModeParams` begins.

Two smaller corrections went into that table's header at the same time: it described the curve
as "a symmetric ±12 trim curve" (it runs −12..**+10**, with a five-entry zero run rather than a
crossing) and cited its reference as `0xF99874`, which is the address of the **literal** — the
instruction `add XBC,0x00FCC5C9` starts at `0xF99872`.

So `unexplained_FCC5BE` is now: four zero bytes (the tail of the boot RAM image), the three
single-byte MIDI messages at `0xFCC5C2`-`0xFCC5C4` (decoded in
`notes/FINDINGS-prom_c-serial-midi.md`), the pivot 77 at `0xFCC5C5` and the divisor 128 at
`0xFCC5C7` — only the four zeros are still unaccounted for.

### What 0xFC8B0B returns — stated as read, not converted

`0xFC8B0B` is **not** converted. What its instructions say: it fills 31 words at RAM
`0x00E2A1` through `0xFC8A29`/`0xFC8ADA`, accumulates their sum in DE, compares that sum with a
further word, then requires yet another word to equal **`0x5AA5`**, and returns
`XIY = 0x00E2A1` on success or `XIY = 0` on failure (0xFC8B5F-0xFC8B77).

A 62-byte block with a checksum and a magic is what a stored calibration looks like, and 62 is
one more than the 61 bytes the trim loop reads. **Where it is read from is not established**,
and the routine's name here says only what this pass does with it.

The trim curve is zero for calibration values `0x61..0x65`, so a "correct" per-key value is
around 97-101 and the trim spans −12..+10.

---

## 6. ★★ What the note and velocity are FOR: MIDI note-on over the link

`0xF98CB9` — now converted as `KeyEvents_ToLink` — is the consumer, and it packs each event as

```
0x90 , note , velocity
```

The `0x90` is a literal in the code (`ld (XBC+0xde),0x90` at 0xF98D24). It is MIDI's Note-On
status byte for channel 1, and the buffer of up to **ten** such triples (the loop bound is
`0x1E = 30` bytes, i.e. 30/3) goes to `Link_SendBlock` on **link channel 5**.

That closes three separate loose ends at once, and each is an independent check on the same
reading:

1. The output curve spans **1..127 and never reaches 0**. In MIDI, note-on with velocity 0
   *is* a note-off — and §3 above shows `KeyScan_ReadEvent` forcing the velocity byte to 0 on
   exactly the note-OFF path. The curve's floor of 1 is what keeps that encoding unambiguous.
   The "can never be a note-off by accident" remark in `ToneGen_VelocityFromTouch`'s header
   turns out to be the whole point.
2. The **+36** transposition: MIDI note 36 is C2, so keys 0..60 become 36..96 = C2..C7 — the
   compass of a 61-key instrument, and 61 is the count §4 derives twice.
3. The two pointer arguments of `KeyScan_ReadEvent` point into that frame buffer, one triple
   apart.

⚠ "MIDI" is the **encoding** here, not the destination: the buffer goes to the inter-processor
link, not to the UART. MAIN's own channel-6 drain is the UART path.

★ And the two touch controls are set from the OTHER processor. `ToneGen_SetVelCurveMode` and
`ToneGen_SetVelOffset` both carried "Called from: not traced / Unknown: which UI control feeds
it". `Link_Ch3_SetTouchControl` (0xF9901B, link channel 3) is the answer: a two-byte packet
whose first byte selects — `0x80` -> curve mode, `0x90` -> offset — and whose second is the
value. The UI is on CPU 1, which is why nothing on CPU 2 could be found.

---

## 7. What the next pass needs

* `0x00E2E1`, the flush counter that makes `KeyEvents_ToLink` throw the keyboard away for a
  pass. Nothing in converted code writes it.
* `0xFC8B0B`'s two helpers `0xFC8A29` and `0xFC8ADA` are the transport of the calibration
  block. They would name the medium.
* `0x008517`, and whatever reads the key-state bitmap at `0x0000FFF0` through a pointer.
* `Dev108000_Preload_80toBF`'s 64 write pairs: now that the port is known to deliver key
  events, what a *write* to it means is the obvious next question.
