#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for maincpu sequencer part/step/event functions.

Covers 3 NOP-padded regions in kn5000_v10_program.s:
  1. SeqPart  (F49B31-F4CE3B)  Sequencer part management: part init, comparison,
     event walking, position navigation, transpose, velocity edit, part select
  2. SeqStep  (F4CE4D-F4FCAD)  Step recording & event manipulation: note dispatch,
     step record, event insert/delete, playback state, part compaction, file I/O
  3. SMF_Slot (F29282 region)  SMF slot parameter processing (3 remaining labels)

Each rename was verified by analysing the routine's code, register usage,
called functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
# ---------------------------------------------------------------------------

RENAMES = [

    # ==================================================================
    # 3. SMF_Slot (3 remaining labels in the F29282 region)
    #    SMF slot parameter processing — leftover LABEL_* from prior rename
    # ==================================================================

    ('LABEL_F29698', 'SMF_SlotChain_Fmt3CheckStep',
     'Chord type 3: check step=0xC, translate channel'),

    ('LABEL_F29A8E', 'SMF_SlotParam_SostenutoImpl',
     'Store translated channel to xiy+2, set step=1'),

    ('LABEL_F29B2A', 'SMF_SlotParam_Format5Set',
     'Set 4411 bit0 (ordi8 4411,1) before Format5Return'),

    # ==================================================================
    # 1. SeqPart (lines 147807-152223, 385 labels)
    #    Sequencer part management: handles loading, comparing, navigating,
    #    editing (transpose/velocity), and exchanging sequencer parts.
    #    Key addresses: 10359=current part, 9858=second part, 10362=error,
    #    10363=flags, 9780=source part, 9810=dest part, 9862/9778=positions
    # ==================================================================

    ('LABEL_F49B31', 'SeqPart_InitClear',
     'Clear current part: call F3FEFB, check F3F604, set error or init slots'),

    ('LABEL_F49B4B', 'SeqPart_InitSlots',
     'Set up part slots via F415B2/F415DB/F4178A/F4179D/F417E5/F417F4'),

    ('LABEL_F49BAF', 'SeqPart_InitFinish',
     'Finish init: call F3FF1A, write ffe3+1 counters via F4179D/F417F4/F415B2'),

    ('LABEL_F49C0B', 'SeqPart_Compare',
     'Compare two parts: elaborate multi-field comparison logic'),

    ('LABEL_F49C90', 'SeqPart_CompareFields',
     'Compare part fields: position/counter checks'),

    ('LABEL_F49CBD', 'SeqPart_CompareCheckA',
     'Compare check A: test specific part byte'),

    ('LABEL_F49CC1', 'SeqPart_CompareNoMatch',
     'Compare: set no-match (hl=0xFFFF) and return'),

    ('LABEL_F49CC8', 'SeqPart_CompareCheckB',
     'Compare check B: cp a with next field'),

    ('LABEL_F49CD0', 'SeqPart_CompareCheckC',
     'Compare check C: third field comparison'),

    ('LABEL_F49CD5', 'SeqPart_CompareCheckD',
     'Compare check D: test 8-bit field, jump on mismatch'),

    ('LABEL_F49CDD', 'SeqPart_CompareCheckE',
     'Compare check E: further field comparison'),

    ('LABEL_F49CEF', 'SeqPart_CompareSetFlag',
     'Compare: set flag bit in 10363'),

    ('LABEL_F49CF7', 'SeqPart_CompareReturn',
     'Compare: return with hl=0 (match)'),

    ('LABEL_F49CFE', 'SeqPart_CompareLong',
     'Compare long: extended comparison with 16-bit fields'),

    ('LABEL_F49D13', 'SeqPart_CompareLongReturn',
     'Compare long return path'),

    ('LABEL_F49D17', 'SeqPart_SetupWithDispatch',
     'Set up part and dispatch events via event type loop'),

    ('LABEL_F49D51', 'SeqPart_DispatchReturn',
     'Return from event dispatch'),

    ('LABEL_F49D66', 'SeqPart_DispatchCheckEvent',
     'Check event type before dispatch'),

    ('LABEL_F49D84', 'SeqPart_EventLoop',
     'Event loop: dispatch D1/D2/D3(tempo), 80-86(notes), B0/C0/90(control)'),

    ('LABEL_F49DC8', 'SeqPart_EventLoopD0',
     'Event loop: handle D0 events'),

    ('LABEL_F49DFB', 'SeqPart_EventLoopD1D2D3',
     'Event loop: handle D1/D2/D3 tempo events'),

    ('LABEL_F49E03', 'SeqPart_EventLoopNote',
     'Event loop: handle note events (80-86 range)'),

    ('LABEL_F49E0B', 'SeqPart_EventLoopB0',
     'Event loop: handle B0 control change'),

    ('LABEL_F49E25', 'SeqPart_EventLoopC0',
     'Event loop: handle C0 program change'),

    ('LABEL_F49E2D', 'SeqPart_EventLoop90',
     'Event loop: handle 90 note-on events'),

    ('LABEL_F49E35', 'SeqPart_EventLoopSkip',
     'Event loop: skip unhandled event byte'),

    ('LABEL_F49E41', 'SeqPart_EventLoopContinue',
     'Event loop: advance position and loop back'),

    ('LABEL_F49E4A', 'SeqPart_ClearSingle',
     'Clear single part data: zero counters, reset flags'),

    ('LABEL_F49E9F', 'SeqPart_ClearSingleReturn',
     'Return from clear single part'),

    ('LABEL_F49EA0', 'SeqPart_CompareLeft',
     'Compare part position left (0x27D4/0x27D6 pair)'),

    ('LABEL_F49EC2', 'SeqPart_CompareLeftCheck',
     'Left compare: check boundary condition'),

    ('LABEL_F49EC8', 'SeqPart_CompareLeftLoop',
     'Left compare: loop reading events until boundary'),

    ('LABEL_F49EE6', 'SeqPart_CompareLeftDone',
     'Left compare: done, set result'),

    ('LABEL_F49EED', 'SeqPart_CompareRight',
     'Compare part position right (0x27D8/0x27DA pair)'),

    ('LABEL_F49F0F', 'SeqPart_CompareRightCheck',
     'Right compare: check boundary condition'),

    ('LABEL_F49F15', 'SeqPart_CompareRightLoop',
     'Right compare: loop reading events until boundary'),

    ('LABEL_F49F33', 'SeqPart_CompareRightDone',
     'Right compare: done, set result'),

    ('LABEL_F49F3A', 'SeqPart_WaitLeftMatch',
     'Wait for left position match: loop calling F401A4'),

    ('LABEL_F49F3C', 'SeqPart_WaitLeftLoop',
     'Left match wait: inner loop body'),

    ('LABEL_F49F4A', 'SeqPart_WaitRightMatch',
     'Wait for right position match: loop calling F401A4'),

    ('LABEL_F49F4C', 'SeqPart_WaitRightLoop',
     'Right match wait: inner loop body'),

    ('LABEL_F49F5A', 'SeqPart_DualSwap',
     'Dual part swap: set up 0x81 via F3FC46, compare left/right'),

    ('LABEL_F49F8E', 'SeqPart_DualSwapFinish',
     'Finish dual swap: store results, pop xiz, return'),

    ('LABEL_F49FC2', 'SeqPart_DualSwapReturn',
     'Dual swap return: pop xiz, inc sp, ret'),

    ('LABEL_F49FC6', 'SeqPart_ValidateRight',
     'Validate right part: check bit1 of 10194, call F3FB78'),

    ('LABEL_F49FE0', 'SeqPart_ValidateRightLoop',
     'Right validation loop: call F3FC46'),

    ('LABEL_F49FE4', 'SeqPart_ValidateRightCore',
     'Right validation core: compare positions via F37C81/F37CBB'),

    ('LABEL_F4A00E', 'SeqPart_ValidateLeft',
     'Validate left part: check bit0 of 10194, call F3FB78'),

    ('LABEL_F4A028', 'SeqPart_ValidateLeftLoop',
     'Left validation loop: call F3FC46'),

    ('LABEL_F4A02C', 'SeqPart_ValidateLeftCore',
     'Left validation core: compare positions via F37C81/F37CBB'),

    ('LABEL_F4A056', 'SeqPart_InitWithValidation',
     'Initialize with validation: call F3FEFB/F3FABF, set error=3 or 0'),

    ('LABEL_F4A073', 'SeqPart_InitValidOk',
     'Validation OK: set error=0, clear flags bit6, return hl=0'),

    ('LABEL_F4A07F', 'SeqPart_CheckVoiceType',
     'Check part voice type: lookup 61856 table, test for D/F/10 (drum/rhythm)'),

    ('LABEL_F4A09C', 'SeqPart_CheckVoiceIsDrum',
     'Voice is drum/rhythm type (D/E/F/10)'),

    ('LABEL_F4A0AC', 'SeqPart_CheckBothCompatible',
     'Check both parts compatible: compare voice types of both parts'),

    ('LABEL_F4A116', 'SeqPart_CompatReturn',
     'Compatibility check return'),

    ('LABEL_F4A119', 'SeqPart_SetupLeftPos',
     'Set up left part position from mem data'),

    ('LABEL_F4A136', 'SeqPart_SetupLeftDone',
     'Left position setup done'),

    ('LABEL_F4A145', 'SeqPart_SetupRightPos',
     'Set up right part position from mem data'),

    ('LABEL_F4A162', 'SeqPart_SetupRightDone',
     'Right position setup done'),

    ('LABEL_F4A171', 'SeqPart_HandlePartChange',
     'Handle part number change: update 10359, call F3F604'),

    ('LABEL_F4A198', 'SeqPart_PartChangeError',
     'Part change: error path (set error=3)'),

    ('LABEL_F4A19C', 'SeqPart_AllocNewEntry',
     'Allocate new part entry: call F415DB/F4179D/F417F4'),

    ('LABEL_F4A1B3', 'SeqPart_AllocDone',
     'New entry allocation done'),

    ('LABEL_F4A203', 'SeqPart_AllocReturn',
     'Allocation return path'),

    ('LABEL_F4A207', 'SeqPart_ByteBlockA207',
     'Large .byte data block (undecoded instructions)'),

    ('LABEL_F4A4EA', 'SeqPart_SinglePartLoad',
     'Single part load procedure: init error=0, check voice type'),

    ('LABEL_F4A501', 'SeqPart_SingleLoadCheckType',
     'Single load: check voice type, branch for drum'),

    ('LABEL_F4A532', 'SeqPart_SingleLoadSetup',
     'Single load: set up source/dest part numbers'),

    ('LABEL_F4A53E', 'SeqPart_SingleLoadMode',
     'Single load: dispatch by mode (0/1/2)'),

    ('LABEL_F4A550', 'SeqPart_SingleLoadMode0',
     'Single load mode 0: basic load path'),

    ('LABEL_F4A55C', 'SeqPart_SingleLoadMode1',
     'Single load mode 1: extended load path'),

    ('LABEL_F4A55F', 'SeqPart_SingleLoadMode2',
     'Single load mode 2: full load path'),

    ('LABEL_F4A57A', 'SeqPart_SingleLoadInit',
     'Single load: init counters and start event walk'),

    ('LABEL_F4A583', 'SeqPart_SingleLoadSkipDrum',
     'Single load: skip drum-specific init'),

    ('LABEL_F4A593', 'SeqPart_SingleLoadVoiceSetup',
     'Single load: set up voice parameters'),

    ('LABEL_F4A5B6', 'SeqPart_SingleLoadFinish',
     'Single load: finish and return'),

    ('LABEL_F4A5DC', 'SeqPart_SingleLoadError',
     'Single load: error exit path'),

    ('LABEL_F4A5E8', 'SeqPart_SingleLoadReturn',
     'Single load: return'),

    ('LABEL_F4A5EE', 'SeqPart_SingleLoadCleanup',
     'Single load: cleanup on error'),

    ('LABEL_F4A5FA', 'SeqPart_FullLoad',
     'Full part load with event processing: dispatch mode 0/1/2'),

    ('LABEL_F4A67D', 'SeqPart_FullLoadWalk',
     'Full load: walk events, track 0x82 end markers'),

    ('LABEL_F4A68C', 'SeqPart_FullLoadReadEvent',
     'Full load: read next event via F3FC17'),

    ('LABEL_F4A69F', 'SeqPart_FullLoadCheck81',
     'Full load: check for 0x81 marker'),

    ('LABEL_F4A6C8', 'SeqPart_FullLoadCountCheck',
     'Full load: compare event count against total'),

    ('LABEL_F4A6D2', 'SeqPart_FullLoadComplete',
     'Full load: all events processed, advance position'),

    ('LABEL_F4A6EB', 'SeqPart_FullLoadSrcMatch',
     'Full load: check if source part matches current'),

    ('LABEL_F4A700', 'SeqPart_FullLoadProcess',
     'Full load: process event - validate, check bit7'),

    ('LABEL_F4A739', 'SeqPart_FullLoadValidate',
     'Full load: validate event via F3FAF3'),

    ('LABEL_F4A747', 'SeqPart_FullLoadMode1',
     'Full load mode 1: check 9694 count, walk events'),

    ('LABEL_F4A755', 'SeqPart_FullLoadMode1Walk',
     'Full load mode 1: event walk initialization'),

    ('LABEL_F4A764', 'SeqPart_FullLoadMode1Read',
     'Full load mode 1: read event via F3FC17'),

    ('LABEL_F4A777', 'SeqPart_FullLoadMode1Check81',
     'Full load mode 1: check for 0x81 marker'),

    ('LABEL_F4A7A0', 'SeqPart_FullLoadMode1Count',
     'Full load mode 1: compare event count'),

    ('LABEL_F4A7AA', 'SeqPart_FullLoadMode1Done',
     'Full load mode 1: all events processed'),

    ('LABEL_F4A7C3', 'SeqPart_FullLoadMode1Src',
     'Full load mode 1: check source part match'),

    ('LABEL_F4A7CE', 'SeqPart_FullLoadMode1Process',
     'Full load mode 1: process event'),

    ('LABEL_F4A7E9', 'SeqPart_FullLoadMode1Validate',
     'Full load mode 1: validate event'),

    ('LABEL_F4A807', 'SeqPart_FullLoadMode2',
     'Full load mode 2: check 9694 count, walk events'),

    ('LABEL_F4A810', 'SeqPart_FullLoadMode2Walk',
     'Full load mode 2: event walk initialization'),

    ('LABEL_F4A820', 'SeqPart_FullLoadMode2Read',
     'Full load mode 2: read event via F3FC17'),

    ('LABEL_F4A833', 'SeqPart_FullLoadMode2Check81',
     'Full load mode 2: check for 0x81 marker'),

    ('LABEL_F4A85E', 'SeqPart_FullLoadMode2Count',
     'Full load mode 2: compare event count'),

    ('LABEL_F4A881', 'SeqPart_FullLoadMode2Src',
     'Full load mode 2: source part match check'),

    ('LABEL_F4A894', 'SeqPart_FullLoadMode2Process',
     'Full load mode 2: process and validate event'),

    ('LABEL_F4A8C2', 'SeqPart_FullLoadMode2Done',
     'Full load mode 2: completed, advance position'),

    ('LABEL_F4A8CD', 'SeqPart_FullLoadMode2Validate',
     'Full load mode 2: validate via F3FAF3'),

    ('LABEL_F4A8E3', 'SeqPart_FullLoadExit',
     'Full load: common exit — pop xiz, return'),

    ('LABEL_F4A928', 'SeqPart_FullLoadWriteBack',
     'Full load: write back updated positions'),

    ('LABEL_F4A93D', 'SeqPart_FullLoadWriteReturn',
     'Full load: write-back return'),

    ('LABEL_F4A956', 'SeqPart_FullLoadErrorExit',
     'Full load: error exit — jump to error handler'),

    ('LABEL_F4A95A', 'SeqPart_ByteBlockA95A',
     'Large .byte data block (undecoded instructions)'),

    ('LABEL_F4ABCD', 'SeqPart_DualCopySetup',
     'Dual-part copy setup: set source/dest, call F4AF4E'),

    ('LABEL_F4ABFA', 'SeqPart_DualCopyCheck',
     'Dual copy: check compatibility of source/dest'),

    ('LABEL_F4AC2B', 'SeqPart_DualCopyInit',
     'Dual copy: initialize counters for multi-part walk'),

    ('LABEL_F4AC5C', 'SeqPart_DualCopyProcess',
     'Dual copy: process event during walk'),

    ('LABEL_F4AC7E', 'SeqPart_DualCopyValidate',
     'Dual copy: validate event data'),

    ('LABEL_F4AC87', 'SeqPart_DualCopyAdvance',
     'Dual copy: advance to next event'),

    ('LABEL_F4ACB0', 'SeqPart_DualCopyFinish',
     'Dual copy: finish multi-part walk'),

    ('LABEL_F4AD01', 'SeqPart_DualCopyReturn',
     'Dual copy: return path'),

    ('LABEL_F4AD2D', 'SeqPart_DualCopyErrorCheck',
     'Dual copy: check error code after walk'),

    ('LABEL_F4AD31', 'SeqPart_DualCopyErrorExit',
     'Dual copy: error exit with code 0x46'),

    ('LABEL_F4AD70', 'SeqPart_DualCopyJumpExit',
     'Dual copy: jump to F439AB exit'),

    ('LABEL_F4AD74', 'SeqPart_DualCopyBit3Check',
     'Dual copy: check bit3 of 10363, call F4039F/F425E2'),

    ('LABEL_F4AD92', 'SeqPart_ByteBlockAD92',
     'Large .byte data block (undecoded instructions)'),

    ('LABEL_F4AF4E', 'SeqPart_MultiPartWalker',
     'Multi-part event walker: walk events across parts, dispatch by type'),

    ('LABEL_F4AFB0', 'SeqPart_WalkerLoop',
     'Walker: main event processing loop'),

    ('LABEL_F4AFBD', 'SeqPart_WalkerCheckType',
     'Walker: check event type for dispatch'),

    ('LABEL_F4AFDA', 'SeqPart_WalkerD0',
     'Walker: handle D0 event'),

    ('LABEL_F4AFE5', 'SeqPart_WalkerD1D2D3',
     'Walker: handle D1/D2/D3 tempo events'),

    ('LABEL_F4AFF1', 'SeqPart_WalkerNote',
     'Walker: handle note events (80-86 range)'),

    ('LABEL_F4B039', 'SeqPart_WalkerB0',
     'Walker: handle B0 control change'),

    ('LABEL_F4B043', 'SeqPart_WalkerC0',
     'Walker: handle C0 program change'),

    ('LABEL_F4B04D', 'SeqPart_Walker90',
     'Walker: handle 90 note-on'),

    ('LABEL_F4B057', 'SeqPart_WalkerSkip',
     'Walker: skip unhandled event byte'),

    ('LABEL_F4B061', 'SeqPart_WalkerContinue',
     'Walker: advance position and continue loop'),

    ('LABEL_F4B073', 'SeqPart_WalkerBoundary',
     'Walker: check for end boundary (0x82 marker)'),

    ('LABEL_F4B082', 'SeqPart_WalkerEndCheck',
     'Walker: check if all events processed'),

    ('LABEL_F4B091', 'SeqPart_WalkerAdvance',
     'Walker: advance to next event set'),

    ('LABEL_F4B09F', 'SeqPart_WalkerNextSet',
     'Walker: start next event set'),

    ('LABEL_F4B0BF', 'SeqPart_WalkerComplete',
     'Walker: all sets processed, return'),

    ('LABEL_F4B0C3', 'SeqPart_WalkerReturn',
     'Walker: common return path'),

    ('LABEL_F4B0DC', 'SeqPart_WalkerExit',
     'Walker: exit with error check'),

    ('LABEL_F4B0DE', 'SeqPart_ByteBlockB0DE',
     'Large .byte data block (undecoded instructions)'),

    ('LABEL_F4B1D1', 'SeqPart_DualPartLoad',
     'Dual part load handler: load two parts simultaneously'),

    ('LABEL_F4B1FE', 'SeqPart_DualLoadSetup',
     'Dual load: set up source/dest part numbers'),

    ('LABEL_F4B21B', 'SeqPart_DualLoadCheck',
     'Dual load: check part compatibility'),

    ('LABEL_F4B234', 'SeqPart_DualLoadInit',
     'Dual load: initialize for event walk'),

    ('LABEL_F4B23D', 'SeqPart_DualLoadLoop',
     'Dual load: main event processing loop'),

    ('LABEL_F4B250', 'SeqPart_DualLoadEvent',
     'Dual load: process single event'),

    ('LABEL_F4B274', 'SeqPart_DualLoadValidate',
     'Dual load: validate event data'),

    ('LABEL_F4B2A4', 'SeqPart_DualLoadAdvance',
     'Dual load: advance to next event'),

    ('LABEL_F4B2C3', 'SeqPart_DualLoadFinish',
     'Dual load: finish processing'),

    ('LABEL_F4B2CF', 'SeqPart_DualLoadComplete',
     'Dual load: all events done'),

    ('LABEL_F4B2D8', 'SeqPart_DualLoadReturn',
     'Dual load: return path'),

    ('LABEL_F4B309', 'SeqPart_DualLoadCleanup',
     'Dual load: cleanup after error or completion'),

    ('LABEL_F4B30D', 'SeqPart_DualLoadFinal',
     'Dual load: final return'),

    ('LABEL_F4B32A', 'SeqPart_DualLoadErrorCheck',
     'Dual load: check error status'),

    ('LABEL_F4B332', 'SeqPart_DualLoadPartA',
     'Dual load: process part A'),

    ('LABEL_F4B33D', 'SeqPart_DualLoadPartADone',
     'Dual load: part A done'),

    ('LABEL_F4B341', 'SeqPart_DualLoadPartB',
     'Dual load: process part B'),

    ('LABEL_F4B397', 'SeqPart_DualLoadPartBCheck',
     'Dual load: part B compatibility check'),

    ('LABEL_F4B3A3', 'SeqPart_DualLoadPartBInit',
     'Dual load: part B initialization'),

    ('LABEL_F4B3AF', 'SeqPart_DualLoadPartBRun',
     'Dual load: part B event processing'),

    ('LABEL_F4B3C0', 'SeqPart_DualLoadPartBFinish',
     'Dual load: part B finish, check drum part'),

    ('LABEL_F4B3F1', 'SeqPart_DualLoadNavigate',
     'Dual load: call main navigation (F4BA1E)'),

    ('LABEL_F4B3F4', 'SeqPart_DualLoadExit',
     'Dual load: exit — call F3FF2D/F3FF1A, pop, ret'),

    ('LABEL_F4B400', 'SeqPart_DrumPartHandler',
     'Drum/rhythm part special handling: F40AE4/F400A7, check voice type'),

    ('LABEL_F4B4CB', 'SeqPart_DrumPartBoundary',
     'Drum part: set boundary positions from 9778/9862/9694'),

    ('LABEL_F4B4E5', 'SeqPart_DrumPartExtended',
     'Drum part: extended setup with second walker via F40AFD'),

    ('LABEL_F4B51E', 'SeqPart_DrumPartJumpExit',
     'Drum part: jump to F43A46 exit'),

    ('LABEL_F4B522', 'SeqPart_Exchange',
     'Part exchange/setup with position management'),

    ('LABEL_F4B56A', 'SeqPart_ExchangeInit',
     'Exchange: initialize flags and positions'),

    ('LABEL_F4B5BD', 'SeqPart_ExchangeProcess',
     'Exchange: process event data for both parts'),

    ('LABEL_F4B659', 'SeqPart_ExchangeValidate',
     'Exchange: validate exchanged data'),

    ('LABEL_F4B6A7', 'SeqPart_ExchangeAdvance',
     'Exchange: advance positions'),

    ('LABEL_F4B6D7', 'SeqPart_ExchangeCheckDone',
     'Exchange: check if all events processed'),

    ('LABEL_F4B6FC', 'SeqPart_ExchangeUpdate',
     'Exchange: update position counters'),

    ('LABEL_F4B721', 'SeqPart_ExchangeFinish',
     'Exchange: finish, clean up state'),

    ('LABEL_F4B72A', 'SeqPart_ExchangeReturn',
     'Exchange: return path'),

    ('LABEL_F4B72D', 'SeqPart_ExchangeError',
     'Exchange: error handling path'),

    ('LABEL_F4B75F', 'SeqPart_ExchangeCleanup',
     'Exchange: cleanup on error/completion'),

    ('LABEL_F4B762', 'SeqPart_ExchangeJump',
     'Exchange: jump to position handler'),

    ('LABEL_F4B764', 'SeqPart_PositionForward',
     'Position forward handler: advance through events'),

    ('LABEL_F4B78C', 'SeqPart_PosForwardLoop',
     'Position forward: main advancement loop'),

    ('LABEL_F4B7A4', 'SeqPart_PosForwardStep',
     'Position forward: advance one step'),

    ('LABEL_F4B833', 'SeqPart_PosForwardCheck',
     'Position forward: check boundary'),

    ('LABEL_F4B842', 'SeqPart_PosForwardDone',
     'Position forward: finished, update state'),

    ('LABEL_F4B871', 'SeqPart_PosForwardUpdate',
     'Position forward: update counters'),

    ('LABEL_F4B893', 'SeqPart_PosForwardValidate',
     'Position forward: validate result'),

    ('LABEL_F4B898', 'SeqPart_PosForwardReturn',
     'Position forward: return'),

    ('LABEL_F4B89B', 'SeqPart_PosForwardError',
     'Position forward: error exit'),

    ('LABEL_F4B8A2', 'SeqPart_PositionBackward',
     'Position backward handler: retreat through events'),

    ('LABEL_F4B8BC', 'SeqPart_PosBackwardLoop',
     'Position backward: main retreat loop'),

    ('LABEL_F4B93C', 'SeqPart_PosBackwardCheck',
     'Position backward: check boundary'),

    ('LABEL_F4B940', 'SeqPart_PosBackwardDone',
     'Position backward: finished, update state'),

    ('LABEL_F4B952', 'SeqPart_PosBackwardUpdate',
     'Position backward: update counters'),

    ('LABEL_F4B9A8', 'SeqPart_PosBackwardValidate',
     'Position backward: validate result'),

    ('LABEL_F4B9B5', 'SeqPart_PosBackwardReturn',
     'Position backward: return'),

    ('LABEL_F4B9B9', 'SeqPart_PositionEqual',
     'Equal position handler: no movement needed'),

    ('LABEL_F4B9CC', 'SeqPart_PosEqualSpecial',
     'Equal position: special case (part=0x7F or matches 9858)'),

    ('LABEL_F4B9F9', 'SeqPart_PosEqualSetFF',
     'Equal position: set bc=0xFF'),

    ('LABEL_F4B9FC', 'SeqPart_PosEqualStore',
     'Equal position: store results to 10222/10220'),

    ('LABEL_F4BA07', 'SeqPart_UndoAllocOnError',
     'Undo allocations if error: check bit7 of 10363, call SeqPart_InitClear'),

    ('LABEL_F4BA1E', 'SeqPart_MainNavigate',
     'Main part navigation: compare positions, call forward/backward/equal'),

    ('LABEL_F4BA58', 'SeqPart_NavForward',
     'Navigate: positions differ, source < dest — call forward handler'),

    ('LABEL_F4BA62', 'SeqPart_NavBackward',
     'Navigate: source > dest — init for backward, validate, walk events'),

    ('LABEL_F4BAE6', 'SeqPart_NavBackwardProcess',
     'Navigate backward: process event data'),

    ('LABEL_F4BB3A', 'SeqPart_NavBackwardValidate',
     'Navigate backward: validate results'),

    ('LABEL_F4BBB6', 'SeqPart_NavBackwardCheck',
     'Navigate backward: check completion'),

    ('LABEL_F4BBBA', 'SeqPart_NavBackwardDone',
     'Navigate backward: processing done'),

    ('LABEL_F4BBD6', 'SeqPart_NavBackwardWrite',
     'Navigate backward: write results back'),

    ('LABEL_F4BC67', 'SeqPart_NavBackwardCleanup',
     'Navigate backward: cleanup and return'),

    ('LABEL_F4BC80', 'SeqPart_NavBackwardReturn',
     'Navigate backward: return path'),

    ('LABEL_F4BCAC', 'SeqPart_NavProcessWalker',
     'Navigate: process walker results'),

    ('LABEL_F4BD6A', 'SeqPart_NavWalkerValidate',
     'Navigate: validate walker output'),

    ('LABEL_F4BD94', 'SeqPart_NavWalkerFinish',
     'Navigate: finish walker processing'),

    ('LABEL_F4BE26', 'SeqPart_NavWalkerReturn',
     'Navigate: walker return path'),

    ('LABEL_F4BE2A', 'SeqPart_NavWalkerError',
     'Navigate: walker error handling'),

    ('LABEL_F4BE56', 'SeqPart_NavWalkerCleanup',
     'Navigate: walker cleanup'),

    ('LABEL_F4BE81', 'SeqPart_NavExit',
     'Main navigation: common exit path'),

    ('LABEL_F4BE84', 'SeqPart_CountEventsInRange',
     'Count events in a range: walk from xwa to xbc, count entries'),

    ('LABEL_F4BEC0', 'SeqPart_CountLoop',
     'Count events: main counting loop'),

    ('LABEL_F4BEC7', 'SeqPart_CountCheckEnd',
     'Count events: check for end marker'),

    ('LABEL_F4BEE1', 'SeqPart_CountAdvance',
     'Count events: advance to next event'),

    ('LABEL_F4BEEE', 'SeqPart_CountReturn',
     'Count events: return with count in xiz'),

    ('LABEL_F4BF05', 'SeqPart_CountError',
     'Count events: error exit'),

    ('LABEL_F4BF10', 'SeqPart_CountBoundary',
     'Count events: boundary check'),

    ('LABEL_F4BF14', 'SeqPart_CountDone',
     'Count events: done, return count'),

    ('LABEL_F4BF18', 'SeqPart_ComputeStepCount',
     'Walk events and compute step count: walk from wa, count steps'),

    ('LABEL_F4BF43', 'SeqPart_StepCountLoop',
     'Step count: main loop body'),

    ('LABEL_F4BF66', 'SeqPart_StepCountAdvance',
     'Step count: advance one step'),

    ('LABEL_F4BF73', 'SeqPart_StepCountCheck',
     'Step count: check boundary'),

    ('LABEL_F4BF7A', 'SeqPart_StepCountDone',
     'Step count: done'),

    ('LABEL_F4BF87', 'SeqPart_StepCountReturn',
     'Step count: return path'),

    ('LABEL_F4BF99', 'SeqPart_StepCountError',
     'Step count: error exit'),

    ('LABEL_F4BF9F', 'SeqPart_StepCountPopReturn',
     'Step count: pop iz and return'),

    ('LABEL_F4BFA1', 'SeqPart_ReplayForward',
     'Replay events forward: iterate events from saved position'),

    ('LABEL_F4BFC3', 'SeqPart_ReplayLoop',
     'Replay: main event replay loop'),

    ('LABEL_F4BFEF', 'SeqPart_ReplayEnd',
     'Replay: write end marker (0x82)'),

    ('LABEL_F4BFFE', 'SeqPart_ReplayReturn',
     'Replay: pop xiz and return'),

    ('LABEL_F4C000', 'SeqPart_Splice',
     'Part splice operation: count events, compute steps, replay, update refs'),

    ('LABEL_F4C081', 'SeqPart_SpliceReturn',
     'Splice: return (inc 4, xsp, ret)'),

    ('LABEL_F4C084', 'SeqPart_RestoreState',
     'Restore state after part change: reset voice, update positions'),

    ('LABEL_F4C0F3', 'SeqPart_TransposeSetup',
     'Transpose setup: init from 9726, check 9728/9730 values'),

    ('LABEL_F4C10D', 'SeqPart_TransposeCheck',
     'Transpose: check if transpose value is non-zero'),

    ('LABEL_F4C12E', 'SeqPart_TransposeInit',
     'Transpose: init walker for event scan'),

    ('LABEL_F4C136', 'SeqPart_TransposeMode',
     'Transpose: dispatch by edit mode'),

    ('LABEL_F4C167', 'SeqPart_TransposeSetBounds',
     'Transpose: set boundary positions'),

    ('LABEL_F4C16E', 'SeqPart_TransposeValidate',
     'Transpose: validate settings'),

    ('LABEL_F4C177', 'SeqPart_TransposeBoundsOk',
     'Transpose: bounds validated OK'),

    ('LABEL_F4C17A', 'SeqPart_TransposeStartWalk',
     'Transpose: start event walk'),

    ('LABEL_F4C1A4', 'SeqPart_TransposeFinish',
     'Transpose: finish and return'),

    ('LABEL_F4C1BB', 'SeqPart_TransposeReturn',
     'Transpose: return path'),

    ('LABEL_F4C1CA', 'SeqPart_TransposeExit',
     'Transpose: exit with error check'),

    ('LABEL_F4C1D6', 'SeqPart_TransposeWalker',
     'Transpose event walker: scan events, apply transpose to notes'),

    ('LABEL_F4C202', 'SeqPart_TransposeWalkLoop',
     'Transpose walker: main loop'),

    ('LABEL_F4C20F', 'SeqPart_TransposeCheckNote',
     'Transpose walker: check if event is a note (80-86 range)'),

    ('LABEL_F4C225', 'SeqPart_TransposeApply',
     'Transpose walker: apply transpose value to note'),

    ('LABEL_F4C230', 'SeqPart_TransposeClampHigh',
     'Transpose walker: clamp note to maximum (0x7F)'),

    ('LABEL_F4C23F', 'SeqPart_TransposeClampLow',
     'Transpose walker: clamp note to minimum (0)'),

    ('LABEL_F4C27C', 'SeqPart_TransposeSkip',
     'Transpose walker: skip non-note event'),

    ('LABEL_F4C285', 'SeqPart_TransposeAdvance',
     'Transpose walker: advance to next event'),

    ('LABEL_F4C28D', 'SeqPart_TransposeDone',
     'Transpose walker: done processing'),

    ('LABEL_F4C29A', 'SeqPart_TransposeError',
     'Transpose walker: error exit'),

    ('LABEL_F4C2A1', 'SeqPart_TransposePopReturn',
     'Transpose walker: pop and return'),

    ('LABEL_F4C2A3', 'SeqPart_VelocityEditSetup',
     'Velocity edit setup: init from 9726/9728/9730 parameters'),

    ('LABEL_F4C2BA', 'SeqPart_VelEditCheck',
     'Velocity edit: check parameters non-zero'),

    ('LABEL_F4C2F7', 'SeqPart_VelEditInit',
     'Velocity edit: init walker for event scan'),

    ('LABEL_F4C2FE', 'SeqPart_VelEditMode',
     'Velocity edit: dispatch by edit mode'),

    ('LABEL_F4C301', 'SeqPart_VelEditBounds',
     'Velocity edit: set boundary positions'),

    ('LABEL_F4C32E', 'SeqPart_VelEditValidate',
     'Velocity edit: validate settings'),

    ('LABEL_F4C345', 'SeqPart_VelEditStartWalk',
     'Velocity edit: start event walk'),

    ('LABEL_F4C354', 'SeqPart_VelEditReturn',
     'Velocity edit: return path'),

    ('LABEL_F4C360', 'SeqPart_VelocityCurveCalc',
     'Velocity curve calculation: jump table with 11 entries'),

    ('LABEL_F4C38C', 'SeqPart_VelCurveData',
     'Velocity curve: .byte data block with curve definitions'),

    ('LABEL_F4C4FE', 'SeqPart_VelRangeToZone',
     'Velocity range to zone mapper: 12 zones at threshold boundaries'),

    ('LABEL_F4C50A', 'SeqPart_VelZone1',
     'Velocity zone 1: threshold 0x04, result e=1'),

    ('LABEL_F4C513', 'SeqPart_VelZone2',
     'Velocity zone 2: threshold 0x0C, result e=2'),

    ('LABEL_F4C51C', 'SeqPart_VelZone3',
     'Velocity zone 3: threshold 0x14, result e=3'),

    ('LABEL_F4C525', 'SeqPart_VelZone4',
     'Velocity zone 4: threshold 0x1C, result e=4'),

    ('LABEL_F4C52E', 'SeqPart_VelZone5',
     'Velocity zone 5: threshold 0x24, result e=5'),

    ('LABEL_F4C537', 'SeqPart_VelZone6',
     'Velocity zone 6: threshold 0x2C, result e=6'),

    ('LABEL_F4C540', 'SeqPart_VelZone7',
     'Velocity zone 7: threshold 0x34, result e=7'),

    ('LABEL_F4C549', 'SeqPart_VelZone8',
     'Velocity zone 8: threshold 0x3C, result e=8'),

    ('LABEL_F4C552', 'SeqPart_VelZone9',
     'Velocity zone 9: threshold 0x44, result e=9'),

    ('LABEL_F4C55B', 'SeqPart_VelZone10',
     'Velocity zone 10: threshold 0x4C, result e=0xA'),

    ('LABEL_F4C564', 'SeqPart_VelZone11',
     'Velocity zone 11: threshold 0x54/0x5C, result e=0 or 0xB'),

    ('LABEL_F4C56D', 'SeqPart_VelZoneLookup',
     'Velocity zone: lookup curve data from E44E8E/E44EB4 tables'),

    ('LABEL_F4C598', 'SeqPart_VelCalcSubtract',
     'Velocity calc: subtract base velocity'),

    ('LABEL_F4C5A9', 'SeqPart_VelCalcMultiply',
     'Velocity calc: multiply by curve factor'),

    ('LABEL_F4C5BB', 'SeqPart_VelCalcAdd',
     'Velocity calc: add curve offset'),

    ('LABEL_F4C5CA', 'SeqPart_VelCalcClamp',
     'Velocity calc: clamp to minimum 0x60'),

    ('LABEL_F4C5CC', 'SeqPart_VelCalcStore',
     'Velocity calc: store result to 9790/9788'),

    ('LABEL_F4C5D3', 'SeqPart_VelExprEdit',
     'Velocity/expression edit main: walk events, apply velocity changes'),

    ('LABEL_F4C629', 'SeqPart_VelExprLoop',
     'Vel/expr edit: main event walk loop'),

    ('LABEL_F4C646', 'SeqPart_VelExprReadEvent',
     'Vel/expr edit: read next event'),

    ('LABEL_F4C67A', 'SeqPart_VelExprCheckEnd',
     'Vel/expr edit: check for end marker'),

    ('LABEL_F4C685', 'SeqPart_VelExprCheckNote',
     'Vel/expr edit: check if event is a note'),

    ('LABEL_F4C698', 'SeqPart_VelExprExit',
     'Vel/expr edit: exit path'),

    ('LABEL_F4C69B', 'SeqPart_VelExprDone',
     'Vel/expr edit: done processing'),

    ('LABEL_F4C6AE', 'SeqPart_VelExprApply',
     'Vel/expr edit: apply velocity/expression change to note'),

    ('LABEL_F4C6C4', 'SeqPart_VelExprClamp',
     'Vel/expr edit: clamp velocity value'),

    ('LABEL_F4C726', 'SeqPart_VelExprWrite',
     'Vel/expr edit: write modified velocity back'),

    ('LABEL_F4C744', 'SeqPart_VelExprSkip',
     'Vel/expr edit: skip non-note event'),

    ('LABEL_F4C752', 'SeqPart_VelExprAdvance',
     'Vel/expr edit: advance to next event'),

    ('LABEL_F4C761', 'SeqPart_VelExprContinue',
     'Vel/expr edit: continue walk loop'),

    ('LABEL_F4C77A', 'SeqPart_VelExprBoundary',
     'Vel/expr edit: boundary check'),

    ('LABEL_F4C788', 'SeqPart_VelExprError',
     'Vel/expr edit: error exit'),

    ('LABEL_F4C7A7', 'SeqPart_VelExprReturn',
     'Vel/expr edit: return path'),

    ('LABEL_F4C7C4', 'SeqPart_VelExprFinish',
     'Vel/expr edit: finish and cleanup'),

    ('LABEL_F4C7E0', 'SeqPart_VelExprComplete',
     'Vel/expr edit: processing complete'),

    ('LABEL_F4C7E6', 'SeqPart_VelExprUpdate',
     'Vel/expr edit: update position counters'),

    ('LABEL_F4C7FB', 'SeqPart_VelExprStore',
     'Vel/expr edit: store updated positions'),

    ('LABEL_F4C80A', 'SeqPart_VelExprPopIz',
     'Vel/expr edit: pop xiz path'),

    ('LABEL_F4C80C', 'SeqPart_VelExprPopReturn',
     'Vel/expr edit: pop and return'),

    ('LABEL_F4C811', 'SeqPart_VelExprClampMax',
     'Vel/expr edit: clamp to max velocity'),

    ('LABEL_F4C815', 'SeqPart_VelExprClampMin',
     'Vel/expr edit: clamp to min velocity'),

    ('LABEL_F4C829', 'SeqPart_VelExprFinalExit',
     'Vel/expr edit: final exit path (pop xiz, inc sp, ret)'),

    ('LABEL_F4C82D', 'SeqPart_BufferSwap',
     'Part buffer swap for editing: exchange data between buffers'),

    ('LABEL_F4C8B6', 'SeqPart_BufferSwapReturn',
     'Buffer swap: return'),

    ('LABEL_F4C8CD', 'SeqPart_PartSelect',
     'Part select: iterate parts, call inner processing for each'),

    ('LABEL_F4C8E4', 'SeqPart_PartSelectLoop',
     'Part select: main iteration loop'),

    ('LABEL_F4C911', 'SeqPart_PartSelectCheck',
     'Part select: check part validity'),

    ('LABEL_F4C918', 'SeqPart_PartSelectSkip',
     'Part select: skip invalid part'),

    ('LABEL_F4C926', 'SeqPart_PartSelectDone',
     'Part select: iteration done'),

    ('LABEL_F4C929', 'SeqPart_PartSelectProcess',
     'Part select: process current part'),

    ('LABEL_F4C953', 'SeqPart_PartSelectFinish',
     'Part select: finish current part'),

    ('LABEL_F4C96F', 'SeqPart_PartSelectReturn',
     'Part select: return path'),

    ('LABEL_F4C97E', 'SeqPart_PartSelectExit',
     'Part select: exit with results'),

    ('LABEL_F4C98A', 'SeqPart_InnerProcess',
     'Inner part processing loop: process single part events'),

    ('LABEL_F4C9DF', 'SeqPart_InnerLoop',
     'Inner process: main event loop'),

    ('LABEL_F4C9EC', 'SeqPart_InnerReadEvent',
     'Inner process: read next event'),

    ('LABEL_F4CA09', 'SeqPart_InnerCheckType',
     'Inner process: check event type for dispatch'),

    ('LABEL_F4CA14', 'SeqPart_InnerCheckNote',
     'Inner process: check if event is note (80-86)'),

    ('LABEL_F4CA23', 'SeqPart_InnerCheck90',
     'Inner process: check for 90 note-on event'),

    ('LABEL_F4CA5B', 'SeqPart_InnerVelAdd',
     'Inner process: add velocity offset (saturate at 0x7F)'),

    ('LABEL_F4CA5F', 'SeqPart_InnerVelAddNeg',
     'Inner process: add negative velocity (clamp at 0)'),

    ('LABEL_F4CA65', 'SeqPart_InnerVelStore',
     'Inner process: store modified velocity via F421B5'),

    ('LABEL_F4CA6B', 'SeqPart_InnerAdvance',
     'Inner process: advance to next event'),

    ('LABEL_F4CA78', 'SeqPart_InnerBoundary',
     'Inner process: boundary check (compare iz vs 9694)'),

    ('LABEL_F4CA7F', 'SeqPart_InnerReturn',
     'Inner process: pop xiz and return'),

    ('LABEL_F4CA81', 'SeqPart_PartVoiceCheck',
     'Part voice check: verify part compatibility via F3F854'),

    ('LABEL_F4CA98', 'SeqPart_VoiceCheckCompare',
     'Voice check: compare 9750 vs 9816'),

    ('LABEL_F4CAD0', 'SeqPart_VoiceCheckDrum',
     'Voice check: drum type detected (D/E/F/10), set error=9'),

    ('LABEL_F4CAD7', 'SeqPart_VoiceCheckOk',
     'Voice check: OK, store part number, call F4CB4A'),

    ('LABEL_F4CAE5', 'SeqPart_VoiceCheckMulti',
     'Voice check: multi-part iteration (parts 1-16)'),

    ('LABEL_F4CAE8', 'SeqPart_VoiceCheckMultiLoop',
     'Voice check: multi-part loop body'),

    ('LABEL_F4CB12', 'SeqPart_VoiceCheckMultiNext',
     'Voice check: advance to next part in multi-check'),

    ('LABEL_F4CB2F', 'SeqPart_VoiceCheckMultiDone',
     'Voice check: multi-part iteration done'),

    ('LABEL_F4CB3E', 'SeqPart_VoiceCheckReturn',
     'Voice check: common return path (call F3FF1A, ret)'),

    ('LABEL_F4CB4A', 'SeqPart_VoiceCheckSetup',
     'Voice check: set up for voice comparison'),

    ('LABEL_F4CBC9', 'SeqPart_VoiceCheckSetupDone',
     'Voice check: setup complete'),

    ('LABEL_F4CBD6', 'SeqPart_VoiceCheckSetupReturn',
     'Voice check: setup return'),

    ('LABEL_F4CBF2', 'SeqPart_VoiceCheckProcess',
     'Voice check: process voice data'),

    ('LABEL_F4CBFD', 'SeqPart_VoiceCheckValidate',
     'Voice check: validate voice type'),

    ('LABEL_F4CC09', 'SeqPart_VoiceCheckComplete',
     'Voice check: processing complete'),

    ('LABEL_F4CC0B', 'SeqPart_VoiceCheckFinal',
     'Voice check: final checks'),

    ('LABEL_F4CC3D', 'SeqPart_VoiceCheckDispatch',
     'Voice check: dispatch by voice type'),

    ('LABEL_F4CC48', 'SeqPart_VoiceCheckModeA',
     'Voice check: mode A processing'),

    ('LABEL_F4CC4A', 'SeqPart_VoiceCheckModeB',
     'Voice check: mode B processing'),

    ('LABEL_F4CC66', 'SeqPart_VoiceCheckModeC',
     'Voice check: mode C processing'),

    ('LABEL_F4CC97', 'SeqPart_VoiceCheckUpdate',
     'Voice check: update voice data'),

    ('LABEL_F4CC9E', 'SeqPart_VoiceCheckStore',
     'Voice check: store voice result'),

    ('LABEL_F4CCA7', 'SeqPart_VoiceCheckCleanup',
     'Voice check: cleanup after check'),

    ('LABEL_F4CCAA', 'SeqPart_VoiceCheckFinish',
     'Voice check: finish and return'),

    ('LABEL_F4CCD4', 'SeqPart_VoiceCheckWalk',
     'Voice check: walk event data'),

    ('LABEL_F4CCEB', 'SeqPart_VoiceCheckWalkLoop',
     'Voice check: walk loop body'),

    ('LABEL_F4CCFA', 'SeqPart_VoiceCheckWalkDone',
     'Voice check: walk done'),

    ('LABEL_F4CD06', 'SeqPart_VoiceCheckWalkReturn',
     'Voice check: walk return path'),

    ('LABEL_F4CD37', 'SeqPart_VoiceCheckWalkAdvance',
     'Voice check: walk advance to next event'),

    ('LABEL_F4CD61', 'SeqPart_VoiceCheckWalkValidate',
     'Voice check: walk validate event'),

    ('LABEL_F4CD70', 'SeqPart_VoiceCheckWalkSkip',
     'Voice check: walk skip non-matching event'),

    ('LABEL_F4CDA5', 'SeqPart_VoiceCheckWalkError',
     'Voice check: walk error exit'),

    ('LABEL_F4CDAF', 'SeqPart_VoiceCheckWalkCleanup',
     'Voice check: walk cleanup'),

    ('LABEL_F4CDCD', 'SeqPart_VoiceCheckWalkFinish',
     'Voice check: walk finish'),

    ('LABEL_F4CDD4', 'SeqPart_VoiceCheckWalkExit',
     'Voice check: walk exit path'),

    ('LABEL_F4CDD6', 'SeqPart_VoiceCheckFinalReturn',
     'Voice check: final return (pop, ret)'),

    ('LABEL_F4CE09', 'SeqPart_VoiceCheckEndCheck',
     'Voice check: end boundary check'),

    ('LABEL_F4CE0D', 'SeqPart_VoiceCheckEndStore',
     'Voice check: end store results'),

    ('LABEL_F4CE18', 'SeqPart_VoiceCheckEndAdvance',
     'Voice check: end advance position'),

    ('LABEL_F4CE23', 'SeqPart_VoiceCheckEndReturn',
     'Voice check: end return'),

    ('LABEL_F4CE31', 'SeqPart_VoiceCheckEndError',
     'Voice check: end error handling'),

    ('LABEL_F4CE37', 'SeqPart_VoiceCheckEndCleanup',
     'Voice check: end cleanup'),

    ('LABEL_F4CE3B', 'SeqPart_VoiceCheckEndExit',
     'Voice check: end exit path'),

    # ==================================================================
    # 2. SeqStep (lines 152224-157440+, 427 labels)
    #    Step recording & event manipulation: step-record note dispatch,
    #    event insertion/deletion, position management, playback state
    #    machine, part compaction, file I/O operations.
    #    Key addresses: 10044/10046=saved position, 9824=step flags,
    #    9994/9992/9996=part numbers, 32578=status code, 8956=state
    # ==================================================================

    ('LABEL_F4CE4D', 'SeqStep_NoteDispatch',
     'Step record note dispatch: check bit0 of 10363, dispatch by event type'),

    ('LABEL_F4CE61', 'SeqStep_NoteReadEvent',
     'Note dispatch: read event via F421A6, dispatch D0-D3/80-86/90/B0/C0'),

    ('LABEL_F4CEAD', 'SeqStep_NoteByteBlock',
     '.byte data block for note dispatch (undecoded instructions)'),

    ('LABEL_F4CF03', 'SeqStep_NoteSetD1',
     'Note dispatch: set counter=2 for D0/D1/D3 events'),

    ('LABEL_F4CF08', 'SeqStep_NoteSetD2',
     'Note dispatch: set counter=3 for D2 (tempo) events'),

    ('LABEL_F4CF0D', 'SeqStep_NoteSetOther',
     'Note dispatch: set counter=5 for other events'),

    ('LABEL_F4CF10', 'SeqStep_NoteConsumeInit',
     'Note consume: init counter and start reading'),

    ('LABEL_F4CF13', 'SeqStep_NoteConsumeLoop',
     'Note consume: read and consume event bytes'),

    ('LABEL_F4CF2E', 'SeqStep_NoteConsumeAdvance',
     'Note consume: advance counter, check if all consumed'),

    ('LABEL_F4CF4C', 'SeqStep_NoteCheckVel',
     'Note consume: check if byte 1, test velocity (0x5F threshold)'),

    ('LABEL_F4CF82', 'SeqStep_NoteVelSave',
     'Note consume: save velocity position to 10012/10018'),

    ('LABEL_F4CFA2', 'SeqStep_NoteVelSkip',
     'Note consume: skip velocity (above threshold)'),

    ('LABEL_F4CFAA', 'SeqStep_NoteVelContinue',
     'Note consume: continue after velocity check'),

    ('LABEL_F4CFB5', 'SeqStep_NoteExit',
     'Note dispatch: exit path (restore saved positions, pop, ret)'),

    ('LABEL_F4CFB9', 'SeqStep_NoteExitRestore',
     'Note dispatch: restore positions from stack'),

    ('LABEL_F4CFC4', 'SeqStep_NoteReturn',
     'Note dispatch: pop xiz, inc sp, ret'),

    ('LABEL_F4CFDA', 'SeqStep_EventProcess',
     'Step record event processing: handle position tracking, event insertion'),

    ('LABEL_F4D047', 'SeqStep_EventPosManage',
     'Step record: position management'),

    ('LABEL_F4D06A', 'SeqStep_EventPosCheck',
     'Step record: position check'),

    ('LABEL_F4D08C', 'SeqStep_EventPosUpdate',
     'Step record: update position after event'),

    ('LABEL_F4D0C8', 'SeqStep_EventPosAdvance',
     'Step record: advance position counter'),

    ('LABEL_F4D0F0', 'SeqStep_EventPosSetD1',
     'Step record: set counter=2 for D0/D1 events'),

    ('LABEL_F4D0F5', 'SeqStep_EventPosSetD2',
     'Step record: set counter=3 for D2 events'),

    ('LABEL_F4D0FA', 'SeqStep_EventPosSetD3',
     'Step record: set counter=5 for D3 events'),

    ('LABEL_F4D0FD', 'SeqStep_EventPosSetNote',
     'Step record: set counter for note events'),

    ('LABEL_F4D100', 'SeqStep_EventPosConsumeLoop',
     'Step record: consume event bytes loop'),

    ('LABEL_F4D117', 'SeqStep_EventPosConsumeCheck',
     'Step record: consume check counter'),

    ('LABEL_F4D127', 'SeqStep_EventPosConsumeAdvance',
     'Step record: consume advance'),

    ('LABEL_F4D171', 'SeqStep_EventPosFinish',
     'Step record: position management finish'),

    ('LABEL_F4D17A', 'SeqStep_EventPosReturn',
     'Step record: position return'),

    ('LABEL_F4D17D', 'SeqStep_EventPosExit',
     'Step record: position exit'),

    ('LABEL_F4D19F', 'SeqStep_EventPosComplete',
     'Step record: position complete'),

    ('LABEL_F4D1A7', 'SeqStep_EventPosDone',
     'Step record: position done'),

    ('LABEL_F4D1B2', 'SeqStep_EventExit',
     'Step record event exit: pop xiz, inc sp, ret'),

    ('LABEL_F4D1C0', 'SeqStep_EventCleanup',
     'Step record event cleanup'),

    ('LABEL_F4D1CB', 'SeqStep_EventRestore',
     'Step record: restore saved positions'),

    ('LABEL_F4D1E1', 'SeqStep_EventStorePos',
     'Step record: store current position'),

    ('LABEL_F4D20D', 'SeqStep_EventSetState',
     'Step record: set state flags'),

    ('LABEL_F4D21C', 'SeqStep_EventAdvancePos',
     'Step record: advance read position'),

    ('LABEL_F4D230', 'SeqStep_VelNoteFwd',
     'Velocity/note modification (forward): modify event values'),

    ('LABEL_F4D268', 'SeqStep_VelNoteFwdApply',
     'Vel/note fwd: apply modification'),

    ('LABEL_F4D277', 'SeqStep_VelNoteBwd',
     'Velocity/note modification (backward): modify event values'),

    ('LABEL_F4D2A1', 'SeqStep_DeleteEvent',
     'Delete event at current position'),

    ('LABEL_F4D2CF', 'SeqStep_DeleteSetD1',
     'Delete event: set counter=2 for D0/D1/D3'),

    ('LABEL_F4D2D4', 'SeqStep_DeleteSetD2',
     'Delete event: set counter=3 for D2'),

    ('LABEL_F4D2D9', 'SeqStep_DeleteSetOther',
     'Delete event: set counter=5 for other events'),

    ('LABEL_F4D2DC', 'SeqStep_DeleteConsumeInit',
     'Delete: init consume counter'),

    ('LABEL_F4D2DE', 'SeqStep_DeleteConsumeLoop',
     'Delete: consume and delete event bytes loop'),

    ('LABEL_F4D2F8', 'SeqStep_DeleteConsumeAdvance',
     'Delete: advance consume counter'),

    ('LABEL_F4D32D', 'SeqStep_DeleteFinish',
     'Delete: finish and update position'),

    ('LABEL_F4D33D', 'SeqStep_DeleteReturn',
     'Delete: return path'),

    ('LABEL_F4D346', 'SeqStep_DeleteCheck',
     'Delete: check result status'),

    ('LABEL_F4D34C', 'SeqStep_DeleteExit',
     'Delete: exit path'),

    ('LABEL_F4D368', 'SeqStep_DeleteCleanup',
     'Delete: cleanup after deletion'),

    ('LABEL_F4D37D', 'SeqStep_DeleteDone',
     'Delete: processing done'),

    ('LABEL_F4D3CD', 'SeqStep_DeleteExitRestore',
     'Delete: exit restoring saved positions'),

    ('LABEL_F4D3D7', 'SeqStep_DeletePopReturn',
     'Delete: pop xiz, inc sp, ret'),

    ('LABEL_F4D3DB', 'SeqStep_TrackChange',
     'Step track change: swap parts between tracks, process part chain'),

    ('LABEL_F4D415', 'SeqStep_TrackChangeCheck',
     'Track change: check source vs dest part numbers'),

    ('LABEL_F4D426', 'SeqStep_TrackChangeCompare',
     'Track change: compare part numbers (9992/9994/9998)'),

    ('LABEL_F4D436', 'SeqStep_TrackChangeClear',
     'Track change: clear counter to 0'),

    ('LABEL_F4D439', 'SeqStep_TrackChangeSetup',
     'Track change: set up part counters for voice check'),

    ('LABEL_F4D45F', 'SeqStep_TrackChangeDrum',
     'Track change: handle drum type parts (D/E/F/10)'),

    ('LABEL_F4D473', 'SeqStep_TrackChangeDrumClear',
     'Track change: drum clear counter'),

    ('LABEL_F4D476', 'SeqStep_TrackChangeDrumSetup',
     'Track change: drum part setup'),

    ('LABEL_F4D495', 'SeqStep_TrackChangeProcess',
     'Track change: process part data'),

    ('LABEL_F4D4A9', 'SeqStep_TrackChangeStore',
     'Track change: store processed data'),

    ('LABEL_F4D4AC', 'SeqStep_TrackChangeUpdate',
     'Track change: update state'),

    ('LABEL_F4D4AF', 'SeqStep_TrackChangeAdvance',
     'Track change: advance to next part'),

    ('LABEL_F4D4D5', 'SeqStep_TrackChangeNext',
     'Track change: process next part in chain'),

    ('LABEL_F4D4DE', 'SeqStep_TrackChangeNonDrum',
     'Track change: non-drum part handling'),

    ('LABEL_F4D4E6', 'SeqStep_TrackChangeLoop',
     'Track change: main processing loop'),

    ('LABEL_F4D4EE', 'SeqStep_TrackChangeLoopCheck',
     'Track change: loop boundary check'),

    ('LABEL_F4D4F3', 'SeqStep_TrackChangeLoopBody',
     'Track change: loop body processing'),

    ('LABEL_F4D52A', 'SeqStep_TrackChangeLoopDone',
     'Track change: loop done'),

    ('LABEL_F4D555', 'SeqStep_TrackChangeLoopReturn',
     'Track change: loop return'),

    ('LABEL_F4D558', 'SeqStep_TrackChangeLoopExit',
     'Track change: loop exit path'),

    ('LABEL_F4D5C4', 'SeqStep_TrackChangeFinish',
     'Track change: finish processing'),

    ('LABEL_F4D5D6', 'SeqStep_TrackChangeComplete',
     'Track change: processing complete'),

    ('LABEL_F4D5DE', 'SeqStep_TrackChangeValidate',
     'Track change: validate results'),

    ('LABEL_F4D5FD', 'SeqStep_TrackChangeFinal',
     'Track change: final cleanup'),

    ('LABEL_F4D65D', 'SeqStep_TrackChangeWriteBack',
     'Track change: write back updated data'),

    ('LABEL_F4D66C', 'SeqStep_TrackChangeWriteDone',
     'Track change: write done'),

    ('LABEL_F4D6B3', 'SeqStep_TrackChangeError',
     'Track change: error handling'),

    ('LABEL_F4D6C7', 'SeqStep_TrackChangeErrorExit',
     'Track change: error exit'),

    ('LABEL_F4D6CA', 'SeqStep_TrackChangeRecover',
     'Track change: recover from error'),

    ('LABEL_F4D713', 'SeqStep_TrackChangeRecoverDone',
     'Track change: recovery done'),

    ('LABEL_F4D727', 'SeqStep_TrackChangeRecoverStore',
     'Track change: recovery store'),

    ('LABEL_F4D72A', 'SeqStep_TrackChangeRecoverReturn',
     'Track change: recovery return'),

    ('LABEL_F4D76F', 'SeqStep_TrackChangeRecoverAdvance',
     'Track change: recovery advance'),

    ('LABEL_F4D78D', 'SeqStep_TrackChangeRecoverLoop',
     'Track change: recovery loop'),

    ('LABEL_F4D7B8', 'SeqStep_TrackChangeRecoverExit',
     'Track change: recovery exit'),

    ('LABEL_F4D7BD', 'SeqStep_TrackChangeExit',
     'Track change: final exit (pop xiz, inc sp, ret)'),

    ('LABEL_F4D7C1', 'SeqStep_MultiTrackProcess',
     'Multi-track step processing loop'),

    ('LABEL_F4D7CA', 'SeqStep_MultiTrackLoop',
     'Multi-track: main processing loop'),

    ('LABEL_F4D7E7', 'SeqStep_MultiTrackCheck',
     'Multi-track: check boundaries'),

    ('LABEL_F4D7EA', 'SeqStep_MultiTrackAdvance',
     'Multi-track: advance to next track'),

    ('LABEL_F4D84A', 'SeqStep_MultiTrackInner',
     'Multi-track: inner processing'),

    ('LABEL_F4D85C', 'SeqStep_MultiTrackCopyCheck',
     'Multi-track: check if copy needed (62001)'),

    ('LABEL_F4D864', 'SeqStep_MultiTrackCleanup',
     'Multi-track: cleanup — save/restore 10360, call F3F8AF'),

    ('LABEL_F4D888', 'SeqStep_PartCopy',
     'Part copy: allocate space, copy data between parts'),

    ('LABEL_F4D8E8', 'SeqStep_PartCopyLoop',
     'Part copy: byte-by-byte copy loop'),

    ('LABEL_F4D8F7', 'SeqStep_PartCopyFinish',
     'Part copy: finish, update references'),

    ('LABEL_F4D93B', 'SeqStep_PartCopyUpdateSrc',
     'Part copy: update source part references'),

    ('LABEL_F4D94F', 'SeqStep_PartCopyClearSrc',
     'Part copy: clear source counter to 0'),

    ('LABEL_F4D952', 'SeqStep_PartCopySetupDest',
     'Part copy: set up destination part'),

    ('LABEL_F4D99D', 'SeqStep_PartCopyComplete',
     'Part copy: copy complete'),

    ('LABEL_F4D9B0', 'SeqStep_VoiceReassign',
     'Voice reassign: reassign voice to different part'),

    ('LABEL_F4D9C8', 'SeqStep_VoiceReassignCheck',
     'Voice reassign: check compatibility'),

    ('LABEL_F4D9CC', 'SeqStep_VoiceReassignSetup',
     'Voice reassign: set up for reassignment'),

    ('LABEL_F4DA04', 'SeqStep_VoiceReassignProcess',
     'Voice reassign: process voice data'),

    ('LABEL_F4DA23', 'SeqStep_VoiceReassignValidate',
     'Voice reassign: validate result'),

    ('LABEL_F4DA30', 'SeqStep_VoiceReassignStore',
     'Voice reassign: store reassigned voice'),

    ('LABEL_F4DA46', 'SeqStep_VoiceReassignUpdate',
     'Voice reassign: update references'),

    ('LABEL_F4DA51', 'SeqStep_VoiceReassignDone',
     'Voice reassign: done'),

    ('LABEL_F4DA67', 'SeqStep_VoiceReassignReturn',
     'Voice reassign: return path'),

    ('LABEL_F4DA6A', 'SeqStep_VoiceReassignExit',
     'Voice reassign: exit'),

    ('LABEL_F4DA7B', 'SeqStep_VoiceReassignError',
     'Voice reassign: error handling'),

    ('LABEL_F4DA7E', 'SeqStep_VoiceReassignCleanup',
     'Voice reassign: cleanup after error'),

    ('LABEL_F4DAFC', 'SeqStep_VoiceReassignFinalExit',
     'Voice reassign: final exit (pop, ret)'),

    ('LABEL_F4DB01', 'SeqStep_EventAdvance',
     'Event advance with validation: advance position, validate'),

    ('LABEL_F4DB1F', 'SeqStep_EventAdvanceCheck',
     'Event advance: check boundary'),

    ('LABEL_F4DB2A', 'SeqStep_EventAdvanceLoop',
     'Event advance: main advance loop'),

    ('LABEL_F4DB33', 'SeqStep_EventAdvanceRead',
     'Event advance: read next byte'),

    ('LABEL_F4DB37', 'SeqStep_EventAdvanceBit7',
     'Event advance: check bit7 of event byte'),

    ('LABEL_F4DB40', 'SeqStep_EventAdvanceStore',
     'Event advance: store position update'),

    ('LABEL_F4DB62', 'SeqStep_EventAdvanceDone',
     'Event advance: advance done'),

    ('LABEL_F4DB7C', 'SeqStep_EventAdvanceReturn',
     'Event advance: return'),

    ('LABEL_F4DB82', 'SeqStep_EventAdvanceError',
     'Event advance: error (set error flag)'),

    ('LABEL_F4DBAE', 'SeqStep_MeasureRead',
     'Measure read procedure: read events for one measure'),

    ('LABEL_F4DC1E', 'SeqStep_MeasureReadLoop',
     'Measure read: main reading loop'),

    ('LABEL_F4DC38', 'SeqStep_MeasureReadCheck',
     'Measure read: check event type'),

    ('LABEL_F4DC50', 'SeqStep_MeasureReadProcess',
     'Measure read: process event data'),

    ('LABEL_F4DC8C', 'SeqStep_MeasureReadDone',
     'Measure read: reading done'),

    ('LABEL_F4DC99', 'SeqStep_SkipToHighBit',
     'Skip to next high-bit event: advance past non-high-bit bytes'),

    ('LABEL_F4DCB0', 'SeqStep_SkipLoop',
     'Skip: main skip loop'),

    ('LABEL_F4DCC5', 'SeqStep_SkipCheck',
     'Skip: check if current byte has bit7 set'),

    ('LABEL_F4DCD4', 'SeqStep_SkipDone',
     'Skip: done, return'),

    ('LABEL_F4DCF4', 'SeqStep_AdvanceHelper1',
     'Event advance helper 1: advance position by one'),

    ('LABEL_F4DD0B', 'SeqStep_AdvanceHelper2',
     'Event advance helper 2: skip non-event bytes'),

    ('LABEL_F4DD20', 'SeqStep_AdvanceHelper2Loop',
     'Advance helper 2: loop body'),

    ('LABEL_F4DD2F', 'SeqStep_AdvanceHelper2Done',
     'Advance helper 2: done'),

    ('LABEL_F4DD4F', 'SeqStep_DecrementPos',
     'Decrement playback position'),

    ('LABEL_F4DD65', 'SeqStep_DecrementCheck',
     'Decrement: check result, update 10022/10016'),

    ('LABEL_F4DD7A', 'SeqStep_DecrementStore',
     'Decrement: store result (set 9826=1)'),

    ('LABEL_F4DD80', 'SeqStep_WalkWithCallback',
     'Walk events with callback: iterate events, call callback function'),

    ('LABEL_F4DD94', 'SeqStep_WalkCbLoop',
     'Walk callback: main loop'),

    ('LABEL_F4DDA3', 'SeqStep_WalkCbCheck81',
     'Walk callback: check for 0x81 marker'),

    ('LABEL_F4DDAC', 'SeqStep_WalkCbCountCheck',
     'Walk callback: check count (2 markers = done)'),

    ('LABEL_F4DDB3', 'SeqStep_WalkCbReturn',
     'Walk callback: return (pop, inc sp, ret)'),

    ('LABEL_F4DDB9', 'SeqStep_WalkInner',
     'Inner event walk loop: walk single event set'),

    ('LABEL_F4DDBC', 'SeqStep_WalkInnerLoop',
     'Walk inner: main loop body'),

    ('LABEL_F4DDC8', 'SeqStep_WalkInnerProcess',
     'Walk inner: process event, check bit7 for end'),

    ('LABEL_F4DDD3', 'SeqStep_WalkInnerReturn',
     'Walk inner: pop xiz, ret'),

    ('LABEL_F4DDD5', 'SeqStep_WalkReadNext',
     'Walk: read next event position from 10433'),

    ('LABEL_F4DDED', 'SeqStep_WalkUpdatePos',
     'Walk: update position (store to 10431)'),

    ('LABEL_F4DDF9', 'SeqStep_WalkAdvancePos',
     'Walk: advance position counter (10433)'),

    ('LABEL_F4DDFF', 'SeqStep_WalkAdvanceDone',
     'Walk: advance done, return hl=0'),

    ('LABEL_F4DE02', 'SeqStep_WalkReadByte',
     'Walk: read byte at current position via F41CB1'),

    ('LABEL_F4DE12', 'SeqStep_InsertEvent',
     'Insert event at current position'),

    ('LABEL_F4DE1E', 'SeqStep_InsertEventInner',
     'Insert event: inner insertion logic'),

    ('LABEL_F4DE50', 'SeqStep_InsertValidate',
     'Insert: validate insertion point'),

    ('LABEL_F4DEAB', 'SeqStep_InsertError',
     'Insert: error exit'),

    ('LABEL_F4DEAF', 'SeqStep_InsertDone',
     'Insert: insertion done'),

    ('LABEL_F4DEBC', 'SeqStep_PrepareReadBack',
     'Prepare position for read-back'),

    ('LABEL_F4DEE8', 'SeqStep_PrepareCheck',
     'Prepare read-back: check state'),

    ('LABEL_F4DEEE', 'SeqStep_PrepareDone',
     'Prepare read-back: done'),

    ('LABEL_F4DEFF', 'SeqStep_DeleteShiftEvents',
     'Delete/shift events: remove event bytes and shift remaining'),

    ('LABEL_F4DF2E', 'SeqStep_DeleteShiftLoop',
     'Delete/shift: main shift loop'),

    ('LABEL_F4DF3A', 'SeqStep_DeleteShiftAdvance',
     'Delete/shift: advance position'),

    ('LABEL_F4DF75', 'SeqStep_DeleteShiftDone',
     'Delete/shift: shifting done'),

    ('LABEL_F4DFA8', 'SeqStep_DeleteShiftUpdate',
     'Delete/shift: update references'),

    ('LABEL_F4DFC6', 'SeqStep_DeleteShiftReturn',
     'Delete/shift: return path'),

    ('LABEL_F4DFE6', 'SeqStep_DeleteShiftError',
     'Delete/shift: error handling'),

    ('LABEL_F4DFED', 'SeqStep_DeleteShiftCleanup',
     'Delete/shift: cleanup'),

    ('LABEL_F4DFF1', 'SeqStep_DeleteShiftExit',
     'Delete/shift: exit path'),

    ('LABEL_F4DFFF', 'SeqStep_DeleteShiftFinal',
     'Delete/shift: final operations'),

    ('LABEL_F4E077', 'SeqStep_BoundaryCheckA',
     'Boundary check A: test position limits'),

    ('LABEL_F4E079', 'SeqStep_BoundaryCheckB',
     'Boundary check B: additional limit test'),

    ('LABEL_F4E07B', 'SeqStep_BoundaryReturn',
     'Boundary check: return'),

    ('LABEL_F4E08E', 'SeqStep_BoundaryProcess',
     'Boundary: process boundary condition'),

    ('LABEL_F4E093', 'SeqStep_BoundaryAdvance',
     'Boundary: advance past boundary'),

    ('LABEL_F4E0C6', 'SeqStep_BoundaryDone',
     'Boundary: processing done'),

    ('LABEL_F4E0C9', 'SeqStep_BoundaryExit',
     'Boundary: exit path'),

    ('LABEL_F4E126', 'SeqStep_BoundaryError',
     'Boundary: error handling'),

    ('LABEL_F4E17F', 'SeqStep_BoundaryFinal',
     'Boundary: final operations'),

    ('LABEL_F4E183', 'SeqStep_SkipIfLeftFlag',
     'Skip event if left-hand flag set in 10361'),

    ('LABEL_F4E194', 'SeqStep_SkipIfLeftCheck',
     'Skip if left: check flag value'),

    ('LABEL_F4E197', 'SeqStep_SkipIfLeftDone',
     'Skip if left: done, return'),

    ('LABEL_F4E1A0', 'SeqStep_SkipIfLeftReturn',
     'Skip if left: return hl value'),

    ('LABEL_F4E1A4', 'SeqStep_SkipInvertedA',
     'Skip event with inverted return A'),

    ('LABEL_F4E1B1', 'SeqStep_SkipInvertedADone',
     'Skip inverted A: done'),

    ('LABEL_F4E1B4', 'SeqStep_SkipInvertedB',
     'Skip event with inverted return B'),

    ('LABEL_F4E1C1', 'SeqStep_SkipInvertedBDone',
     'Skip inverted B: done'),

    ('LABEL_F4E1C4', 'SeqStep_AdvanceOneEvent',
     'Advance one event: consume current + skip to next'),

    ('LABEL_F4E1E0', 'SeqStep_AdvanceOneDone',
     'Advance one: done, return hl=0xFFFF'),

    ('LABEL_F4E1E4', 'SeqStep_AdvanceOneReturn',
     'Advance one: return hl=0'),

    ('LABEL_F4E1E7', 'SeqStep_SkipToMeasure',
     'Skip to next measure boundary: advance until bit7 set'),

    ('LABEL_F4E1F4', 'SeqStep_SkipToMeasureLoop',
     'Skip to measure: loop reading events via F3FC17'),

    ('LABEL_F4E202', 'SeqStep_SkipThreeEvents',
     'Skip three consecutive events via F3FAF3'),

    ('LABEL_F4E22B', 'SeqStep_SkipThreeError',
     'Skip three events: error exit (hl=0xFFFF)'),

    ('LABEL_F4E22F', 'SeqStep_SkipThreeReturn',
     'Skip three events: return hl=0'),

    ('LABEL_F4E232', 'SeqStep_ProcessC0',
     'Process C0 (program change) event with parameters'),

    ('LABEL_F4E24E', 'SeqStep_ProcessC0SavePos',
     'Process C0: save position, skip three events'),

    ('LABEL_F4E271', 'SeqStep_ProcessC0Check',
     'Process C0: check parameter count'),

    ('LABEL_F4E27C', 'SeqStep_ProcessC0ReadParam',
     'Process C0: read parameter byte, validate'),

    ('LABEL_F4E29B', 'SeqStep_ProcessC0Error',
     'Process C0: error exit (hl=0xFFFF)'),

    ('LABEL_F4E2A0', 'SeqStep_ProcessC0Advance',
     'Process C0: advance counter, read next parameter'),

    ('LABEL_F4E2AF', 'SeqStep_ProcessC0Done',
     'Process C0: done (hl=0)'),

    ('LABEL_F4E2B1', 'SeqStep_ProcessC0Return',
     'Process C0: pop xiz, inc sp, ret'),

    ('LABEL_F4E2B5', 'SeqStep_ProcessB0',
     'Process B0 (control change) event with chord data'),

    ('LABEL_F4E311', 'SeqStep_ProcessB0Check',
     'Process B0: check control type'),

    ('LABEL_F4E31E', 'SeqStep_ProcessB0Advance',
     'Process B0: advance position'),

    ('LABEL_F4E324', 'SeqStep_ProcessB0Validate',
     'Process B0: validate event data'),

    ('LABEL_F4E32F', 'SeqStep_ProcessB0Skip',
     'Process B0: skip unhandled control'),

    ('LABEL_F4E33A', 'SeqStep_ProcessB0Done',
     'Process B0: processing done'),

    ('LABEL_F4E34C', 'SeqStep_ProcessB0Return',
     'Process B0: return path'),

    ('LABEL_F4E358', 'SeqStep_ProcessB0Error',
     'Process B0: error exit'),

    ('LABEL_F4E35D', 'SeqStep_ProcessB0Cleanup',
     'Process B0: cleanup after processing'),

    ('LABEL_F4E36C', 'SeqStep_ProcessB0Exit',
     'Process B0: exit path'),

    ('LABEL_F4E36E', 'SeqStep_ProcessB0Final',
     'Process B0: final operations'),

    ('LABEL_F4E372', 'SeqStep_ParseRhythm',
     'Parse rhythm/chord data from event stream'),

    ('LABEL_F4E3D1', 'SeqStep_ParseRhythmLoop',
     'Parse rhythm: main loop'),

    ('LABEL_F4E3DC', 'SeqStep_ParseRhythmCheck',
     'Parse rhythm: check event type'),

    ('LABEL_F4E3E0', 'SeqStep_ParseRhythmAdvance',
     'Parse rhythm: advance position'),

    ('LABEL_F4E3F5', 'SeqStep_ParseRhythmProcess',
     'Parse rhythm: process rhythm event'),

    ('LABEL_F4E402', 'SeqStep_ParseRhythmStore',
     'Parse rhythm: store rhythm data'),

    ('LABEL_F4E40B', 'SeqStep_ParseRhythmDone',
     'Parse rhythm: processing done'),

    ('LABEL_F4E411', 'SeqStep_ParseRhythmReturn',
     'Parse rhythm: return path'),

    ('LABEL_F4E421', 'SeqStep_ParseRhythmError',
     'Parse rhythm: error exit'),

    ('LABEL_F4E452', 'SeqStep_ParseRhythmSkip',
     'Parse rhythm: skip non-rhythm event'),

    ('LABEL_F4E45D', 'SeqStep_ParseRhythmValidate',
     'Parse rhythm: validate parsed data'),

    ('LABEL_F4E463', 'SeqStep_ParseRhythmCleanup',
     'Parse rhythm: cleanup'),

    ('LABEL_F4E46F', 'SeqStep_ParseRhythmExit',
     'Parse rhythm: exit path'),

    ('LABEL_F4E49C', 'SeqStep_ParseRhythmFinal',
     'Parse rhythm: final operations'),

    ('LABEL_F4E4A0', 'SeqStep_ParseRhythmComplete',
     'Parse rhythm: complete'),

    ('LABEL_F4E4A3', 'SeqStep_CommitEvent',
     'Commit current event to output position'),

    ('LABEL_F4E4C1', 'SeqStep_ProcessC0Ext',
     'Process C0 extended (with voice flag check)'),

    ('LABEL_F4E4DD', 'SeqStep_ProcessC0ExtCheck',
     'C0 extended: check voice flag'),

    ('LABEL_F4E500', 'SeqStep_ProcessC0ExtProcess',
     'C0 extended: process event'),

    ('LABEL_F4E506', 'SeqStep_ProcessC0ExtSkip',
     'C0 extended: skip event'),

    ('LABEL_F4E511', 'SeqStep_ProcessC0ExtDone',
     'C0 extended: done'),

    ('LABEL_F4E530', 'SeqStep_ProcessC0ExtReturn',
     'C0 extended: return'),

    ('LABEL_F4E535', 'SeqStep_ProcessC0ExtExit',
     'C0 extended: exit path'),

    ('LABEL_F4E544', 'SeqStep_ProcessC0ExtFinal',
     'C0 extended: final operations'),

    ('LABEL_F4E546', 'SeqStep_ProcessC0ExtComplete',
     'C0 extended: complete'),

    ('LABEL_F4E54A', 'SeqStep_ProcessB0Ext',
     'Process B0 extended (with voice flag check)'),

    ('LABEL_F4E5AC', 'SeqStep_ProcessB0ExtCheck',
     'B0 extended: check voice flag'),

    ('LABEL_F4E5B7', 'SeqStep_ProcessB0ExtProcess',
     'B0 extended: process event'),

    ('LABEL_F4E5BB', 'SeqStep_ProcessB0ExtSkip',
     'B0 extended: skip event'),

    ('LABEL_F4E5C1', 'SeqStep_ProcessB0ExtDone',
     'B0 extended: done'),

    ('LABEL_F4E5D9', 'SeqStep_ProcessB0ExtReturn',
     'B0 extended: return'),

    ('LABEL_F4E5F8', 'SeqStep_ProcessB0ExtExit',
     'B0 extended: exit path'),

    ('LABEL_F4E5FB', 'SeqStep_ProcessB0ExtFinal',
     'B0 extended: final operations'),

    ('LABEL_F4E5FF', 'SeqStep_ProcessB0ExtComplete',
     'B0 extended: complete'),

    ('LABEL_F4E622', 'SeqStep_ProcessB0ExtCleanup',
     'B0 extended: cleanup'),

    ('LABEL_F4E635', 'SeqStep_MainTimerTick',
     'Main timer tick: dispatch based on mode (8956), call subsystems'),

    ('LABEL_F4E65A', 'SeqStep_TimerDispatchA',
     'Timer dispatch A: lookup jump table at E44F00 by mode (8956)'),

    ('LABEL_F4E66F', 'SeqStep_TimerDispatchB',
     'Timer dispatch B: lookup jump table at E44F5C by mode'),

    ('LABEL_F4E684', 'SeqStep_TimerDispatchC',
     'Timer dispatch C: lookup jump table at E44FB8 by mode'),

    ('LABEL_F4E699', 'SeqStep_PlaybackStateMachine',
     'Playback state machine: handle tempo, fill, pattern changes'),

    ('LABEL_F4E6AA', 'SeqStep_PlaybackDecrCount',
     'Playback: decrement tempo counter (7518)'),

    ('LABEL_F4E6D5', 'SeqStep_PlaybackCheckFill',
     'Playback: check fill flag (bit4 of 1057)'),

    ('LABEL_F4E6E1', 'SeqStep_PlaybackCallFill',
     'Playback: call fill handler (F3A125)'),

    ('LABEL_F4E6E7', 'SeqStep_PlaybackCheckBeat',
     'Playback: check beat flag (bit1 of 1057)'),

    ('LABEL_F4E6F3', 'SeqStep_PlaybackCheckPattern',
     'Playback: check pattern change (10420)'),

    ('LABEL_F4E701', 'SeqStep_PlaybackNoAction',
     'Playback: no action needed (l=0)'),

    ('LABEL_F4E705', 'SeqStep_PlaybackCheck10408',
     'Playback: check 10408 (running playback)'),

    ('LABEL_F4E713', 'SeqStep_PlaybackCheckFill2',
     'Playback: second fill check (bit4)'),

    ('LABEL_F4E71F', 'SeqStep_PlaybackCallExtFill',
     'Playback: call extended fill handler (F3A1FA)'),

    ('LABEL_F4E723', 'SeqStep_PlaybackResultDispatch',
     'Playback: dispatch by result code (1/2/3/4)'),

    ('LABEL_F4E735', 'SeqStep_PlaybackCheckBeat2',
     'Playback: second beat check'),

    ('LABEL_F4E741', 'SeqStep_PlaybackCheckTiming',
     'Playback: timing check (10410/10420/10437)'),

    ('LABEL_F4E757', 'SeqStep_PlaybackCallPattern',
     'Playback: call pattern handler (F3A342)'),

    ('LABEL_F4E75D', 'SeqStep_PlaybackResult1',
     'Playback result 1: call F3CAC1'),

    ('LABEL_F4E763', 'SeqStep_PlaybackResult4',
     'Playback result 4: call F4384C'),

    ('LABEL_F4E769', 'SeqStep_PlaybackResult2',
     'Playback result 2: call F4382A'),

    ('LABEL_F4E76F', 'SeqStep_PlaybackResult3',
     'Playback result 3: call F437FA'),

    ('LABEL_F4E773', 'SeqStep_PlaybackReturn',
     'Playback: pop and return'),

    ('LABEL_F4E777', 'SeqStep_PlaybackNop',
     'Playback: ret (no-op handler)'),

    ('LABEL_F4E778', 'SeqStep_PlaybackMaxPart',
     '.byte 0x0E (max part number constant)'),

    ('LABEL_F4E779', 'SeqStep_FindLastUsedPart',
     'Find last used part: search backward from 0x4D8'),

    ('LABEL_F4E798', 'SeqStep_FindLastLoop',
     'Find last: compare and swap loop'),

    ('LABEL_F4E7A7', 'SeqStep_FindLastReturn',
     'Find last: inc sp, ret'),

    ('LABEL_F4E7AA', 'SeqStep_FindAndCompactEntry',
     'Find and compact entry point: find first empty, jump to compact'),

    ('LABEL_F4E7B4', 'SeqStep_FindAndCompact',
     'Find and compact parts: defragment part table'),

    ('LABEL_F4E7DD', 'SeqStep_CompactLoop',
     'Compact: main swap loop'),

    ('LABEL_F4E7EE', 'SeqStep_CompactDone',
     'Compact: done, pop iz, inc sp, ret'),

    ('LABEL_F4E80D', 'SeqStep_SearchBackward',
     'Search backward for active part (from wa, decrement)'),

    ('LABEL_F4E810', 'SeqStep_SearchBackwardLoop',
     'Search backward: main loop'),

    ('LABEL_F4E81D', 'SeqStep_SearchBackwardDone',
     'Search backward: done'),

    ('LABEL_F4E821', 'SeqStep_SearchForward',
     'Search forward for empty part (from wa, increment)'),

    ('LABEL_F4E824', 'SeqStep_SearchForwardLoop',
     'Search forward: main loop'),

    ('LABEL_F4E836', 'SeqStep_SearchForwardDone',
     'Search forward: done'),

    ('LABEL_F4E83A', 'SeqStep_SwapTwoParts',
     'Swap two parts: copy data, update refs'),

    ('LABEL_F4E878', 'SeqStep_CopyPartData',
     'Copy part sample data (256 bytes)'),

    ('LABEL_F4E898', 'SeqStep_CopyPartReturn',
     'Copy part data: return'),

    ('LABEL_F4E8BD', 'SeqStep_UpdateRefsAfterSwap',
     'Update song references after part swap'),

    ('LABEL_F4E8D9', 'SeqStep_UpdateRefsLoop',
     'Update refs: main loop'),

    ('LABEL_F4E8DC', 'SeqStep_UpdateRefsCheck',
     'Update refs: check part match'),

    ('LABEL_F4E8DF', 'SeqStep_UpdateRefsAdvance',
     'Update refs: advance to next ref'),

    ('LABEL_F4E914', 'SeqStep_UpdateRefsDone',
     'Update refs: done'),

    ('LABEL_F4E926', 'SeqStep_UpdateRefsReturn',
     'Update refs: return'),

    ('LABEL_F4E92A', 'SeqStep_UpdateForwardLinks',
     'Update forward chain links after swap'),

    ('LABEL_F4E948', 'SeqStep_UpdateLinksLoop',
     'Update links: main loop'),

    ('LABEL_F4E94B', 'SeqStep_UpdateLinksCheck',
     'Update links: check link match'),

    ('LABEL_F4E94E', 'SeqStep_UpdateLinksAdvance',
     'Update links: advance to next link'),

    ('LABEL_F4E97D', 'SeqStep_UpdateLinksDone',
     'Update links: done'),

    ('LABEL_F4E98F', 'SeqStep_UpdateLinksReturn',
     'Update links: return'),

    ('LABEL_F4E993', 'SeqStep_RebuildPartChain',
     'Rebuild part chain from scratch'),

    ('LABEL_F4E9AF', 'SeqStep_RebuildLoop',
     'Rebuild chain: main loop'),

    ('LABEL_F4E9F3', 'SeqStep_RebuildCheck',
     'Rebuild chain: check part status'),

    ('LABEL_F4EA27', 'SeqStep_RebuildAdvance',
     'Rebuild chain: advance to next part'),

    ('LABEL_F4EA41', 'SeqStep_RebuildDone',
     'Rebuild chain: done'),

    ('LABEL_F4EA5B', 'SeqStep_RebuildReturn',
     'Rebuild chain: return'),

    ('LABEL_F4EA5F', 'SeqStep_ByteBlockEA5F',
     'Large .byte data block (undecoded, reinit part table after compaction)'),

    ('LABEL_F4EAD7', 'SeqStep_ReinitPartTable',
     'Reinitialize part table after compaction'),

    ('LABEL_F4EB46', 'SeqStep_ReinitLoop',
     'Reinit table: loop setting up parts 1-10'),

    ('LABEL_F4EB66', 'SeqStep_MemAllocWrapper',
     'Memory allocation wrapper: call Malloc, optionally Memset'),

    ('LABEL_F4EB8C', 'SeqStep_MemAllocFail',
     'Memory alloc: allocation failed (set error 0x0003)'),

    ('LABEL_F4EB93', 'SeqStep_MemAllocReturn',
     'Memory alloc: return xhl=xiz (allocated pointer)'),

    ('LABEL_F4EE7D', 'SeqStep_FileReadSetup',
     'File read setup: initialize for file read operation'),

    ('LABEL_F4EE87', 'SeqStep_FileReadCheck',
     'File read: check file handle validity'),

    ('LABEL_F4EE96', 'SeqStep_FileReadProcess',
     'File read: process read operation'),

    ('LABEL_F4EEC6', 'SeqStep_FileReadAdvance',
     'File read: advance buffer position'),

    ('LABEL_F4EED0', 'SeqStep_FileReadLoop',
     'File read: main read loop'),

    ('LABEL_F4EEDF', 'SeqStep_FileReadDone',
     'File read: reading done'),

    ('LABEL_F4EF02', 'SeqStep_FileReadReturn',
     'File read: return'),

    ('LABEL_F4EF11', 'SeqStep_FileReadError',
     'File read: error handling'),

    ('LABEL_F4EF1D', 'SeqStep_FileReadCleanup',
     'File read: cleanup'),

    ('LABEL_F4EF2E', 'SeqStep_FileReadComplete',
     'File read: complete, call vtable method'),

    ('LABEL_F4EF50', 'SeqStep_FileReadVtableFail',
     'File read: vtable call failed (hl=0xFFFF)'),

    ('LABEL_F4EF53', 'SeqStep_FileReadVtableReturn',
     'File read: vtable return (inc sp, ret)'),

    ('LABEL_F4EF56', 'SeqStep_ByteBlockEF56',
     '.byte data block (undecoded file operation code)'),

    ('LABEL_F4EFA9', 'SeqStep_FileWriteSetup',
     'File write setup: check handle, call vtable write method'),

    ('LABEL_F4EFB8', 'SeqStep_FileWriteNoHandle',
     'File write: no handle (set error 0x0011)'),

    ('LABEL_F4EFC4', 'SeqStep_FileWriteCheckMode',
     'File write: check write mode (bit1 of handle+4)'),

    ('LABEL_F4EFD5', 'SeqStep_FileWriteProcess',
     'File write: call vtable write method'),

    ('LABEL_F4EFFC', 'SeqStep_FileWriteFail',
     'File write: write failed (hl=0xFFFF)'),

    ('LABEL_F4EFFF', 'SeqStep_FileWriteReturn',
     'File write: inc sp, ret'),

    ('LABEL_F4F002', 'SeqStep_ByteBlockF002',
     '.byte data block (undecoded file operation code)'),

    ('LABEL_F4F067', 'SeqStep_FileCloseInner',
     'File close inner: cleanup file handle'),

    ('LABEL_F4F08B', 'SeqStep_FileCloseCheck',
     'File close: check handle validity'),

    ('LABEL_F4F098', 'SeqStep_FileCloseProcess',
     'File close: process close operation'),

    ('LABEL_F4F0B9', 'SeqStep_FileCloseReturn',
     'File close: return'),

    ('LABEL_F4F0F9', 'SeqStep_FileCloseCleanup',
     'File close: cleanup resources'),

    ('LABEL_F4F116', 'SeqStep_FileCloseDone',
     'File close: done'),

    ('LABEL_F4F11B', 'SeqStep_FileCloseComplete',
     'File close: complete'),

    ('LABEL_F4F11D', 'SeqStep_FileCloseFinal',
     'File close: final operations'),

    ('LABEL_F4F121', 'SeqStep_FileCloseExit',
     'File close: exit path'),

    ('LABEL_F4F205', 'SeqStep_FileNopA',
     'File: no-op return A (ret)'),

    ('LABEL_F4F206', 'SeqStep_FileNopB',
     'File: no-op return B (ret)'),

    ('LABEL_F4F207', 'SeqStep_FreeMemory',
     'Free memory: call Free(), return hl=0'),

    ('LABEL_F4F214', 'SeqStep_MallocWrapper',
     'Malloc wrapper: call Malloc(wa) for size from stack'),

    ('LABEL_F4F237', 'SeqStep_FileOpenSetupVtable',
     'File open: set up vtable, call method at offset+32'),

    ('LABEL_F4F245', 'SeqStep_ByteBlockF245',
     '.byte data block (undecoded file operation code)'),

    ('LABEL_F4F33E', 'SeqStep_FileSeekSetup',
     'File seek setup: validate handle, begin seek'),

    ('LABEL_F4F34E', 'SeqStep_FileSeekNoHandle',
     'File seek: no handle (set error 0x0011)'),

    ('LABEL_F4F359', 'SeqStep_FileSeekProcess',
     'File seek: process seek operation'),

    ('LABEL_F4F374', 'SeqStep_FileSeekValidate',
     'File seek: validate seek position'),

    ('LABEL_F4F386', 'SeqStep_FileSeekCheck',
     'File seek: check bounds'),

    ('LABEL_F4F395', 'SeqStep_FileSeekAdvance',
     'File seek: advance to target position'),

    ('LABEL_F4F3AA', 'SeqStep_FileSeekDone',
     'File seek: seeking done'),

    ('LABEL_F4F3BF', 'SeqStep_FileSeekReturn',
     'File seek: return'),

    ('LABEL_F4F3C2', 'SeqStep_FileSeekUpdate',
     'File seek: update file position'),

    ('LABEL_F4F3D0', 'SeqStep_FileSeekStore',
     'File seek: store new position'),

    ('LABEL_F4F3DD', 'SeqStep_FileSeekComplete',
     'File seek: complete'),

    ('LABEL_F4F3EA', 'SeqStep_FileSeekFinal',
     'File seek: final operations'),

    ('LABEL_F4F3F6', 'SeqStep_FileSeekExit',
     'File seek: exit path'),

    ('LABEL_F4F403', 'SeqStep_FileSeekError',
     'File seek: error handling'),

    ('LABEL_F4F421', 'SeqStep_FileSeekCleanup',
     'File seek: cleanup'),

    ('LABEL_F4F477', 'SeqStep_FileTellSetup',
     'File tell: get current position'),

    ('LABEL_F4F47D', 'SeqStep_FileTellReturn',
     'File tell: return position'),

    ('LABEL_F4F4AE', 'SeqStep_FileTellProcess',
     'File tell: process tell operation'),

    ('LABEL_F4F4DA', 'SeqStep_FileTellDone',
     'File tell: done'),

    ('LABEL_F4F508', 'SeqStep_FileTellComplete',
     'File tell: complete'),

    ('LABEL_F4F526', 'SeqStep_FileTellExit',
     'File tell: exit path'),

    ('LABEL_F4F52A', 'SeqStep_FileTellFinal',
     'File tell: final operations'),

    ('LABEL_F4F5E4', 'SeqStep_FileIoHelper',
     'File I/O helper: common file operation support'),

    ('LABEL_F4F5FD', 'SeqStep_FileIoCheck',
     'File I/O: check operation status'),

    ('LABEL_F4F611', 'SeqStep_FileIoProcess',
     'File I/O: process operation'),

    ('LABEL_F4F639', 'SeqStep_FileIoAdvance',
     'File I/O: advance buffer'),

    ('LABEL_F4F657', 'SeqStep_FileIoDone',
     'File I/O: operation done'),

    ('LABEL_F4F667', 'SeqStep_FileIoReturn',
     'File I/O: return'),

    ('LABEL_F4F681', 'SeqStep_FileIoError',
     'File I/O: error handling'),

    ('LABEL_F4F68C', 'SeqStep_FileIoCleanup',
     'File I/O: cleanup'),

    ('LABEL_F4F696', 'SeqStep_FileIoExit',
     'File I/O: exit path'),

    ('LABEL_F4F6A8', 'SeqStep_FileIoComplete',
     'File I/O: complete'),

    ('LABEL_F4F6C1', 'SeqStep_FileIoFinal',
     'File I/O: final operations'),

    ('LABEL_F4F6D0', 'SeqStep_FileIoUpdate',
     'File I/O: update state'),

    ('LABEL_F4F6ED', 'SeqStep_FileIoStore',
     'File I/O: store result'),

    ('LABEL_F4F6FF', 'SeqStep_FileIoValidate',
     'File I/O: validate result'),

    ('LABEL_F4F70C', 'SeqStep_FileIoLoop',
     'File I/O: main processing loop'),

    ('LABEL_F4F711', 'SeqStep_FileIoLoopReturn',
     'File I/O: loop return'),

    ('LABEL_F4F793', 'SeqStep_FileIoSetSuccess',
     'File I/O: set success flag'),

    ('LABEL_F4F79A', 'SeqStep_FileIoRetryLoop',
     'File I/O: retry loop for sector reads'),

    ('LABEL_F4F7C8', 'SeqStep_FileIoRetryCheck',
     'File I/O: retry check'),

    ('LABEL_F4F7EF', 'SeqStep_FileIoSetupResult',
     'File I/O: set up result structure'),

    ('LABEL_F4F824', 'SeqStep_FileIoSetFlag',
     'File I/O: set DMA flag at 0x03E3E0'),

    ('LABEL_F4F826', 'SeqStep_FileIoPopReturn',
     'File I/O: pop xiz, inc sp, ret'),

    ('LABEL_F4F82A', 'SeqStep_FileIoClearStatus',
     'File I/O: clear status byte'),

    ('LABEL_F4F83A', 'SeqStep_FileBufferSetup',
     'File buffer setup: allocate and initialize I/O buffer'),

    ('LABEL_F4F880', 'SeqStep_FileBufferAlloc',
     'File buffer: allocate memory'),

    ('LABEL_F4F8BF', 'SeqStep_FileBufferInit',
     'File buffer: initialize buffer fields'),

    ('LABEL_F4F8CE', 'SeqStep_FileBufferCheck',
     'File buffer: check allocation result'),

    ('LABEL_F4F8D9', 'SeqStep_FileBufferDone',
     'File buffer: initialization done'),

    ('LABEL_F4F8F6', 'SeqStep_FileBufferReturn',
     'File buffer: return'),

    ('LABEL_F4F904', 'SeqStep_FileBufferError',
     'File buffer: error handling'),

    ('LABEL_F4F913', 'SeqStep_FileBufferCleanup',
     'File buffer: cleanup'),

    ('LABEL_F4F916', 'SeqStep_FileBufferExit',
     'File buffer: exit path'),

    ('LABEL_F4F91A', 'SeqStep_FileBufferFinal',
     'File buffer: final operations'),

    ('LABEL_F4F976', 'SeqStep_FileSectorRead',
     'File sector read: read sector data from storage'),

    ('LABEL_F4F996', 'SeqStep_FileSectorProcess',
     'File sector: process read data'),

    ('LABEL_F4F9DE', 'SeqStep_FileSectorDone',
     'File sector: reading done'),

    ('LABEL_F4FA59', 'SeqStep_FileSectorComplete',
     'File sector: complete'),

    ('LABEL_F4FABE', 'SeqStep_FileSectorReturn',
     'File sector: return'),

    ('LABEL_F4FBA5', 'SeqStep_FileSectorError',
     'File sector: error handling'),

    ('LABEL_F4FBCE', 'SeqStep_FileSectorCleanup',
     'File sector: cleanup'),

    ('LABEL_F4FBDC', 'SeqStep_FileSectorExit',
     'File sector: exit path'),

    ('LABEL_F4FC1E', 'SeqStep_FileSectorFinal',
     'File sector: final operations'),

    ('LABEL_F4FC5F', 'SeqStep_FileSectorUpdate',
     'File sector: update buffer state'),

    ('LABEL_F4FC6C', 'SeqStep_FileSectorStore',
     'File sector: store sector data'),

    ('LABEL_F4FC85', 'SeqStep_FileSectorValidate',
     'File sector: validate data'),

    ('LABEL_F4FC91', 'SeqStep_FileSectorCheck',
     'File sector: check result'),

    ('LABEL_F4FCA1', 'SeqStep_FileSectorAdvance',
     'File sector: advance to next sector'),

    ('LABEL_F4FCA8', 'SeqStep_FileSectorLoop',
     'File sector: sector read loop'),

    ('LABEL_F4FCAD', 'SeqStep_FileSectorPopReturn',
     'File sector: pop and return'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found (as definition), skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu/kn5000_v10_program.s')


if __name__ == '__main__':
    main()
