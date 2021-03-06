@ @c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/time.h>

#include <linux/ioctl.h>

#define __force
#define __bitwise
#define __user
#include <sound/asound.h>

#define DEBUG 1

/* alsa parameter manipulation cruft */

#define PARAM_MAX SNDRV_PCM_HW_PARAM_LAST_INTERVAL

static inline int param_is_mask(int p)
{
    return (p >= SNDRV_PCM_HW_PARAM_FIRST_MASK) && 
        (p <= SNDRV_PCM_HW_PARAM_LAST_MASK);
}

static inline int param_is_interval(int p)
{
    return (p >= SNDRV_PCM_HW_PARAM_FIRST_INTERVAL) &&
        (p <= SNDRV_PCM_HW_PARAM_LAST_INTERVAL);
}

static inline struct snd_interval *param_to_interval(struct snd_pcm_hw_params *p, int n)
{
    return &(p->intervals[n - SNDRV_PCM_HW_PARAM_FIRST_INTERVAL]);
}

static inline struct snd_mask *param_to_mask(struct snd_pcm_hw_params *p, int n)
{
    return &(p->masks[n - SNDRV_PCM_HW_PARAM_FIRST_MASK]);
}

static void param_set_mask(struct snd_pcm_hw_params *p, int n, unsigned bit)
{
    if (bit >= SNDRV_MASK_MAX)
        return;
    if (param_is_mask(n)) {
        struct snd_mask *m = param_to_mask(p, n);
        m->bits[0] = 0;
        m->bits[1] = 0;
        m->bits[bit >> 5] |= (1 << (bit & 31));
    }
}

static void param_set_min(struct snd_pcm_hw_params *p, int n, unsigned val)
{
    if (param_is_interval(n)) {
        struct snd_interval *i = param_to_interval(p, n);
        i->min = val;
    }   
}

static void param_set_max(struct snd_pcm_hw_params *p, int n, unsigned val)
{
    if (param_is_interval(n)) {
        struct snd_interval *i = param_to_interval(p, n);
        i->max = val;
    }   
}

static void param_set_int(struct snd_pcm_hw_params *p, int n, unsigned val)
{
    if (param_is_interval(n)) {
        struct snd_interval *i = param_to_interval(p, n);
        i->min = val;
        i->max = val;
        i->integer = 1;
    }   
}

static void param_init(struct snd_pcm_hw_params *p)
{
    int n;
    memset(p, 0, sizeof(*p));
    for (n = SNDRV_PCM_HW_PARAM_FIRST_MASK;
         n <= SNDRV_PCM_HW_PARAM_LAST_MASK; n++) {
            struct snd_mask *m = param_to_mask(p, n);
            m->bits[0] = ~0;
            m->bits[1] = ~0;
    }        
    for (n = SNDRV_PCM_HW_PARAM_FIRST_INTERVAL;
         n <= SNDRV_PCM_HW_PARAM_LAST_INTERVAL; n++) {
            struct snd_interval *i = param_to_interval(p, n);
            i->min = 0;
            i->max = ~0;
    }
}

/* debugging gunk */

#if DEBUG
static const char *param_name[PARAM_MAX+1] = {
    [SNDRV_PCM_HW_PARAM_ACCESS] = "access",
    [SNDRV_PCM_HW_PARAM_FORMAT] = "format",
    [SNDRV_PCM_HW_PARAM_SUBFORMAT] = "subformat",

    [SNDRV_PCM_HW_PARAM_SAMPLE_BITS] = "sample_bits",
    [SNDRV_PCM_HW_PARAM_FRAME_BITS] = "frame_bits",
    [SNDRV_PCM_HW_PARAM_CHANNELS] = "channels",
    [SNDRV_PCM_HW_PARAM_RATE] = "rate",
    [SNDRV_PCM_HW_PARAM_PERIOD_TIME] = "period_time",
    [SNDRV_PCM_HW_PARAM_PERIOD_SIZE] = "period_size",
    [SNDRV_PCM_HW_PARAM_PERIOD_BYTES] = "period_bytes",
    [SNDRV_PCM_HW_PARAM_PERIODS] = "periods",
    [SNDRV_PCM_HW_PARAM_BUFFER_TIME] = "buffer_time",
    [SNDRV_PCM_HW_PARAM_BUFFER_SIZE] = "buffer_size",
    [SNDRV_PCM_HW_PARAM_BUFFER_BYTES] = "buffer_bytes",
    [SNDRV_PCM_HW_PARAM_TICK_TIME] = "tick_time",
};

static void param_dump(struct snd_pcm_hw_params *p)
{
    int n;

    for (n = SNDRV_PCM_HW_PARAM_FIRST_MASK;
         n <= SNDRV_PCM_HW_PARAM_LAST_MASK; n++) {
            struct snd_mask *m = param_to_mask(p, n);
            printf("%s = %08x%08x\n", param_name[n],
                   m->bits[1], m->bits[0]);
    }
    for (n = SNDRV_PCM_HW_PARAM_FIRST_INTERVAL;
         n <= SNDRV_PCM_HW_PARAM_LAST_INTERVAL; n++) {
            struct snd_interval *i = param_to_interval(p, n);
            printf("%s = (%d,%d) omin=%d omax=%d int=%d empty=%d\n",
                   param_name[n], i->min, i->max, i->openmin,
                   i->openmax, i->integer, i->empty);
    }
}

static void info_dump(struct snd_pcm_info *info)
{
    printf("device = %d\n", info->device);
    printf("subdevice = %d\n", info->subdevice);
    printf("stream = %d\n", info->stream);
    printf("card = %d\n", info->card);
    printf("id = '%s'\n", info->id);
    printf("name = '%s'\n", info->name);
    printf("subname = '%s'\n", info->subname);
    printf("dev_class = %d\n", info->dev_class);
    printf("dev_subclass = %d\n", info->dev_subclass);
    printf("subdevices_count = %d\n", info->subdevices_count);
    printf("subdevices_avail = %d\n", info->subdevices_avail);
}
#else
static void param_dump(struct snd_pcm_hw_params *p) {}
static void info_dump(struct snd_pcm_info *info) {}
#endif

#define PCM_ERROR_MAX 128

struct pcm {
    int fd;
    int running:1;
    int underruns;
    unsigned buffer_size;
    char error[PCM_ERROR_MAX];
};

unsigned pcm_buffer_size(struct pcm *pcm)
{
    return pcm->buffer_size;
}

const char* pcm_error(struct pcm *pcm)
{
    return pcm->error;
}

struct pcm *pcm_alloc(void)
{
    struct pcm *pcm = calloc(1, sizeof(struct pcm));
    if (pcm) {
        pcm->fd = -1;
    }
    return pcm;
}

static int oops(struct pcm *pcm, int e, const char *fmt, ...)
{
    va_list ap;
    int sz;

    va_start(ap, fmt);
    vsnprintf(pcm->error, PCM_ERROR_MAX, fmt, ap);
    va_end(ap);
    sz = strlen(pcm->error);

    if (errno)
        snprintf(pcm->error + sz, PCM_ERROR_MAX - sz,
                 ": %s", strerror(e));
    return -1;
}

int pcm_write(struct pcm *pcm, void *data, unsigned count)
{
    struct snd_xferi x;

    x.buf = data;
    x.frames = count / 4;

    for (;;) {
        if (!pcm->running) {
            if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_PREPARE))
                return oops(pcm, errno, "cannot prepare channel");
            if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_WRITEI_FRAMES, &x))
                return oops(pcm, errno, "cannot write initial data");
            if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_START))
                return oops(pcm, errno, "cannot start channel");
            pcm->running = 1;
            return 0;
        }
        if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_WRITEI_FRAMES, &x)) {
            pcm->running = 0;
            if (errno == EPIPE) {
                    /* we failed to make our window -- try to restart */
                pcm->underruns++;
                continue;
            }
            return oops(pcm, errno, "cannot write stream data");
        }
        return 0;
    }   
}

int pcm_close(struct pcm *pcm) 
{
    if (pcm->fd < 0)
        return oops(pcm, 0, "not open");

    close(pcm->fd);
    pcm->running = 0;
    pcm->buffer_size = 0;
    pcm->fd = -1;
    return 0;
}

int pcm_open(struct pcm *pcm)
{
    struct snd_pcm_info info;
    struct snd_pcm_hw_params params;
    struct snd_pcm_sw_params sparams;
    unsigned bufsz = 8192;

    if (pcm->fd >= 0)
        return oops(pcm, 0, "already open");

    if ((pcm->fd = open("/dev/snd/pcmC2D0p", O_RDWR))==-1)
      fprintf(stderr, "ERROR: device file not found - try another one\n");
    if (pcm->fd < 0)
        return oops(pcm, errno, "cannot open device '%s'");

    if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_INFO, &info)) {
        oops(pcm, errno, "cannot get info - %s");
        goto fail;
    }
    info_dump(&info);
    printf("----------------------------------\n");
    param_init(&params);
    param_set_mask(&params, SNDRV_PCM_HW_PARAM_ACCESS,
                   SNDRV_PCM_ACCESS_RW_INTERLEAVED);
    param_set_mask(&params, SNDRV_PCM_HW_PARAM_FORMAT,
                   SNDRV_PCM_FORMAT_S16_LE);
    param_set_mask(&params, SNDRV_PCM_HW_PARAM_SUBFORMAT,
                   SNDRV_PCM_SUBFORMAT_STD);
    param_set_min(&params, SNDRV_PCM_HW_PARAM_BUFFER_BYTES, bufsz);
    /* FIXME: try not to set parameters except sample_bits, channels and
       rate - will it use some default values? */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_SAMPLE_BITS, 16);
    param_set_int(&params, SNDRV_PCM_HW_PARAM_FRAME_BITS, 16);
    param_set_int(&params, SNDRV_PCM_HW_PARAM_CHANNELS, 1);
    param_set_int(&params, SNDRV_PCM_HW_PARAM_PERIODS, 2);
    param_set_int(&params, SNDRV_PCM_HW_PARAM_RATE, 32000);
//data rate = 512 kbit/s
//https://larsimmisch.github.io/pyalsaaudio/terminology.html
#if 0
    param_set_int(&params, SNDRV_PCM_HW_PARAM_BUFFER_TIME, ?); /* Approx duration of buffer
                                                 * in us
                                                 */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_BUFFER_SIZE, ?); /* Size of buffer in frames */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_PERIOD_TIME, ?); /* Approx distance between
                                                 * interrupts in us
                                                 */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, ?); /* Approx frames between
                                                 * interrupts
                                                 */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_PERIOD_BYTES, ?); /* Approx bytes between
                                                 * interrupts
                                                 */
    param_set_int(&params, SNDRV_PCM_HW_PARAM_TICK_TIME, ?); /* Approx tick duration in us */
#endif
    if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_HW_PARAMS, &params)) {
        oops(pcm, errno, "cannot set hw params");
        goto fail;
    }
    param_dump(&params);

    memset(&sparams, 0, sizeof(sparams));
    sparams.tstamp_mode = SNDRV_PCM_TSTAMP_NONE;
    sparams.period_step = 1;
    sparams.avail_min = 1;
    sparams.start_threshold = bufsz / 4;
    sparams.stop_threshold = bufsz / 4;
    sparams.xfer_align = bufsz / 8; /* needed for old kernels */
    sparams.silence_size = 0;
    sparams.silence_threshold = 0;

    if (ioctl(pcm->fd, SNDRV_PCM_IOCTL_SW_PARAMS, &sparams)) {
        oops(pcm, errno, "cannot set sw params");
        goto fail;
    }

    pcm->buffer_size = bufsz / 2;
    pcm->underruns = 0;
    return 0;

fail:
    close(pcm->fd);
    pcm->fd = -1;
    return -1;
}

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

#include <sys/stat.h>

int main(void)
{
    int fd;
    fd = open("my.pcm", O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "cannot open\n");
        return -1;
    }

  struct stat st;
  fstat(fd, &st);
  return play_file(fd, st.st_size);
}

