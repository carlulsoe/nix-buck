#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <zlib.h>

#include "report.h"

// Round-trip a message through zlib, a library from nixpkgs.
int main(void) {
  const char msg[] = "hello from a relocated store path, through zlib";
  unsigned char packed[256], unpacked[256];
  uLongf n = sizeof(packed), m = sizeof(unpacked);
  char libz[PATH_MAX];

  if (compress(packed, &n, (const Bytef *)msg, sizeof(msg)) != Z_OK ||
      uncompress(unpacked, &m, packed, n) != Z_OK || m != sizeof(msg) ||
      memcmp(msg, unpacked, m) != 0) {
    fprintf(stderr, "zlib round trip failed\n");
    return 1;
  }
  loaded("/libz.so", libz, sizeof(libz));
  printf("%s\n", (const char *)unpacked);
  printf("zlib:           %s, round trip ok\n", zlibVersion());
  printf("libz:           %s\n", libz);
  report();
  return 0;
}
