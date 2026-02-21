import os
import sys

print()

results = {}
msg = ""
total_length = 0
total_score = 0

for entry in [
	("maincpu",		"kn5000_v10_program.rom",	"kn5000_v10_program.rebuilt.rom"),
	("subcpu boot",		"kn5000_subcpu_boot.ic30",	"kn5000_subcpu_boot.rebuilt.rom"),
	("subcpu payload",	"kn5000_subprogram_v142.rom",	"kn5000_subprogram_v142.rebuilt.rom"),
	("table data",		"kn5000_table_data.rom",	"kn5000_table_data.rebuilt.rom"),
	("custom data",		"kn5000_custom_data.ic19",	"kn5000_custom_data.rebuilt.rom"),
	("hdae5000",		"hd-ae5000_v2_06i.ic4",		"hd-ae5000_v2_06i.rebuilt.rom"),
]:
	key, original_name, rebuilt_name = entry
	msg += f"==== {key} ====\n"
	original_name = f"original_ROMs/{original_name}"
	rebuilt_name = f"rebuilt_ROMs/{rebuilt_name}"
	original = open(original_name, "rb").read()
	try:
		rebuilt =  open(rebuilt_name, "rb").read()
	except FileNotFoundError:
		rebuilt = []

	if len(rebuilt) > len(original):
		msg += "Rebuilt ROM is too big!\n"

	score = 0
	for i in range(len(original)):
		if i >= len(rebuilt):
			msg += "Rebuilt ROM is too small\n"
			break
		if original[i] == rebuilt[i]:
			score += 1

	percentage = f"{100*score/len(original):0.2f}%"
	badbytes = len(original)-score

	total_length += len(original)
	total_score += score

	if badbytes:
		msg += f"Similarity: {percentage}  ({badbytes} incorrect bytes)\n\n"
	else:
		msg += f"Similarity: {percentage}\n\n"


total_badbytes = total_length - total_score
total_percentage = f"{100*total_score/total_length:0.2f}%"

if total_badbytes:
	print(f"romset bytematch: {total_percentage}  ({total_badbytes} incorrect bytes)\n")
else:
	print(f"romset bytematch: {total_percentage}\n")

print (msg)

# LLVM build comparison (optional - only if LLVM ROM exists)
llvm_rom = "rebuilt_ROMs/kn5000_v10_program.llvm.rom"
original_rom = "original_ROMs/kn5000_v10_program.rom"

if os.path.exists(llvm_rom):
	print("==== LLVM build (maincpu) ====")
	original = open(original_rom, "rb").read()
	llvm = open(llvm_rom, "rb").read()

	if len(llvm) > len(original):
		print(f"LLVM ROM is too big! ({len(llvm)} vs {len(original)} expected)")
	elif len(llvm) < len(original):
		print(f"LLVM ROM is too small ({len(llvm)} vs {len(original)} expected)")

	compare_len = min(len(original), len(llvm))
	score = 0
	first_mismatches = []
	for i in range(compare_len):
		if original[i] == llvm[i]:
			score += 1
		elif len(first_mismatches) < 20:
			first_mismatches.append((i, original[i], llvm[i]))

	percentage = f"{100*score/len(original):0.2f}%"
	badbytes = len(original) - score + max(0, len(original) - len(llvm))

	if badbytes:
		print(f"Similarity: {percentage}  ({badbytes} incorrect bytes)")
	else:
		print(f"Similarity: {percentage}")

	if first_mismatches:
		print(f"\nFirst {len(first_mismatches)} mismatches:")
		print(f"  {'Address':>10s}  {'Original':>8s}  {'LLVM':>8s}")
		for addr, orig_byte, llvm_byte in first_mismatches:
			rom_addr = 0xE00000 + addr
			print(f"  0x{rom_addr:06X}  0x{orig_byte:02X}       0x{llvm_byte:02X}")

	print()
