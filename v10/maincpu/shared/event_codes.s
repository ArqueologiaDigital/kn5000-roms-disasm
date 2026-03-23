; =============================================================================
; Event Code Constants
; See https://arqueologiadigital.github.io/KN5000-docs/event-codes/ for details
; =============================================================================

; ClassProc getter events (handled by jump table at 0xEAA8F8)
.equ EVT_IDENTITY, 0x1E00000	; Identity query -- returns XWA unchanged
.equ EVT_GET_HL, 0x1E00001	; Returns *(XHL)
.equ EVT_GET_IZ, 0x1E00002	; Returns *(XIZ)
.equ EVT_GET_CONFIG, 0x1E00003	; Returns *(XHL+0x0C)

; ClassProc special events
.equ EVT_KEYPRESS, 0x1E0000D	; Keypress handling
.equ EVT_INPUT, 0x1E0000E	; Other input event
.equ EVT_RETURN_ZERO, 0x1E0000F	; Returns immediately (no-op)
.equ EVT_GET_CONFIG_2, 0x1E00015	; Returns *(XHL+0x0C)

; ObjectProc lifecycle events (handled by jump table at 0xEAA8A4)
.equ EVT_REDRAW, 0x1E00014	; UI redraw / refresh

; Request/action events (reach record function directly)
.equ EVT_MENU_OPEN, 0x1C00001	; DISK MENU screen displayed
.equ EVT_SELECT_CONFIRM, 0x1C00002	; Selection confirmed after button press
.equ EVT_ACTIVATE, 0x1C00008	; DISK MENU entry selected via button press
.equ EVT_POST_INIT, 0x1C0000D	; Posted after custom init
.equ EVT_INIT_HOOK, 0x1C0000F	; Custom initialization hook
.equ EVT_CPANEL_EVENT, 0x1C00013	; Control panel event
.equ EVT_HD_INIT_PARAMS, 0x1C00016	; Hard disk initialization parameters
.equ EVT_BUTTON_FOCUS, 0x1C00039	; Button focus during selection

; Activation events
.equ EVT_POST_ACTIVATE, 0x1E0009C	; Programmatic activation via PostEvent

; Display/memory allocation events
.equ EVT_ALLOC_DATA_PTR, 0x1E000A1	; Returns palette/graphics data pointer
.equ EVT_ALLOC_WIDTH, 0x1E000A2	; Returns display width (320)
.equ EVT_ALLOC_HEIGHT, 0x1E000A3	; Returns display height (240)

; Display callback identifiers
.equ EVT_DISPLAY_CALLBACK, 0x1CA0000	; Display callback
.equ EVT_DISPLAY_UPDATE, 0x1CA0004	; Display state update

; Grid/Check widget events
.equ EVT_GRIDCHECK_RESP_A, 0x1E40008	; Grid/Check response A
.equ EVT_GRIDCHECK_RESP_B, 0x1E4000A	; Grid/Check response B
.equ EVT_OBJECT_STATE_QUERY, 0x1E0008F	; Object state query
