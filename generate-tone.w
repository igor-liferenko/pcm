@ Usig file streams enstead of raw files is better because they
do buffering for us to write to hard drive in big chunks.

@c
#include <wchar.h>
#include <stdio.h>
#include <math.h>

int main(void)
{
  signed short buf;
  int i;

  FILE *fp;
  
  if ((fp = fopen("my.pcm","w")) == NULL) {
    fwprintf(stderr, L"open failed on output: %m");
    return 1;
  }

  for (i = 0; i < 40000; i++) {
    buf = (signed short) (sin((double)i/10.0) * 32768.0);
    if (!fwrite(&buf, sizeof (signed short), 1, fp)) {
      fwprintf(stderr, L"write failed: %m\n");
      return 1;
    }
    buf = 0;
    if (!fwrite(&buf, sizeof (signed short), 1, fp)) {
      fwprintf(stderr, L"write failed: %m\n");
      return 1;
    }
  }

  fclose(fp);

  return 0;
}
