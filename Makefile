all:
	ctangle playpcm
	clang -w -g -Wall -O2 -o play playpcm.c
	ctangle generate-tone generate-tone-usb
	clang -o gen generate-tone.c -lm
	./gen
