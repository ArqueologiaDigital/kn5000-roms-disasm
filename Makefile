ASL_PATH=../tools/asl
ASL=$(ASL_PATH)/asl -w
P2BIN=$(ASL_PATH)/p2bin

LLVM_BIN=/mnt/shared/llvm-project/build/bin
LLVM_MC=$(LLVM_BIN)/llvm-mc
LLVM_LLD=$(LLVM_BIN)/ld.lld
LLVM_OBJCOPY=$(LLVM_BIN)/llvm-objcopy

# Primary build: LLVM assembly (authoritative source)
all: llvm-all
	python scripts/compare_roms.py

# LLVM build targets (primary)
llvm-all: rebuilt_ROMs/kn5000_v10_program.llvm.rom rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom rebuilt_ROMs/kn5000_table_data.llvm.rom rebuilt_ROMs/kn5000_custom_data.llvm.rom

# Full build: both ASL and LLVM (for verification)
all-full: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom rebuilt_ROMs/kn5000_table_data.rebuilt.rom rebuilt_ROMs/kn5000_custom_data.rebuilt.rom rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom llvm-all
	python scripts/compare_roms.py

rebuilt_ROMs/kn5000_v10_program.rebuilt.p: tmp94c241.inc maincpu/kn5000_v10_program.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(ASL) maincpu/kn5000_v10_program.asm -o rebuilt_ROMs/kn5000_v10_program.rebuilt.p

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p: tmp94c241.inc subcpu/kn5000_subprogram_v142.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p
	$(ASL) subcpu/kn5000_subprogram_v142.asm -o rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p

# Preset data assembly -> uncompressed binary -> LZSS compressed
# Uses --reference option to replay original compression decisions for byte-identical output.
PRESET_DATA_SRC=table_data/preset_data.asm
PRESET_DATA_DIR=table_data/includes

# Assemble preset_data.asm to produce uncompressed binary
$(PRESET_DATA_DIR)/preset_data.p: $(PRESET_DATA_SRC) $(PRESET_DATA_DIR)/preset_data_uncompressed.bin
	$(ASL) $(PRESET_DATA_SRC) -o $(PRESET_DATA_DIR)/preset_data.p

$(PRESET_DATA_DIR)/preset_data.bin: $(PRESET_DATA_DIR)/preset_data.p
	$(P2BIN) $(PRESET_DATA_DIR)/preset_data.p $(PRESET_DATA_DIR)/preset_data.bin

# LZSS compress the assembled binary
$(PRESET_DATA_DIR)/preset_data_compressed.bin: $(PRESET_DATA_DIR)/preset_data.bin
	python scripts/compress_lzss.py $(PRESET_DATA_DIR)/preset_data.bin $(PRESET_DATA_DIR)/preset_data_compressed.bin --reference original_ROMs/preset_data_compressed.original.bin

# Manual target to rebuild preset data from scratch
rebuild-preset-data: $(PRESET_DATA_DIR)/preset_data_compressed.bin

# Legacy target for recompression only (without reassembly)
recompress-lzss:
	python scripts/compress_lzss.py $(PRESET_DATA_DIR)/preset_data_uncompressed.bin $(PRESET_DATA_DIR)/preset_data_compressed.bin --reference original_ROMs/preset_data_compressed.original.bin

rebuilt_ROMs/kn5000_table_data.rebuilt.p: tmp94c241.inc table_data/kn5000_table_data.asm $(PRESET_DATA_DIR)/preset_data_compressed.bin
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_table_data.rebuilt.p
	$(ASL) table_data/kn5000_table_data.asm -o rebuilt_ROMs/kn5000_table_data.rebuilt.p

rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p: tmp94c241.inc subcpu/boot/kn5000_subcpu_boot.asm subcpu/boot/subcpu_boot_data_8000.bin
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p
	$(ASL) subcpu/boot/kn5000_subcpu_boot.asm -o rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.p


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

rebuilt_ROMs/kn5000_custom_data.rebuilt.p: tmp94c241.inc custom_data/kn5000_custom_data.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/kn5000_custom_data.rebuilt.p
	$(ASL) custom_data/kn5000_custom_data.asm -o rebuilt_ROMs/kn5000_custom_data.rebuilt.p

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p: tmp94c241.inc hdae5000/hd-ae5000_v2_06i.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(ASL) hdae5000/hd-ae5000_v2_06i.asm -o rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p

rebuilt_ROMs/kn5000_custom_data.rebuilt.rom: rebuilt_ROMs/kn5000_custom_data.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_custom_data.rebuilt.p rebuilt_ROMs/kn5000_custom_data.rebuilt.rom

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom: rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(P2BIN) rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom


# ============================================================================
# LLVM parallel builds
# ============================================================================

# --- Maincpu LLVM build ---
MAINCPU_LLVM_SRC=maincpu/llvm/kn5000_v10_program.s

rebuilt_ROMs/kn5000_v10_program.llvm.o: $(MAINCPU_LLVM_SRC) original_ROMs/kn5000_v10_program.rom
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I maincpu/llvm -o $@ $<

rebuilt_ROMs/kn5000_v10_program.llvm.elf: rebuilt_ROMs/kn5000_v10_program.llvm.o maincpu/llvm/maincpu.ld
	$(LLVM_LLD) -T maincpu/llvm/maincpu.ld -o $@ $<

rebuilt_ROMs/kn5000_v10_program.llvm.rom: rebuilt_ROMs/kn5000_v10_program.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- Subcpu payload LLVM build ---
SUBCPU_LLVM_SRC=subcpu/llvm/kn5000_subprogram_v142.s

rebuilt_ROMs/kn5000_subprogram_v142.llvm.o: $(SUBCPU_LLVM_SRC)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I subcpu/llvm -o $@ $<

rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf: rebuilt_ROMs/kn5000_subprogram_v142.llvm.o subcpu/llvm/subcpu.ld
	$(LLVM_LLD) -T subcpu/llvm/subcpu.ld -o $@ $<

rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom: rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@.full
	dd if=$@.full of=$@.part_a bs=1 count=256 2>/dev/null
	dd if=$@.full of=$@.part_b bs=1 skip=60416 2>/dev/null
	cat $@.part_a $@.part_b > $@
	rm -f $@.full $@.part_a $@.part_b

# --- Subcpu boot LLVM build ---
SUBCPU_BOOT_LLVM_SRC=subcpu/boot/llvm/kn5000_subcpu_boot.s

rebuilt_ROMs/kn5000_subcpu_boot.llvm.o: $(SUBCPU_BOOT_LLVM_SRC)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I subcpu/boot/llvm -o $@ $<

rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf: rebuilt_ROMs/kn5000_subcpu_boot.llvm.o subcpu/boot/llvm/subcpu_boot.ld
	$(LLVM_LLD) -T subcpu/boot/llvm/subcpu_boot.ld -o $@ $<

rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom: rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- HDAE5000 LLVM build ---
HDAE5000_LLVM_SRC=hdae5000/llvm/hd-ae5000_v2_06i.s

rebuilt_ROMs/hd-ae5000_v2_06i.llvm.o: $(HDAE5000_LLVM_SRC)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I hdae5000/llvm -o $@ $<

rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf: rebuilt_ROMs/hd-ae5000_v2_06i.llvm.o hdae5000/llvm/hdae5000.ld
	$(LLVM_LLD) -T hdae5000/llvm/hdae5000.ld -o $@ $<

rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom: rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- Table data LLVM build ---
TABLE_DATA_LLVM_SRC=table_data/llvm/kn5000_table_data.s

rebuilt_ROMs/kn5000_table_data.llvm.o: $(TABLE_DATA_LLVM_SRC)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I table_data/llvm -o $@ $<

rebuilt_ROMs/kn5000_table_data.llvm.elf: rebuilt_ROMs/kn5000_table_data.llvm.o table_data/llvm/table_data.ld
	$(LLVM_LLD) -T table_data/llvm/table_data.ld -o $@ $<

rebuilt_ROMs/kn5000_table_data.llvm.rom: rebuilt_ROMs/kn5000_table_data.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- Custom data LLVM build ---
CUSTOM_DATA_LLVM_SRC=custom_data/llvm/kn5000_custom_data.s

rebuilt_ROMs/kn5000_custom_data.llvm.o: $(CUSTOM_DATA_LLVM_SRC)
	mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I custom_data/llvm -o $@ $<

rebuilt_ROMs/kn5000_custom_data.llvm.elf: rebuilt_ROMs/kn5000_custom_data.llvm.o custom_data/llvm/custom_data.ld
	$(LLVM_LLD) -T custom_data/llvm/custom_data.ld -o $@ $<

rebuilt_ROMs/kn5000_custom_data.llvm.rom: rebuilt_ROMs/kn5000_custom_data.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# --- LLVM conversion targets ---
llvm-convert: scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm tmp94c241.inc
	python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm

llvm-convert-subcpu: scripts/asl_to_llvm.py subcpu/kn5000_subprogram_v142.asm tmp94c241.inc rebuilt_ROMs/kn5000_subprogram_v142.full
	python scripts/asl_to_llvm.py subcpu/kn5000_subprogram_v142.asm --rom-base 0x0400 --rom-size 0x3EB00 --rom-file rebuilt_ROMs/kn5000_subprogram_v142.full --output-dir subcpu/llvm

llvm-convert-boot: scripts/asl_to_llvm.py subcpu/boot/kn5000_subcpu_boot.asm tmp94c241.inc
	python scripts/asl_to_llvm.py subcpu/boot/kn5000_subcpu_boot.asm --rom-base 0xFE0000 --rom-size 0x20000 --rom-file original_ROMs/kn5000_subcpu_boot.ic30 --output-dir subcpu/boot/llvm

llvm-convert-hdae5000: scripts/asl_to_llvm.py hdae5000/hd-ae5000_v2_06i.asm tmp94c241.inc
	python scripts/asl_to_llvm.py hdae5000/hd-ae5000_v2_06i.asm --rom-base 0x280000 --rom-size 0x80000 --rom-file original_ROMs/hd-ae5000_v2_06i.ic4 --output-dir hdae5000/llvm

llvm-convert-tabledata: scripts/asl_to_llvm.py table_data/kn5000_table_data.asm tmp94c241.inc
	python scripts/asl_to_llvm.py table_data/kn5000_table_data.asm --rom-base 0x800000 --rom-size 0x200000 --rom-file original_ROMs/kn5000_table_data.rom --output-dir table_data/llvm

llvm-convert-customdata: scripts/asl_to_llvm.py custom_data/kn5000_custom_data.asm tmp94c241.inc
	python scripts/asl_to_llvm.py custom_data/kn5000_custom_data.asm --rom-base 0x300000 --rom-size 0x100000 --rom-file original_ROMs/kn5000_custom_data.ic19 --output-dir custom_data/llvm

llvm-convert-all: llvm-convert llvm-convert-subcpu llvm-convert-boot llvm-convert-hdae5000 llvm-convert-tabledata llvm-convert-customdata

clean_llvm:
	rm -f rebuilt_ROMs/kn5000_v10_program.llvm.*
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.llvm.*
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.llvm.*
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.llvm.*
	rm -f rebuilt_ROMs/kn5000_table_data.llvm.*
	rm -f rebuilt_ROMs/kn5000_custom_data.llvm.*

# Documentation website targets
DOCS_DIR=../kn5000-docs
DOCS_GALLERY=$(DOCS_DIR)/assets/images/gallery

gallery:
	python scripts/convert_images.py $(DOCS_GALLERY)

issues:
	cd /mnt/shared/kn5000_project && python scripts/export_issues_to_website.py $(DOCS_DIR)/issues.md

rom-status:
	python scripts/generate_rom_status_diagram.py

# Update all website content (gallery + issues + rom status diagram)
website: gallery issues rom-status
	@echo "Website content updated. Don't forget to commit kn5000-docs."

clean: clean_subcpu clean_subcpu_boot clean_maincpu clean_table_data clean_custom_data clean_hdae5000 clean_llvm

clean_maincpu:
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.*

clean_subcpu:
	rm -f part_a.rom
	rm -f part_b.rom
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.full
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.*

clean_table_data:
	rm -f rebuilt_ROMs/kn5000_table_data.rebuilt.*

clean_preset_data:
	rm -f table_data/includes/preset_data.p
	rm -f table_data/includes/preset_data.bin

clean_subcpu_boot:
	rm -f rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.*

clean_custom_data:
	rm -f rebuilt_ROMs/kn5000_custom_data.rebuilt.*

clean_hdae5000:
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.*
