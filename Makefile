all:
	ctangle playpcm
	clang -w -g -Wall -O2 -o play playpcm.c # usb sound card (mono) FIXME: homebrew or standard? - try both; + see ~/snd/TODO
	ctangle generate-tone generate-tone-usb
	clang -o gen generate-tone.c -lm
	./gen
