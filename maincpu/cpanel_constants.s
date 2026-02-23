; =============================================================================
; cpanel_constants.asm - Control Panel Constants for Main CPU
; =============================================================================
; This file contains all control panel related constants, including:
;   - State machine and protocol variables
;   - RX/TX buffer addresses
;   - Button state arrays with detailed bit mappings
;   - LED row/pattern output addresses with mappings
;   - Event queue addresses
;
; The KN5000 has two control panel MCUs (left and right panels) that
; communicate with the main CPU via serial protocol.
; =============================================================================

; =============================================================================
; Control Panel State Machine Variables (RAM at 0x8Dxxh)
; =============================================================================

.equ CPANEL_STATE_MACHINE_INDEX, 0x8D8A	; (byte)
.equ CPANEL_PACKET_BYTE_COUNT, 0x8D8B	; (byte) // range 0-17
				   ;          (0, 1 or 2 + nibble)
.equ CPANEL_TX_RX_FLAGS, 0x8D8C	; (8 bits)
			;   8D8Dh: unused byte?
.equ PFCR_VALUE, 0x8D8E	; (byte)
.equ PFFC_VALUE, 0x8D8F	; (byte)
			;   8D90h: unused byte?
.equ CPANEL_UNUSED_1, 0x8D91	; (byte) // This one looks pointless...
.equ CPANEL_PROTOCOL_FLAGS, 0x8D92	; (8 bits)
.equ CPANEL_PANEL_DETECT_FLAGS, 0x8D93	; (8 bits)
.equ CPANEL_RX_PACKET_BYTE_1, 0x8D94	; (byte) First byte from incoming panel packets
				   ; (1st Value saved to
				   ;  XIZ + IX(mod 080h) array)
.equ CPANEL_RX_PACKET_BYTE_2, 0x8D95	; (byte) Second byte from incoming panel packets
				   ; (2nd Value saved to
				   ;  XIZ + IX(mod 080h) array)
.equ CPANEL_LAST_EVENT_VALUE, 0x8D96	; (byte) Last processed event value (stored to event queue)
.equ CPANEL_COUNTER_DOWN_FROM_200, 0x8D97	; (byte) counts down
				   ; from 0c8h (=200) to zero.
.equ CPANEL_COUNTER_UP_TO_20, 0x8D98	; (byte) counts up to 014h (=20).
			;   8D99h: unused byte?
.equ CPANEL_COUNTER_UP_TO_42, 0x8D9A	; (byte) counts up to 02ah (=42).
.equ TIMESTAMP_FOR_DELAY, 0x8D9B	; (word)

; =============================================================================
; Control Panel RX/TX Buffers (RAM at 0x8Dxxh-0x8Exxh)
; =============================================================================

.equ CPANEL_RX_READ_PTR, 0x8D9D	; (word) NOTE: Used as index IY for
				   ;         CPANEL_RX_RING_BUFFER[IY MOD 05Ch]
				   ; in code near CPanel_RX_ProcessWithFlag and CPanel_RX_SyncPacket
.equ CPANEL_RX_WRITE_PTR, 0x8D9F	; (word)
.equ CPANEL_RX_RING_BUFFER, 0x8DA1	; 05ch (=92) bytes
.equ CPANEL_LED_READ_PTR, 0x8DFD	; (word)
.equ CPANEL_LED_WRITE_PTR, 0x8DFF	; (word)
			;   8E00h: unused byte?
.equ CPANEL_LED_TX_BUFFER, 0x8E01	; 03ch (=60) bytes
	;		... ? 8E3Dh

; =============================================================================
; Control Panel Button State Arrays (RAM at 0x8E4Ah)
; =============================================================================
; Two arrays of 11 bytes each (segments 0-10), one per panel.
; Each byte represents 8 buttons (1=pressed), active high.
;
; RIGHT PANEL (CPR) - Offset +0 to +10:
;   SEG0: bit5=TRANSPOSE-, bit6=TRANSPOSE+
;   SEG1: bit0=ORGAN&ACCORDION, bit1=ORCHESTRAL PAD, bit2=SYNTH, bit3=BASS,
;         bit4=DIGITAL DRAWBAR, bit5=ACCORDION REGISTER, bit6=GM SPECIAL, bit7=DRUM KITS
;   SEG2: bit0=PIANO, bit1=GUITAR, bit2=STRINGS&VOCAL, bit3=BRASS,
;         bit4=FLUTE, bit5=SAX&REED, bit6=MALLET&ORCH PERC, bit7=WORLD PERC
;   SEG3: bit0=SUSTAIN, bit1=DIGITAL EFFECT, bit2=DSP EFFECT, bit3=DIGITAL REVERB,
;         bit4=ACOUSTIC ILLUSION
;   SEG4: bit0=PART:LEFT, bit1=PART:RIGHT2, bit2=PART:RIGHT1, bit3=ENTERTAINER,
;         bit4=CONDUCTOR:LEFT, bit5=CONDUCTOR:RIGHT2, bit6=CONDUCTOR:RIGHT1, bit7=TECHNI CHORD
;   SEG5: bit3=SEQUENCER:PLAY, bit4=SEQUENCER:EASY REC, bit5=SEQUENCER:MENU
;   SEG6: bit0=PM1, bit1=PM2, bit2=PM3, bit3=PM4, bit4=PM5, bit5=PM6, bit6=PM7, bit7=PM8
;   SEG7: bit0=PM:SET, bit1=PM:NEXT BANK, bit2=PM:BANK VIEW
;   SEG8: bit3=R1/R2 OCTAVE-, bit4=R1/R2 OCTAVE+, bit5=START/STOP, bit6=SYNCHRO&BREAK, bit7=TAP TEMPO
;   SEG9: bit6=MEMORY A, bit7=MEMORY B
;   SEG10: bit2=MENU:SOUND, bit3=MENU:CONTROL, bit4=MENU:MIDI, bit5=MENU:DISK
;
; LEFT PANEL (CPL) - Offset +16 to +26:
;   SEG0: bit0=STANDARD ROCK, bit1=R&ROLL&BLUES, bit2=POP&BALLAD, bit3=FUNK&FUSION,
;         bit4=SOUL&MODERN DANCE, bit5=BIG BAND&SWING, bit6=JAZZ COMBO
;   SEG1: bit0=COMPOSER:MEMORY, bit1=COMPOSER:MENU, bit2=SOUND ARR:SET, bit3=SOUND ARR:ON/OFF,
;         bit4=MUSIC STYLIST, bit5=FADE IN, bit6=FADE OUT
;   SEG2: bit0=FILL IN 1, bit1=FILL IN 2, bit2=INTRO&ENDING 1, bit3=INTRO&ENDING 2,
;         bit6=PAGE DOWN, bit7=PAGE UP
;   SEG3: bit0=DEMO, bit1=MSP BANK, bit2=MSP MENU, bit3=MSP STOP/RECORD
;   SEG4: bit0=VARIATION 1, bit1=VARIATION 2, bit2=VARIATION 3, bit3=VARIATION 4,
;         bit4=MUSIC STYLE ARRANGER, bit5=SPLIT POINT, bit6=AUTO PLAY CHORD
;   SEG5: bit0=MSP1, bit1=MSP2, bit2=MSP3, bit3=MSP4, bit4=MSP5, bit5=MSP6
;   SEG6: bit0=U.S. TRAD, bit1=COUNTRY, bit2=LATIN, bit3=MARCH&WALTZ,
;         bit4=PARTY TIME, bit5=SHOWTIME&TRAD DANCE, bit6=WORLD, bit7=CUSTOM
;   SEG7: bit0=RIGHT 5, bit1=RIGHT 4, bit2=DISPLAY HOLD, bit3=EXIT,
;         bit4=DOWN 7, bit5=UP 7, bit6=DOWN 8, bit7=UP 8
;   SEG8: bit0=RIGHT 3, bit1=RIGHT 2, bit2=RIGHT 1,
;         bit4=DOWN 5, bit5=UP 5, bit6=DOWN 6, bit7=UP 6
;   SEG9: bit0=LEFT 5, bit1=LEFT 4, bit2=LEFT 3,
;         bit4=DOWN 3, bit5=UP 3, bit6=DOWN 4, bit7=UP 4
;   SEG10: bit0=LEFT 2, bit1=LEFT 1, bit2=HELP, bit3=OTHER PARTS/TR,
;          bit4=DOWN 1, bit5=UP 1, bit6=DOWN 2, bit7=UP 2
; =============================================================================
.equ STATE_OF_CPANEL_BUTTONS, 0x8E4A	; NOTE: 8E4Ah=Right / 8E5Ah=Left
	STATE_OF_CPANEL_BUTTONS_RIGHT = STATE_OF_CPANEL_BUTTONS + 0
	STATE_OF_CPANEL_BUTTONS_LEFT = STATE_OF_CPANEL_BUTTONS + 16

; =============================================================================
; Control Panel LED Row/Pattern Output (RAM at 0x8F38h)
; =============================================================================
; LEDs are addressed via 2-byte sequences: [row_select, pattern]
; row_select bits 7-6 select panel (0x00-0x0F=CPR, 0xC0-0xCF=CPL)
;
; RIGHT PANEL (CPR) LED Rows:
;   Row 0x00: bit0=SUSTAIN, bit1=DIGITAL EFFECT, bit2=DSP EFFECT, bit3=DIGITAL REVERB,
;             bit4=ACOUSTIC ILLUSION, bit5=SEQ:PLAY, bit6=SEQ:EASY REC, bit7=SEQ:MENU
;   Row 0x01: bit0=PIANO, bit1=GUITAR, bit2=STRINGS&VOCAL, bit3=BRASS,
;             bit4=FLUTE, bit5=SAX&REED, bit6=MALLET&ORCH PERC, bit7=WORLD PERC
;   Row 0x02: bit0=ORGAN&ACCORDION, bit1=ORCHESTRAL PAD, bit2=SYNTH, bit3=BASS,
;             bit4=DIGITAL DRAWBAR, bit5=ACCORDION REGISTER, bit6=GM SPECIAL, bit7=DRUM KITS
;   Row 0x03: bit0=PM1, bit1=PM2, bit2=PM3, bit3=PM4, bit4=PM5, bit5=PM6, bit6=PM7, bit7=PM8
;   Row 0x04: bit0=PART:LEFT, bit1=PART:RIGHT2, bit2=PART:RIGHT1, bit3=ENTERTAINER,
;             bit4=COND:LEFT, bit5=COND:RIGHT2, bit6=COND:RIGHT1, bit7=TECHNI CHORD
;   Row 0x08: bit0=MENU:SOUND, bit1=MENU:CONTROL, bit2=MENU:MIDI, bit3=MENU:DISK
;   Row 0x0A: bit0=MEMORY A, bit1=MEMORY B
;   Row 0x0B: bit0=SYNCHRO&BREAK, bit1=R1/R2 OCTAVE-, bit2=R1/R2 OCTAVE+, bit3=BANK VIEW
;   Row 0x0C: bit0=START/STOP BEAT1, bit1=BEAT2, bit2=BEAT3, bit3=BEAT4
;
; LEFT PANEL (CPL) LED Rows:
;   Row 0xC0: bit0=COMPOSER:MEMORY, bit1=COMPOSER:MENU, bit2=SOUND ARR:SET, bit3=SOUND ARR:ON/OFF,
;             bit4=MUSIC STYLIST, bit5=FADE IN, bit6=FADE OUT, bit7=DISPLAY HOLD
;   Row 0xC1: bit0=U.S. TRAD, bit1=COUNTRY, bit2=LATIN, bit3=MARCH&WALTZ,
;             bit4=PARTY TIME, bit5=SHOWTIME&TRAD DANCE, bit6=WORLD, bit7=CUSTOM
;   Row 0xC2: bit0=STANDARD ROCK, bit1=R&ROLL&BLUES, bit2=POP&BALLAD, bit3=FUNK&FUSION,
;             bit4=SOUL&MODERN DANCE, bit5=BIG BAND&SWING, bit6=JAZZ COMBO, bit7=MSP:MENU
;   Row 0xC3: bit0=VARIATION1, bit1=VARIATION2, bit2=VARIATION3, bit3=VARIATION4,
;             bit4=MUSIC STYLE ARRANGER, bit5=AUTO PLAY CHORD
;   Row 0xC4: bit0=FILL IN 1, bit1=FILL IN 2, bit2=INTRO&ENDING 1, bit3=INTRO&ENDING 2,
;             bit4=SPLIT POINT(L), bit5=SPLIT POINT(C), bit6=SPLIT POINT(R), bit7=TEMPO/PROGRAM
;   Row 0xC8: bit0=OTHER PARTS/TR
; =============================================================================
.equ CPANEL_LEDS__ROW_AND_PATTERN_BYTES, 0x8F38	; (word) 8F38h=row_select 8F39h=pattern

; =============================================================================
; Control Panel Event Queues (RAM at 0x200xxxh)
; =============================================================================
; These are circular buffers for control panel events.

;CPANEL_RX_EVENT_QUEUE	-8:	EQU 000200a5h (word)
;		-6: (unused word)
;		-4:	EQU 000200a9h (word)
;		-2:	EQU 000200abh (word)
.equ CPANEL_RX_EVENT_QUEUE, 0x200ad	; (128 bytes) Not sure yet what is placed here

	; 2012d:	 (unused word ?)
;CPANEL_LED_EVENT_QUEUE  -8:	EQU 0002012fh (word)
;		      -6: (unused word)
;		      -4:	EQU 00020133h (word)
;		      -2:	EQU 00020135h (word)
.equ CPANEL_LED_EVENT_QUEUE, 0x20137	; (128 bytes), Also not sure yet here.

; End of control panel constants
