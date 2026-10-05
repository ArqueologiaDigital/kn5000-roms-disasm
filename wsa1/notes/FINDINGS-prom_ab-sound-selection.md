# prom_a / prom_b: a part's sound, as a panel selection and as PROGRAM CHANGE & BANK (2026-10-05)

## 1. Two stored forms of a part's sound

A part's sound is stored in two forms, and prom_a 0xFC22BA-0xFC2594 converts between them:

| form | where | bytes |
|---|---|---|
| PROGRAM CHANGE & BANK (the Reference Guide parameter) | the part's first record, bytes 0 / 1 | program, bank |
| the panel selection | the part's second record, +0x1B / +0x1C / +0x1D | group, member, bank code |

The bank codes are `SoundSel_Bank`'s:
- R1 0x00, R2 0x01;
- U1 / U2 0x08 / 0x09, E1 0x10;
- RE-MAP 0x18-0x1A;
- RD 0x20, UD 0x28 / 0x29.

`SoundGroup_LoadSelectionFromPart` copies the second record's three bytes to `SoundSel_Group` / `_Member` /
`_Bank`. The SysEx setter of PROGRAM CHANGE & BANK (`SysExParam_SetProgramChangeAndBank`) stores the pair,
then calls `SoundSel_FromProgramAndBank` and writes its three results to +0x1B..+0x1D.

The converters take their arguments in a RAM block and leave their results there: `SoundConv_Arg0..3`
(0x60F010-0x60F013) and `SoundConv_Result0..2` (0x60F014-0x60F016). What each byte means depends on the
routine:

| routine (slot) | arguments | results |
|---|---|---|
| `SoundSel_ToProgramAndBank` (`T_SoundSel_ToProgramAndBank`) | group, member, -, bank code | program, bank |
| `SoundSel_FromProgramAndBank` (`T_SoundSel_FromProgramAndBank`) | program, bank, part | group, member, bank code |
| `CombiSel_ToNumberAndBank` (`T_CombiSel_ToNumberAndBank`) | group, member, -, bank code | number, bank |
| `CombiSel_FromNumberAndBank` (`T_CombiSel_FromNumberAndBank`) | number, bank | group, member, bank |
| `PartSound_FromProgramChange` (`T_PartSound_FromProgramChange`) | -, -, program number, part | program, bank |
| `PartSound_ToProgramChange` (`T_PartSound_ToProgramChange`) | program, bank, part | bank select (two bytes), program number |

## 2. How each bank converts

- **Preset banks (R1 / R2 / RD).** Two prom_b tables of 8-word rows do the work:
  - `SoundCodeByGroupMember_ModeOffsetGroup` (0xF06EF4) maps (group + bias, member) to (program, bank). The bias
    is 0 for R1, 0x10 for R2 and 0x20 for RD (0x22 in GM mode).
  - `PanelSoundSel_ByProgramAndBank` (0xF07134) maps (program, bank) back. Its row is the program (+0x80 for the
    drum banks), its column the bank & 7. The word's low byte is the group across R1 / R2 / RD, and its high byte
    is the member.

  Every one of the 272 panel selections (128 in R1, 128 in R2, 16 in RD) round-trips exactly, so the two are
  inverses: `python3 notes/prom_ab_sound_selection_tables.py`.
- **User and E banks (0x08 / 0x09 / 0x10).** Number = group x 8 + member, both ways (`PanelSel_ToNumberDirect`,
  `PanelSel_FromNumberDirect`). Combinations use this rule for every bank except RE-MAP.
- **RE-MAP banks (0x18-0x1A).** `SoundRemap_Ram` (0x5210) holds three blocks 0x210 bytes apart. Each block has
  16 group names (`SoundRemap1_GroupNames` ...) followed by 128 (program, bank) words (`SoundRemap1_Map` ...),
  indexed by group x 8 + member. `CombiRemap_Ram` (0x5860) has the same shape for combinations.
- **RE-MAP 3 is also the program-change map.** `PartSound_FromProgramChange` turns a received program number P
  into `SoundRemap3_Map[P]`, except on parts 9 and 0x19, which take (P, bank 0x20). The callers are SMF
  playback and `ParamApply_PartProgMode3`. In the other direction, `PartSound_ToProgramChange` sends index i
  when the part's pair is found in that map. Otherwise it sends the word of `ProgramChangeOut_ByProgramAndBank`
  (0xF08514) at program x 8 + bank & 7. In GM mode (0x7F4D bit 2), `SoundSel_FromPresetProgramAndBank` also
  looks a pair up in `SoundRemap3_Map` first.

## 3. Corrections

Two prom_b tables and one prom_a routine were named after (group, member) indexing:
- `SoundCodeByGroupMember_ByteGroup`;
- `SoundCodeByGroupMember_SevenBitGroup`;
- `SoundCode_FromGroupMember_ByteGroup`.

All three are indexed by (program, bank). They are now `PanelSoundSel_ByProgramAndBank`,
`ProgramChangeOut_ByProgramAndBank` and `SoundSel_FromPresetProgramAndBank`. Their old headers stay, with a
CORRECTED note after each.

prom_b's warning that the three tables "are not inverses of one another" was measured between 0xF07134 and
0xF08514, which are both indexed by (program, bank). 0xF06EF4 and 0xF07134 are inverses.
- Kind of error: misclassification (the index read as the wrong pair).
- Method that produced it: naming from the index arithmetic alone, without the callers that fill the
  arguments.

## 4. Not established

- What `ProgramChangeOut_ByProgramAndBank`'s values are for a given sound. It is not an identity map.
- Why parts 9 and 0x19 are the drum parts (MIDI channel 10 on either port, presumably).
- What "mode 3" in `ParamApply_PartProgMode3` is.
