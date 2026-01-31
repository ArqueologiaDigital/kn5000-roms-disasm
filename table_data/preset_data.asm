; ===========================================================================
; Preset Data for KN5000 Table Data ROM
; ===========================================================================
;
; This file defines the preset/parameter data that gets LZSS-compressed
; and included in the table_data ROM at label Compressed_Preset_Data_LZSS.
;
; Total size: 32,910 bytes (0x808E)
; After LZSS compression: 27,953 bytes
;
; Structure:
;   0x0000-0x00AF: Header/configuration (176 bytes, mostly zeros)
;   0x00B0-0x808D: Preset parameter data (32,734 bytes)
;
; Data characteristics:
;   - Record markers: "00 03" appears to start records (24 occurrences)
;   - Flag byte 0x80: Indicates "value set" (value in next byte)
;   - Most parameter values are in MIDI range (0-127)
;   - Variable-length records
;
; Build workflow:
;   make rebuild-preset-data
;     1. Assemble this file -> preset_data.bin
;     2. Compress with LZSS -> preset_data_compressed.bin
;     3. Include compressed data in table_data ROM
;
; ===========================================================================

    cpu 96c141          ; Use TLCS-900 for data definitions
    org 0

; ===========================================================================
; HEADER SECTION (0x0000 - 0x00AF)
; ===========================================================================
; 176 bytes, mostly zeros with sparse configuration values.
; Non-zero bytes at specific offsets suggest a fixed structure.
;
; Known non-zero positions:
;   0x18-0x1B: 01 2E 00 20
;   0x2E:      FF
;   0x45:      20
;   0x57-0x5A: 01 2E 00 20
;   0x61:      12
;   0x94-0x9E: 00 03 01 00 00 01 2E 01 2E 00 20
;   0xA4-0xA5: 01 2E
; ---------------------------------------------------------------------------

Preset_Header:
    ; Offset 0x00-0x17: All zeros (24 bytes)
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x18-0x1F: Configuration block 1
    db 001h, 02Eh, 000h, 020h      ; 0x18: possibly version/ID
    db 000h, 000h, 000h, 000h      ; 0x1C: padding

    ; Offset 0x20-0x2F
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h  ; 0x2E = 0xFF marker

    ; Offset 0x30-0x3F: All zeros
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x40-0x4F
    db 000h, 000h, 000h, 000h, 000h, 020h, 000h, 000h  ; 0x45 = 0x20
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x50-0x5F
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h  ; 0x57 = 0x01
    db 02Eh, 000h, 020h, 000h, 000h, 000h, 000h, 000h  ; 0x58-0x5A: 2E 00 20

    ; Offset 0x60-0x6F
    db 000h, 012h, 000h, 000h, 000h, 000h, 000h, 000h  ; 0x61 = 0x12
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x70-0x7F: All zeros
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x80-0x8F: All zeros
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x90-0x9F: Record marker block
    db 000h, 000h, 000h, 000h, 000h, 003h, 001h, 000h  ; 0x94-0x97: 00 03 01 00 (record marker)
    db 000h, 001h, 02Eh, 001h, 02Eh, 000h, 020h, 000h  ; 0x98-0x9F

    ; Offset 0xA0-0xAF
    db 000h, 000h, 000h, 000h, 001h, 02Eh, 000h, 000h  ; 0xA4-0xA5: 01 2E
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

Preset_Header_End:

; Verify header size
    if (Preset_Header_End - Preset_Header) != 176
        error "Header size mismatch! Expected 176 bytes."
    endif

; ===========================================================================
; PARAMETER DATA SECTION (0x00B0 - 0x808D)
; ===========================================================================
; Variable-length preset parameter records.
;
; Record format (tentative):
;   - Records often start with "00 03" marker
;   - Parameters use "00 XX" for value XX, or "80 XX" for flagged value XX
;   - "18 XX" appears to be a parameter type indicator
;   - "64 03 00 7F 20 00 70 80" is a common sequence
;
; First record at 0xB0 (parameters 0x00-0xFF range):
;   00 03 - record marker
;   00 48 - parameter: value 0x48 (72)
;   00 82 - parameter: value 0x82 (130, or 0x02 with flag?)
;   00 14 - parameter: value 0x14 (20)
;   ... etc.
; ---------------------------------------------------------------------------

Preset_Parameters:
    ; TODO: As structure is reverse-engineered, replace with documented
    ; parameter definitions. For now, include binary for byte-matching.
    binclude "includes/preset_data_uncompressed.bin", 0B0h, 32734

Preset_Parameters_End:

; ===========================================================================
; SIZE VERIFICATION
; ===========================================================================

Preset_Data_End:

    ; Verify total size matches expected
    if (Preset_Data_End - Preset_Header) != 32910
        error "Preset data size mismatch! Expected 32910 bytes."
    endif

; ===========================================================================
; END OF FILE
; ===========================================================================
