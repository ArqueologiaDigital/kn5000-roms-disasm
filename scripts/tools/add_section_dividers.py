#!/usr/bin/env python3
"""
Add internal section divider comments to large assembly files.

Inserts section markers before key label names to help navigate
files with 10K-32K lines. Uses binary I/O for Latin-1 safety.
"""

import os
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')

# Format: (file_path, [(label_name, section_title, description), ...])
SECTIONS = [
    ('audio/note_voice_mapping.s', [
        ('NoteOnProcess_NextChannel:', 'Note-On Processing & Voice Allocation',
         'Note-on channel processing, voice slot allocation, and\n'
         '; accompaniment note-on setup.'),
        ('AccMidi_ReadNextEvent:', 'Rhythm & Accompaniment MIDI Processing',
         'MIDI event input handling for rhythm patterns and\n'
         '; accompaniment playback. Includes CC dispatch.'),
        ('Voice_InitializeAll:', 'Voice Initialization & Event Dispatch',
         'Voice state initialization, per-voice event dispatch,\n'
         '; and voice table group setup.'),
        ('NoteMap_ProcessAndMerge:', 'NoteMap Entry Management',
         'NoteMap storage, retrieval, voice linking, merge\n'
         '; allocation, and control change encoding.'),
        ('MidiEvent_ConfigChannel:', 'MIDI Event & Channel Configuration',
         'MIDI channel configuration, voice slot data init,\n'
         '; and note sequence parsing.'),
        ('Voice_BuildProgramNotify:', 'Voice Program Change & Notification',
         'Voice program change notification, NoteMap finalization,\n'
         '; and extended control change processing.'),
    ]),
    ('sequencer/sequencer_engine.s', [
        ('SeqAcc_HandlePlaybackTick:', 'Sequencer Playback Control',
         'Playback state machine: tick handling, start/stop,\n'
         '; repeat management, tempo, and part activation.'),
        ('SeqPlay_ProcessPartVoices:', 'Part & Voice Processing',
         'Per-part voice iteration, event processing, tempo\n'
         '; events, and playback abort/cleanup.'),
        ('SeqPlay_CheckDrumPartAndClearCounters:', 'Drum Parts & Channel Dispatch',
         'Drum part handling, counter management, channel\n'
         '; slot allocation, and MIDI event dispatch.'),
        ('SeqPlay_InitializePlayback:', 'Playback Initialization & Voice Assignment',
         'Playback state setup, voice finding, channel\n'
         '; configuration, and position/flag management.'),
        ('SeqPlay_ProcessVoiceAndNotes:', 'Voice Processing & Cleanup',
         'Voice and note processing, stop/cleanup routines,\n'
         '; and playback finalization.'),
    ]),
    ('sequencer/accompaniment_engine.s', [
        ('Seq_ProcessAndContinue:', 'Sequence Processing & Voice Selection',
         'Sequence continuation and accompaniment voice\n'
         '; part offset selection.'),
        ('AccPart_InitPositionsAndBase:', 'Accompaniment Part Management',
         'Part position initialization, buffer reset, tuning\n'
         '; configuration, and style index lookup.'),
        ('AccVoice_ProcessEventLoop:', 'Voice Event Processing',
         'Per-voice event loop, event dispatch, and\n'
         '; sound patch handling.'),
        ('AccVoice_SetChordChangeFlags:', 'Chord, Table & Address Lookup',
         'Chord change flags, voice table address lookup,\n'
         '; and buffer advance routines.'),
        ('AccPedal_DirectionA:', 'Pedal Direction & MIDI Dispatch',
         'Pedal direction control (forward/reverse/alternate)\n'
         '; and accompaniment MIDI event dispatch.'),
    ]),
    ('display/scoop_display.s', [
        ('GraphicsRender_TwoTable:', 'Graphics Rendering',
         'Two-table rendering, conditional updates, event\n'
         '; checking, and curve/glide setup.'),
        ('ParamUpdate_AddAndStore:', 'Parameter Update Routines',
         'Parameter add/store, zero-check, and conditional\n'
         '; update helpers.'),
        ('SoundEvt_ShortPacketHandler:', 'Sound Event Handlers',
         'Sound event packet processing (short and long),\n'
         '; tone parameter bytecode, and default handlers.'),
        ('PerfMode_ParamHandler_Table:', 'Performance Mode Parameter Handlers',
         'Parameter handler dispatch table and individual\n'
         '; handlers for each performance mode parameter.'),
    ]),
    ('ui/drawbar_panel_ui.s', [
        ('TtMdPmemOut:', 'Accompaniment Parameter Output',
         'Left/right parameter output grid boxes, cell\n'
         '; initialization, scroll, and navigation.'),
        ('PmemOutLGridCheck:', 'Parameter Output Grid Checks',
         'Grid validation, checking, and event handling\n'
         '; for left/right parameter output panels.'),
        ('TtMdCtlMsg_EventDispatch:', 'Control Message Dispatch',
         'MIDI control message event dispatch, grid box\n'
         '; event handling, and message routing.'),
    ]),
]


def make_divider(title, description):
    """Create a section divider as bytes."""
    bar = b'; ' + b'-' * 77 + b'\n'
    lines = [b'\n', bar]
    lines.append(f'; Section: {title}\n'.encode('ascii'))
    lines.append(bar)
    lines.append(f'; {description}\n'.encode('ascii'))
    lines.append(bar)
    lines.append(b'\n')
    return b''.join(lines)


def add_dividers_to_file(rel_path, sections):
    """Add section dividers before specified labels."""
    full_path = os.path.join(MAINCPU_DIR, rel_path)
    if not os.path.exists(full_path):
        print(f'  WARNING: {rel_path} not found')
        return 0

    with open(full_path, 'rb') as f:
        content = f.read()

    added = 0
    for label, title, desc in sections:
        label_bytes = label.encode('ascii')
        # Find the label at the start of a line
        search = b'\n' + label_bytes
        pos = content.find(search)
        if pos == -1:
            print(f'  WARNING: label "{label}" not found in {rel_path}')
            continue

        # Check if there's already a section divider nearby (within 200 bytes before)
        preceding = content[max(0, pos - 200):pos]
        if b'; Section:' in preceding or b'; ---' in preceding:
            print(f'  SKIP (already has divider): {label} in {rel_path}')
            continue

        divider = make_divider(title, desc)
        content = content[:pos] + b'\n' + divider + content[pos + 1:]  # replace the \n with \n + divider
        added += 1

    if added > 0:
        with open(full_path, 'wb') as f:
            f.write(content)
        print(f'  {rel_path}: {added} section dividers added')

    return added


def main():
    print('=== Adding Section Dividers to Large Files ===\n')
    total = 0
    for rel_path, sections in SECTIONS:
        total += add_dividers_to_file(rel_path, sections)
    print(f'\nDone: {total} dividers added')


if __name__ == '__main__':
    main()
