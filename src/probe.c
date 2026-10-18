#include <stdio.h>
#include <string.h>
#include <unistd.h>

// Paths every worker has and no action should see: its store, its shell
// and system files, NativeLink's CAS and action cache, and other homes.
static const char *const worker[] = {
    "/nix/store", "/bin/sh", "/usr",  "/etc/passwd", "/var/lib/nativelink/cas",
    "/var/lib/nativelink/ac", "/run", "/root", "/sys",
};

int main(void) {
  for (size_t i = 0; i < sizeof(worker) / sizeof(*worker); i++)
    printf("%s: %s\n", worker[i], access(worker[i], F_OK) == 0 ? "visible" : "hidden");

  // The network: interfaces are the /proc/net/dev lines with a colon.
  FILE *dev = fopen("/proc/net/dev", "r");
  char line[512];
  int interfaces = 0;
  while (dev && fgets(line, sizeof(line), dev))
    interfaces += strchr(line, ':') && !strstr(line, " lo:");
  printf("network interfaces besides lo: %d\n", dev ? interfaces : -1);
  return 0;
}
