/* naka_sequencer_exit_link.ld — Linker script for naka_sequencer_exit.c  * v7 addresses where v7's own bytes agree:
 * scripts/generators/generate_v7_naka_link_scripts.py
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Linked widget descriptors */
NakaDesc_FuncTtlNo_B     = 0x00E270A6;
NakaDesc_Empty_C          = 0x00E270C2;
NakaDesc_Empty_D          = 0x00E270C8;
NakaDesc_FuncIndex        = 0x00E270CE;
NakaDesc_Mode             = 0x00E270F0;
NakaDesc_ColorFontPageFunc = 0x00E27100;
ClassProps_IvPnlWrExit              = 0x00E2713C;
NakaDesc_Empty_E          = 0x00E27142;
NakaDesc_Empty_F          = 0x00E27148;
NakaDesc_Empty_G          = 0x00E2714E;
NakaDesc_Empty_H          = 0x00E27154;
NakaDesc_Empty_I          = 0x00E2715A;
NakaDesc_StyleFunc        = 0x00E27160;
NakaDesc_Empty_J          = 0x00E2717A;

/* Proc handler functions */
EqOnOffFuncToggleProc     = 0x00F345BA;
MsgToTtlProc              = 0x00F2EFD0;
AcIndexWideToggleProc     = 0x00F2ECC7;
IvPlayExitProc            = 0x00F2EB4C;
HelpTtlProc               = 0x00F2E87A;
IvPnlWrExitProc           = 0x00F309AD;
IvSdrevProc               = 0x00F2E954;
IvSddspProc               = 0x00F2E9F3;
IvSdaccProc               = 0x00F2EAAE;
IvPunchExitProc           = 0x00F2EBD5;
IvAutoPunchExitProc       = 0x00F2EC4A;
AcPanicEditSwProc         = 0x00F2E508;
IvRealRecExitProc         = 0x00F2E466;
