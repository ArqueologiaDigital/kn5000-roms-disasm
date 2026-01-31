; =============================================================================
; sequencer_reference.asm - Sequencer Function Reference
; =============================================================================
; This file documents all sequencer-related functions in the KN5000 Main CPU.
;
; NOTE: Unlike the FDC or Control Panel code, the sequencer functions are
; NOT in a contiguous block. They are distributed throughout the ROM and
; interleaved with other application code (UI, menus, etc.). This file
; serves as a reference/index only - the actual code remains in the main
; source file.
;
; The KN5000 has a 16-track MIDI sequencer with the following capabilities:
;   - Real-time and step recording
;   - Song playback with tempo control
;   - Track editing (copy, merge, insert, delete, transpose)
;   - Quantization
;   - Punch-in/punch-out recording
;   - SMF (Standard MIDI File) import/export
;
; =============================================================================

; =============================================================================
; SEQUENCER DISPATCH TABLES
; =============================================================================
; These tables dispatch to track-specific handlers.
;
; SQTR_DISPATCH_TABLE_1        ; 0xF20D37 - Line 176478
;   Handler for SqTrAsTtlFunc, 6 cases (XDE 0-5)
;
; SQTR_DISPATCH_TABLE_2        ; 0xF20D8E - Line 176520
;   SqTrAsTtlFunc handler with multiple cases
;   SQTR_DISPATCH_TABLE_2_CASE1  ; 0xF20DC1 - Line 176539
;   SQTR_DISPATCH_TABLE_2_CASE2  ; 0xF20DDA - Line 176553
;   SQTR_DISPATCH_TABLE_2_CASE5  ; 0xF20E08 - Line 176567

; =============================================================================
; SEQUENCER MODE FUNCTIONS
; =============================================================================
; These handle sequencer mode transitions and state management.
;
; SeqModeFunc                  ; Line 232574 - Main sequencer mode handler
; SeqErecModeFunc              ; Line 232598 - Easy record mode
; SeqPlayModeFunc              ; Line 232618 - Playback mode
; SeqRealModeFunc              ; Line 232641 - Real-time record mode
; SeqEditModeFunc              ; Line 232716 - Edit mode
; SeqStepModeFunc              ; Line 178235 - Step record mode

; =============================================================================
; SEQUENCER TITLE/MENU FUNCTIONS
; =============================================================================
; These handle sequencer menu screens and title displays.
;
; SqRealRecTitleFunc           ; Line 232735 - Real-time recording title
; SqPlayTitleFunc              ; Line 232792 - Playback title
; SqQtzTitleFunc               ; Line 232819 - Quantize title
; SqMdelTitleFunc              ; Line 232838 - Measure delete title
; SqMersTitleFunc              ; Line 232857 - Measure erase title
; SqVcngTitleFunc              ; Line 232876 - Velocity change title
; SqTrnsTitleFunc              ; Line 232895 - Transpose title
; SqNcngTitleFunc              ; Line 232899 - Note change title
; SqSoclTitleFunc              ; Line 232903 - Solo clear title
; SqMcpyTitleFunc              ; Line 232916 - Measure copy title
; SqMinsTitleFunc              ; Line 232940 - Measure insert title
; SqTrclTitleFunc              ; Line 232963 - Track clear title
; SqSngcpTitleFunc             ; Line 232982 - Song copy title
; SqTrmgTitleFunc              ; Line 232998 - Track merge title
; SqAdlyTitleFunc              ; Line 233010 - After delay title
; SqPunchTitleFunc             ; Line 233014 - Punch-in title
; SqPunchmTitleFunc            ; Line 233031 - Punch mode title
; SqNoteSelTitleFunc           ; Line 233048 - Note select title
; SqNoteEdtTitleFunc           ; Line 233061 - Note edit title
; SqDrmSelTitleFunc            ; Line 233071 - Drum select title
; SqDrmEdtTitleFunc            ; Line 233085 - Drum edit title
; SqNoteCycpTitleFunc          ; Line 233140 - Note cycle copy title
; SqDrmCycpTitleFunc           ; Line 233150 - Drum cycle copy title
; SqStepTtlFunc                ; Line 178303 - Step record title

; =============================================================================
; SEQUENCER TRACK FUNCTIONS
; =============================================================================
; These handle track selection and track-specific operations.
;
; SqTrAsTtlFunc                ; Line 176503 - Track assign title
; SqTrAsSureFunc               ; Line 176597 - Track assign confirm
; SqTrAsPsTtlFunc              ; Line 176647 - Track assign preset title
; SqTrAsPsSureFunc             ; Line 176691 - Track assign preset confirm
; SqTrAsPsSongFunc             ; Line 194765 - Track assign preset song
; SqTrSelTtlFunc               ; Line 178268 - Track select title
; SqAftSetTtlFunc              ; Line 176435 - After set title
; SqAftSetFunc                 ; Line 194795 - After set handler

; =============================================================================
; SEQUENCER SONG FUNCTIONS
; =============================================================================
; These handle song selection, naming, and memory management.
;
; SeqSongNameFunc              ; Line 178666 - Song name handler
; SeqSongMemoryFunc            ; Line 178822 - Song memory handler
; SeqNameOKFunc                ; Line 195063 - Name OK confirmation
; SeqNamingCheck               ; Line 195076 - Naming validation
; SqSngSelTtlFunc              ; Line 176439 - Song select title
; SqSngNameTtlFunc             ; Line 176463 - Song name title
; SqMdlyPlyTtlFunc             ; Line 176735 - Melody play title
; PsSeqSongNoBoxProc           ; Line 168156 - Song number box proc

; =============================================================================
; SEQUENCER VALUE/EDIT PROCESSORS
; =============================================================================
; These handle value editing in the sequencer UI.
;
; SqplyValProc                 ; Line 198686 - Play value processor
; SqedtValProc                 ; Line 199180 - Edit value processor
; SqedtFixProc                 ; Line 199556 - Edit fix processor
; SqedtVal3Proc                ; Line 200406 - Edit value 3 processor
; SqedtVal2Proc                ; Line 200742 - Edit value 2 processor
; SqplyFunc                    ; Line 203691 - Play function
; SqedtFunc                    ; Line 204001 - Edit function

; =============================================================================
; SEQUENCER LOAD/SAVE FUNCTIONS
; =============================================================================
; These handle sequence file I/O operations.
;
; SeqLoadPre                   ; Line 233864 - Pre-load handler
; SeqLoadPost                  ; Line 233868 - Post-load handler
; SeqSavePre                   ; Line 233943 - Pre-save handler
; SeqSavePost                  ; Line 233958 - Post-save handler

; =============================================================================
; SMF (STANDARD MIDI FILE) FUNCTIONS
; =============================================================================
; These handle SMF import/export operations.
;
; SmfSeqToSongNumFunc          ; Line 324788 - SMF to song number
; SmfSeqFromSongNumFunc        ; Line 324821 - Song number to SMF
; SmfSeqSongNameFunc           ; Line 324854 - SMF song name handler
; FmmSeqSongNameFunc           ; Line 328584 - FMM seq song name

; =============================================================================
; MISCELLANEOUS SEQUENCER FUNCTIONS
; =============================================================================
;
; ExcSeqFunc                   ; Line 294470 - Exclusive sequence function

; =============================================================================
; SUMMARY
; =============================================================================
; Total sequencer functions: 61
;
; Line ranges:
;   168156         - PsSeqSongNoBoxProc (isolated)
;   176435-178822  - Track/song title functions (cluster 1)
;   194765-195076  - Track assign/naming functions (cluster 2)
;   198686-204001  - Value processors and edit functions (cluster 3)
;   232574-233958  - Mode functions, title functions, load/save (cluster 4)
;   294470         - ExcSeqFunc (isolated)
;   324788-328584  - SMF functions (cluster 5)
;
; The sequencer code is distributed across ~160,000 lines of the main source
; because it's part of the application layer, not a hardware driver subsystem.
; =============================================================================

; End of sequencer reference
