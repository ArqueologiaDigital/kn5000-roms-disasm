; =============================================================================
; sfr_tmp94c241.asm - TMP94C241 Special Function Register Definitions
; =============================================================================
; This file contains SFR address definitions for the Toshiba TMP94C241
; microcontroller used in the Technics KN5000 keyboard.
;
; These definitions are shared between maincpu and table_data ROMs.
; =============================================================================

; -----------------------------------------------------------------------------
; I/O Ports (P0-PH, PZ)
; Each port has: Data register, Control register (CR), Function register (FC)
; -----------------------------------------------------------------------------
.equ P0, 0x0
.equ P0CR, 0x2
.equ P0FC, 0x3
.equ P1, 0x4
.equ P1CR, 0x6
.equ P1FC, 0x7
.equ P2, 0x8
.equ P2CR, 0xa
.equ P2FC, 0xb
.equ P3, 0xc
.equ P3CR, 0xe
.equ P3FC, 0xf
.equ P4, 0x10
.equ P4CR, 0x12
.equ P4FC, 0x13
.equ P5, 0x14
.equ P5CR, 0x16
.equ P5FC, 0x17
.equ P6, 0x18
.equ P6CR, 0x1a
.equ P6FC, 0x1b
.equ P7, 0x1c
.equ P7CR, 0x1e
.equ P7FC, 0x1f
.equ P8, 0x20
.equ P8CR, 0x22
.equ P8FC, 0x23
.equ PA, 0x28
.equ PAFC, 0x2b
.equ PB, 0x2c
.equ PBFC, 0x2f
.equ PC, 0x30
.equ PCCR, 0x32
.equ PCFC, 0x33
.equ PD, 0x34
.equ PDCR, 0x36
.equ PDFC, 0x37
.equ PE, 0x38
.equ PECR, 0x3a
.equ PEFC, 0x3b
.equ PF, 0x3c
.equ PFCR, 0x3e
.equ PFFC, 0x3f
.equ PG, 0x40
.equ PH, 0x44
.equ PHCR, 0x46
.equ PHFC, 0x47
.equ PZ, 0x68
.equ PZCR, 0x6a

; -----------------------------------------------------------------------------
; 8-bit Timers (T0-T3)
; -----------------------------------------------------------------------------
.equ T8RUN, 0x80	; 8-bit Timer Run register
.equ TRDC, 0x81	; Timer RD Control
.equ T02FFCR, 0x82	; Timer 0/2 Flip-Flop Control
.equ T01MOD, 0x84	; Timer 0/1 Mode
.equ T23MOD, 0x85	; Timer 2/3 Mode
.equ TREG0, 0x88	; Timer 0 Register
.equ TREG1, 0x89	; Timer 1 Register
.equ TREG2, 0x8a	; Timer 2 Register
.equ TREG3, 0x8b	; Timer 3 Register

; -----------------------------------------------------------------------------
; 16-bit Timers (T4-TA)
; -----------------------------------------------------------------------------
.equ TREG4L, 0x90
.equ TREG4H, 0x91
.equ TREG5L, 0x92
.equ TREG5H, 0x93
.equ CAP4L, 0x94
.equ CAP4H, 0x95
.equ CAP5L, 0x96
.equ CAP5H, 0x97
.equ T4MOD, 0x98
.equ T4FFCR, 0x99
.equ T16RUN, 0x9e	; 16-bit Timer Run
.equ T16CR, 0x9f	; 16-bit Timer Control

.equ TREG6L, 0xa0
.equ TREG6H, 0xa1
.equ TREG7L, 0xa2
.equ TREG7H, 0xa3
.equ CAP6L, 0xa4
.equ CAP6H, 0xa5
.equ CAP7L, 0xa6
.equ CAP7H, 0xa7
.equ T6MOD, 0xa8
.equ T6FFCR, 0xa9

.equ TREG8L, 0xb0
.equ TREG8H, 0xb1
.equ TREG9L, 0xb2
.equ TREG9H, 0xb3
.equ CAP8L, 0xb4
.equ CAP8H, 0xb5
.equ CAP9L, 0xb6
.equ CAP9H, 0xb7
.equ T8MOD, 0xb8
.equ T8FFCR, 0xb9

.equ TREGAL, 0xc0
.equ TREGAH, 0xc1
.equ TREGBL, 0xc2
.equ TREGBH, 0xc3
.equ CAPAL, 0xc4
.equ CAPAH, 0xc5
.equ CAPBL, 0xc6
.equ CAPBH, 0xc7
.equ TAMOD, 0xc8
.equ TAFFCR, 0xc9

; -----------------------------------------------------------------------------
; Serial Channels (SC0, SC1)
; -----------------------------------------------------------------------------
.equ SC0BUF, 0xd0	; Serial Channel 0 Buffer
.equ SC0CR, 0xd1	; Serial Channel 0 Control
.equ SC0MOD, 0xd2	; Serial Channel 0 Mode
.equ BR0CR, 0xd3	; Baud Rate 0 Control
.equ SC1BUF, 0xd4	; Serial Channel 1 Buffer
.equ SC1CR, 0xd5	; Serial Channel 1 Control
.equ SC1MOD, 0xd6	; Serial Channel 1 Mode
.equ BR1CR, 0xd7	; Baud Rate 1 Control

; -----------------------------------------------------------------------------
; Interrupt Control
; -----------------------------------------------------------------------------
.equ INTE45, 0xe0
.equ INTE67, 0xe1
.equ INTE89, 0xe2
.equ INTEAB, 0xe3
.equ INTET01, 0xe4
.equ INTET23, 0xe5
.equ INTET45, 0xe6
.equ INTET67, 0xe7
.equ INTET89, 0xe8
.equ INTETAB, 0xe9
.equ INTES0, 0xea
.equ INTES1, 0xeb
.equ INTETC01, 0xec
.equ INTETC23, 0xed
.equ INTETC45, 0xee
.equ INTETC67, 0xef
.equ INTE0AD, 0xf0
.equ IIMC, 0xf6	; Interrupt I/O Mode Control
.equ INTNMWDT, 0xf7	; NMI/Watchdog Timer
.equ INTCLR, 0xf8	; Interrupt Clear

; -----------------------------------------------------------------------------
; DMA Controller
; -----------------------------------------------------------------------------
.equ DMA0V, 0x100
.equ DMA1V, 0x101
.equ DMA2V, 0x102
.equ DMA3V, 0x103
.equ DMA4V, 0x104
.equ DMA5V, 0x105
.equ DMA6V, 0x106
.equ DMA7V, 0x107
.equ DMAB, 0x108
.equ DMAR, 0x109

; -----------------------------------------------------------------------------
; System Control
; -----------------------------------------------------------------------------
.equ CLKMOD, 0x10a	; Clock Mode
.equ WDMOD, 0x110	; Watchdog Mode
.equ WDCR, 0x111	; Watchdog Control

; -----------------------------------------------------------------------------
; A/D Converter
; -----------------------------------------------------------------------------
.equ ADREG04L, 0x120
.equ ADREG04H, 0x121
.equ ADREG15L, 0x122
.equ ADREG15H, 0x123
.equ ADREG26L, 0x124
.equ ADREG26H, 0x125
.equ ADREG37L, 0x126
.equ ADREG37H, 0x127
.equ ADMOD1, 0x128
.equ ADMOD2, 0x129

; -----------------------------------------------------------------------------
; D/A Converter
; -----------------------------------------------------------------------------
.equ DAREG0, 0x130
.equ DAREG1, 0x131
.equ DADRV, 0x132

; -----------------------------------------------------------------------------
; Memory Controller - Block Chip Select
; -----------------------------------------------------------------------------
.equ B0CSL, 0x140
.equ B0CSH, 0x141
.equ MAMR0, 0x142	; Address Mask Register 0
.equ MSAR0, 0x143	; Start Address Register 0
.equ B1CSL, 0x144
.equ B1CSH, 0x145
.equ MAMR1, 0x146
.equ MSAR1, 0x147
.equ B2CSL, 0x148
.equ B2CSH, 0x149
.equ MAMR2, 0x14a
.equ MSAR2, 0x14b
.equ B3CSL, 0x14c
.equ B3CSH, 0x14d
.equ MAMR3, 0x14e
.equ MSAR3, 0x14f
.equ B4CSL, 0x150
.equ B4CSH, 0x151
.equ MAMR4, 0x152
.equ MSAR4, 0x153
.equ B5CSL, 0x154
.equ B5CSH, 0x155
.equ MAMR5, 0x156
.equ MSAR5, 0x157

; -----------------------------------------------------------------------------
; DRAM Controller
; -----------------------------------------------------------------------------
.equ DRAM0CRL, 0x160
.equ DRAM0CRH, 0x161
.equ DRAM1CRL, 0x162
.equ DRAM1CRH, 0x163
.equ DRAM0REF, 0x164
.equ DRAM1REF, 0x165
.equ PMEMCR, 0x166	; Page ROM Control
