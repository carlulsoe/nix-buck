#pragma once
#include <stddef.h>

// Print where this program finds itself: kernel, host, the executable the
// kernel ran, the libc the loader mapped, and whether nixpkgs' gcc is here.
void report(void);

// The path of the first loaded object whose path contains `needle`, or "?".
void loaded(const char *needle, char *path, size_t size);
