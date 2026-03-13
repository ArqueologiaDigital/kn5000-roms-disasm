#!/usr/bin/env python3
"""
Add descriptive comment headers to all assembly source files that lack them.

Uses binary I/O to preserve Latin-1 bytes in maincpu .s files.
"""

import os
import sys

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAINCPU_DIR = os.path.join(REPO_DIR, 'maincpu')

# Map: file path (relative to maincpu/) -> (title, description lines)
HEADERS = {
    # === audio/ ===
    'audio/audio_control_engine.s': (
        'Audio Control Engine',
        [
            'MIDI stream processing, control panel LED management, voice/tone',
            'parameter control, and sound preset dispatch. This is the main',
            'bridge between the UI layer and the SubCPU audio engine.',
        ],
    ),
    'audio/audioinit_routines.s': (
        'Audio Initialization',
        [
            'Audio subsystem initialization and stereo voice configuration.',
            'Called during system boot to set up voice slots, output routing,',
            'and default sound parameters.',
        ],
    ),
    'audio/dsp_config_sysex.s': (
        'DSP Configuration & SysEx Processing',
        [
            'DSP effect parameter handlers (reverb, chorus, EQ, compressor)',
            'and System Exclusive (SysEx) command processing. Manages effect',
            'presets and real-time parameter editing.',
        ],
    ),
    'audio/note_voice_mapping.s': (
        'Note & Voice Mapping (26K lines)',
        [
            'Note-on processing, polyphonic voice allocation and stealing,',
            'NoteMap dispatch (91 functions), sequence playback support, MIDI',
            'output formatting, sound parameter management, and utility routines.',
            'One of the largest files in the ROM.',
        ],
    ),
    'audio/semenu_routines.s': (
        'Sound Editor Menu (SeMenu)',
        [
            'Event handling and navigation for the Sound Editor menu system.',
            'Manages dialog boxes, notification handlers, object registration,',
            'and display flushing for sound editing screens.',
        ],
    ),
    'audio/sndparam_routines.s': (
        'Sound Parameter Routines',
        [
            'Sound parameter probe, match, and heap allocation. Provides',
            'lookup and comparison services for sound preset data.',
        ],
    ),
    'audio/sound_editor_ui.s': (
        'Sound Editor UI',
        [
            'Sound editor user interface: patch/bank selection, parameter',
            'editing, drum kit editor. Includes flash/floppy integration',
            'for saving/loading sound patches.',
        ],
    ),
    'audio/sound_navigation.s': (
        'Sound Navigation',
        [
            'Sound bank browsing functions: MainGetSoundName,',
            'Sound_Navigate_Next/Prev, MainGetRhythmName, MainGetPmemName,',
            'and MainTrSwControl for sound selection UI.',
        ],
    ),

    # === boot/ ===
    'boot/system_handlers.s': (
        'System Handlers (8K lines)',
        [
            'Core system infrastructure: interrupt handlers (NMI, DMA, timers),',
            'the UI state machine, cooperative task scheduler, flash memory',
            'update routines, and LZSS decompression engine.',
        ],
    ),
    'boot/main_title_ctrl_panel.s': (
        'Main Title & System Initialization',
        [
            'System initialization sequence (graphics, event queue, timers,',
            'object table, LCD power-on) and the main title screen UI event',
            'loop. Entry point after boot completes.',
        ],
    ),
    'boot/screen_group_dispatch.s': (
        'Screen Group Dispatch',
        [
            'Boot screen group dispatcher for startup screens and error',
            'dialogs. Also contains the system reinitialization routine',
            'called during display mode transitions.',
        ],
    ),

    # === display/ ===
    'display/scoop_display.s': (
        'Scoop Display & Performance Parameters (10K lines)',
        [
            'Display dirty-region tracking, performance mode parameter',
            'handlers, and the Scoop (oscilloscope) editor UI. Manages',
            'the real-time display update system for the 320x240 LCD.',
        ],
    ),
    'display/graphics_text_vga.s': (
        'Graphics, Text & VGA Routines',
        [
            'VGA palette initialization, text rendering engine, string',
            'layout, character set handling, and VRAM blit operations.',
            'The low-level graphics API used by all UI subsystems.',
        ],
    ),

    # === midi/ ===
    'midi/midipkt_routines.s': (
        'MIDI Packet Routines',
        [
            'MIDI packet extraction, packing, and queue management.',
            'Handles the low-level MIDI message framing between the',
            'serial I/O layer and the dispatch handlers.',
        ],
    ),
    'midi/midi_dispatch_handlers.s': (
        'MIDI Dispatch Handlers (11K lines)',
        [
            'MIDI Control Change handlers (22 types), serial input parsing,',
            'file data validation, sound mode handlers, and arpeggiator queue.',
            'The main MIDI message routing and processing layer.',
        ],
    ),

    # === sequencer/ ===
    'sequencer/sequencer_engine.s': (
        'Sequencer Engine (32K lines)',
        [
            'Core sequencer: note editor UI, playback control, voice',
            'allocation, application event framework, and part/voice data',
            'management. One of the largest files in the ROM.',
            '',
            'Internal codename: "YOKO" (Matsushita/Technics developer name).',
        ],
    ),
    'sequencer/sequencer_ui.s': (
        'Sequencer UI (14K lines)',
        [
            'Sequencer editing user interface: track display, step/event',
            'editing, and the bitmap drum editor integration.',
        ],
    ),
    'sequencer/smf_event_processor.s': (
        'SMF Event Processor',
        [
            'Standard MIDI File (SMF) event processing, tone generation',
            'dispatch, and voice channel management. Bridges SMF playback',
            'data to the audio engine.',
        ],
    ),
    'sequencer/smf_config_routines.s': (
        'SMF Configuration',
        [
            'SMF (Standard MIDI File) configuration and parameter setup.',
            'Manages playback settings, channel assignments, and tempo.',
        ],
    ),
    'sequencer/rhythm_routines.s': (
        'Rhythm Pattern Routines',
        [
            'Rhythm pattern comparison, trigger logic, and transposition.',
            'Evaluates accompaniment pattern matching and rhythm dispatch.',
        ],
    ),
    'sequencer/accompseq_routines.s': (
        'Accompaniment Sequencer',
        [
            'Accompaniment sequencer periodic processing. Handles real-time',
            'accompaniment playback, manual MIDI mode, and fade-out timing.',
        ],
    ),
    'sequencer/accompaniment_engine.s': (
        'Accompaniment Engine (32K lines)',
        [
            'Rhythm note dispatch, accompaniment voice selection, timing,',
            'patch management, drum configuration, and style conversion.',
            'One of the largest files in the ROM.',
        ],
    ),
    'sequencer/bmdredit_routines.s': (
        'Bitmap Drum Editor',
        [
            'Bitmap drum editor: stream positioning, sequence display,',
            'and voice allocation UI. Provides the graphical drum pattern',
            'editing interface.',
        ],
    ),

    # === storage/ ===
    'storage/flash_floppy_handlers.s': (
        'Flash & Floppy Handlers',
        [
            'Flash memory sector write routines, floppy disk note event',
            'loading, and FDC format UI. Bridges storage hardware to the',
            'file I/O subsystem.',
        ],
    ),

    # === demo/ ===
    'demo/fdemotext_routines.s': (
        'Feature Demo Text Processing',
        [
            'Text data processing for Feature Demo mode: voice probing,',
            'flag processing, and formatted output for demo displays.',
        ],
    ),
    'demo/file_demo_proc.s': (
        'File Demo Procedures',
        [
            'File demo procedures and title handlers. Manages demo file',
            'playback, title display, and demo mode UI integration.',
        ],
    ),

    # === ui/ ===
    'ui/ui_control_panel.s': (
        'UI Control Panel (4K lines)',
        [
            'Control panel key dispatch, UI task control, slider/scrollbar',
            'handlers, and the GroupBoxProc container widget. Routes button',
            'presses and dial events to the appropriate UI handlers.',
        ],
    ),
    'ui/ui_window_procs.s': (
        'UI Window Procedures (8K lines)',
        [
            'Window procedure handlers for all standard widget types:',
            'ModeEdit, TitleEdit, StringBox, Label, Bitmap, Icon, Line,',
            'Frame, EditSw, TextBox, VwBox, ListBox, RadioBox, TempoBox,',
            'GridBox. The core UI rendering and event dispatch layer.',
        ],
    ),
    'ui/ui_mode_handlers.s': (
        'UI Mode Handlers (12K lines)',
        [
            'Mode-specific UI handlers for Pmem (parametric memory), bank',
            'editor, filter grid, RVari (rhythm variation), and DSP effect',
            'editing modes.',
        ],
    ),
    'ui/ui_widget_defs.s': (
        'UI Widget Definitions (19K lines)',
        [
            'Grid box implementations, exit window handling, title/resource',
            'widgets, event dispatch loops, and object enumeration. Defines',
            'the widget infrastructure used by all UI screens.',
        ],
    ),
    'ui/drawbar_panel_ui.s': (
        'Drawbar & Panel UI (15K lines)',
        [
            'Drawbar organ slider UI, DSP effect controls, the presentation',
            'system, and the demo menu. Handles the real-time parameter',
            'display for the drawbar interface.',
        ],
    ),
    'ui/bitmap_out_routines.s': (
        'Bitmap Output Routines',
        [
            'Bitmap blitting and palette loading for VGA display.',
            'Handles bitmap decompression and rendering to the framebuffer.',
        ],
    ),
    'ui/drawing_primitives.s': (
        'Drawing Primitives',
        [
            'Low-level drawing routines: Bresenham line drawing, rectangle',
            'fill, and reverse string rendering. Used by higher-level UI',
            'widgets for all graphical output.',
        ],
    ),
    'ui/psgridbox_routines.s': (
        'PS Grid Box Widget',
        [
            'Parameter Selection Grid Box widget: initialization, memory',
            'allocation, visibility control, and event handling.',
        ],
    ),
    'ui/rvari_routines.s': (
        'RVari (Rhythm Variation) Screen',
        [
            'Rhythm variation selection screen renderer and interaction',
            'handlers. Displays and navigates rhythm variation options',
            'with type-specific rendering (Type E/Other).',
        ],
    ),
    'ui/setwall_routines.s': (
        'Wallpaper & Wall Display',
        [
            'Wallpaper image loading and wall display update routines.',
            'Manages the panel slot selection/matching system for the',
            'background display.',
        ],
    ),
}


def make_header(title, desc_lines):
    """Create a comment header block as bytes."""
    bar = b'; ' + b'=' * 77 + b'\n'
    lines = [bar]
    lines.append(f'; {title}\n'.encode('ascii'))
    lines.append(bar)

    if desc_lines:
        lines.append(b';\n')
        for line in desc_lines:
            if line == '':
                lines.append(b';\n')
            else:
                lines.append(f'; {line}\n'.encode('ascii'))

    lines.append(bar)
    lines.append(b'\n')
    return b''.join(lines)


def main():
    added = 0
    skipped = 0

    for rel_path, (title, desc_lines) in sorted(HEADERS.items()):
        full_path = os.path.join(MAINCPU_DIR, rel_path)
        if not os.path.exists(full_path):
            print(f'  WARNING: {rel_path} not found, skipping')
            skipped += 1
            continue

        with open(full_path, 'rb') as f:
            content = f.read()

        # Check if file already has a proper header
        first_line = content.split(b'\n', 1)[0].strip()
        if first_line.startswith(b'; ===='):
            print(f'  SKIP (already has header): {rel_path}')
            skipped += 1
            continue

        header = make_header(title, desc_lines)

        with open(full_path, 'wb') as f:
            f.write(header + content)

        print(f'  Added header: {rel_path}')
        added += 1

    print(f'\nDone: {added} headers added, {skipped} skipped')


if __name__ == '__main__':
    main()
