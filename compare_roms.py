import sys

print()

results = {}
msg = ""
for entry in [
	("maincpu", "kn5000_v10_program"),
	("subcpu payload", "kn5000_subprogram_v142")
]:
	key, filename = entry
	msg += f"==== {filename} ====\n"
	original_name = f"original_ROMs/{filename}.rom"
	rebuilt_name = f"rebuilt_ROMs/{filename}.rebuilt.rom"
	original = open(original_name, "rb").read()
	rebuilt =  open(rebuilt_name, "rb").read()

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
	results[key] = (percentage, badbytes)

	if badbytes:
		msg += f"Similarity: {percentage}  ({badbytes} incorrect bytes)\n\n"
	else:
		msg += f"Similarity: {percentage}\n\n"		

title = []
for key, value in results.items():
	percentage, badbytes = value
	if badbytes:
		title.append(f"{key}: {percentage} ({badbytes} bad bytes)")
	else:
		title.append(f"{key}: {percentage}")
print (" | ".join(title) + "\n")
print (msg)
