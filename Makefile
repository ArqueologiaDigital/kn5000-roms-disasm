ASL_PATH=/home/fsanches/devel/Projeto_KN5000/kn5000_homebrew/asl-current
ASL=$(ASL_PATH)/asl
P2BIN=$(ASL_PATH)/p2bin

all: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom
	python compare_roms.py

rebuilt_ROMs/kn5000_v10_program.rebuilt.p:
	mkdir -p rebuilt_ROMs
	$(ASL) maincpu/kn5000_v10_program.asm -l -o rebuilt_ROMs/kn5000_v10_program.rebuilt.p

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p:
	mkdir -p rebuilt_ROMs
	$(ASL) subcpu/kn5000_subprogram_v142.asm -l -o rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p


rebuilt_ROMs/kn5000_v10_program.rebuilt.rom: rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_v10_program.rebuilt.p rebuilt_ROMs/kn5000_v10_program.rebuilt.rom

rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom: rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.p rebuilt_ROMs/kn5000_subprogram_v142.full
	dd if=rebuilt_ROMs/kn5000_subprogram_v142.full of=part_a.rom bs=1 count=256
	dd if=rebuilt_ROMs/kn5000_subprogram_v142.full of=part_b.rom bs=1 skip=60416
	cat part_a.rom part_b.rom > rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom

clean: clean_subcpu clean_maincpu

clean_maincpu:
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.*

clean_subcpu:
	rm part_a.rom
	rm part_b.rom
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.full
	rm -f rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.*
