; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFACE67-0xFAD141  the register writers for the device at 0x0010C000
; ==============================================================================
;
; 752 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared: 17 routines that establish the port's shape
; {select, write data, read data} and the `channel + K*0x40` register map.
; ★ This banner also carries the round-4 NAMING RETRACTION that fixes the
; Dev10C_ prefix; keeping it with the driver it governs is the point.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFACE67-0xFAD141 -- the register writers for the 64-channel parameter device
;                      at 0x0010C000.  17 routines, 731 bytes
; ==============================================================================
;
; ⚠⚠ NAMING RETRACTION, ROUND 4.  Every label in this bank and in the two banks
; below was prefixed `TG_` (and `TG2_` for 0x00104000) from round 2 until round 4,
; and the supporting note was titled "The WSA1's tone generator".  NOTHING IN THIS
; IMAGE ESTABLISHES THAT THE DEVICE MAKES SOUND.  What is established is only the
; shape, and the shape is what the names now say: `Dev10C_...` for 0x0010C000 and
; `Dev104_...` for 0x00104000, matching the neutral convention this file already
; used for `Dev108000_Preload_80toBF` before that device's role was pinned down.
; The tone-generator reading is a reasonable INFERENCE and it is written out in
; full, with what would settle it, in notes/FINDINGS-prom_c-tone-generator.md §0.
; What is missing is an instruction connecting a NOTE to a CHANNEL: CPU 2 scans
; the keybed (0x00108000) and then SENDS the note-on over the inter-processor link
; (Link_Ch0_AppendToRing's block comment), so the one path this image does show
; from a key to anything goes AWAY from this device, not into it.
;
; 0x0010C000 is CPU 2's busiest device: prom_c loads that literal into a pointer
; register 102 times, against 20 for 0x00E00000, 12 for 0x00104000 and 3 for
; 0x00108000.  All 102 are the SAME instruction shape, `ld <X..>,0x0010C000`
; (51 x XIX, 41 x XBC, 10 x XWA), so the census has no false positives to discard
; -- `python3 notes/prom_c_tg_regmap.py --selftest` re-derives the count and
; checks the LAST site, not only the first.
;
; ★ THE PORT IS AN ADDRESS/DATA PAIR, AND ONE ROUTINE PROVES IT WITHOUT
; INTERPRETATION.  Dev10C_WriteReg at 0xFACE89 is 25 bytes long and does nothing but
;
;       ld bc,(xiz+8)   / ld (xix),bc         ; +0x00 <- argument 0
;       ld bc,(xiz+10)  / ld (xix+2),bc       ; +0x02 <- argument 1
;
; -- no arithmetic, no mask, no shift between the argument and the port.  There
; is no reading of that in which +0x00 is anything but a 16-bit register selector
; and +0x02 anything but that register's 16-bit data.  Every other routine here
; is that same pair with the register number computed first.
;
; ★ THE REGISTER NUMBER IS `channel + K`, AND EVERY K IS A MULTIPLE OF 0x40.
; `python3 notes/prom_c_tg_regmap.py` extracts the (K, source field) pair from
; each site mechanically -- it parses unidasm's rendering, bounds the window to
; one routine, and prints the sites it could NOT match rather than dropping them
; (75 of 102 matched; the 27 it rejects are sites whose register number is in a
; register it cannot follow, and they are listed by `--unmatched`).  Over the
; matched set:
;
;   19 distinct K:  0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180 0x01C0
;                   0x0400 0x0440 0x0480 0x04C0 0x0540 0x0580 0x05C0 0x0600 0x0640
;                   0x0800 0x0840 0x0880
;   all divisible by 0x40; as K/0x40:  1 2 3 4 5 6 7  16 17 18 19 21 22 23 24 25  32 33 34
;
; and K = 0 occurs too (0xFACE89 here, 0xFB7331 elsewhere).  So the device's
; register file reads as `parameter_block * 0x40 + channel`, with 0x40 channels
; per block.  ⚠ THAT LAST SENTENCE IS AN OBSERVATION ABOUT THE CONSTANTS, not
; something any instruction says.  What the instructions say is only `chan + K`.
;
; ★ 0x40 IS ALSO A BRANCH POINT IN THE CODE.  Dev10C_SetChanReg_01C0_or_0600 and
; Dev10C_SetChanReg_0540_or_0580 both `cp hl,0x0040` on the channel argument and pick
; a different block AND a different source field on each arm.  Independently, the
; loop at 0xFADCC3 that drives this bank walks a list of channel bytes and stops
; on the first one >= 0x40 (`cp H,0x40 / jr NC,exit`) -- so in that path 0x40 is a
; list TERMINATOR, and the channel numbers that reach the accessors from it are
; 0..63.  Something else reaches the >= 0x40 arms; that caller is not converted.
;
; ★ ALL 23 STRUCT-TAKING CALL SITES PASS THE SAME POINTER, 0x00D75E.  The bank has
; 25 calr sites in total (`--callers` finds them by displacement, and reports that
; no routine here is uncalled); 23 of them set the arguments up as
; `lda XBC,0x00D75E / push XBC / <compute chan> / push WA`, and the two that do
; not are the two routines that take no struct (Dev10C_WriteReg, Dev10C_WriteReg_0201).
; 0x00D75E is work DRAM -- outside the boot RAM image at 0x00E2DF
; (notes/FINDINGS-prom_c-ram-image.md) -- and prom_c takes its address 74 times,
; every one of them the identical instruction `lda XBC,0x00D75E`
; (`python3 notes/prom_c_xrefs.py 0x00D75E --no-window --classify`).  It is a
; single global STAGING STRUCT: the accessors read fields 0x08..0x42 of it and
; push them at the hardware.  The fields observed here are
; 0x08 0x0A 0x0C 0x0E 0x10 0x14 0x1A 0x1C 0x2C 0x2E 0x38 0x3A 0x3C 0x3E 0x40 0x42.
;
; ⚠ NO KN5000 COUNTERPART.  `python3 notes/prom_c_sibling_map.py --addr 0xFACE67
; --len 731` reports the run does not occur in the sibling image at all, so unlike
; the 0x00E00000 writers at the top of this file NOTHING here is a transplanted
; name.  Every name below describes only what its own instructions do.
;
; ⚠ THIS BANK IS DUPLICATED INSIDE prom_c.  13 of the 17 bodies occur a second
; time, byte for byte, between 0xFB7016 and 0xFB7FCE -- and two of the 17
; (0xFACEA2 and 0xFACF78) are byte-identical to EACH OTHER.  Run
; `python3 notes/prom_c_tg_regmap.py --dups` for the address of every copy.  The
; second bank is larger than this one (it adds K = 0x0040, 0x0080, 0x0480, 0x05C0,
; 0x0640) and is NOT converted here.
;
; ★ AND +0x04 IS THE READ PORT.  0xFA68FC does the SAME select through the same
; pointer -- `ld (XIX),BC` -- and then takes the value from XIX+4:
;
;       ld xbc,xix / inc 4,xbc / ld (xiz-14),xbc / ld hl,(xbc)     ; 0xFA6903
;
; 16 bits again.  So the device's shape, entirely from prom_c's own instructions,
; is {+0x00 select, +0x02 write data, +0x04 read data}.  That routine is not
; converted here; it is quoted because it was, when this block was written, the
; only evidence in this image that the port can be read at all.
; ⚠ CORRECTED, round 7 (finish pass): IT IS NO LONGER THE ONLY ONE.  0xFC7E57 --
; now `Dev10C_ReadChanReg_0100` -- is a DEDICATED one-register read accessor with the
; same three-step shape and nothing else in it: `add HL,0x0100` at 0xFC7E64,
; `ld (XIX),HL` at 0xFC7E6D (select), `ld BC,(XIX+0x04)` at 0xFC7E6F (read).  Two
; sites, in different modules, written by different hands, agree on +0x04, which is
; a better standing for the read port than one quoted site.
;
; ⚠ WHAT ANY REGISTER MEANS IS NOT ESTABLISHED BY THIS BANK, and no name below claims one.
; ★ CORRECTED 2026-08-25 (round 7): four of the registers this bank writes DO have a meaning
; now, established elsewhere and never from these accessors -- `chan + 0x0400` is the PITCH
; (1/256 semitone), `chan + 0x0080` the OUTPUT LEVEL, `chan + 0x0040` the key-zone word, and
; `chan + 0x0800`/`0x0840` have a quiescent pair.  `Dev10C_SetChanPitch_Reg0400` below is the
; single-register PITCH writer, called from the two controller-driven refresh loops at
; 0xFADD1A and 0xFADDB8.  See notes/FINDINGS-prom_c-dev10c-register-meanings.md.

; --------------------------------------------------------------------------
; Dev10C_SetChanPitch_Reg0400 -- register (chan + 0x0400) = staging->0x0E.
;
; Called from: 0xFADD1A, 0xFADDB8 (notes/prom_c_tg_regmap.py --callers).
; Inputs:  (XIZ+8) = chan, 16-bit.  (XIZ+10) = pointer to the staging struct.
;          Both sites are `lda XBC,0x00D75E / push XBC / <compute chan> / push WA`,
;          so the struct they pass is the one at 0x00D75E.  ⚠ The address above is a VARIABLE, not a call site.  It is stated here rather than in `Called from:` because notes/prom_c_audit_callsites.py harvests every 0xXXXXXX in that paragraph and cannot tell prose from a citation.
; Outputs: one 16-bit write to the device at 0x0010C000.
; Evidence: `add hl,0x0400` on the argument, `ld (xix),hl`, then
;          `ld wa,(xbc+14)` / `ld (xix+2),wa`.  Nothing else touches the port.
; ★ NAMED (round 7): register block 0x0400 is the PITCH, in units of 1/256 of a semitone,
;          saturated to 0x0000..0x7FFF = notes 0..127.996.  The field this routine sends,
;          staging word 7 at 0x00D76C, is what Voice_StagePitch_Reg0400_AB/_CD computes.
;          Evidence and the whole chain: notes/FINDINGS-prom_c-dev10c-register-meanings.md,
;          asserted by notes/prom_c_dev10c_meaning_checks.py sections 7 and 8.
; ★ ROUND 6 ------------------------------------------------------------
; ⚠ RENAMED (was Dev10C_SetChanReg_0400).  Register
;          0x0400 + chan of the 0x0010C000 device is the PITCH, in 1/256 of a semitone --
;          established by notes/FINDINGS-prom_c-dev10c-register-meanings.md and re-derived by
;          `python3 notes/prom_c_dev10c_meaning_checks.py`, NOT by this round.  The register
;          number is kept in the name so the claim stays checkable against that finding.
; --------------------------------------------------------------------------
Dev10C_SetChanPitch_Reg0400:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACE67  ee 0c 00 00
	pushw hl                                   ; FACE6B  2b
	push xix                                   ; FACE6C  3c
	ld hl, (xiz+8)                             ; FACE6D  9e 08 23
	add hl, 0x0400                             ; FACE70  db c8 00 04
	ld xix, 0x0010C000                         ; FACE74  44 00 c0 10 00
	ld (xix), hl                               ; FACE79  b4 53
	ld xbc, (xiz+10)                           ; FACE7B  ae 0a 21
	ld wa, (xbc+14)                            ; FACE7E  99 0e 20
	ld (xix+2), wa                             ; FACE81  bc 02 50
	pop xix                                    ; FACE84  5c
	popw hl                                    ; FACE85  4b
	unlk32 xiz                                 ; FACE86  ee 0d
	ret                                        ; FACE88  0e
; --------------------------------------------------------------------------
; ★ Dev10C_WriteReg -- the RAW two-word primitive, and the routine that fixes the
; port's shape for the whole bank.
;
; Called from: 0xFADF40, its only calr site.
; Inputs:  (XIZ+8) = the 16-bit REGISTER NUMBER, (XIZ+10) = the 16-bit VALUE.
; Outputs: one register of the device at 0x0010C000.
; Evidence: ★ both arguments go to the port UNMODIFIED and in order -- there is
;          no add, no mask and no shift anywhere in the 25 bytes:
;              ld bc,(xiz+8)  / ld (xix),bc
;              ld bc,(xiz+10) / ld (xix+2),bc
;          so +0x00 is a register selector and +0x02 is that register's data, and
;          every other routine below is this one with the number computed.
;          At the single call site the number pushed is the channel (`ld C,(XIX)`
;          / extz / push) and the value comes from (XHL+0x29) where
;          XHL = 0x3BCF + chan*0x44 -- i.e. block 0, and the value comes out of
;          the per-channel record array, not out of the staging struct.
; Unknown:  what block 0 holds.
; --------------------------------------------------------------------------
Dev10C_WriteReg:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACE89  ee 0c 00 00
	push xix                                   ; FACE8D  3c
	ld xix, 0x0010C000                         ; FACE8E  44 00 c0 10 00
	ld bc, (xiz+8)                             ; FACE93  9e 08 21
	ld (xix), bc                               ; FACE96  b4 51
	ld bc, (xiz+10)                            ; FACE98  9e 0a 21
	ld (xix+2), bc                             ; FACE9B  bc 02 51
	pop xix                                    ; FACE9E  5c
	unlk32 xiz                                 ; FACE9F  ee 0d
	ret                                        ; FACEA1  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880 -- registers (chan+0x0840) = staging->0x1A and
; (chan+0x0880) = staging->0x1C, in that order.
;
; Called from: 0xFADE9B.
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Outputs: two 16-bit writes.
; Evidence: the two `add`s are `0x0840` and `0x0880`; the sources are the
;          ADJACENT struct words 0x1A and 0x1C.  The four bytes of frame the
;          `link XIZ,0xFFFC` opens hold a copy of the data-port address
;          (`ld xwa,xix / inc 2,xwa / ld (xiz-4),xwa`), which is why the second
;          write goes through XIY rather than (XIX+2).
; ⚠ BYTE-IDENTICAL, all 60 bytes, to Dev10C_SetChanReg_0840_0880_dup at 0xFACF78 --
;          two copies of one function in the same bank.  Reproduce with
;          `python3 notes/prom_c_tg_regmap.py --dups`, whose 0xFACEA2 and
;          0xFACF78 rows report each other's address.
; Unknown:  whether 0x1A/0x1C are the halves of one 32-bit quantity.  They are
;          adjacent and written to adjacent blocks, which is suggestive and is
;          NOT evidence.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACEA2  ee 0c fc ff
	pushw hl                                   ; FACEA6  2b
	push xix                                   ; FACEA7  3c
	ld hl, (xiz+8)                             ; FACEA8  9e 08 23
	add hl, 0x0840                             ; FACEAB  db c8 40 08
	ld xix, 0x0010C000                         ; FACEAF  44 00 c0 10 00
	ld (xix), hl                               ; FACEB4  b4 53
	ld xbc, (xiz+10)                           ; FACEB6  ae 0a 21
	ld hl, (xbc+26)                            ; FACEB9  99 1a 23
	ld xwa, xix                                ; FACEBC  ec 88
	inc 2, xwa                                 ; FACEBE  e8 62
	ld (xiz-4), xwa                            ; FACEC0  be fc 60
	ld (xwa), hl                               ; FACEC3  b0 53
	ld bc, (xiz+8)                             ; FACEC5  9e 08 21
	add bc, 0x0880                             ; FACEC8  d9 c8 80 08
	ld (xix), bc                               ; FACECC  b4 51
	ld xbc, (xiz+10)                           ; FACECE  ae 0a 21
	ld wa, (xbc+28)                            ; FACED1  99 1c 20
	ld xiy, (xiz-4)                            ; FACED4  ae fc 25
	ld (xiy), wa                               ; FACED7  b5 50
	pop xix                                    ; FACED9  5c
	popw hl                                    ; FACEDA  4b
	unlk32 xiz                                 ; FACEDB  ee 0d
	ret                                        ; FACEDD  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0800 -- registers (chan+0x0840) = staging->0x2E and
; (chan+0x0800) = staging->0x2C.  Note the DESCENDING block order.
;
; Called from: 0xFADF91.
; Inputs / Outputs: as above.
; Evidence: `add hl,0x0840` then `add bc,0x0800`; sources (xbc+46) and (xbc+44).
; Unknown:  why this one writes the higher block first when
;          Dev10C_SetChanReg_0840_0880 writes the lower first.
; ★★ ROUND 3 -- THIS ROUTINE IS WHY THE STAGING STRUCT'S SIZE IS KNOWN.  It reads
;   fields +0x2C and +0x2E, which are PAST the 22 words (+0x00..+0x2A) that
;   Dev10C_WriteAllChanRegs commits.  Four readings close on one number:
;     1. 0x00D75E + 0x2C = 0x00D78A -- the absolute address round 2's
;        Dev10C_WriteSixChanRegs_FromD78A commits registers 0x0800/0x0840/0x0900/
;        0x0940/0x09C0/0x0A00 from.  It maps +0x2C -> 0x0800 and +0x2E -> 0x0840,
;        exactly as this routine does.
;     2. Dev10C_ResetAllChannels copies 0x44 = 68 bytes (`push 0x0044` at 0xFB814B)
;        from ROM 0xFE12CF into a second instance at RAM 0x00D8DB.
;     3. 0x00D75E + 0x44 = 0x00D7A2 -- the pointer VoiceRegs_Stage_A pushes at
;        0xFB0B5B as the 0x00104000 staging struct.  The two structs abut.
;     4. The highest field any accessor reads is +0x42 (Dev10C_SetChanReg_0640),
;        which is the last word that fits in 68 bytes.
;   So the 0x0010C000 staging struct is RAM 0x00D75E..0x00D7A1, 68 bytes:
;     +0x00..+0x2A  the 22 words Dev10C_WriteAllChanRegs commits
;     +0x2C..+0x36  the six words Dev10C_WriteSixChanRegs_FromD78A commits
;     +0x38..+0x42  the slot gate/value words the Dev10C_Slot* writers commit
; ⚠ NOT ESTABLISHED: why registers 0x0800 and 0x0840 have TWO committers reading
;   two different words.  The reset image disagrees with itself about 0x0800 --
;   word 12 (+0x18) is 0xFF80 and word 22 (+0x2C) is 0xA080 -- so the two paths are
;   alternatives, and nothing here says which one runs when.
; Evidence: `python3 notes/prom_c_naming_round3.py --struct` prints the ten checks
;          above and the whole 68-byte image, word by word, out of the ROM.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0800:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACEDE  ee 0c fc ff
	pushw hl                                   ; FACEE2  2b
	push xix                                   ; FACEE3  3c
	ld hl, (xiz+8)                             ; FACEE4  9e 08 23
	add hl, 0x0840                             ; FACEE7  db c8 40 08
	ld xix, 0x0010C000                         ; FACEEB  44 00 c0 10 00
	ld (xix), hl                               ; FACEF0  b4 53
	ld xbc, (xiz+10)                           ; FACEF2  ae 0a 21
	ld hl, (xbc+46)                            ; FACEF5  99 2e 23
	ld xwa, xix                                ; FACEF8  ec 88
	inc 2, xwa                                 ; FACEFA  e8 62
	ld (xiz-4), xwa                            ; FACEFC  be fc 60
	ld (xwa), hl                               ; FACEFF  b0 53
	ld bc, (xiz+8)                             ; FACF01  9e 08 21
	add bc, 0x0800                             ; FACF04  d9 c8 00 08
	ld (xix), bc                               ; FACF08  b4 51
	ld xbc, (xiz+10)                           ; FACF0A  ae 0a 21
	ld wa, (xbc+44)                            ; FACF0D  99 2c 20
	ld xiy, (xiz-4)                            ; FACF10  ae fc 25
	ld (xiy), wa                               ; FACF13  b5 50
	pop xix                                    ; FACF15  5c
	popw hl                                    ; FACF16  4b
	unlk32 xiz                                 ; FACF17  ee 0d
	ret                                        ; FACF19  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840 -- register (chan + 0x0840) = staging->0x2E.
;
; Called from: 0xFADF32.
; Evidence: the single-write half of Dev10C_SetChanReg_0840_0800 above -- same block,
;          same source field.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACF1A  ee 0c 00 00
	pushw hl                                   ; FACF1E  2b
	push xix                                   ; FACF1F  3c
	ld hl, (xiz+8)                             ; FACF20  9e 08 23
	add hl, 0x0840                             ; FACF23  db c8 40 08
	ld xix, 0x0010C000                         ; FACF27  44 00 c0 10 00
	ld (xix), hl                               ; FACF2C  b4 53
	ld xbc, (xiz+10)                           ; FACF2E  ae 0a 21
	ld wa, (xbc+46)                            ; FACF31  99 2e 20
	ld (xix+2), wa                             ; FACF34  bc 02 50
	pop xix                                    ; FACF37  5c
	popw hl                                    ; FACF38  4b
	unlk32 xiz                                 ; FACF39  ee 0d
	ret                                        ; FACF3B  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0100_0140 -- registers (chan+0x0100) = staging->0x08 and
; (chan+0x0140) = staging->0x0A.
;
; Called from: 0xFAE004.
; Evidence: `add hl,0x0100` / `add bc,0x0140`; sources (xbc+8) and (xbc+10).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0100_0140:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACF3C  ee 0c fc ff
	pushw hl                                   ; FACF40  2b
	push xix                                   ; FACF41  3c
	ld hl, (xiz+8)                             ; FACF42  9e 08 23
	add hl, 0x0100                             ; FACF45  db c8 00 01
	ld xix, 0x0010C000                         ; FACF49  44 00 c0 10 00
	ld (xix), hl                               ; FACF4E  b4 53
	ld xbc, (xiz+10)                           ; FACF50  ae 0a 21
	ld hl, (xbc+8)                             ; FACF53  99 08 23
	ld xwa, xix                                ; FACF56  ec 88
	inc 2, xwa                                 ; FACF58  e8 62
	ld (xiz-4), xwa                            ; FACF5A  be fc 60
	ld (xwa), hl                               ; FACF5D  b0 53
	ld bc, (xiz+8)                             ; FACF5F  9e 08 21
	add bc, 0x0140                             ; FACF62  d9 c8 40 01
	ld (xix), bc                               ; FACF66  b4 51
	ld xbc, (xiz+10)                           ; FACF68  ae 0a 21
	ld wa, (xbc+10)                            ; FACF6B  99 0a 20
	ld xiy, (xiz-4)                            ; FACF6E  ae fc 25
	ld (xiy), wa                               ; FACF71  b5 50
	pop xix                                    ; FACF73  5c
	popw hl                                    ; FACF74  4b
	unlk32 xiz                                 ; FACF75  ee 0d
	ret                                        ; FACF77  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880_dup -- ⚠ 60 bytes BYTE-IDENTICAL to
; Dev10C_SetChanReg_0840_0880 at 0xFACEA2.  It is a second copy of the same function,
; not a variant: `notes/prom_c_tg_regmap.py --dups` finds each at the other's
; address.  It is given its own name because it has its own callers.
;
; Called from: 0xFAE092, 0xFAE0F8.
; Evidence / Inputs / Outputs: see 0xFACEA2.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFACF81  `add rr,0x0840` forms the select value chan+0x0840,
;          0xFACF8F  `ld rr,(XBC+0x1A)` fetches the staging word it is
;                    given -- struct offset +0x1A.
;          0xFACF9E  `add rr,0x0880` forms the select value chan+0x0880,
;          0xFACFA7  `ld rr,(XBC+0x1C)` fetches the staging word it is
;                    given -- struct offset +0x1C.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880_dup:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACF78  ee 0c fc ff
	pushw hl                                   ; FACF7C  2b
	push xix                                   ; FACF7D  3c
	ld hl, (xiz+8)                             ; FACF7E  9e 08 23
	add hl, 0x0840                             ; FACF81  db c8 40 08
	ld xix, 0x0010C000                         ; FACF85  44 00 c0 10 00
	ld (xix), hl                               ; FACF8A  b4 53
	ld xbc, (xiz+10)                           ; FACF8C  ae 0a 21
	ld hl, (xbc+26)                            ; FACF8F  99 1a 23
	ld xwa, xix                                ; FACF92  ec 88
	inc 2, xwa                                 ; FACF94  e8 62
	ld (xiz-4), xwa                            ; FACF96  be fc 60
	ld (xwa), hl                               ; FACF99  b0 53
	ld bc, (xiz+8)                             ; FACF9B  9e 08 21
	add bc, 0x0880                             ; FACF9E  d9 c8 80 08
	ld (xix), bc                               ; FACFA2  b4 51
	ld xbc, (xiz+10)                           ; FACFA4  ae 0a 21
	ld wa, (xbc+28)                            ; FACFA7  99 1c 20
	ld xiy, (xiz-4)                            ; FACFAA  ae fc 25
	ld (xiy), wa                               ; FACFAD  b5 50
	pop xix                                    ; FACFAF  5c
	popw hl                                    ; FACFB0  4b
	unlk32 xiz                                 ; FACFB1  ee 0d
	ret                                        ; FACFB3  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0180 -- register (chan + 0x0180) = staging->0x0C.
; Called from: 0xFAE650, 0xFAE78C.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFACFBD  `add rr,0x0180` forms the select value chan+0x0180,
;          0xFACFCB  `ld rr,(XBC+0x0C)` fetches the staging word it is
;                    given -- struct offset +0x0C.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0180:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFB4  ee 0c 00 00
	pushw hl                                   ; FACFB8  2b
	push xix                                   ; FACFB9  3c
	ld hl, (xiz+8)                             ; FACFBA  9e 08 23
	add hl, 0x0180                             ; FACFBD  db c8 80 01
	ld xix, 0x0010C000                         ; FACFC1  44 00 c0 10 00
	ld (xix), hl                               ; FACFC6  b4 53
	ld xbc, (xiz+10)                           ; FACFC8  ae 0a 21
	ld wa, (xbc+12)                            ; FACFCB  99 0c 20
	ld (xix+2), wa                             ; FACFCE  bc 02 50
	pop xix                                    ; FACFD1  5c
	popw hl                                    ; FACFD2  4b
	unlk32 xiz                                 ; FACFD3  ee 0d
	ret                                        ; FACFD5  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440 -- register (chan + 0x0440) = staging->0x10.
; Called from: 0xFAE3D3, 0xFAE50D.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFACFDF  `add rr,0x0440` forms the select value chan+0x0440,
;          0xFACFED  `ld rr,(XBC+0x10)` fetches the staging word it is
;                    given -- struct offset +0x10.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; ★ GAP A, round 3 -- what IS established about register chan+0x0440:
;   * it is committed from staging word 8, at struct offset +0x10, both by
;     this accessor and by Dev10C_WriteAllChanRegs (0xFB713A); two independent
;     readings of the same pairing.
;   * its POWER-ON value is 0x0000, and the ROM bytes that say so are at
;     0xFE12DF -- offset +0x10 of the 68-byte reset image at 0xFE12CF that
;     Dev10C_ResetAllChannels copies to RAM 0x00D8DB.  ⚠ The copy is at
;     0xFB8146 / 0xFB814B / 0xFB814F (lda XIX,0x00d8db / push 0x0044 /
;     lda XWA,0xfe12cf); notes/prom_c_gapA_remaining_regs.py cites 0xFB8175
;     for it, which is the argument load of the NEXT loop -- corrected here,
;     see notes/wave7-round1/README.md lane g1.
; ★★ ROUND 4 -- WHAT THE REGISTER HOLDS.  Word 8 is `MODE | CHANNEL`, and the
;   CHANNEL field (bits 6..0) is a channel of this same 0x0010C000 device: it is
;   bit for bit the value its producer hands to a Dev10C_Slot* accessor as that
;   accessor's `chan` argument, where it is added to a register-block base
;   (0x0540 / 0x0580 / 0x05C0) to form the device's register selector.  Bits 5..0
;   are the channel of the 64-channel device and bit 6 selects the block --
;   Dev10C_Slot1or3_StrobeGate splits on that bit at 0xFB801F and its two arms
;   read the two slots' own staging fields (+0x3A / +0x3E).  The MODE bits (7..6)
;   come from the tone descriptor on one path (0xFA99F3 `and WA,0x00c0`) and from
;   Dev10C_ChanSelHighBits on the other (0xFA9AE7).
;   ⚠ THE TWO FIELDS OVERLAP AT BIT 6 in this word and are combined with `or`;
;   word 0x0480 masks its channel to 0x3F and does not.  Stated, not resolved.
;   Producer: Voice_StageChanSel_Reg0440_Reg0480 (0xFA9915).  Full citation list
;   and the raw-byte write census: `python3 notes/prom_c_understanding_round4.py`.
; ⚠ STILL NOT ESTABLISHED: that the named channel is a DIFFERENT channel from the
;   one the word is written to, and what the two mode bits mean.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFD6  ee 0c 00 00
	pushw hl                                   ; FACFDA  2b
	push xix                                   ; FACFDB  3c
	ld hl, (xiz+8)                             ; FACFDC  9e 08 23
	add hl, 0x0440                             ; FACFDF  db c8 40 04
	ld xix, 0x0010C000                         ; FACFE3  44 00 c0 10 00
	ld (xix), hl                               ; FACFE8  b4 53
	ld xbc, (xiz+10)                           ; FACFEA  ae 0a 21
	ld wa, (xbc+16)                            ; FACFED  99 10 20
	ld (xix+2), wa                             ; FACFF0  bc 02 50
	pop xix                                    ; FACFF3  5c
	popw hl                                    ; FACFF4  4b
	unlk32 xiz                                 ; FACFF5  ee 0d
	ret                                        ; FACFF7  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_04C0 -- register (chan + 0x04C0) = staging->0x14.
; Called from: 0xFAE8D1, 0xFAEA0F.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFAD001  `add rr,0x04C0` forms the select value chan+0x04C0,
;          0xFAD00F  `ld rr,(XBC+0x14)` fetches the staging word it is
;                    given -- struct offset +0x14.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; ★ GAP A, round 3 -- what IS established about register chan+0x04C0:
;   * it is committed from staging word 10, at struct offset +0x14, both by
;     this accessor and by Dev10C_WriteAllChanRegs (0xFB713A); two independent
;     readings of the same pairing.
;   * its POWER-ON value is 0x0000, and the ROM bytes that say so are at
;     0xFE12E3 -- offset +0x14 of the 68-byte reset image at 0xFE12CF that
;     Dev10C_ResetAllChannels copies to RAM 0x00D8DB.  ⚠ The copy is at
;     0xFB8146 / 0xFB814B / 0xFB814F (lda XIX,0x00d8db / push 0x0044 /
;     lda XWA,0xfe12cf); notes/prom_c_gapA_remaining_regs.py cites 0xFB8175
;     for it, which is the argument load of the NEXT loop -- corrected here,
;     see notes/wave7-round1/README.md lane g1.
; ★★ ROUND 4 -- WHAT THE REGISTER HOLDS.  Word 10 tiles into THREE disjoint
;   fields: a literal 0x4400, a 0x3300 mode field taken from the tone descriptor
;   word at +0x22 (0xFA9FE8 `and WA,0x3300`), and a 0x007F channel of this same
;   0x0010C000 device (0xFA9F85 / 0xFA9FAC `and WA,0x007f`).  The channel field is
;   a channel because the same masked value is handed to
;   Dev10C_Slot1or3_StrobeGate at 0xFAA02D/0xFAA02E, which adds a register-block
;   base to it (0xFB8030 / 0xFB8070).
;   ⚠ AND THE POWER-ON ROW ABOVE IS NOT THE WHOLE STORY FOR THIS REGISTER: its
;   producer SEEDS the word with 0x4400 at 0xFA9F20 before any test, so a
;   REJECTED lookup leaves 0x4400 in it, not 0x0000.  0x0000 is only what the
;   reset image writes.
;   Producer: Voice_StageChanSel_Reg04C0 (0xFA9F19).  Full citation list and the
;   raw-byte write census: `python3 notes/prom_c_understanding_round4.py`.
; ⚠ STILL NOT ESTABLISHED: what the literal 0x4400 or the two mode bits mean, and
;   whether the named channel differs from the one the word is written to.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_04C0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFF8  ee 0c 00 00
	pushw hl                                   ; FACFFC  2b
	push xix                                   ; FACFFD  3c
	ld hl, (xiz+8)                             ; FACFFE  9e 08 23
	add hl, 0x04C0                             ; FAD001  db c8 c0 04
	ld xix, 0x0010C000                         ; FAD005  44 00 c0 10 00
	ld (xix), hl                               ; FAD00A  b4 53
	ld xbc, (xiz+10)                           ; FAD00C  ae 0a 21
	ld wa, (xbc+20)                            ; FAD00F  99 14 20
	ld (xix+2), wa                             ; FAD012  bc 02 50
	pop xix                                    ; FAD015  5c
	popw hl                                    ; FAD016  4b
	unlk32 xiz                                 ; FAD017  ee 0d
	ret                                        ; FAD019  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0600 -- register (chan + 0x0600) = staging->0x40.
; Called from: 0xFAE475, 0xFAE598.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFAD023  `add rr,0x0600` forms the select value chan+0x0600,
;          0xFAD031  `ld rr,(XBC+0x40)` fetches the staging word it is
;                    given -- struct offset +0x40.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0600:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD01A  ee 0c 00 00
	pushw hl                                   ; FAD01E  2b
	push xix                                   ; FAD01F  3c
	ld hl, (xiz+8)                             ; FAD020  9e 08 23
	add hl, 0x0600                             ; FAD023  db c8 00 06
	ld xix, 0x0010C000                         ; FAD027  44 00 c0 10 00
	ld (xix), hl                               ; FAD02C  b4 53
	ld xbc, (xiz+10)                           ; FAD02E  ae 0a 21
	ld wa, (xbc+64)                            ; FAD031  99 40 20
	ld (xix+2), wa                             ; FAD034  bc 02 50
	pop xix                                    ; FAD037  5c
	popw hl                                    ; FAD038  4b
	unlk32 xiz                                 ; FAD039  ee 0d
	ret                                        ; FAD03B  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0580 -- register (chan + 0x0580) = staging->0x3C.
; Called from: 0xFAE5B7.  No copy of this body exists elsewhere in prom_c
;              (`--dups`), unlike thirteen of its neighbours.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFAD045  `add rr,0x0580` forms the select value chan+0x0580,
;          0xFAD053  `ld rr,(XBC+0x3C)` fetches the staging word it is
;                    given -- struct offset +0x3C.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0580:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD03C  ee 0c 00 00
	pushw hl                                   ; FAD040  2b
	push xix                                   ; FAD041  3c
	ld hl, (xiz+8)                             ; FAD042  9e 08 23
	add hl, 0x0580                             ; FAD045  db c8 80 05
	ld xix, 0x0010C000                         ; FAD049  44 00 c0 10 00
	ld (xix), hl                               ; FAD04E  b4 53
	ld xbc, (xiz+10)                           ; FAD050  ae 0a 21
	ld wa, (xbc+60)                            ; FAD053  99 3c 20
	ld (xix+2), wa                             ; FAD056  bc 02 50
	pop xix                                    ; FAD059  5c
	popw hl                                    ; FAD05A  4b
	unlk32 xiz                                 ; FAD05B  ee 0d
	ret                                        ; FAD05D  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0 -- register (chan + 0x01C0) = staging->0x38.
; Called from: 0xFAE6F4, 0xFAE819.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFAD067  `add rr,0x01C0` forms the select value chan+0x01C0,
;          0xFAD075  `ld rr,(XBC+0x38)` fetches the staging word it is
;                    given -- struct offset +0x38.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD05E  ee 0c 00 00
	pushw hl                                   ; FAD062  2b
	push xix                                   ; FAD063  3c
	ld hl, (xiz+8)                             ; FAD064  9e 08 23
	add hl, 0x01C0                             ; FAD067  db c8 c0 01
	ld xix, 0x0010C000                         ; FAD06B  44 00 c0 10 00
	ld (xix), hl                               ; FAD070  b4 53
	ld xbc, (xiz+10)                           ; FAD072  ae 0a 21
	ld wa, (xbc+56)                            ; FAD075  99 38 20
	ld (xix+2), wa                             ; FAD078  bc 02 50
	pop xix                                    ; FAD07B  5c
	popw hl                                    ; FAD07C  4b
	unlk32 xiz                                 ; FAD07D  ee 0d
	ret                                        ; FAD07F  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0540 -- register (chan + 0x0540) = staging->0x3A.
; Called from: 0xFAE838.
; Evidence: decoded from the ROM bytes, not from the name --
;          0xFAD089  `add rr,0x0540` forms the select value chan+0x0540,
;          0xFAD097  `ld rr,(XBC+0x3A)` fetches the staging word it is
;                    given -- struct offset +0x3A.
;          Re-derived for all 32 Dev10C_/Dev104_ accessors at once by
;          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each
;          NAME against the bytes and reports the mismatch count.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0540:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD080  ee 0c 00 00
	pushw hl                                   ; FAD084  2b
	push xix                                   ; FAD085  3c
	ld hl, (xiz+8)                             ; FAD086  9e 08 23
	add hl, 0x0540                             ; FAD089  db c8 40 05
	ld xix, 0x0010C000                         ; FAD08D  44 00 c0 10 00
	ld (xix), hl                               ; FAD092  b4 53
	ld xbc, (xiz+10)                           ; FAD094  ae 0a 21
	ld wa, (xbc+58)                            ; FAD097  99 3a 20
	ld (xix+2), wa                             ; FAD09A  bc 02 50
	pop xix                                    ; FAD09D  5c
	popw hl                                    ; FAD09E  4b
	unlk32 xiz                                 ; FAD09F  ee 0d
	ret                                        ; FAD0A1  0e
; --------------------------------------------------------------------------
; ★ Dev10C_SetChanReg_01C0_or_0600 -- the channel number is COMPARED AGAINST 0x40 and
; picks BOTH the register block and the source field:
;
;       chan <  0x40 :  register (chan + 0x01C0) = staging->0x38
;       chan >= 0x40 :  register (chan + 0x0600) = staging->0x42
;
; Called from: 0xFAE977, 0xFAEAA4.
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Outputs: exactly ONE 16-bit write, on whichever arm is taken.
; Evidence: `cp hl,0x0040` / `jr nc,...`.  On TLCS-900 CF is set when the first
;          operand is the smaller, so NC is taken for chan >= 0x40.  The two arms
;          are otherwise the same six instructions with different constants.
; ★★ CORRECTED (wave 7 round 3) -- THE SPLIT IS NOW ESTABLISHED, and the last
;   sentence of the old paragraph ("they are different parameters") was WRONG.
;   Decoding all eight Dev10C_Slot* writers with the same scanner gives:
;       slot   gate register   gate word   value register   value word
;         1     chan+0x0540      +0x3A       chan+0x01C0       +0x38
;         2     chan+0x0580      +0x3C       chan+0x0600       +0x40
;         3     chan+0x05C0      +0x3E       chan+0x0640       +0x42
;   This routine's LOW arm is slot 1's value (0x01C0, +0x38).  Its HIGH arm uses
;   register 0x0600 with struct word +0x42 -- and +0x42 is SLOT 3's value word,
;   while the register arithmetic is an identity:
;       0x0600 + chan  ==  0x0640 + (chan - 0x40)   for every chan in 0x40..0x7F
;   so the high arm IS slot 3, addressed with the lower block base and an
;   un-decremented channel.  The same holds for Dev10C_SetChanReg_0540_or_0580
;   (0x0580 + chan == 0x05C0 + (chan - 0x40), word +0x3E = slot 3's gate) and for
;   the two Dev10C_Slot1or3_* routines, whose name was right all along.
;   A register block is therefore 0x40 = 64 channels wide, which is also the
;   literal loop counter `ld D,0x40` at 0xFB8116 in Dev10C_ResetAllChannels.
; Evidence: `python3 notes/prom_c_naming_round3.py --slots` decodes the table from
;          the ROM and reports that of the (register, word) pairs these ten routines
;          use, 8 are the slot-3 alias and ZERO are unexplained; `--claims C12/C13`
;          assert that and the 0x40 counter byte.
; ⚠ STILL NOT ESTABLISHED: what a slot IS.  Three parallel (gate, value) pairs per
;   channel is the structure; "partial", "operator" and "envelope stage" all fit it.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_or_0600:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD0A2  ee 0c 00 00
	pushw hl                                   ; FAD0A6  2b
	pushw de                                   ; FAD0A7  2a
	push xix                                   ; FAD0A8  3c
	ld hl, (xiz+8)                             ; FAD0A9  9e 08 23
	cp hl, 0x0040                              ; FAD0AC  db cf 40 00
	jr nc, Dev10C_SetChanReg_01C0_or_0600__high                            ; FAD0B0  6f 18
	ld de, hl                                  ; FAD0B2  db 8a
	add de, 0x01C0                             ; FAD0B4  da c8 c0 01
	ld xix, 0x0010C000                         ; FAD0B8  44 00 c0 10 00
	ld (xix), de                               ; FAD0BD  b4 52
	ld xbc, (xiz+10)                           ; FAD0BF  ae 0a 21
	ld wa, (xbc+56)                            ; FAD0C2  99 38 20
	ld (xix+2), wa                             ; FAD0C5  bc 02 50
	jr Dev10C_SetChanReg_01C0_or_0600__done                                ; FAD0C8  68 16
Dev10C_SetChanReg_01C0_or_0600__high:
	ld de, hl                                  ; FAD0CA  db 8a
	add de, 0x0600                             ; FAD0CC  da c8 00 06
	ld xix, 0x0010C000                         ; FAD0D0  44 00 c0 10 00
	ld (xix), de                               ; FAD0D5  b4 52
	ld xbc, (xiz+10)                           ; FAD0D7  ae 0a 21
	ld wa, (xbc+66)                            ; FAD0DA  99 42 20
	ld (xix+2), wa                             ; FAD0DD  bc 02 50
Dev10C_SetChanReg_01C0_or_0600__done:
	pop xix                                    ; FAD0E0  5c
	popw de                                    ; FAD0E1  4a
	popw hl                                    ; FAD0E2  4b
	unlk32 xiz                                 ; FAD0E3  ee 0d
	ret                                        ; FAD0E5  0e
; --------------------------------------------------------------------------
; ★ Dev10C_SetChanReg_0540_or_0580 -- the same split, different pair:
;
;       chan <  0x40 :  register (chan + 0x0540) = staging->0x3A
;       chan >= 0x40 :  register (chan + 0x0580) = staging->0x3E
;
; Called from: 0xFAEABE.
; Evidence: identical shape to 0xFAD0A2; `cp hl,0x0040` / `jr nc,...`.
; ⚠ Note the low arm is the same (block, field) pair as Dev10C_SetChanReg_0540 at
;          0xFAD080, and the high arm is the same BLOCK as Dev10C_SetChanReg_0580 at
;          0xFAD03C but a DIFFERENT source field (0x3E, not 0x3C).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0540_or_0580:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD0E6  ee 0c 00 00
	pushw hl                                   ; FAD0EA  2b
	pushw de                                   ; FAD0EB  2a
	push xix                                   ; FAD0EC  3c
	ld hl, (xiz+8)                             ; FAD0ED  9e 08 23
	cp hl, 0x0040                              ; FAD0F0  db cf 40 00
	jr nc, Dev10C_SetChanReg_0540_or_0580__high                            ; FAD0F4  6f 18
	ld de, hl                                  ; FAD0F6  db 8a
	add de, 0x0540                             ; FAD0F8  da c8 40 05
	ld xix, 0x0010C000                         ; FAD0FC  44 00 c0 10 00
	ld (xix), de                               ; FAD101  b4 52
	ld xbc, (xiz+10)                           ; FAD103  ae 0a 21
	ld wa, (xbc+58)                            ; FAD106  99 3a 20
	ld (xix+2), wa                             ; FAD109  bc 02 50
	jr Dev10C_SetChanReg_0540_or_0580__done                                ; FAD10C  68 16
Dev10C_SetChanReg_0540_or_0580__high:
	ld de, hl                                  ; FAD10E  db 8a
	add de, 0x0580                             ; FAD110  da c8 80 05
	ld xix, 0x0010C000                         ; FAD114  44 00 c0 10 00
	ld (xix), de                               ; FAD119  b4 52
	ld xbc, (xiz+10)                           ; FAD11B  ae 0a 21
	ld wa, (xbc+62)                            ; FAD11E  99 3e 20
	ld (xix+2), wa                             ; FAD121  bc 02 50
Dev10C_SetChanReg_0540_or_0580__done:
	pop xix                                    ; FAD124  5c
	popw de                                    ; FAD125  4a
	popw hl                                    ; FAD126  4b
	unlk32 xiz                                 ; FAD127  ee 0d
	ret                                        ; FAD129  0e
; --------------------------------------------------------------------------
; Dev10C_WriteReg_0201 -- register 0x0201 = the caller's word.  The only routine in
; the bank whose register number is a constant.
;
; Called from: 0xFADCB9, its only calr site, which builds the word as
;              `and bc,0x0F9F / or bc,ix / or bc,hl` -- a packed field, so 0x0201
;              is a CONTROL register and not a per-channel parameter.
; Inputs:  (XIZ+8) = the 16-bit value.  There is no second argument: the caller
;          drops 2 bytes (`pop BC`), not 6.
; Outputs: one 16-bit write.
; Evidence: `ldw (xix),0x0201` writes the number as an immediate.
; Unknown:  what the register does, and what the 0x0F9F mask means.  Under the
;          `block*0x40 + channel` reading of the address that number is block 8,
;          channel 1 -- stated because the arithmetic works, not because anything
;          confirms it.
; --------------------------------------------------------------------------
Dev10C_WriteReg_0201:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD12A  ee 0c 00 00
	push xix                                   ; FAD12E  3c
	ld xix, 0x0010C000                         ; FAD12F  44 00 c0 10 00
	ldw (xix), 0x0201                          ; FAD134  b4 02 01 02
	ld bc, (xiz+8)                             ; FAD138  9e 08 21
	ld (xix+2), bc                             ; FAD13B  bc 02 51
	pop xix                                    ; FAD13E  5c
	unlk32 xiz                                 ; FAD13F  ee 0d
	ret                                        ; FAD141  0e
