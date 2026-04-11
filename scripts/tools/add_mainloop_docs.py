#!/usr/bin/env python3
"""Add documentation header to the MainLoop routine."""

import re

MAINLOOP_DOCS = """; =============================================================================
; MainLoop - Firmware Main Processing Loop (EF1248)
; =============================================================================
; Called after boot initialization completes. Runs indefinitely, processing
; all firmware subsystems in a fixed order each iteration.
;
; The loop is organized into phases, each gated by timer flags in RAM (0x13,04):
;   - Bits 0-7 of the timer flag word control which subsystem groups run
;   - tset_dd16 atomically tests and sets each bit (preventing re-entry)
;   - Timer ISR periodically clears bits to schedule the next iteration
;
; PHASE 1: Input Processing (gated by bit 0 of 0x22,04)
;   Boot_CallInitHandlers - Re-entrant timer/init handler dispatch
;   MidiChannel_ProcessOutputState - Process MIDI output channel state changes
;   AccWrap_FlagSync - Synchronize accompaniment wrapper flags
;   MidiParam_ProcessDeltas - Delta-debounce filter for encoder parameters
;   CPanel_RX_ProcessOrInit - Receive/process control panel serial data
;   Encoder_TimingAndOutput - Encoder timing management and output formatting
;   MidiChannel_ScanPending - Scan for pending MIDI channel changes
;
; PHASE 2: Sequencer Core
;   Seq_TickWrapper - Advance sequencer by one tick (if mode > 7)
;   Seq_EventProcessingTick - Process pending sequencer events (called 5x/loop)
;   SeqStep_MainTimerTick - Step sequencer timer processing
;
; PHASE 3: Voice and Effects Reset (conditional)
;   SeqMain_InitBuffer - Reset sequencer buffer on voice/effect change
;   Voice_InitializeAll - Reinitialize all voice parameters
;   MIDI_BroadcastPitchReset - Reset pitch bend on all channels
;
; PHASE 4: MIDI and Control Panel Polling (gated by timer bits 4-7)
;   MidiChannel_DispatchChanged - Process changed MIDI parameter bitmasks
;   MIDI_ProcessChangedChannels - Dispatch MIDI CC changes
;   CPanel_Poll - Poll control panel for button/encoder events
;   EffectMode_CheckAndDispatch - Process effect mode changes
;   Demo_SelectEntry_TimerTick - Demo mode timer processing
;   CommPort_StatusCheckAndSend - Communication port status/send
;   BitMapOut_DecrementTimer - Bitmap output timer management
;
; PHASE 5: UI and Display
;   MainTitle_PrepareAndDispatch - UI title screen event dispatch
;   SwbtWr_ProcessAll - Process switchboard write queue
;   AccDir_PeriodicEntry - Accompaniment direction periodic processing
;   Display_DirtyRegionDispatch - Redraw dirty screen regions
;
; PHASE 6: Sequencer Finalization
;   SeqPhase_OperationStateCheck - Check/init operation state
;   AccompSeq_PeriodicEntry - Accompaniment sequencer periodic dispatch
;   CallExtIfActive_Entry - Call extension interface if active (HDAE5000)
; =============================================================================
"""

def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'
    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # Insert docs before MainLoop: label
    text = text.replace('\nMainLoop:\n', '\n' + MAINLOOP_DOCS + 'MainLoop:\n', 1)

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))

    print("MainLoop documentation header added.")

if __name__ == '__main__':
    main()
