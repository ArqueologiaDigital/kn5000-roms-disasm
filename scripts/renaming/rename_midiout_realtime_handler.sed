# audio/dsp_config_sysex.s: a code entry (widget_dispatch.s points at it) named as data; its first instruction
# was decoded as `.byte 0xc1, lo, hi / push xsp / cp (xwa-80), iz` until 2026-10-03.
s/\bMidiOut_RealtimeDispatch_Data\b/MidiOut_RealtimeDispatch_Handler/g
