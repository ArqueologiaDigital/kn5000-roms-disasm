/**
 * sndparam_types.h -- the 18-byte sound-parameter descriptor
 *
 * WHAT REGISTERS THESE.  SndParam_RegisterAllWidgets
 * (v10/maincpu/audio/sndparam_routines.s:3135-3151) walks 972 `.long` pointers
 * from SndParam_RegisterLoop_Data (= 0xEE01A0, in ui_widgets/widget_dispatch.s),
 * reads the u32 at each record's +0x00 as a key, and hands the pair to
 * SndParam_InsertEntry, which hashes the key and stores {key, record pointer}
 * as an 8-byte slot in the RAM table at 0x34100.  Every later access re-hashes
 * a key (SndParam_LookupByKey / SndParam_ProbeEntry), recovers the record
 * pointer with `ld xwa, (xwa+4)`, and reads fields off it -- so every
 * `(xwa + N)` in the SndParam_* accessors is a read of the field at +N here.
 * Called once at boot from midi/midi_serial_routines.s (MIDI_INIT_SEQUENCES),
 * alongside a second pass, SndParam_ReregisterAll.
 *
 * FIELD PROVENANCE -- one citation per field, all in
 * v10/maincpu/audio/sndparam_routines.s unless stated:
 *
 *   +0x00 key           `ld xwa, (xbc)` :3145 -- the whole u32 is the lookup
 *                       key; the hash uses its low byte and its second byte
 *                       (:3159-3174, `and xhl,0xff` / `srl xhl,8` / `and 0x1f`,
 *                       then DivMod32 by 0x7FF), and the stored key is compared
 *                       whole at :3196 `cp xiz, xde`.  Byte +0x03 is 0 in all
 *                       972 records, so it is effectively 24-bit.
 *   +0x04 bank_index    `ld c,(xwa+4)` / `extz bc` / `sla bc,2` / `lda_24 xde,
 *                       (SndParam_DMA_Zone2Check_Data)` :813-816 -- x4 index
 *                       into the RAM-bank pointer table at 0xEE1160, whose
 *                       entries are 26 bytes apart (0xF9B6, 0xF9D0, ...).
 *                       `or xde,xde; ret z` -- a null bank aborts the access.
 *                       Same at :870-876, :917-923, :945, :1241-1246, :1996-1998.
 *   +0x05 bank_offset   `ld c,(xwa+5)` / `ld L,(XIX+BC)` :820-822 -- byte offset
 *                       inside that bank.  Word variant doubles it
 *                       (`add bc,bc`, :924-927).
 *   +0x06 mask          `ld l,(xbc+6)` / `and l,a` :2523-2524 (encode) and
 *                       `ld c,(xde+6)` / `and a,c` :2569-2572 (decode).  Also
 *                       used inverted to clear bits in a caller struct:
 *                       `cpl c` / `and (xwa+3),c` :475-478.
 *   +0x07 clamp_min     `ld a,(xbc+7)` / `cp a,l` / `jr ule,+2` / `ld l,a`
 *                       :2508-2511 -- RAISES the value to +0x07.
 *   +0x08 clamp_max     `ld a,(xbc+8)` / `cp a,l` / `jr nc,+2` / `ld l,a`
 *                       :2512-2515 -- LOWERS the value to +0x08.
 *   +0x09 shift         `ld a,(xbc+9)` / `and a,0xf` / `jr z,+2` / `sll A,L`
 *                       :2516-2520 on the encode path, `srl A,L` :2574-2578 on
 *                       the decode path.  Only the LOW NIBBLE is ever read; no
 *                       instruction reads the high nibble.
 *   +0x0A xor_value     `ld a,(xbc+10)` / `xor a,l` :2521-2522; also
 *                       `ld c,(xwa+10)` / `xor hl,bc` :826-828.
 *   +0x0B aux_index     x4 index into the SAME descriptor pointer table, giving
 *                       a second record R: six readers use base 0xEE0198
 *                       (:890-894, :1256-1268, :2012-2027, :2530-2542,
 *                       :2602-2619, :2671-2683) and two use base+4 = 0xEE019C
 *                       (:928-931, :1361-1371).  R is consumed as a small byte
 *                       map (`cp l,(xbc+1)` -> R[3] else `cp l,(xbc+2)` -> R[4]
 *                       else R[5], :894-907), as a 2-way map (:1265-1268), as a
 *                       bias (:2021-2027) or as an LE16 array
 *                       (`add xde,xde` / `ld de,(xde)`, :1369-1371).
 *                       0xFF in the large majority of records; :837-841 also
 *                       compares it against the literal 2.
 *                       !! Which of those shapes applies to a given record is
 *                       decided by the accessor selected below, not by this
 *                       byte, so no per-record aux TYPE is claimed here.
 *   +0x0C read_accessor      `ld a,(xwa+12)` / `cps a,7` / `sla wa,2` /
 *                       SndParam_RO_Dispatch_Data (0xEE10D0) :293-302.
 *   +0x0D register_accessor  `ld c,(xwa+13)` / `cp c,0x9` /
 *                       SndParam_DispatchCallback_Data (0xEE10EC) :48-58.
 *   +0x0E lookup2_accessor   `ld a,(xwa+14)` / `cp a,0x8` /
 *                       SndParam_Lkp2_Dispatch_Data (0xEE1110) :178-189.
 *   +0x0F codec         `ld e,(xwa+15)` / `sla de,2` /
 *                       SndParam_RW_ProcessResult_Data (0xEE1130) :585-592 picks
 *                       slot n (the ENCODER); :463-472 does `inc 3,a` first and
 *                       picks slot n+3 (the matching DECODER).
 *   +0x10 write_accessor     `ld c,(xwa+16)` / `cps c,6` /
 *                       SndParam_DispatchTypeDE5_Data (0xEE1148) :86-95.
 *   +0x11 unknown_0x11  !! NO READER.  No `(X??+0x11)` load exists anywhere in
 *                       the 0xFCD200-0xFCF000 accessor region.  0xFF in almost
 *                       every record, which is consistent with padding or a
 *                       terminator -- but consistent is not evidenced, so the
 *                       field is left named for its offset.
 *
 * Cross-field use worth knowing: SndParam_ReregisterAll :3260-3264 reads
 * (+0x04, +0x05, +0x06) together and SndParam_AllocAndInsert :3290-3330 packs
 * them (`+0x05 << 8` | `+0x04` | `+0x06`) into a second hash table at RAM
 * 0x97D8; and SndParam_WriteFieldSub_Data :2684-2704 builds the 4-byte packet
 * {+0x04, +0x05, value & mask, mask} for SndParam_PackAndWrite.
 *
 * !! The record LABELS (ExtPartParam_*, SeqMixParam_*, PartParam_*,
 * MidiChParam_*, VoiceParamEx_*, VoiceCtrlR1_*) are NOT evidence of anything.
 * Commits feda55d9 and 16f0917a assigned those six prefixes by ADDRESS-RANGE
 * BUCKETING, not by any reader; nothing distinguishes the six kinds
 * structurally and no code references any of the labels.  They are preserved
 * here only because the pointer table names them.
 *
 * Generated-alongside: scripts/generators/gen_sndparam_records_c.py.
 */
#ifndef SNDPARAM_TYPES_H
#define SNDPARAM_TYPES_H

#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint32_t key;                /* +0x00 hash key; +0x03 always 0 */
    uint8_t  bank_index;         /* +0x04 x4 index into the RAM-bank table */
    uint8_t  bank_offset;        /* +0x05 byte offset inside that bank */
    uint8_t  mask;               /* +0x06 AND mask */
    uint8_t  clamp_min;          /* +0x07 value is raised to this */
    uint8_t  clamp_max;          /* +0x08 value is lowered to this */
    uint8_t  shift;              /* +0x09 low nibble = shift count */
    uint8_t  xor_value;          /* +0x0A XORed with the value */
    uint8_t  aux_index;          /* +0x0B x4 index to a second record, 0xFF none */
    uint8_t  read_accessor;      /* +0x0C < 7  */
    uint8_t  register_accessor;  /* +0x0D < 9  */
    uint8_t  lookup2_accessor;   /* +0x0E < 8  */
    uint8_t  codec;              /* +0x0F encoder n, decoder n+3 */
    uint8_t  write_accessor;     /* +0x10 < 6  */
    uint8_t  unknown_0x11;       /* +0x11 NO READER FOUND */
} sndparam_descriptor_t;

_Static_assert(sizeof(sndparam_descriptor_t) == 18,
    "sndparam_descriptor_t must be exactly 18 bytes");

#endif /* SNDPARAM_TYPES_H */
