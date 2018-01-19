CFLAGS := -g -Wall -O2

all:
	gcc -w $(CFLAGS) -o playpcm playpcm.c
