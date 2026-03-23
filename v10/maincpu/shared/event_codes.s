; =============================================================================
; Event Code Constants
; See https://arqueologiadigital.github.io/KN5000-docs/event-codes/ for details
; =============================================================================

; ClassProc getter events (handled by jump table at 0xeaa8f8)
.equ EVT_IDENTITY, 0x1e00000	; Identity query -- returns XWA unchanged
.equ EVT_GET_HL, 0x1e00001	; Returns *(XHL)
.equ EVT_GET_IZ, 0x1e00002	; Returns *(XIZ)
.equ EVT_GET_CONFIG, 0x1e00003	; Returns *(XHL+0x0c)

; ClassProc special events
.equ EVT_KEYPRESS, 0x1e0000d	; Keypress handling
.equ EVT_INPUT, 0x1e0000e	; Other input event
.equ EVT_RETURN_ZERO, 0x1e0000f	; Returns immediately (no-op)
.equ EVT_GET_CONFIG_2, 0x1e00015	; Returns *(XHL+0x0c)

; ObjectProc lifecycle events (handled by jump table at 0xeaa8a4)
.equ EVT_REDRAW, 0x1e00014	; UI redraw / refresh

; Request/action events (reach record function directly)
.equ EVT_MENU_OPEN, 0x1c00001	; DISK MENU screen displayed
.equ EVT_SELECT_CONFIRM, 0x1c00002	; Selection confirmed after button press
.equ EVT_ACTIVATE, 0x1c00008	; DISK MENU entry selected via button press
.equ EVT_POST_INIT, 0x1c0000d	; Posted after custom init
.equ EVT_INIT_HOOK, 0x1c0000f	; Custom initialization hook
.equ EVT_CPANEL_EVENT, 0x1c00013	; Control panel event
.equ EVT_HD_INIT_PARAMS, 0x1c00016	; Hard disk initialization parameters
.equ EVT_BUTTON_FOCUS, 0x1c00039	; Button focus during selection

; Activation events
.equ EVT_POST_ACTIVATE, 0x1e0009c	; Programmatic activation via PostEvent

; Display/memory allocation events
.equ EVT_ALLOC_DATA_PTR, 0x1e000a1	; Returns palette/graphics data pointer
.equ EVT_ALLOC_WIDTH, 0x1e000a2	; Returns display width (320)
.equ EVT_ALLOC_HEIGHT, 0x1e000a3	; Returns display height (240)

; Display callback identifiers
.equ EVT_DISPLAY_CALLBACK, 0x1ca0000	; Display callback
.equ EVT_DISPLAY_UPDATE, 0x1ca0004	; Display state update

; Grid/Check widget events
.equ EVT_GRIDCHECK_RESP_A, 0x1e40008	; Grid/Check response A
.equ EVT_GRIDCHECK_RESP_B, 0x1e4000a	; Grid/Check response B
.equ EVT_OBJECT_STATE_QUERY, 0x1e0008f	; Object state query
