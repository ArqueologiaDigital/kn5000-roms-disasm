import os

# Create binary of original
os.system('git checkout maincpu/kn5000_v10_program.s')
os.system('/mnt/shared/llvm-project/build/bin/llvm-mc -triple=tlcs900 -filetype=obj -I maincpu -o orig.o maincpu/kn5000_v10_program.s')
# llvm-objcopy doesn't extract the exact binary section perfectly, let's just dump hex
os.system('/mnt/shared/llvm-project/build/bin/llvm-objdump -s orig.o > orig.hex')

# Create binary of modified
os.system('python3 scripts/refactor_llvm_strings.py')
os.system('/mnt/shared/llvm-project/build/bin/llvm-mc -triple=tlcs900 -filetype=obj -I maincpu -o mod.o maincpu/kn5000_v10_program.s 2> mod.err')
os.system('/mnt/shared/llvm-project/build/bin/llvm-objdump -s mod.o > mod.hex')

with open('orig.hex') as f:
    orig = f.readlines()
with open('mod.hex') as f:
    mod = f.readlines()

for i in range(min(len(orig), len(mod))):
    if orig[i] != mod[i]:
        print(f"Diff at line {i}:")
        print(f"Orig: {orig[i].strip()}")
        print(f"Mod : {mod[i].strip()}")
        break
