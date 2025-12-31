import sys

print()

for filename in [
	"kn5000_v10_program",
	"kn5000_subprogram_v142"
]:
	print(f" ==== {filename} ====")
	original_name = f"original_ROMs/{filename}.rom"
	rebuilt_name = f"rebuilt_ROMs/{filename}.rebuilt.rom"
	original = open(original_name, "rb").read()
	rebuilt =  open(rebuilt_name, "rb").read()

	if len(rebuilt) > len(original):
		print("Rebuilt ROM is too big!")

	score = 0
	for i in range(len(original)):
		if i >= len(rebuilt):
			print("Rebuilt ROM is too small")
			break
		if original[i] == rebuilt[i]:
			score += 1

	print(f"Similarity: {100*score/len(original):0.2f}%  ({len(original)-score} incorrect bytes)\n\n")

