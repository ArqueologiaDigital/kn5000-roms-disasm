# The draw-task command ring at RAM 0x03247C (fields at -10 alloc, -8 read, -4 write,
# -2 free bytes, 0x80 bytes of u32 entries).  The routines were named as if they dequeued
# and executed commands; they post to and take from the ring (Wave 2 claims review, checked
# 2026-10-02: Type2 stores XWA at the write index when more than 4 bytes are free and
# returns 0 when full; its caller retries, yielding priority, until the post succeeds).
s/\bDisplayCmd_ScanQueue_MatchDone\b/DrawRing_Post_Return/g
s/\bDisplayCmd_ScanQueue_Continue\b/DrawRing_Init/g
s/\bDisplayCmd_ScanQueue_Match\b/DrawRing_Post_Check/g
s/\bDisplayCmd_ScanQueue\b/DrawRing_Post_Retry/g
s/\bDisplayCmd_DequeueAndExecute\b/DrawRing_Post/g
s/\bDisplayCmd_Execute_Type1\b/DrawRing_TryTake_Load/g
s/\bDisplayCmd_Execute_Type2\b/DrawRing_TryPost/g
s/\bDisplayCmd_Execute_Type3\b/DrawRing_TryPost_Store/g
s/\bDisplayCmd_Execute\b/DrawRing_TryTake/g
