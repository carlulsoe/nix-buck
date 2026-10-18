#define _GNU_SOURCE
#include "report.h"

#include <limits.h>
#include <link.h>
#include <stdio.h>
#include <string.h>
#include <sys/utsname.h>
#include <unistd.h>

#ifndef NIX_GCC
#define NIX_GCC "/nix/store/unknown-gcc"
#endif

struct search {
  const char *needle;
  char *path;
  size_t size;
};

static int match(struct dl_phdr_info *info, size_t size, void *data) {
  struct search *s = data;
  (void)size;
  if (strstr(info->dlpi_name, s->needle)) {
    snprintf(s->path, s->size, "%s", info->dlpi_name);
    return 1;
  }
  return 0;
}

void loaded(const char *needle, char *path, size_t size) {
  struct search s = {needle, path, size};
  snprintf(path, size, "?");
  dl_iterate_phdr(match, &s);
}

void report(void) {
  char exe[PATH_MAX] = {0};
  char libc[PATH_MAX];
  struct utsname u;

  // Where did the kernel find me?
  readlink("/proc/self/exe", exe, sizeof(exe) - 1);

  // Which libc did the loader actually map?
  loaded("/libc.so", libc, sizeof(libc));

  uname(&u);
  printf("kernel:         %s %s\n", u.sysname, u.release);
  printf("hostname:       %s\n", u.nodename);
  printf("/proc/self/exe: %s\n", exe);
  printf("libc:           %s\n", libc);

  // Does the store path gcc was told about exist on this machine at all?
  printf("%s on this machine: %s\n", NIX_GCC,
         access(NIX_GCC, F_OK) == 0 ? "present" : "absent");
}
