#ifndef _AUDIO_H_
#define _AUDIO_H_

struct pcm;

struct pcm *pcm_alloc(void);

/* Acquire/release an 44100 16bit stereo pcm channel.
 * Returns non-zero on error
 */
int pcm_open(struct pcm *pcm, unsigned rate, unsigned channels);
int pcm_close(struct pcm *pcm);

/* Returns a human readable reason for the last error. */
const char *pcm_error(struct pcm *pcm);

/* Returns the buffer size (int bytes) that should be used for pcm_write.
 * This will be 1/2 of the actual fifo size.
 */
unsigned pcm_buffer_size(struct pcm *pcm);

/* Write data to the fifo.
 * Will start playback on the first write or on a write that
 * occurs after a fifo underrun.
 */
int pcm_write(struct pcm *pcm, void *data, unsigned count);

#endif
