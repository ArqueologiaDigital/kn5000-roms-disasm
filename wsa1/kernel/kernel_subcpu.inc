; ============================================================================
; kernel/kernel_subcpu.inc -- what the SHARED kernel source means on the SUB
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
; ★ Read together, these equates ARE subcpu (CPU 2, prom_c)'s kernel RAM map.
;   The other processor's is in kernel_maincpu.inc, and the two differ in
;   every row but one -- same kernel, different RAM.

.equ KERNEL_STACK_TOP,           0x0000FA00	; the kernel's own stack; different RAM maps
.equ KERNEL_CURRENT_TASK,        0x00000091	; word cell: pointer to the running task's control block, 0 = none
.equ KERNEL_PENDING_TICKS,       0x00000090	; byte cell: timer-3 ticks not yet serviced (INTT3_KernelTick raises it)
.equ KERNEL_TCB_BASE,            0x00000100	; task control blocks, stride 12
.equ KERNEL_TASK_COUNT,          0x00000003	; how many control blocks Kernel_InitRam clears
.equ KERNEL_READY_HEADS,         0x00000124	; ready-queue heads, stride 4, one per priority level
.equ KERNEL_READY_LEVELS,        0x00000002	; how many priority levels Kernel_Dispatch scans
.equ KERNEL_SEMA_QUEUES,         0x0000012C	; one wait-queue head per counting semaphore, stride 4
.equ KERNEL_SEMA_COUNTS,         0x0000013C	; the semaphore counts themselves, one byte each
.equ KERNEL_SEMA_COUNT,          0x00000004	; how many counting semaphores this CPU has
.equ KERNEL_SEMA_COUNT_IMAGE,    0x00F9810E	; ROM: the power-on image of KERNEL_SEMA_COUNTS
.equ KERNEL_MSGQ_WAITQ,          0x00000140	; one receiver wait-queue head per message queue, stride 4
.equ KERNEL_MSGQ_HEADS,          0x00000148	; one message-list head per message queue, stride 4
.equ KERNEL_MSGQ_COUNT,          0x00000002	; how many message queues this CPU has
.equ KERNEL_NODE_POOL,           0x00000150	; the message nodes themselves, stride 8
.equ KERNEL_NODE_COUNT,          0x00000004	; how many message nodes are in the pool
.equ KERNEL_FREE_LIST,           0x00000170	; head of the free-node list; the whole pool is appended to it at boot
.equ KERNEL_TIMERS,              0x00000174	; software-timer slots, stride 8
.equ KERNEL_TIMER_COUNT,         0x00000002	; same on both CPUs -- named so the RAM map above is complete   ⚠ SAME on both CPUs
.equ KERNEL_BOOT_TIMER_CALLBACK, 0x00F98112	; ROM: the callback in SoftTimer_Request_Boot's inline argument block
.equ KERNEL_TCB_TEMPLATE,        0xFFF980DE	; the task entry-point record array minus one 12-byte stride, with the 0xFF top byte the ROM literal actually carries
