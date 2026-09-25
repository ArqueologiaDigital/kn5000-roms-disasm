# Boot_LoadDiskData handler labels: named by the disk type that reaches them through
# Boot_LoadDiskData_JumpOffsets (index = type - 1), types as Boot_DetectDiskType assigns
# them (FileIdentifierStringsTable slot).  table_data/kn5000_table_data.s, 2026-09-25.
s/\bBoot_LoadDiskData__ldd_type678\b/Boot_LoadDiskData__ldd_TablePCK/g
s/\bBoot_LoadDiskData__ldd_type1\b/Boot_LoadDiskData__ldd_Program12/g
s/\bBoot_LoadDiskData__ldd_type2\b/Boot_LoadDiskData__ldd_Table12/g
s/\bBoot_LoadDiskData__ldd_type3\b/Boot_LoadDiskData__ldd_CustomData/g
s/\bBoot_LoadDiskData__ldd_type4\b/Boot_LoadDiskData__ldd_HDAEPrg/g
s/\bBoot_LoadDiskData__ldd_type5\b/Boot_LoadDiskData__ldd_ProgramPCK/g
