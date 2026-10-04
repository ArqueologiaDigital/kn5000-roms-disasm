/* prom_a.ld -- linker script for Technics SX-WSA1R wsa1_prom_a.ic12
 *
 * IC12, program EPROM, boot image of CPU 1 (IC1, "MICROCOMPUTER (MAIN)",
 * Toshiba TMP95C061 / TLCS-900/H).
 *
 * Base 0xF80000 is ESTABLISHED: 33 of 64 words at file offset 0x7FF00 point
 * into 0xF00000-0xFFFFFF, which is where a TMP95C061 fetches its reset PC
 * (0xFFFF00); that word is 0x00F826A9 and the code there is a boot block.
 *
 * ==========================================================================
 * CPU 1 MEMORY MAP -- programmed by RESET at 0xF826A9, MSAR/MAMR/BnCS block
 * at 0xF8272D-0xF82777.  Full argument, with every gap named:
 * notes/FINDINGS-memory-map.md.  The window sizes come from
 * scripts/analysis/mamr_reading_elimination.py, which kills the 64 KB-per-unit
 * reading of MAMR and lower-CS-wins priority using this machine's own firmware.
 * ==========================================================================
 *
 *   0x000000-0x00007F   internal I/O registers (tmp95c061.cpp:111-173)
 *   0x000080-0x0051FF   CS1  static RAM, cleared at boot -- LOWER BOUND, the
 *                            chip's real size is NOT ESTABLISHED
 *   0x005200-0x3FFFFF   CS1  NOT ESTABLISHED
 *   0x600000-0x6033FF   CS3  work DRAM, cleared at boot
 *   0x603400-0x603FFF   CS3  work DRAM, deliberately NOT cleared and live
 *                            (prom_b 0xF440A5) -- a preserved region
 *   0x604000-0x60FFFF   CS3  work DRAM, cleared at boot
 *   0x60EB80            CS3  initial stack pointer (set at 0xF85606)
 *   0x617800+n*0x100    CS3  256-byte record array (0xF61F5B / 0xF5E2F4)
 *   0x610000-0x67FFFF   CS3  NOT ESTABLISHED beyond ~0x617800
 *   0x680000-0x78FFFF   CS0  NOT ESTABLISHED -- no device referenced anywhere
 *   0x790000/0x790001   CS0  display-controller-shaped port, busy in bit 6 of
 *                            0x790000 (0xF8ECF4).  Part identity UNVERIFIED
 *   0x7A0000            CS0  byte port, ring-buffered via (0x605A3E)
 *   0x7B0004/0x7B0005   CS0  byte registers
 *   0x7C0000            CS0  inter-processor link port (strobe P7.0, busy P7.3)
 *   0x7E0008-0x7E0017   CS0  16-bit port; the one traced caller uses 0x7E0008
 *                            as a FIFO, 256 x 2 bytes (0xFE4CE0 / 0xFE509B)
 *   0x7F0000/0x7F0002   CS0  address/data register pair, slot (n<<5)|0x10
 *   0xE00000-0xEFFFFF   CS2  NOT ESTABLISHED -- never referenced by CPU 1
 *   0xF00000-0xF7FFFF   CS2  prom_b   (base CONFIRMED, four proofs)
 *   0xF80000-0xFFFFFF   CS2  prom_a   (this image)
 *   elsewhere           BEXCS  NOT ESTABLISHED
 *
 * ⚠ CS0's own window is the ONE row the elimination leaves open: either
 *   0x600000-0x7FFFFF (MSAR truncated to the window) or 0x780000-0x97FFFF
 *   (MSAR literal).  Both survivors put every device above on CS0.  Do not
 *   quote a CS0 range without this caveat.
 *
 * ⚠ BnCS/BEXCS bit layout, DREFCR and DMEMCR fields: NOT ESTABLISHED.  MAME
 *   stores these registers and decodes none of them.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF80000, LENGTH = 512K
}

SECTIONS {
  .text 0xF80000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Cross-ROM: prom_b routines prom_a reaches by number, several PC-relatively (calr / jr).
 * A `.set` constant would be folded into the 16-bit displacement and rejected; a symbol
 * defined here is relocated by ld.lld instead (scripts/tools/link_prom_a_to_prom_b.py,
 * 2026-10-03).  Cross-ref: wsa1/prom_b/wsa1_prom_b.s. */
T_ModuleInit_Phase2Veneer = 0xF40034;
T_F42C7C = 0xF42C7C;
T_CallbackQueue_ResetAndRestartTask2 = 0xF42E80;
sub_F7E39F_Nop = 0xF7E2D8;
PromB_LCD_ScreenRedraw_Begin = 0xF7E2D9;
PromB_LCD_ScreenRedraw_End = 0xF7E2E7;
sub_F7E2ED = 0xF7E2ED;
sub_F7E354 = 0xF7E354;
Blink_EnableThenStop_Copy = 0xF7F237;
Blink_DisableThenStop = 0xF7F245;
