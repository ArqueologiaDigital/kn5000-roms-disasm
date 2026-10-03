; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xFC856C-0xFC89C4  THE FLASH DRIVER, 512 KiB at 0x00E80000
; ==============================================================================
;
; 891 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared: 16 routines, the JEDEC command sequences, the two
; boot-block sector maps, the 64 KiB staging buffer, and the six routines
; the link's three deferred jobs call.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xFC856C-0xFC89C4 -- THE FLASH DRIVER: the 512 KiB device at 0x00E80000, the
;                      64 KiB staging buffer at 0x00010000, and the three jobs
;                      CPU 1 drives through the inter-processor link.
;                      16 routines, 1,113 bytes
; ==============================================================================
;
; ★★ THIS CLOSES Link_ServiceTask's LARGEST OPEN QUESTION.  That routine's header
; (converted above) ends "Unknown: the six 0xFC8xxx routines the three jobs call".
; All six are here, and together they say what the link is FOR:
;
;   bit 7 of 0x00852C  ->  Flash_ReadSectorToBuffer((0x00852D))
;                          Flash_ReadResetMode()
;                          Flash_SectorErase((0x00852D))
;                          -- "start a sector": copy it into RAM, then erase it
;   bit 6 of 0x00852C  ->  Flash_ReadResetMode()
;                          while (Flash_SectorBlankCheck((0x008531)) == 0xFFFF) ;
;                          Flash_ProgramSectorFromBuffer((0x008531))
;                          Link_SendCmdByte(6)   -- i.e. command 0xE6 back to CPU 1
;                          -- "commit the sector", then acknowledge
;   bit 5 of 0x00852C  ->  while (0x008536) < (0x008535):
;                              Flash_ProgramSlice1K((0x008536)++)
;                          -- "program the 1 KiB slices that have arrived so far".
;                          Link_ServiceTask holds 0x008536 in XIX for the whole
;                          routine (`lda XIX,0x008536` at 0xF99E60) and the arm's
;                          two loops both test `cp C,(0x008535)`.
;                          ⚠ SIMPLIFIED.  The real arm has two sub-paths -- one
;                          when the counter is still 0, gated on a blank check of
;                          the sector in (0x008568) that re-sets bit 5 and retries
;                          if the erase has not finished, and one when it is not,
;                          gated on (0x008537) == 1 -- and only the first sets
;                          (0x008537).  Read Link_ServiceTask for the exact shape;
;                          what is identified here is the CALL TARGET
;
; So the 0xE1/0xE2 command pair and micro-DMA channel 3 are the transport of a
; FLASH DOWNLOAD: CPU 1 pushes data into CPU 2's RAM buffer at 0x00010000 and
; CPU 2 burns it into the flash a kilobyte at a time, acknowledging with 0xE6.
; ⚠ Each of those three lines is a reading of the arms in Link_ServiceTask, whose
; own instructions are converted above; the call targets are the ones its header
; already cited, and they are what is newly identified here.  What the downloaded
; bytes ARE is still unknown.
;
; ★★ THE FLASH IS A 4-Mbit x16 BOOT-BLOCK PART, AND THE ROM PROVES ITS SECTOR MAP
; WITHOUT ANY DATASHEET.  Flash_SectorErase has two special arms, and the boot
; block they split is 64 KiB in both:
;
;     device code 0x22AB, sector 0x00E80000  ->  0x30 at +0x0000 +0x4000
;                                                +0x6000 +0x8000
;                                                = 16K, 8K, 8K, 32K
;     otherwise,          sector 0x00EF0000  ->  0x30 at +0x70000 +0x78000
;                                                +0x7A000 +0x7C000
;                                                = 32K, 8K, 8K, 16K
;
; The two maps are exact mirror images, one at the bottom of the device and one at
; the top, and the top one begins at 0x70000 -- seven 64 KiB sectors below it --
; so the device is 0x80000 = 512 KiB.
; ⚠ THIS IS NOT NEW AND IS NOT INDEPENDENT.  notes/FINDINGS-memory-map.md §2
; ("The flash, and why its size is established") already derived exactly this,
; from THIS SAME ROUTINE, before the block was converted.  What round 4 adds is
; not the size but the rest of the driver around it, and a script:
; `python3 notes/prom_c_flash_driver_check.py` asserts all four offsets on each
; arm, both size lists, the mirror relation and the 7 x 64 KiB, from the bytes --
; so the memory map's paragraph is now reproducible instead of hand-read.
;
; ⚠ THE PART NUMBER IS AN INFERENCE, AND IT IS LABELLED AS ONE -- the same
; inference notes/FINDINGS-memory-map.md §2 already records ("Am29F400B/T-class;
; that is an inference from published ID tables, with no datasheet in these
; trees").  16K/8K/8K/32K at the bottom and its mirror at the top is that family's
; sector map, and JEDEC assigns manufacturer code 0x01 to AMD and 0x04 to Fujitsu
; -- the two codes Flash_ReadDeviceId accepts.  That is EXTERNAL knowledge.  What
; this image establishes on its own is: a JEDEC-command flash, 512 KiB, 16-bit,
; with a split boot block at either end and exactly two device codes recognised
; (0x2223 and 0x22AB).  No part is named in any label here.
; ★ What round 4 DOES add to that paragraph is the manufacturer side: the memory
; map only had the device-ID compare at 0xFC8694.  Flash_ReadDeviceId shows where
; the value comes from -- a real autoselect read of the chip at boot, gated on
; manufacturer code 1 or 4 -- so 0x00E29D holds what the silicon answered and not
; a build-time constant.
;
; ★ THE STAGING BUFFER IS AT 0x00010000 AND IS ONE WHOLE SECTOR.
; Flash_ReadSectorToBuffer, Flash_ProgramSectorFromBuffer and Flash_ProgramSlice1K
; all load 0x00010000 into XIX and mask their flash argument with 0x00FF0000, and
; the block routines compute their destination as `flash address - 0x00E70000`,
; which is 0x00010000 + (address - 0x00E80000).  ⚠ SO THE BUFFER SHADOWS THE FIRST
; 64 KiB OF THE FLASH ONLY: for a sector above 0x00E8FFFF the block writers would
; address past the buffer.  Stated as read; nothing here says the firmware ever
; does that.  This also fills in one row of notes/FINDINGS-memory-map.md, whose
; CS3 range 0x010080-0x01FFFF was "NOT ESTABLISHED".
;
; ★ ONE LOOP COUNTS WITH AN 8-BIT REGISTER WHERE ITS TWO SIBLINGS USE 16.
; Flash_ProgramSectorFromBuffer (0xFC8935) and Flash_ProgramSlice1K (0xFC8989)
; both end their loop with `djnz BC` -- prefix byte 0xD9, the 16-bit register BC --
; and cover 0x8000 and 0x0200 words respectively.  Flash_SectorBlankCheck loads
; `ld BC,0x4000` and then ends its loop with `djnz B` at 0xFC89A5 -- prefix byte
; 0xCA, the 8-BIT register B, which is the HIGH byte of BC.  B is therefore 0x40,
; the loop runs 64 times, and since each pass compares a 32-bit long the routine
; inspects the FIRST 256 BYTES of the sector and not the 64 KiB the 0x4000 implies.
; The prefix->register mapping is MAME's: oC8()/oD8() and get_reg8_current()
; in mame/src/devices/cpu/tlcs900/900tbl.hxx (lines 115-150, 5672-5690).
; ⚠ Recorded as what the bytes say.  Whether it is a defect or a deliberate short
; poll is NOT established -- as an "is the erase finished" poll a 256-byte sample
; is adequate, and every caller uses it only that way.
; `notes/prom_c_flash_driver_check.py` asserts both prefix bytes and all three
; counts.
;
; ⚠ WHAT THIS BLOCK DOES NOT ESTABLISH: what is stored in the flash; what
; 0x00E83232 holds (Flash_ReadResetMode reads it and every caller discards the
; value); and what the layer at 0xFC38xx-0xFC3Cxx -- three callers of
; Flash_ReprogramSector and three more of Flash_ReadSectorToBuffer -- is doing.
; That layer is the next thing to convert.
;
; --------------------------------------------------------------------------
; Flash_ReadResetMode -- put the flash back into read mode.
;
; Called from: EIGHT sites: 0xF99EB9 and 0xF99EDB (`call`, both inside
;          Link_ServiceTask, converted above), and 0xFC85F3, 0xFC8774, 0xFC8799,
;          0xFC8806, 0xFC88A0, 0xFC88EE (`calr`, all in this block).
;          `notes/prom_c_xrefs.py 0xFC856C --no-window` -- 2 literal, 6 CALR.
; Inputs:  none.
; Outputs: the JEDEC read/reset sequence on the flash at 0x00E80000 --
;          (0x00E8AAAA) = 0xAA, (0x00E85554) = 0x55, (0x00E8AAAA) = 0xF0 -- and
;          then WA = the 16-bit word read from 0x00E83232.
; Evidence: byte-checked.  `python3 notes/prom_c_flash_driver_check.py` asserts
;          the two unlock addresses and every command byte in this block against
;          the ROM image, matching BYTES and not disassembler text.
; Unknown:  ⚠ why it reads 0x00E83232.  The read is real (`ld BC,(XIX+0x3232)` at
;          0xFC8593 with XIX = 0x00E80000) and the value is returned, but every
;          caller in this image discards WA.  A dummy read to complete the reset
;          is one reading and a fixed word stored in the flash is another;
;          nothing here decides between them.
; --------------------------------------------------------------------------
Flash_ReadResetMode:
	link	xiz, 0xfffc          ; FC856C  link XIZ,0xfffc   [llvm-mc cannot encode this]
	push	xix                               ; FC8570  push XIX
	ld	xix, 0xE80000                       ; FC8571  ld XIX,0x00e80000
	ld	xbc, xix                            ; FC8576  ld XBC,XIX
	add	xbc, 0xAAAA                        ; FC8578  add XBC,0x0000aaaa
	ld	(xiz-4), xbc                        ; FC857E  ld (XIZ+0xfc),XBC
	ldw	(xbc), 0x00aa         ; FC8581  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ldw	(xix+21844), 0x0055 ; FC8585  ld (XIX+0x5554),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC858C  ld XBC,(XIZ+0xfc)
	ldw	(xbc), 0x00f0         ; FC858F  ld (XBC),0x00f0   [llvm-mc cannot encode this]
	ld	bc, (xix+0x3232)                    ; FC8593  ld BC,(XIX+0x3232)
	ld	wa, bc                              ; FC8598  ld WA,BC
	pop	xix                                ; FC859A  pop XIX
	unlk	xiz                             ; FC859B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC859D  ret
; --------------------------------------------------------------------------
; ★★ Flash_ReadDeviceId -- JEDEC autoselect: read the manufacturer and device
;                     codes out of the flash, and recognise exactly two parts.
;
; Called from: 0xFC88A3 (`calr`), ONE site -- Flash_ProbeAndStoreDeviceId, below.
; Inputs:  none.
; Outputs: (0x00E29F) = the 16-bit MANUFACTURER code read from 0x00E80000.
;          WA = the 16-bit DEVICE code read from 0x00E80002 if the pair is
;          recognised, otherwise 0xFFFF -- IX is preloaded with 0xFFFF at
;          0xFC85AD and is only overwritten on a match.
;          ⚠ THE RESET IS ON THE MATCHING PATH ONLY.  `calr Flash_ReadResetMode`
;          is at 0xFC85F3, and 0xFC85E1 `jr NZ,0xFC85F6` jumps PAST it when the
;          manufacturer word is neither 1 nor 4.  So on an unrecognised part this
;          routine returns with the device still in autoselect mode, where reads
;          return ID words rather than data.  Its one caller
;          (Flash_ProbeAndStoreDeviceId) does not reset it afterwards either.
;          Stated as the instructions read; no claim that it ever happens.
; Evidence: (0x00E8AAAA)=0xAA / (0x00E85554)=0x55 / (0x00E8AAAA)=0x90 is JEDEC
;          autoselect, and the two reads that follow are at base+0 and base+2.
;          The four literals it tests are asserted from the ROM bytes by
;          `python3 notes/prom_c_flash_driver_check.py`: manufacturer 1
;          (`cp DE,1` at 0xFC85DB) or 4 (0xFC85DF), device 0x2223 (0xFC85E3) or
;          0x22AB (0xFC85EB).
;          ⚠ The manufacturer test GATES the device test but the device value is
;          what is returned, and the two device comparisons are written as two
;          independent `cp / jr NZ / ld IX,HL` pairs rather than a switch -- so a
;          part answering 0x2223 is accepted exactly as one answering 0x22AB, and
;          only 0x22AB gets the special boot map in Flash_SectorErase.
; Unknown:  the meaning of the codes is external knowledge; see the block comment
;          above for what is and is not established from this image.
; --------------------------------------------------------------------------
Flash_ReadDeviceId:
	link	xiz, 0xfff8          ; FC859E  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FC85A2  push HL
	pushw	de                               ; FC85A3  push DE
	pushw	ix                               ; FC85A4  push IX
	ld	xbc, 0xE80000                       ; FC85A5  ld XBC,0x00e80000
	ld	(xiz-4), xbc                        ; FC85AA  ld (XIZ+0xfc),XBC
	ldw	ix, 0xFFFF                         ; FC85AD  ld IX,0xffff
	add	xbc, 0xAAAA                        ; FC85B0  add XBC,0x0000aaaa
	ld	(xiz-8), xbc                        ; FC85B6  ld (XIZ+0xf8),XBC
	ldw	(xbc), 0x00aa         ; FC85B9  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC85BD  ld XBC,(XIZ+0xfc)
	ldw	(xbc+21844), 0x0055 ; FC85C0  ld (XBC+0x5554),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC85C7  ld XBC,(XIZ+0xf8)
	ldw	(xbc), 0x0090         ; FC85CA  ld (XBC),0x0090   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC85CE  ld XBC,(XIZ+0xfc)
	ld	de, (xbc)                           ; FC85D1  ld DE,(XBC)
	ld	(0xE29F:24), de                    ; FC85D3  ld (0x00e29f),DE
	ld	hl, (xbc+2)                         ; FC85D8  ld HL,(XBC+0x02)
	cp	de, 1:i3                              ; FC85DB  cp DE,1
	jr z, Flash_ReadDeviceId__FC85E3                        ; FC85DD  jr Z,0xfc85e3
	cp	de, 4:i3                              ; FC85DF  cp DE,4
	jr nz, Flash_ReadDeviceId__FC85F6                       ; FC85E1  jr NZ,0xfc85f6
Flash_ReadDeviceId__FC85E3:
	cp	hl, 0x2223                          ; FC85E3  cp HL,0x2223
	jr nz, Flash_ReadDeviceId__FC85EB                       ; FC85E7  jr NZ,0xfc85eb
	ld	ix, hl                              ; FC85E9  ld IX,HL
Flash_ReadDeviceId__FC85EB:
	cp	hl, 0x22AB                          ; FC85EB  cp HL,0x22ab
	jr nz, Flash_ReadDeviceId__FC85F3                       ; FC85EF  jr NZ,0xfc85f3
	ld	ix, hl                              ; FC85F1  ld IX,HL
Flash_ReadDeviceId__FC85F3:
	calr Flash_ReadResetMode             ; FC85F3  calr 0xfc856c
Flash_ReadDeviceId__FC85F6:
	ld	wa, ix                              ; FC85F6  ld WA,IX
	popw	ix                                ; FC85F8  pop IX
	popw	de                                ; FC85F9  pop DE
	popw	hl                                ; FC85FA  pop HL
	unlk	xiz                             ; FC85FB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC85FD  ret
; --------------------------------------------------------------------------
; Flash_ChipErase -- erase the ENTIRE flash device.
;
; Called from: NOT FOUND.  `notes/prom_c_xrefs.py 0xFC85FE --no-window` reports no
;          literal and no calr reaching it; short PC-relative forms are not
;          searched, so this is "not found", never "unreachable".
; Inputs:  none.
; Outputs: the six-cycle JEDEC chip-erase command -- AA / 55 / 0x80 then
;          AA / 55 / 0x10, all through 0x00E8AAAA and 0x00E85554.
;          ⚠ It does NOT wait for completion and returns immediately.
; Evidence: the six command bytes are asserted from the ROM by
;          `notes/prom_c_flash_driver_check.py`; 0x10 after the 0x80 setup is
;          what distinguishes chip erase from the 0x30 of Flash_SectorErase.
; --------------------------------------------------------------------------
Flash_ChipErase:
	link	xiz, 0xfff8          ; FC85FE  link XIZ,0xfff8   [llvm-mc cannot encode this]
	push	xix                               ; FC8602  push XIX
	ld	xix, 0xE80000                       ; FC8603  ld XIX,0x00e80000
	ld	xbc, xix                            ; FC8608  ld XBC,XIX
	add	xbc, 0xAAAA                        ; FC860A  add XBC,0x0000aaaa
	ld	(xiz-4), xbc                        ; FC8610  ld (XIZ+0xfc),XBC
	ldw	(xbc), 0x00aa         ; FC8613  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, xix                            ; FC8617  ld XBC,XIX
	add	xbc, 0x5554                        ; FC8619  add XBC,0x00005554
	ld	(xiz-8), xbc                        ; FC861F  ld (XIZ+0xf8),XBC
	ldw	(xbc), 0x0055         ; FC8622  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC8626  ld XBC,(XIZ+0xfc)
	ldw	(xbc), 0x0080         ; FC8629  ld (XBC),0x0080   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC862D  ld XBC,(XIZ+0xfc)
	ldw	(xbc), 0x00aa         ; FC8630  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC8634  ld XBC,(XIZ+0xf8)
	ldw	(xbc), 0x0055         ; FC8637  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC863B  ld XBC,(XIZ+0xfc)
	ldw	(xbc), 0x0010         ; FC863E  ld (XBC),0x0010   [llvm-mc cannot encode this]
	pop	xix                                ; FC8642  pop XIX
	unlk	xiz                             ; FC8643  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8645  ret
; --------------------------------------------------------------------------
; ★★ Flash_SectorErase -- erase one 64 KiB sector, splitting the BOOT BLOCK into
;                    its four sub-sectors, with a different map at each end.
;
; Called from: FOUR sites: 0xF99EC3 (`call`, the bit-7 job of Link_ServiceTask)
;          and 0xFC8778, 0xFC87A8, 0xFC8815 (`calr`, in this block).
;          `notes/prom_c_xrefs.py 0xFC8646 --no-window`.
; Inputs:  (XIZ+0x08) = a flash address, masked down to a 64 KiB boundary at
;          0xFC8656 (`ld XWA,0x00FF0000 / and XIX,XWA`).  It also reads
;          (0x00E29D), the device code Flash_ProbeAndStoreDeviceId stored there.
; Outputs: AA / 55 / 0x80 then AA / 55 / 0x30 -- JEDEC sector erase -- with the
;          0x30 issued once per sub-sector.  Interrupts are raised to level 6 for
;          the whole sequence (`ei 6` at 0xFC865D, back to `ei 0` at 0xFC8713).
;          ⚠ It does not wait; Flash_SectorBlankCheck is the completion poll.
; Evidence: three arms, all four offsets of each asserted from the ROM bytes by
;          `python3 notes/prom_c_flash_driver_check.py`:
;            (0x00E29D) == 0x22AB and sector == 0x00E80000
;                -> 0x30 at +0x0000, +0x4000, +0x6000, +0x8000   (16K 8K 8K 32K)
;            device code anything else, and sector == 0x00EF0000
;                -> 0x30 at +0x70000, +0x78000, +0x7A000, +0x7C000 (32K 8K 8K 16K)
;            neither
;                -> a single 0x30 at the sector base
; Unknown:  ⚠ the two arms are keyed on DIFFERENT things -- the first on the device
;          code AND the address, the second on the address alone.  So device code
;          0x22AB with sector 0x00EF0000, or 0x2223 with sector 0x00E80000, both
;          fall through to the single-0x30 arm, which on a split boot block would
;          erase only its first sub-sector.  Recorded as the instructions read; no
;          claim that either combination ever occurs.
; --------------------------------------------------------------------------
Flash_SectorErase:
	link	xiz, 0xfff4          ; FC8646  link XIZ,0xfff4   [llvm-mc cannot encode this]
	push	xix                               ; FC864A  push XIX
	ld	xbc, 0xE80000                       ; FC864B  ld XBC,0x00e80000
	ld	(xiz-4), xbc                        ; FC8650  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC8653  ld XIX,(XIZ+0x08)
	ld	xwa, MASK_BITS16_23                       ; FC8656  ld XWA,0x00ff0000
	and	xix, xwa                           ; FC865B  and XIX,XWA
	ei	6                                   ; FC865D  ei 0x06
	ld	xbc, (xiz-4)                        ; FC865F  ld XBC,(XIZ+0xfc)
	add	xbc, 0xAAAA                        ; FC8662  add XBC,0x0000aaaa
	ld	(xiz-8), xbc                        ; FC8668  ld (XIZ+0xf8),XBC
	ldw	(xbc), 0x00aa         ; FC866B  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC866F  ld XBC,(XIZ+0xfc)
	add	xbc, 0x5554                        ; FC8672  add XBC,0x00005554
	ld	(xiz-12), xbc                       ; FC8678  ld (XIZ+0xf4),XBC
	ldw	(xbc), 0x0055         ; FC867B  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC867F  ld XBC,(XIZ+0xf8)
	ldw	(xbc), 0x0080         ; FC8682  ld (XBC),0x0080   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC8686  ld XBC,(XIZ+0xf8)
	ldw	(xbc), 0x00aa         ; FC8689  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-12)                       ; FC868D  ld XBC,(XIZ+0xf4)
	ldw	(xbc), 0x0055         ; FC8690  ld (XBC),0x0055   [llvm-mc cannot encode this]
	cpw	(0x00e29d:24), 0x22ab ; FC8694  cp (0x00e29d),0x22ab   [llvm-mc cannot encode this]
	jr nz, Flash_SectorErase__FC86CF                       ; FC869B  jr NZ,0xfc86cf
	cp	xix, 0xE80000                       ; FC869D  cp XIX,0x00e80000
	jr nz, Flash_SectorErase__FC870D                       ; FC86A3  jr NZ,0xfc870d
	ld	xbc, (xiz-4)                        ; FC86A5  ld XBC,(XIZ+0xfc)
	ldw	(xbc), 0x0030         ; FC86A8  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86AC  ld XBC,(XIZ+0xfc)
	ldw	(xbc+16384), 0x0030 ; FC86AF  ld (XBC+0x4000),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86B6  ld XBC,(XIZ+0xfc)
	ldw	(xbc+24576), 0x0030 ; FC86B9  ld (XBC+0x6000),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86C0  ld XBC,(XIZ+0xfc)
	add	xbc, 0x8000                        ; FC86C3  add XBC,0x00008000
	ldw	(xbc), 0x0030         ; FC86C9  ld (XBC),0x0030   [llvm-mc cannot encode this]
	jr Flash_SectorErase__FC8713                           ; FC86CD  jr T,0xfc8713
Flash_SectorErase__FC86CF:
	cp	xix, 0xEF0000                       ; FC86CF  cp XIX,0x00ef0000
	jr nz, Flash_SectorErase__FC870D                       ; FC86D5  jr NZ,0xfc870d
	ld	xbc, (xiz-4)                        ; FC86D7  ld XBC,(XIZ+0xfc)
	add	xbc, 0x70000                       ; FC86DA  add XBC,0x00070000
	ldw	(xbc), 0x0030         ; FC86E0  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86E4  ld XBC,(XIZ+0xfc)
	add	xbc, 0x78000                       ; FC86E7  add XBC,0x00078000
	ldw	(xbc), 0x0030         ; FC86ED  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86F1  ld XBC,(XIZ+0xfc)
	add	xbc, 0x7A000                       ; FC86F4  add XBC,0x0007a000
	ldw	(xbc), 0x0030         ; FC86FA  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86FE  ld XBC,(XIZ+0xfc)
	add	xbc, 0x7C000                       ; FC8701  add XBC,0x0007c000
	ldw	(xbc), 0x0030         ; FC8707  ld (XBC),0x0030   [llvm-mc cannot encode this]
	jr Flash_SectorErase__FC8713                           ; FC870B  jr T,0xfc8713
Flash_SectorErase__FC870D:
	ld	xbc, xix                            ; FC870D  ld XBC,XIX
	ldw	(xbc), 0x0030         ; FC870F  ld (XBC),0x0030   [llvm-mc cannot encode this]
Flash_SectorErase__FC8713:
	ei	0                                     ; FC8713  ei 0x00
	pop	xix                                ; FC8715  pop XIX
	unlk	xiz                             ; FC8716  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8718  ret
; --------------------------------------------------------------------------
; DSP_WriteChans0to3_FromE29D -- call DSP_ChannelRegs_Write8 for channels 0, 1, 2
;                     and 3, all four from the same 8 bytes at 0x00E29D.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC8719 --no-window`: no literal,
;          no calr; short PC-relative forms are not searched).
; Inputs:  the 8 bytes at 0x00E29D.
; Outputs: 32 DSP registers -- eight in each of channels 0..3 of the device at
;          0x00E00000, via DSP_ChannelRegs_Write8 (0xF9804A, converted at the top
;          of this file).
; Evidence: mechanical, and byte-asserted by
;          `python3 notes/prom_c_flash_driver_check.py`.  `lda XIX,0xF9804A` at
;          0xFC871A takes that routine's address; each of the four blocks does
;          `push &0x00E29D / push #n / push &<next block> / jp XIX` for
;          n = 0, 1, 2, 3 -- a hand-built call whose "return address" is the last
;          push, so the callee's `ret` lands on the following block.  That places
;          the channel at (XSP+4) and the pointer at (XSP+6), which is exactly
;          DSP_ChannelRegs_Write8's documented convention, and 0xFC8763 then drops
;          0x18 = 24 = 4 x 6 argument bytes.
; Unknown:  ⚠ WHAT IT IS FOR, and why it sits inside the flash driver.  0x00E29D
;          is where Flash_ProbeAndStoreDeviceId stores the device code and
;          0x00E29F is where Flash_ReadDeviceId stores the manufacturer code, so
;          the first four of the eight bytes handed to each DSP channel are the
;          two flash ID words.  Whether that is deliberate or whether 0x00E29D is
;          simply a scratch buffer two unrelated things share is NOT established.
; --------------------------------------------------------------------------
DSP_WriteChans0to3_FromE29D:
	push	xix                               ; FC8719  push XIX
	lda	xix, (DSP_ChannelRegs_Write8:24)                 ; FC871A  lda XIX,0xf9804a
	lda	xbc, (0xE29D:24)                   ; FC871F  lda XBC,0x00e29d
	push	xbc                               ; FC8724  push XBC
	pushw	0                                ; FC8725  push 0x0000
	lda	xiy, (DSP_WriteChans0to3_FromE29D__FC8730:24)                 ; FC8728  lda XIY,0xfc8730
	push	xiy                               ; FC872D  push XIY
	jp	(xix)                               ; FC872E  jp T,XIX
DSP_WriteChans0to3_FromE29D__FC8730:
	lda	xbc, (0xE29D:24)                   ; FC8730  lda XBC,0x00e29d
	push	xbc                               ; FC8735  push XBC
	pushw	1                                ; FC8736  push 0x0001
	lda	xiy, (DSP_WriteChans0to3_FromE29D__FC8741:24)                 ; FC8739  lda XIY,0xfc8741
	push	xiy                               ; FC873E  push XIY
	jp	(xix)                               ; FC873F  jp T,XIX
DSP_WriteChans0to3_FromE29D__FC8741:
	lda	xbc, (0xE29D:24)                   ; FC8741  lda XBC,0x00e29d
	push	xbc                               ; FC8746  push XBC
	pushw	2                                ; FC8747  push 0x0002
	lda	xiy, (DSP_WriteChans0to3_FromE29D__FC8752:24)                 ; FC874A  lda XIY,0xfc8752
	push	xiy                               ; FC874F  push XIY
	jp	(xix)                               ; FC8750  jp T,XIX
DSP_WriteChans0to3_FromE29D__FC8752:
	lda	xbc, (0xE29D:24)                   ; FC8752  lda XBC,0x00e29d
	push	xbc                               ; FC8757  push XBC
	pushw	3                                ; FC8758  push 0x0003
	lda	xiy, (DSP_WriteChans0to3_FromE29D__FC8763:24)                 ; FC875B  lda XIY,0xfc8763
	push	xiy                               ; FC8760  push XIY
	jp	(xix)                               ; FC8761  jp T,XIX
DSP_WriteChans0to3_FromE29D__FC8763:
	add	xsp, 24                            ; FC8763  add XSP,0x00000018
	pop	xix                                ; FC8769  pop XIX
	ret                                    ; FC876A  ret
; --------------------------------------------------------------------------
; sub_FC876B -- one `ret`, nothing else.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC876B --no-window`).
; Evidence: the single byte 0x0E at 0xFC876B, between the `ret` that ends
;          DSP_WriteChans0to3_FromE29D and the `link` that starts
;          Flash_ReprogramSector.  Named, not interpreted: this file already has
;          one such stub (Link_ChannelHandler_Ignore) that turned out to be a
;          pointer-table entry, so a lone `ret` is worth a label even when
;          nothing found reaches it.
; --------------------------------------------------------------------------
sub_FC876B:
	ret                                    ; FC876B  ret
; --------------------------------------------------------------------------
; Flash_ReprogramSector -- erase one sector and burn the staging buffer into it.
;
; Called from: 0xFC39E1, 0xFC3B17, 0xFC3CAB (`call`) -- THREE sites, all in the
;          still-unconverted stretch around 0xFC38xx-0xFC3Cxx.
;          `notes/prom_c_xrefs.py 0xFC876C --no-window`.
; Inputs:  (XIZ+0x08) = the flash sector address.  The staging buffer at
;          0x00010000 must already hold what is to be written -- this routine
;          never fills it.
; Outputs: Flash_ReadResetMode(), Flash_SectorErase(addr), then
;          `while (Flash_SectorBlankCheck(addr) == 0xFFFF) ;`, then
;          Flash_ProgramSectorFromBuffer(addr).
; Evidence: the four calls are the instructions at 0xFC8774, 0xFC8778, 0xFC877D
;          and 0xFC8789, and the wait is `cp WA,0xFFFF / jr Z,0xFC877C` at
;          0xFC8782 -- i.e. it spins while the sector is NOT yet blank, which is
;          the sense Flash_SectorBlankCheck's return value has.
; --------------------------------------------------------------------------
Flash_ReprogramSector:
	link	xiz, 0x0000          ; FC876C  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; FC8770  push XIX
	ld	xix, (xiz+8)                        ; FC8771  ld XIX,(XIZ+0x08)
	calr Flash_ReadResetMode             ; FC8774  calr 0xfc856c
	push	xix                               ; FC8777  push XIX
	calr Flash_SectorErase             ; FC8778  calr 0xfc8646
	pop	xiy                                ; FC877B  pop XIY
Flash_ReprogramSector__FC877C:
	push	xix                               ; FC877C  push XIX
	call	Flash_SectorBlankCheck                          ; FC877D  call 0xfc898f
	pop	xiy                                ; FC8781  pop XIY
	cp	wa, 0xFFFF                          ; FC8782  cp WA,0xffff
	jr z, Flash_ReprogramSector__FC877C                        ; FC8786  jr Z,0xfc877c
	push	xix                               ; FC8788  push XIX
	call	Flash_ProgramSectorFromBuffer                          ; FC8789  call 0xfc88f9
	pop	xbc                                ; FC878D  pop XBC
	pop	xix                                ; FC878E  pop XIX
	unlk	xiz                             ; FC878F  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8791  ret
; --------------------------------------------------------------------------
; Flash_WriteBlockIntoSector -- patch one block into the staging buffer, then
;                     erase and reprogram the sector that holds it.
;
; Called from: 0xFC88EB (`calr`), ONE site -- Flash_WriteRampPattern_E81000.
; Inputs:  (XIZ+0x08) = source pointer; (XIZ+0x0C) = a BYTE count (halved to a
;          word count at 0xFC87C2, `srl 0x01,IY`); (XIZ+0x0E) = the flash address
;          to write at.
; Outputs: Flash_ReadResetMode(); Flash_ReadSectorToBuffer(addr);
;          Flash_SectorErase(addr); then count/2 words copied from the source to
;          `addr - 0x00E70000`, i.e. into the staging buffer at the same offset
;          the flash address has inside the device; then the blank-check spin and
;          Flash_ProgramSectorFromBuffer(addr).
; Evidence: the destination arithmetic is the single instruction
;          `sub XBC,0x00E70000` at 0xFC87AE, asserted from the bytes by
;          `notes/prom_c_flash_driver_check.py`, and 0xE80000 - 0xE70000 =
;          0x010000 is the buffer base the other three routines load literally.
;          ⚠ THE READ-MODIFY-WRITE IS WHAT MAKES THIS SAFE: the sector is copied
;          into RAM BEFORE it is erased, the caller's block overwrites part of the
;          copy, and the copy goes back.  Without that first step the erase would
;          destroy everything else in the sector.
; Unknown:  the buffer only covers 0x00E80000-0x00E8FFFF, so an address above that
;          would write past it.  Stated as read.
; --------------------------------------------------------------------------
Flash_WriteBlockIntoSector:
	link	xiz, 0xfffc          ; FC8792  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FC8796  push HL
	pushw	de                               ; FC8797  push DE
	push	xix                               ; FC8798  push XIX
	calr Flash_ReadResetMode             ; FC8799  calr 0xfc856c
	ld	xbc, (xiz+14)                       ; FC879C  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC879F  push XBC
	call	Flash_ReadSectorToBuffer                          ; FC87A0  call 0xfc89af
	ld	xbc, (xiz+14)                       ; FC87A4  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87A7  push XBC
	calr Flash_SectorErase             ; FC87A8  calr 0xfc8646
	ld	xbc, (xiz+14)                       ; FC87AB  ld XBC,(XIZ+0x0e)
	sub	xbc, 0xE70000                      ; FC87AE  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC87B4  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC87B7  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC87BA  ld HL,0x0000
	ld	de, (xiz+12)                        ; FC87BD  ld DE,(XIZ+0x0c)
	ld	iy, de                              ; FC87C0  ld IY,DE
	srl	iy, 1                              ; FC87C2  srl 0x01,IY
	ld	de, iy                              ; FC87C5  ld DE,IY
	inc	8, xsp                             ; FC87C7  inc 0,XSP
Flash_WriteBlockIntoSector__FC87C9:
	cp	hl, de                              ; FC87C9  cp HL,DE
	jr nc, Flash_WriteBlockIntoSector__FC87E1                       ; FC87CB  jr NC,0xfc87e1
	ld	bc, (xix)                           ; FC87CD  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC87CF  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC87D2  ld (XWA),BC
	inc	2, xix                             ; FC87D4  inc 2,XIX
	sub	xbc, xbc                           ; FC87D6  sub XBC,XBC
	inc	2, xbc                             ; FC87D8  inc 2,XBC
	add	(xiz-4), xbc                       ; FC87DA  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC87DD  inc 1,HL
	jr Flash_WriteBlockIntoSector__FC87C9                           ; FC87DF  jr T,0xfc87c9
Flash_WriteBlockIntoSector__FC87E1:
	ld	xbc, (xiz+14)                       ; FC87E1  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87E4  push XBC
	call	Flash_SectorBlankCheck                          ; FC87E5  call 0xfc898f
	pop	xiy                                ; FC87E9  pop XIY
	cp	wa, 0xFFFF                          ; FC87EA  cp WA,0xffff
	jr z, Flash_WriteBlockIntoSector__FC87E1                        ; FC87EE  jr Z,0xfc87e1
	ld	xbc, (xiz+14)                       ; FC87F0  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87F3  push XBC
	call	Flash_ProgramSectorFromBuffer                          ; FC87F4  call 0xfc88f9
	pop	xbc                                ; FC87F8  pop XBC
	pop	xix                                ; FC87F9  pop XIX
	popw	de                                ; FC87FA  pop DE
	popw	hl                                ; FC87FB  pop HL
	unlk	xiz                             ; FC87FC  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC87FE  ret
; --------------------------------------------------------------------------
; Flash_WriteTwoBlocksIntoSector -- Flash_WriteBlockIntoSector with a second
;                     source block, written after the first.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC87FF --no-window`).
; Inputs:  six arguments.  (XIZ+0x08) src1, (XIZ+0x0C) byte count 1,
;          (XIZ+0x0E) the flash address -- which is also the sector that gets
;          erased and reprogrammed -- then (XIZ+0x12) src2, (XIZ+0x16) byte
;          count 2, (XIZ+0x18) the flash address for the second block.
; Outputs: identical to Flash_WriteBlockIntoSector up to 0xFC884E, then a second
;          copy loop through `(XIZ+0x18) - 0x00E70000`, and only then the
;          blank-check spin and Flash_ProgramSectorFromBuffer((XIZ+0x0E)).
; Evidence: the two copy loops at 0xFC8836 and 0xFC886A are the same eight
;          instructions with different frame offsets; the second destination uses
;          the same `sub XBC,0x00E70000` (0xFC8851, byte-asserted by
;          `notes/prom_c_flash_driver_check.py`).
;          ⚠ ONLY ONE SECTOR IS ERASED AND COMMITTED -- (XIZ+0x0E)'s.  The second
;          block therefore has to fall in the same 64 KiB sector for this to be
;          correct, and nothing in the routine checks that.  Stated as read.
; --------------------------------------------------------------------------
Flash_WriteTwoBlocksIntoSector:
	link	xiz, 0xfffc          ; FC87FF  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FC8803  push HL
	pushw	de                               ; FC8804  push DE
	push	xix                               ; FC8805  push XIX
	calr Flash_ReadResetMode             ; FC8806  calr 0xfc856c
	ld	xbc, (xiz+14)                       ; FC8809  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC880C  push XBC
	call	Flash_ReadSectorToBuffer                          ; FC880D  call 0xfc89af
	ld	xbc, (xiz+14)                       ; FC8811  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8814  push XBC
	calr Flash_SectorErase             ; FC8815  calr 0xfc8646
	ld	xbc, (xiz+14)                       ; FC8818  ld XBC,(XIZ+0x0e)
	sub	xbc, 0xE70000                      ; FC881B  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC8821  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC8824  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC8827  ld HL,0x0000
	ld	de, (xiz+12)                        ; FC882A  ld DE,(XIZ+0x0c)
	ld	iy, de                              ; FC882D  ld IY,DE
	srl	iy, 1                              ; FC882F  srl 0x01,IY
	ld	de, iy                              ; FC8832  ld DE,IY
	inc	8, xsp                             ; FC8834  inc 0,XSP
Flash_WriteTwoBlocksIntoSector__FC8836:
	cp	hl, de                              ; FC8836  cp HL,DE
	jr nc, Flash_WriteTwoBlocksIntoSector__FC884E                       ; FC8838  jr NC,0xfc884e
	ld	bc, (xix)                           ; FC883A  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC883C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC883F  ld (XWA),BC
	inc	2, xix                             ; FC8841  inc 2,XIX
	sub	xbc, xbc                           ; FC8843  sub XBC,XBC
	inc	2, xbc                             ; FC8845  inc 2,XBC
	add	(xiz-4), xbc                       ; FC8847  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC884A  inc 1,HL
	jr Flash_WriteTwoBlocksIntoSector__FC8836                           ; FC884C  jr T,0xfc8836
Flash_WriteTwoBlocksIntoSector__FC884E:
	ld	xbc, (xiz+24)                       ; FC884E  ld XBC,(XIZ+0x18)
	sub	xbc, 0xE70000                      ; FC8851  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC8857  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+18)                       ; FC885A  ld XIX,(XIZ+0x12)
	ldw	hl, 0                              ; FC885D  ld HL,0x0000
	ld	de, (xiz+22)                        ; FC8860  ld DE,(XIZ+0x16)
	ld	iy, de                              ; FC8863  ld IY,DE
	srl	iy, 1                              ; FC8865  srl 0x01,IY
	ld	de, iy                              ; FC8868  ld DE,IY
Flash_WriteTwoBlocksIntoSector__FC886A:
	cp	hl, de                              ; FC886A  cp HL,DE
	jr nc, Flash_WriteTwoBlocksIntoSector__FC8882                       ; FC886C  jr NC,0xfc8882
	ld	bc, (xix)                           ; FC886E  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC8870  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC8873  ld (XWA),BC
	inc	2, xix                             ; FC8875  inc 2,XIX
	sub	xbc, xbc                           ; FC8877  sub XBC,XBC
	inc	2, xbc                             ; FC8879  inc 2,XBC
	add	(xiz-4), xbc                       ; FC887B  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC887E  inc 1,HL
	jr Flash_WriteTwoBlocksIntoSector__FC886A                           ; FC8880  jr T,0xfc886a
Flash_WriteTwoBlocksIntoSector__FC8882:
	ld	xbc, (xiz+14)                       ; FC8882  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8885  push XBC
	call	Flash_SectorBlankCheck                          ; FC8886  call 0xfc898f
	pop	xiy                                ; FC888A  pop XIY
	cp	wa, 0xFFFF                          ; FC888B  cp WA,0xffff
	jr z, Flash_WriteTwoBlocksIntoSector__FC8882                        ; FC888F  jr Z,0xfc8882
	ld	xbc, (xiz+14)                       ; FC8891  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8894  push XBC
	call	Flash_ProgramSectorFromBuffer                          ; FC8895  call 0xfc88f9
	pop	xbc                                ; FC8899  pop XBC
	pop	xix                                ; FC889A  pop XIX
	popw	de                                ; FC889B  pop DE
	popw	hl                                ; FC889C  pop HL
	unlk	xiz                             ; FC889D  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC889F  ret
; --------------------------------------------------------------------------
; Flash_ProbeAndStoreDeviceId -- reset the flash, read its ID, remember it.
;
; Called from: 0xF98B85 (`call`) -- ONE site, in MAIN's start-up sequence.
;          `notes/prom_c_xrefs.py 0xFC88A0 --no-window`.
; Inputs:  none.
; Outputs: (0x00E29D) = the device code Flash_ReadDeviceId returned (0x2223,
;          0x22AB or 0xFFFF); (0x00E29F) = the manufacturer code, written by
;          Flash_ReadDeviceId itself.
; Evidence: three instructions, no frame: `calr Flash_ReadResetMode` (0xFC88A0),
;          `calr Flash_ReadDeviceId` (0xFC88A3), `ld (0x00E29D),WA` (0xFC88A6,
;          byte-asserted by `notes/prom_c_flash_driver_check.py`).
;          ★ This is what makes Flash_SectorErase's `cp (0x00E29D),0x22AB` a test
;          of the REAL part in the machine rather than of a build-time constant --
;          the value is sampled from the device at boot.
; --------------------------------------------------------------------------
Flash_ProbeAndStoreDeviceId:
	calr Flash_ReadResetMode             ; FC88A0  calr 0xfc856c
	calr Flash_ReadDeviceId             ; FC88A3  calr 0xfc859e
	ld	(0xE29D:24), wa                    ; FC88A6  ld (0x00e29d),WA
	ret                                    ; FC88AB  ret
; --------------------------------------------------------------------------
; MemFillWordRamp -- fill a word array with 0, 1, 2, ... n-1.
;
; Called from: 0xFC88E0 (`calr`), ONE site -- Flash_WriteRampPattern_E81000.
; Inputs:  (XIZ+0x08) = destination pointer; (XIZ+0x0C) = the number of WORDS.
; Outputs: dest[i] = i for i = 0 .. count-1, 16 bits each.
; Evidence: `ld (XIX),HL / inc 2,XIX / inc 1,HL` with the bound
;          `cp HL,(XIZ+0x0c) / jr C` -- the store is 2 bytes wide and the pointer
;          advances by 2, so the count is in words.  Named for what it does; it is
;          not flash-specific and its one caller is the pattern writer below.
; --------------------------------------------------------------------------
MemFillWordRamp:
	link	xiz, 0x0000          ; FC88AC  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FC88B0  push HL
	push	xix                               ; FC88B1  push XIX
	ld	xix, (xiz+8)                        ; FC88B2  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC88B5  ld HL,0x0000
	jr MemFillWordRamp__FC88C0                           ; FC88B8  jr T,0xfc88c0
MemFillWordRamp__FC88BA:
	ld	(xix), hl                           ; FC88BA  ld (XIX),HL
	inc	2, xix                             ; FC88BC  inc 2,XIX
	inc	1, hl                              ; FC88BE  inc 1,HL
MemFillWordRamp__FC88C0:
	cp	hl, (xiz+12)               ; FC88C0  cp HL,(XIZ+0x0c)   [llvm-mc cannot encode this]
	jr c, MemFillWordRamp__FC88BA                        ; FC88C3  jr C,0xfc88ba
	pop	xix                                ; FC88C5  pop XIX
	popw	hl                                ; FC88C6  pop HL
	unlk	xiz                             ; FC88C7  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC88C9  ret
; --------------------------------------------------------------------------
; Flash_WriteRampPattern_E81000 -- build a counting pattern in RAM and burn it to
;                     the flash at 0x00E81000.  A test or factory routine.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC88CA --no-window`).
; Inputs:  none -- every value is an immediate.
; Outputs: MemFillWordRamp(0x0000F000, 0x0100), i.e. 256 words 0..0xFF at
;          0x0000F000; then Flash_WriteBlockIntoSector(0x0000F000, 0x0100,
;          0x00E81000), which writes 0x0100/2 = 128 words = 256 bytes of that
;          ramp into the flash; then Flash_ReadResetMode.
; Evidence: `ld IX,0xF000 / extz XIX` (0xFC88CF) gives the 24-bit pointer
;          0x0000F000, and the two `push 0x0100` are the same immediate used as a
;          WORD count by MemFillWordRamp and as a BYTE count by
;          Flash_WriteBlockIntoSector -- which is why the ramp filled is twice as
;          long as the part written.  Stated as read.
; Unknown:  ⚠ what it is for.  Writing an ascending pattern into a fixed flash
;          address and never reading it back is what a production test looks like,
;          but nothing here calls it and nothing here verifies the result.
; --------------------------------------------------------------------------
Flash_WriteRampPattern_E81000:
	link	xiz, 0xfffc          ; FC88CA  link XIZ,0xfffc   [llvm-mc cannot encode this]
	push	xix                               ; FC88CE  push XIX
	ldw	ix, 0xF000                         ; FC88CF  ld IX,0xf000
	extz	xix                               ; FC88D2  extz XIX
	ld	xbc, 0xE81000                       ; FC88D4  ld XBC,0x00e81000
	ld	(xiz-4), xbc                        ; FC88D9  ld (XIZ+0xfc),XBC
	pushw	0x100                            ; FC88DC  push 0x0100
	push	xix                               ; FC88DF  push XIX
	calr MemFillWordRamp             ; FC88E0  calr 0xfc88ac
	ld	xbc, (xiz-4)                        ; FC88E3  ld XBC,(XIZ+0xfc)
	push	xbc                               ; FC88E6  push XBC
	pushw	0x100                            ; FC88E7  push 0x0100
	push	xix                               ; FC88EA  push XIX
	calr Flash_WriteBlockIntoSector             ; FC88EB  calr 0xfc8792
	calr Flash_ReadResetMode             ; FC88EE  calr 0xfc856c
	inc	8, xsp                             ; FC88F1  inc 0,XSP
	inc	8, xsp                             ; FC88F3  inc 0,XSP
	pop	xix                                ; FC88F5  pop XIX
	unlk	xiz                             ; FC88F6  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC88F8  ret
; --------------------------------------------------------------------------
; ★ Flash_ProgramSectorFromBuffer -- burn the whole 64 KiB staging buffer into one
;                     sector, word by word, skipping words that are 0xFFFF.
;
; Called from: FOUR sites: 0xF99EF6 (`call`, the bit-6 job of Link_ServiceTask),
;          0xFC8789, 0xFC87F4, 0xFC8895 (in this block).
;          `notes/prom_c_xrefs.py 0xFC88F9 --no-window`.
; Inputs:  (XSP+4) = a flash address; no stack frame.  Masked to its 64 KiB
;          sector at 0xFC8908.  Source: the staging buffer at 0x00010000.
; Outputs: for each of 0x8000 words: if the buffer word is 0xFFFF it is skipped
;          (an erased cell already reads 0xFFFF); otherwise AA / 55 / 0xA0 --
;          the JEDEC word-program command -- then the word is written to the flash
;          and re-read until it matches (`cp (XIY),WA / jr NZ` at 0xFC892F), which
;          is the data-polling completion test.  Interrupts are raised to level 6
;          around each program cycle and lowered again before the poll.
; Evidence: `ld BC,0x8000` at 0xFC890E and `djnz BC` at 0xFC8935 (prefix byte
;          0xD9 = the 16-bit BC), so 0x8000 words = 65,536 bytes = one whole
;          sector.  Both are asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  the skip means this can only ever turn 1 bits into 0 bits, which is
;          what flash does -- so the caller must have erased the sector first.
;          Every caller in this image does.
; --------------------------------------------------------------------------
Flash_ProgramSectorFromBuffer:
	ld	xiy, (xsp+4)                        ; FC88F9  ld XIY,(XSP+0x04)
	push	xhl                               ; FC88FC  push XHL
	push	xix                               ; FC88FD  push XIX
	ld	xhl, 0xE8AAAA                       ; FC88FE  ld XHL,0x00e8aaaa
	ld	xix, 0x10000                        ; FC8903  ld XIX,0x00010000
	and	xiy, MASK_BITS16_23                      ; FC8908  and XIY,0x00ff0000
	ldw	bc, 0x8000                         ; FC890E  ld BC,0x8000
	ld	wa, (xix+)                       ; FC8911  ld WA,(XIX+)
	cp	wa, 0xFFFF                          ; FC8914  cp WA,0xffff
	jr z, Flash_ProgramSectorFromBuffer__FC8933                        ; FC8918  jr Z,0xfc8933
	ei	6                                   ; FC891A  ei 0x06
	ldw	(xhl), 0x00aa         ; FC891C  ld (XHL),0x00aa   [llvm-mc cannot encode this]
	ldw	(0xE85554:24), 85                 ; FC8920  ld (0xe85554),0x0055
	ldw	(xhl), 0x00a0         ; FC8927  ld (XHL),0x00a0   [llvm-mc cannot encode this]
	ld	(xiy), wa                           ; FC892B  ld (XIY),WA
	ei	0                                     ; FC892D  ei 0x00
Flash_ProgramSectorFromBuffer__FC892F:
	cp	(xiy), wa                           ; FC892F  cp (XIY),WA
	jr nz, Flash_ProgramSectorFromBuffer__FC892F                       ; FC8931  jr NZ,0xfc892f
Flash_ProgramSectorFromBuffer__FC8933:
	inc	2, xiy                             ; FC8933  inc 2,XIY
	djnz16	bc, -39                         ; FC8935  djnz BC,0xfc8911
	pop	xix                                ; FC8938  pop XIX
	pop	xhl                                ; FC8939  pop XHL
	ret                                    ; FC893A  ret
; --------------------------------------------------------------------------
; ★★ Flash_ProgramSlice1K -- burn ONE 1 KiB slice of the staging buffer into the
;                     matching 1 KiB of the sector.  This is the routine the
;                     inter-processor link drives.
;
; Called from: 0xF99F32 and 0xF99F5E (`call`) -- TWO sites, both the bit-5 job of
;          Link_ServiceTask, which calls it once per slice index while a counter
;          is below a limit byte (see Inputs).
;          `notes/prom_c_xrefs.py 0xFC893B --no-window`.
; Inputs:  (XSP+4) = the slice INDEX, one byte, no stack frame.  The sector comes
;          from the 32-bit variable (0x008568), masked with 0x00FF0000; the source
;          is the staging buffer at 0x00010000.  The index the two call sites pass
;          is the byte at 0x008536 and the bound they test it against is the byte
;          at 0x008535 -- both read off Link_ServiceTask, not off this routine.
; Outputs: the same AA / 55 / 0xA0 word-program loop as
;          Flash_ProgramSectorFromBuffer, restricted to
;          buffer[index*0x400 .. index*0x400+0x3FF] -> sector[same offset].
; Evidence: `extz WA / sll 0x0a,WA / extz XWA / or XIX,XWA / or XIY,XWA` at
;          0xFC8957-0xFC8960 scales the index by 1 << 10 = 1024 and ORs it into
;          BOTH the buffer pointer and the flash pointer, so the two stay aligned;
;          `ld BC,0x0200` at 0xFC8962 with `djnz BC` at 0xFC8989 (prefix 0xD9, the
;          16-bit BC) is 512 words = 1,024 bytes, which is exactly the 1 << 10 the
;          index was scaled by.  The shift, the count and the prefix byte are all
;          asserted from the ROM by `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  ⚠ `or` is used rather than `add`, so an index of 0x40 or more would
;          collide with the sector bits instead of overflowing cleanly.  With a
;          64 KiB sector the valid range is 0..0x3F.  Nothing here bounds it; the
;          caller's counter is what limits it.
; --------------------------------------------------------------------------
Flash_ProgramSlice1K:
	ld	a, (xsp+4)                          ; FC893B  ld A,(XSP+0x04)
	push	xhl                               ; FC893E  push XHL
	push	xix                               ; FC893F  push XIX
	ld	xhl, 0xE8AAAA                       ; FC8940  ld XHL,0x00e8aaaa
	ld	xix, 0x10000                        ; FC8945  ld XIX,0x00010000
	lda	xiy, (0x8568:24)                   ; FC894A  lda XIY,0x008568
	ld	xiy, (xiy)                          ; FC894F  ld XIY,(XIY)
	and	xiy, MASK_BITS16_23                      ; FC8951  and XIY,0x00ff0000
	extz	wa                                ; FC8957  extz WA
	sll	wa, 10                             ; FC8959  sll 0x0a,WA
	extz	xwa                               ; FC895C  extz XWA
	or	xix, xwa                            ; FC895E  or XIX,XWA
	or	xiy, xwa                            ; FC8960  or XIY,XWA
	ldw	bc, 0x200                          ; FC8962  ld BC,0x0200
	ld	wa, (xix+)                       ; FC8965  ld WA,(XIX+)
	cp	wa, 0xFFFF                          ; FC8968  cp WA,0xffff
	jr z, Flash_ProgramSlice1K__FC8987                        ; FC896C  jr Z,0xfc8987
	ei	6                                   ; FC896E  ei 0x06
	ldw	(xhl), 0x00aa         ; FC8970  ld (XHL),0x00aa   [llvm-mc cannot encode this]
	ldw	(0xE85554:24), 85                 ; FC8974  ld (0xe85554),0x0055
	ldw	(xhl), 0x00a0         ; FC897B  ld (XHL),0x00a0   [llvm-mc cannot encode this]
	ld	(xiy), wa                           ; FC897F  ld (XIY),WA
	ei	0                                     ; FC8981  ei 0x00
Flash_ProgramSlice1K__FC8983:
	cp	(xiy), wa                           ; FC8983  cp (XIY),WA
	jr nz, Flash_ProgramSlice1K__FC8983                       ; FC8985  jr NZ,0xfc8983
Flash_ProgramSlice1K__FC8987:
	inc	2, xiy                             ; FC8987  inc 2,XIY
	djnz16	bc, -39                         ; FC8989  djnz BC,0xfc8965
	pop	xix                                ; FC898C  pop XIX
	pop	xhl                                ; FC898D  pop XHL
	ret                                    ; FC898E  ret
; --------------------------------------------------------------------------
; ★ Flash_SectorBlankCheck -- is this sector erased?  ⚠ It only looks at the first
;                     256 bytes, and the reason is one prefix byte.
;
; Called from: FIVE sites: 0xF99EE5 and 0xF99F20 (`call`, both in
;          Link_ServiceTask) and 0xFC877D, 0xFC87E5, 0xFC8886 (in this block).
;          `notes/prom_c_xrefs.py 0xFC898F --no-window`.
; Inputs:  (XSP+4) = a flash address, masked to its 64 KiB sector at 0xFC8992.
;          No stack frame.
; Outputs: WA = 0 if every long inspected is 0xFFFFFFFF; WA = 0xFFFF as soon as
;          one is not.  Callers spin while it returns 0xFFFF, i.e. until the
;          erase has completed.
; Evidence: `ld XWA,0xFFFFFFFF` (0xFC899B) and `cp XWA,(XIY+)` (0xFC89A0) compare
;          32 bits at a time.  The count is where it gets interesting:
;          `ld BC,0x4000` at 0xFC8998 -- but the loop ends with `djnz B` at
;          0xFC89A5, prefix byte 0xCA, which is the 8-BIT register B, the HIGH
;          byte of BC.  B is therefore 0x40 = 64, and 64 x 4 bytes = 256.
;          ★ Its two siblings in this block use `djnz BC`, prefix byte 0xD9, and
;          do cover their full counts -- so the difference is one byte of encoding
;          and not a difference in intent that can be read off the source.
;          The prefix -> register mapping is MAME's `oC8()` / `oD8()` and
;          `get_reg8_current()`, mame/src/devices/cpu/tlcs900/900tbl.hxx lines
;          115-150 and 5672-5690.  Both prefix bytes and all three loop counts in
;          this block are asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  ⚠ whether the 8-bit `djnz` is a defect or a deliberately short poll is
;          NOT established.  As "has the erase finished" -- which is the only way
;          any caller uses it -- 256 bytes is a sufficient sample.  As "is this
;          sector blank" it is not.  Recorded, not judged.
; --------------------------------------------------------------------------
Flash_SectorBlankCheck:
	ld	xiy, (xsp+4)                        ; FC898F  ld XIY,(XSP+0x04)
	and	xiy, MASK_BITS16_23                      ; FC8992  and XIY,0x00ff0000
	ldw	bc, 0x4000                         ; FC8998  ld BC,0x4000
	ld	xwa, 0xFFFFFFFF                     ; FC899B  ld XWA,0xffffffff
	cp	xwa, (xiy+)                      ; FC89A0  cp XWA,(XIY+)
	jr nz, Flash_SectorBlankCheck__FC89AB                       ; FC89A3  jr NZ,0xfc89ab
	djnz8	b, -8                            ; FC89A5  djnz B,0xfc89a0
	xor	wa, wa                             ; FC89A8  xor WA,WA
	ret                                    ; FC89AA  ret
Flash_SectorBlankCheck__FC89AB:
	ldw	wa, 0xFFFF                         ; FC89AB  ld WA,0xffff
	ret                                    ; FC89AE  ret
; --------------------------------------------------------------------------
; Flash_ReadSectorToBuffer -- copy one whole 64 KiB sector into the staging
;                     buffer at 0x00010000.
;
; Called from: SIX sites: 0xF99EB5 (`call`, the bit-7 job of Link_ServiceTask),
;          0xFC87A0, 0xFC880D (in this block), and 0xFC38AB, 0xFC3A5D, 0xFC3B72 --
;          three more in the unconverted layer at 0xFC38xx-0xFC3Bxx.
;          `notes/prom_c_xrefs.py 0xFC89AF --no-window`.
; Inputs:  (XSP+4) = a flash address, masked to its 64 KiB sector at 0xFC89B8.
;          No stack frame.
; Outputs: 0x8000 words moved from the sector to 0x00010000 by one `LDIRW`.
; Evidence: `ld XIX,0x00010000` (destination), `and XIY,0x00FF0000` (source),
;          `ld BC,0x8000`, then the two bytes `95 11` at 0xFC89C1.  MAME's
;          `op_LDIRW` writes `*m_p1_reg32` from `*m_p2_reg32` and `op_90()` sets
;          p1 = the register one below the prefix and p2 = the prefix's own --
;          for prefix 0x95 that is XIX and XIY (900tbl.hxx:2514-2530 and
;          5472-5486).  So the direction is buffer <- flash, and 0x8000 words is
;          65,536 bytes, one whole sector.  Asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; --------------------------------------------------------------------------
Flash_ReadSectorToBuffer:
	ld	xiy, (xsp+4)                        ; FC89AF  ld XIY,(XSP+0x04)
	push	xix                               ; FC89B2  push XIX
	ld	xix, 0x10000                        ; FC89B3  ld XIX,0x00010000
	and	xiy, MASK_BITS16_23                      ; FC89B8  and XIY,0x00ff0000
	ldw	bc, 0x8000                         ; FC89BE  ld BC,0x8000
	ldirw                     ; FC89C1  ldirw   [llvm-mc cannot encode this]
	pop	xix                                ; FC89C3  pop XIX
	ret                                    ; FC89C4  ret
