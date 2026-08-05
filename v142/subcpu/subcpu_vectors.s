	.text

	.include "shared/sfr_tmp94c241.s"

.equ INTER_CPU_COMM_LATCHES, 0x120000	; This is a pair of 8-bit latches used for
                                    ; bidirectional communication between
                                    ; maincpu and subcpu

; Shared with boot ROM (persists after payload load)
	; (EQU→inline label) PAYLOAD_LOADED_FLAG = 0x4FE

; Payload-specific state variables
	; (EQU→inline label) SERIAL_1_VAR_1034 = 0x1034
	; (EQU→inline label) SERIAL_1_VAR_1038 = 0x1038
	; (EQU→inline label) DMA_XFER_STATE = 0x10E8
	; (EQU→inline label) CMD_PROCESSING_STATE = 0x10EA
	; (EQU→inline label) BYTE_FROM_MAINCPU_LATCH = 0x10EC

	.org 0x400 - 0x400, 0xFF

; NAME UNCHANGED (already a real name) -- documentation only.
; This slot is NOT an interrupt entry. The TMP94C241 hardware vector table lives in the boot
; mask ROM at 0xFFFF00 and its entry 0 points at 0xFFFEE0 (RESET_HANDLER in ROM), never here.
; 0x000400 is the PAYLOAD ENTRY POINT: the boot ROM does `call PAYLOAD_ENTRY` (= call 0x400,
; kn5000_subcpu_boot.s, .equ PAYLOAD_ENTRY, 0x400) once the payload has been loaded into DRAM.
; Body is `jp RESET` (0x01F924) + a never-reached `ret`, encoded 1b 24 f9 01 0e.
; Verified: boot's own trampoline image (VECTOR_TRAMPOLINES, 0xFF8F6C) is copied to 0x400 at
; reset and is then OVERWRITTEN by the payload image, which ships its own 45 trampolines here.
; --- 0x000400-0x0004E0  INT_HANDLER_00..INT_HANDLER_2C -- 45 interrupt trampolines, 5 bytes each
; Layout: `jp <24-bit target>` (4 bytes, opcode 0x1B) + `ret` (0x0E) = 5 bytes; 45*5 = 225 = 0xE1.
; These 225 bytes live in DRAM, so they are WRITABLE at runtime (a wild store can repoint any
; interrupt). They are the payload's copy; the boot ROM has an identical-shaped table at 0xFF8F6C.
;
; ★ SLOT NUMBER != HARDWARE VECTOR NUMBER. Reconstructed by reading the hardware vector table
;   VECTOR_TABLE at 0xFFFF00 in subcpu/boot/kn5000_subcpu_boot.s (45 x .long):
;     hw vector 0        -> 0xFFFEE0 (boot ROM)   -- slot 0 is NOT reachable from hardware
;     hw vectors 1..7    -> slots 1..7   (0x405..0x423)
;     hw vector 8        -> slot 44      (0x4DC)  <-- the one out-of-order entry
;     hw vectors 9..44   -> slots 8..43  (0x428..0x4D7), i.e. slot = vector - 1
;
; ★ TMP94C241F vector assignment, anchored on four handlers whose identity is proved by the
;   payload's own code and cross-checked against the boot ROM's trampolines:
;     vec  0      RESET                         -> ROM 0xFFFEE0
;     vec  1..7   SWI1..SWI7                    -> slots 1..7,  all EMPTY_HANDLER (reti)
;     vec  8      NMI                           -> slot 44 = INT_HANDLER_2C -> MUTE_AND_HALT
;     vec  9      INTWD (watchdog)              -> slot  8 = INT_HANDLER_08 -> EMPTY_HANDLER_WITH_RESET
;     vec 10      INT0 (main->sub latch)        -> slot  9 = INT_HANDLER_09 -> INT0_HANDLER (0x020E86)
;     vec 11..19  remaining external INTs       -> slots 10..18, all EMPTY_HANDLER
;     vec 20..31  INTT0..INTTB (12 timers)      -> slots 19..30
;                   vec 21 INTT1 -> slot 20 = INT_HANDLER_14 -> Timer_AudioTick_Handler (0x01FB41)
;                   vec 23 INTT3 -> slot 22 = INT_HANDLER_16 -> INT16_TaskSwitch_Handler (0x01FDC8)
;     vec 32/33   INTRX0 / INTTX0               -> slots 31/32, EMPTY_HANDLER (SC0 unused)
;     vec 34      INTRX1                        -> slot 33 = INT_HANDLER_21 -> INTRX1_HANDLER (0x01F736)
;     vec 35      INTTX1                        -> slot 34 = INT_HANDLER_22 -> INTTX1_HANDLER (0x01F765)
;     vec 36      INTAD                         -> slot 35, EMPTY_HANDLER
;     vec 37..44  INTTC0..INTTC7 (micro-DMA)    -> slots 36..43
;                   vec 37 INTTC0 -> slot 36 = INT_HANDLER_24 -> MICRODMA_CH0_HANDLER (0x020F1F)
;                   vec 39 INTTC2 -> slot 38 = INT_HANDLER_26 -> MICRODMA_CH2_HANDLER (0x020F01)
;   Counts corroborate: 6 INTETxx registers = 12 timers; INTES0/INTES1 = 2 serial channels;
;   4 INTETCxx registers and DMA0V..DMA7V = 8 micro-DMA channels; total = 45 vectors exactly.
;   Timer identity: RESET (0x01F924) leaves INTET01 (SFR 0xE4) as (x & 0x8F) | 0x30, i.e. it
;   enables INTT1 at level 3 and nothing else in that pair -- so the audio tick is INTT1.
;
; Only SEVEN of the 45 slots do anything; 38 are `jp EMPTY_HANDLER` (a bare reti at 0x01FBBC).
INT_HANDLER_00:	; 0400
	jp RESET
	ret

INT_HANDLER_01:	; 0405
	jp EMPTY_HANDLER
	ret

INT_HANDLER_02:	; 040A
	jp EMPTY_HANDLER
	ret

INT_HANDLER_03:	; 040F
	jp EMPTY_HANDLER
	ret

INT_HANDLER_04:	; 0414
	jp EMPTY_HANDLER
	ret

INT_HANDLER_05:	; 0419
	jp EMPTY_HANDLER
	ret

INT_HANDLER_06:	; 041E
	jp EMPTY_HANDLER
	ret

INT_HANDLER_07:	; 0423
	jp EMPTY_HANDLER
	ret

INT_HANDLER_08:	; 0428: watchdog
	jp EMPTY_HANDLER_WITH_RESET
	ret

INT_HANDLER_09:	; 042D: Interrupt #0: Receive data from main-cpu via 8bit latch
	jp INT0_HANDLER
	ret

INT_HANDLER_0A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0B:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0C:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0D:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0E:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0F:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_10:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_11:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_12:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_13:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_14:
	jp Timer_AudioTick_Handler
	ret

INT_HANDLER_15:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_16:
	jp INT16_TaskSwitch_Handler
	ret

INT_HANDLER_17:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_18:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_19:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1B:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1C:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1D:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1E:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1F:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_20:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_21:
	jp INTRX1_HANDLER
	ret

INT_HANDLER_22:
	jp INTTX1_HANDLER
	ret

INT_HANDLER_23:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_24:
	jp MICRODMA_CH0_HANDLER	; Channel #0 completion
	ret

INT_HANDLER_25:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_26:
	jp MICRODMA_CH2_HANDLER	; Channel #2 completion (STOP AND CLEAR TIMER #2)
	ret

INT_HANDLER_27:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_28:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_29:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_2A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_2B:
	jp EMPTY_HANDLER
	ret

; NAME UNCHANGED. Hardware vector 8 = NMI (not "slot 44"); target MUTE_AND_HALT (0x01FBF4),
; which does `res 0,(0x38)` (assert MUTE on port 3 bit 0) then `halt`, with no loop and no reti.
; On this machine NMI is the power-down / power-fail detect. See FINDINGS below: this is the
; only path in the whole payload that stops the main loop while leaving the interrupt-driven
; main->sub receive path (INT0 + micro-DMA ch0) fully functional.
INT_HANDLER_2C:
	jp MUTE_AND_HALT
	ret

