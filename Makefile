# Shared projects root — override with: make PROJECTS_ROOT=/some/other/path <target>
PROJECTS_ROOT ?= $(HOME)/compartilhado

LLVM_BIN=$(PROJECTS_ROOT)/llvm-project/build/bin
LLVM_MC=$(LLVM_BIN)/llvm-mc
LLVM_LLD=$(LLVM_BIN)/ld.lld -e 0
LLVM_OBJCOPY=$(LLVM_BIN)/llvm-objcopy

# Demo song presets: decompressed sources -> recompressed payloads (see rules below).
DEMO_PRESET_DIR=table_data/includes/demo_presets
DEMO_PRESET_IDS=00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18
DEMO_PRESET_COMPRESSED=$(foreach i,$(DEMO_PRESET_IDS),$(DEMO_PRESET_DIR)/demo_preset_$(i)_compressed.bin)
DEMO_PRESET_MIDI_DIR=$(DEMO_PRESET_DIR)/midi
DEMO_PRESET_SIDECAR_DIR=$(DEMO_PRESET_DIR)/sidecar

# Help databases: decompressed sources -> recompressed SLIDE8K payloads (see rules below).
HELP_DB_DIR=table_data/includes/help_databases
HELP_DB_LANGS=english german french spanish indonesian
HELP_DB_COMPRESSED=$(foreach l,$(HELP_DB_LANGS),$(HELP_DB_DIR)/help_db_$(l)_compressed.bin)
# german_stale is a truncated factory remnant: kn5000_table_data.s emits its
# bytes as a raw slice (see table_data/help_databases.s), so its rebuilt
# payload is used by verify-help-databases only, never by the ROM build.
HELP_DB_STALE_COMPRESSED=$(HELP_DB_DIR)/help_db_german_stale_compressed.bin
CLANG=$(LLVM_BIN)/clang

.PHONY: all llvm-all paramblocks screendata naka clean clean-asl clean-all
.PHONY: llvm-convert llvm-convert-all asl-all gallery issues rom-status website
.SECONDARY:

.PHONY: decompress-demo-presets rebuild-demo-presets verify-demo-presets demo-midi demo-sidecars
.PHONY: decompress-help-databases rebuild-help-databases verify-help-databases
.PHONY: dsp dsp-verify dsp-flowcharts

# Primary build: LLVM assembly (authoritative source)
all: llvm-all
	python scripts/build/compare_roms.py

# LLVM build targets (primary)
llvm-all: rebuilt_ROMs/kn5000_v10_program.llvm.rom rebuilt_ROMs/kn5000_v9_program.llvm.rom rebuilt_ROMs/kn5000_v7_program.llvm.rom rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom rebuilt_ROMs/kn5000_subprogram_v142_compressed.rom rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom rebuilt_ROMs/kn5000_table_data.llvm.rom rebuilt_ROMs/kn5000_custom_data.llvm.rom

# ============================================================================
# C-compiled ScreenData paramblocks
# ============================================================================
# C struct source files are compiled to raw binaries, then .incbin'd by assembly.
# This provides type-safe, self-documenting data definitions.

PARAMBLOCK_NAMES = alta altb altc altd alte bal common extended meas medium short value
PARAMBLOCK_BINS = $(patsubst %,v10/maincpu/includes/generated/style_ui_paramblock_%.bin,$(PARAMBLOCK_NAMES))

SCREENDATA_NAMES = ctlonly main meascursor yesctl
SCREENDATA_BINS = $(patsubst %,v10/maincpu/includes/generated/style_ui_screendata_%.bin,$(SCREENDATA_NAMES))

ACCOMP_NAMES = accomp_section_widget accomp_part_widget accomp_display_full
ACCOMP_BINS = $(patsubst %,v10/maincpu/includes/generated/%.bin,$(ACCOMP_NAMES))

SE_NAMES = se_drumkit_display se_rhythm_transport_tables se_name_editor se_compare_screen se_parameter_grid se_transport_display se_setup_sel3 se_apply_confirm se_general_edit
# Note: se_drumkit_display and se_rhythm_transport_tables are .incbin'd in assembly.
# The remaining SE files are compiled but awaiting .incbin integration.
SE_BINS = $(patsubst %,v10/maincpu/includes/generated/%.bin,$(SE_NAMES))
SE_LINK_LD = v10/maincpu/audio/sound_editor_screens/se_screens_link.ld
ACCOMP_LINK_LD = v10/maincpu/sequencer/accomp_screens/accomp_screens_link.ld

NAKA_LINK_LD = v10/maincpu/ui_widgets/naka_ctrl_menu_link.ld
NAKA_TYPES_H = v10/maincpu/ui_widgets/naka_types.h
NAKA_BINS = v10/maincpu/includes/generated/naka_control_menu_header.bin v10/maincpu/includes/generated/naka_ctrl_menu_body.bin v10/maincpu/includes/generated/naka_perf_style.bin v10/maincpu/includes/generated/naka_msp_recording.bin v10/maincpu/includes/generated/naka_effects_seq.bin v10/maincpu/includes/generated/naka_midi_reverb.bin v10/maincpu/includes/generated/naka_composer_style.bin v10/maincpu/includes/generated/naka_direct_play.bin v10/maincpu/includes/generated/naka_technichord_part.bin v10/maincpu/includes/generated/naka_disk_menu_file_io.bin v10/maincpu/includes/generated/naka_debug_naming.bin v10/maincpu/includes/generated/naka_disk_warning.bin v10/maincpu/includes/generated/naka_extension_device.bin v10/maincpu/includes/generated/naka_normal_mode.bin v10/maincpu/includes/generated/naka_widget_tables_1.bin v10/maincpu/includes/generated/naka_master_style.bin v10/maincpu/includes/generated/naka_sound_menu_drawbar.bin v10/maincpu/includes/generated/naka_sequencer_exit.bin v10/maincpu/includes/generated/naka_sequencer_channels.bin v10/maincpu/includes/generated/naka_block_007.bin v10/maincpu/includes/generated/naka_block_012.bin v10/maincpu/includes/generated/naka_widget_names_charmap.bin v10/maincpu/includes/generated/naka_technichord_strings.bin v10/maincpu/includes/generated/naka_widget_tables_2.bin v10/maincpu/includes/generated/naka_style_bitmaps.bin v10/maincpu/includes/generated/naka_widget_descriptors.bin v10/maincpu/includes/generated/naka_accomp7_widgets.bin

VOICE_BINS = v10/maincpu/includes/generated/voice_factory_presets.bin
AUDIO_BINS = v10/maincpu/includes/generated/tonegen_param_table.bin
SOUND_DATA_BINS = v10/maincpu/includes/generated/sound_data_organ_accordion.bin v10/maincpu/includes/generated/sound_data_orchestral_pad.bin v10/maincpu/includes/generated/sound_data_synth.bin v10/maincpu/includes/generated/sound_data_bass.bin v10/maincpu/includes/generated/sound_data_accordion_reg.bin v10/maincpu/includes/generated/sound_data_digital_drawbar.bin v10/maincpu/includes/generated/sound_data_gm_special.bin v10/maincpu/includes/generated/sound_data_guitar.bin v10/maincpu/includes/generated/sound_data_sax_reed.bin v10/maincpu/includes/generated/sound_data_drum_kits.bin v10/maincpu/includes/generated/sound_data_piano.bin v10/maincpu/includes/generated/sound_data_strings_vocal.bin v10/maincpu/includes/generated/sound_data_flute.bin v10/maincpu/includes/generated/sound_data_flute_extra.bin v10/maincpu/includes/generated/sound_data_mallet_orch_perc.bin
SEPAOUT_BINS = v10/maincpu/includes/generated/sepaout_config.bin
GUI_BINS = v10/maincpu/includes/generated/gui_display_struct_data.bin
TONEKIT_BINS = v10/maincpu/includes/generated/tonekit_param_blocks.bin
SOUNDCFG_BINS = v10/maincpu/includes/generated/sound_config_lookup.bin
C_DATA_BINS = $(PARAMBLOCK_BINS) $(VOICE_BINS) $(AUDIO_BINS) $(SOUND_DATA_BINS) $(SCREENDATA_BINS) $(ACCOMP_BINS) $(SE_BINS) $(NAKA_BINS) $(SEPAOUT_BINS) $(GUI_BINS) $(TONEKIT_BINS) $(SOUNDCFG_BINS)

# V9 C data bins (compiled from v9/maincpu sources)
V9_PARAMBLOCK_BINS = $(patsubst %,v9/maincpu/includes/generated/style_ui_paramblock_%.bin,$(PARAMBLOCK_NAMES))
V9_SCREENDATA_BINS = $(patsubst %,v9/maincpu/includes/generated/style_ui_screendata_%.bin,$(SCREENDATA_NAMES))
V9_ACCOMP_BINS = $(patsubst %,v9/maincpu/includes/generated/%.bin,$(ACCOMP_NAMES))
V9_SE_BINS = $(patsubst %,v9/maincpu/includes/generated/%.bin,$(SE_NAMES))
V9_SE_LINK_LD = v9/maincpu/audio/sound_editor_screens/se_screens_link.ld
V9_ACCOMP_LINK_LD = v9/maincpu/sequencer/accomp_screens/accomp_screens_link.ld
V9_NAKA_LINK_LD = v9/maincpu/ui_widgets/naka_ctrl_menu_link.ld
V9_NAKA_TYPES_H = v9/maincpu/ui_widgets/naka_types.h
V9_NAKA_BINS = $(patsubst v10/%,v9/%,$(NAKA_BINS))
V9_VOICE_BINS = v9/maincpu/includes/generated/voice_factory_presets.bin
V9_AUDIO_BINS = v9/maincpu/includes/generated/tonegen_param_table.bin
V9_SOUND_DATA_BINS = $(patsubst v10/%,v9/%,$(SOUND_DATA_BINS))
V9_SEPAOUT_BINS = v9/maincpu/includes/generated/sepaout_config.bin
V9_GUI_BINS = v9/maincpu/includes/generated/gui_display_struct_data.bin
V9_TONEKIT_BINS = v9/maincpu/includes/generated/tonekit_param_blocks.bin
V9_SOUNDCFG_BINS = v9/maincpu/includes/generated/sound_config_lookup.bin
V9_C_DATA_BINS = $(V9_PARAMBLOCK_BINS) $(V9_VOICE_BINS) $(V9_AUDIO_BINS) $(V9_SOUND_DATA_BINS) $(V9_SCREENDATA_BINS) $(V9_ACCOMP_BINS) $(V9_SE_BINS) $(V9_NAKA_BINS) $(V9_SEPAOUT_BINS) $(V9_GUI_BINS) $(V9_TONEKIT_BINS) $(V9_SOUNDCFG_BINS)

# V7 C data bins (compiled from v7/maincpu sources)
V7_PARAMBLOCK_BINS = $(patsubst %,v7/maincpu/includes/generated/style_ui_paramblock_%.bin,$(PARAMBLOCK_NAMES))
V7_SCREENDATA_BINS = $(patsubst %,v7/maincpu/includes/generated/style_ui_screendata_%.bin,$(SCREENDATA_NAMES))
V7_ACCOMP_BINS = $(patsubst %,v7/maincpu/includes/generated/%.bin,$(ACCOMP_NAMES))
V7_SE_BINS = $(patsubst %,v7/maincpu/includes/generated/%.bin,$(SE_NAMES))
V7_SE_LINK_LD = v7/maincpu/audio/sound_editor_screens/se_screens_link.ld
V7_ACCOMP_LINK_LD = v7/maincpu/sequencer/accomp_screens/accomp_screens_link.ld
V7_NAKA_LINK_LD = v7/maincpu/ui_widgets/naka_ctrl_menu_link.ld
V7_NAKA_TYPES_H = v7/maincpu/ui_widgets/naka_types.h
V7_NAKA_BINS = $(patsubst v10/%,v7/%,$(NAKA_BINS))
V7_VOICE_BINS = v7/maincpu/includes/generated/voice_factory_presets.bin
V7_AUDIO_BINS = v7/maincpu/includes/generated/tonegen_param_table.bin
V7_SOUND_DATA_BINS = $(patsubst v10/%,v7/%,$(SOUND_DATA_BINS))
V7_SEPAOUT_BINS = v7/maincpu/includes/generated/sepaout_config.bin
V7_GUI_BINS = v7/maincpu/includes/generated/gui_display_struct_data.bin
V7_TONEKIT_BINS = v7/maincpu/includes/generated/tonekit_param_blocks.bin
V7_SOUNDCFG_BINS = v7/maincpu/includes/generated/sound_config_lookup.bin
V7_C_DATA_BINS = $(V7_PARAMBLOCK_BINS) $(V7_VOICE_BINS) $(V7_AUDIO_BINS) $(V7_SOUND_DATA_BINS) $(V7_SCREENDATA_BINS) $(V7_ACCOMP_BINS) $(V7_SE_BINS) $(V7_NAKA_BINS) $(V7_SEPAOUT_BINS) $(V7_GUI_BINS) $(V7_TONEKIT_BINS) $(V7_SOUNDCFG_BINS)

v10/maincpu/includes/generated/style_ui_paramblock_%.bin: v10/maincpu/style_ui/paramblock/%.c v10/maincpu/style_ui/screendata_types.h
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

# ctlonly uses linker to resolve extern symbol addresses from scoop_display.s
v10/maincpu/includes/generated/style_ui_screendata_ctlonly.bin: v10/maincpu/style_ui/ctlonly.c v10/maincpu/style_ui/screendata_types.h v10/maincpu/style_ui/ctlonly_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/style_ui/ctlonly_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/style_ui_screendata_%.bin: v10/maincpu/style_ui/%.c v10/maincpu/style_ui/screendata_types.h
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

# SE screens use shared linker script to resolve extern handler symbols
v10/maincpu/includes/generated/se_%.bin: v10/maincpu/audio/sound_editor_screens/se_%.c v10/maincpu/style_ui/screendata_types.h $(SE_LINK_LD)
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(SE_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# Accomp screens use shared linker script to resolve extern handler symbols
v10/maincpu/includes/generated/accomp_%.bin: v10/maincpu/sequencer/accomp_screens/accomp_%.c v10/maincpu/style_ui/screendata_types.h $(ACCOMP_LINK_LD)
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(ACCOMP_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# NAKA widget descriptors — compiled C structs with named fields
v10/maincpu/includes/generated/naka_control_menu_header.bin: v10/maincpu/ui_widgets/control_menu_header.c $(NAKA_TYPES_H) $(NAKA_LINK_LD)
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T $(NAKA_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_ctrl_menu_body.bin: v10/maincpu/ui_widgets/naka_ctrl_menu_body.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_ctrl_menu_body_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_ctrl_menu_body_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_perf_style.bin: v10/maincpu/ui_widgets/naka_perf_style.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_perf_style_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_perf_style_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_msp_recording.bin: v10/maincpu/ui_widgets/naka_msp_recording.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_msp_recording_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_msp_recording_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_effects_seq.bin: v10/maincpu/ui_widgets/naka_effects_seq.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_effects_seq_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_effects_seq_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_midi_reverb.bin: v10/maincpu/ui_widgets/naka_midi_reverb.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_midi_reverb_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_midi_reverb_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_composer_style.bin: v10/maincpu/ui_widgets/naka_composer_style.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_composer_style_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_composer_style_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_direct_play.bin: v10/maincpu/ui_widgets/naka_direct_play.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_direct_play_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_direct_play_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_technichord_part.bin: v10/maincpu/ui_widgets/naka_technichord_part.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_technichord_part_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_technichord_part_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_disk_menu_file_io.bin: v10/maincpu/ui_widgets/naka_disk_menu_file_io.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_disk_menu_file_io_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_disk_menu_file_io_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_debug_naming.bin: v10/maincpu/ui_widgets/naka_debug_naming.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_debug_naming_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_debug_naming_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_disk_warning.bin: v10/maincpu/ui_widgets/naka_disk_warning.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_disk_warning_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_disk_warning_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_extension_device.bin: v10/maincpu/ui_widgets/naka_extension_device.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_extension_device_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_extension_device_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_normal_mode.bin: v10/maincpu/ui_widgets/naka_normal_mode.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_normal_mode_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_normal_mode_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_widget_tables_1.bin: v10/maincpu/ui_widgets/naka_widget_tables_1.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_widget_tables_1_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_widget_tables_1_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_master_style.bin: v10/maincpu/ui_widgets/naka_master_style.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_master_style_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_master_style_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_sound_menu_drawbar.bin: v10/maincpu/ui_widgets/naka_sound_menu_drawbar.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_sound_menu_drawbar_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_sound_menu_drawbar_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_sequencer_exit.bin: v10/maincpu/ui_widgets/naka_sequencer_exit.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_sequencer_exit_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_sequencer_exit_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_sequencer_channels.bin: v10/maincpu/ui_widgets/naka_sequencer_channels.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_sequencer_channels_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_sequencer_channels_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_block_007.bin: v10/maincpu/ui_widgets/naka_block_007.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_block_007_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_block_007_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_block_012.bin: v10/maincpu/ui_widgets/naka_block_012.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_block_012_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_block_012_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_widget_names_charmap.bin: v10/maincpu/ui_widgets/naka_widget_names_charmap.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_widget_names_charmap_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_widget_names_charmap_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_technichord_strings.bin: v10/maincpu/ui_widgets/naka_technichord_strings.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_technichord_strings_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_technichord_strings_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_widget_tables_2.bin: v10/maincpu/ui_widgets/naka_widget_tables_2.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_widget_tables_2_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_widget_tables_2_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_style_bitmaps.bin: v10/maincpu/ui_widgets/naka_style_bitmaps.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_style_bitmaps_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_style_bitmaps_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v10/maincpu/includes/generated/naka_widget_descriptors.bin: v10/maincpu/ui_widgets/naka_widget_descriptors.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_widget_descriptors_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_widget_descriptors_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf


v10/maincpu/includes/generated/naka_accomp7_widgets.bin: v10/maincpu/ui_widgets/naka_accomp7_widgets.c $(NAKA_TYPES_H) v10/maincpu/ui_widgets/naka_accomp7_widgets_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v10/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui_widgets/naka_accomp7_widgets_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# ToneKit parameter blocks — 118 blocks of 6-byte sound parameter records
v10/maincpu/includes/generated/tonekit_param_blocks.bin: v10/maincpu/ui_widgets/tonekit_param_blocks.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

# Sound config lookup — 25 x 234-byte channel configuration records
v10/maincpu/includes/generated/sound_config_lookup.bin: v10/maincpu/ui_widgets/sound_config_lookup.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v10/maincpu/includes/generated/voice_factory_presets.bin: v10/maincpu/audio/voice_factory_presets.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v10/maincpu/includes/generated/tonegen_param_table.bin: v10/maincpu/audio/tonegen_param_table.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

# Sound data C struct files — compiled to raw binaries, .incbin'd by assembly
v10/maincpu/includes/generated/sound_data_%.bin: v10/maincpu/audio/sound_data_%.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

# SepaOut config — compiled C struct with linker script for symbol resolution
v10/maincpu/includes/generated/sepaout_config.bin: v10/maincpu/ui/sepaout_config.c v10/maincpu/ui/sepaout_config_link.ld
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_LLD) -T v10/maincpu/ui/sepaout_config_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# GUI display struct data — compiled C struct
v10/maincpu/includes/generated/gui_display_struct_data.bin: v10/maincpu/includes/gui_display_struct_data.c
	@mkdir -p v10/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o


# V9 C data compilation rules (mirror v10 rules with v9 paths)
v9/maincpu/includes/generated/style_ui_paramblock_%.bin: v9/maincpu/style_ui/paramblock/%.c v9/maincpu/style_ui/screendata_types.h
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/style_ui_screendata_ctlonly.bin: v9/maincpu/style_ui/ctlonly.c v9/maincpu/style_ui/screendata_types.h v9/maincpu/style_ui/ctlonly_link.ld
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T v9/maincpu/style_ui/ctlonly_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v9/maincpu/includes/generated/style_ui_screendata_%.bin: v9/maincpu/style_ui/%.c v9/maincpu/style_ui/screendata_types.h
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/se_%.bin: v9/maincpu/audio/sound_editor_screens/se_%.c v9/maincpu/style_ui/screendata_types.h $(V9_SE_LINK_LD)
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(V9_SE_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v9/maincpu/includes/generated/accomp_%.bin: v9/maincpu/sequencer/accomp_screens/accomp_%.c v9/maincpu/style_ui/screendata_types.h $(V9_ACCOMP_LINK_LD)
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(V9_ACCOMP_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# V9 NAKA widget descriptors - generic rule for all naka bins
v9/maincpu/includes/generated/naka_%.bin: v9/maincpu/ui_widgets/naka_%.c $(V9_NAKA_TYPES_H) v9/maincpu/ui_widgets/naka_%_link.ld
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v9/maincpu/ui_widgets/naka_$*_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v9/maincpu/includes/generated/naka_control_menu_header.bin: v9/maincpu/ui_widgets/control_menu_header.c $(V9_NAKA_TYPES_H) $(V9_NAKA_LINK_LD)
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v9/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T $(V9_NAKA_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v9/maincpu/includes/generated/voice_factory_presets.bin: v9/maincpu/audio/voice_factory_presets.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/tonegen_param_table.bin: v9/maincpu/audio/tonegen_param_table.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/sound_data_%.bin: v9/maincpu/audio/sound_data_%.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/sepaout_config.bin: v9/maincpu/ui/sepaout_config.c v9/maincpu/ui/sepaout_config_link.ld
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_LLD) -T v9/maincpu/ui/sepaout_config_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v9/maincpu/includes/generated/gui_display_struct_data.bin: v9/maincpu/includes/gui_display_struct_data.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/tonekit_param_blocks.bin: v9/maincpu/ui_widgets/tonekit_param_blocks.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v9/maincpu/includes/generated/sound_config_lookup.bin: v9/maincpu/ui_widgets/sound_config_lookup.c
	@mkdir -p v9/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o


# V7 C data compilation rules (mirror v9 rules with v7 paths)
v7/maincpu/includes/generated/style_ui_paramblock_%.bin: v7/maincpu/style_ui/paramblock/%.c v7/maincpu/style_ui/screendata_types.h
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/style_ui_screendata_ctlonly.bin: v7/maincpu/style_ui/ctlonly.c v7/maincpu/style_ui/screendata_types.h v7/maincpu/style_ui/ctlonly_link.ld
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T v7/maincpu/style_ui/ctlonly_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v7/maincpu/includes/generated/style_ui_screendata_%.bin: v7/maincpu/style_ui/%.c v7/maincpu/style_ui/screendata_types.h
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/style_ui -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/se_%.bin: v7/maincpu/audio/sound_editor_screens/se_%.c v7/maincpu/style_ui/screendata_types.h $(V7_SE_LINK_LD)
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(V7_SE_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v7/maincpu/includes/generated/accomp_%.bin: v7/maincpu/sequencer/accomp_screens/accomp_%.c v7/maincpu/style_ui/screendata_types.h $(V7_ACCOMP_LINK_LD)
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/style_ui -o $@.o $<
	$(LLVM_LLD) -T $(V7_ACCOMP_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

# V7 NAKA widget descriptors - generic rule for all naka bins
v7/maincpu/includes/generated/naka_%.bin: v7/maincpu/ui_widgets/naka_%.c $(V7_NAKA_TYPES_H) v7/maincpu/ui_widgets/naka_%_link.ld
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T v7/maincpu/ui_widgets/naka_$*_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v7/maincpu/includes/generated/naka_control_menu_header.bin: v7/maincpu/ui_widgets/control_menu_header.c $(V7_NAKA_TYPES_H) $(V7_NAKA_LINK_LD)
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -I v7/maincpu/ui_widgets -o $@.o $<
	$(LLVM_LLD) -T $(V7_NAKA_LINK_LD) -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v7/maincpu/includes/generated/voice_factory_presets.bin: v7/maincpu/audio/voice_factory_presets.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/tonegen_param_table.bin: v7/maincpu/audio/tonegen_param_table.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/sound_data_%.bin: v7/maincpu/audio/sound_data_%.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/sepaout_config.bin: v7/maincpu/ui/sepaout_config.c v7/maincpu/ui/sepaout_config_link.ld
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_LLD) -T v7/maincpu/ui/sepaout_config_link.ld -o $@.elf $@.o
	$(LLVM_OBJCOPY) -O binary -j .text $@.elf $@
	@rm -f $@.o $@.elf

v7/maincpu/includes/generated/gui_display_struct_data.bin: v7/maincpu/includes/gui_display_struct_data.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/tonekit_param_blocks.bin: v7/maincpu/ui_widgets/tonekit_param_blocks.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

v7/maincpu/includes/generated/sound_config_lookup.bin: v7/maincpu/ui_widgets/sound_config_lookup.c
	@mkdir -p v7/maincpu/includes/generated
	$(CLANG) -target tlcs900 -ffreestanding -c -O2 -o $@.o $<
	$(LLVM_OBJCOPY) -O binary -j .text $@.o $@
	@rm -f $@.o

paramblocks: $(PARAMBLOCK_BINS)
screendata: $(SCREENDATA_BINS)
naka: $(NAKA_BINS)

# --- Maincpu ---
rebuilt_ROMs/kn5000_v10_program.llvm.o: v10/maincpu/kn5000_v10_program.s original_ROMs/kn5000_v10_program.rom $(C_DATA_BINS)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I v10/maincpu -o $@ $<

rebuilt_ROMs/kn5000_v10_program.llvm.elf: rebuilt_ROMs/kn5000_v10_program.llvm.o v10/maincpu/maincpu.ld
	$(LLVM_LLD) -T v10/maincpu/maincpu.ld -o $@ $<

rebuilt_ROMs/kn5000_v10_program.llvm.rom: rebuilt_ROMs/kn5000_v10_program.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- V9 Maincpu ---
rebuilt_ROMs/kn5000_v9_program.llvm.o: v9/maincpu/kn5000_v9_program.s original_ROMs/kn5000_v9_program.rom $(V9_C_DATA_BINS)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I v9/maincpu -o $@ $<

rebuilt_ROMs/kn5000_v9_program.llvm.elf: rebuilt_ROMs/kn5000_v9_program.llvm.o v9/maincpu/maincpu.ld
	$(LLVM_LLD) -T v9/maincpu/maincpu.ld -o $@ $<

rebuilt_ROMs/kn5000_v9_program.llvm.rom: rebuilt_ROMs/kn5000_v9_program.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- V7 Maincpu ---
# V7 bins are extracted from the v7 ROM, not compiled from C.
# Two-pass build: first pass uses v9 ELF for address fallback,
# second pass re-extracts using v7 ELF for correct transplant addresses.
v7-extract-bins: rebuilt_ROMs/kn5000_v9_program.llvm.elf $(V7_C_DATA_BINS)
	python3 scripts/build/extract_v7_bins.py

rebuilt_ROMs/kn5000_v7_program.llvm.o: v7/maincpu/kn5000_v7_program.s original_ROMs/kn5000_v7_program.rom v7-extract-bins
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I v7/maincpu -o $@ $<

rebuilt_ROMs/kn5000_v7_program.llvm.elf: rebuilt_ROMs/kn5000_v7_program.llvm.o v7/maincpu/maincpu.ld
	$(LLVM_LLD) -T v7/maincpu/maincpu.ld -o $@ $<

rebuilt_ROMs/kn5000_v7_program.llvm.rom: rebuilt_ROMs/kn5000_v7_program.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@
	@# Second pass: re-extract bins using v7 ELF (correct addresses), then rebuild
	python3 scripts/build/extract_v7_bins.py
	rm -f rebuilt_ROMs/kn5000_v7_program.llvm.o rebuilt_ROMs/kn5000_v7_program.llvm.elf $@
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I v7/maincpu -o rebuilt_ROMs/kn5000_v7_program.llvm.o v7/maincpu/kn5000_v7_program.s
	$(LLVM_LLD) -T v7/maincpu/maincpu.ld -o rebuilt_ROMs/kn5000_v7_program.llvm.elf rebuilt_ROMs/kn5000_v7_program.llvm.o
	$(LLVM_OBJCOPY) -O binary rebuilt_ROMs/kn5000_v7_program.llvm.elf $@

# --- Subcpu payload ---
rebuilt_ROMs/kn5000_subprogram_v142.llvm.o: v142/subcpu/kn5000_subprogram_v142.s
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I v142/subcpu -o $@ $<

rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf: rebuilt_ROMs/kn5000_subprogram_v142.llvm.o v142/subcpu/subcpu.ld
	$(LLVM_LLD) -T v142/subcpu/subcpu.ld -o $@ $<

rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom: rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@.full
	dd if=$@.full of=$@.part_a bs=1 count=256 2>/dev/null || exit 1
	dd if=$@.full of=$@.part_b bs=1 skip=60416 2>/dev/null || exit 1
	sync
	cat $@.part_a $@.part_b > $@
	rm -f $@.full $@.part_a $@.part_b

# --- Subcpu payload firmware-update image (whole-file SLIDE4K) ---
# original_ROMs/kn5000_subprogram_v142_compressed.rom is the v1.42 Sub-CPU
# payload as shipped on firmware-update disks ("Program DATA FILE PCK" /
# File Type 007, flashed to Custom Data 0x3E0000 by
# HANDLE_UPDATE_FILE_TYPE_ID_007h): an 11-byte header ("SLIDE4K\0" magic +
# 24-bit BIG-endian decompressed size, here 03 00 00 = 196,608) followed by
# the LZSS stream. The payload is already source-built, so recompressing the
# build output with the factory stream's decisions must reproduce the update
# image byte-for-byte. compress_lzss.py --strict aborts the build on any
# divergence and the cmp seals whole-file byte-identity (same guarantee the
# demo-preset pipeline provides for the in-ROM SLIDE4K blocks).
rebuilt_ROMs/kn5000_subprogram_v142_compressed.rom: rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom original_ROMs/kn5000_subprogram_v142_compressed.rom
	python3 scripts/build/compress_lzss.py $< $@ --strict --with-header \
		--reference original_ROMs/kn5000_subprogram_v142_compressed.rom
	cmp $@ original_ROMs/kn5000_subprogram_v142_compressed.rom
	@echo "  subprogram v142 update image OK (byte-identical)"

# --- Subcpu boot ---
rebuilt_ROMs/kn5000_subcpu_boot.llvm.o: subcpu/boot/kn5000_subcpu_boot.s
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I subcpu/boot -o $@ $<

rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf: rebuilt_ROMs/kn5000_subcpu_boot.llvm.o subcpu/boot/subcpu_boot.ld
	$(LLVM_LLD) -T subcpu/boot/subcpu_boot.ld -o $@ $<

rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom: rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- HDAE5000 ---
rebuilt_ROMs/hd-ae5000_v2_06i.llvm.o: hdae5000/hd-ae5000_v2_06i.s
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I hdae5000 -o $@ $<

rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf: rebuilt_ROMs/hd-ae5000_v2_06i.llvm.o hdae5000/hdae5000.ld
	$(LLVM_LLD) -T hdae5000/hdae5000.ld -o $@ $<

rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom: rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- Table data ---
rebuilt_ROMs/kn5000_table_data.llvm.o: table_data/kn5000_table_data.s table_data/help_databases.s $(DEMO_PRESET_COMPRESSED) $(HELP_DB_COMPRESSED)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I table_data -o $@ $<

rebuilt_ROMs/kn5000_table_data.llvm.elf: rebuilt_ROMs/kn5000_table_data.llvm.o table_data/table_data.ld
	$(LLVM_LLD) -T table_data/table_data.ld -o $@ $<

rebuilt_ROMs/kn5000_table_data.llvm.rom: rebuilt_ROMs/kn5000_table_data.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- Custom data ---
rebuilt_ROMs/kn5000_custom_data.llvm.o: custom_data/kn5000_custom_data.s
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I custom_data -o $@ $<

rebuilt_ROMs/kn5000_custom_data.llvm.elf: rebuilt_ROMs/kn5000_custom_data.llvm.o custom_data/custom_data.ld
	$(LLVM_LLD) -T custom_data/custom_data.ld -o $@ $<

rebuilt_ROMs/kn5000_custom_data.llvm.rom: rebuilt_ROMs/kn5000_custom_data.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# ============================================================================
# LLVM conversion targets (regenerate .s from ASL sources)
# ============================================================================
# These targets convert ASL .asm sources to LLVM .s files using the converter.
# Only needed when ASL sources change; the .s files are the authoritative source.

llvm-convert: scripts/converters/asl_to_llvm.py archive/asl/maincpu/kn5000_v10_program.asm archive/asl/tmp94c241.inc
	python scripts/converters/asl_to_llvm.py archive/asl/maincpu/kn5000_v10_program.asm --output-dir v10/maincpu

llvm-convert-subcpu: scripts/converters/asl_to_llvm.py archive/asl/subcpu/kn5000_subprogram_v142.asm archive/asl/tmp94c241.inc rebuilt_ROMs/kn5000_subprogram_v142.full
	python scripts/converters/asl_to_llvm.py archive/asl/subcpu/kn5000_subprogram_v142.asm --rom-base 0x0400 --rom-size 0x3EB00 --rom-file rebuilt_ROMs/kn5000_subprogram_v142.full --output-dir v142/subcpu

llvm-convert-boot: scripts/converters/asl_to_llvm.py archive/asl/subcpu/boot/kn5000_subcpu_boot.asm archive/asl/tmp94c241.inc
	python scripts/converters/asl_to_llvm.py archive/asl/subcpu/boot/kn5000_subcpu_boot.asm --rom-base 0xFE0000 --rom-size 0x20000 --rom-file original_ROMs/kn5000_subcpu_boot.ic30 --output-dir subcpu/boot

llvm-convert-hdae5000: scripts/converters/asl_to_llvm.py archive/asl/hdae5000/hd-ae5000_v2_06i.asm archive/asl/tmp94c241.inc
	python scripts/converters/asl_to_llvm.py archive/asl/hdae5000/hd-ae5000_v2_06i.asm --rom-base 0x280000 --rom-size 0x80000 --rom-file original_ROMs/hd-ae5000_v2_06i.ic4 --output-dir hdae5000

llvm-convert-tabledata: scripts/converters/asl_to_llvm.py archive/asl/table_data/kn5000_table_data.asm archive/asl/tmp94c241.inc
	python scripts/converters/asl_to_llvm.py archive/asl/table_data/kn5000_table_data.asm --rom-base 0x800000 --rom-size 0x200000 --rom-file original_ROMs/kn5000_table_data.rom --output-dir table_data

llvm-convert-customdata: scripts/converters/asl_to_llvm.py archive/asl/custom_data/kn5000_custom_data.asm archive/asl/tmp94c241.inc
	python scripts/converters/asl_to_llvm.py archive/asl/custom_data/kn5000_custom_data.asm --rom-base 0x300000 --rom-size 0x100000 --rom-file original_ROMs/kn5000_custom_data.ic19 --output-dir custom_data

llvm-convert-all: llvm-convert llvm-convert-subcpu llvm-convert-boot llvm-convert-hdae5000 llvm-convert-tabledata llvm-convert-customdata

# ============================================================================
# Legacy ASL build targets (archived sources)
# ============================================================================
ASL_PATH=../tools/asl
ASL=$(ASL_PATH)/asl -w
P2BIN=$(ASL_PATH)/p2bin

# ----------------------------------------------------------------------------
# Demo song presets (19 SLIDE4K-compressed blocks)
# ----------------------------------------------------------------------------
# Entries 0-17 live at 0x9C4050-0x9F94CB, entry 18 (the Feature Presentation) at
# 0x8E0000. Each block is an 8-byte "SLIDE4K\0" magic + a 24-bit BIG-ENDIAN
# uncompressed size, followed by the LZSS payload. (Endianness evidence: the
# v142 Sub-CPU update image's size field is 03 00 00 = 0x030000 = 196,608; the
# in-ROM demo blocks all have endian-symmetric size fields like 00 95 00.)
#
# CHECKED-IN SOURCE: midi/*.mid + sidecar/*.yaml
#   .mid   the musical content -- editable in any DAW
#   .yaml  everything MIDI cannot express: song header, cell topology, padding,
#          the exact stream order, running-status flags, and the few durations
#          MIDI cannot round-trip
#
#   .mid + .yaml -> demo_preset_NN.bin -> demo_preset_NN_compressed.bin -> ROM
#
# Both .bin stages are generated (and .gitignore'd). compress_lzss.py --strict
# aborts the build if a payload stops matching the factory stream, so an edit can
# never silently ship different music.

$(DEMO_PRESET_DIR)/demo_preset_%.bin: $(DEMO_PRESET_MIDI_DIR)/demo_preset_%.mid $(DEMO_PRESET_SIDECAR_DIR)/demo_preset_%.yaml
	python3 scripts/build/midi_to_preset.py --midi $< \
		--sidecar $(DEMO_PRESET_SIDECAR_DIR)/demo_preset_$*.yaml -o $@

$(DEMO_PRESET_DIR)/demo_preset_%_compressed.bin: $(DEMO_PRESET_DIR)/demo_preset_%.bin original_ROMs/demo_preset_%_compressed.original.bin
	python3 scripts/build/compress_lzss.py $< $@ --strict --reference original_ROMs/demo_preset_$*_compressed.original.bin

rebuild-demo-presets: $(DEMO_PRESET_COMPRESSED)

# Check every payload against the factory stream byte-for-byte.
verify-demo-presets: $(DEMO_PRESET_COMPRESSED)
	@for i in $(DEMO_PRESET_IDS); do \
		cmp -s $(DEMO_PRESET_DIR)/demo_preset_$${i}_compressed.bin \
		       original_ROMs/demo_preset_$${i}_compressed.original.bin \
		  && echo "  preset $$i OK" || echo "  preset $$i MISMATCH"; \
	done

# --- bootstrap ---------------------------------------------------------------
# Re-derive the checked-in source from the factory ROM. Only needed if the
# extraction itself changes; the results are committed.

decompress-demo-presets: original_ROMs/kn5000_table_data.rom
	python3 scripts/build/decompress_demo_presets.py --rom $< \
		--output-dir $(DEMO_PRESET_DIR) --emit-references

demo-midi: decompress-demo-presets
	python3 scripts/build/demo_preset_to_midi.py \
		$(foreach i,$(DEMO_PRESET_IDS),$(DEMO_PRESET_DIR)/demo_preset_$(i).bin) \
		-o $(DEMO_PRESET_MIDI_DIR) --drum-type 0x0C

demo-sidecars: decompress-demo-presets
	python3 scripts/build/preset_sidecar.py \
		$(foreach i,$(DEMO_PRESET_IDS),$(DEMO_PRESET_DIR)/demo_preset_$(i).bin) \
		-o $(DEMO_PRESET_SIDECAR_DIR)

# ----------------------------------------------------------------------------
# Help databases (6 SLIDE8K-compressed multilingual help-text blocks)
# ----------------------------------------------------------------------------
# Five live blocks (english/german/french/spanish/indonesian) live at ROM
# 0x988690/0x98BB3A/0x98F0DA/0x992A0C/0x9963FA inside the region covered by
# table_data/includes/icons_to_strings.bin (file offsets 0x43918/0x46DC2/
# 0x4A362/0x4DC94/0x51682); a sixth, german_stale, is a truncated remnant at
# ROM 0x983B3A (file offset 0x3EDC2).  Each block is an 11-byte "SLIDE8K\0"
# header + 24-bit BIG-endian decompressed size (always 0x9000) + an LZSS
# stream + ONE alignment pad byte of arbitrary value.  The checked-in source
# is the decompressed database in $(HELP_DB_DIR); the compressed payload
# (stream + pad, no header -- the header is emitted by help_databases.s) is
# rebuilt with compress_slide8k.py --strict --reference, which replays the
# factory encoder's decisions so the output is byte-identical (the final flag
# bytes have nonzero unused bits, so a plain re-encode would NOT byte-match).
#
#   help_db_<lang>.bin -> help_db_<lang>_compressed.bin -> ROM
#
# The original payload slices live in original_ROMs/help_db_*_compressed.
# original.bin (sliced once from icons_to_strings.bin at the offsets above,
# header excluded, pad byte included).

$(HELP_DB_DIR)/help_db_%_compressed.bin: $(HELP_DB_DIR)/help_db_%.bin original_ROMs/help_db_%_compressed.original.bin
	python3 scripts/build/compress_slide8k.py $< $@ --strict --reference original_ROMs/help_db_$*_compressed.original.bin

rebuild-help-databases: $(HELP_DB_COMPRESSED) $(HELP_DB_STALE_COMPRESSED)
	@echo "Help databases recompressed (byte-identical via --strict --reference)."

verify-help-databases: $(HELP_DB_COMPRESSED) $(HELP_DB_STALE_COMPRESSED)
	@for l in $(HELP_DB_LANGS) german_stale; do \
		cmp -s $(HELP_DB_DIR)/help_db_$${l}_compressed.bin \
		       original_ROMs/help_db_$${l}_compressed.original.bin \
		  && echo "  help db $$l OK" || echo "  help db $$l MISMATCH"; \
	done

# Regenerate the checked-in decompressed sources from the raw dump slice
# (one-shot; only needed if icons_to_strings.bin or the tooling changes).
decompress-help-databases:
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x3EDC2 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_german_stale.bin
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x43918 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_english.bin
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x46DC2 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_german.bin
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x4A362 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_french.bin
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x4DC94 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_spanish.bin
	python3 scripts/build/decompress_slide8k.py table_data/includes/icons_to_strings.bin --offset 0x51682 --expected-size 0x9000 --output $(HELP_DB_DIR)/help_db_indonesian.bin

asl-all: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom rebuilt_ROMs/kn5000_table_data.rebuilt.rom rebuilt_ROMs/kn5000_custom_data.rebuilt.rom rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom

rebuilt_ROMs/kn5000_v10_program.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/maincpu/kn5000_v10_program.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(ASL) -i v10/maincpu archive/asl/maincpu/kn5000_v10_program.asm -o rebuilt_ROMs/kn5000_v10_program.rebuilt.p

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/subcpu/kn5000_subprogram_v142.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p
	$(ASL) -i v142/subcpu archive/asl/subcpu/kn5000_subprogram_v142.asm -o rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p

rebuilt_ROMs/kn5000_table_data.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/table_data/kn5000_table_data.asm $(DEMO_PRESET_COMPRESSED)
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_table_data.rebuilt.p
	$(ASL) -i table_data archive/asl/table_data/kn5000_table_data.asm -o rebuilt_ROMs/kn5000_table_data.rebuilt.p

rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/subcpu/boot/kn5000_subcpu_boot.asm subcpu/boot/subcpu_boot_data_8000.bin
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p
	$(ASL) -i subcpu/boot archive/asl/subcpu/boot/kn5000_subcpu_boot.asm -o rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p

rebuilt_ROMs/kn5000_v10_program.rebuilt.rom: rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_v10_program.rebuilt.p rebuilt_ROMs/kn5000_v10_program.rebuilt.rom

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom: rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p rebuilt_ROMs/kn5000_subprogram_v142.full
	dd if=rebuilt_ROMs/kn5000_subprogram_v142.full of=part_a.rom bs=1 count=256
	dd if=rebuilt_ROMs/kn5000_subprogram_v142.full of=part_b.rom bs=1 skip=60416
	cat part_a.rom part_b.rom > rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom

rebuilt_ROMs/kn5000_table_data.rebuilt.rom: rebuilt_ROMs/kn5000_table_data.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_table_data.rebuilt.p rebuilt_ROMs/kn5000_table_data.rebuilt.rom

rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom: rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom

rebuilt_ROMs/kn5000_custom_data.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/custom_data/kn5000_custom_data.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_custom_data.rebuilt.p
	$(ASL) -i custom_data archive/asl/custom_data/kn5000_custom_data.asm -o rebuilt_ROMs/kn5000_custom_data.rebuilt.p

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/hdae5000/hd-ae5000_v2_06i.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(ASL) -i hdae5000 archive/asl/hdae5000/hd-ae5000_v2_06i.asm -o rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p

rebuilt_ROMs/kn5000_custom_data.rebuilt.rom: rebuilt_ROMs/kn5000_custom_data.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_custom_data.rebuilt.p rebuilt_ROMs/kn5000_custom_data.rebuilt.rom

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom: rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(P2BIN) rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom

# ============================================================================
# Documentation website targets
# ============================================================================
DOCS_DIR=../kn5000-docs
DOCS_GALLERY=$(DOCS_DIR)/assets/images/gallery

gallery:
	python scripts/build/convert_images.py $(DOCS_GALLERY)

issues:
	cd $(PROJECTS_ROOT)/kn5000_project && python scripts/export_issues_to_website.py $(DOCS_DIR)/issues.md

rom-status:
	python scripts/build/generate_rom_status_diagram.py

website: gallery issues rom-status
	@echo "Website content updated. Don't forget to commit kn5000-docs."

# ============================================================================
# Clean targets
# ============================================================================
clean:
	rm -f rebuilt_ROMs/kn5000_v10_program.llvm.*
	rm -f rebuilt_ROMs/kn5000_v9_program.llvm.*
	rm -rf v9/maincpu/includes/generated/
	rm -f rebuilt_ROMs/kn5000_v7_program.llvm.*
	rm -rf v7/maincpu/includes/generated/
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.llvm.*
	rm -f rebuilt_ROMs/kn5000_subprogram_v142_compressed.rom
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.llvm.*
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.llvm.*
	rm -f rebuilt_ROMs/kn5000_table_data.llvm.*
	rm -f rebuilt_ROMs/kn5000_custom_data.llvm.*
	rm -rf v10/maincpu/includes/generated/

clean-asl:
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.*
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.* rebuilt_ROMs/kn5000_subprogram_v142.full
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.*
	rm -f rebuilt_ROMs/kn5000_table_data.rebuilt.*
	rm -f rebuilt_ROMs/kn5000_custom_data.rebuilt.*
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.*
	rm -f part_a.rom part_b.rom

clean-all: clean clean-asl

# ============================================================================
# Effects-DSP (NEC uPD6383GF, IC311) microprogram disassembly tree -- dsp/
# ============================================================================
# Regenerate the annotated per-program listings + manifest from the Sub CPU ROM
# and the reverse-engineering tools, then byte-match-verify against the ROM.
# Both are deterministic; `make dsp && git diff --exit-code dsp/disasm` is a
# drift check.  See dsp/README.md.  Override the reused research tools with
# TOOLS=<path to kn7000_mame/tools> if they are not at ~/compartilhado.
TOOLS ?= $(HOME)/compartilhado/kn7000_mame/tools

dsp:
	python3 dsp/tools/gen_dsp_disasm.py --tools $(TOOLS)

dsp-verify:
	python3 dsp/verify.py --tools $(TOOLS)

# Regenerate the per-program STRUCTURAL flowcharts (Mermaid) in dsp/flowcharts/.
# Same inputs as `dsp`; shows signal flow, not a per-instruction dump.  Does not
# touch the .dsm listings, so it cannot affect the byte-match (dsp-verify).
dsp-flowcharts:
	python3 dsp/tools/gen_dsp_flowcharts.py --tools $(TOOLS)
