/*
** Copyright 2009, Brian Swetland. All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions, and the following disclaimer.
** 2. The name of the authors may not be used to endorse or promote products
**    derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
** IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
** OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
** IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY DIRECT, INDIRECT,
** INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
** NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
** THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include "audio.h"

int play_file(int fd, unsigned count)
{
    struct pcm *pcm;
    unsigned avail, xfer, bufsize;
    char *data, *next;

    data = malloc(count);
    if (!data) {
        fprintf(stderr,"could not allocate %d bytes\n", count);
        return -1;
    }
    if (read(fd, data, count) != count) {
        free(data);
        close(fd);
        fprintf(stderr,"could not read %d bytes\n", count);
        return -1;
    }

    close(fd);
    avail = count;
    next = data;

    pcm = pcm_alloc();
    if (pcm_open(pcm))
        goto fail;

    bufsize = pcm_buffer_size(pcm);

    while (avail > 0) {
        xfer = (avail > bufsize) ? bufsize : avail;
        if (pcm_write(pcm, next, xfer))
            goto fail;
        next += xfer;
        avail -= xfer;
    }
    free(data);
    pcm_close(pcm);
    free(pcm);
    return 0;
    
fail:
    free(data);
    fprintf(stderr,"pcm error: %s\n", pcm_error(pcm));
    free(pcm);
    return -1;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr,"usage: playwav <file>\n");
        return -1;
    }
    int fd;
    fd = open(argv[1], O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "playwav: cannot open '%s'\n", argv[1]);
        return -1;
    }
    return play_file(fd, 293892); /* the number is what ls -l shows */
}
