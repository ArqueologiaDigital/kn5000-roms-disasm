	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_d.bin -- THE TONE DATABASE
; ==============================================================================
;
; Reference designator not legible in the manual scan; this image is
; wsa1_os_v2.ic21 of the redistributed v2 firmware set, so IC21 is the likely
; designator and is NOT asserted here.  DATA ONLY -- 60 of the 64 words at file
; offset 0x7FF00 are 0xFFFFFFFF and the other four are the build tag, so there is
; no vector table: it is not a boot image and nothing in it executes.
; (⚠ this line used to say "all 64"; corrected against notes/prom_d_base_checks.py.)
;
; BASE: **0x00F00000 on CPU 2's bus** -- ⚠ CHANGED IN WAVE 7 ROUND 3, where this
; paragraph used to read "NOT ESTABLISHED".  What establishes it:
;
;   * prom_c installs 0x00F00000 in RAM 0x00D7ED and 0x00D7F1 (0xFB051E loads
;     the immediate, 0xFB0523 and 0xFB0528 store it).  Those two stores are the
;     ONLY instructions in prom_c that write either address, so the value is a
;     compile-time constant at every use.
;   * prom_c then reads THIS IMAGE'S 48-slot directory through that base at 99
;     instruction pairs covering 33 slots, and adds the base to the offsets it
;     finds there.  Every one of the 99 is re-decoded from prom_c's ROM bytes.
;   * independently, prom_a 0xF82A5F `ld XWA,0x00F7FFF0` reads eleven bytes that
;     are this image's build tag at file 0x7FFF0, "wsad_54.ssf"; the difference
;     is 0x00F00000.  Two processors, two routes, one base.
;   * the earlier "512 KiB flash at 0xE80000" reading is REFUTED: prom_c's own
;     Flash_SectorErase bounds that part at 0x00E80000..0x00EFFFFF, below this
;     image, and ExtBoard_ProbeAndInstallBases installs the two addresses in
;     SEPARATE slots.  notes/prom_d_base_checks.py, 12 checks.
;
; ORIGIN in prom_d/prom_d.ld nevertheless STAYS 0, and that is deliberate: this
; image's own directory is 0-BASED, and what proves that is not a statistic but
; an instruction sequence -- prom_c reads a tone-record entry out of the table at
; slot +0x08 (0xFB429D) and then ADDS THE BASE TO IT (0xFB429F), having already
; added the base to reach the table (0xFB4298).  A stored absolute address needs
; neither add.  Every offset in this source is therefore FILE-RELATIVE, which is
; how the hardware reads it.  (⚠ the older argument from bank statistics is kept
; in prom_d/prom_d.ld but DOWNGRADED there: round 3 Q8 shows it does not
; discriminate -- prom_c is a code ROM and scores like prom_d on it.)
;
; ★ "DATA ONLY" WAS ATTACKED ON 2026-09-02 AND HELD.  A falsification lane took
; the claim that this image contains no code as something to BREAK, because the
; way it could be false is invisible to the byte gate: code typed as data
; re-assembles to the same bytes.  55 checks,
; notes/prom_cd_falsification_2026_09_02.py, summarised in
; notes/FINDINGS-prom_cd-falsification.md:
;
;   * this image IS on a CPU bus -- wsa1.cpp maps it .rom() in CPU 2's program
;     space -- so "no code" is a real claim and not a tautology;
;   * none of prom_c's 33 vectors lands in it (null: all 33 land in prom_c);
;   * exactly ONE prom_c instruction literal falls in its window, the base
;     itself (null: the same scanner finds many in two other windows);
;   * prom_c's BYTES hold no pointer table into it -- 741 LE32 words in its
;     window against 901 and 675 in windows with NO DEVICE, and 1977 in prom_c's
;     own, so it is at address-space noise while prom_c is enriched;
;   * llvm-mc emits ZERO instruction statements from this source and 76,647 from
;     prom_c's;
;   * and its BYTES do not behave like code: branch-target coherence normalised
;     by boundary density scores 0.29-1.16 here, against 0.81-1.34 for prom_c
;     data and 2.42-3.09 for prom_c code.  Splicing 8 KiB of real prom_c code in
;     scores 2.58, which is how the test is shown to be able to fail.
;
; ⚠ THE REACH OF THAT LAST TEST IS ABOUT 2 KiB.  A shorter routine would evade
; it, and file 0x26000-0x2BFFF (ToneDB_EnvDescTable) has too few branches in its
; decode to be scored at all.  Those 24 KiB are the part of this image least
; attacked.
;
; ⚠ What is still open is which PHYSICAL PART this is.  The base fixes the
; address the firmware reads it at, not the device.
;
; ------------------------------------------------------------------------------
; WHAT THIS IMAGE IS
; ------------------------------------------------------------------------------
; It is a TONE DATABASE of the same design as the KN5000's, which is documented
; in ../kn5000-roms-disasm/table_data/tone_database_directory.s.  A 48-slot
; directory at file 0x0000 names every other region; the KN5000 has the same
; table at its ToneDB_Base, and the correspondences that hold are listed on the
; directory itself below.  The strongest of them:
;
;   * slot +0x08 is the tone-record offset table in both;
;   * slots +0x9C/+0xA0/+0xA4 alias +0x24/+0x28/+0x2C in both;
;   * the tail scalars at +0xD0, +0xD4, +0xD6, +0xD8, +0xDA and +0xE8 hold
;     IDENTICAL values in both (+0xE8 = 426 in each);
;   * slot +0x50 is a catalogue of 16-byte named wave rows starting "Piano L",
;     "Piano R", "Mono Piano" in both;
;   * the 81-byte per-element block inside a tone record is the SAME STRUCTURE
;     in both: 63 of its 81 byte columns share their modal value across the two
;     ROMs' entire populations (1637 KN5000 blocks, 451 WSA1 blocks), against
;     18-29 columns for every shift and rotation null.
;
; And it reaches ACROSS THE ARCHITECTURE BOUNDARY as well: 195 of the 252
; distinct 16-character name fields in the WSA1 images are verbatim in the
; KN7000's (MN10300) table ROM and all 195 are in prom_d, while 74 of the 250
; shared binary runs sit exactly 81 bytes apart -- prom_d's own per-element
; stride, derived on this side without reference to any KN7000.  See the
; MELODIC TONE RECORDS banner; notes/wave7_xref_mn10300_family.py section 4.
;
; Contents, by count:
;     274 tones           256 melodic + 18 drum kits, named and reachable from
;                         the offset table at 0x0B80
;     504 drum instruments 150-byte records with 13-char names
;    1493 wave-catalogue rows across 5 catalogues (307/314/503/208/161), each
;                         count CONFIRMED by that catalogue's own footer block
;     594 wave-select records of 43 bytes in three arrays
;    1280 program-map entries (10 rows x 128 LE16)
;
; ------------------------------------------------------------------------------
; WHAT IS NOT ESTABLISHED -- read this before quoting anything below
; ------------------------------------------------------------------------------
; The byte gate certifies BYTES.  It is blind to a wrong label and a wrong
; comment.  For this file specifically:
;
;   * ⚠ WAVE 7 ROUND 3 RETIRED THE HEADLINE CAVEAT.  This bullet used to read
;     "NO WSA1 INSTRUCTION THAT READS ANY OF THESE STRUCTURES HAS BEEN FOUND",
;     and it appeared four times in this file.  It is now FALSE and is retracted.
;     prom_c reads this image's directory at 99 instruction pairs over 33 slots
;     (notes/prom_d_documentation_round3.py, 62 checks, every citation re-decoded
;     from prom_c's ROM bytes).  What that changed, region by region, is on each
;     banner as an `Evidence:` line.  The headline consequences:
;       - the base, the 0-based offsets and the pointer/scalar split of the
;         directory are now prom_c's own encodings, not a KN5000 transplant;
;       - 81 and 217 (the element block and the tone-record head), 16 (the
;         catalogue row), 128 (the +0xA8 record and the index-map row) and 4/2
;         (the LE32/LE16 entry widths) appear as literals or shifts in prom_c;
;       - the stride words at +0xEC and +0xEE are read and MULTIPLIED BY;
;       - a catalogue's row count is not merely equal to its footer's LE16, it
;         is bounded by it at run time, in all five catalogue/footer pairs;
;       - an index map's VALUE is a catalogue row number, 0xFFFF meaning none.
;     ⚠ BUT 13 of the 39 filled primary slots still have NO reader -- including
;     the two largest structures, the descriptor blocks at +0x30/+0x38 and the
;     wave-select arrays at +0x18/+0x20.  Those keep their transplanted names,
;     and their banners say so in as many words.
;   * The MEANING of individual fields -- inside a tone record, an element
;     block, a wave-select record, a drum-instrument record, a descriptor -- is
;     STILL unknown throughout.  Round 3 read a consumer's ADDRESS ARITHMETIC;
;     it did not read one field.  Where a comment states a field, it states a
;     shape (a count, an offset, a stride) that was measured, never a semantics.
;   * ⚠ WAVE 7 ROUND 2 changed this bullet.  It used to read "Three regions
;     resist framing": the descriptor blocks at slots +0x30/+0x38/+0x70, the 768
;     extra bytes in the index map at +0x28, and the 8 x 128-byte table at +0xA8.
;     The first four are now FRAMED, each from evidence inside the image itself:
;       - +0x30/+0x38/+0x70 are an ARRAY of 14-byte descriptors over a POOL, and
;         the descriptors' own 32-bit offsets say where the array ends.  318, 161
;         and 4 descriptors; header + pool tiles each block exactly; the LAST
;         descriptor's offset is the last object in its pool.
;       - the 768 bytes at 0x22A3B are SIX 128-byte monotone curves, and what
;         says so is that all 318 part-A objects of slot +0x30 begin with a
;         32-bit offset naming one of exactly those six addresses.
;     What still resists: the PURPOSE of the 8 x 128-byte table at +0xA8 (the
;     KN5000 leaves that slot unused, so there is no name to transplant and none
;     is invented -- though round 3 confirmed its 128-byte RECORD SIZE from
;     prom_c's own indexing), and every FIELD inside a descriptor, a curve or a
;     pool row.
;     notes/prom_d_structures_round2.py, 78 checks.
;   * Directory slot +0x88 holds 0x125.  In the KN5000 the same slot holds a
;     SCALAR, not an offset.  Nothing here decides which prom_d means.
;
; ------------------------------------------------------------------------------
; ★ WAVE 7 ROUND 7 -- THE WHOLE-IMAGE INVENTORY, AND THE HONEST HALF OF IT
; ------------------------------------------------------------------------------
; Every label in this file carries either a WITNESS -- a route from the bytes
; to the name -- or a stated REASON for having none, and ONE command re-checks
; all 3,665 of them:
;
;     python3 notes/prom_d_finish_round7.py
;
;   witnessed  3,432   the name has a route: the object's own ASCII, an
;                      Evidence: line, or a witnessed object it is part of
;   nameless     232   NOT named -- and the reason is stated PER OBJECT, in
;                      this file, next to the object it is about
;   boundary       1   prom_d_end, a zero-length end marker, not an object
;   ★ NO WITNESS AT ALL: 0
;
; ⚠ AND GRADED BY PROVENANCE, WHICH IS WHAT A PERCENTAGE HIDES.  A name can
; rest on very different things, and this image's rest mostly on two:
;   self-named        1,708  the object's own 13- or 16-byte ASCII field
;   KN5000 transplant 1,335  ⚠ the name is the SIBLING MACHINE'S, and NO prom_c
;                            instruction reads the directory slot the region
;                            it sits in hangs off.  The slots, in full:
;                            +0x0C +0x10 +0x14 +0x18 +0x20 +0x24
;                            +0x28 +0x2C +0x30 +0x38 +0x48 +0x5C
;   image-internal      337  a relation measured inside this image
;   reader-backed        52  prom_c reads the slot and the read says what it is
;   nameless            232  the 232 above, kept in the same denominator
; So a reader who wants only what THIS machine's firmware confirms should
; discount 1,335 of the 3,665 labels below.  That is the number, said once, here.
;
; ⚠ AND THE 93.7% CONTENT FIGURE THIS FILE SCORES ON
; notes/wave7_documentation_metrics.py IS NOT ROBUST TO SPELLING.  491 of the
; labels it grades CONTENT are <stem>_<Word><digits> whose digits run 0..n-1
; over three or more siblings with no self-named ancestor -- the same shape as
; `PercInst_17`, which the same metric grades FRAMED.  The difference is an
; underscore before the number.  Counting those as framed instead, this file
; reads 80.3%.  Both are true of a stated rule and neither is quoted without
; the other.  notes/prom_d_finish_round7.py Q1, Q2, Q8; 56 checks.
;
; ------------------------------------------------------------------------------
; ★ WAVE 7 ROUND 8 -- THE THREE QUESTIONS, AND WHAT SURVIVES THEM
; ------------------------------------------------------------------------------
; Round 7 gave every label a verdict.  What it did not do is ask the same
; three questions of each, so a nameless object was nameless because ONE
; naming rule had failed on it.  Round 8 asks, of all 3,665:
;     A  does the object CONTAIN a name -- its own ASCII?
;     B  does a prom_c READER reach the region it is in?
;     C  does anything POINT AT it -- a stored index, one of this image's
;        own 1,281 pointer fields, or an address spelling?
; 3,433 NAMED, 232 NAMELESS -- and every nameless object carries all three
; answers below, not one mechanism's failure.
;
; ⚠ AND THE TABLE ADMITS ITS OWN GAP: 854 objects are NAMED while answering
; NO to all three.  They are named by round 6's fourth route -- the object
; CONTAINS A COPY of a named object's bytes -- which is why the three answers
; are printed as facts about routes and NOT as a verdict.
;
; ★ WHAT ROUND 8 NAMED: 31 records whose bytes are carried by two or three
; DIFFERENTLY NAMED records.  Round 6 gave them no label because `nothing
; picks one of them`; round 8 states all of them instead of stating none, and
; `_Or_` is what says no owner was picked.  The bound is 3 names.
;
; ★ WHAT THE STORED-INDEX CENSUS SETTLED, and it is the census round 7's own
; conclusion implied: a record here is reached by an INDEX, so the question
; is which stored index values exist.  Only one field in the image can select
; a wave-select preset.  ⚠ WAVE 7 ROUND 9 CORRECTED THIS SENTENCE'S
; DENOMINATOR: over all 1,549 wave-select records the field takes 64 distinct
; values, because the preset array's OWN +0x0B carries each record's own
; index.  Over the 1,485 records that are not the preset array itself it takes
; 7 -- so 57 of the 64 records of ToneDB_WaveSelTailPresets are
; selected by NOTHING STORED in this image, and each says so on itself.
;
; ⚠ FOUR MORE MECHANISMS MEASURED AND REJECTED (Q4), including the strongest
; one this image offers: the +0x20 array is in its owners' index order with
; 0 backward steps over 106 anchors, so an ambiguous record's owner is
; confined to an interval -- and the interval leaves exactly one candidate 0
; times.  Refuted by its own measurement, and written down so it is not
; re-invented.
;
; ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed.  Round 8 re-attacked it from
; the image's own pointers: 1,281 directory slots, tone-record offsets and
; descriptor pointers, and 0 of them is an absolute address.
;
;
; ------------------------------------------------------------------------------
; ★★ WAVE 7 ROUND 9 -- THE WHOLE-IMAGE LABEL AUDIT, AND WHAT IT FOUND
; ------------------------------------------------------------------------------
;
; Rounds 2-8 each measured something new and wrote it here.  None of them
; ever re-read THIS FILE against the ROM.  That is the gap round 9 closes,
; and it is the gap the byte gate is blind to by construction: the gate
; certifies the .byte directives and says nothing about the label above them
; or the sentence above that.
;
; ★ ONE COMMAND NOW RE-CHECKS THE WHOLE IMAGE:
;       python3 notes/prom_d_inventory_round8.py --selftest
; It re-derives every one of the 3,665 labels below -- its INDEX, its ADDRESS
; and its NAME -- from prom_d's own bytes and compares the result with the
; text in this file.  0 are REFUTED and 0 are unreached.
;
; ★★ AND IT PUBLISHES A HARSHER NUMBER THAN THE GOAL METRIC'S UPPER BOUND
; OF 100 PER CENT:
;       2,897 of 3,665 labels have their NAME re-derived from this image's own
;       bytes -- a record's ASCII name field, a measured byte identity, a
;       curve's own run lengths, a descriptor's own 32-bit offsets;
;       768 have only their ADDRESS derived.  Those names are structural
;       or transplanted and this image does not spell them.
;     Framing is not naming, and that split is the honest reading of a
;     file with zero sub_XXXXXX.
;
; ⚠ WHAT THE AUDIT FOUND IN ALREADY-COMMITTED PROSE -- both corrected in
;   scripts/analysis/gen_prom_d_asm.py, which is the only place a fix
;   survives a regeneration:
;     * the stage-2 table shared by descriptors 0..160 of slot +0x38 is 132
;       bytes -- 128 entries -- and its comment said `108 entries`, which is
;       max(curve)+1 and true only where each descriptor has its OWN table.
;       A sentence refuted by its own object.  The count is now the object's
;       length and the curve's reach is a second clause; Q10d re-derives all
;       319 of these sentences from the pool tiling.
;     * the stored-index census above quoted 1,549 as the denominator for
;       `7 distinct values`.  Over 1,549 the field takes 64, because a
;       preset record's own +0x0B is its own index at 63 of its 64 records
;       (round 9 Q11).  7 is the figure over the other 1,485.
;
; ⚠ AND ROUND 9 PROMOTED NOTHING.  Three mechanisms that would have moved
;   the count were measured and refused, so a later round need not re-invent
;   them:
;     * the twin rule -- the one that named 194 records in the +0x18 and
;       +0x20 arrays -- run for the first time on the 64 records of
;       ToneDB_WaveSelTailPresets: 0 carried, against the melodic blocks
;       AND against the drum tails.  Those 64 labels stay framed for a
;       measured reason now, not for want of trying.  (Q12)
;     * M8, the mechanism after round 8's M7: place a record NO byte
;       identity reaches by the monotone owner order.  0 of 12 on the +0x20
;       array, whose order holds; on the +0x18 array, which has 28 backward
;       steps over 152 anchors, it proposes ONE owner for THREE different
;       records, which refutes it.  (Q13)
;     * General MIDI, the obvious route to naming a program-map row.  Round
;       5 refused it by citing two programs; round 9 refuses it with a count
;       and reads the 16 family names out of prom_b's own `GM RE-MAP` screen
;       instead of typing them: the best row aligns on 18 of 128 programs
;       where a deliberately rotated null aligns on 11, and the eight rows
;       score 15..18, so it does not tell them apart either.  (Q14)
;
; ⚠ ORIGIN STAYS 0 and round 9 proposes no change to it.  What is still open
;   is WHICH PHYSICAL PART this is -- a document question, not a disassembly
;   one, and no census of these bytes can answer it.
;
;
; ------------------------------------------------------------------------------
; ★★ WAVE 7 ROUND 11 -- THE SOUND GROUP: WHAT THE PANEL CALLS TONE k
; ------------------------------------------------------------------------------
;
; Every round from 4 to 10 asked this image about itself, or about prom_c,
; which is the only image that READS it.  Round 11 asked the two images
; nobody had opened: prom_a, which paints the panel, and prom_b, which
; stores the panel's text.  They settle a sentence that had stood over this
; image's tone table since round 4 -- that its index order is `a Technics-
; internal ordering; nothing here identifies which panel control it
; corresponds to`.
;
; ★★ THE TONE INDEX IS 8*GROUP + MEMBER, and it is a proof rather than an
; alignment:
;   * prom_a addresses prom_b's group/member table at 0xF06EF4 as 0xFC230C
;     `mul WA,0x0010` + 0xFC2317 `mul BC,0x0002` + 0xFC231D `add XBC,
;     0x00F06EF4` -- 16 bytes per group over 2 bytes per member, so a
;     group's row holds 8 members.  prom_b's own
;     GroupMaxMemberIndex_ToneGroups at 0xF06EB4 holds 0x07 in all 16 of its
;     bytes, which is the same number said a second way.
;   * entry k of that table is a (program, bank-select) pair, and resolving
;     it through THIS image's own ToneDB_BankMap (+0x6C) and
;     ToneDB_ToneNumBanks (+0x04) gives tone k -- 272 consecutive entries,
;     entry 0 and entry 271 both checked, and entry 272 is the first that is
;     not its own index.  So the table is the INVERSE of this image's
;     program map and is indexed by TONE INDEX.
;   * 272 / 8 = 34 groups, and prom_b's 16-byte name table at 0xF068B4 has
;     EXACTLY 34 named rows before row 34 turns into `----------------`:
;     PIANO, E.PIANO, HARPSI. & MALLET ... PERCUSSION, EFFECT, DRUMS 1,
;     DRUMS 2.
;
; ⚠ WHICH NAME GOES WITH WHICH OCTET is a SEPARATE claim from that, and it
;   has two independent witnesses rather than an assertion: 23 of the 34
;   group names share a word of >=3 letters with one of the 8 tone names
;   their octet holds, where rotating the numbering scores at most 7 -- and
;   the +/-1 shifts are NOT independent nulls, because the list has runs like
;   GUITAR 1/2/3, which Q21 states rather than hides.  And at the END of the
;   table, where a rule that stops early shows, the 16 tone names ending in
;   `Kit` occupy exactly groups [32, 33], which are exactly the rows whose text
;   spells DRUM.  11 groups share no word and are listed by name in Q21.
;
; ⚠ WHAT IT DOES NOT SAY: it names no BYTE of a tone record and says
;   nothing about what a group means to the synthesis.  It says what the
;   PANEL calls tone k, and every banner below claims only that.
;
; ★ WHAT IT NAMED: 8 framed records of ToneDB_MixerDefaultTable, as
;   `_SelectedForGroup_<GROUP>` -- the records whose map columns ALL lie in
;   one group.  The bound is 1 and not round 8's 3 because a group already
;   names 8 tones; the sweep to 5 is printed in Q22.  Two of the 8 are the
;   records round 10 refused because the only tone name there CamelCases to
;   `161`, and one is the LAST record of the array, which round 10 refused
;   for carrying four names.
;   ⚠ AND THE RULE COSTS ONE NAME, printed rather than left implicit:
;   round 10 never labels a record that HAS a byte twin, so that no derived
;   name can contradict another, and M10 keeps that rule.
;    record 67's map columns are all STRINGS 1, while the tone blocks that
;    carry its bytes reach STRINGS 1 and STRINGS 2.
;   That is the record the rule is for.  (Q22f)
;
; ⚠ AND WHAT IT REFUSED, measured rather than skipped:
;   * the 64 records of ToneDB_WaveSelTailPresets.  The 7 presets anything
;     selects at all are selected by records of the +0x18 array, and none
;     reaches one group by either route.  The nearest miss is preset 4, ALL
;     16 of whose records are identified and which spans BRASS, TRUMPET and
;     DEEP BRASS -- three groups, 24 tones.  (Q24)
;   * the 37 framed records of ToneDB_PercMixerDefaultTable: a drum record's
;     group can only be one of the 2 rows spelling DRUM, so the coarser
;     question is coarser than the array itself.  (Q25)
;   * tone record 0x05D, whose own 16 bytes are the drawbar registration
;     this tree's CamelCase rule turns into `161`.  It is member 5 of group
;     11 'ORGAN' -- so the object is PLACED -- and it KEEPS the `161` label,
;     because spelling the apostrophes would invent a morpheme.  (Q26)
;
; ★★ AND A CENSUS ROUND 10 RAN ON ONE MAP, RUN ON ALL TEN.  Of the ten
;   1,024-entry maps whose range fits the 322-record array, ONLY slot +0x0C
;   is a selector: it agrees with the byte rule on 69.9% of its asked
;   positions and the best of the other 9 reaches 3.3%, each within a
;   few points of its own shuffled null.  It reaches 0 of the 111 unreached
;   records, while the maps that DO reach them are exactly the ones that
;   fail the test.  So `unreached` is now a statement about the only map
;   that IS a selector, not about the only map anyone tried.  (Q23)
;
;
; ------------------------------------------------------------------------------
; ★★ WAVE 7 ROUND 12 -- EVERY REMAINING FRAMED LABEL, WITH A REASON EACH
; ------------------------------------------------------------------------------
;
; Rounds 4-11 each measured something new.  What this image did not have is
; the thing a FINISHED image needs: one table that names every object still
; carrying a kind-plus-a-number and states, per object, why.  Round 12 is
; that table -- 232 objects in 5 families, a reason DERIVED for each, and one
; command that re-checks it:
;       python3 notes/prom_d_finish_round12.py            # the inventory
;       python3 notes/prom_d_finish_round12.py --selftest # 35 checks
;
; ★★ AND IT PROMOTES NOTHING, ON PURPOSE.  Three mechanisms were run for
; the first time and none of them is spent:
;
;   * M11, THE TAIL-ONLY TWIN RULE.  Round 9's Q12 ran the twin rule on the
;     +0x3C array over WHOLE records and got 0 of 64.  But a preset supplies
;     only bytes 13..42 -- prom_c 0xFBC7D9 sets i = 13 and 0xFBC7E3 reads
;     the stride word 43 as the bound -- so the head has nothing it must
;     match and the old test was harder than the mechanism needs.  Run on
;     the exact 30 bytes prom_c copies, against the 1,485 wave-select records
;     that are not this array: 0 of 64.  ★ AND THE TEST IS NOT INERT --
;     1,309 of those 1,485 records DO share a tail with another record, so a
;     30-byte match is something this corpus produces in quantity.  The
;     preset array shares none of them.
;
;   * M12, ROUND 8's M6 WITH ROUND 11's GROUP.  M6 named a no-twin record
;     from the preset RUN it sits in and was refused for want of a common
;     WORD; round 11 then supplied GROUPS, which are coarser, and nobody
;     re-ran it.  Run here it proposes 19 names -- and it is REFUSED, by the
;     witness it would have to agree with: where the run route and round
;     11's map route both give exactly one group they DISAGREE on 7 of 40,
;     and on the only proposal the map reaches at all (record 41) the run's
;     answer, 'ETHNIC PERC.', is not even among the map's 4 groups.
;     ⚠ 17 of the 19 proposals come from ONE run with a single identified
;     member.  M12 IS REFUSED; a later round need not re-invent it.
;
;   * ★★ prom_b's 64-ENTRY NAME TABLE -- A CANDIDATE, AND THE GAP THAT
;     KEEPS IT ONE.  prom_b 0xF03241 holds exactly 64 rows of 8 printable
;     bytes and stops ('ORIGINAL' .. 'SPECIAL2').  It is read by exactly
;     4 display-list records, on the consecutive variables
;     0x2808 0x2809 0x280A 0x280B, 
;     each masking with 0x3F -- the same mask prom_c applies at
;     0xFBC744 before indexing this image's 64-record
;     ToneDB_WaveSelTailPresets; rows 38..63 of it are 13 `X L` /
;     `X H` pairs on the parity the paragraph below measures; and
;     prom_a clamps that variable's edit range to 0..0x3F at 0xFD4176.
;     If the panel variable IS that field, all 64 framed records of the
;     +0x3C array are named at once.
;     ⚠⚠ NOTHING IN THE FOUR IMAGES SHOWS THAT IT IS.  The panel variable
;     lives in one CPU's RAM at 0x2808..0x280B; the field is byte +0x0B of
;     a 43-byte record in the other CPU's RAM at 0x87D2 + 43*n, and no
;     instruction has been shown to carry the first into the second.  Two
;     6-bit fields with the same mask and the same range are not the same
;     field.  Nor is the candidate forced by elimination: 1 other table
;     of 64 rows is reached with the same mask (0xF33022).
;     ★ WHAT WOULD CLOSE IT: an instruction chain from Arr2808_Set1
;     (prom_a 0xFDA85E) to the link message prom_c decodes into
;     (record + 0x0B).  Q31 states it so a later round can go straight at it.
;
; ★ WHAT DOES STAND ON THIS IMAGE'S OWN BYTES: the +0x3C array is built in
; EVEN-ALIGNED PAIRS.  Over records 38..63 a record's mean Hamming distance
; to its neighbour is 7.23 of 43 bytes when the lower index is even and 13.67
; when it is odd (AUC 0.929) -- and rows 38..63 of prom_b's table are 13
; `X L` / `X H` pairs on that same parity.  ⚠ IT IS A PARITY WITNESS AND
; NOT AN ALIGNMENT PROOF: Q32 prints the shift sweep and EVERY EVEN SHIFT
; scores the same.  Quoting it as an alignment result would be quoting it
; wrong, so the refutation is printed beside it.
;
; ★ AND THE UNREACHED RECORDS ARE NOT PADDING.  The easiest way to dismiss
; the 122 records of the +0x18 array the selector map reaches at no entry is
; to suppose the array is over-allocated.  Measured: all 122 are byte-DISTINCT
; from one another (largest identical group 1), one run of them 58 records
; long; the +0x20 array's 37 framed records are likewise 37 distinct.
; Padding repeats; these do not.  The hole here is real data whose selector
; this tree has not found, and saying so is the honest version of the score.
;
; Reproduce every number quoted in this file:
;     python3 scripts/analysis/prom_d_tone_database.py
;     python3 notes/prom_d_structures_round2.py        # the record framing, 78 checks
;     python3 notes/prom_d_documentation_round3.py     # who READS it, 62 checks
;     python3 notes/prom_d_base_checks.py              # the base, 12 checks
;     python3 notes/prom_d_split_probe.py              # ★ THE SPLIT LOST NOTHING
;     python3 notes/prom_d_finish_round7.py --selftest # the inventory, 56 checks
;     python3 notes/prom_d_inventory_round8.py --selftest # ★ THE WHOLE IMAGE, 129 checks
;     python3 notes/prom_d_finish_round12.py --selftest  # ★ THE FRAMED SET, 35 checks
; Regenerate this file:
;     python3 scripts/analysis/gen_prom_d_asm.py
; Then, always:
;     python3 scripts/analysis/assert_byte_identical.py
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).
; ==============================================================================

; ==============================================================================
; ★★ WAVE 17, LANE w17/tone-db -- THE FORMAT, AS C STRUCTS, FROM ITS READERS
; ==============================================================================
;
; ⚠ WHY THIS BLOCK IS HERE AND NOT ON THE REGION BANNERS.  The three files this
; one `.include`s are GENERATED by scripts/analysis/gen_prom_d_asm.py, which is
; another lane's file; a comment added to a generated .s would be lost on the
; next regeneration and the byte gate would not notice.  This file is not
; generated, so this is where a hand-written addition survives.  Nothing below
; is repeated from, or contradicts, a banner over there -- it ADDS the field
; layer the header above says is missing:
;
;     "The MEANING of individual fields -- inside a tone record, an element
;      block, a wave-select record, a drum-instrument record, a descriptor --
;      is STILL unknown throughout.  Round 3 read a consumer's ADDRESS
;      ARITHMETIC; it did not read one field."
;
; That is now PARTLY false, and this block is the retraction, with the parts
; that are still true kept: fourteen fields are named from a reader, and every
; other byte is still UNIDENTIFIED and is spelled `unk_<offset>` below.
;
; ★ THE READER IS prom_c/tone_db/tone_db_module.s, which this lane owns as
;   well.  Read its header for the RAM side (the 0x0087D2 staging image, the
;   300-byte part record).  Every instruction cited below is re-decoded from
;   the ROM bytes at the address it is cited at by
;   wsa1/notes/tone_db_naming_w17.py -- 102 checks, each with the cited
;   literal's image-wide occurrence count beside it as its null.
;
; ★ HOW TO READ THE GRADES, which are per FIELD and not per struct:
;     PROVEN        a reader settles it: an instruction reads or writes that
;                   offset and what it then does with the value is decoded.
;     STRONG        several independent facts agree and no null explains them.
;     WEAK          one suggestive pattern.  Not rounded up.
;     UNIDENTIFIED  the offset is inside a framed object and nothing names it.
;   ⚠ A PROVEN field is proven to be READ THAT WAY.  It is NOT proven to mean
;   anything musical: `+0xD0 low nibble indexes a 12-entry algorithm table` is
;   a fact about the firmware, not about the synthesis, and where the musical
;   reading is missing the struct says so.
;
; ------------------------------------------------------------------------------
; THE DIRECTORY, file 0x00000
; ------------------------------------------------------------------------------
;   struct ToneDB_Directory {           /* 256 B; every offset is FILE-RELATIVE */
;       le32 slot[48];                  /* +0x00..+0xBF  PROVEN pointers:       */
;                                       /*   99 reads load a 32-bit register    */
;       le16 scalar[32];                /* +0xC0..+0xFF  PROVEN scalars:        */
;                                       /*   99 of 99 reads load a 16-bit one   */
;   };
;   The named slots are on ToneDB_Directory's own banner in
;   tone_database_directory.s and are not repeated.  What wave 17 adds is
;   which of them a reader REACHES, below.
;
; ★★ FIVE SLOTS THE HEADER ABOVE LISTS AS HAVING NO READER, DO.
;   The header says "13 of the 39 filled primary slots still have NO reader --
;   including the two largest structures, the descriptor blocks at +0x30/+0x38
;   and the wave-select arrays at +0x18/+0x20."  For +0x18, +0x1C and +0x20 --
;   and for the index maps +0x0C, +0x10 and +0x14 -- that is now WRONG, and the
;   reason round 3's census missed them is mechanical, not a judgement call:
;   the census matched the instruction pair `load the base; load (base + slot)`,
;   and prom_c 0xFB82C3 SPILLS THE BASE TO ITS FRAME first (0xFB82ED/0xFB82F2,
;   0xFB82F5/0xFB82FA), so the pair never occurs at the indexing site.
;
;     0xFB8369  ld XWA,(XBC+0x0c)   +0x0C  ToneDB_ToneIndexMapA
;     0xFB836F  ld XIY,(XBC+0x18)   +0x18  ToneDB_MixerDefaultTable
;     0xFB8398  ld XWA,(XBC+0x14)   +0x14  ToneDB_PercSourceIndexMapA
;     0xFB839E  ld XIY,(XBC+0x20)   +0x20  ToneDB_PercMixerDefaultTable
;     0xFB83C6  ld XWA,(XBC+0x10)   +0x10  ToneDB_ToneIndexMapB
;     0xFB83CC  ld XIY,(XBC+0x1c)   +0x1C  the +0x18 alias
;
;   and the walk is, in full (prom_c ToneDB_ResolveWaveSelectRecord):
;       row = a 16-byte wave-catalogue row
;       i   = (row[15] & 0x0F) * 128 + (row[14] & 0x7F)     /* 8 banks x 128 */
;       n   = le16 at  dir[map]   + 2*i
;       rec =          dir[array] + n * dir[stride]          /* stride = 43 */
;   with (map, array, stride) = (+0x0C, +0x18, +0xEA) when row[15] & 0xC0 is
;   0x00 or 0xC0, (+0x14, +0x20, +0xF0) when it is 0x40, and (+0x10, +0x1C,
;   +0xEA) when it is 0x80; row[15] bit 5 switches the whole walk to the
;   EXPANSION BOARD's directory at RAM 0x00D80D / 0x00D811.
;   ★ 8 * 128 = 1024 is exactly the entry count this file already gives those
;   index maps, derived on the other side from their spans.  Two routes, one
;   number.  And it AGREES WITH ROUND 11's Q23, which measured statistically
;   that +0x0C selects records of the +0x18 array (69.9% against 3.3% for the
;   best of the other nine maps): Q23 found the relation, this is the
;   instruction that performs it.
;   ⚠ WHAT IT DOES NOT SAY: nothing here reads a FIELD of the record it
;   returns, except +0x0B.  And it says nothing about +0x30/+0x38, which
;   remain unread.
;
; ------------------------------------------------------------------------------
; THE MELODIC TONE RECORD -- 217 + N*81 + N*43, N = 1..4
; ------------------------------------------------------------------------------
;   struct ToneRec {
;       char  name[16];             /* +0x000  PROVEN  the record's own ASCII  */
;       u8    kind;                 /* +0x010  STRONG  bits 7:6 select the
;                                              loader's arm: 0x80 is the DRUM
;                                              path in prom_c 0xFB876B and in
;                                              0xFBAB6C, and 0x80 is the value
;                                              this image carries in all 18 kits
;                                              and in no melodic record         */
;       u8    element_mask;         /* +0x011  PROVEN read: prom_c 0xFB433D
;                                              loads it and passes it to the
;                                              selector at 0xFB405F, whose 0xFF
;                                              answer means `no element` and
;                                              takes the default-block arm.
;                                              The 2-bits-per-slot reading is
;                                              this image's own census          */
;       u8    unk_012[190];         /* +0x012..+0x0CF  UNIDENTIFIED             */
;       u8    dsp_algo;             /* +0x0D0  PROVEN  bits 0:3 index prom_c's
;                                              DSP_AlgoDescriptor_Records
;                                              (0xFDF4F1, 12 records x 39 B):
;                                              0xFBB3B3 loads it, 0xFBB3B8
;                                              masks 0x0F, 0xFBB47D bounds it
;                                              at 11 and the table at 0xFBB48C
;                                              has 12 entries.  Bit 7 is a flag
;                                              prom_c 0xFB87B7-0xFB87C5 mirrors
;                                              from part record +0x09 bit 15.
;                                              Bits 4:6 UNIDENTIFIED            */
;       u8    dsp_param[8];         /* +0x0D1..+0x0D8  PROVEN as a GROUP: eight
;                                              routines write exactly this run
;                                              from one DSP_AlgoDescriptor row,
;                                              a different map per algorithm
;                                              type.  Each byte's meaning
;                                              UNIDENTIFIED                     */
;       ToneRec_Element element[N]; /* +0x0D9  PROVEN  81 B each, prom_c
;                                              0xFB436D-0xFB4379                */
;       WaveSelRec      wavesel[N]; /* +0x0D9 + 81*N  PROVEN  43 B each; for
;                                              N = 4 that is +0x21D = 541, the
;                                              literal prom_c 0xFB844D adds     */
;   };
;   ★ THE HEAD ENDS EXACTLY WHERE THE DSP BLOCK ENDS: 217 = 0xD9, so +0xD0..
;   +0xD8 are the LAST NINE BYTES of the head, and they are the only nine any
;   reader interprets.  ⚠ Two more head bytes are WRITTEN and not read here:
;   +0x023 and +0x024, which prom_c copies from part record +0x17/+0x18 at
;   0xFB888B/0xFB88A4 and again at 0xFBABA9/0xFBABB9.  PROVEN as a copy;
;   UNIDENTIFIED as a meaning.
;   ⚠ NULL for `541 = 217 + 4*81`: over h in [0,713) and s in [1,150] uniform,
;   135 of 106,950 pairs satisfy h + 4s = 541 (0.13%) -- and here h and s are
;   both separately cited instruction literals rather than fitted.
;
;   struct ToneRec_Element {        /* 81 B                                     */
;       u8   unk_00[2];             /* +0x00..+0x01  UNIDENTIFIED               */
;       u8   sel_program;           /* +0x02  PROVEN  byte 14 (+0x0E) of the
;                                            chosen wave-catalogue row; prom_c
;                                            0xFB911A reads it and 0xFB9150
;                                            stores it HERE -- see the caveat
;                                            below                              */
;       u8   sel_bank_family;       /* +0x03  PROVEN  byte 15 (+0x0F) of the
;                                            same row (0xFB912E / 0xFB9173).
;                                            The two together are exactly what
;                                            ToneDB_ResolveWaveSelectRecord
;                                            consumes, so this pair IS the
;                                            element's wave selection           */
;       u8   unk_04[73];            /* +0x04..+0x4C  UNIDENTIFIED               */
;       u8   tail[4];               /* +0x4D..+0x50  PROVEN as a copy: prom_c
;                                            0xFB8828-0xFB8870 copies these
;                                            four bytes into the 4 x 5 RAM
;                                            table at staging image +0x4F6C,
;                                            one row per element, with the
;                                            row's first byte taken from the
;                                            part record instead.  Meaning
;                                            UNIDENTIFIED                       */
;   };
;   ★★ AND +0x02 / +0x03 ARE THE PAIR ToneDB_ResolveWaveSelectRecord CONSUMES,
;   which is what makes an element block's wave choice and its wave-select
;   record one mechanism: 0xFB918E-0xFB919D pushes the same two bytes straight
;   into the resolver.  ⚠ THIS CONTRADICTS AN EXISTING COMMENT in prom_c and
;   the contradiction is REPORTED, not silently fixed -- see
;   `python3 notes/tone_db_naming_w17.py --wrong`.  The prom_c header of
;   ToneDB_SourceNameList1_SelectEntry says the two bytes go to "+0x02 and
;   +0x03 of the part element record at 0x1523 + 0x012C*part + 0x29*element +
;   0x88"; 0xFB914B is a 32-bit LOAD from that address and 0xFB9150 stores two
;   bytes past the value it LOADED, and the same field is the source of an
;   81-byte copy at 0xFB8520/0xFB853E.
;
;   struct WaveSelRec {             /* 43 B; the stride at directory +0xEA/+0xF0 */
;       u8   unk_00[11];            /* +0x00..+0x0A  UNIDENTIFIED               */
;       u8   tail_preset;           /* +0x0B  PROVEN  bits 0:5 select a row of
;                                            directory slot +0x3C
;                                            (ToneDB_WaveSelTailPresets); 0
;                                            means `keep the tone's own`.
;                                            prom_c 0xFBC741 / 0xFBC744 /
;                                            0xFBC74E, then 0xFBC7B6 (+0x3C)
;                                            scaled by 0xFBC7BE (+0xEA).  Bits
;                                            6:7 UNIDENTIFIED                   */
;       u8   unk_0C;                /* +0x0C  UNIDENTIFIED                      */
;       u8   tail[30];              /* +0x0D..+0x2A  PROVEN as a SPAN: the
;                                            preset supplies exactly bytes
;                                            13..42, prom_c 0xFBC7D9 (i = 13)
;                                            to 0xFBC7E3 (bound = +0xEA = 43).
;                                            No individual byte identified      */
;   };
;   ⚠ THIS DOES NOT CLOSE ROUND 12's Q31.  That round asked whether the panel
;   variable at prom_a/prom_b RAM 0x2808..0x280B IS this field and refused to
;   say so for want of an instruction chain.  Nothing here supplies one: this
;   says what prom_c DOES with the field, not where its value comes from.
;
; ------------------------------------------------------------------------------
; THE DRUM-KIT RECORD -- 408 B, tone indices 0x100-0x111
; ------------------------------------------------------------------------------
;   struct DrumKitRec {
;       char name[16];              /* +0x000  PROVEN  its own ASCII            */
;       u8   common[136];           /* +0x010..+0x097  UNIDENTIFIED             */
;       u8   note_map[128][2];      /* +0x098  PROVEN  one entry per MIDI note.
;                                            prom_c 0xFB8900 bounds the loop at
;                                            0x80, 0xFB8913 scales by 2, and
;                                            0xFB891C / 0xFB892A read the entry's
;                                            TWO BYTES SEPARATELY (+0x99+2n and
;                                            +0x98+2n) and push them as TWO
;                                            arguments to
;                                            DrumKit_ResolveInstrumentRecord.
;                                            So it is a byte PAIR the firmware
;                                            never adds up, not an LE16         */
;   };
;   16 + 136 = 0x98 and 0x98 + 2*128 = 408, and prom_c copies exactly 408 bytes
;   (`push 0x0198` at 0xFB856F) into its kit staging image.  The 16/136/128x2
;   framing was this image's own; the reader now confirms all three parts.
;
; ------------------------------------------------------------------------------
; THE DRUM-INSTRUMENT RECORD -- 150 B, the stride at directory +0xEE
; ------------------------------------------------------------------------------
;   struct PercInst {
;       char       name[13];        /* +0x00  PROVEN  its own ASCII             */
;       u8         unk_0D[51];      /* +0x0D..+0x3F  UNIDENTIFIED               */
;       WaveSelRec wavesel[2];      /* +0x40 and +0x6B  PROVEN  prom_c copies
;                                            0x40 = 64 bytes to the record base
;                                            (0xFB85F4) and then, for j = 0..1
;                                            (`cp (XIZ+0xf3),0x02` at 0xFB897D),
;                                            43-byte records to base + 0x40 +
;                                            43*j (0xFB868F: 0x4A1 - 0x461 =
;                                            0x40)                              */
;   };
;   64 + 2*43 = 150 EXACTLY, so the head and the two wave-select records tile
;   the stride word +0xEE with nothing left over.  ⚠ NULL: over a head h in
;   [0,150) uniform, P(h + 2*43 = 150) is 1/150 = 0.67%; the multiplicity 2 is
;   a loop bound in the ROM, not a fitted parameter.
;
; ------------------------------------------------------------------------------
; A WAVE-CATALOGUE ROW -- 16 B, in all five catalogues
; ------------------------------------------------------------------------------
;   struct WaveCatRow {
;       char name[13];              /* +0x00  PROVEN  its own ASCII             */
;       u8   unk_0D;                /* +0x0D  UNIDENTIFIED                      */
;       u8   sel_program;           /* +0x0E  PROVEN  bits 0:6 are the low half
;                                            of the wave-select index; bit 7 is
;                                            cleared and discarded (prom_c
;                                            0xFB82CA `res 0x07,C`)             */
;       u8   sel_bank_family;       /* +0x0F  PROVEN  bits 0:3 a BANK of 128
;                                            (0xFB82D5, then `sll 0x07` at
;                                            0xFB840F); bit 5 selects the
;                                            EXPANSION BOARD's directory
;                                            (0xFB82E0, arms at 0xFB8303);
;                                            bits 6:7 select which (index map,
;                                            record array, stride) triple
;                                            (0xFB8358).  ⚠ BIT 4 IS READ AND
;                                            NEVER ACTED ON: the mask is 0x30
;                                            and 0x00/0x10 take the same arm,
;                                            as do 0x20/0x30                    */
;   };
;
; ★★ AND THE WHOLE WALK IS CONFIRMED ON THE DATA, 829 ROWS, 0 MISSES.
;   Running the decoded resolver over every row of the three catalogues whose
;   rows reach it (notes/tone_db_naming_w17.py Q11):
;       catalogue +0x50, 307 rows -> map +0x0C -> array +0x18   307/307 land
;       catalogue +0x64, 314 rows -> map +0x10 -> array +0x1C   314/314 land
;       catalogue +0x8C, 208 rows -> map +0x14 -> array +0x20   208/208 land
;   * every one of the 829 rows has a bank nibble <= 7, so none indexes past a
;     1024-entry map -- which is the 8-banks-x-128 reading, tested where it
;     could have failed;
;   * every one of the 3 x 1024 map entries is BELOW its array's record count,
;     and two of the three maxima ARE that count minus one: 321 of 322 and 207
;     of 208.  A uniform LE16 lands below 322 with probability 0.49%;
;   * the two MELODIC catalogues carry only family bits 0x00 and 0x80 -- the
;     two arms whose arrays hold 322 records -- and the PERCUSSION catalogue
;     carries only 0x40, the arm whose array holds 208.  829 of 829.  ★ That
;     is what bits 6:7 ARE, and the instructions alone could not have said it.
;   ⚠ AND BIT 5 IS UNEXERCISED IN THIS IMAGE: no internal catalogue row sets
;     it, so the expansion-board arm has no example here.  That is a measured
;     absence, not a claim about the board.
;   The catalogue's row COUNT is the leading LE16 of its footer slot, and
;   prom_c bounds the index against it at run time in all five pairs (round 3
;   Q4c).  The two selector bytes are also what the five *_SelectEntry routines
;   copy into an element block's +0x02/+0x03.
;
; ------------------------------------------------------------------------------
; WHAT THE AUX TABLES ARE, AND HOW EACH IS INDEXED
; ------------------------------------------------------------------------------
;   PROGRAM MAPS
;     +0x6C  ToneDB_BankMap          128 B, indexed by a MIDI bank-select
;                                    value, giving a ROW of +0x04.  PROVEN
;                                    (0xFA7301, 0xFB424F).
;     +0x04  ToneDB_ToneNumBanks     10 rows x 128 le16, indexed row*128 +
;                                    program, giving a TONE INDEX.  PROVEN
;                                    (0xFB4271 `sll 0x07`, 0xFB4276 `add BC,BC`).
;     +0x08  ToneDB_ToneOffsetTable  274 le32 FILE OFFSETS of tone records,
;                                    indexed by that tone index.  PROVEN
;                                    (0xFB429D, and 0xFB429F adds the base a
;                                    SECOND time, which is what makes these
;                                    offsets and not addresses).
;     +0xA8  ToneDB_OctaveShiftByProgram  8 rows x 128 bytes, indexed the same
;                                    way, holding 0x00 / 0xF4 / 0x0C = 0, -12,
;                                    +12 semitones.  PROVEN, and prom_c's own
;                                    Instrument_OctaveShift_Semitones fixes the
;                                    unit (round 11).
;
;   INDEX MAPS -- 1024 le16 each, and there are TWO KINDS
;     value = a WAVE-SELECT RECORD NUMBER, scaled by the 43-byte stride:
;       +0x0C -> +0x18   +0x10 -> +0x1C   +0x14 -> +0x20      PROVEN (0xFB82C3)
;     value = a WAVE-CATALOGUE ROW NUMBER, 0xFFFF meaning none:
;       +0x4C (round 3 Q4g, ToneDB_PercSourceIndexMapB_Lookup)  PROVEN
;       +0x24 +0x28 +0x2C +0x44 +0x48 +0x58 +0x5C +0x60         UNIDENTIFIED --
;         same 1024-entry shape, no reader located, and round 11's Q23 measured
;         that none of them behaves like +0x0C (best 3.3%, each within a few
;         points of its own shuffled null).  ⚠ THAT IS A MEASURED NEGATIVE, not
;         a gap: whatever they select, it is not the +0x18 array.
;     ⚠ The 8-banks-x-128 indexing is PROVEN for +0x0C/+0x10/+0x14 only.  For
;     the rest the 1024 is a span, and this block does not promote it.
;
;   WAVE-SELECT RECORD ARRAYS -- 43 B per record, stride +0xEA / +0xF0
;     +0x18 / +0x1C   322 records, reached by index map +0x0C / +0x10   PROVEN
;     +0x20           208 records, reached by index map +0x14           PROVEN
;     +0x3C / +0x40    64 records, the TAIL PRESETS, reached by a record's own
;                     +0x0B & 0x3F rather than by a map                 PROVEN
;
;   CATALOGUES AND THEIR FOOTERS -- 16 B per row; the footer's leading le16 is
;   the row count AND the run-time bound
;     +0x50 / +0x54  307 rows      +0x64 / +0x68  314 rows
;     +0x80 / +0x84  503 rows      +0x8C / +0x90  208 rows
;     +0x94 / +0x98  161 rows                                    all five PROVEN
;
;   DRUM TABLES
;     +0x74 / +0x7C  DrumKit_NoteMapA / B   2048 le16               UNIDENTIFIED
;     +0x78          PercInst               504 x 150 B, stride +0xEE   PROVEN
;
;   DESCRIPTOR BLOCKS -- a 14-byte descriptor array over a pool, the descriptors'
;   own le32 offsets ending the array
;     +0x70  DrawbarPreset_EnvDescTable   4 descriptors, stride +0xEC = 14.
;            PROVEN reader (DrawbarPreset_GetDescriptor, round 3 Q4e).
;     +0x30 / +0x34  318 descriptors, and +0x38  161 descriptors, stride +0xF2.
;            ⚠ STILL NO READER.  The framing is this image's own (round 2) and
;            wave 17 did not find one either: they are the largest structures
;            in the file and nothing in prom_c reaches their slots.
;     the six 128-byte monotone curves at file 0x22A3B are what all 318 part-A
;     objects of +0x30 point at.  UNIDENTIFIED as to what a curve IS.
;
;   TEMPLATES
;     +0xAC  ToneDB_DefaultLayerParams  one 81-byte element block plus one
;            43-byte wave-select record -- 124 B, one element's worth.  PROVEN:
;            prom_c takes it when the element selector answers 0xFF (0xFB4351,
;            0xFB4356).
;     +0xB0  ToneRec_Template_Clear     a 713-byte 4-element tone record.
;            PROVEN as the no-expansion-board fallback (0xFB41F1).
;     +0xB4  PercInst_Template_Silent   a 150-byte drum-instrument record.
;            UNIDENTIFIED reader; only sub_FB9B69 reaches the slot.
;
; ------------------------------------------------------------------------------
; ⚠ WHAT IS STILL UNIDENTIFIED, said as a count rather than left implicit
; ------------------------------------------------------------------------------
;   of the tone record's 217-byte head, 208 bytes;
;   of its 81-byte element block, 75 bytes;
;   of its 43-byte wave-select record, 41 bytes;
;   of the drum-kit record's 408, the 136-byte common part;
;   of the drum-instrument record's 150, 51 bytes of head after the name;
;   and every byte of every descriptor, curve and index-map ENTRY beyond what
;   the entry is an index INTO.
; Fourteen fields is what a reader-driven pass got.  The rest needs either a
; reader this lane did not find or a machine to measure on, and the header
; above records that Felipe's hardware is in storage.
; ==============================================================================

wsa1_prom_d:

; ==============================================================================
; ★ THE IMAGE ITSELF IS IN THREE INCLUDED FILES
; ==============================================================================
;
; Everything the header above says about `this file` -- the 3,663 labels, the
; census graded by provenance, every `below` and every `banner` -- now means
; THESE FOUR FILES TOGETHER.  Not one sentence of it was reworded for the
; split; the split moves lines between files and adds each file a header.
;
; The three parts mirror ../kn5000-roms-disasm/table_data/, which cuts the
; SAME database the same way, and both cut points are read out of this image's
; own directory rather than typed in:
;
;   tone_database_directory.s  0x00000..0x013C7  directory, program maps, the
;                                               tone-record offset table
;   tone_database_records.s    0x013C8..0x1C589  the melodic tone records; ends
;                                               at directory slot +0xAC, where
;                                               the KN5000's aux module starts
;                                               too
;   tone_database_aux.s        0x1C58A..0x7FFFF  everything else, ending in the
;                                               erased tail and the build tag
;
; ⚠ ORDER IS LOAD-BEARING.  This image is 0 .align directives and 0 .org: the
; address of every byte is the sum of the lengths before it, so swapping two
; .include lines silently moves 512 KiB of data.  The byte gate is what
; catches that, and it is the only thing that would.
; ==============================================================================

	.include "tone_database_directory.s"
	.include "tone_database_records.s"
	.include "tone_database_aux.s"

prom_d_end:
