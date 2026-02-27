import os
os.system('git checkout maincpu/kn5000_v10_program.s')
os.system('make maincpu/kn5000_v10_program.llvm.o')
os.system('/mnt/shared/llvm-project/build/bin/llvm-objdump -d rebuilt_ROMs/kn5000_v10_program.llvm.o > original.txt')
os.system('python3 scripts/refactor_llvm_strings.py')
os.system('make rebuilt_ROMs/kn5000_v10_program.llvm.o')
os.system('/mnt/shared/llvm-project/build/bin/llvm-objdump -d rebuilt_ROMs/kn5000_v10_program.llvm.o > modified.txt')
