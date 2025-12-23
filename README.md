It's been many many years that I've been studying the ROM code of the Technics KN5000 music keyboard with two major goals:

- [To emulate it on MAME](https://github.com/mamedev/mame/pull/14558)
- To be able to develop custom software to run on the real device.

There's much more info at https://forum.fiozera.com.br/t/technics-kn5000-homebrew-development/321

This repo started as a private one. But after putting so much effort into documenting the boot code, I decided to publish it, because it may be useful for other people interested in learning how this machine works.

I hope nobody gets mad at me for doing so. As this device was discontinued decades ago, I believe that there's no actual harm in doing so. It is much more like a museum item being studied by people interested in the history of electronic music equipment development.

Cheers,
Felipe Sanches


Current state of this effort:

I am trying to rebuild the ROM and compare it with the original one with a 100% byte-matching goal.

As of 23rd Dec 2025, I'm at roughly 85% of that goal.

The main reason for not yet being able to get a perfect build is that the ASL assembler only supports the TLCS900 TMP96C141 CPU instruction set, while the KN5000 maincpu is a TMP94C241F.

So, my current goal is to get as close to 99.9% as possible, while leaving placeholder zero bytes on the unsupported isntructions. Then, this will guide me to patch ASL to implement TMP94C241F support. And only after that there's hope of getting a perfect byte-matching rebuild of the ROM.

Once that is acchieved, I'll be able to use such assembler to resume my effort of developing homebrew software for the KN5000. My main project is to port Eric Chahi's Another World virtual machine to run on the musical keyboard (because we can! LOL).

There's some initial code in that direction available at:
https://github.com/felipesanches/kn5000_homebrew/blob/main/demos/anotherworld/another.asm
