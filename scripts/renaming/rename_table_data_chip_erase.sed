# HDAE5000_Flash_Verify issues AA 55 80 AA 55 10 to the Table Data flash at 0x800000: the AMD
# six-cycle CHIP ERASE, not a verification (technics-docs flash-programming.md already says
# "Erase Table Data ROM").
s/\bHDAE5000_Flash_Verify\b/TableDataFlash_ChipErase/g
