# The KN5000 label transplant is off by 0xEB00 — the corrected table

**This is a SECOND, independent arrival at a bug the prom_c lane had already
found.** `notes/kn5000-label-transplant.md` already carries their retraction and
their proof (payload offset `0x1A64` vs `EGEnv_ValueCurve_Simple` at `0x010964`).
Nothing here overturns that; it agrees with it exactly, from the other end of the
machine, and adds three things that were missing:

1. a check that runs and fails loudly — `prom_a/kn5000_run_offsets.py`;
2. the **corrected 105-proposal table** (the old run produced 8, and the reason
   for the difference is itself evidence — see below);
3. one of those proposals actually converted, read and named, in
   `prom_a/wsa1_prom_a.s`: `Int_SignedDiv` / `FP_UnsignedDiv` at `0xFE68F3`.

The bug was hit from prom_a by trying to *use* a proposal: the note offered
`DSP_EffParam_Copy_V4` for `0xFE692E`, and the code there is a signed 64-bit
divide.

## The bug

`scripts/analysis/transplant_kn5000_labels.py` maps a byte run found at KN5000
payload **file offset** `p` onto the KN5000 label whose **address** falls in
`[0x400 + p, 0x400 + p + len)`:

```python
PAYLOAD_BASE = 0x0400
...
lo, hi = PAYLOAD_BASE + poff, PAYLOAD_BASE + poff + L
```

The payload image really is linked at `0x0400` — `v142/subcpu/subcpu.ld:10` says
`ORIGIN = 0x0400`, and `llvm-readelf` reports `.text` at address `0x400`, file
offset `0x400`. So the mapping looks right, and that is exactly why it survived.

But `original_ROMs/kn5000_subprogram_v142.rom` is **not** that image. It is a
splice. `../kn5000-roms-disasm/Makefile:635-640`:

```make
$(LLVM_OBJCOPY) -O binary $< $@.full
dd if=$@.full of=$@.part_a bs=1 count=256
dd if=$@.full of=$@.part_b bs=1 skip=60416
cat $@.part_a $@.part_b > $@
```

First 0x100 bytes, then a **0xEB00-byte hole**, then the rest. So

| rom offset | KN5000 sub-CPU address |
|---|---|
| `< 0x100` | `0x400 + offset` |
| `>= 0x100` | `0xEF00 + offset` |

and everything except the first 256 bytes is named 0xEB00 too low.

## How it was checked

`prom_a/kn5000_run_offsets.py` — run it, it exits non-zero if the claim fails:

```
$ python3 prom_a/kn5000_run_offsets.py
symbol                     addr     -0x400 lands on   -0xEF00 lands on   expected
  Int_SignedDiv            0x3DC14                     25 00              25 00
  FP_UnsignedDiv           0x3DC69                     e9 cf 01 00 00 00  e9 cf 01 00 00 00
  DSP_EffParam_Copy_V4     0x2F14F  c9 d8              d8 12              d8 12
  DSP_EffParam_Copy_V5     0x2F19F  ea 12              d8 12              d8 12

PASS: payload address = rom offset + 0xEF00 (above the first 256 bytes);
      the 0x400 mapping is wrong by 0xEB00.
```

It assembles the first instruction the sibling *source* shows at each symbol and
checks which candidate offset holds those bytes. The two rows with a blank
"-0x400" column are the sharpest evidence: `0x3DC14 - 0x400` is past the end of a
0x30000-byte file, so for symbols above `0x30400` the old mapping cannot even be
evaluated — the script silently skipped them, which is why the old note found
only 8 proposals where the corrected run finds 105.

A second, independent check, on the one run that has been converted:
prom_a `0xFE68F2-0xFE699B` is 170 bytes identical to KN5000 `0x3DC13-0x3DCBC`,
and the **fourteen** labels the sibling defines in that window land on

```
0xFE68F3 0xFE6904 0xFE6914 0xFE6926 0xFE692A 0xFE693A 0xFE693E 0xFE6948
0xFE696B 0xFE6981 0xFE6986 0xFE698D 0xFE6998 0xFE699A
```

— every one an instruction boundary *and* a basic-block head in the WSA1
disassembly (see `Int_SignedDiv` in `prom_a/wsa1_prom_a.s`). Fourteen for
fourteen is not what a wrong alignment produces. Under the old mapping the first
"matching" routine started in the middle of an instruction.

## What has to change

* `scripts/analysis/transplant_kn5000_labels.py` — `PAYLOAD_BASE` must become a
  function of the offset, not a constant. **Not fixed here**: this pass was
  scoped to `prom_a/` and `notes/`, and that file belongs to another lane.
* `notes/kn5000-label-transplant.md` — already retracted by the prom_c lane;
  now also cross-references this note.
* `prom_a/kn5000_run_offsets.py` should probably move to `scripts/analysis/`
  once someone owns that directory again; it is here only because of the same
  scope rule.

## The corrected table

Regenerate with:

```
python3 prom_a/kn5000_run_offsets.py --proposals
```

Same entropy guard and same 48-byte minimum run as the original tool; only the
offset-to-address mapping differs. **105 proposals.**

⚠ Unchanged from the original tool's warning, and worth repeating: byte identity
establishes that the code is the same, not that the surrounding machine is, and
the byte gate is blind to a wrong *name*. These are proposals. The one that has
actually been converted and read (`Int_SignedDiv`) checks out; the other 104 have
not been read.

| WSA1 image | WSA1 addr | KN5000 name | run len | KN5000 subcpu addr |
|---|---|---|---:|---|
| prom_c | `0xFDD5AB` | `Voice_DepthMirror_Table` | 4331 | `0x0FEE4` |
| prom_c | `0xFDD62B` | `PitchBend_ScaleCoeff_Table` | 4331 | `0x0FF64` |
| prom_c | `0xFDD6AB` | `Voice_Colour_TransferCurves` | 4331 | `0x0FFE4` |
| prom_c | `0xFDDDAB` | `Voice_Colour_RowOffset_Table` | 4331 | `0x106E4` |
| prom_c | `0xFDDE2B` | `Voice_OutputLevel_Table` | 4331 | `0x10764` |
| prom_c | `0xFDE02B` | `EGEnv_ValueCurve_Simple` | 4331 | `0x10964` |
| prom_c | `0xFDE12B` | `EGEnv_BaseCurve_A` | 4331 | `0x10A64` |
| prom_c | `0xFDE22B` | `EGEnv_BaseCurve_B` | 4331 | `0x10B64` |
| prom_c | `0xFDE32B` | `Voice_FreqWrite_BaseCurve` | 4331 | `0x10C64` |
| prom_c | `0xFDE42B` | `Voice_ToneRampPitch_Curve` | 4331 | `0x10D64` |
| prom_c | `0xFDE47B` | `Voice_ToneRampFilter_Curve` | 4331 | `0x10DB4` |
| prom_c | `0xFDE495` | `Voice_PitchDepth_Scale` | 4331 | `0x10DCE` |
| prom_c | `0xFDE595` | `Voice_FilterDepth_Scale` | 4331 | `0x10ECE` |
| prom_c | `0xFDE695` | `DSP_AlgoChannel_SelectorRecords` | 4331 | `0x10FCE` |
| prom_c | `0xFDE6A9` | `DSP_AlgoChannel_SelectorRecords` | 2555 | `0x10FCE` |
| prom_c | `0xFDE6AD` | `DSP_AlgoChannel_SelectorByte4` | 2555 | `0x10FD2` |
| prom_c | `0xFDE6AE` | `DSP_AlgoChannel_SelectorByte5` | 2555 | `0x10FD3` |
| prom_c | `0xFDE6F1` | `DSP_ChanFreq_CurvePool` | 2555 | `0x11016` |
| prom_c | `0xFDEA21` | `DSP_ChanFreq_Dispatch1_Curves` | 2555 | `0x11346` |
| prom_c | `0xFDEB53` | `DSP_ChanFreq_Packet1_Curve` | 2555 | `0x11478` |
| prom_c | `0xFDEBB9` | `DSP_ChanFreq_IndexMap` | 2555 | `0x114DE` |
| prom_c | `0xFDEBEC` | `EGEnv_ModeBits_Table` | 2555 | `0x11511` |
| prom_c | `0xFDEBF4` | `TVF_KeyFollow_Curves` | 2555 | `0x11519` |
| prom_c | `0xFDEF74` | `Voice_LevelPair_AttackCurve` | 2555 | `0x11899` |
| prom_c | `0xFDEF8E` | `Voice_LevelPair_Bit11Default` | 2555 | `0x118B3` |
| prom_c | `0xFDEFD9` | `Voice_EnvelopeLevel_Curve` | 2555 | `0x118FE` |
| prom_c | `0xFDF03E` | `Voice_EnvelopeRate_Table` | 2555 | `0x11963` |
| prom_c | `0xFDF0A3` | `Detune_Scale_Curve` | 2555 | `0x119C8` |
| prom_c | `0xFDF3F1` | `Voice_CC_VolumeCurve` | 724 | `0x11D16` |
| prom_c | `0xFDF4F1` | `DSP_AlgoDescriptor_Records` | 724 | `0x11E16` |
| prom_c | `0xFDF4F7` | `DSP_AlgoDescriptor_SelIdx` | 724 | `0x11E1C` |
| prom_c | `0xFDF4FE` | `DSP_AlgoDescriptor_FlagsAB` | 724 | `0x11E23` |
| prom_c | `0xFDF4FF` | `DSP_AlgoDescriptor_ValueAB` | 724 | `0x11E24` |
| prom_c | `0xFDF156` | `TVF_DepthRecords_A` | 685 | `0x119FB` |
| prom_c | `0xFDF180` | `TVF_DepthRecords_B` | 685 | `0x11A25` |
| prom_c | `0xFDF1AA` | `Voice_FineTune_Curve` | 685 | `0x11A4F` |
| prom_c | `0xFDF22A` | `Instrument_OctaveShift_Semitones` | 685 | `0x11ACF` |
| prom_c | `0xFDF23A` | `Voice_EnvLevel_IndexMap` | 685 | `0x11ADF` |
| prom_c | `0xFDF243` | `Voice_VibratoDepth_Table` | 685 | `0x11AE8` |
| prom_c | `0xFDF2C3` | `Voice_ChromaticBend_Table` | 685 | `0x11B68` |
| prom_c | `0xFDF3D7` | `Voice_KeyShiftRamp_Steps` | 685 | `0x11C7C` |
| prom_c | `0xFCC61A` | `ToneGen_Velocity_Input_Curve` | 513 | `0x1F43E` |
| prom_c | `0xFCC71A` | `ToneGen_Velocity_Output_Curve` | 513 | `0x1F53E` |
| prom_c | `0xFCCD71` | `DSP_MixerGain_Curve` | 512 | `0x131CF` |
| prom_c | `0xFE1375` | `Const_ChannelMax` | 319 | `0x0F785` |
| prom_c | `0xFE1376` | `Const_Zero_Byte` | 319 | `0x0F786` |
| prom_c | `0xFE1377` | `PitchDetune_OffsetTable` | 319 | `0x0F787` |
| prom_c | `0xFE138A` | `Voice_Part_Trim_Table_B` | 319 | `0x0F79A` |
| prom_c | `0xFE139C` | `Voice_Part_Trim_Addend_1` | 319 | `0x0F7AC` |
| prom_c | `0xFE13AE` | `Voice_Part_Trim_Addend_2` | 319 | `0x0F7BE` |
| prom_c | `0xFE13C2` | `Voice_Part_Trim_Base` | 319 | `0x0F7D2` |
| prom_c | `0xFE13D6` | `Voice_Portamento_Rate_Table` | 319 | `0x0F7E6` |
| prom_c | `0xFE14A0` | `Voice_DefaultToneRecord` | 319 | `0x0F8B0` |
| prom_c | `0xFE1F7A` | `Const_ChannelMax` | 319 | `0x0F785` |
| prom_c | `0xFE1F7B` | `Const_Zero_Byte` | 319 | `0x0F786` |
| prom_c | `0xFE1F7C` | `PitchDetune_OffsetTable` | 319 | `0x0F787` |
| prom_c | `0xFE1F8F` | `Voice_Part_Trim_Table_B` | 319 | `0x0F79A` |
| prom_c | `0xFE1FA1` | `Voice_Part_Trim_Addend_1` | 319 | `0x0F7AC` |
| prom_c | `0xFE1FB3` | `Voice_Part_Trim_Addend_2` | 319 | `0x0F7BE` |
| prom_c | `0xFE1FC7` | `Voice_Part_Trim_Base` | 319 | `0x0F7D2` |
| prom_c | `0xFE1FDB` | `Voice_Portamento_Rate_Table` | 319 | `0x0F7E6` |
| prom_c | `0xFE20A5` | `Voice_DefaultToneRecord` | 319 | `0x0F8B0` |
| prom_c | `0xFCCA82` | `DSP_EQ_FreqHz_Table` | 237 | `0x12397` |
| prom_c | `0xFCCAEE` | `DSP_EQ_Q_Table` | 237 | `0x12403` |
| prom_c | `0xFCCB6E` | `DSP_FreqParamCurve_Algo0` | 237 | `0x12483` |
| prom_a | `0xFE68F3` | `Int_SignedDiv` | 169 | `0x3DC14` |
| prom_a | `0xFE6904` | `Int_SignedDiv_AfterSignA` | 169 | `0x3DC25` |
| prom_a | `0xFE6914` | `Int_SignedDiv_CallUnsigned` | 169 | `0x3DC35` |
| prom_a | `0xFE6926` | `Int_SignedDiv_ResultCorr` | 169 | `0x3DC47` |
| prom_a | `0xFE692A` | `Int_SignedDiv_NegResult` | 169 | `0x3DC4B` |
| prom_a | `0xFE693A` | `Int_SignedDiv_ConstData` | 169 | `0x3DC5B` |
| prom_a | `0xFE693E` | `Int_SignedDiv_AltEntry` | 169 | `0x3DC5F` |
| prom_a | `0xFE6948` | `FP_UnsignedDiv` | 169 | `0x3DC69` |
| prom_a | `0xFE696B` | `FP_UnsignedDiv_Overflow` | 169 | `0x3DC8C` |
| prom_a | `0xFE6981` | `FP_UnsignedDiv_ByOne` | 169 | `0x3DCA2` |
| prom_a | `0xFE6986` | `FP_UnsignedDiv_Zero` | 169 | `0x3DCA7` |
| prom_a | `0xFE698D` | `FP_UnsignedDiv_SmallDividend` | 169 | `0x3DCAE` |
| prom_a | `0xFE6998` | `FP_UnsignedDiv_General` | 169 | `0x3DCB9` |
| prom_a | `0xFE699A` | `FP_UnsignedDiv_ShiftLoop` | 169 | `0x3DCBB` |
| prom_c | `0xFD7764` | `DSP_Eff05_Coef_Bytecode` | 164 | `0x16216` |
| prom_c | `0xFDF6C5` | `Voice_SecondaryParam_Curve` | 155 | `0x12038` |
| prom_c | `0xFDF6E4` | `Voice_SecondaryParam_WordCurveA` | 155 | `0x12057` |
| prom_c | `0xFDF722` | `Voice_SecondaryParam_WordCurveB` | 155 | `0x12095` |
| prom_c | `0xFE10C9` | `Voice_PolyphonyLimits_Table` | 123 | `0x0F48C` |
| prom_c | `0xFE10E9` | `Voice_IndexMapping_Table` | 123 | `0x0F4AC` |
| prom_c | `0xFE1129` | `Voice_CommandIndexTable` | 123 | `0x0F4EC` |
| prom_c | `0xFE1CF4` | `Voice_PolyphonyLimits_Table` | 123 | `0x0F48C` |
| prom_c | `0xFE1D14` | `Voice_IndexMapping_Table` | 123 | `0x0F4AC` |
| prom_c | `0xFE1D54` | `Voice_CommandIndexTable` | 123 | `0x0F4EC` |
| prom_c | `0xFD0C4B` | `DSP_Eff65_Param_Values` | 95 | `0x19833` |
| prom_a | `0xF85F7C` | `DSP_WriteAllChannelRegs` | 68 | `0x1FCFB` |
| prom_a | `0xF85FA8` | `DSP_WriteChannelRegs_Inner` | 68 | `0x1FD27` |
| prom_c | `0xF9806D` | `DSP_WriteAllChannelRegs` | 68 | `0x1FCFB` |
| prom_c | `0xF98099` | `DSP_WriteChannelRegs_Inner` | 68 | `0x1FD27` |
| prom_c | `0xFD08CD` | `DSP_Eff64_Param_Values` | 49 | `0x1956C` |
| prom_c | `0xFD0F98` | `DSP_Eff64_Param_Values` | 49 | `0x1956C` |
| prom_c | `0xFD1399` | `DSP_Eff68_Param_Values` | 49 | `0x1A399` |
| prom_c | `0xFE11F0` | `Voice_KeyTable_Remapping` | 48 | `0x0F603` |
| prom_c | `0xFE11F8` | `Voice_Search_Order_List_1` | 48 | `0x0F60B` |
| prom_c | `0xFE1207` | `Voice_Search_Order_List_2` | 48 | `0x0F61A` |
| prom_c | `0xFE1215` | `Voice_Search_Order_List_3` | 48 | `0x0F628` |
| prom_c | `0xFE1E1B` | `Voice_KeyTable_Remapping` | 48 | `0x0F603` |
| prom_c | `0xFE1E23` | `Voice_Search_Order_List_1` | 48 | `0x0F60B` |
| prom_c | `0xFE1E32` | `Voice_Search_Order_List_2` | 48 | `0x0F61A` |
| prom_c | `0xFE1E40` | `Voice_Search_Order_List_3` | 48 | `0x0F628` |

105 proposals
