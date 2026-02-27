import os

# Original
os.system('git checkout maincpu/kn5000_v10_program.s')
os.system('make rebuilt_ROMs/kn5000_v10_program.llvm.rom')
os.system('mv rebuilt_ROMs/kn5000_v10_program.llvm.rom original.rom')

# Modified
os.system('python3 scripts/refactor_llvm_strings.py')
os.system('make rebuilt_ROMs/kn5000_v10_program.llvm.rom')
# It will fail, but we can assemble just the .o and see if we can get it or just diff the source
