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
