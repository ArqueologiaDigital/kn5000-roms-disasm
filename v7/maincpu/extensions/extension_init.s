; =============================================================================
; Extension Device Registration (internal codename: "TOSHI")
; =============================================================================
;
; This subsystem registers expansion slot devices (such as the HD-AE5000 hard
; disk board) with the main firmware. It creates object tables, titles, and
; modes for each device so that the UI framework can present extension-specific
; screens and route events to extension handlers.
;
; "TOSHI" is the Matsushita/Technics developer codename for this subsystem.
; All original symbol names (InitializeToshi, etc.) are preserved.
;
; Files in this directory:
;   extension_init.s  - InitializeToshi(): 70+ RegisterObjectTable calls
;   extension_data.s  - Extension device data tables and NAKA descriptors
; =============================================================================

InitializeToshi:
	.incbin "includes/generated/v7_fix_initializetoshi.bin"
