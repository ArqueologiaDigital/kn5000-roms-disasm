ASL_PATH=/home/fsanches/devel/Projeto_KN5000/kn5000_homebrew/asl-current
ASL=$(ASL_PATH)/asl
P2BIN=$(ASL_PATH)/p2bin

all: rebuilt_ROMs/kn5000_v10_program.rebuilt.rom
	python compare_roms.py

rebuilt_ROMs/kn5000_v10_program.rebuilt.p:
	mkdir -p rebuilt_ROMs
	$(ASL) maincpu/kn5000_v10_program.asm -l -o rebuilt_ROMs/kn5000_v10_program.rebuilt.p

rebuilt_ROMs/kn5000_v10_program.rebuilt.rom: rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	$(P2BIN) rebuilt_ROMs/kn5000_v10_program.rebuilt.p rebuilt_ROMs/kn5000_v10_program.rebuilt.rom

clean:
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.p
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.rom
	rm -f rebuilt_ROMs/kn5000_v10_program.rebuilt.unidasm

