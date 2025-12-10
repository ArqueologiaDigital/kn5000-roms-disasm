images_1bit = {
	"Bitmap_1bit_Flash_Memory_Update": [224, 22, 0x0018e],	# Flash Memory Update
	"Bitmap_1bit_Now_Erasing": [224, 22, 0x003f6],		# Now Erasing!! 
	"Bitmap_1bit_FD_to_Flash_Memory": [224, 22, 0x0065e],	# FD -> Flash Memory 
	"Bitmap_1bit_Completed": [224, 22, 0x008c6],		# Completed! 
	"Bitmap_1bit_Please_Wait": [224, 22, 0x00b2e],		# Please Wait !!
	"Bitmap_1bit_Change_FD_2_of_2": [224, 22, 0x00d96],	# Change FD (2/2) 
	"Bitmap_1bit_Illegal_Disk": [224, 22, 0x00ffe],		# Illegal Disk! 
	"Bitmap_1bit_Turn_On_AGAIN": [224, 22, 0x01266],	# Turn On AGAIN !! 
}

images_8bit = {
	"BitmapNtedt0k": [ 16, 127, 0x34E78],			# A vertical piano keybed
	"BitmapNtedt0d": [240, 127, 0x35668],			# A grid
	"BitmapDredt0k": [ 88, 119, 0x3CD78],			# Horizontal lines 
	"BitmapDredt0d": [168, 119, 0x3F660],			# A grid
	"BitmapSplitPoint_no_split": [ 57,  52, 0x5ae4a],	# Split-point - no split
	"BitmapSplitPoint_C": [ 57,  52, 0x5ba12],		# Split-point C
	"BitmapSplitPoint_Db": [ 57,  52, 0x5c5da],		# Split-point Db
	"BitmapSplitPoint_D": [ 57,  52, 0x5d1a2],		# Split-point D
	"BitmapSplitPoint_Eb": [ 57,  52, 0x5dd6a],		# Split-point Eb
	"BitmapSplitPoint_E": [ 57,  52, 0x5e932],		# Split-point E
	"BitmapSplitPoint_F": [ 57,  52, 0x5f4fa],		# Split-point F
	"BitmapSplitPoint_Gb": [ 57,  52, 0x600c2],		# Split-point Gb
	"BitmapSplitPoint_G": [ 57,  52, 0x60c8a],		# Split-point G
	"BitmapSplitPoint_Ab": [ 57,  52, 0x61852],		# Split-point Ab
	"BitmapSplitPoint_A": [ 57,  52, 0x6241a],		# Split-point A
	"BitmapSplitPoint_Bb": [ 57,  52, 0x62fe2],		# Split-point Bb
	"BitmapSplitPoint_B": [ 57,  52, 0x63baa],		# Split-point B
	"BitmapMIDIConnections_1": [296, 108, 0x64772],		# 1st diagram of MIDI connections
	"BitmapMIDIConnections_2": [296, 108, 0x6c452],		# 2nd diagram ...
	"BitmapMIDIConnections_3": [296, 108, 0x74132],		# 3rd diagram ...
	"BitmapBmphk": [100, 120, 0x7be12],			# Top-view depiction of the kn5000

	# FIXME: There can be other images in-between here...

	"BitmapAccita16": [120,  95, 0x86676],			# italian accordion
	"BitmapAccger16": [120,  95, 0x892fe],			# german accordion
	"BitmapSomeArrows": [294,   6, 0x8bf86],		# some arrows
	"BitmapDrawbarNumberedSlider_1": [ 22, 222, 0x8c66a],	# drawbar numbered-slider + background fill #1
	"BitmapDrawbarNumberedSlider_2": [ 22, 222, 0x8d97e],	# drawbar numbered-slider + background fill #2
	"BitmapDrawbarNumberedSlider_3": [ 22, 222, 0x8ec92],	# drawbar numbered-slider + background fill #3

	# TODO: Are these drawbar images the same as the ones referenced
	# at the routine starting at LABEL_F83B92 ?

	"BitmapTechnicsLogo": [312,  45, 0x8ffa6],	# Technics logo
	"BitmapKN5000Logo": [200,  36, 0x9367e],	# KN-5000 logo

	# 9F960 base adddress referenced at LABEL_F83B92

	"BitmapWormWearingHat": [ 24,  24, 0xA9F20],	# (is is a debugging reference?)
	"BitmapFadeInPicture": [112,  25, 0xB8072],		# Fade In Picture
	"BitmapFadeInText": [ 80,  18, 0xB8B62],		# Fade In Text
	"BitmapFadeOutPicture": [114,  25, 0xB9102],		# Fade Out Picture
	"BitmapFadeOutText": [108,  20, 0xB9C24],		# Fade Out Text
}

for name, values in images_1bit.items():
	w, h, offs = values
	count = int(w*h/8)
	print(f"dd if=kn5000_v10_program.rom bs=1 count={count} of=includes/{name}.bin skip={offs}")

for name, values in images_8bit.items():
	w, h, offs = values
	count = int(w*h)
	print(f"dd if=kn5000_v10_program.rom bs=1 count={count} of=includes/{name}.bin skip={offs}")


for name, values in images_1bit.items():
	w, h, offs = values
	count = int(w*h/8)
	print(f"{name}: include(\"images/{name}.bin\")\t; {hex(0xE00000 + offs)}-{hex(0xE00000 + offs + count)}")

for name, values in images_8bit.items():
	w, h, offs = values
	count = int(w*h)
	print(f"{name}: include(\"images/{name}.bin\")\t; {hex(0xE00000 + offs)}-{hex(0xE00000 + offs + count)}")
