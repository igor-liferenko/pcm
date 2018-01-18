
CFLAGS := -g -Wall -O2

all:
	gcc $(CFLAGS) -o playwav playwav.c audio_alsa.c

clean:
	rm -f playwav *~
