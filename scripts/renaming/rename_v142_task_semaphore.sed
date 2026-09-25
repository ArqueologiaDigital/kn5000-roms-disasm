# Sub-CPU v1.42 task-kernel names settled 2026-09-25 (lane subcpu).  Evidence per rename is in
# the headers written with it and in notes/FINDINGS-subcpu-maincpu-shared-code.md.
#  - TaskQueue_Operations_Opaque: its own header calls it "wait on my own pending count" and the
#    TaskSched_Wake_Task header names the consumer TASKSCHED_BLOCK_SELF.
#  - TaskSem_AddrCalc_Opaque: header "non-destructive read of semaphore A's count".
#  - TaskSched_PreemptiveYield_INT: semaphore V(): count at 0x1091+A / wait queue at 0x107E+4A
#    (the addresses the TaskSem_GetCount header documents); main-CPU twin is Audio_Lock_Release.
#  - TaskQueue_Dequeue_Guard_*: the arms of the no-reschedule copy of that V() that follows it.
s/\bTaskQueue_Operations_Opaque\b/TaskSched_Block_Self/g
s/\bTaskSem_AddrCalc_Opaque\b/TaskSem_GetCount/g
s/\bTaskSched_PreemptiveYield_INT_Dequeue\b/TaskSem_Release_WakeWaiter/g
s/\bTaskSched_PreemptiveYield_INT_Empty\b/TaskSem_Release_NoWaiter/g
s/\bTaskSched_PreemptiveYield_INT\b/TaskSem_Release/g
s/\bTaskQueue_Dequeue_Guard_Dequeue\b/TaskSem_Release_NoResched_WakeWaiter/g
s/\bTaskQueue_Dequeue_Guard_Empty\b/TaskSem_Release_NoResched_NoWaiter/g
