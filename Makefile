ASL_PATH=/home/fsanches/devel/Projeto_KN5000/kn5000_homebrew/asl-current
ASL=$(ASL_PATH)/asl
P2BIN=$(ASL_PATH)/p2bin

all: rebuilt/kn5000_v10_program.rebuilt.rom

rebuilt/kn5000_v10_program.rebuilt.p:
	mkdir -p rebuilt
	$(ASL) kn5000_v10_program.asm -l -o rebuilt/kn5000_v10_program.rebuilt.p

rebuilt/kn5000_v10_program.rebuilt.rom: rebuilt/kn5000_v10_program.rebuilt.p
	$(P2BIN) rebuilt/kn5000_v10_program.rebuilt.p rebuilt/kn5000_v10_program.rebuilt.rom
	python compare_roms.py

clean:
	rm -f rebuilt/kn5000_v10_program.rebuilt.rom
	rm -f rebuilt/kn5000_v10_program.rebuilt.p
