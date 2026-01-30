# UI Subsystem - Undisassembled Code and TODO Items

This file tracks references to undisassembled code found during UI subsystem documentation.

## Completed Work

### Display Update System (0xEF5B27-0xEF5CE7)
- Added semantic names: `Display_ResetDirtyFlags`, `Display_UpdateDirtyRegions`, `Display_MarkClean`
- Documented 11 region update routines (`Display_UpdateRegion0` through `Display_UpdateRegion10`)
- Documented 11 redraw routines (`Display_RedrawStatusBar`, `Display_RedrawTitleBar`, etc.)
- Added EQU constants: `DISPLAY_DIRTY_FLAGS`, `DISPLAY_ENABLE_FLAG`, `DISPLAY_CACHED_VAL*`

### VRAM Drawing (0xEF50DF)
- Renamed `LABEL_EF50DF` to `VRAM_FillRect` with full header documentation
- Documents rectangle fill operation for UI regions

## Undisassembled Code Blocks

### ClassProc Jump Table (0xFA4598)
- **Address**: 0xFA4598 (line 355938)
- **Size**: ~15 bytes
- **Context**: Jump offsets for ClassProc event dispatch (events 0x1E00000-0x1E00007)
- **Referenced from**: ClassProc at line 355937
- **Priority**: HIGH - Core UI event handler

### CmpSetGridCheck (0xF1A8C9)
- **Address**: 0xF1A8C9 (line 167998)
- **Size**: ~147 bytes
- **Context**: Grid/check UI component handler dispatch table
- **Referenced from**: CmpSetGridCheck at line 167995
- **Priority**: MEDIUM - Widget handling code

### LABEL_EF5B79 (0xEF5B79)
- **Address**: 0xEF5B79 (line 142560)
- **Size**: 18 bytes
- **Context**: Appears to be part of VGA/display update routines
- **Referenced from**: Unknown
- **Priority**: LOW - Display helper

## Routines Needing Semantic Names

### Display/VGA Section (0xEF5000-0xEF6000)
| Address | Current Name | Suggested Name | Notes |
|---------|--------------|----------------|-------|
| 0xEF50DF | LABEL_EF50DF | VGA_WaitVSync | Waits for vertical sync |
| 0xEF5163 | LABEL_EF5163 | VGA_UnlockRegisters | Called before register writes |
| 0xEF5B27 | LABEL_EF5B27 | Display_ResetFlags | Clears display state flags |
| 0xEF5B36 | LABEL_EF5B36 | Display_UpdateIfDirty | Conditional display update |
| 0xEF5B71 | LABEL_EF5B71 | Display_MarkClean | Sets display not dirty |
| 0xEF5B8B | LABEL_EF5B8B | Display_CheckFlag0 | Check bit 0 of display state |
| 0xEF5BE9 | LABEL_EF5BE9 | Display_CheckFlag1 | Check another flag |
| 0xEF5C07 | LABEL_EF5C07 | Display_CheckFlag2 | Check another flag |
| 0xEF5C20 | LABEL_EF5C20 | Display_CheckFlag3 | Check another flag |
| 0xEF5C39 | LABEL_EF5C39 | Display_CheckFlag4 | Check another flag |
| 0xEF5C52 | LABEL_EF5C52 | Display_CheckFlag5 | Check another flag |
| 0xEF5C6B | LABEL_EF5C6B | Display_CheckFlag6 | Check another flag |
| 0xEF5C84 | LABEL_EF5C84 | Display_CheckFlag7 | Check another flag |
| 0xEF5C9D | LABEL_EF5C9D | Display_CheckFlag8 | Check another flag |
| 0xEF5CB6 | LABEL_EF5CB6 | Display_CheckFlag9 | Check another flag |
| 0xEF5CCF | LABEL_EF5CCF | Display_CheckFlag10 | Check another flag |

### UI State Machine (0xEF0D00-0xEF0E00)
Already well documented. Key addresses:
- 0xEF0D64: UI_STATE_MACHINE_TABLE
- 0xEF0DA5: UI_SUBSTATE_TABLE

### UI Component Dispatch (0xF1A7CB-0xF1A900)
| Address | Current Name | Suggested Name | Notes |
|---------|--------------|----------------|-------|
| 0xF1A7CB | UI_COMPONENT_DISPATCH | (keep) | Main dispatcher |
| 0xF1A86F | LABEL_F1A86F | UI_Component_Epilogue | Common exit path |
| 0xF1A888 | LABEL_F1A888 | UI_Component_Return | Return from handler |

### Focus/Event System (0xFA4500-0xFA5000)
| Address | Current Name | Suggested Name | Notes |
|---------|--------------|----------------|-------|
| 0x02BC18 | - | UI_ROOT_OBJECT | Root UI object pointer |
| 0x02BC1C | - | UI_ROOT_EVENT | Root event pointer |
| 0x02BC20 | - | UI_ROOT_PARAM | Root param pointer |
| 0x02BC24 | - | UI_FOCUS_OBJECT | Current focus object |
| 0x02BC28 | - | UI_FOCUS_EVENT | Current focus event |
| 0x02BC2C | - | UI_FOCUS_PARAM | Current focus param |

## Widget Tables to Document

### Offset Table at 0xE1CEF0
- Used by UI_COMPONENT_DISPATCH to select handlers
- 8 entries (offsets for cases 0-7)
- **TODO**: Document what each offset points to

### Widget Definition Tables
- 0xE1E516, 0xE1E596, 0xE1E994, 0xE1EA88
- 0xE1ED64, 0xE1EE2C, 0xE1EF42
- **TODO**: Document structure of widget definitions

## UI State Variables

| Address | Name | Description |
|---------|------|-------------|
| 0x0411 | UI_PRIMARY_STATE | Primary state machine index (0-2) |
| 0x0412 | UI_SUBSTATE | Sub-state index (0-15) |
| 0x0413 | UI_FLAGS | Various UI flag bits |
| 0x0414 | UI_PROCESS_FLAG | Process state flag |
| 0x041F | UI_MODE_FLAGS | Mode flags |
| 0x0422 | UI_CONTROL_FLAGS | Control flags |
| 0x045C | UI_COUNTER | Decrement counter |
| 0x0468 | UI_TIMER_LOW | Timer low word |
| 0x046A | UI_TIMER_COUNT | Timer counter |
| 0x034CE | UI_COMPONENT_STATE | Component state byte |
| 0x034D7 | UI_GRID_INDEX | Grid index |
| 0x034D8 | UI_GRID_STATE | Grid state byte |
| 0x034E9 | UI_CHECK_STATE | Check state |
| 0x034EA | UI_CHECK_FLAGS | Check flags |

## Cross-References to Other Subsystems

### Control Panel
- Button state at 0x8E4A (right), 0x8E5A (left)
- CPanel_* routines handle button events

### MIDI
- MIDI events trigger UI updates
- See MIDI_* routines

### Display
- VGA_IO_BASE (0x170000) - LCD controller
- VIDEO_RAM_BASE (0x1A0000) - Video buffer
- OFFSCREEN_BUFFER_1 - Double buffer

## Notes

- The UI uses a 3-state primary state machine with 16 sub-states
- Widget handling uses an offset table at 0xE1CEF0 for polymorphic dispatch
- Focus system maintains object/event/param pointers for both root and current focus
- Display updates use dirty flag checking to optimize redraws
