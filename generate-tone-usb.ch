@x
    buf = 0;
    if (!fwrite(&buf, sizeof (signed short), 1, fp)) {
      fwprintf(stderr, L"write failed: %m\n");
      return 1;
    }
@y
@z
