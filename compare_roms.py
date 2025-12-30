original = open("original_ROMs/kn5000_v10_program.rom", "rb").read()
rebuilt =  open("rebuilt/kn5000_v10_program.rebuilt.rom", "rb").read()

if len(rebuilt) > len(original):
	print("Rebuilt ROM is too big!")

score = 0
for i in range(len(original)):
	if i >= len(rebuilt):
		print("Rebuilt ROM is too small")
		break
	if original[i] == rebuilt[i]:
		score += 1

print(f"Similarity: {100*score/len(original):0.2f}%  ({len(original)-score} incorrect bytes)")

