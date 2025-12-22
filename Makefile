ASL_PATH=/home/fsanches/devel/Projeto_KN5000/kn5000_homebrew/asl-current
ASL=$(ASL_PATH)/asl
P2BIN=$(ASL_PATH)/p2bin

all: kn5000_v10_rebuilt.rom

kn5000_v10_rebuilt.p:
	$(ASL) kn5000_v10_program.asm -l -o kn5000_v10_rebuilt.p

kn5000_v10_rebuilt.rom: kn5000_v10_rebuilt.p
	$(P2BIN) kn5000_v10_rebuilt.p kn5000_v10_rebuilt.rom
	python compare_roms.py

clean:
	rm -f kn5000_v10_rebuilt.rom
	rm -f kn5000_v10_rebuilt.p
