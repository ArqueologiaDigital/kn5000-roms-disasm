; KN5000 Main CPU Program ROM - LLVM build (Phase 1: binary include)
; This file includes the original ROM binary directly to validate the
; LLVM toolchain pipeline (llvm-mc → ld.lld → llvm-objcopy).
; Phase 2 will replace this with converted assembly source.

	.text
	.incbin "../../original_ROMs/kn5000_v10_program.rom"
