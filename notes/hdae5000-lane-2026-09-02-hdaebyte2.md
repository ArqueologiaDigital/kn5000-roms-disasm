# HD-AE5000 lane HDAEBYTE2, 2026-09-02: two small proven wins, one avenue closed

Continuation of `notes/hdae5000-lane-2026-09-02-alignment-padding.md`, working the same
target: HD-AE5000's undocumented `.byte` debt (`hdae5000/tools/measure_debt.py`).
Starting point this session: **11,783 B** undocumented, 3,793 B documented-but-untyped
(the numbers that note left off at).

## Numbers

| step | undocumented `.byte` |
|---|---:|
| start of this session | 11,783 B |
| + generalized `convert_align_pads.py` (45 B, see below) | 11,738 B |
| + `HDAE5000_PPORT_Strings` record terminators documented (29 B) | 11,709 B |
| + version-block control bytes documented (3 B) | **11,706 B** |

Measured by `hdae5000/tools/measure_debt.py`; reproduce with:
```
python3 hdae5000/tools/measure_debt.py
```
Every step rebuilt and `cmp`'d clean against `original_ROMs/hd-ae5000_v2_06i.ic4`
(`make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom && cmp rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom
original_ROMs/hd-ae5000_v2_06i.ic4`) after every edit in this note, not just at the end.

## 1. `convert_align_pads.py` had a blind spot outside `hdae5000_data_tables.s` (45 B)

The alignment-padding rule from the prior note (a bare `.byte 0x00` at an odd real address,
immediately before an `.asciz`/`.ascii`, is proven word-alignment filler) is file-structure
independent, but the *tool* implementing it was not: its `next_content()` stops at the first
non-blank line, and in `hdae5000_data_tables.s` a label always shares its line with the directive
it names. `hdae5000_utilities.s`'s "Registered-object name pool" (`hdae5000_utilities.s:1440+`,
`HDAE5000_Str_*` names published to the main-CPU UI framework) instead puts every label on its
own line, so the tool's next-line check always landed on the label and reported zero convertible
bytes -- silently, not as a failure.

Fixed by skipping bare `Label:` lines when scanning forward for the next real directive
(`hdae5000/tools/convert_align_pads.py`, `LABEL_ONLY_RE`). Re-running the **same** tool against
`hdae5000_data_tables.s` under the fix found **5 more** genuine pad bytes the original bulk pass
had also missed for the same reason (label-only lines do occur in a few spots there too, just not
systematically) -- not a regression, a fix applied evenly.

Fresh evidence gathered per file, not assumed from the other file's numbers:
* `hdae5000_utilities.s`: **70/70** `.asciz` and **1/1** `.ascii` start on an even address
  (`get_lprobe_addrs.py hdae5000_utilities.s`, ground-truth linked addresses).

Total: 40 bytes converted in `hdae5000_utilities.s`, 5 in `hdae5000_data_tables.s`.

## 2. `HDAE5000_PPORT_Strings`: a proven 24-byte record stride, by the consumer (29 B)

`hdae5000_ui_display.s:15963-16011`, `HDAE5000_PPORT_Strings` (0x29541E-0x29562A+len): 20
numbered `"NN>Description"` status strings shown during PPORT (parallel-port PC link) commands,
plus two irregular continuation messages and a shared error string. Every string had been padded
to a fixed field width and the record closed with either a lone `.byte 0x00` or (twice) `.byte
0x09, 0x20, 0x20, 0x00`, all counted as undocumented debt -- the block comment above them named
the string *contents* but nothing on record said the table had a real fixed stride, only that it
"looked" evenly spaced.

**Consumer evidence, not a byte-counting coincidence**: `HDAE5000_Code_2_PartB`'s PPORT command
handlers issue `lda_24 xbc, (0x2954xx/0x2955xx)` before every `HDAE5000_Display_String` call --
one absolute literal per status message. New probe `hdae5000/tools/verify_pport_strings_stride.py`
computes every record's start address independently from these lines' own linked addresses
(`get_lprobe_addrs.py hdae5000_ui_display.s`) and checks every such literal against that list:

```
23 record starts computed, lengths: 24 x20, 22 x2, 24 x1 (last)
23/23 call-site literals land exactly on a record start
```

All 23 -- both irregular 22-byte records included -- are hit exactly by a real load in the
firmware. That is what makes the closing `.byte` a genuine, checkable *record terminator*, not
unexplained filler: shortening a string here (other than trading trailing spaces) would desync
every one of those 23 call sites, which is precisely the property the brief asks a `.balign`/typed
byte to carry. Reproduce:
```
python3 hdae5000/tools/get_lprobe_addrs.py hdae5000_ui_display.s > /tmp/lprobe_ui.txt
python3 hdae5000/tools/verify_pport_strings_stride.py /tmp/lprobe_ui.txt
```
23 lines documented in place (20 x `.byte 0x00` + 2 x `.byte 0x09,0x20,0x20,0x00` + 1 final
`.byte 0x00` = 20+8+1 = 29 B).

## 3. Three control bytes inside the already-confirmed version-info block (3 B)

`hdae5000_ui_display.s:22102`, `.byte 0x1b, 0x1c, 0x1f`, sits between two `.ascii` lines inside the
309-byte span already retracted from "code" to data in an earlier pass (the *"Technics Software
section M. Kitajima"* version string, `0x2999B2-0x299AE6` -- see the comment immediately above
this line and `notes/DEBT-INVENTORY-2026-09-02.md`'s data-as-code section). These 3 bytes carried
no comment of their own even though the block around them is fully accounted for as data.
Documented honestly as "non-ASCII control bytes inside the confirmed-data block, individual
meaning not determined" -- this is NOT a claim of understanding what they mean, only of where they
sit and that they are not code, which is already established.

## What was investigated and is NOT converted: the 769-record UI object pool

The large remaining block (~10,180 `.byte` lines, the overwhelming majority of the 11,706 B left)
is `HDAE5000_UI_Descriptors`/`_UI_Page_Titles`/`_Panel_Save_UI`/`_Credits`/`_Demo_Data`, documented
by an earlier pass as ONE 769-record variable-length pool (`hdae5000_data_tables.s:6276-6411`,
commit `8132d9dc`). This session's brief asked to keep pushing that pool via consumer evidence --
"the routine that indexes the table tells you the stride directly through its indexing
arithmetic." Two checks this session, both negative:

1. **A tree-wide sweep for any 6-hex-digit literal inside the pool's address range**
   (`0x29DC12-0x2A5D2C`) across every `hdae5000/*.s` and `hdae5000/*/*.s` file found **18 hits,
   all of them labels or the existing analysis comments** -- zero load/store/call instructions
   anywhere in this ROM's own source touch a class-body offset. The only two real references to
   the pool at all remain the ones the earlier pass already found: `lda_24 xwa, (0x29c0aa)`
   (load the pool's *address*) and `ldw_da xwa, (0x29d97e)` (load the *record count*), both in
   `hd-ae5000_v2_06i.s:310-312`. **There is no local consumer to read indexing arithmetic from.**

2. **Why**: `hd-ae5000_v2_06i.s:476` registers the pool with the KN5000 *main* CPU via an indirect
   call (`ld_sril XHL, (xwa + 0x00e4)` off a cross-CPU workspace pointer, handler ID `0x7F`,
   `ldw (xsp+8), 0x315` = 789 entries) rather than walking it locally -- HD-AE5000 is an accessory
   that *ships* the descriptor table to the host's window manager and never interprets the
   class-specific body itself. The interpreter, if fully understood anywhere, lives in the KN5000
   main-CPU ROM (`v10/`), not in this image.

   I checked `v10/maincpu/ui/ui_widget_defs.s:8732`, which does define a routine literally named
   `RegisterObjectTable`. **It does not match**, on its own numbers, so I did not attempt to use it
   as consumer evidence: it copies a *fixed* 14 bytes (`lds bc, 7; ldirw`) into a registry slot at
   `0x27ED2 + 14*WA`, guarded by `cp wa, 0x45f` (1,119 slots) -- but HD-AE5000's call passes
   `WA=0x315` (789, this image's own *entry count*, not a slot index) and `XBC` pointing at the
   *start* of a 769-entry, 22-to-82-byte-per-record pool, not a single 14-byte struct. A
   fixed-14-byte-slot registry bounded at 1,119 entries cannot be the same mechanism as a
   variable-22-to-82-byte-record pool of 769 entries; the name match looks like independent
   labeling convergence (both are "register some object with the host"), not the same function.
   There is also no static call edge to check -- HD-AE5000's call is an indirect jump through a
   cross-CPU workspace-relative function-pointer table, so even a numeric match would not have
   been proof, only corroboration. **This avenue is closed; a future pass should not re-derive
   it** unless `v10`'s window-manager dispatch is disassembled far enough to name the *actual*
   handler behind HD-AE5000's `0x7F`/`RegisterObjectTable` call, which is out of this lane's
   territory (v10 belongs to a different lane) and was not attempted here.

The pool's 22-byte header (class id / parent / child / sibling / bbox) and the 13-of-41 classes'
caption offsets, established by the prior pass's `analysis/wave7-probes/verify_hdae5000_ui_pool.py`,
remain the strongest thing on record here -- from pure internal consistency (link symmetry,
bounding-box legality, cross-reference to the 13-entry `HDAE5000_ClassName_Table`), not from a
consumer. The ~13,334 B of class-specific body content per the 41-class table in that pass's
comment block stays undecoded for lack of any code, in this image or reachable from it, that
demonstrably reads those bytes as fields.

## Reproduce everything in this note

```
python3 hdae5000/tools/get_lprobe_addrs.py hdae5000_utilities.s > /tmp/lprobe_util.txt
python3 hdae5000/tools/convert_align_pads.py /tmp/lprobe_util.txt hdae5000/hdae5000_utilities.s --apply
python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe_dt.txt
python3 hdae5000/tools/convert_align_pads.py /tmp/lprobe_dt.txt hdae5000/hdae5000_data_tables.s --apply
python3 hdae5000/tools/get_lprobe_addrs.py hdae5000_ui_display.s > /tmp/lprobe_ui.txt
python3 hdae5000/tools/verify_pport_strings_stride.py /tmp/lprobe_ui.txt
python3 hdae5000/tools/measure_debt.py
make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom
cmp rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom original_ROMs/hd-ae5000_v2_06i.ic4
```
