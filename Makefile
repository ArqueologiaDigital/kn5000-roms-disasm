LLVM_BIN=/mnt/shared/llvm-project/build/bin
LLVM_MC=$(LLVM_BIN)/llvm-mc
LLVM_LLD=$(LLVM_BIN)/ld.lld -e 0
LLVM_OBJCOPY=$(LLVM_BIN)/llvm-objcopy
CLANG=$(LLVM_BIN)/clang

.PHONY: all llvm-all paramblocks screendata naka clean clean-asl clean-all
.PHONY: llvm-convert llvm-convert-all asl-all gallery issues rom-status website
.PHONY: rebuild-preset-data recompress-lzss clean-preset-data decompress-demo-presets

# Primary build: LLVM assembly (authoritative source)
all: llvm-all
	python scripts/build/compare_roms.py

# LLVM build targets (primary)
llvm-all: rebuilt_ROMs/kn5000_v10_program.llvm.rom rebuilt_ROMs/kn5000_v9_program.llvm.rom rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom rebuilt_ROMs/kn5000_table_data.llvm.rom rebuilt_ROMs/kn5000_custom_data.llvm.rom

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
rebuilt_ROMs/kn5000_table_data.llvm.o: table_data/kn5000_table_data.s
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

# Preset data assembly -> uncompressed binary -> LZSS compressed
# Uses --reference option to replay original compression decisions for byte-identical output.
PRESET_DATA_SRC=archive/asl/table_data/preset_data.asm
PRESET_DATA_DIR=table_data/includes

$(PRESET_DATA_DIR)/preset_data.p: $(PRESET_DATA_SRC) $(PRESET_DATA_DIR)/preset_data_uncompressed.bin
	$(ASL) $(PRESET_DATA_SRC) -o $(PRESET_DATA_DIR)/preset_data.p

$(PRESET_DATA_DIR)/preset_data.bin: $(PRESET_DATA_DIR)/preset_data.p
	$(P2BIN) $(PRESET_DATA_DIR)/preset_data.p $(PRESET_DATA_DIR)/preset_data.bin

$(PRESET_DATA_DIR)/preset_data_compressed.bin: $(PRESET_DATA_DIR)/preset_data.bin
	python scripts/build/compress_lzss.py $(PRESET_DATA_DIR)/preset_data.bin $(PRESET_DATA_DIR)/preset_data_compressed.bin --reference original_ROMs/preset_data_compressed.original.bin

rebuild-preset-data: $(PRESET_DATA_DIR)/preset_data_compressed.bin

recompress-lzss:
	python scripts/build/compress_lzss.py $(PRESET_DATA_DIR)/preset_data_uncompressed.bin $(PRESET_DATA_DIR)/preset_data_compressed.bin --reference original_ROMs/preset_data_compressed.original.bin

# Decompress all 19 demo song preset SLIDE4K blocks from the built Table Data ROM.
# Entry 18 = Feature Demo preset (same as preset_data_uncompressed.bin).
# Entries 0-17 are inside icons_to_strings.bin at ROM addresses 0x9C4050-0x9F9FFF.
# These decompressed files are for analysis; the build uses the original compressed data.
DEMO_PRESET_DIR=table_data/includes/demo_presets
decompress-demo-presets: rebuilt_ROMs/kn5000_table_data.llvm.rom
	python3 scripts/build/decompress_demo_presets.py --rom $< --output-dir $(DEMO_PRESET_DIR)

asl-all: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom rebuilt_ROMs/kn5000_table_data.rebuilt.rom rebuilt_ROMs/kn5000_custom_data.rebuilt.rom rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom

rebuilt_ROMs/kn5000_v10_program.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/maincpu/kn5000_v10_program.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(ASL) archive/asl/maincpu/kn5000_v10_program.asm -o rebuilt_ROMs/kn5000_v10_program.rebuilt.p

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/subcpu/kn5000_subprogram_v142.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p
	$(ASL) archive/asl/subcpu/kn5000_subprogram_v142.asm -o rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p

rebuilt_ROMs/kn5000_table_data.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/table_data/kn5000_table_data.asm $(PRESET_DATA_DIR)/preset_data_compressed.bin
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_table_data.rebuilt.p
	$(ASL) archive/asl/table_data/kn5000_table_data.asm -o rebuilt_ROMs/kn5000_table_data.rebuilt.p

rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/subcpu/boot/kn5000_subcpu_boot.asm subcpu/boot/subcpu_boot_data_8000.bin
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p
	$(ASL) archive/asl/subcpu/boot/kn5000_subcpu_boot.asm -o rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p

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
	$(ASL) archive/asl/custom_data/kn5000_custom_data.asm -o rebuilt_ROMs/kn5000_custom_data.rebuilt.p

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p: archive/asl/tmp94c241.inc archive/asl/hdae5000/hd-ae5000_v2_06i.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(ASL) archive/asl/hdae5000/hd-ae5000_v2_06i.asm -o rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p

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
	cd /mnt/shared/kn5000_project && python scripts/export_issues_to_website.py $(DOCS_DIR)/issues.md

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
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.llvm.*
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

clean-preset-data:
	rm -f table_data/includes/preset_data.p
	rm -f table_data/includes/preset_data.bin
