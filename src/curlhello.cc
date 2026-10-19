#include <climits>
#include <cstdio>
#include <string>
#include <unistd.h>

#include <curl/curl.h>
#include <libpsl.h>
#include <openssl/crypto.h>
#include <openssl/provider.h>

extern "C" {
#include "report.h"
}

// libcurl from nixpkgs, in C++. Its closure's libraries name files in other
// store paths by absolute path: do those resolve where this runs?
static const char *here(const std::string &path) {
  return access(path.c_str(), F_OK) == 0 ? "present" : "absent";
}

static size_t collect(char *data, size_t size, size_t n, void *out) {
  static_cast<std::string *>(out)->append(data, size * n);
  return size * n;
}

int main() {
  if (curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK) {
    std::fprintf(stderr, "curl_global_init failed\n");
    return 1;
  }
  const curl_version_info_data *v = curl_version_info(CURLVERSION_NOW);

  // A transfer that needs no network: this program's own bytes.
  char exe[PATH_MAX] = {0};
  readlink("/proc/self/exe", exe, sizeof(exe) - 1);
  std::string body;
  CURL *h = curl_easy_init();
  curl_easy_setopt(h, CURLOPT_URL, ("file://" + std::string(exe)).c_str());
  curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, collect);
  curl_easy_setopt(h, CURLOPT_WRITEDATA, &body);
  CURLcode rc = curl_easy_perform(h);
  curl_easy_cleanup(h);
  if (rc != CURLE_OK || body.compare(0, 4, "\x7f" "ELF") != 0) {
    std::fprintf(stderr, "file:// transfer failed: %s\n", curl_easy_strerror(rc));
    return 1;
  }

  // libpsl's list is a file in another store path, named by absolute path.
  std::string psl = psl_dist_filename();
  psl_ctx_t *ctx = psl_latest(nullptr);
  bool co_uk = ctx && psl_is_public_suffix(ctx, "co.uk");
  psl_free(ctx);

  // OpenSSL's providers are loaded from a directory named the same way.
  // It reports it as MODULESDIR: "<path>".
  std::string modules = OpenSSL_version(OPENSSL_MODULES_DIR);
  modules = modules.substr(modules.find('"') + 1);
  modules.pop_back();
  OSSL_PROVIDER *legacy = OSSL_PROVIDER_load(nullptr, "legacy");

  char libcurl[PATH_MAX];
  loaded("/libcurl.so", libcurl, sizeof(libcurl));
  std::printf("curl:           %s, %s, file:// %zu bytes\n", v->version, v->ssl_version,
              body.size());
  std::printf("libcurl:        %s\n", libcurl);
  std::printf("psl list:       %s (%s), co.uk public: %s\n", psl.c_str(), here(psl),
              co_uk ? "yes" : "no");
  std::printf("ossl modules:   %s (%s), legacy provider: %s\n", modules.c_str(),
              here(modules), legacy ? "loaded" : "not loaded");
  report();
  return 0;
}
