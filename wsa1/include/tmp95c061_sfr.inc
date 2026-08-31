; ==============================================================================
; Toshiba TMP95C061 (TLCS-900/H) internal I/O registers, 0x000000-0x00007F
; ==============================================================================
;
; SOURCE OF THE NAMES: MAME's debugger symbol table for this exact part,
; `tmp95c061_syms[]` in src/devices/cpu/tlcs900/tmp95c061.cpp:1359-1391, cross
; checked against the address map `tmp95c061_device::internal_mem()` at
; :111-173.  No TMP95C061 databook was available in these trees, so the names
; below are MAME's and nothing more.
;
; SOURCE OF THE BIT MEANINGS: mostly nothing.  MAME *names* the memory-controller
; registers but does not decode them -- bcs_w (:1295), bexcs_w (:1300),
; msar01_w (:1313), msar23_w (:1329), drefcr_w (:1343) and dmemcr_w (:1353) are
; bare stores into member variables that no other code reads.  Wherever a comment
; below states a field meaning it says where that meaning comes from, and
; notes/FINDINGS-memory-map.md carries the full argument and its gaps.
;
; ⚠ One MAME footnote worth knowing before trusting a port name: internal_mem()
; line 118 maps 0x12 as port_r<PORT_6> / port_w<PORT_7>, which is a MAME bug
; (0x13 already is P7 both ways).  The symbol table's `0x12 = P6` is the
; authority used here.

; --- I/O ports --------------------------------------------------------------
.equ P1,     0x01
.equ P1CR,   0x04
.equ P2,     0x06
.equ P2FC,   0x09
.equ P5,     0x0D
.equ P5CR,   0x10
.equ P5FC,   0x11
.equ P6,     0x12	; shared with CS0, CS1, CS3/LCAS, RAS, REFOUT (tmp95c061.h:19)
.equ P7,     0x13
.equ P6FC,   0x15
.equ P7CR,   0x16
.equ P7FC,   0x17
.equ P8,     0x18
.equ P9,     0x19
.equ P8CR,   0x1A
.equ P8FC,   0x1B
.equ PA,     0x1E
.equ PB,     0x1F

; --- 8-bit timers 0-3 -------------------------------------------------------
.equ TRUN,   0x20
.equ TREG0,  0x22
.equ TREG1,  0x23
.equ T01MOD, 0x24
.equ TFFCR,  0x25
.equ TREG2,  0x26
.equ TREG3,  0x27
.equ T23MOD, 0x28
.equ TRDC,   0x29
.equ PACR,   0x2C
.equ PAFC,   0x2D
.equ PBCR,   0x2E
.equ PBFC,   0x2F

; --- 16-bit timers 4/5 ------------------------------------------------------
.equ TREG4L, 0x30
.equ TREG4H, 0x31
.equ TREG5L, 0x32
.equ TREG5H, 0x33
.equ CAP1L,  0x34
.equ CAP1H,  0x35
.equ CAP2L,  0x36
.equ CAP2H,  0x37
.equ T4MOD,  0x38
.equ T4FFCR, 0x39
.equ T45CR,  0x3A

; --- Memory controller, chip-select areas 0 and 1 ---------------------------
; MSARn holds A23-A16 of the block start; MAMRn is the window-size mask.
;
; MSAR is PROVEN inside prom_c: `ldio MSAR0,0x10` at 0xFFF038 and, 0x2F bytes
; later, `ld XIX,0x00100000`.
;
; MAMR is not decoded by MAME and no databook is available, so it is settled by
; ELIMINATION instead: scripts/analysis/mamr_reading_elimination.py enumerates
; eight candidate decoders and kills six of them using this machine's own
; firmware.  What survives: **32 KB per MAMR unit** and **higher-numbered chip
; select wins**.  What is still open: whether the base is MSAR<<16 truncated to
; the window or taken literally -- it changes exactly one row, CPU 1's CS0.
; ⚠ Two mutually incompatible readings of this mask have each been "confirmed"
; in the sibling project before, which is why the elimination argues from bytes
; in these ROMs and imports nothing.
.equ MSAR0,  0x3C
.equ MAMR0,  0x3D
.equ MSAR1,  0x3E
.equ MAMR1,  0x3F

; --- 16-bit timers 6/7 ------------------------------------------------------
.equ TREG6L, 0x40
.equ TREG6H, 0x41
.equ TREG7L, 0x42
.equ TREG7H, 0x43
.equ CAP3L,  0x44
.equ CAP3H,  0x45
.equ CAP4L,  0x46
.equ CAP4H,  0x47
.equ T5MOD,  0x48
.equ T5FFCR, 0x49

; --- Pattern generators -----------------------------------------------------
.equ PG0REG, 0x4C
.equ PG1REG, 0x4D
.equ PG01CR, 0x4E

; --- Serial channels 0 and 1 ------------------------------------------------
.equ SC0BUF, 0x50
.equ SC0CR,  0x51
.equ SC0MOD, 0x52
.equ BR0CR,  0x53
.equ SC1BUF, 0x54
.equ SC1CR,  0x55
.equ SC1MOD, 0x56
.equ BR1CR,  0x57
.equ ODE,    0x58

; --- DRAM controller --------------------------------------------------------
; Neither register is decoded anywhere available to this tree.
.equ DREFCR, 0x5A
.equ DMEMCR, 0x5B

; --- Memory controller, chip-select areas 2 and 3 ---------------------------
.equ MSAR2,  0x5C
.equ MAMR2,  0x5D
.equ MSAR3,  0x5E
.equ MAMR3,  0x5F

; --- A/D converter ----------------------------------------------------------
.equ ADREG0L, 0x60
.equ ADREG0H, 0x61
.equ ADREG1L, 0x62
.equ ADREG1H, 0x63
.equ ADREG2L, 0x64
.equ ADREG2H, 0x65
.equ ADREG3L, 0x66
.equ ADREG3H, 0x67

; --- Chip-select / wait control --------------------------------------------
; Bit layout NOT established.  All that is proven from the ROMs: bit 2 of B0CS
; is toggled around a 0x200-byte transfer through 0x7E0000 (prom_a 0xFE509B /
; 0xFE50D5), so the low bits are per-area access timing.  Bit 4 is set on every
; area the firmware enables and matches MAME's reset value B2CS=0x10
; (tmp95c061.cpp:294), so it is plausibly an enable -- unproven.  Bit 3 is
; set on CS2 and CS3 on BOTH CPUs; on this machine those are exactly the two
; 16-bit-wide areas, which is suggestive but not a decode.
.equ B0CS,   0x68
.equ B1CS,   0x69
.equ B2CS,   0x6A
.equ B3CS,   0x6B
.equ BEXCS,  0x6C

.equ ADMOD,  0x6D
.equ WDMOD,  0x6E
.equ WDCR,   0x6F

; --- Interrupt enable / level registers ------------------------------------
.equ INTE0AD, 0x70
.equ INTE45,  0x71
.equ INTE67,  0x72
.equ INTET10, 0x73
.equ INTET32, 0x74
.equ INTET54, 0x75
.equ INTET76, 0x76
.equ INTES0,  0x77
.equ INTES1,  0x78
.equ INTETC01,0x79
.equ INTETC23,0x7A
.equ IIMC,    0x7B

; --- Micro-DMA start vectors -----------------------------------------------
; tlcs900_process_hdma() computes the triggering interrupt as
; (DMAnV & 0x1f) << 2 (tmp95c061.cpp:353), so the value stored here is an
; interrupt vector offset divided by four.
.equ DMA0V,  0x7C
.equ DMA1V,  0x7D
.equ DMA2V,  0x7E
.equ DMA3V,  0x7F

; ==============================================================================
; Register-address bytes used by the (R+) post-increment memory forms
; ==============================================================================
; In the F5-prefixed "(R+)" addressing the base register is named by a register
; address byte whose low two bits select the post-increment step: 0 = +1,
; 1 = +2, 2 = +4.  MAME's disassembler prints all three as "(XIX+)", so the step
; is only visible in the byte.  Verified by feeding 0xF5 <byte> 0x60 to unidasm
; for every base: E0=XWA E4=XBC E8=XDE EC=XHL F0/F2=XIX F4/F6=XIY F8=XIZ FC=XSP.
.equ MEM_XIX_PI2, 0xF1	; (XIX+), post-increment by 2 -- used with a 16-bit store
.equ MEM_XIX_PI4, 0xF2	; (XIX+), post-increment by 4 -- used with a 32-bit store
