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
; RUNTIME DESTINATION:
; ====================
; During boot, the Main CPU decompresses this data to RAM at 0x50000,
; then transfers it to the Sub CPU:
;
;   Offset 0x000-0x0FF (256 bytes)  -> Main CPU RAM 0x0404 (just word at 0x100)
;   Offset 0x100-0x808D (32,654 bytes) -> Sub CPU address 0xF000+
;
; The Sub CPU ROM (kn5000_subprogram_v142) contains DEFAULT values at 0xF000.
; This preset data OVERWRITES those defaults during boot, allowing factory
; presets to configure the audio engine parameters.
;
; SUB CPU 0xF000 AREA PURPOSE:
; ============================
; The Sub CPU uses 0xF000+ for audio engine configuration:
;   - Voice configuration parameters
;   - Envelope rates and settings
;   - Polyphony limits
;   - Pitch/tuning tables
;   - Runtime counters (0xF012, 0xF014, 0xF016, etc.)
;
; PARAMETER ENCODING:
; ===================
; Values use "flagged parameter" format:
;   - 0x80 XX: Parameter with value XX is SET (modified from default)
;   - 0x00 XX: Parameter with value XX (no flag, or default indicator)
;
; Most parameter values are in MIDI range (0-127), suggesting this data
; configures voice/sound parameters like volume, pan, envelope times, etc.
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
; MAIN CPU HEADER SECTION (0x0000 - 0x00FF)
; ===========================================================================
; This section stays on the Main CPU. Only the word at offset 0x100 is
; explicitly copied to RAM 0x0404 before the bulk transfer.
;
; Structure: Mostly zeros with sparse configuration values.
; Non-zero positions suggest a fixed initialization structure.
;
; Key values observed:
;   0x18-0x1B: 01 2E 00 20  (version/format ID?)
;   0x2E:      FF           (marker)
;   0x45:      20
;   0x57-0x5A: 01 2E 00 20
;   0x61:      12
;   0x94-0x97: 00 03 01 00  (record marker)
;   0x98-0x9E: 01 2E 01 2E 00 20
;   0xA4-0xA5: 01 2E
; ---------------------------------------------------------------------------

MainCPU_Header:
    ; Offset 0x00-0x17: All zeros (24 bytes)
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x18-0x1F: Configuration block
    db 001h, 02Eh, 000h, 020h      ; 0x18: Format/version identifier?
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
    db 02Eh, 000h, 020h, 000h, 000h, 000h, 000h, 000h  ; 0x58-0x5A

    ; Offset 0x60-0x6F
    db 000h, 012h, 000h, 000h, 000h, 000h, 000h, 000h  ; 0x61 = 0x12
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x70-0x7F: All zeros
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x80-0x8F: All zeros
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    ; Offset 0x90-0x9F: Record marker area
    db 000h, 000h, 000h, 000h, 000h, 003h, 001h, 000h  ; 0x94: 00 03 01 00
    db 000h, 001h, 02Eh, 001h, 02Eh, 000h, 020h, 000h  ; 0x98-0x9F

    ; Offset 0xA0-0xAF
    db 000h, 000h, 000h, 000h, 001h, 02Eh, 000h, 000h  ; 0xA4-0xA5: 01 2E
    db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

MainCPU_Header_End:

; Verify header size
    if (MainCPU_Header_End - MainCPU_Header) != 176
        error "Header size mismatch! Expected 176 bytes."
    endif

; ===========================================================================
; SUB CPU AUDIO PARAMETERS (0x00B0 - 0x808D)
; ===========================================================================
; This section gets transferred to Sub CPU address 0xF000+ during boot.
; It overwrites the default audio configuration in the Sub CPU ROM.
;
; Destination: Sub CPU 0xF000 (after skipping first 0x100 bytes)
; Transfer size: 32,654 bytes (offset 0x100 to end)
;
; The Sub CPU 0xF000 area contains:
;   0xF000-0xF010: System configuration (counters, flags)
;   0xF010-0xF100: Voice parameters (attack, decay, sustain, release)
;   0xF100-0xF420: Pitch tables, envelope lookup tables
;   0xF420+:       Serial buffers, command dispatch tables
;
; Observed patterns:
;   "00 03" - Record marker (24 occurrences)
;   "80 XX" - Flagged parameter value (XX is the actual value, 0x80 = "set")
;   "18 XX" - Parameter type indicator (XX specifies parameter type)
;   "64 03 00 7F 20 00 70 80" - Common sequence in voice configuration
;
; Most values are MIDI-range (0-127), consistent with audio parameters:
;   - Volume (0x00-0x7F)
;   - Pan (0x00-0x7F, center = 0x40)
;   - Envelope times
;   - Filter cutoff/resonance
;   - Effect send levels
; ---------------------------------------------------------------------------

SubCPU_Audio_Parameters:
    ; TODO: As structure is reverse-engineered, replace with documented
    ; parameter definitions. For now, include binary for byte-matching.
    ;
    ; The first data at offset 0xB0 contains configuration:
    ;   00 03 - record marker
    ;   00 48 - parameter (value 0x48 = 72)
    ;   00 82 - parameter (value 0x82, or 0x02 with high bit?)
    ;   00 14 - parameter (value 0x14 = 20)
    ;   ... continues with more parameters
    ;
    ; From offset 0x100, the "80 XX" flagged format dominates:
    ;   80 32 - flagged parameter, value 0x32 (50)
    ;   80 2E - flagged parameter, value 0x2E (46)
    ;   80 20 - flagged parameter, value 0x20 (32)
    ;   etc.
    binclude "includes/preset_data_uncompressed.bin", 0B0h, 32734

SubCPU_Audio_Parameters_End:

; ===========================================================================
; SIZE VERIFICATION
; ===========================================================================

Preset_Data_End:

    ; Verify total size matches expected
    if (Preset_Data_End - MainCPU_Header) != 32910
        error "Preset data size mismatch! Expected 32910 bytes."
    endif

; ===========================================================================
; CROSS-REFERENCE: Sub CPU Labels at 0xF000
; ===========================================================================
; The following labels in subcpu/kn5000_subprogram_v142.asm contain the
; DEFAULT values that this preset data overwrites:
;
;   LABEL_00F000     - System configuration defaults
;   LABEL_00F420     - Runtime buffer initialization
;   LABEL_00F428     - Zero-initialized counter
;   LABEL_00F42C     - Floating-point constant?
;   LABEL_00F434     - Serial TX buffer structure
;   LABEL_00F44A     - Serial RX buffer structure
;   Voice_PolyphonyLimits_Table (0xF48C)
;   Voice_IndexMapping_Table (0xF4AC)
;   Voice_CommandIndexTable (0xF4EC)
;   Voice_AttackDecay_Widths (0xF507)
;   Voice_EnvelopeRate_Lookup (0xF519)
;   Voice_Pitch_Table_High (0xF6F3)
;
; NOTE: Not all of Sub CPU 0xF000+ gets overwritten - only the first
; ~32KB is transferred. The voice tables at higher addresses remain
; as defined in the Sub CPU ROM.
;
; ===========================================================================
; END OF FILE
; ===========================================================================
