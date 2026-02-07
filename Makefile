ASL_PATH=../tools/asl
ASL=$(ASL_PATH)/asl -w
P2BIN=$(ASL_PATH)/p2bin

all: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom rebuilt_ROMs/kn5000_subcpu_boot.rebuilt.rom rebuilt_ROMs/kn5000_table_data.rebuilt.rom rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom
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

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p: tmp94c241.inc hdae5000/hd-ae5000_v2_06i.asm
	mkdir -p rebuilt_ROMs
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(ASL) hdae5000/hd-ae5000_v2_06i.asm -o rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p

rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom: rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p
	$(P2BIN) rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.p rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.rom


# Documentation website targets
DOCS_DIR=../kn5000-docs
DOCS_GALLERY=$(DOCS_DIR)/assets/images/gallery

gallery:
	python scripts/convert_images.py $(DOCS_GALLERY)

issues:
	python scripts/export_issues_to_website.py $(DOCS_DIR)/issues.md

rom-status:
	python scripts/generate_rom_status_diagram.py

# Update all website content (gallery + issues + rom status diagram)
website: gallery issues rom-status
	@echo "Website content updated. Don't forget to commit kn5000-docs."

clean: clean_subcpu clean_subcpu_boot clean_maincpu clean_table_data clean_hdae5000

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

clean_hdae5000:
	rm -f rebuilt_ROMs/hd-ae5000_v2_06i.rebuilt.*
