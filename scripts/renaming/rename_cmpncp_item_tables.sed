# The CMPNCP (Composer copy page) item tables in accompaniment_engine.s, v10/v9.
# They were decoded as code under positional names; reframed as data 2026-10-03
# (notes/r3-trace-2026-10-02/reframe-specs/cmpncp_itemhandlers_*.json).
s/\bDrumVoice_Handler7_Data_3_Code3\b/CmpNcp_ItemHandlerTable/g
s/\bDrumVoice_Handler7_Data_3_Code2\b/CmpNcp_ItemB_HandlerIndex/g
s/\bDrumVoice_Handler7_Data_3_Code\b/CmpNcp_ItemA_HandlerIndex/g
s/\bDrumVoice_Handler7_Data_2\b/CmpNcp_ProgramGroupBase/g
