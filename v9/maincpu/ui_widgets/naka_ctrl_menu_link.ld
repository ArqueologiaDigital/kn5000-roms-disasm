/* naka_ctrl_menu_link.ld — Linker script for control_menu_header.c
 *
 * Provides absolute symbol addresses for extern references.
 * These addresses correspond to labels in the main ROM ELF.
 *
 * To regenerate:
 *   llvm-nm rebuilt_ROMs/kn5000_v10_program.llvm.elf | grep 'Naka_PresentationRootState'
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* NAKA presentation root state handler (in kn5000_v10_program.s) */
Naka_PresentationRootState = 0x00EF013F;
