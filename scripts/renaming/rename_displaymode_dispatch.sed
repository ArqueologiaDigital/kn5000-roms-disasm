# The routine after DefaultHandler_Ret's `ret` (v10/v9 0xEF61E9) dispatches on the display
# mode byte (0x0D65) & 3 through a 4-entry table; it was reached only through the positional
# alias DefaultHandler_Ret_0x1 and its table and targets carried DefaultHandler_Ret's name
# (Wave 2 claims review).  The routine gets its own label, DisplayMode_Dispatch.
s/\bDefaultHandler_Ret_DispatchTbl_Target0\b/DisplayMode_Dispatch_Mode0/g
s/\bDefaultHandler_Ret_DispatchTbl_Target1\b/DisplayMode_Dispatch_Mode1/g
s/\bDefaultHandler_Ret_DispatchTbl_Target3\b/DisplayMode_Dispatch_Mode3/g
s/\bDefaultHandler_Ret_DispatchTbl\b/DisplayMode_Dispatch_Tbl/g
s/\bDefaultHandler_Ret_Return2\b/DisplayMode_Dispatch_Return/g
s/\bDefaultHandler_Ret_0x1\b/DisplayMode_Dispatch/g
# v7 spelled the same table DefaultHandler_Ret_PtrTbl; renamed in place by the edit that added these lines.
