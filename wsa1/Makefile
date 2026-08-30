# Technics SX-WSA1R ROM disassembly -- LLVM build
#
# Mirrors the practice of ../kn5000-roms-disasm: the assembly sources are the
# authoritative form, and the ONLY thing that certifies them is that reassembling
# reproduces the original ROM byte for byte. Run the gate, never a percentage:
#
#     python3 scripts/analysis/assert_byte_identical.py
#
PROJECTS_ROOT ?= $(HOME)/compartilhado

LLVM_BIN=$(PROJECTS_ROOT)/llvm-project/build/bin
LLVM_MC=$(LLVM_BIN)/llvm-mc
LLVM_LLD=$(LLVM_BIN)/ld.lld -e 0
LLVM_OBJCOPY=$(LLVM_BIN)/llvm-objcopy

PROMS = a b c d

# ⚠ EVERY FILE AN IMAGE PULLS IN IS A PREREQUISITE.  The gate rebuilds before it
# compares, but `make` only rebuilds what it knows is stale: while these were
# missing, an edit to kernel/kernel.s left prom_c's object untouched and the gate
# passed on a stale build.  It was caught by a six-byte failure that survived the
# fix -- the fix had never been assembled.
KERNEL_SRC = kernel/kernel.s kernel/kernel_maincpu.inc kernel/kernel_subcpu.inc
COMMON_INC = include/tmp95c061_sfr.inc include/tlcs900_mem_ops.inc

# prom_c is no longer one file: since the per-subject split it is a master
# listing that `.include`s 26 subject sources in address order (the split, its
# rationale and its preservation proof are notes/prom_c_split.py).  A WILDCARD
# is used deliberately -- a hand-kept list is the same stale-build trap the
# comment above describes, one file further out, and it would go wrong silently.
# ⚠ THE MASTER MUST STAY FIRST: the recipe assembles `$<`.
PROM_C_SRC = prom_c/wsa1_prom_c.s \
             $(filter-out prom_c/wsa1_prom_c.s,$(wildcard prom_c/*.s prom_c/*/*.s))

.PHONY: all clean
.SECONDARY:

all: rebuilt_ROMs/wsa1_prom_a.llvm.rom rebuilt_ROMs/wsa1_prom_b.llvm.rom rebuilt_ROMs/wsa1_prom_c.llvm.rom rebuilt_ROMs/wsa1_prom_d.llvm.rom

rebuilt_ROMs/wsa1_prom_a.llvm.o: prom_a/wsa1_prom_a.s $(COMMON_INC) $(KERNEL_SRC)
	@mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I . -I prom_a -o $@ $<

rebuilt_ROMs/wsa1_prom_a.llvm.elf: rebuilt_ROMs/wsa1_prom_a.llvm.o prom_a/prom_a.ld
	$(LLVM_LLD) -T prom_a/prom_a.ld -o $@ $<

rebuilt_ROMs/wsa1_prom_a.llvm.rom: rebuilt_ROMs/wsa1_prom_a.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

rebuilt_ROMs/wsa1_prom_b.llvm.o: prom_b/wsa1_prom_b.s $(COMMON_INC)
	@mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I . -I prom_b -o $@ $<

rebuilt_ROMs/wsa1_prom_b.llvm.elf: rebuilt_ROMs/wsa1_prom_b.llvm.o prom_b/prom_b.ld
	$(LLVM_LLD) -T prom_b/prom_b.ld -o $@ $<

rebuilt_ROMs/wsa1_prom_b.llvm.rom: rebuilt_ROMs/wsa1_prom_b.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

rebuilt_ROMs/wsa1_prom_c.llvm.o: $(PROM_C_SRC) $(COMMON_INC) $(KERNEL_SRC)
	@mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I . -I prom_c -o $@ $<

rebuilt_ROMs/wsa1_prom_c.llvm.elf: rebuilt_ROMs/wsa1_prom_c.llvm.o prom_c/prom_c.ld
	$(LLVM_LLD) -T prom_c/prom_c.ld -o $@ $<

rebuilt_ROMs/wsa1_prom_c.llvm.rom: rebuilt_ROMs/wsa1_prom_c.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

# prom_d is FOUR files: wsa1_prom_d.s is the header plus three .include lines.
# Mirrors ../kn5000-roms-disasm/table_data/, which splits the same database the
# same way.  All three parts are prerequisites -- see the warning above; an
# include that is not listed here rebuilds nothing and the gate passes stale.
PROM_D_PARTS = prom_d/tone_database_directory.s prom_d/tone_database_records.s \
               prom_d/tone_database_aux.s

rebuilt_ROMs/wsa1_prom_d.llvm.o: prom_d/wsa1_prom_d.s $(PROM_D_PARTS) $(COMMON_INC)
	@mkdir -p rebuilt_ROMs
	$(LLVM_MC) -triple=tlcs900 -filetype=obj -I . -I prom_d -o $@ $<

rebuilt_ROMs/wsa1_prom_d.llvm.elf: rebuilt_ROMs/wsa1_prom_d.llvm.o prom_d/prom_d.ld
	$(LLVM_LLD) -T prom_d/prom_d.ld -o $@ $<

rebuilt_ROMs/wsa1_prom_d.llvm.rom: rebuilt_ROMs/wsa1_prom_d.llvm.elf
	$(LLVM_OBJCOPY) -O binary $< $@

clean:
	rm -rf rebuilt_ROMs
