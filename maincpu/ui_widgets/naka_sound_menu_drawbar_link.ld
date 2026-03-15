/* naka_sound_menu_drawbar_link.ld — Linker script for naka_sound_menu_drawbar.c */

ENTRY(0)

SECTIONS {
    .text 0x00E80FE2 : SUBALIGN(1) { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Linked widget descriptors */
NakaLink_E80CAA                               = 0x00E80CAA;
NakaLink_E80CB0                               = 0x00E80CB0;
NakaLink_E80CB6                               = 0x00E80CB6;
NakaLink_E80CBC                               = 0x00E80CBC;
NakaLink_E80CD4                               = 0x00E80CD4;
NakaLink_E80CF0                               = 0x00E80CF0;

/* Proc handler functions */
AcSndEMenuProc                                = 0x00F7B665;
AcPleaseWaitProc                              = 0x00F7DE48;
IvMPverProc                                   = 0x00F7F422;
AcDrawSettingProc                             = 0x00F82A5E;
AcDrawbarNameProc                             = 0x00F82B06;
