; ============================================================================
; kernel/kernel_maincpu.inc -- what the SHARED kernel source means on the MAIN
; processor of the Technics SX-WSA1R.
; ============================================================================
;
; kernel/kernel.s is ONE source assembled into BOTH CPUs.  Everything that
; genuinely differs between the two copies is named here and nowhere else, so
; the shared body never has to ask which processor it is being built for.
;
; ⚠ EVERY VALUE BELOW IS A MEASUREMENT, not a decision.  Each one is the
;   literal the ROM carries at the sites listed by
;       python3 notes/kernel_join_probe.py --symbols
;   and if one of them is wrong by a single byte the image stops rebuilding:
;       python3 scripts/analysis/assert_byte_identical.py
;
; ★ Read together, these equates ARE maincpu (CPU 1, prom_a)'s kernel RAM map.
;   The other processor's is in kernel_subcpu.inc, and the two differ in
;   every row but one -- same kernel, different RAM.

; prom_a already defines the TLCS-900 byte-emitter macros (m_ld_rm,
; m_st_mr16, m_ldc_cr_reg, ...) near the top of its own file, so kernel.s
; must NOT define them again -- llvm-mc rejects a redefined macro.  prom_c
; has no such block, which is why the definitions in kernel.s are guarded
; on this symbol rather than being unconditional.
.equ KERNEL_MEM_OPS_PROVIDED, 1

.equ KERNEL_STACK_TOP,           0x0060EB80	; the kernel's own stack; different RAM maps
.equ KERNEL_CURRENT_TASK,        0x000000BF	; word cell: pointer to the running task's control block, 0 = none
.equ KERNEL_PENDING_TICKS,       0x000000BE	; byte cell: timer-3 ticks not yet serviced (INTT3_KernelTick raises it)
.equ KERNEL_TCB_BASE,            0x00000300	; task control blocks, stride 12
.equ KERNEL_TASK_COUNT,          0x00000004	; how many control blocks Kernel_InitRam clears
.equ KERNEL_READY_HEADS,         0x00000330	; ready-queue heads, stride 4, one per priority level
.equ KERNEL_READY_LEVELS,        0x00000003	; how many priority levels Kernel_Dispatch scans
.equ KERNEL_SEMA_QUEUES,         0x0000033C	; one wait-queue head per counting semaphore, stride 4
.equ KERNEL_SEMA_COUNTS,         0x0000035C	; the semaphore counts themselves, one byte each
.equ KERNEL_SEMA_COUNT,          0x00000008	; how many counting semaphores this CPU has
.equ KERNEL_SEMA_COUNT_IMAGE,    0x00F85EBA	; ROM: the power-on image of KERNEL_SEMA_COUNTS
.equ KERNEL_MSGQ_WAITQ,          0x00000364	; one receiver wait-queue head per message queue, stride 4
.equ KERNEL_MSGQ_HEADS,          0x00000374	; one message-list head per message queue, stride 4
.equ KERNEL_MSGQ_COUNT,          0x00000004	; how many message queues this CPU has
.equ KERNEL_NODE_POOL,           0x00000384	; the message nodes themselves, stride 8
.equ KERNEL_NODE_COUNT,          0x00000008	; how many message nodes are in the pool
.equ KERNEL_FREE_LIST,           0x000003C4	; head of the free-node list; the whole pool is appended to it at boot
.equ KERNEL_TIMERS,              0x000003C8	; software-timer slots, stride 8
.equ KERNEL_TIMER_COUNT,         0x00000002	; same on both CPUs -- named so the RAM map above is complete   ⚠ SAME on both CPUs
.equ KERNEL_BOOT_TIMER_CALLBACK, 0x00F85EC2	; ROM: the callback in SoftTimer_Request_Boot's inline argument block
.equ KERNEL_TCB_TEMPLATE,        0xFFF85E7E	; the task entry-point record array minus one 12-byte stride, with the 0xFF top byte the ROM literal actually carries
