# midi lane 2026-09-25.  MIDI_CHANNEL_MESSAGE_DISPATCHER sends the FIRST data byte
# of every two-data-byte message (8x 9x Bx Ex) to the routine at 0xFCF7A8, which
# only does `set 6, (0x427) / ld c, e / ret`; the next data byte then finds bit 6
# set and goes to the routine that enqueues status + both bytes (with a special
# case for F2 song position).  Neither is about a queue overflow or SysEx.
/^[[:space:]]*;/!s/\bChanDisp_QueueOverflow\b/ChanDisp_AwaitSecondDataByte/g
/^[[:space:]]*;/!s/\bChanDisp_SysExInProgress\b/ChanDisp_SecondDataByte/g
