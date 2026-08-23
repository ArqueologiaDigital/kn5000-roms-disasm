import sys
rom = open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom','rb').read()
BASE=0xE00000
sites = """0xF16CE3 6
0xF3710A 6
0xF39627 6
0xF39631 6
0xF3A090 6
0xF4E683 7
0xF69ECF 6
0xF6A502 6
0xF86630 7
0xF97333 6
0xF97354 6
0xF97386 6
0xF973B7 6
0xF97466 6
0xF97487 6
0xF974B9 6
0xF974EB 6
0xF975ED 6
0xF97847 6
0xFE82CB 6
0xFE82D1 6
0xFE8370 6
0xFE8376 6
0xEE5115 3
0xF027A5 3""".split('\n')
for l in sites:
    a,n = l.split()
    a=int(a,16); n=int(n)
    b = rom[a-BASE:a-BASE+n]
    print(f"{a:06X} {' '.join('%02x'%x for x in b)}")
