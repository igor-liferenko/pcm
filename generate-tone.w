@ @c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(void)
{
  signed short buf;
  int i;

  FILE *f1;
  
  if ((f1 = fopen("my.pcm","w")) == NULL) {
    perror("open failed on output");
    exit(-1);
  }

  for (i = 0; i < 40000; i++) {
    buf = (signed short) (sin((double)i/10.0) * 32768.0);
    fwrite(&buf, sizeof (signed short), 1, f1);
    if (ferror(f1)) {
      perror("write failed\n");
      exit(-1);
    }
    buf = 0;
    fwrite(&buf, sizeof (signed short), 1, f1);
    if (ferror(f1)) {
      perror("write failed\n");
      exit(-1);
    }
  }

  fclose(f1);

  exit(0);
}
