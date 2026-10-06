# Naming the 168 options of the `.LSW` voice selector

`lsw_panel_schema_from_rom.py` showed that the four accompaniment part records of the panel
work area — TLV tags `0x10 0x11 0x12 0x13` — carry a **type-3** field descriptor on payload
byte **+0** with `min=0, max=167, default=21` (tag `0x13`: `default=40`), and a second one on
**+1** with `min=0, max=7, default=0`.  This note names those 168 options and proves the
naming.

Reproduce everything below with

```
python3 analysis/disk-format-probes/lsw_voice_selector_names.py            # listing + checks
python3 analysis/disk-format-probes/lsw_voice_selector_names.py --quiet    # checks only
```

## What +0 and +1 are

`+0` is a flat **panel sound number** and `+1` is its **variation bank**.  Two ROM tables
resolve the pair, one in the program ROM and one in the table-data ROM.

### 1. Program ROM — number/bank → (category, index)

```
SoundData_CategoryDesc = 0xE023A0        ; RAM 0x00E14E holds this address
                                         ; (Param_SignExtendRetu_Block, note_voice_mapping.s)
map   = *(SoundData_CategoryDesc + 0x10) = 0xE02510
entry = map + 0x80 + bank*0x400 + number*4    -> u16 category, u16 index-in-category
```

Consumer: `ApplyProgramChangeAs_LoadDRAM2` (`v9/maincpu/audio/note_voice_mapping.s`), reached
through `SndParam_FetchOscTableEntry` from `MainGetSoundName` / `Sound_Navigate_Init`
(`v9/maincpu/audio/sound_navigation.s`) — the routines that build the 18-byte name buffer the
sound-select screen displays.

The category name comes from a genuine fixed-width string table:

| item | value |
|---|---|
| address | `SOUND_CATEGORY_NAMES` = **0xE023F0** (program ROM) |
| stride | **16 bytes** |
| entries | **18** |
| encoding | ASCII, space-padded and centred |

```
 0 PIANO             6 MALLET&ORCH PERC   12 DIGITAL DRAWBAR
 1 GUITAR            7 WORLD PERC         13 ACCORDION REG.
 2 STRINGS & VOCAL   8 ORGAN&ACCORDION    14 GM SPECIAL
 3 BRASS             9 ORCHESTRAL PAD     15 DRUM KITS
 4 FLUTE            10 SYNTH              16 MEMORY A
 5 SAX & REED       11 BASS               17 MEMORY B
```

### 2. Table-data ROM — number/bank → the displayed sound name

The same walk the Sub CPU uses (`ToneDB_Find_PatchRecord`, `v142/subcpu`), documented in
`table_data/tone_database_directory.s`:

```
b    = ToneDB_BankMap_Main[bank]                  ; 0x830100, 128 bytes  (bank 0..7 -> b = bank)
tone = ToneDB_ToneNumBanks_Main[b*128 + number]   ; 0x830180, 11 banks x 128 LE16
name = 16 bytes at 0x830000 + ToneDB_ToneOffsetTable[tone]
                                                  ; 0x831B00, 629 x LE32
```

| item | value |
|---|---|
| name table | the head of each tone record, **ROM 0x8324D4 onwards** (file offset `0x324D4` of `kn5000_table_data.rom`) |
| stride | **variable** (`21 + 81*N` bytes); the names are reached through the 629-entry LE32 offset table at **0x831B00** |
| entries | 629 offset-table slots over 579 distinct records; **117 distinct records** are reachable from variation bank 0 |
| encoding | 16 bytes ASCII, space-padded and centred |

## The 168 options, variation bank +1 = 0

Columns: selector value, tone-record name, panel category + position.

```
    0 Piano            PIANO 1                 1 Bright Piano     PIANO 2            
    2 Mellow Piano     PIANO 11                3 Electric Grand   PIANO 5            
    4 Modern E.P.2     PIANO 18                5 E.Piano 1        PIANO 6            
    6 Modern E.P.1     PIANO 8                 7 Music Box        MALLET&ORCH PERC 15
    8 Vibraphone       MALLET&ORCH PERC 2      9 Glockenspiel     MALLET&ORCH PERC 1 
   10 Marimba          MALLET&ORCH PERC 3     11 Xylophone        MALLET&ORCH PERC 4 
   12 Celesta          MALLET&ORCH PERC 5     13 Bottle Marimba   MALLET&ORCH PERC 12
   14 Tubular Bells    MALLET&ORCH PERC 6     15 Steel Drum       WORLD PERC 5       
   16 Harpsichord      PIANO 9                17 Clavi            PIANO 10           
   18 Cembalo          PIANO 19               19 Harpsichord      PIANO 9            
   20 Classical Guitar GUITAR 1               21 Jazz Ac.Guitar   GUITAR 11          
   22 Folk Guitar      GUITAR 3               23 12 String Guitar GUITAR 14          
   24 Jazz Guitar 2    GUITAR 16              25 Jazz Guitar 1    GUITAR 4           
   26 Bright Solid Gtr GUITAR 6               27 Rock Harmonics   GM SPECIAL 2       
   28 Mellow Solid Gtr GUITAR 17              29 Mute Guitar      GUITAR 8           
   30 Distortion Gtr   GUITAR 9               31 Hawaiian Guitar1 WORLD PERC 1       
   32 Harp             MALLET&ORCH PERC 8     33 Banjo            WORLD PERC 3       
   34 Ukulele          WORLD PERC 18          35 Mandolin         WORLD PERC 11      
   36 Shamisen         WORLD PERC 13          37 Koto             WORLD PERC 12      
   38 Sitar            WORLD PERC 14          39 Kalimba          WORLD PERC 6       
   40 Electric Bass    BASS 3                 41 Slap Bass 1      BASS 8             
   42 Picked E.Bass    BASS 7                 43 Acoustic Bass    BASS 1             
   44 Electric Bass    BASS 3                 45 Basic Synth Bass BASS 18            
   46 Wow Bass         BASS 10                47 Mute Bass        BASS 12            
   48 Trumpet          BRASS 5                49 Trumpet          BRASS 5            
   50 Harmon Mute Tpt  BRASS 6                51 Flugel Horn      BRASS 7            
   52 Bright Trombone  BRASS 8                53 Mellow Trombone  BRASS 18           
   54 Closed Fr.Horn   BRASS 9                55 Orchestral Tuba  GM SPECIAL 3       
   56 Bigband Brass    BRASS 1                57 Marching Brass   BRASS 2            
   58 Brass Fall       BRASS 13               59 Octave Horns     BRASS 12           
   60 Synth Brass 1    BRASS 4                61 Synth Brass 1    BRASS 4            
   62 Synth Brass 1    BRASS 4                63 Synth Brass 2    BRASS 14           
   64 Piccolo          FLUTE 1                65 Jazz Flute       FLUTE 2            
   66 Oboe             SAX & REED 8           67 English Horn     SAX & REED 19      
   68 Jazz Clarinet 1  SAX & REED 7           69 Classic Clarinet SAX & REED 17      
   70 Bassoon          SAX & REED 20          71 Jazz Clarinet 1  SAX & REED 7       
   72 Pan Flute 1      FLUTE 5                73 Bagpipe          GM SPECIAL 4       
   74 Recorder         FLUTE 6                75 Shakuhachi       FLUTE 9            
   76 Soprano Sax      SAX & REED 1           77 Alto Sax         SAX & REED 2       
   78 Breathy Tenor    SAX & REED 5           79 Rock Tenor Sax   SAX & REED 12      
   80 Bright Accordion ORGAN&ACCORDION 8      81 Mellow Accordion ORGAN&ACCORDION 19 
   82 Musette          ORGAN&ACCORDION 9      83 Harmonica        SAX & REED 9       
   84 Full Organ       ORGAN&ACCORDION 4      85 Chapel Organ     ORGAN&ACCORDION 3  
   86 Harmonium        GM SPECIAL 6           87 Theatre Organ    ORGAN&ACCORDION 16 
   88 Perc Organ       ORGAN&ACCORDION 1      89 Full Drawbars    ORGAN&ACCORDION 2  
   90 Pop Organ        ORGAN&ACCORDION 12     91 16' & 1'         ORGAN&ACCORDION 7  
   92 Rock Organ       ORGAN&ACCORDION 14     93 Jazz Drawbars    ORGAN&ACCORDION 6  
   94 Sine Lead        SYNTH 3                95 Sine Lead        SYNTH 3            
   96 Violin           STRINGS & VOCAL 12     97 Cello            STRINGS & VOCAL 14 
   98 Bowed Bass       STRINGS & VOCAL 15     99 Pizzicato Str.   STRINGS & VOCAL 7  
  100 ClassicalStrings STRINGS & VOCAL 11    101 Slow Strings     STRINGS & VOCAL 21 
  102 Octave Strings   STRINGS & VOCAL 22    103 Synth Strings 1  STRINGS & VOCAL 24 
  104 Pop Vocal Ah     STRINGS & VOCAL 27    105 Humming          STRINGS & VOCAL 28 
  106 Goblins          SYNTH 30              107 Synth Vocal      STRINGS & VOCAL 29 
  108 Dream            SYNTH 19              109 Vocal Doo        STRINGS & VOCAL 19 
  110 Humming          STRINGS & VOCAL 28    111 Whistle          FLUTE 8            
  112 Chiffer Lead     SYNTH 4               113 African Mallet   MALLET&ORCH PERC 13
  114 Synth Clavi      PIANO 20              115 Synth Clavi      PIANO 20           
  116 Modern E.P.2     PIANO 18              117 Square Lead      SYNTH 1            
  118 Saw Lead         SYNTH 2               119 5th Wave         SYNTH 36           
  120 Bowed Glass      SYNTH 18              121 Square Lead      SYNTH 1            
  122 Agogo            GM SPECIAL 7          123 Telephone        GM SPECIAL 17      
  124 Synth Drum       GM SPECIAL 12         125 Sleigh Bell      MALLET&ORCH PERC 18
  126 Timpani          MALLET&ORCH PERC 9    127 Orchestra Hit    MALLET&ORCH PERC 10
  128..147  MEMORY A 1..20   (user Sound Memory -- name lives in battery-backed RAM)
  148..167  MEMORY B 1..20   (user Sound Memory -- name lives in battery-backed RAM)
```

Banks 1..7 give a **variation of the same slot**, not a different instrument: slot 40 reads
`Electric Bass / Bright E.Bass / Fretless Bass / Funky E.Bass / Fusion E.Bass` for banks
0/1/2/3/4; slot 43 reads `Acoustic Bass / Mellow Ac.Bass`; slot 54 `Closed Fr.Horn /
Open Fr.Horn`; slot 100 `ClassicalStrings / SymphonicStrings`.  Run the script without
`--quiet` for all eight banks.

The two selector defaults land exactly where a Technics accompaniment engine would want them:
**21 = `Jazz Ac.Guitar` (GUITAR 11)** for the chord parts and **40 = `Electric Bass` (BASS 3)**
for the bass part.

## Why this is THE table and not merely *a* table

Three independent arguments, each stated so it could have come out negative.

**(1) The map's domain ends at 167, in all three program ROMs.**  Taking the entry at
index 200 as the filler value, the largest index below the drum-kit block whose entry differs
from the filler is

```
bank        0    1    2    3    4    5    6    7
last index 167  127  127  127  127  127  127  129     (identical in v7, v9 and v10)
```

so the union over all eight banks is **exactly 167**.  Bank 0 spends 0..127 on the fifteen
factory categories, 128..147 on `MEMORY A 1..20`, 148..167 on `MEMORY B 1..20`; 168..239 are a
single dummy entry repeated; 240..255 are the sixteen `DRUM KITS`.  The descriptor's `max=167`
is this table's domain, to the entry.  Had the descriptor's 167 been unrelated to this map, the
boundary would have fallen somewhere else.

**(2) The seven floppy `.LSW` files resolve semantically, far from chance.**  Tag `0x13` (the
accompaniment bass part) holds 175 records across the seven disks.  Resolved through the chain
above, **171 of 175 (97.7 %) fall in category BASS**; the other four are `Orchestral Tuba` (x3)
and `Bright Trombone` (x1) — bass-line instruments both.  Nothing else appears.  The null is
**4.8 %**: only 8 of the 168 options are BASS, so a wrong table would score around 5 %, not 98 %.
Tags `0x10 0x11 0x12` for contrast spread over PIANO / GUITAR / BRASS / SAX & REED /
ORGAN&ACCORDION / STRINGS & VOCAL / SYNTH, as accompaniment chord parts should.

**(3) The bank byte behaves like a variation selector on the same slot,** as shown above —
five different `+1` values on slot 40 give five different basses.  A spurious table would not
keep the instrument family constant while `+1` varies.

**What argument (2) does *not* prove.**  Re-scoring the same corpus with the selector value
deliberately shifted gives

```
index shift  -1     +1     +2     +8
BASS share  49.1%  97.7%  70.3%   0.0%
bank shift   +1     +2     +3
BASS share  70.3%  97.7%  97.7%
```

The eight BASS slots are contiguous (40..47) in every bank, so a one-slot misalignment still
scores 97.7 %.  Argument (2) therefore rules out **the wrong table** (`+8` collapses to zero),
not a possible off-by-one; what pins the alignment exactly is argument (1), where the map's
last meaningful index and the descriptor's `max` are *both* 167 — an off-by-one would make one
of them 166.  The script prints this sweep as check **C4** so the limitation stays visible.

## Negative results

* **Options 128..167 have no name in any ROM.**  They are the 40 user Sound Memories
  (`MEMORY A 1..20`, `MEMORY B 1..20`), stored in battery-backed RAM; the Sub CPU reaches them
  through `ToneDB_Find_PatchRecord` bank selectors `0x10` / `0x15`, which branch to
  RAM-resident areas (`ToneDB_Find_PatchRecord_UserA/_UserB`, 470-byte records) instead of the
  ROM tone database.  No search of the ROM can produce those names, and none of the seven
  floppy `.LSW` files uses a value >= 128 for any of the four melodic tags, so the corpus
  cannot supply them either.
* **The upper half of the panel numbering is not contiguous.**  168..239 is a 72-entry hole in
  the ROM map and 240..255 are the drum kits.  Any note that reads the drum-part tags
  (`0x15 0x16 0x19 0x17 0x18`) as "sound numbers 168..239" is reading a **type-4** descriptor
  triple as `(min, max, default)`.  That reading is safe for **type 3** — tag `0x78`'s sixteen
  `min=32 max=125 default=32` bytes are a printable-ASCII name field, which pins it — but it is
  *not* established for type 4, and tag `0x48` carries a type-3 `(0, 244, 96)` and a type-4
  `(158, 239, 96)` descriptor on the *same* byte, which the `(min, max, default)` reading cannot
  explain.  Treat the drum parts' `+0` range as **unknown**.
  **Resolved 2026-10-06 from the code** (`PanelTlv_Rule_ResetInsideRange`, see the corrected grammar
  in `README-lsw-panel-schema.md`): type 4 resets the field when it lies INSIDE lo..hi.  So the drum
  parts' `RULE_NOT_RANGE(0, 0xFF, 168, 239, 1)` accepts exactly 0..167 and 240..255 -- the melodic
  sounds and the drum kits, rejecting the 72-entry hole -- and tag `0x48`'s pair accepts 0..157 and
  240..244 on that byte, default 96.
* **Contradiction with an earlier note.**  `README-lsw-panel-schema.md` labels tag `0x14` "Bass"
  and tag `0x13` "Rhythm".  The corpus says tag `0x13` is the part whose sound is a bass in
  171 of 175 records, and tag `0x14` has no `+0` sound descriptor at all.  Whichever way the
  part names are eventually fixed, the `0x13 = Rhythm` label does not survive this measurement.
  (That file is not edited here only because this task was restricted to adding new files.)
