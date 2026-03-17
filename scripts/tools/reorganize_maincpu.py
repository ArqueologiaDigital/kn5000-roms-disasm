#!/usr/bin/env python3
"""
Reorganize maincpu/ source files into a hierarchical directory structure.

This script:
1. Creates new subdirectories
2. Moves files with git mv (preserves history)
3. Updates ALL .include directives in ALL .s files using binary I/O
   (to preserve Latin-1 bytes)

All include paths are relative to maincpu/ (the -I root in the Makefile).
"""

import os
import re
import subprocess
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mapping: old path (relative to maincpu/) -> new path (relative to maincpu/)
MOVES = {
    # boot/ — System startup, core handlers
    'system_handlers.s': 'boot/system_handlers.s',
    'main_title_ctrl_panel.s': 'boot/main_title_ctrl_panel.s',
    'screen_group_dispatch.s': 'boot/screen_group_dispatch.s',

    # ui/ — UI framework, widgets, drawing
    'ui_control_panel.s': 'ui/ui_control_panel.s',
    'ui_window_procs.s': 'ui/ui_window_procs.s',
    'ui_mode_handlers.s': 'ui/ui_mode_handlers.s',
    'ui_widget_defs.s': 'ui/ui_widget_defs.s',
    'drawing_primitives.s': 'ui/drawing_primitives.s',
    'bitmap_out_routines.s': 'ui/bitmap_out_routines.s',
    'psgridbox_routines.s': 'ui/psgridbox_routines.s',
    'password_slot_routines.s': 'ui/password_slot_routines.s',
    'setwall_routines.s': 'ui/setwall_routines.s',
    'drawbar_panel_ui.s': 'ui/drawbar_panel_ui.s',
    'rvari_routines.s': 'ui/rvari_routines.s',
    'cpanel_routines.s': 'ui/cpanel_routines.s',

    # display/ — VGA, graphics, text rendering
    'scoop_display.s': 'display/scoop_display.s',
    'graphics_text_vga.s': 'display/graphics_text_vga.s',

    # audio/ — Audio control, sound editor, DSP
    'audio_control_engine.s': 'audio/audio_control_engine.s',
    'audio_cmd_encoder.s': 'audio/audio_cmd_encoder.s',
    'audioinit_routines.s': 'audio/audioinit_routines.s',
    'sound_editor_ui.s': 'audio/sound_editor_ui.s',
    'sound_editor_routines.s': 'audio/sound_editor_routines.s',
    'sound_navigation.s': 'audio/sound_navigation.s',
    'sndparam_routines.s': 'audio/sndparam_routines.s',
    'dsp_config_sysex.s': 'audio/dsp_config_sysex.s',
    'note_voice_mapping.s': 'audio/note_voice_mapping.s',
    'semenu_routines.s': 'audio/semenu_routines.s',

    # midi/ — MIDI processing & computer interface
    'midi_serial_routines.s': 'midi/midi_serial_routines.s',
    'midi_dispatch_handlers.s': 'midi/midi_dispatch_handlers.s',
    'midipkt_routines.s': 'midi/midipkt_routines.s',
    'midi_encoder_routines.s': 'midi/midi_encoder_routines.s',
    'sysex_routines.s': 'midi/sysex_routines.s',
    'computer_interface_config.s': 'midi/computer_interface_config.s',
    'computer_interface_pcg.s': 'midi/computer_interface_pcg.s',

    # sequencer/ — Sequencer, SMF, accompaniment
    'sequencer_engine.s': 'sequencer/sequencer_engine.s',
    'sequencer_ui.s': 'sequencer/sequencer_ui.s',
    'smf_playback.s': 'sequencer/smf_playback.s',
    'smf_event_processor.s': 'sequencer/smf_event_processor.s',
    'smf_config_routines.s': 'sequencer/smf_config_routines.s',
    'seq_step_routines.s': 'sequencer/seq_step_routines.s',
    'accompaniment_engine.s': 'sequencer/accompaniment_engine.s',
    'accompseq_routines.s': 'sequencer/accompseq_routines.s',
    'rhythm_routines.s': 'sequencer/rhythm_routines.s',
    'ssf_gate_states.s': 'sequencer/ssf_gate_states.s',
    'bmdredit_routines.s': 'sequencer/bmdredit_routines.s',

    # storage/ — Flash & floppy
    'flash_floppy_handlers.s': 'storage/flash_floppy_handlers.s',
    'fdc_routines.s': 'storage/fdc_routines.s',

    # demo/ — Demo routines
    'demo_routines.s': 'demo/demo_routines.s',
    'fdemotext_routines.s': 'demo/fdemotext_routines.s',
    'file_demo_proc.s': 'demo/file_demo_proc.s',

    # naka/ — Move remaining naka files from parent into naka/ subdir
    'naka_descriptors.s': 'naka/naka_descriptors.s',
    'naka_dispatch.s': 'naka/naka_dispatch.s',
    'naka_style_bitmap.s': 'naka/naka_style_bitmap.s',
}

def create_directories():
    """Create new subdirectories."""
    new_dirs = set()
    for new_path in MOVES.values():
        d = os.path.dirname(new_path)
        if d:
            new_dirs.add(d)

    for d in sorted(new_dirs):
        full_path = os.path.join(MAINCPU_DIR, d)
        if not os.path.exists(full_path):
            os.makedirs(full_path)
            print(f"  Created directory: maincpu/{d}/")


def move_files():
    """Move files using git mv."""
    for old_path, new_path in sorted(MOVES.items()):
        old_full = os.path.join(MAINCPU_DIR, old_path)
        new_full = os.path.join(MAINCPU_DIR, new_path)
        if not os.path.exists(old_full):
            print(f"  WARNING: {old_path} does not exist, skipping")
            continue
        if os.path.exists(new_full):
            print(f"  WARNING: {new_path} already exists, skipping")
            continue
        result = subprocess.run(
            ['git', 'mv', old_full, new_full],
            cwd=REPO_DIR, capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"  ERROR moving {old_path}: {result.stderr.strip()}")
            sys.exit(1)
        print(f"  Moved: {old_path} -> {new_path}")


def update_includes():
    """Update all .include directives in all .s files using binary I/O."""
    # Build regex pattern to match include directives with old paths
    # Include paths are always quoted: .include "path" or .include "path"
    # Also handle .include with tabs/spaces

    # Collect all .s files recursively
    s_files = []
    for root, dirs, files in os.walk(MAINCPU_DIR):
        for f in files:
            if f.endswith('.s'):
                s_files.append(os.path.join(root, f))

    # For each file, read binary, find and replace include paths
    total_updates = 0
    for filepath in sorted(s_files):
        with open(filepath, 'rb') as f:
            content = f.read()

        original = content

        for old_path, new_path in MOVES.items():
            # Match .include "old_path" (with possible whitespace variants)
            # Use bytes for binary safety
            old_bytes = f'"{old_path}"'.encode('ascii')
            new_bytes = f'"{new_path}"'.encode('ascii')

            if old_bytes in content:
                content = content.replace(old_bytes, new_bytes)

        if content != original:
            with open(filepath, 'wb') as f:
                f.write(content)
            rel_path = os.path.relpath(filepath, MAINCPU_DIR)
            # Count replacements
            n = sum(1 for old_path in MOVES
                    if f'"{old_path}"'.encode('ascii') in original
                    and f'"{old_path}"'.encode('ascii') not in content)
            # Actually count more carefully
            changes = 0
            for old_path, new_path in MOVES.items():
                old_bytes = f'"{old_path}"'.encode('ascii')
                old_count = original.count(old_bytes)
                new_count = content.count(old_bytes)
                changes += old_count - new_count
            total_updates += changes
            print(f"  Updated includes in: maincpu/{rel_path} ({changes} paths)")

    print(f"  Total include path updates: {total_updates}")


def main():
    print("=== KN5000 Maincpu Source Tree Reorganization ===")
    print()

    # Verify we're in the right place
    if not os.path.exists(os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')):
        print("ERROR: Cannot find kn5000_v10_program.s in maincpu/")
        sys.exit(1)

    print(f"Moving {len(MOVES)} files into subdirectories...")
    print()

    print("Step 1: Create directories")
    create_directories()
    print()

    print("Step 2: Move files (git mv)")
    move_files()
    print()

    print("Step 3: Update include paths (binary I/O)")
    update_includes()
    print()

    print("=== Done! Now run: make clean && make all ===")


if __name__ == '__main__':
    main()
