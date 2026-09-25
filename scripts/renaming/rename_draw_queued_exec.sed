# <Prim>_ParamBlock -> <Prim>_QueuedExec in ui/drawing_primitives.s (v10/v9/v7): the blocks are
# the executors DrawTask_FuncDispatch calls for queued draw commands, not parameter data.
# Applied by scripts/converters/convert_draw_queued_exec.py --apply.
s/\bDrawLine_ParamBlock\b/DrawLine_QueuedExec/g
s/\bDrawBox_ParamBlock\b/DrawBox_QueuedExec/g
s/\bDrawFrame_ParamBlock\b/DrawFrame_QueuedExec/g
s/\bMovePixels_ParamBlock\b/MovePixels_QueuedExec/g
s/\bDrawBitmap_ParamBlock\b/DrawBitmap_QueuedExec/g
s/\bDrawBitmapFast_ParamBlock\b/DrawBitmapFast_QueuedExec/g
s/\bDrawIcons_ParamBlock\b/DrawIcons_QueuedExec/g
s/\bDrawFrameSP_ParamBlock\b/DrawFrameSP_QueuedExec/g
s/\bDrawBitmapFile_ParamBlock\b/DrawBitmapFile_QueuedExec/g
