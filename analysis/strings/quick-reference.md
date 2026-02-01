# String Offsets Quick Reference

**ROM:** `kn5000_v10_program.rom`
**Address Mapping:** CPU Address = File Offset + `0xE00000`

## Product Identification

| Offset | String |
|--------|--------|
| `0x5957E` | KN5000 ~95 VOCALIST WORKSTATION |
| `0x450B9` | Technics |
| `0xA0150` | KN5000 SOUND RAM |

## File Format Headers

| Offset | String |
|--------|--------|
| `0x038` | Technics KN5000 Program DATA FILE 1/2 |
| `0x060` | Technics KN5000 Program DATA FILE 2/2 |
| `0x088` | Technics KN5000 Program DATA FILE PCK |
| `0x0B0` | Technics KN5000 Table DATA FILE 1/2 |
| `0x0D8` | Technics KN5000 Table DATA FILE 2/2 |
| `0x100` | Technics KN5000 Table DATA FILE PCK |
| `0x128` | Technics KN5000 CMPCUSTOMDATA FILE |
| `0x150` | Technics KN5000 HD-AEPRG DATA FILE |

## Instrument Bank Categories

**Main catalog at offset `0x23F0`:**

PIANO, GUITAR, STRINGS & VOCAL, BRASS, FLUTE, SAX & REED, MALLET&ORCH PERC, WORLD PERC, ORGAN&ACCORDION, ORCHESTRAL PAD, SYNTH, BASS, DIGITAL DRAWBAR, ACCORDION REG., GM SPECIAL, DRUM KITS, MEMORY A, MEMORY B

### Memory Banks

| Offset | String |
|--------|--------|
| `0xCFDE0` | MEMORY-C |
| `0xCFDEA` | MEMORY-B |
| `0xCFDF4` | MEMORY-A |

## Keyboard Layout & Parts

**At offset `0xCFDFE`:**

RIGHT1, RIGHT2, LEFT, PART4-PART16, ACCOMP1, ACCOMP2, ACCOMP3, BASS, DRUMS, CHORD, R.BASS, MSP, CONTROL, PART27-PART32

## Sequencer Features

| Offset | String |
|--------|--------|
| `0x28A66` | SEQUENCER MENU |
| `0x28C7E` | SEQUENCER PLAY |
| `0x29586` | SONG SELECT /NAMING |
| `0x295D0` | SONG CLEAR |
| `0x29612` | SONG/TRACK COPY |
| `0x22BC0` | TRACK ASSIGN |
| `0x2AAB0` | TRACK CLEAR |
| `0x2AAF2` | TRACK MERGE |
| `0x0B90E` | STEP RECORD: |

## Recording

| Offset | String |
|--------|--------|
| `0x1806E` | RECORDING |
| `0x1819A` | RECORD MEMORY |
| `0x184EC` | RECORD SETTING |

## Rhythm & Chord Control

| Offset | String |
|--------|--------|
| `0x26338` | RHYTHM |
| `0x26356` | CHORD |
| `0x341AA` | RHYTHM GROUP |
| `0xA27A2` | RHYTHM CUSTOM |
| `0xD1304` | RHYTHM SELECTION |
| `0x0C3BE` | Chord types (B, Maj7, aug, min, etc.) |

## Panel Memory

| Offset | String |
|--------|--------|
| `0xD1104` | PANEL MEMORY 8 |
| `0xD1116` | PANEL MEMORY 7 |
| `0xD1128` | PANEL MEMORY 6 |
| `0xD113A` | PANEL MEMORY 5 |
| `0xD114C` | PANEL MEMORY 4 |
| `0xD115E` | PANEL MEMORY 3 |
| `0xD1170` | PANEL MEMORY 2 |
| `0xD1182` | PANEL MEMORY 1 |

## Audio Effects

| Offset | String |
|--------|--------|
| `0x1153EC` | DIGITAL EFFECT |
| `0x02818A` | DSP EFFECT |

**Effect types at `0x115B01`:**
CELESTE 1, CELESTE 2, CHORUS 1, CHORUS 2, ENSEMBLE 1, ENSEMBLE 2, TREMOLO, ORGAN TREMOLO, SINGLE DELAY, REPEAT DELAY, SOLO EFFECT 1, SOLO EFFECT 2, MONO, STEREO

## Special Features

### Drawbar & Accordion

| Offset | String |
|--------|--------|
| `0x841E0` | DRAWBAR SETTING |
| `0x846D6` | DRAWBAR EDIT |
| `0x84758` | ACCORDION REGISTER |
| `0x865FE` | TT_DRAWBAR |
| `0x8660A` | TT_ACCORDION |

### Piano Disc

| Offset | String |
|--------|--------|
| `0x2199C` | PIANO DISC DIRECT PLAY |
| `0x221A2` | PIANO DISC MEDLEY |

### Master Control

| Offset | String |
|--------|--------|
| `0x81A50` | MASTER TUNING |
| `0x83D1E` | TRACK MIXER |
| `0x2DA2E` | METRONOME BALANCE |

## Performance & APC

| Offset | String |
|--------|--------|
| `0x0FFEA1` | APC OFF, BASIC, ADVANCED 1, PIANIST, PIANO MODE, ADVANCED 2, SPLIT |
| `0x0FFF7A` | APC MEMORY ON |
| `0x0D12DC` | APC & MEMORY |

## MIDI Control

| Offset | String |
|--------|--------|
| `0x57018` | PRG.CHANGE\|BANK SELECT\|PITCH BEND\|VOLUME\|EXPRESSION\|PAN\|SUSTAIN\|EFFECT & REVERB |

## Volume Control

**At offset `0xFF932`:**
RT1, RT2, LFT, P4-P15, KBP, AC1, AC2, AC3, DRUM

## Sound Edit Menu

**At offset `0xD57A`:**

| Prefix | Meaning |
|--------|---------|
| `MD_` | Mode descriptor |
| `TT_` | Text title |

Key entries: MD_SOUNDEDIT, TT_SEMENU, TT_SEEASY, TT_DRAWBAR, TT_ACCORDION, TT_SECOPY, TT_SEWRTMEM, TT_SEWRTSND

## System Modes

| Offset | String |
|--------|--------|
| `0xD897C` | MD_NORMAL |
| `0xD8986` | MD_CONTROL |
| `0xD899A` | TT_NORMAL |
| `0xD89A4` | TT_CTMENU |

## Statistics

- **Total Strings:** 9,446 (8+ characters)
- **ROM Size:** 2 MB (0x200000 bytes)
- **Memory Mapping:** File 0x00000-0x1FFFFF = CPU 0xE00000-0xFFFFFF
