# Detailed String Analysis

**ROM:** `kn5000_v10_program.rom`
**Address Mapping:** File offset + `0xE00000` = CPU address

## 1. File Format & Version Identifiers

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x038` | `0xE00038` | Technics KN5000 Program DATA FILE 1/2 |
| `0x060` | `0xE00060` | Technics KN5000 Program DATA FILE 2/2 |
| `0x088` | `0xE00088` | Technics KN5000 Program DATA FILE PCK |
| `0x0B0` | `0xE000B0` | Technics KN5000 Table DATA FILE 1/2 |
| `0x0D8` | `0xE000D8` | Technics KN5000 Table DATA FILE 2/2 |
| `0x100` | `0xE00100` | Technics KN5000 Table DATA FILE PCK |
| `0x128` | `0xE00128` | Technics KN5000 CMPCUSTOMDATA FILE |
| `0x150` | `0xE00150` | Technics KN5000 HD-AEPRG DATA FILE |
| `0x450B9` | `0xE450B9` | Technics |
| `0xA0150` | `0xEA0150` | KN5000 SOUND RAM |
| `0xED56C` | `0xEED56C` | KN5000 SOUND RAM |

**Product Version:** `0x5957E` = "KN5000 ~95 VOCALIST WORKSTATION"

## 2. Instrument Categories & Sound Banks

**Main catalog at `0x23F0` (`0xE023F0`):**

PIANO, GUITAR, STRINGS & VOCAL, BRASS, FLUTE, SAX & REED, MALLET&ORCH PERC, WORLD PERC, ORGAN&ACCORDION, ORCHESTRAL PAD, SYNTH, BASS, DIGITAL DRAWBAR, ACCORDION REG., GM SPECIAL, DRUM KITS, MEMORY A, MEMORY B

### Memory Banks

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xCFDE0` | `0xECFDE0` | MEMORY-C |
| `0xCFDEA` | `0xECFDEA` | MEMORY-B |
| `0xCFDF4` | `0xECFDF4` | MEMORY-A |
| `0x1DB3E` | `0xE1DB3E` | MEMORY C |
| `0x1DB48` | `0xE1DB48` | MEMORY B |
| `0x1DB52` | `0xE1DB52` | MEMORY A |

## 3. Drum Kit References

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x95452` | `0xE95452` | DRUMS |
| `0x11618E` | `0xF1618E` | DRUM DETAIL EDIT |
| `0x116208` | `0xF16208` | DRUM SOUND NAMING |
| `0xA04F2` | `0xEA04F2` | PIANODIR.FIL |

## 4. Sequencer & Song Management

### Main Sequencer

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x28A66` | `0xE28A66` | SEQUENCER MENU |
| `0x28C7E` | `0xE28C7E` | SEQUENCER PLAY |
| `0x235B2` | `0xE235B2` | SEQUENCER : |
| `0xA05D7` | `0xEA05D7` | SEQUENCER |
| `0xA41FE` | `0xEA41FE` | SEQUENCER SONG SAVE |

### Song Management

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x23018` | `0xE23018` | SONG : |
| `0x224F4` | `0xE224F4` | SONG MEDLEY |
| `0x29586` | `0xE29586` | SONG SELECT /NAMING |
| `0x295D0` | `0xE295D0` | SONG CLEAR |
| `0x29612` | `0xE29612` | SONG/TRACK COPY |
| `0x2A3CE` | `0xE2A3CE` | SONG CLEAR |
| `0x2A424` | `0xE2A424` | SONG NO/ALL |
| `0x2A654` | `0xE2A654` | SONG/TRACK COPY |

### Track Management

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x22BC0` | `0xE22BC0` | TRACK ASSIGN |
| `0x2C0F2` | `0xE2C0F2` | TRACK : |
| `0x2AAB0` | `0xE2AAB0` | TRACK CLEAR |
| `0x2AAF2` | `0xE2AAF2` | TRACK MERGE |
| `0x2BC72` | `0xE2BC72` | TRACK MERGE |

### Recording Features

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x1806E` | `0xE1806E` | RECORDING |
| `0x1819A` | `0xE1819A` | RECORD MEMORY |
| `0x18454` | `0xE18454` | RECORDING |
| `0x184EC` | `0xE184EC` | RECORD SETTING |

## 5. Sequencer Recording Modes

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xB90E` | `0xE0B90E` | STEP RECORD: |
| `0xB9F1` | `0xE0B9F1` | Are You Sure? |

## 6. Rhythm & Chord Control

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x26338` | `0xE26338` | RHYTHM |
| `0x26356` | `0xE26356` | CHORD |
| `0x26360` | `0xE26360` | DRUMS |
| `0x95414` | `0xE95414` | RHYTHM |
| `0x9543E` | `0xE9543E` | METRONOME |
| `0x95486` | `0xE95486` | R.BASS |
| `0x9D8D4` | `0xE9D8D4` | R.BASS : |
| `0x341AA` | `0xE341AA` | RHYTHM GROUP |
| `0xA27A2` | `0xEA27A2` | RHYTHM CUSTOM |
| `0xD1304` | `0xED1304` | RHYTHM SELECTION |

### Chord Types

At `0xC3BE` (`0xE0C3BE`): B, Maj7, aug, min, min7, dim, m7, 5, mM7, 7sus46, aug7...

## 7. Keyboard Layout & Part Assignments

At `0xCFDFE` (`0xECFDFE`):

```
RIGHT1, RIGHT2, LEFT, PART4, PART5, PART6, PART7, PART8, PART9, PART10,
PART11, PART12, PART13, PART14, PART15, PART16, ACCOMP1, ACCOMP2, ACCOMP3,
BASS, DRUMS, CHORD, R.BASS, MSP, MSP, CONTROL, PART27, PART28, PART29,
PART30, PART31, PART32
```

## 8. Display/Menu Control (Sound Edit)

### Main Menu Structure

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xD57A` | `0xE0D57A` | MD_SOUNDEDIT |
| `0xD588` | `0xE0D588` | TT_SEMENU |
| `0xD592` | `0xE0D592` | TT_SEEASY |

### Sound Edit Sub-menus (at `0xD5A0`+)

```
TT_SETONTON1, TT_SETONTON2, TT_SETONRAN1, TT_SETONRAN2, TT_SETONHYB1,
TT_SEPITPIT1, TT_SEPITENV1, TT_SEPITENV2, TT_SEPITLFO1, TT_SEAMPAMP1,
TT_SEAMPAMP2, TT_SEAMPENV1, TT_SEAMPENV2, TT_SEAMPLFO1, TT_SEFILLPQ1,
TT_SEFILHPQ1, TT_SEFILL241, TT_SEFILH241, TT_SEFILBPF1, TT_SEFILBCF1,
TT_SEFILFIL2, TT_SEFILENV1, TT_SEFILENV2, TT_SEFILLFO1, TT_SEDIGEFF,
TT_SECTR2, TT_SECTR3, TT_SECOPY, TT_SEWRTMEM, TT_SEWRTSND
```

### Sound Edit Functions

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xD840` | `0xE0D840` | SeWrtSndTitleFunc |
| `0xD852` | `0xE0D852` | SeWrtMemTitleFunc |
| `0xD864` | `0xE0D864` | SeCopyTitleFunc |
| `0xD874` | `0xE0D874` | SeCtr3TitleFunc |
| `0xD884` | `0xE0D884` | SeCtr2TitleFunc |
| `0xD894` | `0xE0D894` | SeDigEffTitleFunc |

## 9. Audio Effects

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x1153EC` | `0xF153EC` | DIGITAL EFFECT |
| `0x115C66` | `0xF15C66` | DIGITAL EFFECT: |
| `0x2818A` | `0xE2818A` | DSP EFFECT |
| `0x34328` | `0xE34328` | DIGITAL EFFECT |
| `0x81B9E` | `0xE81B9E` | DSP EFFECT |
| `0xD103E` | `0xED103E` | DSP EFFECT |
| `0xD1050` | `0xED1050` | DIGITAL EFFECT |

### Digital Effect Types

At `0x115B01` (`0xF15B01`):

```
CELESTE 1, CELESTE 2, CHORUS 1, CHORUS 2, ENSEMBLE 1, ENSEMBLE 2,
TREMOLO, ORGAN TREMOLO, SINGLE DELAY, REPEAT DELAY, SOLO EFFECT 1,
SOLO EFFECT 2, MONO, STEREO
```

## 10. Drawbar & Accordion Control

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x841E0` | `0xE841E0` | DRAWBAR SETTING |
| `0x846D6` | `0xE846D6` | DRAWBAR EDIT |
| `0x84758` | `0xE84758` | ACCORDION REGISTER |
| `0x865FE` | `0xE865FE` | TT_DRAWBAR |
| `0x8660A` | `0xE8660A` | TT_ACCORDION |
| `0x81394` | `0xE81394` | EV_ACCORDIONTAB |
| `0x83AF0` | `0xE83AF0` | BIG BAND BRASS |

## 11. Master Control

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x81A50` | `0xE81A50` | MASTER TUNING |
| `0x82414` | `0xE82414` | TUNING : |
| `0x82D5C` | `0xE82D5C` | MASTER TUNING |
| `0x2DA2E` | `0xE2DA2E` | METRONOME BALANCE |
| `0x83D1E` | `0xE83D1E` | TRACK MIXER |

### MIDI Control

At `0x57018` (`0xE57018`):
```
PRG.CHANGE|BANK SELECT|PITCH BEND|VOLUME|EXPRESSION|PAN|SUSTAIN|EFFECT & REVERB
```

### Performance Menu

At `0xD3F72` (`0xED3F72`):
```
PERFORMANCE | CURRENT PANEL | PART SETTING | MIDI SETTING |
PANEL MEMORY | COMPOSER | SEQUENCER | MSP USER | SOUND MEMORY
```

## 12. Panel & Memory Management

### Panel Memory Presets

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xD1104` | `0xED1104` | PANEL MEMORY 8 |
| `0xD1116` | `0xED1116` | PANEL MEMORY 7 |
| `0xD1128` | `0xED1128` | PANEL MEMORY 6 |
| `0xD113A` | `0xED113A` | PANEL MEMORY 5 |
| `0xD114C` | `0xED114C` | PANEL MEMORY 4 |
| `0xD115E` | `0xED115E` | PANEL MEMORY 3 |
| `0xD1170` | `0xED1170` | PANEL MEMORY 2 |
| `0xD1182` | `0xED1182` | PANEL MEMORY 1 |
| `0xD3E22` | `0xED3E22` | PANEL MEMORY MODE |

### Memory Operations

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x199FE` | `0xE199FE` | COMPOSER MEMORY |
| `0x1FA56` | `0xE1FA56` | MEMORY DUMP |
| `0xAA736` | `0xEAA736` | -MEMORY DUMP- |
| `0x1B47A` | `0xE1B47A` | MEMORY : OFF |
| `0x1B488` | `0xE1B488` | MEMORY : ON |
| `0xA0C60` | `0xEA0C60` | TechnicsFileRename |
| `0xA0C74` | `0xEA0C74` | TechnicsFileNaming |

## 13. Piano Disc & Medley Features

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x2199C` | `0xE2199C` | PIANO DISC DIRECT PLAY |
| `0x221A2` | `0xE221A2` | PIANO DISC MEDLEY |
| `0xA4FB2` | `0xEA4FB2` | PIANO DISC DIRECT PLAY |
| `0xA5316` | `0xEA5316` | SONG MEDLEY |

## 14. Performance & APC Control

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x583A6` | `0xE583A6` | PERFORMANCE \| CURRENT PANEL + PANEL MEMORY \| COMPOSER \| SEQUENCER \| MSP USER \| SOUND MEMORY |
| `0x804D4` | `0xE804D4` | \|-\| CONTROL\| \| ACCOMP1\| ACCOMP2\| ACCOMP3\| BASS\| DRUMS\| CHORD |

### APC Modes

At `0xFFEA1` (`0xEFFEA1`):
```
APC OFF, BASIC, ADVANCED 1, PIANIST, PIANO MODE, ADVANCED 2, SPLIT
```

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xFFF7A` | `0xEFFF7A` | APC MEMORY ON |
| `0xD12DC` | `0xED12DC` | APC & MEMORY |

## 15. Accompaniment Parts & Bass Control

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x18BA8` | `0xE18BA8` | \|-\|BASS\|ACCOMP1\|ACCOMP2\|ACCOMP3 |
| `0x19AC0` | `0xE19AC0` | \|-\|DRUMS\|BASS\|ACCOMP1\|ACCOMP2\|ACCOMP3 |
| `0x1B4C6` | `0xE1B4C6` | ON BASS : OFF |
| `0x1B4D4` | `0xE1B4D4` | ON BASS : ON |

### Volume Control

At `0xFF932` (`0xEFF932`):
```
VOLUME=RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP AC1 AC2 AC3 DRUM
```

## 16. Welcome/Version Strings

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x86618` | `0xE86618` | TT_MESAGE |
| `0x86622` | `0xE86622` | TT_WELCOM |
| `0x8662C` | `0xE8662C` | TT_SOFTVER |

## 17. System Mode Strings

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0xD897C` | `0xED897C` | MD_NORMAL |
| `0xD8986` | `0xED8986` | MD_CONTROL |
| `0xD899A` | `0xED899A` | TT_NORMAL |
| `0xD89A4` | `0xED89A4` | TT_CTMENU |

## 18. Rhythm/Style Database (Sample)

Various rhythm and style names found throughout the ROM:

**Classic:** Bolero puro, GentleSwing, GospelRevival, Roaring 20's, AccordionJazz

**Standard:** Rhumba, Mambo, Simple Swing, Orch. Swing, Show Band, Ray Conniff

**Ballroom:** Fox walk, Fox piano, Dance Band, BigBand Slow, Jive, Gypsy Dance, Scottish Reel, Tarantella, Dixie Band

**Pop/Rock:** 8 Beat Pop, Piano R&Roll, 70's Rock, 60's R&Roll, Twist

**Latin:** Guarania, Vaneirao, Rancheira, Frevo, Baiao, Forro, XOTE, Marcha Rancho, CaribbeanRock

**Brazilian:** Samba, Bossanova, Modern Samba, Samba cancao

**Other:** Vienna Dance, Musette Waltz, Techno, Mod.Bluegrass, Country Blues, Oldies

**User:** Clear, Init, Memory A/B/C

## 19. Character Set & ASCII Table

At `0xCB3A` (`0xE0CB3A`):
```
 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[
```

At `0xCB77` (`0xE0CB77`):
```
]^_`abcdefghijklmnopqrstuvwxyz{|}
```

## 20. Additional Control Strings

| File Offset | CPU Address | String |
|-------------|-------------|--------|
| `0x8030E` | `0xE8030E` | \|-\| EFFECT & REVERB\| MODULATION \| TUNING \| BEND RANGE \| AFTER TOUCH \| RESET ALL CONT. |
| `0x7FDC2` | `0xE7FDC2` | SENDING |

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Strings (8+ chars) | ~9,446 |
| Key Categories | 20+ |
| File Format Headers | 8 variants |
| Instrument Banks | 14+ |
| Memory Banks | 3 (A, B, C) |
| Sequencer Functions | 15+ |
| Effects Types | 10+ |
| Performance Modes | 8+ |
| Rhythm Patterns | 100+ |
| Special Features | Drawbar, Accordion, Piano Disc, Medley, Composer |
