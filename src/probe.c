#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
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
  FILE *f = fopen("/proc/net/dev", "r");
  char line[512];
  int interfaces = 0;
  while (f && fgets(line, sizeof(line), f))
    interfaces += strchr(line, ':') && !strstr(line, " lo:");
  printf("network interfaces besides lo: %d\n", f ? interfaces : -1);
  if (f)
    fclose(f);

  // Privilege: what could get back to the rest of the machine.
  f = fopen("/proc/self/status", "r");
  while (f && fgets(line, sizeof(line), f))
    if (strncmp(line, "CapEff:", 7) == 0)
      printf("effective capabilities: %s", line + 8);
  if (f)
    fclose(f);
  printf("mount: %s\n", mount("none", "/tmp", "tmpfs", 0, NULL) == 0 ? "allowed" : "denied");
  return 0;
}
