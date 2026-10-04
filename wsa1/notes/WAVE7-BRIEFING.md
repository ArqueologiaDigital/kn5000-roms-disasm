# Wave 7 — the shared briefing every lane reads first

Written 2026-08-28 when the effort resumed after the wave-6 pause. This file is the
contract for the wave: what is true at its start, what each lane may touch, and what
it must produce. It is committed rather than passed around because the previous wave
learned that a plan living outside the tree goes stale inside one commit.

## Baseline, measured at resume (not copied from the handoff)

    python3 scripts/analysis/assert_byte_identical.py     -> PASS, from a `make clean`
    python3 scripts/analysis/source_coverage.py

    prom_a   374,691 substantive    43,012 filler   106,585 incbin   13 spans
    prom_b   320,217 substantive    44,612 filler   159,459 incbin  124 spans
    prom_c   395,072 substantive   129,216 filler         0 incbin
    prom_d   330,521 substantive   193,767 filler         0 incbin
    TOTAL  1,420,501 substantive (67.7%)

    sub_XXXXXX routines: 4,997      Evidence: lines: 2,706

## ⚠ The handoff's "next targets" list was STALE and is superseded by this file

`HANDOFF-RESUME-HERE.md` names `0xFE8000-0xFEB330` and `0xFEF746-0xFF3800` as prom_a's
next targets. **Both were converted by wave 6's later rounds**, after that paragraph was
written: `sub_FE8000` is at `prom_a/wsa1_prom_a.s:125114`, `sub_FEF746` at `:132040`, and
the 838-byte effect-name table at `0xFF047F` is `.byte` data at `:133500`. No `.incbin`
covers either range. Likewise prom_b's `0xF067A6-0xF0D79B` is now two spans, not one.

**Derive every target from the tree, never from a prose paragraph.** The span and
frontier tables below were regenerated at resume; regenerate them again before quoting.

## The rules (unchanged, and they are the point)

1. **The gate certifies the tree and nothing else certifies it.**
   `python3 scripts/analysis/assert_byte_identical.py` must print
   `PASS: every rebuilt ROM is byte-identical.` It rebuilds first. A full rebuild from
   `make clean` takes ~1.2 s, so there is no excuse for `--no-build`.
2. **The gate is blind to names and comments.** A confidently wrong routine header
   passes forever. Every documented error in this project's history was gate-clean.
   Therefore: every semantic name carries an `Evidence:` line; every quantified claim
   is reproduced by a committed script that was **tested on the last element as well as
   the first**; every name borrowed from the KN5000 carries a byte diff with the
   differing count stated.
3. **Prefer `sub_XXXXXX` plus a stated gap over a plausible guess.** An honest hole is
   worth more than a confident wrong name, and this tree has paid for that lesson.
4. Commits carry `LLVM: tlcs900_backend @ bcf152d1fe00 (bcf152d1fe003bf7a93ae303b98a66edf06527c0)`.

## Lane discipline for this wave

The four `.s` files are ONE FILE EACH (prom_a is 9.6 MB). **Two agents editing the same
`.s` corrupts it.** So:

* **Recon lanes are READ-ONLY on `prom_*/wsa1_prom_*.s`.** They may create new,
  uniquely-named files under `notes/`. They may not create a file another lane owns.
* **Conversion lanes own exactly one prom** and run in a round where no other lane owns
  that prom.
* A lane verifies with `make rebuilt_ROMs/wsa1_prom_X.llvm.rom` plus a byte compare of
  its own image; the FULL gate runs at the round barrier, before the commit.
* Nobody runs `git commit`, `git checkout`, `git stash` or `git reset`. The wave
  coordinator commits at each barrier. An agent that reverts a file destroys another
  lane's work.

## The gold-standard pattern for converting a span

Read these two together before starting; they are what a good lane looks like:

* `notes/prom_b_f65000_layout.py` — derives the segment boundaries from **content rules
  calibrated against a null corpus** (54,814 bytes of already-proven instruction text,
  on which the rules must fire ZERO times: `--null`). Not from a linear decode.
  `notes/prom_a_linear_decode_check.py` records why a linear decode pins nothing.
* `notes/gen_prom_b_f65000_module.py` — the emitter, which re-derives the layout on every
  run and refuses to print if a segment moved.

And the two prom_a tools, documented in `notes/prom_a-tooling.md`:

* `prom_a/roundtrip.py LO HI --block` — emits labelled assembly that has **already been
  assembled and byte-compared**, so it cannot break the gate.
* `prom_a/insert_region.py LO HI region.s` — splices it in, fixing the `.incbin` chain.

## ⚠ Tools that mislead — do not rank targets with these

* `notes/prom_c_frontier.py`: **132 of its 135 targets are phantoms**, produced by
  linearly disassembling ASCII descriptor strings. Its own docstring says so.
* `notes/prom_b_span_frontier.py`: its `proven 0` is not evidence of data. Its call-site
  scanner only recognises `ld XIY / ld XIX / call`, so a region reached through
  `DisplayListB_RunOne_Stack` scores 0 while being well-evidenced. Wave 6's best target
  scored worst on it.
* A frontier count that does not fall after converting a **data** span is correct, not a
  failure. Data retires no call target. Do not quote a drop that did not happen.

Good tools: `prom_a_module_frontier.py`, `prom_b_module_frontier.py`,
`vector_map.py --unconverted`, `prom_c_kernel_map.py`, `prom_a_xref.py`, `prom_c_xrefs.py`,
the `*_audit_callsites.py` pair, `scripts/analysis/transplant_kn5000_labels.py`
(105 byte-verified proposals — read its retraction banner first).

## The frontier at resume

⚠ **This table is GENERATED. Regenerate it, never retype it** — the README's status section went
stale within one commit precisely because it was maintained by hand, and the first draft of this
very section, typed from a shell heredoc, already omitted two thunk runs (`T_F40214` into
`0xF96018`, and `T_F41F54`'s one remaining slot in `0xFDE70F`).

    python3 notes/wave7_frontier_table.py             # what follows, in full
    python3 notes/wave7_frontier_table.py --selftest  # 16 checks, incl. the LAST span of each image

Output at resume, truncated to the spans a wave would plausibly pick:

```
=== prom_a: 13 .incbin spans, 106,585 bytes still unconverted ===
    0xFAD800-0xFB2000  file 0x2D800     18,432 bytes
        <- T_F41F10-T_F41F3C     12 slots,  12 unconverted, extent   3216,   17 refs
        <- T_Evt2030_RunList-T_ParamApply_OneHotOfSix     20 slots,  20 unconverted, extent   2595,   35 refs
        <- T_F40840-T_F40840      1 slots,   1 unconverted, extent      0,    1 refs
    0xFA5AEB-0xFAA000  file 0x25AEB     17,685 bytes
        <- T_MidiIn_ReqListRebuild_Msg13_16-T_F43358      3 slots,   3 unconverted, extent   8886,    1 refs
        <- T_F40744-T_F40760      8 slots,   8 unconverted, extent   7668,   16 refs
        <- T_F40714-T_F40734      9 slots,   3 unconverted, extent    245,    7 refs
    0xFA1404-0xFA5400  file 0x21404     16,380 bytes
    0xF85FF9-0xF89800  file 0x05FF9     14,343 bytes
        <- T_F40F34-T_F40F50      8 slots,   8 unconverted, extent   2691,  125 refs
        <- T_F40F58-T_F40F94     16 slots,  16 unconverted, extent   1729,    6 refs
    0xF96018-0xF99021  file 0x16018     12,297 bytes
        <- T_F40244-T_F4025C      7 slots,   7 unconverted, extent   5451,   13 refs
        <- T_F401D4-T_F401F0      8 slots,   8 unconverted, extent    576,   16 refs
        <- T_F40214-T_F40228      6 slots,   6 unconverted, extent     21,   19 refs
    0xFC3000-0xFC5400  file 0x43000      9,216 bytes
    0xF8C000-0xF8DA00  file 0x0C000      6,656 bytes
        <- T_F40664-T_F406A0     16 slots,  16 unconverted, extent   2193,   10 refs
    0xFDE70F-0xFE0000  file 0x5E70F      6,385 bytes
        <- T_F41F54-T_F421A8    150 slots,   1 unconverted, extent      0,    0 refs
    0xFC7000-0xFC8000  file 0x47000      4,096 bytes
    0xF85B0D-0xF85C89  file 0x05B0D        380 bytes
    0xF85D1C-0xF85E8A  file 0x05D1C        366 bytes
    0xF8E6FA-0xF8E800  file 0x0E6FA        262 bytes
    0xFA570C-0xFA5763  file 0x2570C         87 bytes

=== prom_b: 124 .incbin spans, 159,459 bytes still unconverted ===
    0xF4F000-0xF55000  file 0x4F000     24,576 bytes
        <- T_F42E40-T_F42E6C     12 slots,  12 unconverted, extent   4624,   16 refs
    0xF067A6-0xF0C735  file 0x067A6     24,463 bytes
        <- T_F41F54-T_F421A8    150 slots,   5 unconverted, extent   2657,    0 refs
        <- T_F42F80-T_F42FAC     12 slots,  11 unconverted, extent   1512,   40 refs
        <- T_F42320-T_F42380     25 slots,   6 unconverted, extent    572,    0 refs
        <- T_ScreenEnter_SoundEditDigitalEffect-T_F433EC      8 slots,   2 unconverted, extent    162,    0 refs
    0xF353AB-0xF3934C  file 0x353AB     16,289 bytes
        <- T_F41250-T_F41264      6 slots,   6 unconverted, extent   4091,    8 refs
        <- T_F42660-T_F42664      2 slots,   2 unconverted, extent     67,    2 refs
    0xF17559-0xF1B400  file 0x17559     16,039 bytes
        <- T_F42FD0-T_DL_Pt1Pt2Pt3Pt4Pt5Pt6Pt7Pt8     13 slots,  13 unconverted, extent   1199,    0 refs
    0xF5553F-0xF57D1E  file 0x5553F     10,207 bytes
        <- T_F40D90-T_F40E18     35 slots,  35 unconverted, extent   3365,    8 refs
        <- T_TableDefault_Ret-T_F42CA8     15 slots,   3 unconverted, extent    427,   33 refs
        <- T_F40ED0-T_F40EF0      9 slots,   1 unconverted, extent      0,    0 refs
    0xF78029-0xF7A400  file 0x78029      9,175 bytes
    0xF3E15C-0xF40000  file 0x3E15C      7,844 bytes
    0xF7E2D8-0xF80000  file 0x7E2D8      7,464 bytes
    0xF00000-0xF01800  file 0x00000      6,144 bytes
        <- T_F40970-T_F40984      6 slots,   6 unconverted, extent    767,    7 refs
        <- T_F409A0-T_F409B4      6 slots,   6 unconverted, extent    687,   33 refs
    0xF29BC6-0xF2ADD2  file 0x29BC6      4,620 bytes
    0xF0DB18-0xF0E800  file 0x0DB18      3,304 bytes
    0xF13D34-0xF147AC  file 0x13D34      2,680 bytes
    0xF3D089-0xF3DA6F  file 0x3D089      2,534 bytes
    0xF0D061-0xF0D79C  file 0x0D061      1,851 bytes
    0xF3C947-0xF3D016  file 0x3C947      1,743 bytes
    0xF0191A-0xF01E72  file 0x0191A      1,368 bytes
    0xF05AB4-0xF05F78  file 0x05AB4      1,220 bytes
    0xF283A7-0xF28802  file 0x283A7      1,115 bytes
    0xF3B3B2-0xF3B7C3  file 0x3B3B2      1,041 bytes
    0xF32FE6-0xF33362  file 0x32FE6        892 bytes
    0xF33F01-0xF341B6  file 0x33F01        693 bytes
    0xF039ED-0xF03C95  file 0x039ED        680 bytes
    0xF2BB0D-0xF2BD18  file 0x2BB0D        523 bytes
    0xF3DC21-0xF3DE26  file 0x3DC21        517 bytes
    0xF2B38F-0xF2B574  file 0x2B38F        485 bytes
    0xF39559-0xF3972D  file 0x39559        468 bytes
    0xF32709-0xF328DC  file 0x32709        467 bytes
    0xF036C2-0xF03892  file 0x036C2        464 bytes
    0xF3B7CD-0xF3B99D  file 0x3B7CD        464 bytes
    0xF3DEB2-0xF3E06E  file 0x3DEB2        444 bytes
    0xF0D7E2-0xF0D99C  file 0x0D7E2        442 bytes
    0xF2AF81-0xF2B130  file 0x2AF81        431 bytes
    0xF3DA77-0xF3DC00  file 0x3DA77        393 bytes
    0xF3C37D-0xF3C4D5  file 0x3C37D        344 bytes
    0xF0550B-0xF0564B  file 0x0550B        320 bytes
    0xF04042-0xF0417E  file 0x04042        316 bytes
    0xF34C6E-0xF34D98  file 0x34C6E        298 bytes
    0xF39737-0xF39854  file 0x39737        285 bytes
    0xF3987A-0xF3998E  file 0x3987A        276 bytes
    0xF2B8F9-0xF2BA0C  file 0x2B8F9        275 bytes
    0xF34256-0xF34361  file 0x34256        267 bytes
    0xF3A6D9-0xF3A7DA  file 0x3A6D9        257 bytes
    0xF04574-0xF04672  file 0x04574        254 bytes
    0xF3A0D9-0xF3A1CF  file 0x3A0D9        246 bytes
    0xF32992-0xF32A7D  file 0x32992        235 bytes
    0xF05286-0xF0535E  file 0x05286        216 bytes
    0xF297A0-0xF29863  file 0x297A0        195 bytes
    0xF03F77-0xF0402E  file 0x03F77        183 bytes
    0xF3C7CD-0xF3C86B  file 0x3C7CD        158 bytes
    0xF05407-0xF0549D  file 0x05407        150 bytes
    0xF2B2E3-0xF2B379  file 0x2B2E3        150 bytes
    0xF3391E-0xF339B4  file 0x3391E        150 bytes
    0xF296D6-0xF29765  file 0x296D6        143 bytes
    0xF33394-0xF3341C  file 0x33394        136 bytes
    0xF339BC-0xF33A3F  file 0x339BC        131 bytes
    0xF02F36-0xF02FB2  file 0x02F36        124 bytes
    0xF14FAC-0xF15024  file 0x14FAC        120 bytes
    0xF0574D-0xF057C0  file 0x0574D        115 bytes
    0xF394E3-0xF39551  file 0x394E3        110 bytes
    0xF3C6B3-0xF3C721  file 0x3C6B3        110 bytes
    0xF04FFD-0xF05063  file 0x04FFD        102 bytes
    0xF02295-0xF022F7  file 0x02295         98 bytes
    0xF03107-0xF03169  file 0x03107         98 bytes
    0xF34E88-0xF34EE8  file 0x34E88         96 bytes
    0xF3B065-0xF3B0C3  file 0x3B065         94 bytes
    0xF04DA3-0xF04DFF  file 0x04DA3         92 bytes
    0xF04CE8-0xF04D43  file 0x04CE8         91 bytes
    0xF32A87-0xF32AD7  file 0x32A87         80 bytes
    0xF334AE-0xF334FE  file 0x334AE         80 bytes
    0xF03173-0xF031BF  file 0x03173         76 bytes
    0xF33B8C-0xF33BD8  file 0x33B8C         76 bytes
    0xF06598-0xF065E0  file 0x06598         72 bytes
    0xF3AD42-0xF3AD88  file 0x3AD42         70 bytes
    0xF05372-0xF053B6  file 0x05372         68 bytes
    0xF05182-0xF051C2  file 0x05182         64 bytes
    0xF0D9A4-0xF0D9E2  file 0x0D9A4         62 bytes
    0xF3AA17-0xF3AA54  file 0x3AA17         61 bytes
    0xF054B1-0xF054ED  file 0x054B1         60 bytes
    0xF3BD58-0xF3BD90  file 0x3BD58         56 bytes
    0xF3BF48-0xF3BF80  file 0x3BF48         56 bytes
    0xF02FF7-0xF0302A  file 0x02FF7         51 bytes
    0xF2882B-0xF2885B  file 0x2882B         48 bytes
    0xF28866-0xF28896  file 0x28866         48 bytes
    0xF288A1-0xF288D1  file 0x288A1         48 bytes
    0xF33508-0xF33538  file 0x33508         48 bytes
    0xF3A433-0xF3A461  file 0x3A433         46 bytes
    0xF05801-0xF0582E  file 0x05801         45 bytes
    0xF04F46-0xF04F72  file 0x04F46         44 bytes
    0xF3A0A5-0xF3A0D1  file 0x3A0A5         44 bytes
    0xF3C873-0xF3C89D  file 0x3C873         42 bytes
    0xF32B3C-0xF32B64  file 0x32B3C         40 bytes
    0xF32C02-0xF32C2A  file 0x32C02         40 bytes
    0xF3380E-0xF33836  file 0x3380E         40 bytes
    0xF33A49-0xF33A71  file 0x33A49         40 bytes
    0xF3AB74-0xF3AB9C  file 0x3AB74         40 bytes
    0xF3B21C-0xF3B244  file 0x3B21C         40 bytes
    0xF35035-0xF3505B  file 0x35035         38 bytes
    0xF0355D-0xF03581  file 0x0355D         36 bytes
    0xF338A5-0xF338C9  file 0x338A5         36 bytes
    0xF3C53F-0xF3C562  file 0x3C53F         35 bytes
    0xF03478-0xF03498  file 0x03478         32 bytes
    0xF03D4A-0xF03D68  file 0x03D4A         30 bytes
    0xF03617-0xF03633  file 0x03617         28 bytes
    0xF050F1-0xF0510D  file 0x050F1         28 bytes
    0xF034C6-0xF034DE  file 0x034C6         24 bytes
    0xF04E93-0xF04EAB  file 0x04E93         24 bytes
    0xF33840-0xF33858  file 0x33840         24 bytes
    0xF3C351-0xF3C367  file 0x3C351         22 bytes
    0xF3C7AD-0xF3C7C3  file 0x3C7AD         22 bytes
    0xF06562-0xF06576  file 0x06562         20 bytes
    0xF32B1E-0xF32B32  file 0x32B1E         20 bytes
    0xF32B97-0xF32BAB  file 0x32B97         20 bytes
    0xF399C1-0xF399D5  file 0x399C1         20 bytes
    0xF3C199-0xF3C1AD  file 0x3C199         20 bytes
    0xF04F20-0xF04F32  file 0x04F20         18 bytes
    0xF04E32-0xF04E42  file 0x04E32         16 bytes
    0xF0509B-0xF050AB  file 0x0509B         16 bytes
    0xF0DA93-0xF0DAA2  file 0x0DA93         15 bytes
    0xF351F9-0xF35208  file 0x351F9         15 bytes
    0xF349BB-0xF349C7  file 0x349BB         12 bytes
    0xF3356B-0xF33573  file 0x3356B          8 bytes
    0xF34968-0xF34970  file 0x34968          8 bytes
    0xF343B6-0xF343BC  file 0x343B6          6 bytes
    0xF3533C-0xF35342  file 0x3533C          6 bytes

=== prom_c: 0 .incbin spans, 0 bytes still unconverted ===
    territorially complete -- remaining work is MEANING, not territory

=== prom_d: 0 .incbin spans, 0 bytes still unconverted ===
    territorially complete -- remaining work is MEANING, not territory

MEANING (not territory):  4,997 routines still named only sub_XXXXXX
                          2,706 Evidence: lines in routine headers
Territory is scripts/analysis/source_coverage.py; the GATE is
scripts/analysis/assert_byte_identical.py and nothing else.
```

prom_c and prom_d have **zero `.incbin`** — territorially complete. Their remaining work is
meaning, not territory: the 65,972-byte byte-code stream at `0xFCD0F7-0xFDD2AA` left whole
because its framing desynchronises at the fifth record (it needs its interpreter found
first — guessing a stride is this project's known failure mode), gap A's four registers
with no statement of any kind (`0x0440`, `0x0480`, `0x04C0`, `0x0500`), and the 4,997
`sub_XXXXXX`.

## What the emulator is asking for

`notes/WSA1-EMULATION-DISASM-GAPS.md`, ~95 ranked entries. Prefer targets that answer it.
Its top three were refreshed on 2026-08-26 **after** wave 6 closed the previous three, so
read that section rather than the older body.
