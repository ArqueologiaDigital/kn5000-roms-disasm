; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFB6E0A-0xFB828D  the three register-device drivers, 0x0010C000 and 0x00104000
; ==============================================================================
;
; 3,488 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
; `.include`s this file at the line the block started on, so the assembler
; sees the same token stream in the same order and the ROM is unchanged:
;
;     python3 scripts/analysis/assert_byte_identical.py    <- the bytes
;     python3 notes/prom_c_split.py --verify               <- the text
;
; ★ EVERY LINE BELOW THIS HEADER IS VERBATIM.  Nothing was reworded, and
;   --verify fails on a single changed character.
;
; WHY THIS IS ONE SUBJECT:
; Four adjacent banners, one subject: the FULL per-channel register map of
; 0x0010C000 and the round-7 table of what those registers MEAN; nine helper
; routines; the 0x00104000 driver with its 19-register per-channel map; and
; the second 0x0010C000 driver with Dev10C_ResetAllChannels, which fixes the
; channel count at 64 with a literal loop counter.
; ⚠ The names stay Dev10C_/Dev104_.  See the header of this file.
;
;
; ==============================================================================
; ★★ WAVE 17, 2026-09-03 -- THE 0x00104000 REGISTER MAP, THE PART RECORD THAT
;    FEEDS IT, AND THE SIGNAL FLOW FROM A NOTE-ON TO THESE WRITES
; ==============================================================================
; ADDED, not replacing.  Everything already in this file stands; this section
; puts the per-register map in one place and grades every line of it.
; Every number below is an assertion in
;     python3 notes/prom_c_dev104_regmap_checks.py --selftest      FAILURES: 0
; which reads original_ROMs/wsa1_prom_c.ic28 and no .s file.
;
; ------------------------------------------------------------------------------
; 0. WHERE THE LINE BETWEEN MEASUREMENT AND INFERENCE RUNS
; ------------------------------------------------------------------------------
; ⚠ DECLARED INFERENCE, held over from the driver work and NOT strengthened here:
;   that 0x00104000 is the ACOUSTIC MODELLING section.  What supports it is that
;   it is the only per-channel synthesis device CPU 2 commands that has no
;   counterpart in the PCM sibling, the KN5000, and that the MAME driver models
;   it as `l7a1429_device`.  NO WSA1R ROM NAMES ANY PART.  Nothing below is
;   evidence for that reading and nothing below depends on it.
;
; ★ MEASURED, and the only thing this section asserts: what the firmware WRITES.
;   Every row of the map is (register number, width, value expression), and the
;   value expression is decoded from the instructions that compute it.
;
; ⚠ AND THE STANDING LIMIT IS UNCHANGED.  "No executable payload crosses
;   0x00104000" is a claim about the BUS -- no opaque byte stream, no handshake,
;   no micro-DMA channel, a fixed destination set, `block*0x40 + channel`
;   numbering, values from a packed record.  A modelling engine with fixed
;   on-die microcode exposing only coefficients produces exactly this traffic.
;   ★ WAVE 17 ADDS ONE MEASUREMENT ON THAT POINT, not a verdict: the whole image
;   holds NINE `ld X??,0x00104000` literals -- eight in this block and one in
;   Dev10C_ResetAllChannels -- and NOT ONE OF THEM READS THE DEVICE.  The
;   companion 0x0010C000 has a documented read port at +0x04 and a dedicated
;   read accessor (Dev10C_ReadChanReg_0100, 0xFC7E57); 0x00104000 has neither.
;   A write-only parameter port is consistent with the coefficient reading and
;   is NOT proof of it.  Checker section 3.
;
; ------------------------------------------------------------------------------
; 1. THE ADDRESSING SCHEME
; ------------------------------------------------------------------------------
;   0x00104000 + 0x00   write   16-bit REGISTER NUMBER          (select)
;   0x00104000 + 0x02   write   that register's 16-bit VALUE    (data)
;   0x00104000 + 0x04   -- no located access.  ⚠ NOT "absent"; not found.
;
;   register number = block * 0x40 + channel
;
; PROVEN, by Dev104_WriteAllChanRegs's own instructions: eighteen `add BC/DE,K`
; immediates, every K a multiple of 0x40, running 0x0040..0x0480 with no gap,
; each followed by `ld BC/DE,(XIX + 2*K/0x40)` -- so the struct field is exactly
; twice the block index over all eighteen, and block 0 is the channel with no
; arithmetic at all.  Checker section 1 re-derives the walk and asserts the LAST
; pair (0x0480 <- 0x24) as well as the first.
;
; ★ THE EIGHT BLOCKS THE SMALL ACCESSORS TOUCH are 0x00C0, 0x0100, 0x0140,
;   0x0180, 0x01C0, 0x0200, 0x0240 and 0x0280 -- exactly 0x40 apart, first to
;   last, 0x0280 - 0x00C0 = 7 * 0x40 (checker section 2).  Plus block 0 on its
;   own, which Dev104_WriteChanReg0 isolates and which is written LAST by the
;   full writer and FIRST by the two multi-register accessors.
;   ⚠ 64 channels per block is NOT established for THIS device.  It is
;   established for 0x0010C000 (Dev10C_ResetAllChannels's literal loop counter);
;   here the only bound is that the blocks are 0x40 apart, which is where a
;   channel field of six bits would have to stop.
;
; ------------------------------------------------------------------------------
; 2. THE 19-REGISTER PER-CHANNEL MAP
; ------------------------------------------------------------------------------
; All nineteen are 16 BITS: every store into the staging struct and every store
; to the data port is a word store.  `chan` is the raw channel argument.
;
; Names used below, each a pointer this code dereferences and nothing more:
;   PART  = *(0x00E082)   187-byte part record,   0x005D23 + 187 * part
;   P     = *(0x00E084)    42-byte sub-record,    PART + 0x13 + 42 * n
;   Q     = *(P + 0x03)    the TONE record P points at (frame slot XIZ-4)
;   R     = *(0x00E086)    37-byte per-voice record, 0x00753E + 37 * m
;   key   = voice[+0x0C] & 0x7F   at 0x00E088 -- the 0..127 LinCoef index
;   Q5(T,d)  = (T[key'] * |d|) >> 5, with key' = 0x7F-key and the sign folded
;              when d < 0; 32 = 1.0.  Six sites, four tables (checker s.10).
;   SatAsym(x) = signed add, +overflow -> 0x7FFF, -overflow -> 0x0000
;
;  reg          word  value the firmware writes                        grade
;  -----------  ----  -------------------------------------------  ------------
;  chan+0x0000  0x00  (R[+0x07] << 8) | P[+0x07], then bit 7        PROVEN as
;                     CLEARED (0xFC51E6) when bits 6..4 are         arithmetic;
;                     ⚠ P[+0x07] is a WORD and R[+0x07] a BYTE, so
;                     the OR overlaps: P[+0x07]'s own high byte
;                     survives underneath R[+0x07].  Read off
;                     0xFC4DD1 (ld IY,(XBC+0x07)) and 0xFC4DE3
;                     (ld A,(XBC+0x07), extz, sll 8, or).
;                     non-zero.  Written LAST by the full writer,   MEANING
;                     FIRST by the two multi-register accessors.    UNIDENTIFIED
;                     Its own bits 6..4 gate register 0x0300.
;  chan+0x0040  0x02  SatAsym(P[+0x0A] + P[+0x12] + d1)             PROVEN /
;                       d1 = +(voice[+0x08] - voice[+0x0A])         UNIDENTIFIED
;                            if bit 7 of Q[+0x16]
;                          = -R[+0x0C]  otherwise
;  chan+0x0080  0x04  SatAsym(P[+0x0C] + P[+0x14] + d2), the same   PROVEN /
;                     rule with the selector bit 7 of Q[+0x20].     UNIDENTIFIED
;                     ⚠ P[+0x12] is exactly 8 bytes after P[+0x0A]
;                     and P[+0x14] 8 after P[+0x0C]: two copies of
;                     one (base, offset) pair.
;  chan+0x00C0  0x06  Curve_Position_Log2Period_251[clamp(R[+0x12]+R[+0x16]        PROVEN as
;                     +R[+0x21], 0..250)]                           arithmetic;
;                     + (0x4280 - R[+0x0E])  unless bit 7 of        LOG-DOMAIN
;                       (*(R[+0x01]))[+0x0E]                        WITH A
;                     - R[+0x0C]                                    KEY-FOLLOW
;                     then forced to 0x0000 or 0x7F00 on a          TERM: STRONG
;                     negative result (0xFC4A2B).  In Pack104_StageRegs_00C0_0100_0240.
;  chan+0x0100  0x08  Dev104_Reg0100_Const_251[the SAME index] -- and that    PROVEN: a
;                     table is 0x0100 in all 251 entries.           CONSTANT on
;                                                                   this firmware
;  chan+0x0140  0x0A  Curve_Fitting_Exp2Decay_256[i1] & 0xFFF8, or 0x0000   PROVEN /
;                     when bit 0 of (0x00E089) is set.              UNIDENTIFIED
;  chan+0x0180  0x0C  Curve_Fitting_Exp2Decay_256[i2] & 0xFFF8, same gate.  PROVEN /
;                                                                   UNIDENTIFIED
;       i1 = clampU8( 0xCF - g(v1) + (int8)(0x00E08C) ),  g(v) = v<48 ? v/2+24 : v
;       v1 = clamp( Q5(LinCoef_Fitting_KeyRamp_Q5_128, Q[+0x17]) + P[+0x16], 0 .. PART[+0x11] )
;       i2, v2: the same with Q[+0x22] and P[+0x18].
;  chan+0x01C0  0x0E  the TOP HALF of the 32-bit product           PROVEN /
;                       fold(word 16) * Curve_Fitting_Exp2Rise_128[         UNIDENTIFIED
;                         clamp(v1, 0..PART[+0x11]) ]
;                     ⚠ "top half" reads `srl 0x00,XIY` (0xFC5361)
;                     as a shift of 16, which is the TLCS-900
;                     encoding rule that a shift count of 0 means
;                     16 -- a CPU-manual fact, not something this
;                     image states.  If that rule were wrong the
;                     shift would be by 0 and the register would be
;                     the product's LOW half instead.  ⚠ THE
;                     TOOLCHAIN IS NOT A WITNESS EITHER: `llvm-mc
;                     --arch=tlcs900` encodes `srl xiy,0` as
;                     ed ef 00 and `srl xiy,16` as ed ef 10, i.e.
;                     it passes the immediate through and does not
;                     implement the rule.  The same
;                     instruction ends the 0x0200 and 0x0240 chains
;                     (0xFC54D7, 0xFC4ACC).
;                     fold(x) = (x & 0x8000) ? 0x8000-(x & 0x7FFF)
;                                            : x + 0x8000
;                     -- so register 0x01C0 is register 0x0400's
;                     word, sign-folded, SCALED by a rising
;                     exponential of the same v1 that scales 0x0140.
;  chan+0x0200  0x10  the same, with v2 and word 17 (reg 0x0440).   PROVEN /
;                                                                   UNIDENTIFIED
;  chan+0x0240  0x12  ( high16( fold(R[+0x1A]) * Curve_Fitting_Exp2Rise_128 PROVEN /
;                       [clamp(R[+0x14]+R[+0x18]+|R[+0x21]|/4,      UNIDENTIFIED
;                        0..0x7F)] ) & 0xFFF8 ) | 7.  In Pack104_StageRegs_00C0_0100_0240;
;                     R[+0x1A] is P[+0x26], i.e. word 18's value.
;  chan+0x0280  0x14  Curve_Exp2Gain_Percent_101[clamp(R[+0x10]+R[+0x23],  PROVEN /
;                     0..100)].  In Pack104_StageReg_0280.                     UNIDENTIFIED
;  chan+0x02C0  0x16  the literal 0xFF00.  ALWAYS -- it is the only PROVEN
;                     value any instruction ever puts in word 11
;                     (0xFC51AD; the Stage_B image patches the same
;                     0xFF00 at 0xFC577A).
;  chan+0x0300  0x18  b = Curve_Exp2Gain_U8_128[Q[+0x13]];             PROVEN /
;                     value = (b << 8) | b   -- one byte in BOTH    UNIDENTIFIED
;                     halves -- and 0x0000 when word 0's bits 6..4
;                     are clear.
;  chan+0x0340  0x1A  Curve_Muting_Cutoff_Q13_128[i3]                              PROVEN /
;  chan+0x0400  0x20  Curve_Muting_Cutoff_Q16_128[i3]   -- the SAME index          UNIDENTIFIED
;  chan+0x0380  0x1C  Curve_Muting_Cutoff_Q13_128[i4]                              PROVEN /
;  chan+0x0440  0x22  Curve_Muting_Cutoff_Q16_128[i4]   -- the SAME index          UNIDENTIFIED
;       i3 = clamp( ks(Q,0x19) + Q5(LinCoef_Muting_KeyRamp_Q5_128, Q[+0x18]) + P[+0x1A],
;                   Table_Muting_CutoffFloor_ByKeyZone_256[(0x00E08C)] .. PART[+0x12] )
;       i4 = clamp( ks(Q,0x25) + Q5(LinCoef_Muting_KeyRamp_Q5_128, Q[+0x23]) + P[+0x1C],
;                   the same bounds )
;  chan+0x03C0  0x1E  P[+0x24], copied straight through (0xFC56BA). PROVEN /
;                                                                   UNIDENTIFIED
;  chan+0x0480  0x24  P[+0x26], via R[+0x1A] (0xFC567F, 0xFC568F).  PROVEN /
;                                                                   UNIDENTIFIED
;
; ★ ks(Q, o) IS A KEY-SCALING STAGE, and it is worth naming because the shape is
;   unambiguous even though the quantity it scales is not:
;
;       if bit 7 of Q[+o]:  0
;       else:  note = voice[+0x08] >> 8                 the NOTE NUMBER
;              note = min(note, Q[+o+2]) then max(note, Q[+o+1])
;              result = ( Q[+o+3] * (note - Q[+o]) ) >> 5
;
;   -- a breakpoint, a low and a high bound, and a Q5 slope, over a value that is
;   a pitch word divided by 256.  The unit is §2 of
;   notes/FINDINGS-prom_c-dev10c-register-meanings.md: the pitch chain's word is
;   1/256 of a semitone, so `>> 8` is the note.  There are TWO of these,
;   o = 0x19 and o = 0x25.  Grade STRONG: the arithmetic is PROVEN and the unit
;   of its input rests on that note's derivation, not on this one.
;
; ★ AND 0x4280 -- note 66 with the half-step centre 0x80 -- IS A PIVOT ON BOTH
;   DEVICES.  The immediate occurs in exactly FOUR instruction operands in the
;   whole image: three on the 0x0010C000 pitch chain (0xFA80C7, 0xFA80D8,
;   0xFA80DF, the key-follow pivot §2 already documents) and ONE at 0xFC4A18,
;   inside Pack104_StageRegs_00C0_0100_0240, on the way to 0x00104000 register 0x00C0 + chan.  Two
;   devices, one reference note, and the census is exhaustive rather than a
;   sighting (checker section 9).
;
; ⚠ WHAT REMAINS UNIDENTIFIED, plainly: SEVENTEEN of the nineteen registers.
;   Only 0x0100 (a constant) and 0x02C0 (a constant) have a value this image
;   fixes; every other row above says how the number is BUILT and not what it
;   IS.  What would settle it is a reader -- and there is none: nothing in prom_c
;   reads this device back, and the sibling argument that named five 0x0010C000
;   registers is unavailable here because the KN5000 has no counterpart device.
;   The remaining routes are (a) the tone-editor UI, which must display these
;   parameters under names, and (b) the ROM's own localisation strings.
;
; ------------------------------------------------------------------------------
; 3. THE RECORDS, AS C STRUCTS
; ------------------------------------------------------------------------------
; ⚠⚠ TWO DIFFERENT RECORDS ARE CALLED "THE PART RECORD" IN THIS TREE, and mixing
; them is exactly the class of error that has already forced retractions here:
;
;   * the 300-byte record at RAM 0x001523, stride 0x012C, that the MIDI
;     controller handlers write -- notes/FINDINGS-prom_c-dev10c-register-
;     meanings.md §1 calls that one "the part record";
;   * the 187-byte record at RAM 0x005D23, stride 0xBB, that
;     Pack104_SetInputs_PartRecord selects.
;
; ONLY THE SECOND FEEDS 0x00104000.  Nothing in the packer reads 0x001523.
;
;   /* selected by Pack104_SetInputs_PartRecord(part) -> (0x00E082).
;      base 0x005D23, stride 0xBB = 187.  Only the fields this path reads are
;      listed; the rest of the 187 bytes is not touched by the packer. */
;   struct Part104 {                              /* consumer */
;     u8   present;              /* +0x00  early-out if zero    Pack104_SetInputs_PartRecord 0xFC4BED */
;     u8   _pad01[0x10];         /* +0x01  UNIDENTIFIED */
;     u8   depth_clamp_hi;       /* +0x11  upper clamp on v1/v2 Dev104_PackStagingStruct 0xFC4FB0, 0xFC506D,
;                                                               0xFC5330, 0xFC54A6 */
;     u8   index_clamp_hi;       /* +0x12  upper clamp on i3/i4 0xFC52C3, 0xFC5439 */
;     struct Part104Voice sub[4];/* +0x13  4 x 42 = 168 bytes; 187 - 19 = 168 exactly */
;     /* the two pointers below OVERLAP sub[] and are read by the selector, not
;        by the packer -- stated as measured, not reconciled: */
;     /* u32 obj16  @ +0x16      Pack104_SetInputs_PartRecord 0xFC4C03 */
;     /* u32 obj40  @ +0x40      Pack104_SetInputs_PartRecord 0xFC4C18 */
;   };
;
;   /* selected by Pack104_SetInputs_SubRecordPair(n) -> (0x00E084) =
;      (0x00E082) + 0x2A*n + 0x13.  42 bytes. */
;   struct Part104Voice {                         /* register it feeds */
;     u8   _pad00[3];            /* +0x00  UNIDENTIFIED */
;     u32  tone;                 /* +0x03  -> Q, the tone record        (all of them) */
;     u16  reg0000_word;         /* +0x07  OR'd under (R[+0x07] << 8)   0x0000 */
;     u16  base_A;               /* +0x0A  base   of chan+0x0040        0x0040 */
;     u16  base_B;               /* +0x0C  base   of chan+0x0080        0x0080 */
;     u8   _pad0E[4];            /* +0x0E  UNIDENTIFIED */
;     u16  offset_A;             /* +0x12  offset of chan+0x0040, 8 after base_A */
;     u16  offset_B;             /* +0x14  offset of chan+0x0080, 8 after base_B */
;     u16  depth_bias_A;         /* +0x16  added to v1                  0x0140, 0x01C0 */
;     u16  depth_bias_B;         /* +0x18  added to v2                  0x0180, 0x0200 */
;     u16  index_bias_A;         /* +0x1A  added to i3                  0x0340, 0x0400 */
;     u16  index_bias_B;         /* +0x1C  added to i4                  0x0380, 0x0440 */
;     u16  to_R23;               /* +0x1E  -> R[+0x23]                  0x0280 */
;     u16  to_R16;               /* +0x20  -> R[+0x16]                  0x00C0 */
;     u16  to_R18;               /* +0x22  -> R[+0x18]                  0x0240 */
;     u16  reg03C0;              /* +0x24  copied through               0x03C0 */
;     u16  reg0480;              /* +0x26  -> R[+0x1A], then through    0x0480, 0x0240 */
;     u8   rand_depth;           /* +0x28  * sine / 50 -> R[+0x21]      0x00C0, 0x0240 */
;     u8   mode;                 /* +0x29  tested with +0x28 to pick R[+0x1C] = 0/1/2 */
;   };
;
;   /* *(Part104Voice.tone).  Every field below is read through the frame slot
;      (XIZ-4) that Dev104_PackStagingStruct loads at 0xFC4DCB. */
;   struct Tone104 {                              /* register it feeds */
;     s8   lincoef_depth_R12;    /* +0x10  Q5 x LinCoef_Position_KeyRamp_Q5_128 -> R[+0x12]  0x00C0 */
;     u8   mode_bit7;            /* +0x12  bit 7 picks the R[+0x1C] arm */
;     u8   reg0300_index;        /* +0x13  -> Curve_Exp2Gain_U8_128         0x0300 */
;     u8   delta_sel_A;          /* +0x16  bit 7 picks d1's form         0x0040 */
;     s8   depth_v1;             /* +0x17  Q5 x LinCoef_Fitting_KeyRamp_Q5_128           0x0140, 0x01C0 */
;     s8   depth_i3;             /* +0x18  Q5 x LinCoef_Muting_KeyRamp_Q5_128           0x0340, 0x0400 */
;     u8   ks_break_i3;          /* +0x19  breakpoint; bit 7 DISABLES */
;     u8   ks_lo_i3;             /* +0x1A  lower note bound */
;     u8   ks_hi_i3;             /* +0x1B  upper note bound */
;     s8   ks_slope_i3;          /* +0x1C  Q5 slope */
;     u8   delta_sel_B;          /* +0x20  bit 7 picks d2's form         0x0080 */
;     s8   depth_v2;             /* +0x22  Q5 x LinCoef_Fitting_KeyRamp_Q5_128           0x0180, 0x0200 */
;     s8   depth_i4;             /* +0x23  Q5 x LinCoef_Muting_KeyRamp_Q5_128           0x0380, 0x0440 */
;     s8   depth_R10;            /* +0x24  Q5 x LinCoef_SubGain_KeyRamp_Q5_128 -> R[+0x10] 0x0280 */
;     u8   ks_break_i4;          /* +0x25  breakpoint; bit 7 DISABLES */
;     u8   ks_lo_i4;             /* +0x26 */
;     u8   ks_hi_i4;             /* +0x27 */
;     s8   ks_slope_i4;          /* +0x28  Q5 slope */
;   };
;
; ⚠ THE FIELD NAMES ABOVE ARE ROLE NAMES INSIDE THE ARITHMETIC, NOT PARAMETER
;   NAMES.  `depth_v1` says "this byte is the Q5 depth in the expression that
;   builds v1"; it does not say what v1 is a depth OF.  Where even that much is
;   not readable the field is `_padNN` and says UNIDENTIFIED.
;
; ★ THE PAIRING IS THE STRONGEST STRUCTURAL SIGNAL IN THE MAP.  Sixteen of the
;   nineteen registers fall into eight A/B pairs -- (0x0040, 0x0080),
;   (0x0140, 0x0180), (0x01C0, 0x0200), (0x0340, 0x0380), (0x0400, 0x0440) --
;   built by the same code twice over two field sets 2, 2, 8 and 0x0B bytes
;   apart.  [INFERENCE, stated as such] two parallel generators per channel is
;   what that shape is.  Nothing here decides what they generate.
;
; ------------------------------------------------------------------------------
; 4. THE STAGING STRUCT, AND WHO FILLS IT
; ------------------------------------------------------------------------------
;   struct Dev104Staging { u16 w[19]; };   /* RAM 0x00D7A2, 38 bytes */
;
; PROVEN that 0x00D7A2 is this device's struct: VoiceRegs_Stage_A pushes it to
; Dev104_PackStagingStruct at 0xFB0B5B and pushes the SAME literal to
; Dev104_WriteAllChanRegs ten bytes later at 0xFB0B65 (checker section 7).
;
; Nineteen words, TWENTY-FOUR stores:
;   * 20 in Dev104_PackStagingStruct itself, covering 15 offsets;
;   * 3 in Pack104_StageRegs_00C0_0100_0240, covering +0x06, +0x08 and +0x12;
;   * 1 in Pack104_StageReg_0280, covering +0x14.
; Checker section 4 asserts each one by its bytes and that the union is exactly
; {0x00, 0x02, ... 0x24}.
;
; ⚠⚠ A CORRECTION TO THE PRODUCER INDEX, and it changes three published counts.
;   `python3 notes/prom_c_dev10c_field_sources.py --dev104` lists nineteen
;   "struct" writes.  FOUR OF THEM ARE NOT STRUCT WRITES:
;
;       0xFC5522   ld (XWA+0x1c),0x01
;       0xFC55AF   ld (XWA+0x1d),H
;       0xFC55C5   ld (XWA+0x1e),H
;       0xFC5657   ld (XWA+0x14),BC
;
;   Every one of the four loads its base with `ld WA,(0x00e086)` -- the ABSOLUTE
;   global -- where every real struct store loads `ld X??,(XIZ+0x08)`, the
;   routine's only argument.  The four write the 37-byte record R, not the
;   struct.  Consequences, all asserted by checker section 5:
;     * the packer writes 15 struct offsets by its own instructions, not 16;
;     * `+0x1D` is NOT a struct offset at all, so the "one high-byte write" in
;       the round-6 correction above Dev104_PackStagingStruct does not exist;
;     * `+0x16` IS written by the packer (0xFC51AA, the literal 0xFF00), against
;       that same correction's list of four fields it "does not write".
;   ⚠ REPORTED, NOT EDITED: the sentences this contradicts are in
;   prom_c/field_accessors.s and notes/FINDINGS-prom_c-dev10c-producers.md §3,
;   which this lane does not own.
;
; ★ AND THE SCANNER MISSES FIVE REAL ONES, in the class its own docstring warns
;   about: 0xFC50D5 and 0xFC50DD (`ld (XBC+0x0a),0x0000`, `ld (XBC+0x0c),0x0000`),
;   0xFC51AD (0xFF00), 0xFC51EF (0x0000) and the read-modify-write 0xFC51E6
;   (`and (XBC),0xff7f`) -- all extended-prefix immediate forms.
;
; ------------------------------------------------------------------------------
; 5. SIGNAL FLOW: FROM A NOTE-ON TO THESE REGISTER WRITES
; ------------------------------------------------------------------------------
; What a "part record" is, in this image: the parameter set of one of the
; instrument's parts, 187 bytes, holding four 42-byte sub-records, each of which
; points at a tone record.  A note-on selects one part record and one sub-record,
; a voice allocation gives the note a CHANNEL, and the packer turns the pair
; (sub-record, voice state) into the nineteen words this device is then handed.
;
;   MidiNote_OnByPartMode / MidiNote_OnTail / MidiNote_OffTail
;     |
;     |-- Pack104_SetInputs_PartRecord(part)
;     |       (0x00E082) = 0x005D23 + 187*part          the PART for this note
;     |
;     |-- Pack104_SetInputs_SubRecordPair(n, m)
;     |       (0x00E084) = (0x00E082) + 42*n + 0x13     one of the four sub-records
;     |       (0x00E086) = 0x00753E + 37*m              the per-voice record R
;     |
;     `-- VoiceRegs_Stage_A(voice)            [_C and _D likewise; _B does NOT]
;           |
;           |-- Pack104_SetInputs_E088_E089_E08A(voice[+0x03], voice[+0x08],
;           |         voice[+0x0C], *(voice[+0x1F]))
;           |       (0x00E088) = voice[+0x0C] & 0x7F    the 0..127 LinCoef key
;           |       (0x00E08A) = voice[+0x08]           a pitch word
;           |       (0x00E089) = *(voice[+0x1F])[0]     bit 0 gates 0x0140/0x0180
;           |
;           |-- ~20 Voice_* helpers fill the OTHER device's staging struct at
;           |     0x00D75E; one of them, Voice_SelectKeyZone_Reg0040, also calls
;           |     Pack104_SetInputs_Rec0C_E08C, which is how the key-zone record
;           |     reaches THIS device (see below)
;           |
;           |-- Pack104_SetInputs_Rec0E_E08D(voice[+0x06], voice[+0x0A])
;           |       R[+0x0E]   = voice[+0x06]           the key-followed pitch
;           |       (0x00E08D) = voice[+0x0A]           pitch + zone offset
;           |
;           |-- Dev104_PackStagingStruct(&Dev104Staging)      0x00D7A2
;           |-- Dev104_WriteAllChanRegs(voice, &Dev104Staging) -> 0x00104000
;           |-- Dev10C_WriteAllChanRegs(voice, 0x00D75E)       -> 0x0010C000
;
; ★ ONE RECORD FIELD REACHES BOTH DEVICES, and it is checkable (section 8).  The
;   key-zone record's word +0x06 -- what the played note selects out of the zone
;   array -- is stored to RAM 0x005A4F, where the 0x0010C000 pitch chain adds it
;   (Voice_PitchAddZoneOffset_*), AND pushed to Pack104_SetInputs_Rec0C_E08C,
;   which puts it in R[+0x0C], which this device's packer SUBTRACTS from register
;   0x00C0 (0xFC4A29) and NEGATES as the delta for registers 0x0040 and 0x0080
;   (0xFC4E72).  The same zone byte +0x05 becomes (0x00E08C), the index into
;   Table_Muting_CutoffFloor_ByKeyZone_256 that lower-bounds i3 and i4.
;
; ★ AND ONE PATH SKIPS THE PACKER ENTIRELY.  VoiceRegs_Stage_B calls
;   Dev104_LoadStageBImage instead: 38 bytes = 19 words copied from
;   Dev104_StagingStruct_StageBImage (0xFE1315) with five fields patched.  On
;   that path the nineteen registers are a ROM IMAGE, not a computation, which
;   is the cheapest possible starting point for an emulator.  Checker s.12.
;   Unknown: what selects the Stage_B path.
;
; ------------------------------------------------------------------------------
; 7. ★★ WAVE 20, 2026-09-03 -- THE REGISTER BLOCKS NOW HAVE NAMES IN THE CODE
; ------------------------------------------------------------------------------
; ADDED, not replacing.  Every line of sections 0-6 above stands as written; this
; section adds the symbolic spelling of the same map and three corrections that
; wave 19 owes it.  ⚠ Where a line below CORRECTS an older one, the older line is
; left exactly as it was -- read them together, newest last.
;
; Wave 19 named twelve of the nineteen registers out of the tone editor's OWN
; vocabulary (notes/FINDINGS-l7a1429-parameter-names.md §4, all STRONG), fitted
; the MUTING pair as a one-pole cutoff (notes/FINDINGS-l7a1429-curve-tables.md)
; and put the engine together in notes/HLE-GUIDE-l7a1429.md.  Until now none of
; that was readable at the instruction that writes the register: every block was
; a bare `add BC,0x0140`.  The `.equ` block below gives each block a name and the
; write sites use it.
;
; ★ THE SUBSTITUTION IS PROVED BY THE BYTE GATE, and here that is a real proof
;   rather than a formality: these values are INSTRUCTION OPERANDS of
;   `add rr,imm16` (4 bytes) and `ld (rr),imm16`, so a symbol the assembler
;   resolved differently would change the ROM.  `make gate-all` stays 13/13.
;   Applied and re-checkable by `python3 notes/dev104_apply_regsyms.py --verify`.
;   ★ AND EVERY CLAIM SECTION 7 MAKES ON ITS OWN ACCOUNT -- the 64-channel bound,
;   the value of register 0x0800, and the census of 0x00104000 literals -- is
;   re-read from original_ROMs/wsa1_prom_c.ic28, no .s file, by
;   `python3 notes/dev104_apply_regsyms.py --checks`.  FAILURES: 0.
;
; ⚠ WHAT IS *NOT* CONVERTED, and why: nothing.  Every 0x00104000 register-block
;   literal in this file is a plain instruction operand.  Had one sat inside an
;   `extpfx*` raw-byte pseudo-instruction it could not take a symbol -- that form
;   is a byte list, not an expression -- and the applier refuses such a line by
;   construction (its --selftest requires the refusal).  Block 0x0000 has no
;   operand at all: its register number is the channel argument unmodified, so
;   DEV104_BLK_0000 is defined for the map's sake and used by no instruction.
;
; ★ NAMING RULE.  A block carries an editor name only where wave 19 graded that
;   name STRONG.  The other eight are named DEV104_BLK_<block>, by NUMBER, so
;   that a placeholder can never be mistaken for a finding -- including the three
;   that wave 19 could describe structurally but not name (0x0240, 0x03C0,
;   0x0480 are the third section's Rise-scaled coefficient and cutoff pair; the
;   editor's three unassigned captions DEPTH / FORMANT / INTERACTION GAIN are a
;   3! choice with no measurement behind it, graded WEAK, and are NOT adopted).
;
; ------------------------------------------------------------------------------
; 7.1 THE SYMBOL TABLE
; ------------------------------------------------------------------------------
;   symbol                      block   what it is                        grade
;   --------------------------  ------  --------------------------------  --------
;   DEV104_BASE                 --      the device: 16-bit register        PROVEN
;                                       NUMBER at +0x00, that register's
;                                       16-bit VALUE at +0x02
;   DEV104_BLK_0000             0x0000  a mode / enable word; its bits     UNIDENT-
;                                       6..4 gate block 0x0300            IFIED
;   DEV104_MAIN_TUNE            0x0040  MAIN RESONATOR KEY SHIFT + TUNE,  STRONG
;                                       1/256 semitone
;   DEV104_SUB_TUNE             0x0080  SUB RESONATOR KEY SHIFT + TUNE    STRONG
;   DEV104_POSITION             0x00C0  resonator POSITION, and its       STRONG
;                                       POSITION MOVEMENT page; a
;                                       log-domain PERIOD, 3072
;                                       counts/octave, pitch NEGATED
;   DEV104_BLK_0100             0x0100  POSITION's table-pair companion,  value
;                                       0x0100 in all 251 entries on      PROVEN /
;                                       this firmware; unit unknown       UNIDENT.
;   DEV104_MAIN_FITTING_DECAY   0x0140  MAIN FITTING, decay form          STRONG
;   DEV104_SUB_FITTING_DECAY    0x0180  SUB FITTING, decay form           STRONG
;   DEV104_MAIN_FITTING_RISE    0x01C0  MAIN FITTING, rise form -- block  STRONG
;                                       0x0400's word folded and scaled
;   DEV104_SUB_FITTING_RISE     0x0200  SUB FITTING, rise form            STRONG
;   DEV104_BLK_0240             0x0240  the THIRD section's Rise-scaled   structure
;                                       copy of block 0x0480              PROVEN /
;                                                                         name WEAK
;   DEV104_SUB_GAIN             0x0280  SUB GAIN, a 0..100 percent        STRONG
;                                       control with an explicit OFF
;   DEV104_BLK_02C0             0x02C0  the literal 0xFF00 on every path  UNIDENT.
;   DEV104_BLK_0300             0x0300  an 8-bit gain over a 0..127       WEAK
;                                       control, duplicated into BOTH
;                                       halves; candidate INTERACTION
;                                       GAIN, not adopted
;   DEV104_MAIN_MUTING_Q13      0x0340  MAIN MUTING, the Q13 companion    STRONG
;                                       coefficient -- COMPUTABLE from
;                                       DEV104_MAIN_MUTING_Q16
;   DEV104_SUB_MUTING_Q13       0x0380  SUB MUTING, Q13 companion         STRONG
;   DEV104_BLK_03C0             0x03C0  the THIRD section's Q13           structure
;                                       companion, index clamped 44..96   PROVEN /
;                                                                         name WEAK
;   DEV104_MAIN_MUTING_Q16      0x0400  MAIN MUTING, the Q16 BILINEAR     fit PROVEN
;                                       cutoff: index = MIDI note - 36,   / name
;                                       466 Hz .. 16.7 kHz                STRONG
;   DEV104_SUB_MUTING_Q16       0x0440  SUB MUTING, Q16 bilinear cutoff   PROVEN /
;                                                                         STRONG
;   DEV104_BLK_0480             0x0480  the THIRD section's Q16 cutoff,   fit PROVEN
;                                       831 Hz .. 16.7 kHz                / name WEAK
;   DEV104_BLK_0800             0x0800  a GLOBAL register -- no channel   UNIDENT-
;                                       field -- written once at power-on IFIED
;                                       with the word at ROM 0xFE1313,
;                                       which is 0x1100
;
; ⚠ MAIN vs SUB HAS ONE POINT OF FAILURE, and it is not this file's to settle:
;   the whole direction rests on block 0x0280 being SUB GAIN, the editor's one
;   parameter that belongs to one resonator and not the other.  If that were the
;   main resonator's level instead, every MAIN_/SUB_ symbol above swaps and
;   nothing else changes -- the pairing, the families and the arithmetic are all
;   direction-blind.  notes/FINDINGS-l7a1429-parameter-names.md §5b.
;
; ------------------------------------------------------------------------------
; 7.2 THREE CORRECTIONS TO THE SECTIONS ABOVE
; ------------------------------------------------------------------------------
; ⚠ (a) SECTION 1 SAYS "64 channels per block is NOT established for THIS device.
;   It is established for 0x0010C000".  THAT IS NOW WRONG, and this device
;   establishes it ITSELF.  ⚠ NOT via the `ldb D,0x40` loop at 0xFB8116 -- that one
;   reloads XIX with 0x0010C000 at 0xFB8102 first and is the OTHER device's.  The
;   power-on sweep's second loop (0xFB81DB, bound `cp HL,0x0040` at 0xFB8281)
;   calls Dev104_WriteChanReg0 with &0x00D8DB once per channel for HL = 0..0x3F,
;   and the first loop (0xFB8175, bound `cp HL,0x0040` at 0xFB81B9) calls
;   Dev104_WriteAllChanRegs the same way.  Both bounds are literal `0x0040`
;   operands in THIS image driving THIS device's own writers, so the count is
;   read off an instruction, not inferred from the 0x40 block stride.
;   ★ 64 CHANNELS, PROVEN.  Section 1's sentence stands as the state of knowledge
;   at wave 17 and is superseded here.
;
; ⚠ (b) SECTION 3 SAYS "Sixteen of the nineteen registers fall into eight A/B
;   pairs" and then lists FIVE.  Neither number is the measured grouping.  What a
;   correlation census over the factory tone records finds
;   (notes/HLE-GUIDE-l7a1429.md §2.2) is TWO PAIRS AND THREE TRIPLES:
;
;       pair    0x0040  0x0080                    MAIN / SUB tuning
;       pair    0x0140  0x0180                    MAIN / SUB FITTING, decay
;       triple  0x01C0  0x0200  0x0240            three Rise-scaled coefficients
;       triple  0x0340  0x0380  0x03C0            three Q13 companions
;       triple  0x0400  0x0440  0x0480            three Q16 cutoffs
;       alone   0x0000 0x00C0 0x0100 0x0280 0x02C0 0x0300
;
;   The triples are why there is a THIRD section at all: 0x0240, 0x03C0 and
;   0x0480 are not spare registers, they are section C's members of the same
;   three families the MAIN and SUB sections have.  The A/B-pair sentence above
;   stays as written; this is the grouping to read the map by.
;
; ⚠ (c) SECTION 3 CALLS `Q` A TONE RECORD AND GIVES A `struct Tone104`.  Q IS THE
;   43-BYTE WAVE-SELECT RECORD -- graded PROVEN in
;   notes/FINDINGS-l7a1429-parameter-names.md §1a, which owes this file the
;   correction: the complete census of Q reads on this path is `{+0x0B}` plus
;   `[+0x0D, +0x2A]`, the record's last byte is `+0x2A`, and on the drawbar arm Q
;   IS `Table_FE14A0`, six bytes before which the ASCII "WSA SOUND RAM S0" begins
;   -- so reading it at `+0x51` would land inside a bank-name string.
;   ★★ THE ARITHMETIC IN SECTION 2 IS UNTOUCHED.  Only the identity of the object
;   those offsets are read from changes -- and that is what made the naming
;   possible, because the 43-byte record has a byte-per-parameter editor behind
;   it (`Q[+0x0B]` = RESONATOR TYPE, and writing it reloads bytes 13..42, every
;   coefficient this device consumes, from a preset) and the tone record does not.
;   `struct Tone104` above should be read as `struct WaveSelRec`, its field names
;   still correct as ROLE names in the arithmetic.
;
; ------------------------------------------------------------------------------
; 7.3 THE FOUR sub_ ROUTINES IN THIS FILE -- THE REFUSAL STILL HOLDS
; ------------------------------------------------------------------------------
; sub_FB6F2C, sub_FB707E, sub_FB7521 and sub_FB762F were refused a name by round
; 12 on a calibrated rule (a register-block set names an ACCESSOR, and all four
; are larger than every member of the calibration set), and wave 17 left that
; refusal standing while adding a full write-by-write decode and a WEAK proposed
; name to each.
;
; ★ WAVE 19'S EVIDENCE DOES NOT REACH THEM, and the reason is structural rather
;   than a judgement call: ALL FOUR DRIVE 0x0010C000, NOT 0x00104000.  Their
;   register blocks are 0x0000 (the literal 0x8100), 0x0080, 0x0800, 0x0840 and
;   0x0900/0x0940/0x0980 -- of the OTHER device, whose block numbering happens to
;   overlap this one's and means something else.  Not one of the four contains a
;   `0x00104000` literal (this file holds nine, and section 0 enumerates them:
;   eight in the Dev104_ family and one in Dev10C_ResetAllChannels).  So naming
;   the L7A1429's registers cannot settle what any of the four is FOR, and the
;   four keep their address labels.  The census and the four spans are section 3
;   of `notes/dev104_apply_regsyms.py --checks`.
;   ⚠ What would settle them is unchanged: a reader of 0x0010C000 block 0x0080,
;   or the meaning of the 0x0000E21D array, or what a gate pulse with no
;   parameter change between its edges does.
;
; ------------------------------------------------------------------------------
; 7.4 THE DEFINITIONS
; ------------------------------------------------------------------------------
; ⚠ These are `.equ`, i.e. `.set`: they emit no bytes.  The file is `.include`d
;   into prom_c/wsa1_prom_c.s, so the names are visible to the whole image from
;   that point on; the DEV104_ prefix keeps them out of every other device's way.

	.equ DEV104_BASE, 0x00104000	; +0x00 register NUMBER, +0x02 its VALUE
	.equ DEV104_BLK_0000, 0x0000	; mode/enable word; bits 6..4 gate 0x0300
	.equ DEV104_MAIN_TUNE, 0x0040	; MAIN RESONATOR KEY SHIFT + TUNE
	.equ DEV104_SUB_TUNE, 0x0080	; SUB RESONATOR KEY SHIFT + TUNE
	.equ DEV104_POSITION, 0x00C0	; resonator POSITION, a log-domain period
	.equ DEV104_BLK_0100, 0x0100	; POSITION's table-pair companion
	.equ DEV104_MAIN_FITTING_DECAY, 0x0140	; MAIN FITTING, decay form
	.equ DEV104_SUB_FITTING_DECAY, 0x0180	; SUB FITTING, decay form
	.equ DEV104_MAIN_FITTING_RISE, 0x01C0	; MAIN FITTING, rise form
	.equ DEV104_SUB_FITTING_RISE, 0x0200	; SUB FITTING, rise form
	.equ DEV104_BLK_0240, 0x0240	; section C's Rise-scaled copy of 0x0480
	.equ DEV104_SUB_GAIN, 0x0280	; SUB GAIN, 0..100 percent with an OFF
	.equ DEV104_BLK_02C0, 0x02C0	; always the literal 0xFF00
	.equ DEV104_BLK_0300, 0x0300	; 8-bit gain, 0..127, in both halves
	.equ DEV104_MAIN_MUTING_Q13, 0x0340	; MAIN MUTING, Q13 companion
	.equ DEV104_SUB_MUTING_Q13, 0x0380	; SUB MUTING, Q13 companion
	.equ DEV104_BLK_03C0, 0x03C0	; section C's Q13 companion
	.equ DEV104_MAIN_MUTING_Q16, 0x0400	; MAIN MUTING, Q16 bilinear cutoff
	.equ DEV104_SUB_MUTING_Q16, 0x0440	; SUB MUTING, Q16 bilinear cutoff
	.equ DEV104_BLK_0480, 0x0480	; section C's Q16 cutoff
	.equ DEV104_BLK_0800, 0x0800	; GLOBAL, no channel field; power-on only
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFB6E0A-0xFB7344 -- the FULL per-channel register map of 0x0010C000, the
;                      block-0x0080 GATE and its RAM shadow
;                      9 routines, 1,339 bytes
; ==============================================================================
;
; The block above (0xFACE67, the first accessor bank) writes ONE register per
; routine.  This block contains the routine that writes a whole channel at once,
; and with it the register blocks the first bank never touches.
;
; ★★ TWENTY-TWO REGISTERS OF ONE CHANNEL, AND THE STRUCT IS THE REGISTER FILE IN
; ORDER.  Dev10C_WriteAllChanRegs (0xFB713A) is an unrolled run of select/write pairs.
; They were extracted by a symbolic walk, not by eye -- `notes/prom_c_tg_chanmap.py`
; follows the two frame slots that hold the +0 and +2 pointers, tracks what each
; 16-bit register holds, and preserves across a `calr` exactly the registers the
; CALLEE pushes and pops (read off the callee, not assumed):
;
;   $ python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --pairs
;   $ python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --groups
;   $ python3 notes/prom_c_tg_chanmap.py --selftest      # checks the LAST pair
;
;     register block   0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180
;     struct word           1      2      3      4      5      6   (offset 0x02..0x0C)
;
;     register block   0x0400 0x0440 0x0480 0x04C0 0x0500
;     struct word           7      8      9     10     11        (offset 0x0E..0x16)
;
;     register block   0x0800 0x0840 0x0880 0x08C0 0x0900 0x0940 0x0980 0x09C0 0x0A00 0x0A40
;     struct word          12     13     14     15     16     17     18     19     20     21
;                                                                    (offset 0x18..0x2A)
;
;     register block   0x0000  <- the LITERAL 0x8100, no struct field at all
;
; So the struct's words 1..21 map onto THREE CONSECUTIVE RUNS of register blocks:
; indices 1-6, 16-20 and 32-41.  `--groups` derives the runs mechanically and
; prints them; it reports four runs rather than three only because block 0x0080 is
; written through the bit-15 path below and is excluded from the plain
; (SELECT, DATA) pairing.  Put it back and the first run is 1..6 unbroken.
;
; ★ EIGHT REGISTER BLOCKS HERE ARE NEW.  notes/FINDINGS-prom_c-tone-generator.md
; §2 lists the 19 distinct constants its census could match:
;   0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180 0x01C0 0x0400 0x0440 0x0480 0x04C0
;   0x0540 0x0580 0x05C0 0x0600 0x0640 0x0800 0x0840 0x0880.
; This routine adds 0x0500, 0x08C0, 0x0900, 0x0940, 0x0980, 0x09C0, 0x0A00 and
; 0x0A40.  The highest register number the device is now known to take is
; therefore 0x0A40 + 0x3F = 0x0A7F, not 0x08BF.  That note's §10 asked for exactly
; this: "the five blocks the first bank never touches ... are the remaining
; 0x0010C000 surface".
;
; ★★ BLOCK 0x0080 IS A GATE WITH A RAM SHADOW, AND THE SHADOW IS AT 0x0000D85B.
; Three routines here do nothing but re-issue one channel's block-0x0080 value
; with bit 15 forced:
;     Dev10C_ChanMinus2_SetReg_0080_Bit15 (0xFB6E8C)  read shadow, SET bit 15, write
;     Dev10C_ChanMinus2_ClrReg_0080_Bit15 (0xFB6EDC)  read shadow, CLEAR bit 15, write
;     Dev10C_SetChanReg_0080_ClrBit15     (0xFB7038)  write struct+0x04 with bit 15
;                                                 clear, and store it to the
;                                                 shadow with bit 15 SET
; The shadow is a 16-bit array at work DRAM 0x0000D85B indexed by channel
; (`ld BC,0x0002 / mul XBC,HL / add XBC,0x0000D85B`), and Dev10C_WriteAllChanRegs
; writes it at 0xFB7317-0xFB7322 with the same value it last sent the device.
; This is the same "bit 15 written 1 then 0" shape §5 of the tone-generator note
; found in the second accessor bank, here with the value it pulses kept in RAM.
; ⚠ What the pulse DOES is still not established.
;
; ★ THE PER-CHANNEL RECORD AT 0x00003BCF CARRIES A TWO-BIT STATE, AND THIS BLOCK
; DRIVES IT.  Every routine here that touches a channel first computes
; `record = 0x00003BCF + 0x44 * ch + 1` -- the 0x44 = 68-byte stride the
; tone-generator note already established for that array -- and reads the 16-bit
; word there:
;     0xFB6E2E  `and WA,0x0600 / cp WA,0x0200`   bit 9 set AND bit 10 clear
;               -> load registers 0x0900/0x0940/0x0980 and SET bit 10 (0xFB6E3A)
;     0xFB6F49  `and WA,0x0400`                  bit 10 set
;               -> run the gate sequence and CLEAR bit 10 (0xFB6FB7, `and ...,0xFBFF`)
;     0xFB6EAA  `cp WA,0`                        the whole word non-zero
;               -> otherwise do nothing
; So bit 9 and bit 10 of that word are a request/loaded pair.  Stated as read; no
; name is given to either bit.
;
; ⚠ THE ±2 IS REAL AND IS NOT EXPLAINED.  0xFB6E0A operates on channel
; `(arg0 + 2) & 0x3F` and 0xFB6E8C/0xFB6EDC on `(arg0 - 2) & 0x3F` -- both the
; record lookup AND the register number use the adjusted value.  The masks make
; it wrap inside 0..0x3F.  Dev10C_WriteAllChanRegs calls the minus-2 helper twice and
; the plus-2 helper once and then writes ITS OWN channel's registers unadjusted,
; so one call touches three different channels.  Why is NOT ESTABLISHED.
;
; ⚠ AND A TRAP FOR THE XREF TOOL.  0xFB6F2C and 0xFB707E call 0xFB6E8C five times
; each through the idiom
;       lda XIX,0xFB6E8C ... push arg / lda XIY,<return> / push XIY / jp (XIX)
; -- a hand-built call.  `notes/prom_c_xrefs.py 0xFB6E8C` classifies the two
; `lda XIX,0xFB6E8C` sites (0xFB6F33, 0xFB7085) as "operand/data" because the byte
; in front of the literal is not 0x1D, and it cannot see the ten transfers at all.
; A caller census of this routine that trusted the tool's classification would be
; wrong by ten.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xFB6E0A 0x53B, restyled by
; notes/prom_c_listing_prep.py, and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xFB6E0A <file>`.

; --------------------------------------------------------------------------
; Dev10C_ChanPlus2_SetRegs_09xx -- for channel (arg0+2)&0x3F, and only if its record
;             word says "requested but not loaded", write register blocks 0x0900,
;             0x0940 and 0x0980 and mark it loaded.
;
; Called from: three calr sites -- the instructions at 0xFB7043
;          (Dev10C_SetChanReg_0080_ClrBit15), 0xFB7150 (Dev10C_WriteAllChanRegs) and
;          0xFB75A9 (not converted).  notes/prom_c_xrefs.py 0xFB6E0A.
; Inputs:  (XIZ+0x08) u16.  The channel it acts on is (arg0 + 2) & 0x3F -- `inc
;          2,HL / and HL,0x003F`, and every later use is of that value.
; Outputs: nothing at all unless bits 10..9 of the record word are exactly 0b01;
;          then registers ch+0x0900, ch+0x0940 and ch+0x0980 of 0x0010C000 all
;          receive the SAME value, and bit 10 of the record word is set.
; Evidence: the guard is `ld WA,DE / and WA,0x0600 / cp WA,0x0200 / jr NZ,exit`
;          on the 16-bit word at 0x00003BCF + 0x44*ch + 1; the mark is
;          `set 0x0a,WA` written back to the same place.  The value written to
;          all three registers is the low byte of the u16 at
;          0x0000E21D + 2*ch (`and DE,0x00FF`).
;          The register numbers come from notes/prom_c_tg_chanmap.py 0xFB6E0A 0x82
;          -- three writes, blocks 0x0900, 0x0940, 0x0980.
; Unknown:  what 0x0000E21D holds and who fills it; what the three registers do;
;          why the channel is offset by +2.
; --------------------------------------------------------------------------
Dev10C_ChanPlus2_SetRegs_09xx:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6E0A  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6E0E  push HL
	pushw	de                               ; FB6E0F  push DE
	push	xix                               ; FB6E10  push XIX
	ld	hl, (xiz+8)                         ; FB6E11  ld HL,(XIZ+0x08)
	inc	2, hl                              ; FB6E14  inc 2,HL
	and	hl, 63                             ; FB6E16  and HL,0x003f
	ldw	bc, 68                             ; FB6E1A  ld BC,0x0044
	mul	xbc, xhl                           ; FB6E1D  mul XBC,HL
	ld	ix, bc                              ; FB6E1F  ld IX,BC
	inc	1, bc                              ; FB6E21  inc 1,BC
	ld	ix, bc                              ; FB6E23  ld IX,BC
	extz	xbc                               ; FB6E25  extz XBC
	ld	de, (xbc+0x3BCF)                    ; FB6E27  ld DE,(XBC+0x3bcf)
	ld	wa, de                              ; FB6E2C  ld WA,DE
	and	wa, 0x600                          ; FB6E2E  and WA,0x0600
	cp	wa, 0x200                           ; FB6E32  cp WA,0x0200
	jr nz, Dev10C_ChanPlus2_SetRegs_09xx__FB6E86                       ; FB6E36  jr NZ,0xfb6e86
	ld	wa, de                              ; FB6E38  ld WA,DE
	set	10, wa                             ; FB6E3A  set 0x0a,WA
	ld	(xbc+0x3BCF), wa                    ; FB6E3D  ld (XBC+0x3bcf),WA
	ldw	bc, 2                              ; FB6E42  ld BC,0x0002
	mul	xbc, xhl                           ; FB6E45  mul XBC,HL
	add	xbc, 0xE21D                        ; FB6E47  add XBC,0x0000e21d
	ld	bc, (xbc)                           ; FB6E4D  ld BC,(XBC)
	ld	de, bc                              ; FB6E4F  ld DE,BC
	and	de, 0xFF                           ; FB6E51  and DE,0x00ff
	ld	ix, hl                              ; FB6E55  ld IX,HL
	add	ix, 0x900                          ; FB6E57  add IX,0x0900
	ld	xbc, 0x10C000                       ; FB6E5B  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6E60  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6E63  ld (XBC),IX
	ld	xix, (xiz-4)                        ; FB6E65  ld XIX,(XIZ+0xfc)
	inc	2, xix                             ; FB6E68  inc 2,XIX
	ld	(xix), de                           ; FB6E6A  ld (XIX),DE
	ld	bc, hl                              ; FB6E6C  ld BC,HL
	add	bc, 0x940                          ; FB6E6E  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB6E72  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB6E75  ld (XWA),BC
	ld	(xix), de                           ; FB6E77  ld (XIX),DE
	ld	bc, hl                              ; FB6E79  ld BC,HL
	add	bc, 0x980                          ; FB6E7B  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB6E7F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB6E82  ld (XWA),BC
	ld	(xix), de                           ; FB6E84  ld (XIX),DE
Dev10C_ChanPlus2_SetRegs_09xx__FB6E86:
	pop	xix                                ; FB6E86  pop XIX
	popw	de                                ; FB6E87  pop DE
	popw	hl                                ; FB6E88  pop HL
	unlk32 xiz                             ; FB6E89  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6E8B  ret

; --------------------------------------------------------------------------
; Dev10C_ChanMinus2_SetReg_0080_Bit15 -- re-issue channel (arg0-2)&0x3F's block-0x0080
;             value from its RAM shadow, with bit 15 SET.
;
; Called from: SEVEN calr sites (0xFB7148, 0xFB714C in Dev10C_WriteAllChanRegs;
;          0xFB7353/57/5B/5F/63 in the unconverted routine at 0xFB7345) AND TEN
;          more transfers the xref tool cannot see -- see the ⚠ about
;          `lda XIX,0xFB6E8C ... jp (XIX)` in the block comment above.
; Inputs:  (XIZ+0x08) u16; the channel used is (arg0 - 2) & 0x3F.
; Outputs: register ch+0x0080 of 0x0010C000 = shadow[ch] | 0x8000, but only if the
;          record word at 0x00003BCF + 0x44*ch + 1 is non-zero.
; Evidence: `dec 2,HL / and HL,0x003F` fixes the channel; `ld WA,(XBC+0x3bcf) /
;          cp WA,0 / jr Z,exit` is the guard; `ld BC,0x0002 / mul XBC,HL /
;          add XBC,0x0000D85B / ld BC,(XBC)` is the shadow read; `set 0x0f,DE` is
;          the bit; `add IX,0x0080` is the register block.
; Unknown:  what bit 15 means.  Its twin below is the same 80 bytes with `res`
;          in place of `set`.
; --------------------------------------------------------------------------
Dev10C_ChanMinus2_SetReg_0080_Bit15:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6E8C  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6E90  push HL
	pushw	de                               ; FB6E91  push DE
	pushw	ix                               ; FB6E92  push IX
	ld	hl, (xiz+8)                         ; FB6E93  ld HL,(XIZ+0x08)
	dec	2, hl                              ; FB6E96  dec 2,HL
	and	hl, 63                             ; FB6E98  and HL,0x003f
	ldw	bc, 68                             ; FB6E9C  ld BC,0x0044
	mul	xbc, xhl                           ; FB6E9F  mul XBC,HL
	inc	1, bc                              ; FB6EA1  inc 1,BC
	extz	xbc                               ; FB6EA3  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6EA5  ld WA,(XBC+0x3bcf)
	cps	wa, 0                              ; FB6EAA  cp WA,0
	jr z, Dev10C_ChanMinus2_SetReg_0080_Bit15__FB6ED6                        ; FB6EAC  jr Z,0xfb6ed6
	ldw	bc, 2                              ; FB6EAE  ld BC,0x0002
	mul	xbc, xhl                           ; FB6EB1  mul XBC,HL
	add	xbc, 0xD85B                        ; FB6EB3  add XBC,0x0000d85b
	ld	bc, (xbc)                           ; FB6EB9  ld BC,(XBC)
	ld	de, bc                              ; FB6EBB  ld DE,BC
	set	15, de                             ; FB6EBD  set 0x0f,DE
	ld	ix, hl                              ; FB6EC0  ld IX,HL
	add	ix, 0x80                           ; FB6EC2  add IX,0x0080
	ld	xbc, 0x10C000                       ; FB6EC6  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6ECB  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6ECE  ld (XBC),IX
	ld	xbc, (xiz-4)                        ; FB6ED0  ld XBC,(XIZ+0xfc)
	ld	(xbc+2), de                         ; FB6ED3  ld (XBC+0x02),DE
Dev10C_ChanMinus2_SetReg_0080_Bit15__FB6ED6:
	popw	ix                                ; FB6ED6  pop IX
	popw	de                                ; FB6ED7  pop DE
	popw	hl                                ; FB6ED8  pop HL
	unlk32 xiz                             ; FB6ED9  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6EDB  ret

; --------------------------------------------------------------------------
; Dev10C_ChanMinus2_ClrReg_0080_Bit15 -- the twin of the routine above with bit 15
;             CLEARED instead of set.
;
; Called from: four calr sites -- the instructions at 0xFB6FCC, 0xFB70CB,
;          0xFB729D and 0xFB73BD.
; Inputs / Outputs: as above, except the value written is shadow[ch] & 0x7FFF.
; Evidence: the two routines are 80 bytes each and differ in ONE instruction --
;          0xFB6EBD `da 31 0f` (set 0x0f,DE) against 0xFB6F0D `da 30 0f`
;          (res 0x0f,DE).  Checked byte by byte over the whole 80, not sampled:
;          the only differing offset is +0x32, where 0x31 (`set`) becomes 0x30
;          (`res`) -- one bit of one byte in eighty.
; Unknown:  as above.
; --------------------------------------------------------------------------
Dev10C_ChanMinus2_ClrReg_0080_Bit15:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6EDC  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6EE0  push HL
	pushw	de                               ; FB6EE1  push DE
	pushw	ix                               ; FB6EE2  push IX
	ld	hl, (xiz+8)                         ; FB6EE3  ld HL,(XIZ+0x08)
	dec	2, hl                              ; FB6EE6  dec 2,HL
	and	hl, 63                             ; FB6EE8  and HL,0x003f
	ldw	bc, 68                             ; FB6EEC  ld BC,0x0044
	mul	xbc, xhl                           ; FB6EEF  mul XBC,HL
	inc	1, bc                              ; FB6EF1  inc 1,BC
	extz	xbc                               ; FB6EF3  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6EF5  ld WA,(XBC+0x3bcf)
	cps	wa, 0                              ; FB6EFA  cp WA,0
	jr z, Dev10C_ChanMinus2_ClrReg_0080_Bit15__FB6F26                        ; FB6EFC  jr Z,0xfb6f26
	ldw	bc, 2                              ; FB6EFE  ld BC,0x0002
	mul	xbc, xhl                           ; FB6F01  mul XBC,HL
	add	xbc, 0xD85B                        ; FB6F03  add XBC,0x0000d85b
	ld	bc, (xbc)                           ; FB6F09  ld BC,(XBC)
	ld	de, bc                              ; FB6F0B  ld DE,BC
	res	15, de                             ; FB6F0D  res 0x0f,DE
	ld	ix, hl                              ; FB6F10  ld IX,HL
	add	ix, 0x80                           ; FB6F12  add IX,0x0080
	ld	xbc, 0x10C000                       ; FB6F16  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6F1B  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6F1E  ld (XBC),IX
	ld	xbc, (xiz-4)                        ; FB6F20  ld XBC,(XIZ+0xfc)
	ld	(xbc+2), de                         ; FB6F23  ld (XBC+0x02),DE
Dev10C_ChanMinus2_ClrReg_0080_Bit15__FB6F26:
	popw	ix                                ; FB6F26  pop IX
	popw	de                                ; FB6F27  pop DE
	popw	hl                                ; FB6F28  pop HL
	unlk32 xiz                             ; FB6F29  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6F2B  ret

; --------------------------------------------------------------------------
; sub_FB6F2C -- NOT NAMED.  For one channel: five bit-15-SET pulses of block
;             0x0080, then one bit-15-CLEAR, then blocks 0x0900/0x0940/0x0980.
;
; Called from: 0xFACAAA (`call 0xFB6F2C`).  One site.
; Inputs:  (XIZ+0x08) u16, used UNADJUSTED as the channel here (the ±2 lives in
;          the helpers it calls).
; Outputs: see below.  Nothing at all unless bit 10 of the record word at
;          0x00003BCF + 0x44*arg0 + 1 is set.
; Evidence: read in order off the instructions --
;            1. guard `and WA,0x0400 / jrl Z,exit`;
;            2. `sh = shadow[(arg0-2)&0x3F]`; if bit 15 of it is SET, clear it,
;               write it back to the shadow and RETURN -- the sequence below is
;               skipped entirely (0xFB6F6D `jr Z` / 0xFB6F7E `jrl T,exit`);
;            3. otherwise call Dev10C_ChanMinus2_SetReg_0080_Bit15 FIVE times with the
;               same argument, through the `push arg / push <return> / jp (XIX)`
;               idiom;
;            4. clear bit 10 of the record word (`and (XBC+0x3bcf),0xFBFF`);
;            5. call Dev10C_ChanMinus2_ClrReg_0080_Bit15 once;
;            6. write registers arg0+0x0900, +0x0940 and +0x0980 with the u16 at
;               0x0000E21D + 2*arg0.
;          The five-then-one shape and the register list come from
;          `python3 notes/prom_c_tg_chanmap.py 0xFB6F2C 0xEA --pairs`.
;          The stack accounting agrees: six 2-byte argument pushes are dropped by
;          `inc 8,xsp` + `inc 4,xsp` = 12 at the end.
; Unknown:  ⚠ WHY FIVE.  The five calls are identical and the shadow does not
;          change between them, so the device receives the same word five times.
;          A hold time is the obvious reading and nothing here supports it.
;          Also unknown: what this routine is FOR.  It is left `sub_` rather than
;          given a plausible name.
; ★ WAVE 17, 2026-09-03 -- WHY THIS LABEL IS STILL AN ADDRESS.
; Round 12 refused to name this routine and the five others in its bucket S3, on a
; CALIBRATED rule: `notes/prom_c_finish_round12.py --regblocks` reproduces the
; register-block half of 36 already-named accessors and then declines to apply it
; here, because "a register-block set names an ACCESSOR" and every one of the six is
; larger than every member of the calibration set.  That refusal stands.
; What HAS changed since is that rounds 7 and 9 named the registers this routine
; touches, so its BEHAVIOUR can now be stated in named terms even though its label
; cannot: block 0x0080 is the OUTPUT LEVEL with bit 15 as the gate the firmware
; pulses 1-then-0 around a parameter update, and blocks 0x0900/0x0940/0x0980 are
; three of the ten byte-pair registers.  In those terms this routine, for a channel
; the record word says is "loaded", re-issues the channel's last output-level word
; with the GATE HIGH five times, drops the loaded bit, re-issues it with the GATE
; LOW once, and then writes the three 0x09xx registers from 0x0000E21D + 2*chan.
; PROPOSED NAME, graded WEAK and NOT APPLIED: `Dev10C_ChanRegateAndSet_09xx`.
; ⚠ WEAK because nothing establishes what a gate pulse with no parameter change
; between the edges does, and "re-gate" is a description of the write pattern, not
; of an effect.  What would settle it: a reader of block 0x0080, or the meaning of
; the 0x0000E21D array.  Adopting it would also need the `Calls:` citations in
; prom_c/wsa1_prom_c.s and prom_c/midi/midi_controllers.s updated, and
; notes/prom_c_finish_round12.py's `regblocks("sub_FB762F")` check re-pointed.
; ★ WAVE 20, 2026-09-03 -- THE REFUSAL STILL HOLDS, and not as a judgement
; call: this routine drives 0x0010C000, NOT 0x00104000.  Its register blocks belong
; to the OTHER device, whose numbering overlaps and means something else, and it
; contains no 0x00104000 literal at all.  So naming the L7A1429's registers cannot
; settle what it is FOR, and the label stays an address.  File header section 7.3.
; --------------------------------------------------------------------------
sub_FB6F2C:
	link32 0xEE, 0x0C, 0xF2, 0xFF          ; FB6F2C  link XIZ,0xfff2   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6F30  push HL
	pushw	de                               ; FB6F31  push DE
	push	xix                               ; FB6F32  push XIX
	lda	xix, (0xFB6E8C:24)                 ; FB6F33  lda XIX,0xfb6e8c
	ld	de, (xiz+8)                         ; FB6F38  ld DE,(XIZ+0x08)
	ldw	bc, 68                             ; FB6F3B  ld BC,0x0044
	mul	xbc, xde                           ; FB6F3E  mul XBC,DE
	inc	1, bc                              ; FB6F40  inc 1,BC
	extz	xbc                               ; FB6F42  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6F44  ld WA,(XBC+0x3bcf)
	and	wa, 0x400                          ; FB6F49  and WA,0x0400
	jrl z, sub_FB6F2C__FB7010                       ; FB6F4D  jrl Z,0xfb7010
	ld	c, e                                ; FB6F50  ld C,E
	dec	2, c                               ; FB6F52  dec 2,C
	and	c, 63                              ; FB6F54  and C,0x3f
	mul	c, 2                               ; FB6F57  mul C,0x02
	extz	xbc                               ; FB6F5A  extz XBC
	ld	(xiz-4), xbc                        ; FB6F5C  ld (XIZ+0xfc),XBC
	add	xbc, 0xD85B                        ; FB6F5F  add XBC,0x0000d85b
	ld	hl, (xbc)                           ; FB6F65  ld HL,(XBC)
	ld	bc, hl                              ; FB6F67  ld BC,HL
	and	bc, 0x8000                         ; FB6F69  and BC,0x8000
	jr z, sub_FB6F2C__FB6F81                        ; FB6F6D  jr Z,0xfb6f81
	ld	bc, hl                              ; FB6F6F  ld BC,HL
	res	15, bc                             ; FB6F71  res 0x0f,BC
	lda	xwa, (0xD85B:24)                   ; FB6F74  lda XWA,0x00d85b
	extpfx3 0xAE, 0xFC, 0x80               ; FB6F79  add XWA,(XIZ+0xfc)   [llvm-mc cannot encode this]
	ld	(xwa), bc                           ; FB6F7C  ld (XWA),BC
	jrl sub_FB6F2C__FB7010                          ; FB6F7E  jrl T,0xfb7010
sub_FB6F2C__FB6F81:
	pushw	de                               ; FB6F81  push DE
	lda	xiy, (0xFB6F8A:24)                 ; FB6F82  lda XIY,0xfb6f8a
	push	xiy                               ; FB6F87  push XIY
	jp	(xix)                               ; FB6F88  jp T,XIX
	pushw	de                               ; FB6F8A  push DE
	lda	xiy, (0xFB6F93:24)                 ; FB6F8B  lda XIY,0xfb6f93
	push	xiy                               ; FB6F90  push XIY
	jp	(xix)                               ; FB6F91  jp T,XIX
	pushw	de                               ; FB6F93  push DE
	lda	xiy, (0xFB6F9C:24)                 ; FB6F94  lda XIY,0xfb6f9c
	push	xiy                               ; FB6F99  push XIY
	jp	(xix)                               ; FB6F9A  jp T,XIX
	pushw	de                               ; FB6F9C  push DE
	lda	xiy, (0xFB6FA5:24)                 ; FB6F9D  lda XIY,0xfb6fa5
	push	xiy                               ; FB6FA2  push XIY
	jp	(xix)                               ; FB6FA3  jp T,XIX
	pushw	de                               ; FB6FA5  push DE
	lda	xiy, (0xFB6FAE:24)                 ; FB6FA6  lda XIY,0xfb6fae
	push	xiy                               ; FB6FAB  push XIY
	jp	(xix)                               ; FB6FAC  jp T,XIX
	ldw	bc, 68                             ; FB6FAE  ld BC,0x0044
	mul	xbc, xde                           ; FB6FB1  mul XBC,DE
	inc	1, bc                              ; FB6FB3  inc 1,BC
	extz	xbc                               ; FB6FB5  extz XBC
	extpfx7 0xD3, 0xE5, 0xCF, 0x3B, 0x3C, 0xFF, 0xFB ; FB6FB7  and (XBC+0x3bcf),0xfbff   [llvm-mc cannot encode this]
	ldw	bc, 2                              ; FB6FBE  ld BC,0x0002
	mul	xbc, xde                           ; FB6FC1  mul XBC,DE
	add	xbc, 0xE21D                        ; FB6FC3  add XBC,0x0000e21d
	ld	hl, (xbc)                           ; FB6FC9  ld HL,(XBC)
	pushw	de                               ; FB6FCB  push DE
	calr (0xFB6EDC - 0xFB6FCF)             ; FB6FCC  calr 0xfb6edc
	ld	bc, de                              ; FB6FCF  ld BC,DE
	add	bc, 0x900                          ; FB6FD1  add BC,0x0900
	ld	(xiz-6), bc                         ; FB6FD5  ld (XIZ+0xfa),BC
	ld	xwa, 0x10C000                       ; FB6FD8  ld XWA,0x0010c000
	ld	(xiz-10), xwa                       ; FB6FDD  ld (XIZ+0xf6),XWA
	ld	(xwa), bc                           ; FB6FE0  ld (XWA),BC
	ld	xbc, (xiz-10)                       ; FB6FE2  ld XBC,(XIZ+0xf6)
	inc	2, xbc                             ; FB6FE5  inc 2,XBC
	ld	(xiz-14), xbc                       ; FB6FE7  ld (XIZ+0xf2),XBC
	ld	(xbc), hl                           ; FB6FEA  ld (XBC),HL
	ld	bc, de                              ; FB6FEC  ld BC,DE
	add	bc, 0x940                          ; FB6FEE  add BC,0x0940
	ld	xwa, (xiz-10)                       ; FB6FF2  ld XWA,(XIZ+0xf6)
	ld	(xwa), bc                           ; FB6FF5  ld (XWA),BC
	ld	xbc, (xiz-14)                       ; FB6FF7  ld XBC,(XIZ+0xf2)
	ld	(xbc), hl                           ; FB6FFA  ld (XBC),HL
	ld	bc, de                              ; FB6FFC  ld BC,DE
	add	bc, 0x980                          ; FB6FFE  add BC,0x0980
	ld	xwa, (xiz-10)                       ; FB7002  ld XWA,(XIZ+0xf6)
	ld	(xwa), bc                           ; FB7005  ld (XWA),BC
	ld	xbc, (xiz-14)                       ; FB7007  ld XBC,(XIZ+0xf2)
	ld	(xbc), hl                           ; FB700A  ld (XBC),HL
	inc	8, xsp                             ; FB700C  inc 0,XSP
	inc	4, xsp                             ; FB700E  inc 4,XSP
sub_FB6F2C__FB7010:
	pop	xix                                ; FB7010  pop XIX
	popw	de                                ; FB7011  pop DE
	popw	hl                                ; FB7012  pop HL
	unlk32 xiz                             ; FB7013  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7015  ret

; --------------------------------------------------------------------------
; Dev10C_SetChanPitch_Reg0400_c -- register (chan + 0x0400) = struct->0x0E.
;
; Called from: NOT FOUND (notes/prom_c_xrefs.py 0xFB7016: no literal, no calr).
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Evidence: ★ BYTE-IDENTICAL, all 34 bytes, to Dev10C_SetChanPitch_Reg0400 at 0xFACE67 in
;          the first accessor bank above.  `python3 notes/prom_c_tg_regmap.py
;          --dups` prints the pair (0xFACE67 -> 0xFB7016).  The name is that
;          routine's, with `_c` to keep the label unique; `_b` is the suffix this
;          file already uses for the copies in the bank at 0xFB7B63 onward.
; Unknown:  as for the original -- what register block 0x0400 does.
; --------------------------------------------------------------------------
Dev10C_SetChanPitch_Reg0400_c:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB7016  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FB701A  push HL
	push	xix                               ; FB701B  push XIX
	ld	hl, (xiz+8)                         ; FB701C  ld HL,(XIZ+0x08)
	add	hl, 0x400                          ; FB701F  add HL,0x0400
	ld	xix, 0x10C000                       ; FB7023  ld XIX,0x0010c000
	ld	(xix), hl                           ; FB7028  ld (XIX),HL
	ld	xbc, (xiz+10)                       ; FB702A  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+14)                        ; FB702D  ld WA,(XBC+0x0e)
	ld	(xix+2), wa                         ; FB7030  ld (XIX+0x02),WA
	pop	xix                                ; FB7033  pop XIX
	popw	hl                                ; FB7034  pop HL
	unlk32 xiz                             ; FB7035  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7037  ret

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0080_ClrBit15 -- write block 0x0080 with bit 15 CLEAR and leave the
;             shadow holding the same value with bit 15 SET.
;
; Called from: 0xFADE1F (`call 0xFB7038`).  One site.
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Outputs: Dev10C_ChanPlus2_SetRegs_09xx(chan) first; then register chan+0x0080 =
;          struct->0x04 with bit 15 cleared; then
;          shadow[chan] = struct->0x04 with bit 15 SET.
; Evidence: `res 0x0f,WA` before the port write at 0xFB705C and `set 0x0f,DE`
;          before the shadow write at 0xFB7075 -- the two polarities are in the
;          SAME routine, four instructions apart, so this is not a transcription
;          slip.  The shadow address is `ld WA,0x0002 / mul XWA,HL /
;          add XWA,0x0000D85B`.
; Unknown:  why the shadow keeps the opposite polarity from what was just sent.
;          Dev10C_WriteAllChanRegs stores the shadow with bit 15 CLEAR instead.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0080_ClrBit15:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB7038  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FB703C  push HL
	pushw	de                               ; FB703D  push DE
	push	xix                               ; FB703E  push XIX
	ld	hl, (xiz+8)                         ; FB703F  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB7042  push HL
	calr (0xFB6E0A - 0xFB7046)             ; FB7043  calr 0xfb6e0a
	ld	de, hl                              ; FB7046  ld DE,HL
	add	de, 0x80                           ; FB7048  add DE,0x0080
	ld	xix, 0x10C000                       ; FB704C  ld XIX,0x0010c000
	ld	(xix), de                           ; FB7051  ld (XIX),DE
	ld	xbc, (xiz+10)                       ; FB7053  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+4)                         ; FB7056  ld WA,(XBC+0x04)
	res	15, wa                             ; FB7059  res 0x0f,WA
	ld	(xix+2), wa                         ; FB705C  ld (XIX+0x02),WA
	ld	xbc, (xiz+10)                       ; FB705F  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+4)                         ; FB7062  ld WA,(XBC+0x04)
	ld	de, wa                              ; FB7065  ld DE,WA
	set	15, de                             ; FB7067  set 0x0f,DE
	ldw	wa, 2                              ; FB706A  ld WA,0x0002
	mul	xwa, xhl                           ; FB706D  mul XWA,HL
	add	xwa, 0xD85B                        ; FB706F  add XWA,0x0000d85b
	ld	(xwa), de                           ; FB7075  ld (XWA),DE
	popw	bc                                ; FB7077  pop BC
	pop	xix                                ; FB7078  pop XIX
	popw	de                                ; FB7079  pop DE
	popw	hl                                ; FB707A  pop HL
	unlk32 xiz                             ; FB707B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB707D  ret

; --------------------------------------------------------------------------
; sub_FB707E -- NOT NAMED.  sub_FB6F2C's shape, but taking a struct: five bit-15
;             pulses, clear the record bit, then blocks 0x0500 and 0x09xx from the
;             struct.
;
; Called from: 0xFADD78 (`call 0xFB707E`).  One site.
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Outputs: five calls to Dev10C_ChanMinus2_SetReg_0080_Bit15(chan) through the
;          `jp (XIX)` idiom; bit 10 of the record word cleared; one call to
;          Dev10C_ChanMinus2_ClrReg_0080_Bit15(chan); then
;              register chan+0x0500 = struct->0x16
;              register chan+0x0900 = struct->0x20
;              register chan+0x0940 = struct->0x22
;              register chan+0x0980 = struct->0x24
; Evidence: `python3 notes/prom_c_tg_chanmap.py 0xFB707E 0xBC --pairs` lists the
;          four register writes and the call; the five hand-built calls are the
;          five `lda XIY,<next> / push XIY / jp (XIX)` groups at 0xFB708E-0xFB70B8
;          with XIX loaded from 0xFB7085.  Unlike sub_FB6F2C there is NO guard on
;          the record word at entry -- the five pulses always run.
;          The four (block, field) pairs are the same four
;          Dev10C_WriteAllChanRegs uses for words 11, 16, 17 and 18.
; Unknown:  as sub_FB6F2C; and why this one has no entry guard.
; ★ WAVE 17, 2026-09-03 -- as sub_FB6F2C above, and refused for the same reason.
; In the named terms of rounds 7 and 9: five gate-high re-issues of the output-level
; word, the loaded bit dropped, one gate-low re-issue, then FOUR registers written
; from the caller's staging struct -- 0x0500 from word 11 and 0x0900/0x0940/0x0980
; from words 16/17/18, which are exactly the four Dev10C_WriteAllChanRegs uses for
; those words.  So this is the struct-driven twin of sub_FB6F2C, without the entry
; guard.  PROPOSED NAME, graded WEAK and NOT APPLIED:
; `Dev10C_ChanRegateAndSet_0500_09xx_FromStruct`.  Same caveat, same blocker.
; ★ WAVE 20, 2026-09-03 -- THE REFUSAL STILL HOLDS, and not as a judgement
; call: this routine drives 0x0010C000, NOT 0x00104000.  Its register blocks belong
; to the OTHER device, whose numbering overlaps and means something else, and it
; contains no 0x00104000 literal at all.  So naming the L7A1429's registers cannot
; settle what it is FOR, and the label stays an address.  File header section 7.3.
; --------------------------------------------------------------------------
sub_FB707E:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FB707E  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FB7082  push HL
	pushw	de                               ; FB7083  push DE
	push	xix                               ; FB7084  push XIX
	lda	xix, (0xFB6E8C:24)                 ; FB7085  lda XIX,0xfb6e8c
	ld	hl, (xiz+8)                         ; FB708A  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB708D  push HL
	lda	xiy, (0xFB7096:24)                 ; FB708E  lda XIY,0xfb7096
	push	xiy                               ; FB7093  push XIY
	jp	(xix)                               ; FB7094  jp T,XIX
	pushw	hl                               ; FB7096  push HL
	lda	xiy, (0xFB709F:24)                 ; FB7097  lda XIY,0xfb709f
	push	xiy                               ; FB709C  push XIY
	jp	(xix)                               ; FB709D  jp T,XIX
	pushw	hl                               ; FB709F  push HL
	lda	xiy, (0xFB70A8:24)                 ; FB70A0  lda XIY,0xfb70a8
	push	xiy                               ; FB70A5  push XIY
	jp	(xix)                               ; FB70A6  jp T,XIX
	pushw	hl                               ; FB70A8  push HL
	lda	xiy, (0xFB70B1:24)                 ; FB70A9  lda XIY,0xfb70b1
	push	xiy                               ; FB70AE  push XIY
	jp	(xix)                               ; FB70AF  jp T,XIX
	pushw	hl                               ; FB70B1  push HL
	lda	xiy, (0xFB70BA:24)                 ; FB70B2  lda XIY,0xfb70ba
	push	xiy                               ; FB70B7  push XIY
	jp	(xix)                               ; FB70B8  jp T,XIX
	ldw	bc, 68                             ; FB70BA  ld BC,0x0044
	mul	xbc, xhl                           ; FB70BD  mul XBC,HL
	inc	1, bc                              ; FB70BF  inc 1,BC
	extz	xbc                               ; FB70C1  extz XBC
	extpfx7 0xD3, 0xE5, 0xCF, 0x3B, 0x3C, 0xFF, 0xFB ; FB70C3  and (XBC+0x3bcf),0xfbff   [llvm-mc cannot encode this]
	pushw	hl                               ; FB70CA  push HL
	calr (0xFB6EDC - 0xFB70CE)             ; FB70CB  calr 0xfb6edc
	ld	de, hl                              ; FB70CE  ld DE,HL
	add	de, 0x500                          ; FB70D0  add DE,0x0500
	ld	xbc, 0x10C000                       ; FB70D4  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB70D9  ld (XIZ+0xfc),XBC
	ld	(xbc), de                           ; FB70DC  ld (XBC),DE
	ld	xbc, (xiz+10)                       ; FB70DE  ld XBC,(XIZ+0x0a)
	ld	de, (xbc+22)                        ; FB70E1  ld DE,(XBC+0x16)
	ld	xwa, (xiz-4)                        ; FB70E4  ld XWA,(XIZ+0xfc)
	inc	2, xwa                             ; FB70E7  inc 2,XWA
	ld	(xiz-8), xwa                        ; FB70E9  ld (XIZ+0xf8),XWA
	ld	(xwa), de                           ; FB70EC  ld (XWA),DE
	ld	bc, hl                              ; FB70EE  ld BC,HL
	add	bc, 0x900                          ; FB70F0  add BC,0x0900
	ld	xwa, (xiz-4)                        ; FB70F4  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB70F7  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB70F9  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+32)                        ; FB70FC  ld WA,(XBC+0x20)
	ld	xiy, (xiz-8)                        ; FB70FF  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB7102  ld (XIY),WA
	ld	bc, hl                              ; FB7104  ld BC,HL
	add	bc, 0x940                          ; FB7106  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB710A  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB710D  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB710F  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+34)                        ; FB7112  ld WA,(XBC+0x22)
	ld	xiy, (xiz-8)                        ; FB7115  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB7118  ld (XIY),WA
	ld	bc, hl                              ; FB711A  ld BC,HL
	add	bc, 0x980                          ; FB711C  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB7120  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7123  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB7125  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+36)                        ; FB7128  ld WA,(XBC+0x24)
	ld	xiy, (xiz-8)                        ; FB712B  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB712E  ld (XIY),WA
	inc	8, xsp                             ; FB7130  inc 0,XSP
	inc	4, xsp                             ; FB7132  inc 4,XSP
	pop	xix                                ; FB7134  pop XIX
	popw	de                                ; FB7135  pop DE
	popw	hl                                ; FB7136  pop HL
	unlk32 xiz                             ; FB7137  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7139  ret

; ============================================================================
; ★★ 0x0010C000: THE REGISTERS THAT NOW HAVE A MEANING   (round 7, 2026-08-25)
; ============================================================================
; Rounds 4-6 established this device's SHAPE (64 channels, `block*0x40 + chan`,
; select/data/read at +0, +2, +4) and, in wave 5, a per-register list of the
; routines that PRODUCE each staged word -- but not one register's meaning.  Four
; now have one, and one more has its quiescent value.  Every claim below is an
; assertion in `python3 notes/prom_c_dev10c_meaning_checks.py` (0 failures) and is
; written up in notes/FINDINGS-prom_c-dev10c-register-meanings.md.
;
;   register        staged   named by                        what it carries
;   --------------  -------  ------------------------------  ---------------------
;   chan + 0x0040   word 1   Voice_SelectKeyZone_Reg0040     word 0 of the key-zone
;                                                            record the note selects;
;                                                            bits 15..12 a field a
;                                                            config bit DOUBLES, bits
;                                                            11..0 a payload
;   chan + 0x0080   word 2   Voice_StageLevel_Reg0080        OUTPUT LEVEL.  bits 11..0
;                                                            log2 amplitude, 256 counts
;                                                            per octave, larger =
;                                                            louder; bits 14..12 a
;                                                            note-derived 3-bit field;
;                                                            bit 15 the gate pulse
;   chan + 0x0400   word 7   Voice_StagePitch_Reg0400_AB/CD  PITCH, 1/256 semitone,
;                                                            saturated to 0..0x7FFF =
;                                                            notes 0..127.996
;   chan + 0x0800   word 12  (quiescent value only)          0xFF80 at power-on and on
;   chan + 0x0840   word 13  (quiescent value only)          0xFF00   a voice-list clear
;   -- added round 3, 2026-08-25; see the section after this table ------------
;   chan + 0x0100   word 4   Voice_StagePair_Reg0100_0140_*  bits 6..0 a value clamped
;   chan + 0x0140   word 5     (four of them; both words        to 36..120, bits 15..7
;                              always written together)         passed through.  The
;                                                               KN5000 sibling calls
;                                                               0x100 the TVF cutoff and
;                                                               0x140 its depth/bias
;   chan + 0x0180   word 6   Voice_StageRegs_CD / Voice_StageRegs_0180_AB         WRITE side: a 0..0x7F
;                                                               control, tone byte 0x80
;                                                               = choose at random.  The
;                                                               sibling calls it pan,
;                                                               0x40 = centre.  ⚠ the
;                                                               READ is a different
;                                                               quantity entirely
;   -- added round 9, 2026-08-30 -----------------------------------------------
;   chan + 0x00C0   word 3   Voice_StageRegs_00C0_AB         (MIDI CONTROLLER 91 << 8)
;                            NotePool8_Reg00C0_FromPart0-      | MIDI CONTROLLER 93.
;                              Ctrl91And93                     Each half 0..0x7F.  The
;                                                              two producers are
;                                                              unrelated code paths and
;                                                              agree on the split; the
;                                                              main one offsets each
;                                                              half by a per-tone depth
;                                                              and clamps, the pool one
;                                                              copies part 0's two bytes
;                                                              straight through.
;                                                              ⚠ WHAT the two depths do
;                                                              is NOT established: the
;                                                              MIDI allocation calls 91
;                                                              and 93 'effects depth 1
;                                                              and 3', and this firmware
;                                                              corroborates only
;                                                              controllers 7, 64 and 120
;                                                              of its own numbers.
;
;
; ============================================================================
; ★★ ADDED ROUND 2, 2026-08-25: BLOCK GROUP 0x20-0x29 IS A GROUP OF BYTE PAIRS,
;    AND `chan + 0x0800` IS (ENVELOPE LEVEL << 8) | (ENVELOPE RATE)
; ============================================================================
; Asserted by `python3 notes/prom_c_reg_bytepair_check.py --selftest` (a census of
; all 22 computed stores) and written up in
; notes/FINDINGS-prom_c-voice-readback.md §8.
;
; ★ EVERY ONE OF THE TEN REGISTERS 0x0800, 0x0840, 0x0880, 0x08C0, 0x0900, 0x0940,
; 0x0980, 0x09C0, 0x0A00 and 0x0A40 IS ASSEMBLED AS TWO 8-BIT FIELDS.  The census
; finds 22 computed stores over all ten staging words and classifies every one:
; twelve build the word as `hi << 8 | (lo & 0xFF)` and eight as
; `(source & 0xFF00) | (value & 0x00FF)` -- the same split seen from the other side,
; keeping the high byte of a source word and replacing the low.  The two remaining
; stores put a 7-bit value with bit 15 set.  There is no other idiom.
;
; ★★ `chan + 0x0800` IS NAMED, AND BY TWO INDEPENDENT DERIVATIONS.
;   * In THIS image: staging word 12 has exactly four producers -- Voice_StageRegs_0800_A,
;     Voice_StageRegs_0800_CD, Voice_StageRegs_0800_B_ModeLt3 and Voice_StageRegs_0800_B_ModeGe3 -- and those are EXACTLY the four
;     routines in prom_c that read `Voice_LevelPair_AttackCurve` (0xFDEF74, 101
;     bytes descending 0xFF..0x09).  Its LOW byte is
;     `Voice_EnvelopeRate_Table[tone[+0x28]]` (`add XWA,0x00fdf03e` at 0xFAA62E,
;     packed at 0xFAA640-0xFAA649); its HIGH byte is a value clamped to 0..0xFF.
;     tone offset 0x28 is 40 decimal.
;   * In the KN5000 SUB-CPU, whose `Voice_EnvelopeRate_Table` is BYTE-IDENTICAL to
;     this one, the disassembly says of it, in its own words:
;         "Indexed by tonerec+40 in Voice_Calc_LevelPair_PatchAtk_*; packed as
;          (level << 8) | rate into TG register 0x800."
;     (../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s, the header above
;     `Voice_EnvelopeRate_Table`.)  Same table bytes, same tone-record offset 40,
;     same packing, SAME REGISTER NUMBER 0x800, reached independently.
;   So: high byte = an envelope LEVEL taken from a 101-entry curve indexed by a
;   0..100 parameter; low byte = an envelope RATE from a monotone 0x00..0x7F table.
;   ⚠ The curve DESCENDS (0xFF at parameter 0 to 0x09 at 100), so whether the byte
;   is "level" or "attenuation" at the pin is NOT decided here; "level" is the
;   sibling's word and is carried over with that caveat.
;
; ★ THE OTHER SIX OF THE GROUP -- 0x0900, 0x0940, 0x0980, 0x09C0, 0x0A00, 0x0A40 --
; are written by exactly two routines, Voice_StageRegs_0900_0940_0980_AB and Voice_StageRegs_09C0_0A00_0A40_AB (three registers
; each), and those two make TWELVE `Voice_EnvelopeLevel_Curve` lookups between them
; ⚠ CORRECTED round 3, 2026-08-25: "exactly two" counts only the routines the
; producer census can see.  sub_FC7FCA also writes 0x0900, 0x0940 and 0x0980 -- all
; three with the SAME value, 0xE000 | (a signed delta & 0xFF) -- through a struct
; pointer its callers hand it (0xFC80E8/0xFC80EE/0xFC80F4).  The 3-and-3 grouping of
; the CURVE-READING producers, which is what the sentence is about, is unaffected.
; See notes/prom_c_staging_producer_audit.py.
; (six each) and no other curve lookup.  Their HIGH bytes are the clamped results;
; their LOW bytes are SIGNED, `DetuneCurve_LookupSigned` of a value first clamped to
; -50..+50, i.e. a +/-127 depth.  ⚠ That these six are envelope STAGES, and in what
; order, is NOT asserted -- what is established is the byte split, the curve behind
; the high byte and the +/-50 -> +/-127 law behind the low byte.
;
; ⚠ `Detune_Scale_Curve` is a name TRANSPLANTED from the KN5000 sub-CPU (the 51
; bytes are identical).  In BOTH images its only callers are level packers, not a
; pitch path -- the KN5000's own header says `Detune_ScaleSymmetric` is "called from
; the level packer".  The local wrappers are therefore named for the TABLE they use
; and not for a quantity.
;
; ⚠ WHAT IS STILL NOT ESTABLISHED.  Eleven per-channel registers still have no
; meaning -- 0x00C0 (only its stopped value, 0x0000), 0x0100, 0x0140, 0x0180 (see
; Dev10C_PollBankAndRetire for what is READ there), 0x0440, 0x0480, 0x04C0, 0x0500,
; 0x0840, 0x0880 and 0x08C0 -- and neither do the two BYTES of the six registers
; above.  The 3-bit field inside 0x0080; what the key-zone record IS; whether any of
; the three parallel gate/value slots is a key-on.  None of those is guessed here.
; ⚠ SUPERSEDED IN PART, round 3, 2026-08-25: the count above is NINE, not eleven.
; 0x0100 and 0x0140 are decoded as a PAIR immediately below, and 0x0180's WRITE side
; is decoded too.  Everything else in this paragraph stands.
;
; ============================================================================
; ★★ ADDED ROUND 3, 2026-08-25: 0x0100 AND 0x0140 ARE A PAIR, AND THE KN5000
;    SUB-CPU STAGES THE SAME 22 REGISTERS IN THE SAME ORDER
; ============================================================================
; Asserted by `python3 notes/prom_c_reg0100_0140_checks.py --selftest` (3 negative
; controls, FAILURES: 0) and written up in
; notes/FINDINGS-prom_c-dev10c-sibling-register-map.md.
;
; ★ 0x0100 + chan AND 0x0140 + chan ARE ONE OBJECT.  Four routines stage them --
; Voice_StagePair_Reg0100_0140_{AB,CD,First,Both} -- and every one writes BOTH words
; and NOTHING else; a fifth writer, VoiceParam_DispatchOn_17_11's arm 0, copies both
; verbatim.  Their values are the voice record's words +0x3F and +0x41, and the
; modulated form is
;
;     register = (voice_word & 0xFF80) | Clamp_36_to_120( (voice_word & 0x7F) -/+ M )
;     M        = (voice[+0x23])[+0x21]            a per-part byte
;     sign     = SUBTRACT if bit 7 of (voice[+0x25])[+0x18], else ADD
;     enable   = bit 6 of the same word; clear -> the voice word passes through
;
; so the register is a 9-bit pass-through field over a 7-bit quantity whose bounds,
; 36 and 120, are the only two immediates in Clamp_36_to_120 (0xFA76B2).  All EIGHT
; callers of that clamp are on this path -- found by decoding every `calr`/`call` in
; the image, not by reading a header (checker section 1b).
;
; ★★ AND THE SIBLING NAMES IT.  The KN5000 sub-CPU stages 22 words at its RAM
; 0x0451CC into 22 registers of one voice, and ITS 22 REGISTER NUMBERS ARE THESE 22,
; IN THIS ORDER (machine-compared, checker section 5b, against
; ../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:6938-6959).  It calls
; 0x100 the TVF CUTOFF, 0x140 its DEPTH/BIAS and 0x180 PAN with 0x40 as centre, and
; its emitters TVF_Emit_Offset_Reg100 / _Both / TVF_Emit_Registers are this image's
; three stagers routine for routine -- same enable bit 6, same sign bit 7, same 0x7F
; extract, same 0xFF80 merge, same clamp with the same UPPER immediate 0x78, same
; six-case dispatcher.
; ⚠ THE BYTES ARE NOT THE SAME.  19 of 20, 100 of 102 and 116 of 120 shared bytes
; differ (checker section 5): different calling convention, different record offsets.
; Nothing here is transplanted.  What is borrowed is the IDENTIFICATION of the
; registers, and it is borrowed against a measured calibration -- on the five
; registers where THIS image has its own independent answer (0x0040's 4/12 split,
; 0x0080's level + 3-bit field + gate, 0x0400's pitch, 0x0800's (level<<8)|rate, and
; the 3+3 grouping of 0x0900-0x0A40), the sibling agrees FIVE times out of five and
; contradicts nothing.  The routine names in this file therefore state REGISTER
; NUMBERS; "cutoff" and "pan" live in the findings note with this caveat attached.
;
; ★ 0x0180 + chan, WRITE SIDE.  Both producers build voice[+0x27] from the tone
; record's byte (voice[+0x17])[+0x01]: the value 0x80 means "choose one at random"
; (Rand_FromTickSquared with bit 7 cleared, 0xFA978F / 0xFA9EDF) and anything else is
; that byte offset either way by a per-part byte and clamped to 0..0x7F
; (Clamp_ToRange_LowByte with hi = 0x7F, lo = 0, pushed at 0xFA97BD/0xFA97C0).
; A 0..0x7F control with a random encoding and a centre at 0x40 is what the sibling
; calls pan.  ⚠ The READ at this same block is NOT this quantity -- it is masked
; 0x3FFF and shifted right 5 -- and this comment does not reconcile them.
;
; ⚠ AND THE PRODUCER INDEX IS INCOMPLETE.  notes/prom_c_dev10c_field_sources.py
; misses 17 write sites in three classes; the corrected figure is 87 sites over the
; same 21 of 22 words, and register 0x0040 gains a producer, Word_AddTickLow3, that
; writes through a pointer VoiceRegs_Stage_D hands it.  Re-derive with
; `python3 notes/prom_c_staging_producer_audit.py --selftest`.
; ============================================================================

; --------------------------------------------------------------------------
; ★★ Dev10C_WriteAllChanRegs -- twenty-two registers of ONE channel of 0x0010C000, in
;             one unrolled run, from a 0x2C-byte struct.  The twin of
;             Dev104_WriteAllChanRegs (0xFB77EF), which does the same for 0x00104000.
;
; Called from: SEVEN sites -- `call 0xFB713A` at 0xFAC3FE, 0xFB0B86, 0xFB1FA5,
;          0xFB288B, 0xFB2F65 and 0xFC3F17, plus the `calr` at 0xFB817E inside
;          Dev10C_ResetAllChannels (which is why step 5 of the reset sweep in
;          notes/FINDINGS-prom_c-tone-generator.md §6 lists 0xFB713A).
;          notes/prom_c_xrefs.py 0xFB713A.
; Inputs:  (XIZ+0x08) channel, (XIZ+0x0a) pointer to the staging struct (XIX).
; Outputs: the register table in the block comment above, plus the three helper
;          calls at the top and the shadow write at the bottom.
; Evidence: ★ THE WHOLE TABLE IS MACHINE-EXTRACTED.  `notes/prom_c_tg_chanmap.py`
;          walks the routine, tracks the two device pointers through their frame
;          slots and the value registers through their arithmetic, and prints
;          every port write in EXECUTION ORDER with its provenance -- it does not
;          zip two lists, which is the mistake
;          notes/FINDINGS-prom_c-tone-generator.md §3 had to retract:
;
;            $ python3 notes/prom_c_tg_chanmap.py --selftest
;              Dev10C_WriteAllChanRegs 0xFB713A: 23 SELECT, 23 DATA, 0 untracked
;              selftest: OK
;
;          The selftest asserts the LAST select (arg0 + 0x0080) and the LAST data
;          write (struct+0x04 with bit 15 cleared), not the first.
;          ★ THE LAST WRITE IS THE GATE FALLING.  Register chan+0x0080 is written
;          TWICE by this routine: at 0xFB7179 with struct->0x04 and bit 15 SET, and
;          at 0xFB7302 with the same field and bit 15 CLEAR -- the 1-then-0 pulse
;          §5 of the tone-generator note describes, here wrapped round the other
;          twenty registers instead of round one companion.
;          ★ AND THE PULSE'S VALUE IS THEN SHADOWED: 0xFB7317-0xFB7322 stores
;          struct->0x04 with bit 15 clear to 0x0000D85B + 2*chan, which is exactly
;          what the two ±2 helpers read back.
;          Register block 0 gets the literal 0x8100 (0xFB7239) and no struct field
;          -- the same constant three routines of the second accessor bank write,
;          per §5 of that note.
; Unknown:  what any register does.
;          ✔ PARTLY CLOSED 2026-08-30 (round 9): what struct word 0 (offset 0x00)
;          is for.  This routine never writes it and puts the literal 0x8100 in
;          register block 0 instead (0xFB7234).  But one of its seven callers,
;          NotePool8_NoteOnOff, fills word 0 of its own buffer and then sends that
;          word to register chan+0x0000 through Dev10C_WriteReg_c immediately
;          after this burst returns -- `ld BC,(XIZ+0x92)` at 0xFC3F1B, the channel
;          pushed at 0xFC3F1F, `call 0xfb732c` at 0xFC3F27.  On THAT path word 0
;          is the value for register block 0.  ⚠ One caller's usage is not a
;          statement about the field: the other six callers were not traced, and
;          Dev104_WriteAllChanRegs writes ITS word 0 LAST.
; --------------------------------------------------------------------------
Dev10C_WriteAllChanRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FB713A  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FB713E  push HL
	pushw	de                               ; FB713F  push DE
	push	xix                               ; FB7140  push XIX
	ld	xix, (xiz+10)                       ; FB7141  ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                         ; FB7144  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB7147  push HL
	calr (0xFB6E8C - 0xFB714B)             ; FB7148  calr 0xfb6e8c
	pushw	hl                               ; FB714B  push HL
	calr (0xFB6E8C - 0xFB714F)             ; FB714C  calr 0xfb6e8c
	pushw	hl                               ; FB714F  push HL
	calr (0xFB6E0A - 0xFB7153)             ; FB7150  calr 0xfb6e0a
	ld	de, hl                              ; FB7153  ld DE,HL
	add	de, 64                             ; FB7155  add DE,0x0040
	ld	xbc, 0x10C000                       ; FB7159  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB715E  ld (XIZ+0xfc),XBC
	ld	(xbc), de                           ; FB7161  ld (XBC),DE
	ld	de, (xix+2)                         ; FB7163  ld DE,(XIX+0x02)
	ld	xbc, (xiz-4)                        ; FB7166  ld XBC,(XIZ+0xfc)
	inc	2, xbc                             ; FB7169  inc 2,XBC
	ld	(xiz-8), xbc                        ; FB716B  ld (XIZ+0xf8),XBC
	ld	(xbc), de                           ; FB716E  ld (XBC),DE
	ld	de, hl                              ; FB7170  ld DE,HL
	add	de, 0x80                           ; FB7172  add DE,0x0080
	ld	xbc, (xiz-4)                        ; FB7176  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                           ; FB7179  ld (XBC),DE
	ld	bc, (xix+4)                         ; FB717B  ld BC,(XIX+0x04)
	set	15, bc                             ; FB717E  set 0x0f,BC
	ld	xwa, (xiz-8)                        ; FB7181  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7184  ld (XWA),BC
	ld	bc, hl                              ; FB7186  ld BC,HL
	add	bc, 0xC0                           ; FB7188  add BC,0x00c0
	ld	xwa, (xiz-4)                        ; FB718C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB718F  ld (XWA),BC
	ld	bc, (xix+6)                         ; FB7191  ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                        ; FB7194  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7197  ld (XWA),BC
	ld	bc, hl                              ; FB7199  ld BC,HL
	add	bc, 0x100                          ; FB719B  add BC,0x0100
	ld	xwa, (xiz-4)                        ; FB719F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71A2  ld (XWA),BC
	ld	bc, (xix+8)                         ; FB71A4  ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                        ; FB71A7  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71AA  ld (XWA),BC
	ld	bc, hl                              ; FB71AC  ld BC,HL
	add	bc, 0x140                          ; FB71AE  add BC,0x0140
	ld	xwa, (xiz-4)                        ; FB71B2  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71B5  ld (XWA),BC
	ld	bc, (xix+10)                        ; FB71B7  ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                        ; FB71BA  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71BD  ld (XWA),BC
	ld	bc, hl                              ; FB71BF  ld BC,HL
	add	bc, 0x180                          ; FB71C1  add BC,0x0180
	ld	xwa, (xiz-4)                        ; FB71C5  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71C8  ld (XWA),BC
	ld	bc, (xix+12)                        ; FB71CA  ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                        ; FB71CD  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71D0  ld (XWA),BC
	ld	bc, hl                              ; FB71D2  ld BC,HL
	add	bc, 0x400                          ; FB71D4  add BC,0x0400
	ld	xwa, (xiz-4)                        ; FB71D8  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71DB  ld (XWA),BC
	ld	bc, (xix+14)                        ; FB71DD  ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                        ; FB71E0  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71E3  ld (XWA),BC
	ld	bc, hl                              ; FB71E5  ld BC,HL
	add	bc, 0x440                          ; FB71E7  add BC,0x0440
	ld	xwa, (xiz-4)                        ; FB71EB  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71EE  ld (XWA),BC
	ld	bc, (xix+16)                        ; FB71F0  ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                        ; FB71F3  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71F6  ld (XWA),BC
	ld	bc, hl                              ; FB71F8  ld BC,HL
	add	bc, 0x480                          ; FB71FA  add BC,0x0480
	ld	xwa, (xiz-4)                        ; FB71FE  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7201  ld (XWA),BC
	ld	bc, (xix+18)                        ; FB7203  ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                        ; FB7206  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7209  ld (XWA),BC
	ld	bc, hl                              ; FB720B  ld BC,HL
	add	bc, 0x4C0                          ; FB720D  add BC,0x04c0
	ld	xwa, (xiz-4)                        ; FB7211  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7214  ld (XWA),BC
	ld	bc, (xix+20)                        ; FB7216  ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                        ; FB7219  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB721C  ld (XWA),BC
	ld	bc, hl                              ; FB721E  ld BC,HL
	add	bc, 0x800                          ; FB7220  add BC,0x0800
	ld	xwa, (xiz-4)                        ; FB7224  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7227  ld (XWA),BC
	ld	bc, (xix+24)                        ; FB7229  ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                        ; FB722C  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB722F  ld (XWA),BC
	ld	xbc, (xiz-4)                        ; FB7231  ld XBC,(XIZ+0xfc)
	ld	(xbc), hl                           ; FB7234  ld (XBC),HL
	ld	xbc, (xiz-8)                        ; FB7236  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x00, 0x81         ; FB7239  ld (XBC),0x8100   [llvm-mc cannot encode this]
	ld	bc, hl                              ; FB723D  ld BC,HL
	add	bc, 0x840                          ; FB723F  add BC,0x0840
	ld	xwa, (xiz-4)                        ; FB7243  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7246  ld (XWA),BC
	ld	bc, (xix+26)                        ; FB7248  ld BC,(XIX+0x1a)
	ld	xwa, (xiz-8)                        ; FB724B  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB724E  ld (XWA),BC
	ld	bc, hl                              ; FB7250  ld BC,HL
	add	bc, 0x880                          ; FB7252  add BC,0x0880
	ld	xwa, (xiz-4)                        ; FB7256  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7259  ld (XWA),BC
	ld	bc, (xix+28)                        ; FB725B  ld BC,(XIX+0x1c)
	ld	xwa, (xiz-8)                        ; FB725E  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7261  ld (XWA),BC
	ld	bc, hl                              ; FB7263  ld BC,HL
	add	bc, 0x9C0                          ; FB7265  add BC,0x09c0
	ld	xwa, (xiz-4)                        ; FB7269  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB726C  ld (XWA),BC
	ld	bc, (xix+38)                        ; FB726E  ld BC,(XIX+0x26)
	ld	xwa, (xiz-8)                        ; FB7271  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7274  ld (XWA),BC
	ld	bc, hl                              ; FB7276  ld BC,HL
	add	bc, 0xA00                          ; FB7278  add BC,0x0a00
	ld	xwa, (xiz-4)                        ; FB727C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB727F  ld (XWA),BC
	ld	bc, (xix+40)                        ; FB7281  ld BC,(XIX+0x28)
	ld	xwa, (xiz-8)                        ; FB7284  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7287  ld (XWA),BC
	ld	bc, hl                              ; FB7289  ld BC,HL
	add	bc, 0xA40                          ; FB728B  add BC,0x0a40
	ld	xwa, (xiz-4)                        ; FB728F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7292  ld (XWA),BC
	ld	bc, (xix+42)                        ; FB7294  ld BC,(XIX+0x2a)
	ld	xwa, (xiz-8)                        ; FB7297  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB729A  ld (XWA),BC
	pushw	hl                               ; FB729C  push HL
	calr (0xFB6EDC - 0xFB72A0)             ; FB729D  calr 0xfb6edc
	ld	bc, hl                              ; FB72A0  ld BC,HL
	add	bc, 0x8C0                          ; FB72A2  add BC,0x08c0
	ld	xwa, (xiz-4)                        ; FB72A6  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72A9  ld (XWA),BC
	ld	bc, (xix+30)                        ; FB72AB  ld BC,(XIX+0x1e)
	ld	xwa, (xiz-8)                        ; FB72AE  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72B1  ld (XWA),BC
	ld	bc, hl                              ; FB72B3  ld BC,HL
	add	bc, 0x500                          ; FB72B5  add BC,0x0500
	ld	xwa, (xiz-4)                        ; FB72B9  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72BC  ld (XWA),BC
	ld	bc, (xix+22)                        ; FB72BE  ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                        ; FB72C1  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72C4  ld (XWA),BC
	ld	bc, hl                              ; FB72C6  ld BC,HL
	add	bc, 0x900                          ; FB72C8  add BC,0x0900
	ld	xwa, (xiz-4)                        ; FB72CC  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72CF  ld (XWA),BC
	ld	bc, (xix+32)                        ; FB72D1  ld BC,(XIX+0x20)
	ld	xwa, (xiz-8)                        ; FB72D4  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72D7  ld (XWA),BC
	ld	bc, hl                              ; FB72D9  ld BC,HL
	add	bc, 0x940                          ; FB72DB  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB72DF  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72E2  ld (XWA),BC
	ld	bc, (xix+34)                        ; FB72E4  ld BC,(XIX+0x22)
	ld	xwa, (xiz-8)                        ; FB72E7  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72EA  ld (XWA),BC
	ld	bc, hl                              ; FB72EC  ld BC,HL
	add	bc, 0x980                          ; FB72EE  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB72F2  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72F5  ld (XWA),BC
	ld	bc, (xix+36)                        ; FB72F7  ld BC,(XIX+0x24)
	ld	xwa, (xiz-8)                        ; FB72FA  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72FD  ld (XWA),BC
	ld	xbc, (xiz-4)                        ; FB72FF  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                           ; FB7302  ld (XBC),DE
	ld	bc, (xix+4)                         ; FB7304  ld BC,(XIX+0x04)
	res	15, bc                             ; FB7307  res 0x0f,BC
	ld	xwa, (xiz-8)                        ; FB730A  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB730D  ld (XWA),BC
	ld	bc, (xix+4)                         ; FB730F  ld BC,(XIX+0x04)
	ld	de, bc                              ; FB7312  ld DE,BC
	res	15, de                             ; FB7314  res 0x0f,DE
	ldw	bc, 2                              ; FB7317  ld BC,0x0002
	mul	xbc, xhl                           ; FB731A  mul XBC,HL
	add	xbc, 0xD85B                        ; FB731C  add XBC,0x0000d85b
	ld	(xbc), de                           ; FB7322  ld (XBC),DE
	inc	8, xsp                             ; FB7324  inc 0,XSP
	pop	xix                                ; FB7326  pop XIX
	popw	de                                ; FB7327  pop DE
	popw	hl                                ; FB7328  pop HL
	unlk32 xiz                             ; FB7329  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB732B  ret

; --------------------------------------------------------------------------
; Dev10C_WriteReg_c -- register (arg0) = arg1.  The bare address/data pair.
;
; Called from: NINE `call` sites (0xFAC054, 0xFAC413, 0xFB371D, 0xFB382A,
;          0xFB39AD, 0xFB3AB8, 0xFB3BD1, 0xFB3D87, 0xFC3F27) and the `calr` at
;          0xFB81AE inside Dev10C_ResetAllChannels.
; Inputs:  (XIZ+0x08) = the 16-bit register number, (XIZ+0x0a) = its value.
; Evidence: ★ BYTE-IDENTICAL, all 25 bytes, to Dev10C_WriteReg at 0xFACE89 above
;          (`notes/prom_c_tg_regmap.py --dups`).  It is the routine that fixes the
;          port's shape: no arithmetic between the arguments and the port.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Dev10C_WriteReg_c:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB732C  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; FB7330  push XIX
	ld	xix, 0x10C000                       ; FB7331  ld XIX,0x0010c000
	ld	bc, (xiz+8)                         ; FB7336  ld BC,(XIZ+0x08)
	ld	(xix), bc                           ; FB7339  ld (XIX),BC
	ld	bc, (xiz+10)                        ; FB733B  ld BC,(XIZ+0x0a)
	ld	(xix+2), bc                         ; FB733E  ld (XIX+0x02),BC
	pop	xix                                ; FB7341  pop XIX
	unlk32 xiz                             ; FB7342  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7344  ret

; ==============================================================================
; 0xFB7345-0xFB7714 -- not yet converted
; ==============================================================================

; ==============================================================================
; 0xFB7345-0xFB7714 -- 9 routines, 0 computed-goto arm(s), 0 table(s), 976 bytes
; ==============================================================================
;
; Boundaries, read off the bytes rather than asserted:
;   0xFB7344 = 0x0E (`ret`)   0xFB7345 = EE 0C (`link XIZ`)
;   0xFB7714 = 0x0E (`ret`)   0xFB7715 = EE 0C (`link XIZ`)
;   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between
;   routines; anything else on those lines is a cut that needs reading.
;
; Call census (`python3 notes/prom_c_module_map.py 0xFB7345 0xFB7715`):
;   9 literal call site(s) from outside this block, 0 from inside it.
;          3  sub_FAC08D
;          2  Voice_Retire_Mode20
;          1  Dev10C_StageRegs_0800_0840_ForNoteOn
;          1  sub_FADEAC
;          1  Voice_Retire_Mode08
;          1  Voice_Retire_Mode10
;   ⚠ Sites in code that is still `.incbin` are counted under
;   "(caller not yet converted)"; that row shrinks as conversion proceeds,
;   so every named row is a FLOOR.
;
; No computed-goto table: `python3 notes/prom_c_jumptables.py 0xFB7345 0xFB7715`
;   prints none, so the whole range is decoded linearly.
;
; ★ DECODE ALIGNMENT.  notes/gen_prom_c_block.py requires every
;   call/calr/jp/jrl/jr target that a DECODED INSTRUCTION in this file names
;   and that lands inside this range to be the start of a listing line.  A
;   byte round trip cannot show that -- a misaligned decode of data can
;   re-encode to the same bytes -- so this is the test that says the listing
;   was read at the right offsets, and it is what found the BC-form jump
;   table at 0xFAF08F that the table scanner had missed.
;
; ⚠ NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Each header states the frame
;   size, the argument slots read, the absolute addresses read and written,
;   the routines called and the call sites -- operands and decoded-instruction
;   scans, nothing interpreted.
;
; ★ REGENERATE:
;     python3 notes/gen_prom_c_block.py --start 0xFB7345 --end 0xFB7715 > /tmp/b.s
;     python3 notes/gen_prom_c_block_headers.py --start 0xFB7345 --end 0xFB7715 \
;         --labels > /tmp/b.labels
;     python3 notes/gen_prom_c_block_headers.py --start 0xFB7345 --end 0xFB7715 \
;         --headers > /tmp/b.headers
;     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \
;         /tmp/b.headers > /tmp/b.final.s
;     python3 notes/prom_c_verify_fragment.py c 0xFB7345 /tmp/b.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; Dev10C_WriteSixChanRegs_FromD78A -- 0xFB7345..0xFB73EF (171 bytes)
;             push SIX words into six per-channel registers of the device at 0x0010C000,
;             from the six words that follow the 22-word staging struct.
;             (★ NAMED in wave 7 round 2; was `sub_FB7345`.)
;
; Called from: 4 site(s) outside this module:
;          0xFADF70 in sub_FADEAC__FADF55, 0xFB3DB3 in Voice_Retire_Mode20__FB3D9E
;          0xFB3E3D in Voice_Retire_Mode08__FB3E26, 0xFB3E80 in Voice_Retire_Mode10
;          ★ ALL FOUR pass the same shape: `lda XBC,0x00D75E / push XBC`, then the
;          channel word.  So "struct" below is 0x00D75E at every located call site.
; Inputs:  frame `link XIZ,-8`; (XIZ+0x08) = channel number, (XIZ+0x0A) = struct base.
; Outputs: six registers of ONE channel of 0x0010C000 (no absolute-addressed RAM write).
; Calls:   0xFB6E8C = Dev10C_ChanMinus2_SetReg_0080_Bit15 -- FIVE calr sites, 0xFB7353,
;          0xFB7357, 0xFB735B, 0xFB735F and 0xFB7363, all with the same argument
;          0xFB6EDC = Dev10C_ChanMinus2_ClrReg_0080_Bit15 -- once, 0xFB73BD, between the
;          fourth and fifth register write
; Evidence: ★ the register/word map is NOT read off this listing by eye.  It is
;          reproduced from the ROM bytes by `python3 notes/prom_c_tg_chanmap.py 0xFB7345
;          0xAB --pairs`, which follows the two frame slots holding the select and data
;          pointers and prints, in execution order:
;              0xFB7374  register arg0 + 0x0840   <- struct+0x2E
;              0xFB738C  register arg0 + 0x0A00   <- struct+0x36
;              0xFB739F  register arg0 + 0x0800   <- struct+0x2C
;              0xFB73B2  register arg0 + 0x09C0   <- struct+0x34
;              0xFB73C9  register arg0 + 0x0940   <- struct+0x32
;              0xFB73DC  register arg0 + 0x0900   <- struct+0x30
;          Sorted by register those six pairs are SIX CONSECUTIVE WORDS feeding
;          ascending blocks: 0x0800<-+0x2C, 0x0840<-+0x2E, 0x0900<-+0x30, 0x0940<-+0x32,
;          0x09C0<-+0x34, 0x0A00<-+0x36 -- i.e. RAM 0x00D78A, 0x00D78C, 0x00D78E,
;          0x00D790, 0x00D792, 0x00D794, since every located caller passes struct =
;          0x00D75E.
;          Those six words sit immediately AFTER the 22-word staging struct
;          0x00D75E..0x00D789 that Dev10C_WriteAllChanRegs (0xFB713A) moves
;          (notes/FINDINGS-prom_c-dev10c-producers.md §2), and they feed exactly the six
;          register blocks that struct's words 12, 13, 16, 17, 19 and 20 feed.
;          Their five producers are named beside them:
;          Dev10C_StageRegs_0800_0840_{FAB818,FAB8CC,FAB9D8} write 0x00D78A/0x00D78C,
;          Dev10C_StageRegs_0900_0940 (0xFABAE3) writes 0x00D78E/0x00D790 and
;          Dev10C_StageRegs_09C0_0A00 (0xFABBFB) writes 0x00D792/0x00D794.
; Unknown:  ⚠ WHY the argument is used with TWO channel conventions.  The six direct
;          writes index the register file with arg0 unmodified, while the six
;          Dev10C_ChanMinus2_* calls index it with (arg0 - 2) & 0x3F.  Nothing in this
;          routine explains the offset of two, and no reading of it establishes one.
;          ⚠ WHY the set-bit-15 call is repeated FIVE times with the same argument.
;          Dev10C_ChanMinus2_SetReg_0080_Bit15 preserves HL (notes/prom_c_tg_chanmap.py
;          prints its preserved set), so the four repeats change nothing.  Whether that
;          is a compiler artefact or a deliberate delay is NOT ESTABLISHED.
;          ⚠ what the six values MEAN.  Registers 0x0800/0x0840 have a documented
;          quiescent pair (0xFF80/0xFF00, notes/FINDINGS-prom_c-dev10c-register-
;          meanings.md §5); blocks 0x0900-0x0A40 have no statement of any kind.
;          ⚠ whether this is the ONLY consumer of the six words.  No absolute LOAD of
;          0x00D78A..0x00D795 exists anywhere in prom_c, but a consumer that receives
;          the struct base as an argument, as this routine does, is invisible to that
;          search.  "Only located consumer", not "only consumer".
; --------------------------------------------------------------------------
Dev10C_WriteSixChanRegs_FromD78A:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7345  link XIZ,0xfff8
	pushw	hl                                   ; FB7349  push HL
	pushw	de                                   ; FB734A  push DE
	push	xix                                   ; FB734B  push XIX
	ld	xix, (xiz+10)                           ; FB734C  ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB734F  ld HL,(XIZ+0x08)
	pushw	hl                                   ; FB7352  push HL
	calr (0xFB6E8C - 0xFB7356)                 ; FB7353  calr 0xfb6e8c
	pushw	hl                                   ; FB7356  push HL
	calr (0xFB6E8C - 0xFB735A)                 ; FB7357  calr 0xfb6e8c
	pushw	hl                                   ; FB735A  push HL
	calr (0xFB6E8C - 0xFB735E)                 ; FB735B  calr 0xfb6e8c
	pushw	hl                                   ; FB735E  push HL
	calr (0xFB6E8C - 0xFB7362)                 ; FB735F  calr 0xfb6e8c
	pushw	hl                                   ; FB7362  push HL
	calr (0xFB6E8C - 0xFB7366)                 ; FB7363  calr 0xfb6e8c
	ld	de, hl                                  ; FB7366  ld DE,HL
	add	de, 0x840                              ; FB7368  add DE,0x0840
	ld	xbc, 0x10C000                           ; FB736C  ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7371  ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7374  ld (XBC),DE
	ld	de, (xix+46)                            ; FB7376  ld DE,(XIX+0x2e)
	ld	xbc, (xiz-4)                            ; FB7379  ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB737C  inc 2,XBC
	ld	(xiz-8), xbc                            ; FB737E  ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7381  ld (XBC),DE
	ld	bc, hl                                  ; FB7383  ld BC,HL
	add	bc, 0xA00                              ; FB7385  add BC,0x0a00
	ld	xwa, (xiz-4)                            ; FB7389  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB738C  ld (XWA),BC
	ld	bc, (xix+54)                            ; FB738E  ld BC,(XIX+0x36)
	ld	xwa, (xiz-8)                            ; FB7391  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7394  ld (XWA),BC
	ld	bc, hl                                  ; FB7396  ld BC,HL
	add	bc, 0x800                              ; FB7398  add BC,0x0800
	ld	xwa, (xiz-4)                            ; FB739C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB739F  ld (XWA),BC
	ld	bc, (xix+44)                            ; FB73A1  ld BC,(XIX+0x2c)
	ld	xwa, (xiz-8)                            ; FB73A4  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB73A7  ld (XWA),BC
	ld	bc, hl                                  ; FB73A9  ld BC,HL
	add	bc, 0x9C0                              ; FB73AB  add BC,0x09c0
	ld	xwa, (xiz-4)                            ; FB73AF  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB73B2  ld (XWA),BC
	ld	bc, (xix+52)                            ; FB73B4  ld BC,(XIX+0x34)
	ld	xwa, (xiz-8)                            ; FB73B7  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB73BA  ld (XWA),BC
	pushw	hl                                   ; FB73BC  push HL
	calr (0xFB6EDC - 0xFB73C0)                 ; FB73BD  calr 0xfb6edc
	ld	bc, hl                                  ; FB73C0  ld BC,HL
	add	bc, 0x940                              ; FB73C2  add BC,0x0940
	ld	xwa, (xiz-4)                            ; FB73C6  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB73C9  ld (XWA),BC
	ld	bc, (xix+50)                            ; FB73CB  ld BC,(XIX+0x32)
	ld	xwa, (xiz-8)                            ; FB73CE  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB73D1  ld (XWA),BC
	ld	bc, hl                                  ; FB73D3  ld BC,HL
	add	bc, 0x900                              ; FB73D5  add BC,0x0900
	ld	xwa, (xiz-4)                            ; FB73D9  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB73DC  ld (XWA),BC
	ld	bc, (xix+48)                            ; FB73DE  ld BC,(XIX+0x30)
	ld	xwa, (xiz-8)                            ; FB73E1  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB73E4  ld (XWA),BC
	inc	8, xsp                                 ; FB73E6  inc 0,XSP
	inc	4, xsp                                 ; FB73E8  inc 4,XSP
	pop	xix                                    ; FB73EA  pop XIX
	popw	de                                    ; FB73EB  pop DE
	popw	hl                                    ; FB73EC  pop HL
	unlk32 xiz                                 ; FB73ED  unlk XIZ
	ret                                        ; FB73EF  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0800_b -- 0xFB73F0..0xFB742B (60 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAB8BD in Dev10C_StageRegs_0800_0840_ForNoteOn__FAB87E
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB73F0-0xFB742B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 60 bytes BYTE-IDENTICAL, zero differing, to
;          Dev10C_SetChanReg_0840_0800 at 0xFACEDE -- the bank-B copy, named with the
;          `_b` suffix the tree already uses for the other bank-B accessors.
;          So: register (chan+0x0840) = staging->0x2E and (chan+0x0800) = staging->0x30.
;          `python3 notes/prom_c_finish_round7.py --twins`.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0800_b:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB73F0  link XIZ,0xfffc
	pushw	hl                                   ; FB73F4  push HL
	push	xix                                   ; FB73F5  push XIX
	ld	hl, (xiz+8)                             ; FB73F6  ld HL,(XIZ+0x08)
	add	hl, 0x840                              ; FB73F9  add HL,0x0840
	ld	xix, 0x10C000                           ; FB73FD  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7402  ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7404  ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+46)                            ; FB7407  ld HL,(XBC+0x2e)
	ld	xwa, xix                                ; FB740A  ld XWA,XIX
	inc	2, xwa                                 ; FB740C  inc 2,XWA
	ld	(xiz-4), xwa                            ; FB740E  ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7411  ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7413  ld BC,(XIZ+0x08)
	add	bc, 0x800                              ; FB7416  add BC,0x0800
	ld	(xix), bc                               ; FB741A  ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB741C  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+44)                            ; FB741F  ld WA,(XBC+0x2c)
	ld	xiy, (xiz-4)                            ; FB7422  ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7425  ld (XIY),WA
	pop	xix                                    ; FB7427  pop XIX
	popw	hl                                    ; FB7428  pop HL
	unlk32 xiz                                 ; FB7429  unlk XIZ
	ret                                        ; FB742B  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_b -- 0xFB742C..0xFB744D (34 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB742C-0xFB744D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 34 bytes BYTE-IDENTICAL, zero differing, to
;          Dev10C_SetChanReg_0840 at 0xFACF1A -- the bank-B copy.
;          So: register (chan+0x0840) = staging->0x2E.
;          `python3 notes/prom_c_finish_round7.py --twins`.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB742C  link XIZ,0x0000
	pushw	hl                                   ; FB7430  push HL
	push	xix                                   ; FB7431  push XIX
	ld	hl, (xiz+8)                             ; FB7432  ld HL,(XIZ+0x08)
	add	hl, 0x840                              ; FB7435  add HL,0x0840
	ld	xix, 0x10C000                           ; FB7439  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB743E  ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7440  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+46)                            ; FB7443  ld WA,(XBC+0x2e)
	ld	(xix+2), wa                             ; FB7446  ld (XIX+0x02),WA
	pop	xix                                    ; FB7449  pop XIX
	popw	hl                                    ; FB744A  pop HL
	unlk32 xiz                                 ; FB744B  unlk XIZ
	ret                                        ; FB744D  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0100_0140_b -- 0xFB744E..0xFB7489 (60 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB744E-0xFB7489
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 60 bytes BYTE-IDENTICAL, zero differing, to
;          Dev10C_SetChanReg_0100_0140 at 0xFACF3C -- the bank-B copy.
;          So: registers (chan+0x0100) = staging->0x08 and (chan+0x0140) = staging->0x0A.
;          `python3 notes/prom_c_finish_round7.py --twins`.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0100_0140_b:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB744E  link XIZ,0xfffc
	pushw	hl                                   ; FB7452  push HL
	push	xix                                   ; FB7453  push XIX
	ld	hl, (xiz+8)                             ; FB7454  ld HL,(XIZ+0x08)
	add	hl, 0x100                              ; FB7457  add HL,0x0100
	ld	xix, 0x10C000                           ; FB745B  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7460  ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7462  ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+8)                             ; FB7465  ld HL,(XBC+0x08)
	ld	xwa, xix                                ; FB7468  ld XWA,XIX
	inc	2, xwa                                 ; FB746A  inc 2,XWA
	ld	(xiz-4), xwa                            ; FB746C  ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB746F  ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7471  ld BC,(XIZ+0x08)
	add	bc, 0x140                              ; FB7474  add BC,0x0140
	ld	(xix), bc                               ; FB7478  ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB747A  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+10)                            ; FB747D  ld WA,(XBC+0x0a)
	ld	xiy, (xiz-4)                            ; FB7480  ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7483  ld (XIY),WA
	pop	xix                                    ; FB7485  pop XIX
	popw	hl                                    ; FB7486  pop HL
	unlk32 xiz                                 ; FB7487  unlk XIZ
	ret                                        ; FB7489  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880_b -- 0xFB748A..0xFB74C5 (60 bytes)
;
; Called from: no site outside this module.
;          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address anywhere
;          in the image.  A register-indirect call would be invisible to that
;          scan, so this is "not found", not "dead".
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB748A-0xFB74C5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  ⚠ 60 bytes BYTE-IDENTICAL, zero differing, to
;          Dev10C_SetChanReg_0840_0880 at 0xFACEA2 AND to Dev10C_SetChanReg_0840_0880_dup
;          at 0xFACF78 -- so this function exists THREE times in prom_c, twice in bank A
;          and once here.  `python3 notes/prom_c_finish_round7.py --twins`.
;          So: registers (chan+0x0840) = staging->0x1A and (chan+0x0880) = staging->0x1C.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880_b:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB748A  link XIZ,0xfffc
	pushw	hl                                   ; FB748E  push HL
	push	xix                                   ; FB748F  push XIX
	ld	hl, (xiz+8)                             ; FB7490  ld HL,(XIZ+0x08)
	add	hl, 0x840                              ; FB7493  add HL,0x0840
	ld	xix, 0x10C000                           ; FB7497  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB749C  ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB749E  ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+26)                            ; FB74A1  ld HL,(XBC+0x1a)
	ld	xwa, xix                                ; FB74A4  ld XWA,XIX
	inc	2, xwa                                 ; FB74A6  inc 2,XWA
	ld	(xiz-4), xwa                            ; FB74A8  ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB74AB  ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB74AD  ld BC,(XIZ+0x08)
	add	bc, 0x880                              ; FB74B0  add BC,0x0880
	ld	(xix), bc                               ; FB74B4  ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB74B6  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+28)                            ; FB74B9  ld WA,(XBC+0x1c)
	ld	xiy, (xiz-4)                            ; FB74BC  ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB74BF  ld (XIY),WA
	pop	xix                                    ; FB74C1  pop XIX
	popw	hl                                    ; FB74C2  pop HL
	unlk32 xiz                                 ; FB74C3  unlk XIZ
	ret                                        ; FB74C5  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880_From2E -- 0xFB74C6..0xFB7501 (60 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB3D7C in Voice_Retire_Mode20__FB3D5A
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB74C6-0xFB7501
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ NAMED (round 7 finish pass).  Registers (chan+0x0840) AND (chan+0x0880) both take
;          staging->0x2E -- the SAME source word into both blocks.
;          60 bytes, 2 of which differ from Dev10C_SetChanReg_0840_0880 at 0xFACEA2,
;          and both differing bytes are the struct offset: 0xFB74DE holds 2E where
;          0xFACEBA holds 1A, and 0xFB74F6 holds 2E where 0xFACED2 holds 1C.  Every
;          other byte, the two `add`s 0x0840 and 0x0880 included, is the same.
;          So the name is NOT a borrowed one: the register pair is the twin's, the
;          source field is this routine's own operand, and the suffix says so.
;          `python3 notes/prom_c_finish_round7.py --twins`.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880_From2E:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB74C6  link XIZ,0xfffc
	pushw	hl                                   ; FB74CA  push HL
	push	xix                                   ; FB74CB  push XIX
	ld	hl, (xiz+8)                             ; FB74CC  ld HL,(XIZ+0x08)
	add	hl, 0x840                              ; FB74CF  add HL,0x0840
	ld	xix, 0x10C000                           ; FB74D3  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB74D8  ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB74DA  ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+46)                            ; FB74DD  ld HL,(XBC+0x2e)
	ld	xwa, xix                                ; FB74E0  ld XWA,XIX
	inc	2, xwa                                 ; FB74E2  inc 2,XWA
	ld	(xiz-4), xwa                            ; FB74E4  ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB74E7  ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB74E9  ld BC,(XIZ+0x08)
	add	bc, 0x880                              ; FB74EC  add BC,0x0880
	ld	(xix), bc                               ; FB74F0  ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB74F2  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+46)                            ; FB74F5  ld WA,(XBC+0x2e)
	ld	xiy, (xiz-4)                            ; FB74F8  ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB74FB  ld (XIY),WA
	pop	xix                                    ; FB74FD  pop XIX
	popw	hl                                    ; FB74FE  pop HL
	unlk32 xiz                                 ; FB74FF  unlk XIZ
	ret                                        ; FB7501  ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0180_FromArg -- 0xFB7502..0xFB7520 (31 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAC0E3 in sub_FAC08D__FAC0DC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB7502-0xFB7520
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; --------------------------------------------------------------------------
; ★ NAMED (round 7 finish pass).  Register (chan + 0x0180) = THE ARGUMENT, not a
;          staging-struct field.  That is the whole difference from
;          Dev10C_SetChanReg_0180 (0xFACFB4) and its bank-B copy _0180_b (0xFB7B9F),
;          which both fetch staging->0x0C; this one writes what it is handed.
; Inputs:  (XIZ+0x08) = chan, (XIZ+0x0A) = the 16-bit value.
; Evidence: `add HL,0x0180` at 0xFB750B forms the register selector,
;          `ld XIX,0x0010C000` at 0xFB750F is the port window, `ld (XIX),HL` at
;          0xFB7514 selects, `ld BC,(XIZ+0x0A)` at 0xFB7516 fetches the argument and
;          `ld (XIX+0x02),BC` at 0xFB7519 writes it.  Thirteen instructions, no other
;          memory access; the routine is exactly its name.
; Unknown:  what register 0x0180 + chan IS beyond what
;          notes/FINDINGS-prom_c-voice-readback.md establishes about it -- a magnitude
;          the firmware watches fall.  This accessor asserts nothing about that.
Dev10C_SetChanReg_0180_FromArg:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7502  link XIZ,0x0000
	pushw	hl                                   ; FB7506  push HL
	push	xix                                   ; FB7507  push XIX
	ld	hl, (xiz+8)                             ; FB7508  ld HL,(XIZ+0x08)
	add	hl, 0x180                              ; FB750B  add HL,0x0180
	ld	xix, 0x10C000                           ; FB750F  ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7514  ld (XIX),HL
	ld	bc, (xiz+10)                            ; FB7516  ld BC,(XIZ+0x0a)
	ld	(xix+2), bc                             ; FB7519  ld (XIX+0x02),BC
	pop	xix                                    ; FB751C  pop XIX
	popw	hl                                    ; FB751D  pop HL
	unlk32 xiz                                 ; FB751E  unlk XIZ
	ret                                        ; FB7520  ret
; --------------------------------------------------------------------------
; sub_FB7521 -- 0xFB7521..0xFB762E (270 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAC247 in sub_FAC08D__FAC232
; Inputs:  frame `link XIZ,-20`; argument slots read: (XIZ+0x08), (XIZ+0x0A), (XIZ+0x0E)
; Outputs: no absolute-addressed write.
; Calls:   0xFB6E0A = Dev10C_ChanPlus2_SetRegs_09xx
; Evidence: the listing below is the byte-identical round-trip of 0xFB7521-0xFB762E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; ★ WAVE 17, 2026-09-03 -- DECODED.  This header is the auto-generated boilerplate
; ("Unknown: what the routine is FOR"); the routine is in fact a short, fully
; readable per-channel sequence, and the decode is below.  The label is left as an
; address for the reason given above sub_FB6F2C: round 12's refusal of bucket S3.
;
; Arguments: (XIZ+0x08) = chan; (XIZ+0x0A) = XIX, a struct pointer; (XIZ+0x0E) = HL,
; a 16-bit RECORD pointer.  That third argument is the per-channel record array at
; 0x00003BCF: this routine sends HL[+0x29] to register block 0, and 0xFADF40 ->
; Dev10C_WriteReg does the same thing with (0x3BCF + 0x44*chan)[+0x29] -- the same
; field to the same block, from two different routines.
;
; The writes, in execution order, from the (select, data) pairs at the addresses
; shown:
;     0xFB7542/54  register chan + 0x0800 = rec[+0x39]
;     0xFB7559/5E  register chan + 0x0000 = 0x8100        the same literal the
;                                                          second accessor bank writes
;     0xFB756E/76  register chan + 0x0840 = rec[+0x3B]  ) four times, the same
;     0xFB757E/86        "               = rec[+0x3B]  ) value each time
;     0xFB758E/96        "               = rec[+0x3B]  )
;     0xFB759E/A6        "               = rec[+0x3B]  )
;     0xFB75A9     calr Dev10C_ChanPlus2_SetRegs_09xx(chan)
;     0xFB75B8/CB  register chan + 0x0080 = struct[+0x04] & 0x7FFF   ) four times
;     0xFB75D3/DE        "               = struct[+0x04] & 0x7FFF   ) -- bit 15
;     0xFB75E6/F1        "               = struct[+0x04] & 0x7FFF   )    CLEAR
;     0xFB75F9/04        "               = struct[+0x04] & 0x7FFF   )
;     0xFB7609/11  register chan + 0x0000 = rec[+0x29]
;     0xFB7626     shadow[chan] at 0x0000D85B = struct[+0x04] & 0x7FFF
;
; ★ IN NAMED TERMS: it loads block 0x0800 -- (envelope level << 8) | (envelope
; rate), round 2 -- and its companion 0x0840 from a SECOND pair of record fields
; (+0x39, +0x3B, not the +0x18/+0x1A the full writer uses), and then drives the
; OUTPUT-LEVEL gate LOW and shadows the ungated word.  Dev10C_WriteAllChanRegs
; ends with exactly that gate-low write and exactly that shadow store.
; [INFERENCE, stated as such] a second envelope pair plus a falling gate is the
; shape of a NOTE-OFF / RELEASE.  Its caller, sub_FAC08D, dispatches on bits 14..12
; of voice_record[+0x2D] and elsewhere calls Voice_Retire_Mode20, which is
; consistent and is NOT proof.
; PROPOSED NAME, graded WEAK and NOT APPLIED:
; `Dev10C_ChanSetEnvPair_ThenGateLow`.
; ⚠ The 0x7FFF mask is `and BC,(XIZ+0xec)` against a frame slot loaded with the
; literal 0x7FFF at 0xFB75C0 -- a masked constant, not an immediate, which is why a
; naive immediate scan does not see the gate bit being cleared here.
; ★ WAVE 20, 2026-09-03 -- THE REFUSAL STILL HOLDS, and not as a judgement
; call: this routine drives 0x0010C000, NOT 0x00104000.  Its register blocks belong
; to the OTHER device, whose numbering overlaps and means something else, and it
; contains no 0x00104000 literal at all.  So naming the L7A1429's registers cannot
; settle what it is FOR, and the label stays an address.  File header section 7.3.
; --------------------------------------------------------------------------
sub_FB7521:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FB7521  link XIZ,0xffec
	push	xhl                                   ; FB7525  push XHL
	pushw	de                                   ; FB7526  push DE
	push	xix                                   ; FB7527  push XIX
	ld	xix, (xiz+10)                           ; FB7528  ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+14)                            ; FB752B  ld HL,(XIZ+0x0e)
	ld	de, (xiz+8)                             ; FB752E  ld DE,(XIZ+0x08)
	ld	bc, de                                  ; FB7531  ld BC,DE
	add	bc, 0x800                              ; FB7533  add BC,0x0800
	ld	(xiz-2), bc                             ; FB7537  ld (XIZ+0xfe),BC
	ld	xwa, 0x10C000                           ; FB753A  ld XWA,0x0010c000
	ld	(xiz-6), xwa                            ; FB753F  ld (XIZ+0xfa),XWA
	ld	(xwa), bc                               ; FB7542  ld (XWA),BC
	extz	xhl                                   ; FB7544  extz XHL
	ld	bc, (xhl+57)                            ; FB7546  ld BC,(XHL+0x39)
	ld	(xiz-8), bc                             ; FB7549  ld (XIZ+0xf8),BC
	ld	xwa, (xiz-6)                            ; FB754C  ld XWA,(XIZ+0xfa)
	inc	2, xwa                                 ; FB754F  inc 2,XWA
	ld	(xiz-12), xwa                           ; FB7551  ld (XIZ+0xf4),XWA
	ld	(xwa), bc                               ; FB7554  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB7556  ld XBC,(XIZ+0xfa)
	ld	(xbc), de                               ; FB7559  ld (XBC),DE
	ld	xbc, (xiz-12)                           ; FB755B  ld XBC,(XIZ+0xf4)
	extpfx4 0xB1, 0x02, 0x00, 0x81             ; FB755E  ld (XBC),0x8100
	ld	bc, de                                  ; FB7562  ld BC,DE
	add	bc, 0x840                              ; FB7564  add BC,0x0840
	ld	(xiz-14), bc                            ; FB7568  ld (XIZ+0xf2),BC
	ld	xwa, (xiz-6)                            ; FB756B  ld XWA,(XIZ+0xfa)
	ld	(xwa), bc                               ; FB756E  ld (XWA),BC
	ld	bc, (xhl+59)                            ; FB7570  ld BC,(XHL+0x3b)
	ld	xwa, (xiz-12)                           ; FB7573  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB7576  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB7578  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-14)                            ; FB757B  ld WA,(XIZ+0xf2)
	ld	(xbc), wa                               ; FB757E  ld (XBC),WA
	ld	bc, (xhl+59)                            ; FB7580  ld BC,(XHL+0x3b)
	ld	xwa, (xiz-12)                           ; FB7583  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB7586  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB7588  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-14)                            ; FB758B  ld WA,(XIZ+0xf2)
	ld	(xbc), wa                               ; FB758E  ld (XBC),WA
	ld	bc, (xhl+59)                            ; FB7590  ld BC,(XHL+0x3b)
	ld	xwa, (xiz-12)                           ; FB7593  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB7596  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB7598  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-14)                            ; FB759B  ld WA,(XIZ+0xf2)
	ld	(xbc), wa                               ; FB759E  ld (XBC),WA
	ld	bc, (xhl+59)                            ; FB75A0  ld BC,(XHL+0x3b)
	ld	xwa, (xiz-12)                           ; FB75A3  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB75A6  ld (XWA),BC
	pushw	de                                   ; FB75A8  push DE
	calr (0xFB6E0A - 0xFB75AC)                 ; FB75A9  calr 0xfb6e0a
	ld	bc, de                                  ; FB75AC  ld BC,DE
	add	bc, 0x80                               ; FB75AE  add BC,0x0080
	ld	(xiz-16), bc                            ; FB75B2  ld (XIZ+0xf0),BC
	ld	xwa, (xiz-6)                            ; FB75B5  ld XWA,(XIZ+0xfa)
	ld	(xwa), bc                               ; FB75B8  ld (XWA),BC
	ld	bc, (xix+4)                             ; FB75BA  ld BC,(XIX+0x04)
	ld	(xiz-18), bc                            ; FB75BD  ld (XIZ+0xee),BC
	ldw (xiz-20), 0x7FFF                       ; FB75C0  ld (XIZ+0xec),0x7fff
	extpfx3 0x9E, 0xEC, 0xC1                   ; FB75C5  and BC,(XIZ+0xec)
	ld	xwa, (xiz-12)                           ; FB75C8  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB75CB  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB75CD  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-16)                            ; FB75D0  ld WA,(XIZ+0xf0)
	ld	(xbc), wa                               ; FB75D3  ld (XBC),WA
	ld	bc, (xix+4)                             ; FB75D5  ld BC,(XIX+0x04)
	extpfx3 0x9E, 0xEC, 0xC1                   ; FB75D8  and BC,(XIZ+0xec)
	ld	xwa, (xiz-12)                           ; FB75DB  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB75DE  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB75E0  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-16)                            ; FB75E3  ld WA,(XIZ+0xf0)
	ld	(xbc), wa                               ; FB75E6  ld (XBC),WA
	ld	bc, (xix+4)                             ; FB75E8  ld BC,(XIX+0x04)
	extpfx3 0x9E, 0xEC, 0xC1                   ; FB75EB  and BC,(XIZ+0xec)
	ld	xwa, (xiz-12)                           ; FB75EE  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB75F1  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB75F3  ld XBC,(XIZ+0xfa)
	ld	wa, (xiz-16)                            ; FB75F6  ld WA,(XIZ+0xf0)
	ld	(xbc), wa                               ; FB75F9  ld (XBC),WA
	ld	bc, (xix+4)                             ; FB75FB  ld BC,(XIX+0x04)
	extpfx3 0x9E, 0xEC, 0xC1                   ; FB75FE  and BC,(XIZ+0xec)
	ld	xwa, (xiz-12)                           ; FB7601  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB7604  ld (XWA),BC
	ld	xbc, (xiz-6)                            ; FB7606  ld XBC,(XIZ+0xfa)
	ld	(xbc), de                               ; FB7609  ld (XBC),DE
	ld	bc, (xhl+41)                            ; FB760B  ld BC,(XHL+0x29)
	ld	xwa, (xiz-12)                           ; FB760E  ld XWA,(XIZ+0xf4)
	ld	(xwa), bc                               ; FB7611  ld (XWA),BC
	ld	bc, (xix+4)                             ; FB7613  ld BC,(XIX+0x04)
	ld	hl, bc                                  ; FB7616  ld HL,BC
	extpfx3 0x9E, 0xEC, 0xC3                   ; FB7618  and HL,(XIZ+0xec)
	ldw	bc, 2                                  ; FB761B  ld BC,0x0002
	mul	xbc, xde                               ; FB761E  mul XBC,DE
	add	xbc, 0xD85B                            ; FB7620  add XBC,0x0000d85b
	ld	(xbc), hl                               ; FB7626  ld (XBC),HL
	popw	bc                                    ; FB7628  pop BC
	pop	xix                                    ; FB7629  pop XIX
	popw	de                                    ; FB762A  pop DE
	pop	xhl                                    ; FB762B  pop XHL
	unlk32 xiz                                 ; FB762C  unlk XIZ
	ret                                        ; FB762E  ret
; --------------------------------------------------------------------------
; sub_FB762F -- 0xFB762F..0xFB7714 (230 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFAC1BB in sub_FAC08D__FAC174
; Inputs:  frame `link XIZ,-10`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFB762F-0xFB7714
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; ★ WAVE 17, 2026-09-03 -- DECODED, and it is sub_FB7521's shorter twin.
; Arguments: (XIZ+0x08) = chan; (XIZ+0x0A) = HL, the same 16-bit record pointer.
; There is no struct argument and no gate write at all.  Writes, in order:
;     0xFB764A/59  register chan + 0x0800 = rec[+0x39]
;     0xFB765E/63  register chan + 0x0000 = 0x8100
;     0xFB7670/82  register chan + 0x0840 = rec[+0x3B]   ) EIGHT times, the value
;     ... 0xFB76F3/0xFB7700, eight (select, data) pairs  ) fetched afresh each time
;                                                          through `ld WA,(XHL+BC)`
;                                                          with BC = 0x3B in a frame
;                                                          slot (0xFB7672)
;     0xFB7705/0D  register chan + 0x0000 = rec[+0x29]
; Same three record fields, same 0x8100, same two register blocks as sub_FB7521.
; Both are reached from the same dispatcher, sub_FAC08D, which selects on bits 14..12
; of voice_record[+0x2D]: this one from 0xFAC1BB, inside the 0x2000 arm the
; `cp BC,0x2000 / jrl Z,0xFAC174` at 0xFAC0F6 enters, and sub_FB7521 from 0xFAC247,
; inside a different arm of the same routine.  The differences between the two are
; exactly: four repeats there against eight here, and the gate-low block that only
; sub_FB7521 has.
; PROPOSED NAME, graded WEAK and NOT APPLIED: `Dev10C_ChanSetEnvPair_NoGate`.
; ⚠ WHY THE REPEAT COUNT DIFFERS (4 vs 8, and 5 in sub_FB6F2C/sub_FB707E) IS NOT
; ESTABLISHED.  Four routines in this file re-issue one register several times with
; an unchanged value; a hold or settling time is the obvious reading and nothing in
; the image supports it.
; ★ WAVE 20, 2026-09-03 -- THE REFUSAL STILL HOLDS, and not as a judgement
; call: this routine drives 0x0010C000, NOT 0x00104000.  Its register blocks belong
; to the OTHER device, whose numbering overlaps and means something else, and it
; contains no 0x00104000 literal at all.  So naming the L7A1429's registers cannot
; settle what it is FOR, and the label stays an address.  File header section 7.3.
; --------------------------------------------------------------------------
sub_FB762F:
	link32 0xEE, 0x0C, 0xF6, 0xFF              ; FB762F  link XIZ,0xfff6
	push	xhl                                   ; FB7633  push XHL
	pushw	de                                   ; FB7634  push DE
	pushw	ix                                   ; FB7635  push IX
	ld	de, (xiz+8)                             ; FB7636  ld DE,(XIZ+0x08)
	ld	hl, (xiz+10)                            ; FB7639  ld HL,(XIZ+0x0a)
	ld	ix, de                                  ; FB763C  ld IX,DE
	add	ix, 0x800                              ; FB763E  add IX,0x0800
	ld	xbc, 0x10C000                           ; FB7642  ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7647  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                               ; FB764A  ld (XBC),IX
	extz	xhl                                   ; FB764C  extz XHL
	ld	ix, (xhl+57)                            ; FB764E  ld IX,(XHL+0x39)
	ld	xbc, (xiz-4)                            ; FB7651  ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7654  inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7656  ld (XIZ+0xf8),XBC
	ld	(xbc), ix                               ; FB7659  ld (XBC),IX
	ld	xbc, (xiz-4)                            ; FB765B  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                               ; FB765E  ld (XBC),DE
	ld	xbc, (xiz-8)                            ; FB7660  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x00, 0x81             ; FB7663  ld (XBC),0x8100
	ld	ix, de                                  ; FB7667  ld IX,DE
	add	ix, 0x840                              ; FB7669  add IX,0x0840
	ld	xbc, (xiz-4)                            ; FB766D  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB7670  ld (XBC),IX
	ldw (xiz-10), 0x003B                       ; FB7672  ld (XIZ+0xf6),0x003b
	ld	bc, (xiz-10)                            ; FB7677  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB767A  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB767F  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB7682  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB7684  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB7687  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB7689  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB768C  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB7691  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB7694  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB7696  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB7699  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB769B  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB769E  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB76A3  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB76A6  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB76A8  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB76AB  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB76AD  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB76B0  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB76B5  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB76B8  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB76BA  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB76BD  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB76BF  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB76C2  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB76C7  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB76CA  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB76CC  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB76CF  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB76D1  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB76D4  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB76D9  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB76DC  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB76DE  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB76E1  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB76E3  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB76E6  ld WA,(XHL+BC)
	ld	xiy, (xiz-8)                            ; FB76EB  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                               ; FB76EE  ld (XIY),WA
	ld	xbc, (xiz-4)                            ; FB76F0  ld XBC,(XIZ+0xfc)
	ld	(xbc), ix                               ; FB76F3  ld (XBC),IX
	ld	bc, (xiz-10)                            ; FB76F5  ld BC,(XIZ+0xf6)
	extpfx5 0xD3, 0x07, 0xEC, 0xE4, 0x20       ; FB76F8  ld WA,(XHL+BC)
	ld	xbc, (xiz-8)                            ; FB76FD  ld XBC,(XIZ+0xf8)
	ld	(xbc), wa                               ; FB7700  ld (XBC),WA
	ld	xbc, (xiz-4)                            ; FB7702  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                               ; FB7705  ld (XBC),DE
	ld	bc, (xhl+41)                            ; FB7707  ld BC,(XHL+0x29)
	ld	xwa, (xiz-8)                            ; FB770A  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB770D  ld (XWA),BC
	popw	ix                                    ; FB770F  pop IX
	popw	de                                    ; FB7710  pop DE
	pop	xhl                                    ; FB7711  pop XHL
	unlk32 xiz                                 ; FB7712  unlk XIZ
	ret                                        ; FB7714  ret

; ==============================================================================
; 0xFB7715-0xFB7B62 -- the driver for the SECOND register device, 0x00104000,
;                      and the tone generator's thirteen GLOBAL registers
;                      9 routines, 1,102 bytes
; ==============================================================================
;
; This block sits immediately below the second tone-generator driver and is part
; of the same module.  It settles two things the memory map could only gesture at.
;
; ★ 0x00104000 IS AN ADDRESS/DATA PAIR OF THE SAME KIND AS 0x0010C000, WITH THE
; SAME `block * 0x40 + channel` REGISTER MAP.  Dev104_WriteAllChanRegs below writes
; nineteen registers of one channel in one unrolled run, blocks 0x0000 through
; 0x0480 in 0x40 steps, taking the value for block k*0x40 from word 2*k of a
; struct.  Nothing is inferred: the run is exhaustive and the field offset is a
; linear function of the block index, checked over all nineteen by
; `python3 notes/prom_c_tg_regmap.py --dev104` (which tests the LAST pair, not
; only the first).  prom_c loads the literal 0x00104000 into a pointer register
; nine times and every one of them is in this block or in Dev10C_ResetAllChannels.
;
; ★ THE TONE GENERATOR HAS GLOBAL REGISTERS, AND THERE ARE THIRTEEN OF THEM.
; Dev10C_WriteGlobalRegs takes no channel argument at all -- every register number in
; it is an immediate -- and writes 0x0200-0x0205, 0x0C00-0x0C05 and 0x0E00 from
; thirteen consecutive words.  Its argument is therefore 26 bytes, which is
; exactly the gap between the two ROM addresses Dev10C_ResetAllChannels hands out
; (0xFE12B5 and 0xFE12CF).  The register-number ARITHMETIC also agrees with the
; other bank: Dev10C_WriteReg_0201 at 0xFAD12A writes 0x0201 on its own.
;
; ⚠ TWO ROUTINES HERE HAVE NO CALLER: 0xFB796E and 0xFB79D0 are reached by no
; absolute `call` and no `calr` in prom_c.  Same caveat as always -- a call
; through a register operand would not be found.
;
; ⚠ NOTHING HERE SAYS WHAT ANY REGISTER DOES, and no name below claims one.  The
; names encode the register block and the struct field, both read off the
; instructions.
;
; Transcribed the same way as the block below it:
; `notes/llvm_roundtrip_force.py c 0xFB7715 0x44E` proved the listing rebuilds
; these bytes, and the 31 instructions it left as `.byte` were each replaced with
; a mnemonic re-encoded by `llvm-mc --show-encoding` and accepted only on an exact
; byte match.  No `.byte` and no `extpfx` remains in this block.

; --------------------------------------------------------------------------
; ★★ Dev10C_WriteGlobalRegs -- the THIRTEEN GLOBAL registers of the 0x0010C000 device,
; written from thirteen consecutive words of one struct.
;
;     register 0x0200 0x0201 0x0202 0x0203 0x0204 0x0205  <- arg0->0x00 .. 0x0A
;     register 0x0C00 0x0C01 0x0C02 0x0C03 0x0C04 0x0C05  <- arg0->0x0C .. 0x16
;     register 0x0E00                                     <- arg0->0x18
;
; Called from: 0xFB80EE, inside Dev10C_ResetAllChannels.
; Inputs:  (XIZ+8) = a pointer to 13 words -- that site passes the ROM image at
;          0xFE12B5 (Dev10C_GlobalRegs_ResetImage, decoded below).  ⚠ That address
;          is DATA, not a call site; it is stated here rather than in
;          `Called from:` because notes/prom_c_audit_callsites.py harvests every
;          0xXXXXXX in that paragraph and cannot tell prose from a citation.
;          ★ THERE IS NO CHANNEL ARGUMENT and
;          no `add` anywhere in the routine -- every register number is an
;          immediate.  That is what makes these registers GLOBAL rather than
;          per-channel, and it is read off the instruction, not assumed.
; Outputs: 13 16-bit writes.
; Evidence: thirteen `ldw (xbc),0xNNNN` immediates, each followed by a fetch from
;          (XIX + 2k) and a store through the +2 pointer held in the frame.
; ★ THE ARGUMENT'S SIZE CHECKS OUT AGAINST THE ROM.  13 words = 26 = 0x1A bytes,
;   and Dev10C_ResetAllChannels passes 0xFE12B5 while the NEXT ROM block it uses
;   starts at 0xFE12CF.  0xFE12CF - 0xFE12B5 = 0x1A exactly.  Two independent
;   facts -- this routine's field count and the spacing of two ROM addresses in
;   another routine -- give the same size.
; ★ AND IT AGREES WITH THE OTHER BANK.  Dev10C_WriteReg_0201 at 0xFAD12A writes
;   register 0x0201 alone, with a value the caller builds by masking with 0x0F9F.
;   0x0201 is the second of the six registers here, so both banks agree that
;   0x0200-0x0205 is one six-register control block.
; Unknown:  what any of the thirteen do.
; --------------------------------------------------------------------------
Dev10C_WriteGlobalRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7715  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7719  2b                push HL
	push	xix                                   ; FB771A  3c                push XIX
	ld	xix, (xiz+8)                            ; FB771B  ae 08 24          ld XIX,(XIZ+0x08)
	ld	xbc, 0x0010C000                         ; FB771E  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7723  be fc 61          ld (XIZ+0xfc),XBC
	ldw (xbc), 0x0200                          ; FB7726  b1 02 00 02       ld (XBC),0x0200
	ld	hl, (xix)                               ; FB772A  94 23             ld HL,(XIX)
	ld	xbc, (xiz-4)                            ; FB772C  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB772F  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7731  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), hl                               ; FB7734  b1 53             ld (XBC),HL
	ld	xbc, (xiz-4)                            ; FB7736  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0201                          ; FB7739  b1 02 01 02       ld (XBC),0x0201
	ld	bc, (xix+2)                             ; FB773D  9c 02 21          ld BC,(XIX+0x02)
	ld	xwa, (xiz-8)                            ; FB7740  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7743  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7745  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0202                          ; FB7748  b1 02 02 02       ld (XBC),0x0202
	ld	bc, (xix+4)                             ; FB774C  9c 04 21          ld BC,(XIX+0x04)
	ld	xwa, (xiz-8)                            ; FB774F  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7752  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7754  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0203                          ; FB7757  b1 02 03 02       ld (XBC),0x0203
	ld	bc, (xix+6)                             ; FB775B  9c 06 21          ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                            ; FB775E  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7761  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7763  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0204                          ; FB7766  b1 02 04 02       ld (XBC),0x0204
	ld	bc, (xix+8)                             ; FB776A  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB776D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7770  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7772  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0205                          ; FB7775  b1 02 05 02       ld (XBC),0x0205
	ld	bc, (xix+10)                            ; FB7779  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB777C  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB777F  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7781  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C00                          ; FB7784  b1 02 00 0c       ld (XBC),0x0c00
	ld	bc, (xix+12)                            ; FB7788  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB778B  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB778E  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7790  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C01                          ; FB7793  b1 02 01 0c       ld (XBC),0x0c01
	ld	bc, (xix+14)                            ; FB7797  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB779A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB779D  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB779F  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C02                          ; FB77A2  b1 02 02 0c       ld (XBC),0x0c02
	ld	bc, (xix+16)                            ; FB77A6  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB77A9  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77AC  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77AE  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C03                          ; FB77B1  b1 02 03 0c       ld (XBC),0x0c03
	ld	bc, (xix+18)                            ; FB77B5  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB77B8  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77BB  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77BD  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C04                          ; FB77C0  b1 02 04 0c       ld (XBC),0x0c04
	ld	bc, (xix+20)                            ; FB77C4  9c 14 21          ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                            ; FB77C7  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77CA  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77CC  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C05                          ; FB77CF  b1 02 05 0c       ld (XBC),0x0c05
	ld	bc, (xix+22)                            ; FB77D3  9c 16 21          ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                            ; FB77D6  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77D9  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77DB  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0E00                          ; FB77DE  b1 02 00 0e       ld (XBC),0x0e00
	ld	bc, (xix+24)                            ; FB77E2  9c 18 21          ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                            ; FB77E5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77E8  b0 51             ld (XWA),BC
	pop	xix                                    ; FB77EA  5c                pop XIX
	popw	hl                                    ; FB77EB  4b                pop HL
	unlk32 xiz                                 ; FB77EC  ee 0d             unlk XIZ
	ret                                        ; FB77EE  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev104_WriteAllChanRegs -- the COMPLETE per-channel register map of the SECOND
; device, 0x00104000, in one unrolled routine.
;
;     register (chan + k*0x40) = arg1->(2*k)      for k = 1,2,3 ... 0x12
;     register (chan + 0)      = arg1->0x00       written LAST
;
; so nineteen 16-bit registers per channel, fed from nineteen consecutive words
; of the staging struct, with the field offset exactly twice the block index.
; The mapping is not eyeballed: `python3 notes/prom_c_tg_regmap.py --dev104`
; re-derives it from the ROM and checks the LAST pair (0x0480 <- 0x24) as well as
; the first, then asserts field == 2 * (base / 0x40) for every one of the 19.
;
; ★ 0x00104000 THEREFORE HAS THE SAME SHAPE AS 0x0010C000: a 16-bit register
; number at +0x00, that register's 16-bit value at +0x02, and register numbers of
; the form `parameter_block * 0x40 + channel`.  notes/FINDINGS-memory-map.md had
; the address/data pair for this device from a single site; this is the whole map.
;
; Called from: 0xFAC3EC, 0xFB0B71, 0xFB1F51, 0xFB2876, 0xFB2F4B, 0xFB3708,
;              0xFB3815, 0xFC3ECD and 0xFB81A4 (in Dev10C_ResetAllChannels).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = struct pointer (kept in XIX).
; Unknown:  what any of the nineteen parameters is.  Note that block 0 is written
;           LAST, after all the others -- the shape of a "commit" register, but
;           nothing here establishes that.
; --------------------------------------------------------------------------
Dev104_WriteAllChanRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB77EF  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB77F3  2b                push HL
	pushw	de                                   ; FB77F4  2a                push DE
	push	xix                                   ; FB77F5  3c                push XIX
	ld	xix, (xiz+10)                           ; FB77F6  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB77F9  9e 08 23          ld HL,(XIZ+0x08)
	ld	de, hl                                  ; FB77FC  db 8a             ld DE,HL
	add	de, DEV104_MAIN_TUNE                   ; FB77FE  da c8 40 00       add DE,0x0040
	ld	xbc, DEV104_BASE                        ; FB7802  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7807  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB780A  b1 52             ld (XBC),DE
	ld	de, (xix+2)                             ; FB780C  9c 02 22          ld DE,(XIX+0x02)
	ld	xbc, (xiz-4)                            ; FB780F  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7812  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7814  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7817  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7819  db 89             ld BC,HL
	add	bc, DEV104_SUB_TUNE                    ; FB781B  d9 c8 80 00       add BC,0x0080
	ld	xwa, (xiz-4)                            ; FB781F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7822  b0 51             ld (XWA),BC
	ld	bc, (xix+4)                             ; FB7824  9c 04 21          ld BC,(XIX+0x04)
	ld	xwa, (xiz-8)                            ; FB7827  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB782A  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB782C  db 89             ld BC,HL
	add	bc, DEV104_POSITION                    ; FB782E  d9 c8 c0 00       add BC,0x00c0
	ld	xwa, (xiz-4)                            ; FB7832  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7835  b0 51             ld (XWA),BC
	ld	bc, (xix+6)                             ; FB7837  9c 06 21          ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                            ; FB783A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB783D  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB783F  db 89             ld BC,HL
	add	bc, DEV104_BLK_0100                    ; FB7841  d9 c8 00 01       add BC,0x0100
	ld	xwa, (xiz-4)                            ; FB7845  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7848  b0 51             ld (XWA),BC
	ld	bc, (xix+8)                             ; FB784A  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB784D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7850  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7852  db 89             ld BC,HL
	add	bc, DEV104_MAIN_FITTING_DECAY          ; FB7854  d9 c8 40 01       add BC,0x0140
	ld	xwa, (xiz-4)                            ; FB7858  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB785B  b0 51             ld (XWA),BC
	ld	bc, (xix+10)                            ; FB785D  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB7860  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7863  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7865  db 89             ld BC,HL
	add	bc, DEV104_SUB_FITTING_DECAY           ; FB7867  d9 c8 80 01       add BC,0x0180
	ld	xwa, (xiz-4)                            ; FB786B  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB786E  b0 51             ld (XWA),BC
	ld	bc, (xix+12)                            ; FB7870  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB7873  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7876  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7878  db 89             ld BC,HL
	add	bc, DEV104_MAIN_FITTING_RISE           ; FB787A  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB787E  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7881  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB7883  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB7886  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7889  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB788B  db 89             ld BC,HL
	add	bc, DEV104_SUB_FITTING_RISE            ; FB788D  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB7891  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7894  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB7896  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB7899  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB789C  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB789E  db 89             ld BC,HL
	add	bc, DEV104_BLK_0240                    ; FB78A0  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB78A4  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78A7  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB78A9  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB78AC  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78AF  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78B1  db 89             ld BC,HL
	add	bc, DEV104_SUB_GAIN                    ; FB78B3  d9 c8 80 02       add BC,0x0280
	ld	xwa, (xiz-4)                            ; FB78B7  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78BA  b0 51             ld (XWA),BC
	ld	bc, (xix+20)                            ; FB78BC  9c 14 21          ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                            ; FB78BF  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78C2  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78C4  db 89             ld BC,HL
	add	bc, DEV104_BLK_02C0                    ; FB78C6  d9 c8 c0 02       add BC,0x02c0
	ld	xwa, (xiz-4)                            ; FB78CA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78CD  b0 51             ld (XWA),BC
	ld	bc, (xix+22)                            ; FB78CF  9c 16 21          ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                            ; FB78D2  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78D5  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78D7  db 89             ld BC,HL
	add	bc, DEV104_BLK_0300                    ; FB78D9  d9 c8 00 03       add BC,0x0300
	ld	xwa, (xiz-4)                            ; FB78DD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78E0  b0 51             ld (XWA),BC
	ld	bc, (xix+24)                            ; FB78E2  9c 18 21          ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                            ; FB78E5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78E8  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78EA  db 89             ld BC,HL
	add	bc, DEV104_MAIN_MUTING_Q13             ; FB78EC  d9 c8 40 03       add BC,0x0340
	ld	xwa, (xiz-4)                            ; FB78F0  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78F3  b0 51             ld (XWA),BC
	ld	bc, (xix+26)                            ; FB78F5  9c 1a 21          ld BC,(XIX+0x1a)
	ld	xwa, (xiz-8)                            ; FB78F8  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78FB  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78FD  db 89             ld BC,HL
	add	bc, DEV104_SUB_MUTING_Q13              ; FB78FF  d9 c8 80 03       add BC,0x0380
	ld	xwa, (xiz-4)                            ; FB7903  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7906  b0 51             ld (XWA),BC
	ld	bc, (xix+28)                            ; FB7908  9c 1c 21          ld BC,(XIX+0x1c)
	ld	xwa, (xiz-8)                            ; FB790B  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB790E  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7910  db 89             ld BC,HL
	add	bc, DEV104_BLK_03C0                    ; FB7912  d9 c8 c0 03       add BC,0x03c0
	ld	xwa, (xiz-4)                            ; FB7916  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7919  b0 51             ld (XWA),BC
	ld	bc, (xix+30)                            ; FB791B  9c 1e 21          ld BC,(XIX+0x1e)
	ld	xwa, (xiz-8)                            ; FB791E  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7921  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7923  db 89             ld BC,HL
	add	bc, DEV104_MAIN_MUTING_Q16             ; FB7925  d9 c8 00 04       add BC,0x0400
	ld	xwa, (xiz-4)                            ; FB7929  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB792C  b0 51             ld (XWA),BC
	ld	bc, (xix+32)                            ; FB792E  9c 20 21          ld BC,(XIX+0x20)
	ld	xwa, (xiz-8)                            ; FB7931  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7934  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7936  db 89             ld BC,HL
	add	bc, DEV104_SUB_MUTING_Q16              ; FB7938  d9 c8 40 04       add BC,0x0440
	ld	xwa, (xiz-4)                            ; FB793C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB793F  b0 51             ld (XWA),BC
	ld	bc, (xix+34)                            ; FB7941  9c 22 21          ld BC,(XIX+0x22)
	ld	xwa, (xiz-8)                            ; FB7944  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7947  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7949  db 89             ld BC,HL
	add	bc, DEV104_BLK_0480                    ; FB794B  d9 c8 80 04       add BC,0x0480
	ld	xwa, (xiz-4)                            ; FB794F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7952  b0 51             ld (XWA),BC
	ld	bc, (xix+36)                            ; FB7954  9c 24 21          ld BC,(XIX+0x24)
	ld	xwa, (xiz-8)                            ; FB7957  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB795A  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB795C  ae fc 21          ld XBC,(XIZ+0xfc)
	ld	(xbc), hl                               ; FB795F  b1 53             ld (XBC),HL
	ld	bc, (xix)                               ; FB7961  94 21             ld BC,(XIX)
	ld	xwa, (xiz-8)                            ; FB7963  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7966  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7968  5c                pop XIX
	popw	de                                    ; FB7969  4a                pop DE
	popw	hl                                    ; FB796A  4b                pop HL
	unlk32 xiz                                 ; FB796B  ee 0d             unlk XIZ
	ret                                        ; FB796D  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_01C0_0200_0240 -- register (chan+0) from struct field 0x00
; FIRST, then (chan+0x01C0), (chan+0x0200), (chan+0x0240) from fields 0x0E, 0x10,
; 0x12.
; ⚠ CORRECTION, ROUND 4.  This header used to end "... then register (chan+0) from
; field 0x00 last -- the same trailing write Dev104_WriteAllChanRegs ends with".
; The (chan+0) write is FIRST here, at 0xFB7983, before any of the other three.
; It IS last in Dev104_WriteAllChanRegs (0xFB795F, its final write), so the
; comparison was backwards, not merely mis-ordered.
; Called from: NOT FOUND (no absolute `call`, no `calr`; notes/prom_c_xrefs.py).
; Evidence: `python3 notes/prom_c_tg_chanmap.py 0xFB796E 0x62 --dev 0x00104000
;          --pairs` walks the routine and prints the four writes in EXECUTION
;          order: 0xFB7983 chan+0 <- field 0x00, 0xFB799A chan+0x01C0 <- 0x0E,
;          0xFB79AD chan+0x0200 <- 0x10, 0xFB79C0 chan+0x0240 <- 0x12.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_01C0_0200_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB796E  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7972  2b                push HL
	pushw	de                                   ; FB7973  2a                push DE
	push	xix                                   ; FB7974  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7975  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7978  9e 08 23          ld HL,(XIZ+0x08)
	ld	xbc, DEV104_BASE                        ; FB797B  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7980  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7983  b1 53             ld (XBC),HL
	ld	de, (xix)                               ; FB7985  94 22             ld DE,(XIX)
	ld	xbc, (xiz-4)                            ; FB7987  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB798A  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB798C  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB798F  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7991  db 89             ld BC,HL
	add	bc, DEV104_MAIN_FITTING_RISE           ; FB7993  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB7997  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB799A  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB799C  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB799F  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79A2  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB79A4  db 89             ld BC,HL
	add	bc, DEV104_SUB_FITTING_RISE            ; FB79A6  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB79AA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79AD  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB79AF  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB79B2  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79B5  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB79B7  db 89             ld BC,HL
	add	bc, DEV104_BLK_0240                    ; FB79B9  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB79BD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79C0  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB79C2  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB79C5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79C8  b0 51             ld (XWA),BC
	pop	xix                                    ; FB79CA  5c                pop XIX
	popw	de                                    ; FB79CB  4a                pop DE
	popw	hl                                    ; FB79CC  4b                pop HL
	unlk32 xiz                                 ; FB79CD  ee 0d             unlk XIZ
	ret                                        ; FB79CF  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_0140_to_0240 -- register (chan+0) from struct field 0x00
; FIRST, then (chan+0x0140), (chan+0x0180), (chan+0x01C0), (chan+0x0200),
; (chan+0x0240) from fields 0x0A, 0x0C, 0x0E, 0x10, 0x12.
; ⚠ CORRECTION, ROUND 4: this header used to say the (chan+0) write came LAST.
; It is the FIRST of the six, at 0xFB79E5.  Same defect as the header above.
; Called from: NOT FOUND -- `notes/prom_c_xrefs.py 0xFB79D0 --no-window` finds no
;          literal and no calr; short PC-relative forms are not searched.
; Evidence: `ld XBC,0x00104000` at 0xFB79DD is the device, and each register is the
;          select/data pair this bank's block comment establishes, with the
;          register number formed by `add BC,<K>` on the channel argument.  The
;          order and the field numbers are read off the ROM, not off this header:
;          `python3 notes/prom_c_tg_chanmap.py 0xFB79D0 0x88 --dev 0x00104000
;          --pairs` walks the routine and prints, in EXECUTION order,
;            0xFB79E5 chan+0      <- field 0x00     0xFB7A22 chan+0x01C0 <- 0x0E
;            0xFB79FC chan+0x0140 <- field 0x0A     0xFB7A35 chan+0x0200 <- 0x10
;            0xFB7A0F chan+0x0180 <- field 0x0C     0xFB7A48 chan+0x0240 <- 0x12
;          ⚠ 0x88 is the routine's real length (0xFB79D0-0xFB7A57); an earlier
;          draft of this line passed 0x66 and therefore saw only four of the six
;          writes.  Always pass the length to the `ret`.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_0140_to_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB79D0  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB79D4  2b                push HL
	pushw	de                                   ; FB79D5  2a                push DE
	push	xix                                   ; FB79D6  3c                push XIX
	ld	xix, (xiz+10)                           ; FB79D7  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB79DA  9e 08 23          ld HL,(XIZ+0x08)
	ld	xbc, DEV104_BASE                        ; FB79DD  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB79E2  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB79E5  b1 53             ld (XBC),HL
	ld	de, (xix)                               ; FB79E7  94 22             ld DE,(XIX)
	ld	xbc, (xiz-4)                            ; FB79E9  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB79EC  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB79EE  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB79F1  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB79F3  db 89             ld BC,HL
	add	bc, DEV104_MAIN_FITTING_DECAY          ; FB79F5  d9 c8 40 01       add BC,0x0140
	ld	xwa, (xiz-4)                            ; FB79F9  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79FC  b0 51             ld (XWA),BC
	ld	bc, (xix+10)                            ; FB79FE  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB7A01  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A04  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A06  db 89             ld BC,HL
	add	bc, DEV104_SUB_FITTING_DECAY           ; FB7A08  d9 c8 80 01       add BC,0x0180
	ld	xwa, (xiz-4)                            ; FB7A0C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A0F  b0 51             ld (XWA),BC
	ld	bc, (xix+12)                            ; FB7A11  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB7A14  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A17  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A19  db 89             ld BC,HL
	add	bc, DEV104_MAIN_FITTING_RISE           ; FB7A1B  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB7A1F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A22  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB7A24  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB7A27  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A2A  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A2C  db 89             ld BC,HL
	add	bc, DEV104_SUB_FITTING_RISE            ; FB7A2E  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB7A32  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A35  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB7A37  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB7A3A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A3D  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A3F  db 89             ld BC,HL
	add	bc, DEV104_BLK_0240                    ; FB7A41  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB7A45  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A48  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB7A4A  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB7A4D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A50  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7A52  5c                pop XIX
	popw	de                                    ; FB7A53  4a                pop DE
	popw	hl                                    ; FB7A54  4b                pop HL
	unlk32 xiz                                 ; FB7A55  ee 0d             unlk XIZ
	ret                                        ; FB7A57  0e                ret
; --------------------------------------------------------------------------
; Dev104_WriteChanReg0 -- register (chan + 0) of 0x00104000 = the first word of the
; struct.  The smallest routine in the block, and the one that isolates the
; (chan+0) write on its own.
; ⚠ CORRECTION, ROUND 4: this header used to call that write "the trailing write
; the two routines above and Dev104_WriteAllChanRegs all end with".  Only
; Dev104_WriteAllChanRegs ends with it (0xFB795F).  In the two routines above it
; is the FIRST write, not the last -- measured with
; `notes/prom_c_tg_chanmap.py ... --pairs`, which reports execution order.
; Called from: 0xFAC3D7, 0xFB36FB, 0xFB3808, 0xFB3927, 0xFB3A72, 0xFB3B90,
;              0xFC3EA1 and 0xFB826B (in Dev10C_ResetAllChannels).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = struct pointer.
; Evidence: `ld (xix),bc` with BC = the raw argument (no `add`), then
;          `ld wa,(xbc)` / `ld (xix+2),wa` -- field 0x00.
; --------------------------------------------------------------------------
Dev104_WriteChanReg0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7A58  ee 0c 00 00       link XIZ,0x0000
	push	xix                                   ; FB7A5C  3c                push XIX
	ld	xix, DEV104_BASE                        ; FB7A5D  44 00 40 10 00    ld XIX,0x00104000
	ld	bc, (xiz+8)                             ; FB7A62  9e 08 21          ld BC,(XIZ+0x08)
	ld	(xix), bc                               ; FB7A65  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7A67  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc)                               ; FB7A6A  91 20             ld WA,(XBC)
	ld	(xix+2), wa                             ; FB7A6C  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7A6F  5c                pop XIX
	unlk32 xiz                                 ; FB7A70  ee 0d             unlk XIZ
	ret                                        ; FB7A72  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_00C0_0100_0240 -- registers (chan+0x00C0), (chan+0x0100),
; (chan+0x0240) from fields 0x06, 0x08, 0x12.
; Called from: 0xFACB85, 0xFAEB56, 0xFAEBC2.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7A82  `add rr,0x00C0` forms the select value chan+0x00C0,
;          0xFB7A90  `ld rr,(XIX+0x06)` fetches the staging word it is
;                    given -- struct offset +0x06.
;          0xFB7A9F  `add rr,0x0100` forms the select value chan+0x0100,
;          0xFB7AA8  `ld rr,(XIX+0x08)` fetches the staging word it is
;                    given -- struct offset +0x08.
;          0xFB7AB2  `add rr,0x0240` forms the select value chan+0x0240,
;          0xFB7ABB  `ld rr,(XIX+0x12)` fetches the staging word it is
;                    given -- struct offset +0x12.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_00C0_0100_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7A73  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7A77  2b                push HL
	pushw	de                                   ; FB7A78  2a                push DE
	push	xix                                   ; FB7A79  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7A7A  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7A7D  9e 08 23          ld HL,(XIZ+0x08)
	ld	de, hl                                  ; FB7A80  db 8a             ld DE,HL
	add	de, DEV104_POSITION                    ; FB7A82  da c8 c0 00       add DE,0x00c0
	ld	xbc, DEV104_BASE                        ; FB7A86  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7A8B  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7A8E  b1 52             ld (XBC),DE
	ld	de, (xix+6)                             ; FB7A90  9c 06 22          ld DE,(XIX+0x06)
	ld	xbc, (xiz-4)                            ; FB7A93  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7A96  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7A98  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7A9B  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7A9D  db 89             ld BC,HL
	add	bc, DEV104_BLK_0100                    ; FB7A9F  d9 c8 00 01       add BC,0x0100
	ld	xwa, (xiz-4)                            ; FB7AA3  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7AA6  b0 51             ld (XWA),BC
	ld	bc, (xix+8)                             ; FB7AA8  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB7AAB  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7AAE  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7AB0  db 89             ld BC,HL
	add	bc, DEV104_BLK_0240                    ; FB7AB2  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB7AB6  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7AB9  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB7ABB  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB7ABE  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7AC1  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7AC3  5c                pop XIX
	popw	de                                    ; FB7AC4  4a                pop DE
	popw	hl                                    ; FB7AC5  4b                pop HL
	unlk32 xiz                                 ; FB7AC6  ee 0d             unlk XIZ
	ret                                        ; FB7AC8  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_00C0_0100 -- registers (chan+0x00C0), (chan+0x0100) from fields
; 0x06, 0x08.
; Called from: 0xFACB96.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7AD2  `add rr,0x00C0` forms the select value chan+0x00C0,
;          0xFB7AE0  `ld rr,(XBC+0x06)` fetches the staging word it is
;                    given -- struct offset +0x06.
;          0xFB7AEF  `add rr,0x0100` forms the select value chan+0x0100,
;          0xFB7AF8  `ld rr,(XBC+0x08)` fetches the staging word it is
;                    given -- struct offset +0x08.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_00C0_0100:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7AC9  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7ACD  2b                push HL
	push	xix                                   ; FB7ACE  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7ACF  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, DEV104_POSITION                    ; FB7AD2  db c8 c0 00       add HL,0x00c0
	ld	xix, DEV104_BASE                        ; FB7AD6  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7ADB  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7ADD  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+6)                             ; FB7AE0  99 06 23          ld HL,(XBC+0x06)
	ld	xwa, xix                                ; FB7AE3  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7AE5  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7AE7  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7AEA  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7AEC  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, DEV104_BLK_0100                    ; FB7AEF  d9 c8 00 01       add BC,0x0100
	ld	(xix), bc                               ; FB7AF3  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7AF5  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+8)                             ; FB7AF8  99 08 20          ld WA,(XBC+0x08)
	ld	xiy, (xiz-4)                            ; FB7AFB  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7AFE  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B00  5c                pop XIX
	popw	hl                                    ; FB7B01  4b                pop HL
	unlk32 xiz                                 ; FB7B02  ee 0d             unlk XIZ
	ret                                        ; FB7B04  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_0140_0180 -- registers (chan+0x0140), (chan+0x0180) from fields
; 0x0A, 0x0C.
; Called from: 0xFB373A, 0xFB3847, 0xFB39D1, 0xFB3AD9, 0xFB3BF2.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7B0E  `add rr,0x0140` forms the select value chan+0x0140,
;          0xFB7B1C  `ld rr,(XBC+0x0A)` fetches the staging word it is
;                    given -- struct offset +0x0A.
;          0xFB7B2B  `add rr,0x0180` forms the select value chan+0x0180,
;          0xFB7B34  `ld rr,(XBC+0x0C)` fetches the staging word it is
;                    given -- struct offset +0x0C.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_0140_0180:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7B05  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7B09  2b                push HL
	push	xix                                   ; FB7B0A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B0B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, DEV104_MAIN_FITTING_DECAY          ; FB7B0E  db c8 40 01       add HL,0x0140
	ld	xix, DEV104_BASE                        ; FB7B12  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7B17  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B19  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+10)                            ; FB7B1C  99 0a 23          ld HL,(XBC+0x0a)
	ld	xwa, xix                                ; FB7B1F  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7B21  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7B23  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7B26  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7B28  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, DEV104_SUB_FITTING_DECAY           ; FB7B2B  d9 c8 80 01       add BC,0x0180
	ld	(xix), bc                               ; FB7B2F  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7B31  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+12)                            ; FB7B34  99 0c 20          ld WA,(XBC+0x0c)
	ld	xiy, (xiz-4)                            ; FB7B37  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7B3A  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B3C  5c                pop XIX
	popw	hl                                    ; FB7B3D  4b                pop HL
	unlk32 xiz                                 ; FB7B3E  ee 0d             unlk XIZ
	ret                                        ; FB7B40  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanReg_0280 -- register (chan+0x0280) from field 0x14.
; Called from: 0xFAED24.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7B4A  `add rr,0x0280` forms the select value chan+0x0280,
;          0xFB7B58  `ld rr,(XBC+0x14)` fetches the staging word it is
;                    given -- struct offset +0x14.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev104_SetChanReg_0280:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7B41  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7B45  2b                push HL
	push	xix                                   ; FB7B46  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B47  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, DEV104_SUB_GAIN                    ; FB7B4A  db c8 80 02       add HL,0x0280
	ld	xix, DEV104_BASE                        ; FB7B4E  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7B53  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B55  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+20)                            ; FB7B58  99 14 20          ld WA,(XBC+0x14)
	ld	(xix+2), wa                             ; FB7B5B  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7B5E  5c                pop XIX
	popw	hl                                    ; FB7B5F  4b                pop HL
	unlk32 xiz                                 ; FB7B60  ee 0d             unlk XIZ
	ret                                        ; FB7B62  0e                ret


; ==============================================================================
; 0xFB7B63-0xFB828D -- the SECOND tone-generator driver, and the power-on sweep
;                      22 routines, 1,835 bytes
; ==============================================================================
;
; The same device, 0x0010C000, driven by a second copy of the accessor family --
; `python3 notes/prom_c_tg_regmap.py --dups` shows 13 of the 17 routines in the
; 0xFACE67 bank occur again, byte for byte, between 0xFB7016 and 0xFB7FCE.  This
; block is the largest contiguous stretch of that second driver.  It is worth
; converting on its own account because it contains three things the first bank
; does not:
;
;   * the BIT-15 STROBE.  Six routines write a gate register with bit 15 set and
;     then write the SAME register again with bit 15 cleared (`res 15`), loading a
;     companion register in between.  That is the only place in either bank where
;     one routine writes one register twice.
;   * the THREE-SLOT structure.  The gate/value pairs come in three parallel sets:
;
;         slot   gate register   gate field   value register   value field
;           1      chan+0x0540      0x3A        chan+0x01C0        0x38
;           2      chan+0x0580      0x3C        chan+0x0600        0x40
;           3      chan+0x05C0      0x3E        chan+0x0640        0x42
;
;     ⚠ the gates are a clean 0x40 ladder; the VALUE registers are not -- slot 1's
;     is in block 7 and slots 2 and 3 are in blocks 0x18 and 0x19.  Stated as read.
;   * ★★ THE EXPLANATION OF THE `chan >= 0x40` SPLIT.  Six routines across the two
;     banks branch on `cp hl,0x0040`.  The high arm is NOT a different parameter:
;     its base is exactly 0x40 below the base an unconditional routine uses for the
;     same staging field, and the channel argument already carries that 0x40, so
;     0x0580 + (0x40+k) = 0x05C0 + k -- slot 3's register for channel k.  Every
;     port write on every arm of all six routines satisfies this:
;
;         python3 notes/prom_c_tg_regmap.py --slots      # 0 failures, exit 0
;
;     The reference set that check tests against is built by symbolically walking
;     the 32 routines that have NO bound check, so a failure would be reported, not
;     absorbed.  ⚠ An earlier draft of that check zipped two lists instead of
;     pairing a select with its data write; it passed, on pairs the ROM never
;     writes.  The comment in `_walk` records that, because the wrong version
;     printed a table that looked exactly like evidence.
;
;     It follows that a "channel" argument of 0x40..0x7F selects SLOT 3 of physical
;     channel 0..0x3F.  It is not a 65th channel, and 0x40 is not a channel count
;     derived from a bound.
;
; ★★ THE CHANNEL COUNT IS 64, AND IT COMES FROM A LOOP COUNTER.  Dev10C_ResetAllChannels
; below runs `ldb d,0x40` and steps one register per pass through blocks 0x0800 and
; 0x0840, so each block has exactly 0x40 registers.  A second loop in the same
; routine runs `cp hl,0x0040` over the channels.  That is the count read off an
; instruction rather than inferred from an address stride.
;
; ★ AND THE STAGING STRUCT'S POWER-ON IMAGE IS IN THIS ROM.  Dev10C_ResetAllChannels
; copies 0x44 = 68 bytes from ROM 0xFE12CF to 0x00D8DB and 0x26 = 38 bytes from ROM
; 0xFE133B to 0x00D91F, through the already-converted MemCopyWords at 0xF9A038
; whose argument order its own header fixes.  68 is exactly the span of the staging
; fields both banks read (0x08..0x42 plus a word).
; ⚠ 0x00D8DB is NOT 0x00D75E, the struct the 0xFACE67 bank's callers pass.  There
; are at least two staging structs of the same shape.
;
; ⚠ SIX ROUTINES HERE HAVE NO CALLER.  0xFB7B63, 0xFB7B9F, 0xFB7BC1, 0xFB7BE3,
; 0xFB7C05 and 0xFB7DF5 are reached by no absolute `call` and no `calr` anywhere in
; prom_c (notes/prom_c_xrefs.py).  A call through a register operand would be
; invisible to that search, so their headers say "NOT FOUND", not "dead".
;
; HOW THIS BLOCK WAS TRANSCRIBED.  Mechanically, not by hand:
; `notes/llvm_roundtrip_force.py c 0xFB7B63 0x72B` produced the listing and PROVED
; it re-assembles to these bytes before printing it; 65 instructions it could not
; spell were then replaced one at a time, each replacement re-encoded with
; `llvm-mc --show-encoding` and accepted only if it produced the ROM's own bytes.
; Seven remain as `extpfx`, which per notes/prom_c-llvm-mc-spellings.md is the
; correct escape hatch and keeps one source line per instruction.  Each line
; carries its address, its ROM bytes and unidasm's independent decode.

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440_0480 -- registers (chan+0x0440) = staging->0x10 and
; (chan+0x0480) = staging->0x12.
;
; Called from: NOT FOUND.  notes/prom_c_xrefs.py finds neither an absolute `call`
;              nor a `calr` displacement anywhere in prom_c reaching 0xFB7B63.  A
;              call through a register operand would be invisible to that search,
;              so this is "not found", not "dead".
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Evidence: `add hl,0x0440` / `add bc,0x0480`; sources (xbc+16), (xbc+18).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440_0480:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7B63  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7B67  2b                push HL
	push	xix                                   ; FB7B68  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B69  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0440                             ; FB7B6C  db c8 40 04       add HL,0x0440
	ld	xix, 0x0010C000                         ; FB7B70  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7B75  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B77  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+16)                            ; FB7B7A  99 10 23          ld HL,(XBC+0x10)
	ld	xwa, xix                                ; FB7B7D  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7B7F  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7B81  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7B84  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7B86  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, 0x0480                             ; FB7B89  d9 c8 80 04       add BC,0x0480
	ld	(xix), bc                               ; FB7B8D  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7B8F  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+18)                            ; FB7B92  99 12 20          ld WA,(XBC+0x12)
	ld	xiy, (xiz-4)                            ; FB7B95  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7B98  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B9A  5c                pop XIX
	popw	hl                                    ; FB7B9B  4b                pop HL
	unlk32 xiz                                 ; FB7B9C  ee 0d             unlk XIZ
	ret                                        ; FB7B9E  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0180_b -- register (chan+0x0180) = staging->0x0C.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0180 at 0xFACFB4
;   (`python3 notes/prom_c_tg_regmap.py --dups`).
; Called from: NOT FOUND (same caveat as 0xFB7B63).
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7BA8  `add rr,0x0180` forms the select value chan+0x0180,
;          0xFB7BB6  `ld rr,(XBC+0x0C)` fetches the staging word it is
;                    given -- struct offset +0x0C.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0180_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7B9F  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BA3  2b                push HL
	push	xix                                   ; FB7BA4  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BA5  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0180                             ; FB7BA8  db c8 80 01       add HL,0x0180
	ld	xix, 0x0010C000                         ; FB7BAC  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BB1  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BB3  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+12)                            ; FB7BB6  99 0c 20          ld WA,(XBC+0x0c)
	ld	(xix+2), wa                             ; FB7BB9  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7BBC  5c                pop XIX
	popw	hl                                    ; FB7BBD  4b                pop HL
	unlk32 xiz                                 ; FB7BBE  ee 0d             unlk XIZ
	ret                                        ; FB7BC0  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440_b -- register (chan+0x0440) = staging->0x10.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0440 at 0xFACFD6.
; Called from: NOT FOUND.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7BCA  `add rr,0x0440` forms the select value chan+0x0440,
;          0xFB7BD8  `ld rr,(XBC+0x10)` fetches the staging word it is
;                    given -- struct offset +0x10.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7BC1  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BC5  2b                push HL
	push	xix                                   ; FB7BC6  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BC7  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0440                             ; FB7BCA  db c8 40 04       add HL,0x0440
	ld	xix, 0x0010C000                         ; FB7BCE  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BD3  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BD5  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+16)                            ; FB7BD8  99 10 20          ld WA,(XBC+0x10)
	ld	(xix+2), wa                             ; FB7BDB  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7BDE  5c                pop XIX
	popw	hl                                    ; FB7BDF  4b                pop HL
	unlk32 xiz                                 ; FB7BE0  ee 0d             unlk XIZ
	ret                                        ; FB7BE2  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0480 -- register (chan+0x0480) = staging->0x12.
; Block 0x0480 has no writer in the 0xFACE67 bank; it is one of the five blocks
; only this second bank reaches.
; Called from: NOT FOUND.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7BEC  `add rr,0x0480` forms the select value chan+0x0480,
;          0xFB7BFA  `ld rr,(XBC+0x12)` fetches the staging word it is
;                    given -- struct offset +0x12.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; ★ GAP A, round 3 -- what IS established about register chan+0x0480:
;   * it is committed from staging word 9, at struct offset +0x12, both by
;     this accessor and by Dev10C_WriteAllChanRegs (0xFB713A); two independent
;     readings of the same pairing.
;   * its POWER-ON value is 0x0000, and the ROM bytes that say so are at
;     0xFE12E1 -- offset +0x12 of the 68-byte reset image at 0xFE12CF that
;     Dev10C_ResetAllChannels copies to RAM 0x00D8DB.  ⚠ The copy is at
;     0xFB8146 / 0xFB814B / 0xFB814F (lda XIX,0x00d8db / push 0x0044 /
;     lda XWA,0xfe12cf); notes/prom_c_gapA_remaining_regs.py cites 0xFB8175
;     for it, which is the argument load of the NEXT loop -- corrected here,
;     see notes/wave7-round1/README.md lane g1.
; ★★ ROUND 4 -- WHAT THE REGISTER HOLDS.  Word 9 is `MODE | CHANNEL`, and its two
;   fields TILE cleanly: bits 5..0 are a channel of this same 0x0010C000 device
;   (0xFA9BC2 `and BC,0x003f`) and bits 7..6 are a mode from
;   Dev10C_ChanSelHighBits (0xFA9B90), which returns only 0x0040 or 0x00C0 here
;   because 0 is rejected at 0xFA9B98/0xFA9B9A.  The channel field is a channel
;   because the SAME six-bit value is handed to Dev10C_Slot3_WriteGateAndValue at
;   0xFA9C4D/0xFA9C51/0xFA9C52, which turns it into the register selector
;   chan+0x05C0 (0xFB7D35).
;   Producer: Voice_StageChanSel_Reg0440_Reg0480 (0xFA9915).  Full citation list
;   and the raw-byte write census: `python3 notes/prom_c_understanding_round4.py`.
; ⚠ STILL NOT ESTABLISHED: that the named channel is a DIFFERENT channel from the
;   one the word is written to, and what the two mode bits mean.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0480:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7BE3  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BE7  2b                push HL
	push	xix                                   ; FB7BE8  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BE9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0480                             ; FB7BEC  db c8 80 04       add HL,0x0480
	ld	xix, 0x0010C000                         ; FB7BF0  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BF5  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BF7  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+18)                            ; FB7BFA  99 12 20          ld WA,(XBC+0x12)
	ld	(xix+2), wa                             ; FB7BFD  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7C00  5c                pop XIX
	popw	hl                                    ; FB7C01  4b                pop HL
	unlk32 xiz                                 ; FB7C02  ee 0d             unlk XIZ
	ret                                        ; FB7C04  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_04C0_b -- register (chan+0x04C0) = staging->0x14.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_04C0 at 0xFACFF8.
; Called from: NOT FOUND.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7C0E  `add rr,0x04C0` forms the select value chan+0x04C0,
;          0xFB7C1C  `ld rr,(XBC+0x14)` fetches the staging word it is
;                    given -- struct offset +0x14.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_04C0_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7C05  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7C09  2b                push HL
	push	xix                                   ; FB7C0A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7C0B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x04C0                             ; FB7C0E  db c8 c0 04       add HL,0x04c0
	ld	xix, 0x0010C000                         ; FB7C12  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7C17  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7C19  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+20)                            ; FB7C1C  99 14 20          ld WA,(XBC+0x14)
	ld	(xix+2), wa                             ; FB7C1F  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7C22  5c                pop XIX
	popw	hl                                    ; FB7C23  4b                pop HL
	unlk32 xiz                                 ; FB7C24  ee 0d             unlk XIZ
	ret                                        ; FB7C26  0e                ret
; --------------------------------------------------------------------------
; ★ Dev10C_Slot2_WriteGateAndValue -- the routine that shows what BIT 15 of a gate
; register is for.
;
;       if (staging->0x3C & 0x8000)  register (chan+0x0580) = staging->0x3C
;       register (chan+0x0600) = staging->0x40
;       register (chan+0x0580) = staging->0x3C with BIT 15 CLEARED
;
; Called from: 0xFA9B6D, 0xFAC516, 0xFAC57F, 0xFB8AEA and 0xFB822A (the last
;              inside Dev10C_ResetAllChannels below).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct (here loaded into XIX).
; Evidence: `and bc,0x8000` / `jr z,...` guards the first write; `res 15,bc`
;          (unidasm: `res 0x0f,BC`) makes the third.  Same field both times.
; ★ So the sequence written to register (chan+0x0580) is <value with bit 15> then
;   <the same value without bit 15> -- a ONE-THEN-ZERO PULSE on bit 15 with the
;   companion register loaded in between.  That is a strobe, and it is the only
;   place in either bank where the same register is written twice in one routine.
; ⚠ What the strobe DOES is not established.  "Trigger", "latch" and "key-on" all
;   fit the shape and nothing here distinguishes them.
; --------------------------------------------------------------------------
Dev10C_Slot2_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7C27  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7C2B  2b                push HL
	pushw	de                                   ; FB7C2C  2a                push DE
	push	xix                                   ; FB7C2D  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7C2E  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7C31  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+60)                            ; FB7C34  9c 3c 21          ld BC,(XIX+0x3c)
	and	bc, 0x8000                             ; FB7C37  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot2_WriteGateAndValue__FB7C56                             ; FB7C3B  66 19             jr Z,0xfb7c56
	ld	de, hl                                  ; FB7C3D  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB7C3F  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB7C43  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7C48  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7C4B  b1 52             ld (XBC),DE
	ld	bc, (xix+60)                            ; FB7C4D  9c 3c 21          ld BC,(XIX+0x3c)
	ld	xwa, (xiz-4)                            ; FB7C50  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7C53  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot2_WriteGateAndValue__FB7C56:
	ld	de, hl                                  ; FB7C56  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7C58  da c8 00 06       add DE,0x0600
	ld	xbc, 0x0010C000                         ; FB7C5C  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7C61  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7C64  b1 52             ld (XBC),DE
	ld	de, (xix+64)                            ; FB7C66  9c 40 22          ld DE,(XIX+0x40)
	ld	xbc, (xiz-4)                            ; FB7C69  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7C6C  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7C6E  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7C71  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7C73  db 89             ld BC,HL
	add	bc, 0x0580                             ; FB7C75  d9 c8 80 05       add BC,0x0580
	ld	xwa, (xiz-4)                            ; FB7C79  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7C7C  b0 51             ld (XWA),BC
	ld	bc, (xix+60)                            ; FB7C7E  9c 3c 21          ld BC,(XIX+0x3c)
	res	15, bc                                 ; FB7C81  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7C84  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7C87  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7C89  5c                pop XIX
	popw	de                                    ; FB7C8A  4a                pop DE
	popw	hl                                    ; FB7C8B  4b                pop HL
	unlk32 xiz                                 ; FB7C8C  ee 0d             unlk XIZ
	ret                                        ; FB7C8E  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0600_b -- register (chan+0x0600) = staging->0x40.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0600 at 0xFAD01A.
; Called from: 0xFA9AC2, 0xFABEAD, 0xFACD0B.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7C98  `add rr,0x0600` forms the select value chan+0x0600,
;          0xFB7CA6  `ld rr,(XBC+0x40)` fetches the staging word it is
;                    given -- struct offset +0x40.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0600_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7C8F  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7C93  2b                push HL
	push	xix                                   ; FB7C94  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7C95  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0600                             ; FB7C98  db c8 00 06       add HL,0x0600
	ld	xix, 0x0010C000                         ; FB7C9C  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7CA1  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7CA3  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+64)                            ; FB7CA6  99 40 20          ld WA,(XBC+0x40)
	ld	(xix+2), wa                             ; FB7CA9  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7CAC  5c                pop XIX
	popw	hl                                    ; FB7CAD  4b                pop HL
	unlk32 xiz                                 ; FB7CAE  ee 0d             unlk XIZ
	ret                                        ; FB7CB0  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot2_StrobeGate -- the same pulse as Dev10C_Slot2_WriteGateAndValue without the
; companion register:
;
;       if (staging->0x3C & 0x8000)  register (chan+0x0580) = staging->0x3C
;       register (chan+0x0580) = staging->0x3C with bit 15 cleared
;
; Called from: 0xFA9A43, 0xFACDB1.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB7CC6 select chan+0x0580, 0xFB7CD4 fetch (XIX+0x3C)  -- slot 2 gate
;          0xFB7CE0 select chan+0x0580, 0xFB7CEE fetch (XIX+0x3C)  -- slot 2 gate
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot2_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7CB1  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7CB5  2b                push HL
	push	xix                                   ; FB7CB6  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7CB7  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+60)                            ; FB7CBA  9c 3c 21          ld BC,(XIX+0x3c)
	and	bc, 0x8000                             ; FB7CBD  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot2_StrobeGate__FB7CDD                             ; FB7CC1  66 1a             jr Z,0xfb7cdd
	ld	hl, (xiz+8)                             ; FB7CC3  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7CC6  db c8 80 05       add HL,0x0580
	ld	xbc, 0x0010C000                         ; FB7CCA  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7CCF  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7CD2  b1 53             ld (XBC),HL
	ld	bc, (xix+60)                            ; FB7CD4  9c 3c 21          ld BC,(XIX+0x3c)
	ld	xwa, (xiz-4)                            ; FB7CD7  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7CDA  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot2_StrobeGate__FB7CDD:
	ld	hl, (xiz+8)                             ; FB7CDD  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7CE0  db c8 80 05       add HL,0x0580
	ld	xbc, 0x0010C000                         ; FB7CE4  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7CE9  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7CEC  b1 53             ld (XBC),HL
	ld	bc, (xix+60)                            ; FB7CEE  9c 3c 21          ld BC,(XIX+0x3c)
	res	15, bc                                 ; FB7CF1  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7CF4  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7CF7  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7CFA  5c                pop XIX
	popw	hl                                    ; FB7CFB  4b                pop HL
	unlk32 xiz                                 ; FB7CFC  ee 0d             unlk XIZ
	ret                                        ; FB7CFE  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot2_WriteGate8100 -- register (chan+0x0580) = the CONSTANT 0x8100.
; Called from: 0xFA999F.
; Evidence: `ldw (xix+2),0x8100` -- an immediate, not a struct field.
; ⚠ 0x8100 has bit 15 set (the bit the strobe routines pulse) and bit 8 set.
;   Nothing here says what either means.
; --------------------------------------------------------------------------
Dev10C_Slot2_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7CFF  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7D03  2b                push HL
	push	xix                                   ; FB7D04  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7D05  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7D08  db c8 80 05       add HL,0x0580
	ld	xix, 0x0010C000                         ; FB7D0C  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7D11  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7D13  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7D18  5c                pop XIX
	popw	hl                                    ; FB7D19  4b                pop HL
	unlk32 xiz                                 ; FB7D1A  ee 0d             unlk XIZ
	ret                                        ; FB7D1C  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_WriteGateAndValue -- Dev10C_Slot2_WriteGateAndValue's shape on the THIRD
; slot:
;       if (staging->0x3E & 0x8000)  register (chan+0x05C0) = staging->0x3E
;       register (chan+0x0640) = staging->0x42
;       register (chan+0x05C0) = staging->0x3E with bit 15 cleared
;
; Called from: 0xFA9C52, 0xFAC679, 0xFAC6E2, 0xFB8236.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB7D35 select chan+0x05C0, 0xFB7D43 fetch (XIX+0x3E)  -- slot 3 gate
;          0xFB7D4E select chan+0x0640, 0xFB7D5C fetch (XIX+0x42)  -- slot 3 value
;          0xFB7D6B select chan+0x05C0, 0xFB7D74 fetch (XIX+0x3E)  -- slot 3 gate
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot3_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7D1D  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7D21  2b                push HL
	pushw	de                                   ; FB7D22  2a                push DE
	push	xix                                   ; FB7D23  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7D24  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7D27  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+62)                            ; FB7D2A  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7D2D  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot3_WriteGateAndValue__FB7D4C                             ; FB7D31  66 19             jr Z,0xfb7d4c
	ld	de, hl                                  ; FB7D33  db 8a             ld DE,HL
	add	de, 0x05C0                             ; FB7D35  da c8 c0 05       add DE,0x05c0
	ld	xbc, 0x0010C000                         ; FB7D39  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7D3E  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7D41  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB7D43  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7D46  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7D49  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot3_WriteGateAndValue__FB7D4C:
	ld	de, hl                                  ; FB7D4C  db 8a             ld DE,HL
	add	de, 0x0640                             ; FB7D4E  da c8 40 06       add DE,0x0640
	ld	xbc, 0x0010C000                         ; FB7D52  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7D57  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7D5A  b1 52             ld (XBC),DE
	ld	de, (xix+66)                            ; FB7D5C  9c 42 22          ld DE,(XIX+0x42)
	ld	xbc, (xiz-4)                            ; FB7D5F  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7D62  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7D64  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7D67  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7D69  db 89             ld BC,HL
	add	bc, 0x05C0                             ; FB7D6B  d9 c8 c0 05       add BC,0x05c0
	ld	xwa, (xiz-4)                            ; FB7D6F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7D72  b0 51             ld (XWA),BC
	ld	bc, (xix+62)                            ; FB7D74  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7D77  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7D7A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7D7D  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7D7F  5c                pop XIX
	popw	de                                    ; FB7D80  4a                pop DE
	popw	hl                                    ; FB7D81  4b                pop HL
	unlk32 xiz                                 ; FB7D82  ee 0d             unlk XIZ
	ret                                        ; FB7D84  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0640 -- register (chan+0x0640) = staging->0x42.
; Called from: 0xFACCCA.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7D8E  `add rr,0x0640` forms the select value chan+0x0640,
;          0xFB7D9C  `ld rr,(XBC+0x42)` fetches the staging word it is
;                    given -- struct offset +0x42.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0640:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7D85  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7D89  2b                push HL
	push	xix                                   ; FB7D8A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7D8B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0640                             ; FB7D8E  db c8 40 06       add HL,0x0640
	ld	xix, 0x0010C000                         ; FB7D92  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7D97  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7D99  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+66)                            ; FB7D9C  99 42 20          ld WA,(XBC+0x42)
	ld	(xix+2), wa                             ; FB7D9F  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7DA2  5c                pop XIX
	popw	hl                                    ; FB7DA3  4b                pop HL
	unlk32 xiz                                 ; FB7DA4  ee 0d             unlk XIZ
	ret                                        ; FB7DA6  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_StrobeGate -- slot 3's copy of Dev10C_Slot2_StrobeGate, on 0x05C0 / 0x3E.
; Called from: 0xFACD70.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB7DBC select chan+0x05C0, 0xFB7DCA fetch (XIX+0x3E)  -- slot 3 gate
;          0xFB7DD6 select chan+0x05C0, 0xFB7DE4 fetch (XIX+0x3E)  -- slot 3 gate
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot3_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7DA7  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7DAB  2b                push HL
	push	xix                                   ; FB7DAC  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7DAD  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+62)                            ; FB7DB0  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7DB3  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot3_StrobeGate__FB7DD3                             ; FB7DB7  66 1a             jr Z,0xfb7dd3
	ld	hl, (xiz+8)                             ; FB7DB9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DBC  db c8 c0 05       add HL,0x05c0
	ld	xbc, 0x0010C000                         ; FB7DC0  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7DC5  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7DC8  b1 53             ld (XBC),HL
	ld	bc, (xix+62)                            ; FB7DCA  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7DCD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7DD0  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot3_StrobeGate__FB7DD3:
	ld	hl, (xiz+8)                             ; FB7DD3  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DD6  db c8 c0 05       add HL,0x05c0
	ld	xbc, 0x0010C000                         ; FB7DDA  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7DDF  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7DE2  b1 53             ld (XBC),HL
	ld	bc, (xix+62)                            ; FB7DE4  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7DE7  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7DEA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7DED  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7DF0  5c                pop XIX
	popw	hl                                    ; FB7DF1  4b                pop HL
	unlk32 xiz                                 ; FB7DF2  ee 0d             unlk XIZ
	ret                                        ; FB7DF4  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_WriteGate8100 -- register (chan+0x05C0) = 0x8100.
; Called from: NOT FOUND -- `notes/prom_c_xrefs.py 0xFB7DF5 --no-window` finds no
;          literal and no calr; short PC-relative forms are not searched.
; Evidence: eleven instructions, all of them here: `ld HL,(XIZ+0x08) /
;          add HL,0x05c0 / ld XIX,0x0010C000 / ld (XIX),HL /
;          ld (XIX+0x02),0x8100` -- the select/data pair with an immediate.
;          0x05C0 is slot 3's GATE register in the three-slot table of
;          notes/FINDINGS-prom_c-tone-generator.md §5, and 0x8100 is the same
;          constant its slot-1 and slot-2 twins write, which is why the name says
;          "Gate8100" rather than naming a function for the value.
;          ⚠ What writing 0x8100 DOES is not established.
; --------------------------------------------------------------------------
Dev10C_Slot3_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7DF5  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7DF9  2b                push HL
	push	xix                                   ; FB7DFA  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7DFB  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DFE  db c8 c0 05       add HL,0x05c0
	ld	xix, 0x0010C000                         ; FB7E02  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7E07  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7E09  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7E0E  5c                pop XIX
	popw	hl                                    ; FB7E0F  4b                pop HL
	unlk32 xiz                                 ; FB7E10  ee 0d             unlk XIZ
	ret                                        ; FB7E12  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_WriteGateAndValue -- the FIRST slot's copy.  ⚠ Note that slot 1's
; companion register is in a different part of the map from slots 2 and 3:
;
;       if (staging->0x3A & 0x8000)  register (chan+0x0540) = staging->0x3A
;       register (chan+0x01C0) = staging->0x38          <-- block 7, not 0x18/0x19
;       register (chan+0x0540) = staging->0x3A with bit 15 cleared
;
; Called from: 0xFA9EAE, 0xFB8BEA, 0xFB821E.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB7E2B select chan+0x0540, 0xFB7E39 fetch (XIX+0x3A)  -- slot 1 gate
;          0xFB7E44 select chan+0x01C0, 0xFB7E52 fetch (XIX+0x38)  -- slot 1 value
;          0xFB7E61 select chan+0x0540, 0xFB7E6A fetch (XIX+0x3A)  -- slot 1 gate
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot1_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7E13  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7E17  2b                push HL
	pushw	de                                   ; FB7E18  2a                push DE
	push	xix                                   ; FB7E19  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7E1A  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7E1D  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+58)                            ; FB7E20  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7E23  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1_WriteGateAndValue__FB7E42                             ; FB7E27  66 19             jr Z,0xfb7e42
	ld	de, hl                                  ; FB7E29  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB7E2B  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB7E2F  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7E34  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7E37  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB7E39  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7E3C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7E3F  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1_WriteGateAndValue__FB7E42:
	ld	de, hl                                  ; FB7E42  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7E44  da c8 c0 01       add DE,0x01c0
	ld	xbc, 0x0010C000                         ; FB7E48  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7E4D  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7E50  b1 52             ld (XBC),DE
	ld	de, (xix+56)                            ; FB7E52  9c 38 22          ld DE,(XIX+0x38)
	ld	xbc, (xiz-4)                            ; FB7E55  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7E58  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7E5A  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7E5D  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7E5F  db 89             ld BC,HL
	add	bc, 0x0540                             ; FB7E61  d9 c8 40 05       add BC,0x0540
	ld	xwa, (xiz-4)                            ; FB7E65  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7E68  b0 51             ld (XWA),BC
	ld	bc, (xix+58)                            ; FB7E6A  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7E6D  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7E70  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7E73  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7E75  5c                pop XIX
	popw	de                                    ; FB7E76  4a                pop DE
	popw	hl                                    ; FB7E77  4b                pop HL
	unlk32 xiz                                 ; FB7E78  ee 0d             unlk XIZ
	ret                                        ; FB7E7A  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0_b -- register (chan+0x01C0) = staging->0x38.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_01C0 at 0xFAD05E.
; Called from: 0xFA9E09, 0xFABF3A, 0xFACE04.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7E84  `add rr,0x01C0` forms the select value chan+0x01C0,
;          0xFB7E92  `ld rr,(XBC+0x38)` fetches the staging word it is
;                    given -- struct offset +0x38.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7E7B  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7E7F  2b                push HL
	push	xix                                   ; FB7E80  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7E81  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x01C0                             ; FB7E84  db c8 c0 01       add HL,0x01c0
	ld	xix, 0x0010C000                         ; FB7E88  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7E8D  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7E8F  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+56)                            ; FB7E92  99 38 20          ld WA,(XBC+0x38)
	ld	(xix+2), wa                             ; FB7E95  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7E98  5c                pop XIX
	popw	hl                                    ; FB7E99  4b                pop HL
	unlk32 xiz                                 ; FB7E9A  ee 0d             unlk XIZ
	ret                                        ; FB7E9C  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_StrobeGate -- slot 1's copy of Dev10C_Slot2_StrobeGate, on 0x0540 / 0x3A.
; Called from: 0xFA9D89, 0xFAC78C, 0xFAC7DF, 0xFACE57.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB7EB2 select chan+0x0540, 0xFB7EC0 fetch (XIX+0x3A)  -- slot 1 gate
;          0xFB7ECC select chan+0x0540, 0xFB7EDA fetch (XIX+0x3A)  -- slot 1 gate
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot1_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7E9D  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7EA1  2b                push HL
	push	xix                                   ; FB7EA2  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7EA3  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+58)                            ; FB7EA6  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7EA9  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1_StrobeGate__FB7EC9                             ; FB7EAD  66 1a             jr Z,0xfb7ec9
	ld	hl, (xiz+8)                             ; FB7EAF  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7EB2  db c8 40 05       add HL,0x0540
	ld	xbc, 0x0010C000                         ; FB7EB6  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7EBB  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7EBE  b1 53             ld (XBC),HL
	ld	bc, (xix+58)                            ; FB7EC0  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7EC3  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7EC6  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1_StrobeGate__FB7EC9:
	ld	hl, (xiz+8)                             ; FB7EC9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7ECC  db c8 40 05       add HL,0x0540
	ld	xbc, 0x0010C000                         ; FB7ED0  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7ED5  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7ED8  b1 53             ld (XBC),HL
	ld	bc, (xix+58)                            ; FB7EDA  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7EDD  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7EE0  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7EE3  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7EE6  5c                pop XIX
	popw	hl                                    ; FB7EE7  4b                pop HL
	unlk32 xiz                                 ; FB7EE8  ee 0d             unlk XIZ
	ret                                        ; FB7EEA  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_WriteGate8100 -- register (chan+0x0540) = 0x8100.
; Called from: 0xFA9CD6.
; --------------------------------------------------------------------------
Dev10C_Slot1_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7EEB  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7EEF  2b                push HL
	push	xix                                   ; FB7EF0  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7EF1  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7EF4  db c8 40 05       add HL,0x0540
	ld	xix, 0x0010C000                         ; FB7EF8  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7EFD  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7EFF  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7F04  5c                pop XIX
	popw	hl                                    ; FB7F05  4b                pop HL
	unlk32 xiz                                 ; FB7F06  ee 0d             unlk XIZ
	ret                                        ; FB7F08  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev10C_Slot1or3_WriteGateAndValue -- the routine that MAKES THE `chan >= 0x40`
; SPLIT ADD UP.
;
;       chan <  0x40 :  slot 1 -- gate (chan+0x0540) from 0x3A, value (chan+0x01C0) from 0x38
;       chan >= 0x40 :  gate (chan+0x0580) from 0x3E, value (chan+0x0600) from 0x42
;
; and the high arm is not a different parameter: 0x0580 + (0x40+k) = 0x05C0 + k
; and 0x0600 + (0x40+k) = 0x0640 + k, which are EXACTLY the registers
; Dev10C_Slot3_WriteGateAndValue writes for channel k -- with exactly slot 3's struct
; fields, 0x3E and 0x42.  The base is 0x40 low because the channel argument
; already carries that 0x40.
;
; Called from: 0xFB8CE0.
; Evidence: `cp hl,0x0040` / `jr nc,...`; then the two arms.  The identity above
;          is checked for all five bound-checked routines in both banks by
;          `python3 notes/prom_c_tg_regmap.py --slots`, which fails loudly rather
;          than printing a table if any of them does not satisfy it.
; ⚠ It follows that a "channel" argument of 0x40..0x7F means slot 3 of physical
;   channel 0..0x3F, NOT a 65th channel.  Anything that reads the 0x40 bound as a
;   channel COUNT is reading it wrong.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7F09  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7F0D  2b                push HL
	pushw	de                                   ; FB7F0E  2a                push DE
	push	xix                                   ; FB7F0F  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7F10  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7F13  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB7F16  db cf 40 00       cp HL,0x0040
	jr nc, Dev10C_Slot1or3_WriteGateAndValue__FB7F73                            ; FB7F1A  6f 57             jr NC,0xfb7f73
	ld	bc, (xix+58)                            ; FB7F1C  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7F1F  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1or3_WriteGateAndValue__FB7F3E                             ; FB7F23  66 19             jr Z,0xfb7f3e
	ld	de, hl                                  ; FB7F25  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB7F27  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB7F2B  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F30  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F33  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB7F35  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7F38  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7F3B  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1or3_WriteGateAndValue__FB7F3E:
	ld	de, hl                                  ; FB7F3E  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7F40  da c8 c0 01       add DE,0x01c0
	ld	xbc, 0x0010C000                         ; FB7F44  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F49  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F4C  b1 52             ld (XBC),DE
	ld	de, (xix+56)                            ; FB7F4E  9c 38 22          ld DE,(XIX+0x38)
	ld	xbc, (xiz-4)                            ; FB7F51  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7F54  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7F56  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7F59  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7F5B  db 89             ld BC,HL
	add	bc, 0x0540                             ; FB7F5D  d9 c8 40 05       add BC,0x0540
	ld	xwa, (xiz-4)                            ; FB7F61  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7F64  b0 51             ld (XWA),BC
	ld	bc, (xix+58)                            ; FB7F66  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7F69  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7F6C  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7F6F  b0 51             ld (XWA),BC
	jr Dev10C_Slot1or3_WriteGateAndValue__FB7FC8                                ; FB7F71  68 55             jr T,0xfb7fc8
Dev10C_Slot1or3_WriteGateAndValue__FB7F73:
	ld	bc, (xix+62)                            ; FB7F73  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7F76  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1or3_WriteGateAndValue__FB7F95                             ; FB7F7A  66 19             jr Z,0xfb7f95
	ld	de, hl                                  ; FB7F7C  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB7F7E  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB7F82  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F87  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F8A  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB7F8C  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7F8F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7F92  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1or3_WriteGateAndValue__FB7F95:
	ld	de, hl                                  ; FB7F95  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7F97  da c8 00 06       add DE,0x0600
	ld	xbc, 0x0010C000                         ; FB7F9B  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7FA0  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7FA3  b1 52             ld (XBC),DE
	ld	de, (xix+66)                            ; FB7FA5  9c 42 22          ld DE,(XIX+0x42)
	ld	xbc, (xiz-4)                            ; FB7FA8  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7FAB  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7FAD  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7FB0  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7FB2  db 89             ld BC,HL
	add	bc, 0x0580                             ; FB7FB4  d9 c8 80 05       add BC,0x0580
	ld	xwa, (xiz-4)                            ; FB7FB8  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7FBB  b0 51             ld (XWA),BC
	ld	bc, (xix+62)                            ; FB7FBD  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7FC0  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7FC3  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7FC6  b0 51             ld (XWA),BC
Dev10C_Slot1or3_WriteGateAndValue__FB7FC8:
	pop	xix                                    ; FB7FC8  5c                pop XIX
	popw	de                                    ; FB7FC9  4a                pop DE
	popw	hl                                    ; FB7FCA  4b                pop HL
	unlk32 xiz                                 ; FB7FCB  ee 0d             unlk XIZ
	ret                                        ; FB7FCD  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0_or_0600_b -- the value half of the split alone.
; ⚠ 68 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_01C0_or_0600 at 0xFAD0A2.
; Called from: 0xFAA0B0, 0xFAC008.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFB7FE0  `add rr,0x01C0` forms the select value chan+0x01C0,
;          0xFB7FEE  `ld rr,(XBC+0x38)` fetches the staging word it is
;                    given -- struct offset +0x38.
;          0xFB7FF8  `add rr,0x0600` forms the select value chan+0x0600,
;          0xFB8006  `ld rr,(XBC+0x42)` fetches the staging word it is
;                    given -- struct offset +0x42.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_or_0600_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7FCE  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7FD2  2b                push HL
	pushw	de                                   ; FB7FD3  2a                push DE
	push	xix                                   ; FB7FD4  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7FD5  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB7FD8  db cf 40 00       cp HL,0x0040
	jr nc, Dev10C_SetChanReg_01C0_or_0600_b__FB7FF6                            ; FB7FDC  6f 18             jr NC,0xfb7ff6
	ld	de, hl                                  ; FB7FDE  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7FE0  da c8 c0 01       add DE,0x01c0
	ld	xix, 0x0010C000                         ; FB7FE4  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), de                               ; FB7FE9  b4 52             ld (XIX),DE
	ld	xbc, (xiz+10)                           ; FB7FEB  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+56)                            ; FB7FEE  99 38 20          ld WA,(XBC+0x38)
	ld	(xix+2), wa                             ; FB7FF1  bc 02 50          ld (XIX+0x02),WA
	jr Dev10C_SetChanReg_01C0_or_0600_b__FB800C                                ; FB7FF4  68 16             jr T,0xfb800c
Dev10C_SetChanReg_01C0_or_0600_b__FB7FF6:
	ld	de, hl                                  ; FB7FF6  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7FF8  da c8 00 06       add DE,0x0600
	ld	xix, 0x0010C000                         ; FB7FFC  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), de                               ; FB8001  b4 52             ld (XIX),DE
	ld	xbc, (xiz+10)                           ; FB8003  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+66)                            ; FB8006  99 42 20          ld WA,(XBC+0x42)
	ld	(xix+2), wa                             ; FB8009  bc 02 50          ld (XIX+0x02),WA
Dev10C_SetChanReg_01C0_or_0600_b__FB800C:
	pop	xix                                    ; FB800C  5c                pop XIX
	popw	de                                    ; FB800D  4a                pop DE
	popw	hl                                    ; FB800E  4b                pop HL
	unlk32 xiz                                 ; FB800F  ee 0d             unlk XIZ
	ret                                        ; FB8011  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1or3_StrobeGate -- the gate half of the split alone: the bit-15 pulse on
; slot 1 for chan < 0x40 and on slot 3 for chan >= 0x40.
; Called from: 0xFAA02E.
; Evidence: decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`:
;          0xFB8030 select chan+0x0540, 0xFB803E fetch (XIX+0x3A)  -- slot 1 gate
;          0xFB8049 select chan+0x0540, 0xFB8057 fetch (XIX+0x3A)  -- slot 1 gate
;          0xFB8070 select chan+0x0580, 0xFB807E fetch (XIX+0x3E)  -- slot 3 gate, aliased (0x0580+chan == 0x05C0+(chan-0x40))
;          0xFB8089 select chan+0x0580, 0xFB8097 fetch (XIX+0x3E)  -- slot 3 gate, aliased (0x0580+chan == 0x05C0+(chan-0x40))
;          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38), 2: (0x0580,+0x3C)/
;          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`
;          checks that these ten routines use no pair outside it.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB8012  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB8016  2b                push HL
	pushw	de                                   ; FB8017  2a                push DE
	push	xix                                   ; FB8018  3c                push XIX
	ld	xix, (xiz+10)                           ; FB8019  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB801C  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB801F  db cf 40 00       cp HL,0x0040
	jr nc, Dev10C_Slot1or3_StrobeGate__FB8065                            ; FB8023  6f 40             jr NC,0xfb8065
	ld	bc, (xix+58)                            ; FB8025  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB8028  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1or3_StrobeGate__FB8047                             ; FB802C  66 19             jr Z,0xfb8047
	ld	de, hl                                  ; FB802E  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB8030  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB8034  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8039  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB803C  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB803E  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB8041  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8044  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1or3_StrobeGate__FB8047:
	ld	de, hl                                  ; FB8047  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB8049  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB804D  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8052  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB8055  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB8057  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB805A  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB805D  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8060  b8 02 51          ld (XWA+0x02),BC
	jr Dev10C_Slot1or3_StrobeGate__FB80A3                                ; FB8063  68 3e             jr T,0xfb80a3
Dev10C_Slot1or3_StrobeGate__FB8065:
	ld	bc, (xix+62)                            ; FB8065  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB8068  d9 cc 00 80       and BC,0x8000
	jr z, Dev10C_Slot1or3_StrobeGate__FB8087                             ; FB806C  66 19             jr Z,0xfb8087
	ld	de, hl                                  ; FB806E  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB8070  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB8074  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8079  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB807C  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB807E  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB8081  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8084  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1or3_StrobeGate__FB8087:
	ld	de, hl                                  ; FB8087  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB8089  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB808D  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8092  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB8095  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB8097  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB809A  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB809D  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB80A0  b8 02 51          ld (XWA+0x02),BC
Dev10C_Slot1or3_StrobeGate__FB80A3:
	pop	xix                                    ; FB80A3  5c                pop XIX
	popw	de                                    ; FB80A4  4a                pop DE
	popw	hl                                    ; FB80A5  4b                pop HL
	unlk32 xiz                                 ; FB80A6  ee 0d             unlk XIZ
	ret                                        ; FB80A8  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1or3_WriteGate8100 -- register (chan+0x0540) or (chan+0x0580) = 0x8100,
; on the same chan < 0x40 split.
; Called from: 0xFA9F8C.
; Evidence: the two arms only choose the SELECT value; the data write
;          `ldw (xbc+2),0x8100` is shared and sits after the join.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB80A9  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB80AD  2b                push HL
	pushw	de                                   ; FB80AE  2a                push DE
	push	xix                                   ; FB80AF  3c                push XIX
	ld	xix, 0x0010C000                         ; FB80B0  44 00 c0 10 00    ld XIX,0x0010c000
	ld	hl, (xiz+8)                             ; FB80B5  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB80B8  db cf 40 00       cp HL,0x0040
	jr nc, Dev10C_Slot1or3_WriteGate8100__FB80CA                            ; FB80BC  6f 0c             jr NC,0xfb80ca
	ld	de, hl                                  ; FB80BE  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB80C0  da c8 40 05       add DE,0x0540
	ld	xbc, xix                                ; FB80C4  ec 89             ld XBC,XIX
	ld	(xbc), de                               ; FB80C6  b1 52             ld (XBC),DE
	jr Dev10C_Slot1or3_WriteGate8100__FB80D4                                ; FB80C8  68 0a             jr T,0xfb80d4
Dev10C_Slot1or3_WriteGate8100__FB80CA:
	ld	de, hl                                  ; FB80CA  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB80CC  da c8 80 05       add DE,0x0580
	ld	xbc, xix                                ; FB80D0  ec 89             ld XBC,XIX
	ld	(xbc), de                               ; FB80D2  b1 52             ld (XBC),DE
Dev10C_Slot1or3_WriteGate8100__FB80D4:
	ld	xbc, xix                                ; FB80D4  ec 89             ld XBC,XIX
	ldw (xbc+2), 0x8100                        ; FB80D6  b9 02 02 00 81    ld (XBC+0x02),0x8100
	pop	xix                                    ; FB80DB  5c                pop XIX
	popw	de                                    ; FB80DC  4a                pop DE
	popw	hl                                    ; FB80DD  4b                pop HL
	unlk32 xiz                                 ; FB80DE  ee 0d             unlk XIZ
	ret                                        ; FB80E0  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev10C_ResetAllChannels -- the power-on sweep.  This is the single most useful
; routine in the image for anyone modelling the device, because it fixes the
; CHANNEL COUNT with a loop counter instead of a comparison, and it names the ROM
; block the staging structs are initialised from.
;
; Called from: 0xFB05CD.
; Inputs:  none.
; Outputs: see below.
; Evidence, step by step, all of it in the listing:
;
;   1. `lda_24 xbc,0xFE12B5` / `push xbc` / `calr 0xFB7715`  -- hands a ROM block
;      at 0xFE12B5 to an unconverted routine.
;   2. `ld xix,0x00104000` / `ldw (xix),0x0800` / `ldw_da bc,0xFE1313` /
;      `ld (xix+2),bc`  -- ★ THE DEVICE AT 0x00104000 HAS THE SAME ADDRESS/DATA
;      SHAPE: register 0x0800 of it is loaded with the 16-bit word at ROM
;      0xFE1313.
;   3. ★ `ldb d,0x40` -- SIXTY-FOUR iterations, a literal loop counter, and the
;      loop body walks HL from 0x0840 and a frame word from 0x0800 upward by one
;      each pass, writing
;             register (0x0840 + i) = 0xFF00
;             register (0x0800 + i) = 0xFF80        for i = 0..0x3F
;      so blocks 0x21 and 0x20 have exactly 0x40 registers each.  This is the
;      channel count read off an instruction, not inferred from an address.
;      Five `nop`s follow each data write -- the bus-timing padding
;      notes/FINDINGS-memory-map.md already recorded for this device.
;   4. Two calls to MemCopyWords (0xF9A038, converted above), whose argument order
;      is fixed by its own header -- (XSP+8) source, (XSP+12) dest, (XSP+16) count:
;             0x00D8DB <- ROM 0xFE12CF, 0x44 = 68 bytes
;             0x00D91F <- ROM 0xFE133B, 0x26 = 38 bytes
;      ★ 68 is exactly the span of the staging-struct fields both banks read
;      (0x08..0x42 inclusive of a word at 0x42), so 0x00D8DB is a staging struct
;      and ROM 0xFE12CF is its POWER-ON IMAGE.
;      ⚠ 0x00D8DB is NOT the 0x00D75E the 0xFACE67 bank uses.  There are at least
;      two of these structs.
;   5. A loop over HL = 0..0x3F (`cp hl,0x0040` / `jr c,...`) that calls
;      0xFB713A, 0xFB77EF and Dev10C_WriteReg (0xFB732C) with &0x00D8DB, editing a
;      bitfield at 0x00D91F between calls.
;   6. A second loop over HL = 0..0x3F that writes, per channel,
;             register (0x0840 + i) = 0xFF00
;             register (0x0800 + i) = 0xFF80
;             register (0x00C0 + i) = 0x0000
;             register (0x0000 + i) = 0x7E00
;      and then calls Dev10C_Slot1_WriteGateAndValue, Dev10C_Slot2_WriteGateAndValue,
;      Dev10C_Slot3_WriteGateAndValue and 0xFB7A58, each with &0x00D8DB.
;      ★ All three slots, in order, for every one of 64 channels -- which is the
;      strongest evidence in the image that the three (gate, value) pairs really
;      are three parallel per-channel objects and not three unrelated parameters.
;
; ⚠ CORRECTED (wave 7 round 3).  This paragraph used to say that 0xFB7715,
;   0xFB713A, 0xFB77EF and 0xFB7A58 are NOT converted.  ALL FOUR ARE CONVERTED AND
;   NAMED: Dev10C_WriteGlobalRegs, Dev10C_WriteAllChanRegs, Dev104_WriteAllChanRegs
;   and Dev104_WriteChanReg0 -- `llvm-nm rebuilt_ROMs/wsa1_prom_c.llvm.elf` places a
;   symbol at each, and prom_c has zero `.incbin`.  What steps 1 and 5 COMPUTE is
;   still not established; that part of the sentence stands.  The reset VALUES above
;   are what the ROM writes; what they mean is not established.
; ★ ROUND 3 -- step 4's copy IS the 0x0010C000 staging struct's power-on image, and
;   the struct is 68 bytes: RAM 0x00D75E..0x00D7A1 on the voice path, a second
;   instance at 0x00D8DB here.  0x00D75E + 0x2C = 0x00D78A (round 2's
;   Dev10C_WriteSixChanRegs_FromD78A) and 0x00D75E + 0x44 = 0x00D7A2 (the 0x00104000
;   struct VoiceRegs_Stage_A pushes at 0xFB0B5B), so three readings close on the same
;   length.  Word by word, out of the ROM:
;   `python3 notes/prom_c_naming_round3.py --struct`.
; ★ AND THE IMAGE AGREES WITH THIS ROUTINE'S OWN DIRECT WRITES: image word 12 (+0x18,
;   register 0x0800) is 0xFF80 and word 13 (+0x1A, register 0x0840) is 0xFF00 --
;   exactly the two constants step 3 writes at 0xFB8132 and 0xFB811E.  Two
;   independent paths, the same two values; if the field map were off by one word
;   that coincidence would break.
; --------------------------------------------------------------------------
Dev10C_ResetAllChannels:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FB80E1  ee 0c f4 ff       link XIZ,0xfff4
	pushw	hl                                   ; FB80E5  2b                push HL
	pushw	de                                   ; FB80E6  2a                push DE
	push	xix                                   ; FB80E7  3c                push XIX
	lda	xbc, (0xFE12B5:24)                       ; FB80E8  f2 b5 12 fe 31    lda XBC,0xfe12b5
	push	xbc                                   ; FB80ED  39                push XBC
	calr (0xFB7715 - 0xFB80F1)                 ; FB80EE  1e 24 f6          calr 0xfb7715
	ld	xix, DEV104_BASE                        ; FB80F1  44 00 40 10 00    ld XIX,0x00104000
	ldw (xix), DEV104_BLK_0800                 ; FB80F6  b4 02 00 08       ld (XIX),0x0800
	ld	bc, (0xFE1313:24)                        ; FB80FA  d2 13 13 fe 21    ld BC,(0xfe1313)
	ld	(xix+2), bc                             ; FB80FF  bc 02 51          ld (XIX+0x02),BC
	ld	xix, 0x0010C000                         ; FB8102  44 00 c0 10 00    ld XIX,0x0010c000
	ld	xbc, xix                                ; FB8107  ec 89             ld XBC,XIX
	inc	2, xbc                                 ; FB8109  e9 62             inc 2,XBC
	ld	(xiz-6), xbc                            ; FB810B  be fa 61          ld (XIZ+0xfa),XBC
	ldw	hl, 0x0840                             ; FB810E  33 40 08          ld HL,0x0840
	ldw (xiz-2), 0x0800                        ; FB8111  be fe 02 00 08    ld (XIZ+0xfe),0x0800
	ldb	d, 64                                  ; FB8116  24 40             ld D,0x40
	pop	xiy                                    ; FB8118  5d                pop XIY
Dev10C_ResetAllChannels__FB8119:
	ld	(xix), hl                               ; FB8119  b4 53             ld (XIX),HL
	ld	xbc, (xiz-6)                            ; FB811B  ae fa 21          ld XBC,(XIZ+0xfa)
	ldw (xbc), 0xFF00                          ; FB811E  b1 02 00 ff       ld (XBC),0xff00
	nop                                        ; FB8122  00                nop
	nop                                        ; FB8123  00                nop
	nop                                        ; FB8124  00                nop
	nop                                        ; FB8125  00                nop
	nop                                        ; FB8126  00                nop
	ld	bc, (xiz-2)                             ; FB8127  9e fe 21          ld BC,(XIZ+0xfe)
	ld	(xiz-10), bc                            ; FB812A  be f6 51          ld (XIZ+0xf6),BC
	ld	(xix), bc                               ; FB812D  b4 51             ld (XIX),BC
	ld	xbc, (xiz-6)                            ; FB812F  ae fa 21          ld XBC,(XIZ+0xfa)
	ldw (xbc), 0xFF80                          ; FB8132  b1 02 80 ff       ld (XBC),0xff80
	inc	1, hl                                  ; FB8136  db 61             inc 1,HL
	ld	bc, (xiz-10)                            ; FB8138  9e f6 21          ld BC,(XIZ+0xf6)
	inc	1, bc                                  ; FB813B  d9 61             inc 1,BC
	ld	(xiz-2), bc                             ; FB813D  be fe 51          ld (XIZ+0xfe),BC
	dec	1, d                                   ; FB8140  cc 69             dec 1,D
	cps	d, 0                                   ; FB8142  cc d8             cp D,0
	jr nz, Dev10C_ResetAllChannels__FB8119                            ; FB8144  6e d3             jr NZ,0xfb8119
	lda	xix, (0x00D8DB:24)                       ; FB8146  f2 db d8 00 34    lda XIX,0x00d8db
	pushw	68                                   ; FB814B  0b 44 00          push 0x0044
	push	xix                                   ; FB814E  3c                push XIX
	lda	xwa, (0xFE12CF:24)                       ; FB814F  f2 cf 12 fe 30    lda XWA,0xfe12cf
	push	xwa                                   ; FB8154  38                push XWA
	call 0x00F9A038                            ; FB8155  1d 38 a0 f9       call 0xf9a038
	lda	xix, (0x00D91F:24)                       ; FB8159  f2 1f d9 00 34    lda XIX,0x00d91f
	pushw	38                                   ; FB815E  0b 26 00          push 0x0026
	push	xix                                   ; FB8161  3c                push XIX
	lda	xbc, (0xFE133B:24)                       ; FB8162  f2 3b 13 fe 31    lda XBC,0xfe133b
	push	xbc                                   ; FB8167  39                push XBC
	call 0x00F9A038                            ; FB8168  1d 38 a0 f9       call 0xf9a038
	ldw	hl, 0                                  ; FB816C  33 00 00          ld HL,0x0000
	add	xsp, 20                                ; FB816F  ef c8 14 00 00 00 add XSP,0x00000014
Dev10C_ResetAllChannels__FB8175:
	lda	xbc, (0x00D8DB:24)                       ; FB8175  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB817A  39                push XBC
	ld	de, hl                                  ; FB817B  db 8a             ld DE,HL
	pushw	de                                   ; FB817D  2a                push DE
	calr (0xFB713A - 0xFB8181)                 ; FB817E  1e b9 ef          calr 0xfb713a
	extpfx7 0xD2, 0x1F, 0xD9, 0x00, 0x3C, 0xFF, 0xC0 ; FB8181  d2 1f d9 00 3c ff c0 and (0x00d91f),0xc0ff
	ld	ix, (0x00D91F:24)                        ; FB8188  d2 1f d9 00 24    ld IX,(0x00d91f)
	ld	bc, de                                  ; FB818D  da 89             ld BC,DE
	sll	bc, 8                                  ; FB818F  d9 ee 08          sll 0x08,BC
	and	bc, 0x3F00                             ; FB8192  d9 cc 00 3f       and BC,0x3f00
	or	bc, ix                                  ; FB8196  dc e1             or BC,IX
	ld	(0x00D91F:24), bc                        ; FB8198  f2 1f d9 00 51    ld (0x00d91f),BC
	lda	xbc, (0x00D91F:24)                       ; FB819D  f2 1f d9 00 31    lda XBC,0x00d91f
	push	xbc                                   ; FB81A2  39                push XBC
	pushw	de                                   ; FB81A3  2a                push DE
	calr (0xFB77EF - 0xFB81A7)                 ; FB81A4  1e 48 f6          calr 0xfb77ef
	ld	bc, (0x00D8DB:24)                        ; FB81A7  d2 db d8 00 21    ld BC,(0x00d8db)
	pushw	bc                                   ; FB81AC  29                push BC
	pushw	de                                   ; FB81AD  2a                push DE
	calr (0xFB732C - 0xFB81B1)                 ; FB81AE  1e 7b f1          calr 0xfb732c
	ld	hl, de                                  ; FB81B1  da 8b             ld HL,DE
	inc	1, hl                                  ; FB81B3  db 61             inc 1,HL
	inc	8, xsp                                 ; FB81B5  ef 60             inc 0,XSP
	inc	8, xsp                                 ; FB81B7  ef 60             inc 0,XSP
	cp	hl, 64                                  ; FB81B9  db cf 40 00       cp HL,0x0040
	jr c, Dev10C_ResetAllChannels__FB8175                             ; FB81BD  67 b6             jr C,0xfb8175
	ldw	hl, 0                                  ; FB81BF  33 00 00          ld HL,0x0000
	ld	xix, 0x0010C000                         ; FB81C2  44 00 c0 10 00    ld XIX,0x0010c000
	ld	xbc, xix                                ; FB81C7  ec 89             ld XBC,XIX
	inc	2, xbc                                 ; FB81C9  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB81CB  be f8 61          ld (XIZ+0xf8),XBC
	ldw (xiz-2), 0x0840                        ; FB81CE  be fe 02 40 08    ld (XIZ+0xfe),0x0840
	ldw	de, 0x0800                             ; FB81D3  32 00 08          ld DE,0x0800
	ldw (xiz-4), 0x00C0                        ; FB81D6  be fc 02 c0 00    ld (XIZ+0xfc),0x00c0
Dev10C_ResetAllChannels__FB81DB:
	ld	bc, (xiz-2)                             ; FB81DB  9e fe 21          ld BC,(XIZ+0xfe)
	ld	(xix), bc                               ; FB81DE  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB81E0  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0xFF00                          ; FB81E3  b1 02 00 ff       ld (XBC),0xff00
	nop                                        ; FB81E7  00                nop
	nop                                        ; FB81E8  00                nop
	nop                                        ; FB81E9  00                nop
	nop                                        ; FB81EA  00                nop
	nop                                        ; FB81EB  00                nop
	ld	(xix), de                               ; FB81EC  b4 52             ld (XIX),DE
	ld	xbc, (xiz-8)                            ; FB81EE  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0xFF80                          ; FB81F1  b1 02 80 ff       ld (XBC),0xff80
	ld	bc, (xiz-4)                             ; FB81F5  9e fc 21          ld BC,(XIZ+0xfc)
	ld	(xix), bc                               ; FB81F8  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB81FA  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0x0000                          ; FB81FD  b1 02 00 00       ld (XBC),0x0000
	nop                                        ; FB8201  00                nop
	nop                                        ; FB8202  00                nop
	nop                                        ; FB8203  00                nop
	nop                                        ; FB8204  00                nop
	nop                                        ; FB8205  00                nop
	ld	(xiz-10), hl                            ; FB8206  be f6 53          ld (XIZ+0xf6),HL
	ld	bc, (xiz-10)                            ; FB8209  9e f6 21          ld BC,(XIZ+0xf6)
	ld	(xix), bc                               ; FB820C  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB820E  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0x7E00                          ; FB8211  b1 02 00 7e       ld (XBC),0x7e00
	lda	xbc, (0x00D8DB:24)                       ; FB8215  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB821A  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB821B  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7E13 - 0xFB8221)                 ; FB821E  1e f2 fb          calr 0xfb7e13
	lda	xbc, (0x00D8DB:24)                       ; FB8221  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB8226  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8227  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7C27 - 0xFB822D)                 ; FB822A  1e fa f9          calr 0xfb7c27
	lda	xbc, (0x00D8DB:24)                       ; FB822D  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB8232  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8233  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7D1D - 0xFB8239)                 ; FB8236  1e e4 fa          calr 0xfb7d1d
	extpfx7 0xD2, 0x1F, 0xD9, 0x00, 0x3C, 0xFF, 0xC0 ; FB8239  d2 1f d9 00 3c ff c0 and (0x00d91f),0xc0ff
	ld	bc, (0x00D91F:24)                        ; FB8240  d2 1f d9 00 21    ld BC,(0x00d91f)
	res	2, bc                                  ; FB8245  d9 30 02          res 0x02,BC
	ld	(xiz-12), bc                            ; FB8248  be f4 51          ld (XIZ+0xf4),BC
	ld	(0x00D91F:24), bc                        ; FB824B  f2 1f d9 00 51    ld (0x00d91f),BC
	ld	bc, (xiz-10)                            ; FB8250  9e f6 21          ld BC,(XIZ+0xf6)
	sll	bc, 8                                  ; FB8253  d9 ee 08          sll 0x08,BC
	and	bc, 0x3F00                             ; FB8256  d9 cc 00 3f       and BC,0x3f00
	extpfx3 0x9E, 0xF4, 0xE1                   ; FB825A  9e f4 e1          or BC,(XIZ+0xf4)
	ld	(0x00D91F:24), bc                        ; FB825D  f2 1f d9 00 51    ld (0x00d91f),BC
	lda	xbc, (0x00D91F:24)                       ; FB8262  f2 1f d9 00 31    lda XBC,0x00d91f
	push	xbc                                   ; FB8267  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8268  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7A58 - 0xFB826E)                 ; FB826B  1e ea f7          calr 0xfb7a58
	incw	1, (xiz-2)                            ; FB826E  9e fe 61          incw 1,(XIZ+0xfe)
	inc	1, de                                  ; FB8271  da 61             inc 1,DE
	incw	1, (xiz-4)                            ; FB8273  9e fc 61          incw 1,(XIZ+0xfc)
	ld	hl, (xiz-10)                            ; FB8276  9e f6 23          ld HL,(XIZ+0xf6)
	inc	1, hl                                  ; FB8279  db 61             inc 1,HL
	add	xsp, 24                                ; FB827B  ef c8 18 00 00 00 add XSP,0x00000018
	cp	hl, 64                                  ; FB8281  db cf 40 00       cp HL,0x0040
	jrl c, Dev10C_ResetAllChannels__FB81DB                            ; FB8285  77 53 ff          jrl C,0xfb81db
	pop	xix                                    ; FB8288  5c                pop XIX
	popw	de                                    ; FB8289  4a                pop DE
	popw	hl                                    ; FB828A  4b                pop HL
	unlk32 xiz                                 ; FB828B  ee 0d             unlk XIZ
	ret                                        ; FB828D  0e                ret
