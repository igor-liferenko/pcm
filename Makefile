all:
	ctangle playpcm
	clang -w -g -Wall -O2 -o play playpcm.c
	ctangle generate-tone
	clang -o gen generate-tone.c -lm
