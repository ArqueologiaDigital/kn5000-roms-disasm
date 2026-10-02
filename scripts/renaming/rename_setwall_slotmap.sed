# The two 20-byte SetWall slot maps are each one entry short of a permutation
# (row 0 repeats 0x00 and omits 0x10; row 1 repeats 0x10 and omits 0x00): not "Perm".
s/\bNoRef_SetWall_SlotPerm20x2\b/NoRef_SetWall_SlotMap20x2/g
