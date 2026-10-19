# Generated from the flake's relocated closures (nix/pins.py); install
# with `nix run .#push-closure`. Do not edit.
NIX_CLOSURES = {
    "bash": {
        "digest": "991117ef16ead906b985607afe5ec863e5e03af05e16eaab65f9cf574a109e11:164",
        "originals": {
            "bash": "1mv3qz005gkbalxfghk4y3s8ayv4d2dl-bash-interactive-5.3p15"
        },
        "references": {
            "092adj9f7dgn821dhzwqdxlmhx9abl66-readline-8.3p3": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6"
            ],
            "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc": [],
            "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25": [
                "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8"
            ],
            "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8": [
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2": [
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6"
            ],
            "1parks22f011p4rj6nzvp3aq9wakvwcm-bash-interactive-5.3p15": [
                "092adj9f7dgn821dhzwqdxlmhx9abl66-readline-8.3p3",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6",
                "1parks22f011p4rj6nzvp3aq9wakvwcm-bash-interactive-5.3p15"
            ]
        },
        "roots": {
            "bash": "1parks22f011p4rj6nzvp3aq9wakvwcm-bash-interactive-5.3p15"
        }
    },
    "curl": {
        "digest": "ced24bfb87572ef7487006dcc77eda308d0772add9440502aee3c0192fbcf7e0:164",
        "originals": {
            "curl": "36alc2mwna4nzf6djdj2hvh4w4r3cai5-curl-8.22.0",
            "curl-dev": "aph5dkajglxjn9642bp0h3x7cwzijr52-curl-8.22.0-dev",
            "libpsl": "lhk23vackrdgmxya733h3wp01xz622gn-libpsl-0.21.5",
            "libpsl-dev": "nzn56qpiz5vm9zp7isv8q6ma7i900hqv-libpsl-0.21.5-dev",
            "openssl": "cxd8d2vg70c3pa31v2473hphaa1v0j44-openssl-3.5.8",
            "openssl-dev": "hc6mxys4iyawmwiyaixkcl9izjrqmr2q-openssl-3.5.8-dev"
        },
        "references": {
            "0291nn3in5i6vnqjjpcv6a63gmjp0f2w-brotli-1.2.0-lib": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1099cpsbclgv3bgbrrni9id0dyqknxnv-gcc-16.2.0-libgcc"
            ],
            "0763hb4lzv9a75xv83qdj1rcrmggv6r5-zstd-1.5.7-bin": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0763hb4lzv9a75xv83qdj1rcrmggv6r5-zstd-1.5.7-bin",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "18h28xby3f6mzszf3xs5jynjw5q0941x-gnugrep-3.12",
                "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15"
            ],
            "0811l0cr9xj0758ajfz7hacmn41r89bj-nghttp2-1.70.0": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "12plmkqxm6mml2grhwhhilba48c8679z-c-ares-1.34.8",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib",
                "1ri1j5r3pvnsnwg406jyv0972a5dd440-libev-4.33"
            ],
            "090fcslqnf8y160878lbgm9hwmyjqnnm-nghttp3-1.17.0-dev": [
                "090fcslqnf8y160878lbgm9hwmyjqnnm-nghttp3-1.17.0-dev",
                "1g915ka5b9yrn3vb9b127nm00d0ld4q1-nghttp3-1.17.0"
            ],
            "0bhz5bpn33dqv73pl1zi0wi021rjigss-pcre2-10.48": [
                "0bhz5bpn33dqv73pl1zi0wi021rjigss-pcre2-10.48",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "0c1m3byzwi5iwic6b6300dbrc74qi7f8-libpsl-0.21.5-dev": [
                "0c1m3byzwi5iwic6b6300dbrc74qi7f8-libpsl-0.21.5-dev",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
                "1zhf3vjfjfzlbxg2dccygxid698m8dr1-publicsuffix-list-0-unstable-2026-09-02"
            ],
            "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc": [],
            "0gh1s3crs70nlkwaymn0vklw4bhyw379-zlib-1.3.2-static": [],
            "0kd8imza9xqirj174wphhv4x0zwdpfl1-libedit-20260508-3.1": [
                "0kd8imza9xqirj174wphhv4x0zwdpfl1-libedit-20260508-3.1",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6"
            ],
            "0pbhqz344z961k9jnd9946v91jp96h0w-curl-8.22.0": [
                "0291nn3in5i6vnqjjpcv6a63gmjp0f2w-brotli-1.2.0-lib",
                "0pbhqz344z961k9jnd9946v91jp96h0w-curl-8.22.0",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "11gims3x36i6n0pjzz0lyij0b1vbm41l-ngtcp2-1.23.0",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1g915ka5b9yrn3vb9b127nm00d0ld4q1-nghttp3-1.17.0",
                "1gfi4mgx5gqdksc6jykbiqiy06g00z6j-libssh2-1.11.1",
                "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7",
                "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "0rxal52l9chiqnzai2vfjv4jww0zjvxi-openssl-3.5.8-bin": [
                "0rxal52l9chiqnzai2vfjv4jww0zjvxi-openssl-3.5.8-bin",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8"
            ],
            "0s4mrcgfn8h1i46dsb1wl45xywqks155-keyutils-1.6.3-lib": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "0vpw07bw8yhfzdzlha3hgm25v5nnq3p1-curl-8.22.0-man": [],
            "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25": [
                "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8"
            ],
            "1099cpsbclgv3bgbrrni9id0dyqknxnv-gcc-16.2.0-libgcc": [],
            "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "11gims3x36i6n0pjzz0lyij0b1vbm41l-ngtcp2-1.23.0": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8"
            ],
            "12nvm3d3fdxbs6lb8rb1a5yh5g521m81-libssh2-1.11.1-dev": [
                "12nvm3d3fdxbs6lb8rb1a5yh5g521m81-libssh2-1.11.1-dev",
                "16ladilnrz6b8gs1v6pnx18bkr4j2j9v-openssl-3.5.8-dev",
                "1gfi4mgx5gqdksc6jykbiqiy06g00z6j-libssh2-1.11.1"
            ],
            "12plmkqxm6mml2grhwhhilba48c8679z-c-ares-1.34.8": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "12plmkqxm6mml2grhwhhilba48c8679z-c-ares-1.34.8"
            ],
            "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8": [
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2": [
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "160bi73cdgjr8lh1kxrvw4l7cmsi52nw-krb5-1.22.2-dev": [
                "160bi73cdgjr8lh1kxrvw4l7cmsi52nw-krb5-1.22.2-dev",
                "1dprd055yl8y4h64kj2sz5vprvysi36y-krb5-1.22.2",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "1637law14xcn1qv4lv9x2x0yg924shax-curl-8.22.0-bin": [
                "0291nn3in5i6vnqjjpcv6a63gmjp0f2w-brotli-1.2.0-lib",
                "0pbhqz344z961k9jnd9946v91jp96h0w-curl-8.22.0",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "11gims3x36i6n0pjzz0lyij0b1vbm41l-ngtcp2-1.23.0",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1g915ka5b9yrn3vb9b127nm00d0ld4q1-nghttp3-1.17.0",
                "1gfi4mgx5gqdksc6jykbiqiy06g00z6j-libssh2-1.11.1",
                "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15",
                "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "16ladilnrz6b8gs1v6pnx18bkr4j2j9v-openssl-3.5.8-dev": [
                "0rxal52l9chiqnzai2vfjv4jww0zjvxi-openssl-3.5.8-bin",
                "16ladilnrz6b8gs1v6pnx18bkr4j2j9v-openssl-3.5.8-dev",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8"
            ],
            "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8"
            ],
            "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "17mk1a2gbal33fqclfcs0pbj6y6mpwd6-ncurses-6.6"
            ],
            "18h28xby3f6mzszf3xs5jynjw5q0941x-gnugrep-3.12": [
                "0bhz5bpn33dqv73pl1zi0wi021rjigss-pcre2-10.48",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "18h28xby3f6mzszf3xs5jynjw5q0941x-gnugrep-3.12"
            ],
            "1crmbdm2rxj4ic5s5j6jy082lh1vndkk-libidn2-2.3.8-bin": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "1d5hpmak15vrmw47fx6h2mi8h4gvw11g-ngtcp2-1.23.0-dev": [
                "11gims3x36i6n0pjzz0lyij0b1vbm41l-ngtcp2-1.23.0",
                "1d5hpmak15vrmw47fx6h2mi8h4gvw11g-ngtcp2-1.23.0-dev"
            ],
            "1dprd055yl8y4h64kj2sz5vprvysi36y-krb5-1.22.2": [
                "0kd8imza9xqirj174wphhv4x0zwdpfl1-libedit-20260508-3.1",
                "0s4mrcgfn8h1i46dsb1wl45xywqks155-keyutils-1.6.3-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "1g915ka5b9yrn3vb9b127nm00d0ld4q1-nghttp3-1.17.0": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "1gfi4mgx5gqdksc6jykbiqiy06g00z6j-libssh2-1.11.1": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1gfi4mgx5gqdksc6jykbiqiy06g00z6j-libssh2-1.11.1"
            ],
            "1gm9lg5wxy10l6g5al99qk33wbmgbajb-brotli-1.2.0-dev": [
                "0291nn3in5i6vnqjjpcv6a63gmjp0f2w-brotli-1.2.0-lib",
                "1gm9lg5wxy10l6g5al99qk33wbmgbajb-brotli-1.2.0-dev",
                "1p6bvyww2a123zg82g9an02mavwji58y-brotli-1.2.0"
            ],
            "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "1h9mps595bq3vi1051flgzmwabawlwv1-libidn2-2.3.8-dev": [
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "1crmbdm2rxj4ic5s5j6jy082lh1vndkk-libidn2-2.3.8-bin",
                "1h9mps595bq3vi1051flgzmwabawlwv1-libidn2-2.3.8-dev"
            ],
            "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15"
            ],
            "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2",
                "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
                "1zhf3vjfjfzlbxg2dccygxid698m8dr1-publicsuffix-list-0-unstable-2026-09-02"
            ],
            "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib"
            ],
            "1n457kcx9r0wbh29gpw7grljs69ya1hx-nghttp2-1.70.0-dev": [
                "0811l0cr9xj0758ajfz7hacmn41r89bj-nghttp2-1.70.0",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib",
                "1n457kcx9r0wbh29gpw7grljs69ya1hx-nghttp2-1.70.0-dev"
            ],
            "1nslirpb8sqr94vd9g9chhaj22aqg7k4-zstd-1.5.7-dev": [
                "0763hb4lzv9a75xv83qdj1rcrmggv6r5-zstd-1.5.7-bin",
                "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7",
                "1nslirpb8sqr94vd9g9chhaj22aqg7k4-zstd-1.5.7-dev"
            ],
            "1p6bvyww2a123zg82g9an02mavwji58y-brotli-1.2.0": [
                "0291nn3in5i6vnqjjpcv6a63gmjp0f2w-brotli-1.2.0-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "1p85jdm93nl3ddh9x9ahly690g4nkvsq-curl-8.22.0-dev": [
                "090fcslqnf8y160878lbgm9hwmyjqnnm-nghttp3-1.17.0-dev",
                "0c1m3byzwi5iwic6b6300dbrc74qi7f8-libpsl-0.21.5-dev",
                "0pbhqz344z961k9jnd9946v91jp96h0w-curl-8.22.0",
                "0vpw07bw8yhfzdzlha3hgm25v5nnq3p1-curl-8.22.0-man",
                "11gims3x36i6n0pjzz0lyij0b1vbm41l-ngtcp2-1.23.0",
                "12nvm3d3fdxbs6lb8rb1a5yh5g521m81-libssh2-1.11.1-dev",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "160bi73cdgjr8lh1kxrvw4l7cmsi52nw-krb5-1.22.2-dev",
                "1637law14xcn1qv4lv9x2x0yg924shax-curl-8.22.0-bin",
                "16ladilnrz6b8gs1v6pnx18bkr4j2j9v-openssl-3.5.8-dev",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1d5hpmak15vrmw47fx6h2mi8h4gvw11g-ngtcp2-1.23.0-dev",
                "1g915ka5b9yrn3vb9b127nm00d0ld4q1-nghttp3-1.17.0",
                "1gm9lg5wxy10l6g5al99qk33wbmgbajb-brotli-1.2.0-dev",
                "1h12i6vylahv486lj46l4sr0l0ag95xs-zstd-1.5.7",
                "1h9mps595bq3vi1051flgzmwabawlwv1-libidn2-2.3.8-dev",
                "1jw6yf42va9zvnfba7civw5pwnrisyrf-bash-5.3p15",
                "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
                "1mcszjlqq21dza67g7qihm4dcs6rmmb7-nghttp2-1.70.0-lib",
                "1n457kcx9r0wbh29gpw7grljs69ya1hx-nghttp2-1.70.0-dev",
                "1nslirpb8sqr94vd9g9chhaj22aqg7k4-zstd-1.5.7-dev",
                "1p85jdm93nl3ddh9x9ahly690g4nkvsq-curl-8.22.0-dev",
                "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "1ri1j5r3pvnsnwg406jyv0972a5dd440-libev-4.33": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1ri1j5r3pvnsnwg406jyv0972a5dd440-libev-4.33"
            ],
            "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev": [
                "0gh1s3crs70nlkwaymn0vklw4bhyw379-zlib-1.3.2-static",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
                "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev"
            ],
            "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib": [
                "0s4mrcgfn8h1i46dsb1wl45xywqks155-keyutils-1.6.3-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
                "1z3y3jpzz8hzmpgkgkpyk7nc9j2anh40-krb5-1.22.2-lib"
            ],
            "1zhf3vjfjfzlbxg2dccygxid698m8dr1-publicsuffix-list-0-unstable-2026-09-02": []
        },
        "roots": {
            "curl": "0pbhqz344z961k9jnd9946v91jp96h0w-curl-8.22.0",
            "curl-dev": "1p85jdm93nl3ddh9x9ahly690g4nkvsq-curl-8.22.0-dev",
            "libpsl": "1l752i8wiccghb3x0064kqs16ql0cgjf-libpsl-0.21.5",
            "libpsl-dev": "0c1m3byzwi5iwic6b6300dbrc74qi7f8-libpsl-0.21.5-dev",
            "openssl": "173knz040xwhcbzkbda7c1fv2ibrxqjh-openssl-3.5.8",
            "openssl-dev": "16ladilnrz6b8gs1v6pnx18bkr4j2j9v-openssl-3.5.8-dev"
        }
    },
    "gcc": {
        "digest": "28b2aa73bb3a59181b3aa2dd40f787b18189d54c1d0ef95cb26a035457c2346b:164",
        "originals": {
            "binutils": "y5sgl0vvrpbcwgjwpjs60r1hg0gi7i0n-binutils-2.46",
            "gcc": "5q6bdxkp7lc70gn9mnf4yiybrx8ry5xq-gcc-16.2.0",
            "gcc-lib": "j7qx4s4mr17j1wqgvqdzj33lmrnzb387-gcc-16.2.0-lib",
            "glibc": "h4wfwic161kxrr74jlzla5lsm28hgary-glibc-2.44-25",
            "glibc-dev": "m38wglsqnh1mrmj2cmqa3pjb6w4yjxdi-glibc-2.44-25-dev",
            "linux-headers": "ggggdaqvaxkimbzx5p6knxr2nlqlqqnl-linux-headers-7.2"
        },
        "references": {
            "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1099cpsbclgv3bgbrrni9id0dyqknxnv-gcc-16.2.0-libgcc"
            ],
            "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc": [],
            "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0": [
                "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "0jcjp3z3vhkbjc6vnygqj70pkypj82l8-mpfr-4.2.2": [
                "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0",
                "0jcjp3z3vhkbjc6vnygqj70pkypj82l8-mpfr-4.2.2",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "0lf1hajqi5kr935wm9mf0anb2bf0py2w-gcc-16.2.0": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0",
                "0jcjp3z3vhkbjc6vnygqj70pkypj82l8-mpfr-4.2.2",
                "0lf1hajqi5kr935wm9mf0anb2bf0py2w-gcc-16.2.0",
                "0n12zh99dqkafbrwqlbhx56bgg06bcxc-libmpc-1.4.1",
                "0rqwfy46h02qm13xp7zvxc9i0f4czd7n-glibc-2.44-25-dev",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
                "1fa0vd04yxbcgkpdfkdsikd726bjmyiy-isl-0.20"
            ],
            "0mxll92afyffkab6ycwammpp0an28zpa-binutils-2.46-lib": [
                "0mxll92afyffkab6ycwammpp0an28zpa-binutils-2.46-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2"
            ],
            "0n12zh99dqkafbrwqlbhx56bgg06bcxc-libmpc-1.4.1": [
                "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0",
                "0jcjp3z3vhkbjc6vnygqj70pkypj82l8-mpfr-4.2.2",
                "0n12zh99dqkafbrwqlbhx56bgg06bcxc-libmpc-1.4.1",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "0rqwfy46h02qm13xp7zvxc9i0f4czd7n-glibc-2.44-25-dev": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13rgrk2km9sk9mi618cdvn6rjrj577nf-glibc-2.44-25-bin",
                "1c2b89r5mx55y9iqgm8kkihh2nxsr8iy-linux-headers-7.2"
            ],
            "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25": [
                "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8"
            ],
            "1099cpsbclgv3bgbrrni9id0dyqknxnv-gcc-16.2.0-libgcc": [],
            "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8": [
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "13rgrk2km9sk9mi618cdvn6rjrj577nf-glibc-2.44-25-bin": [
                "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13rgrk2km9sk9mi618cdvn6rjrj577nf-glibc-2.44-25-bin"
            ],
            "1594zm6fdcdf4cpbr4qi0yb7pdbla2lb-binutils-2.46": [
                "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
                "0mxll92afyffkab6ycwammpp0an28zpa-binutils-2.46-lib",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
                "1594zm6fdcdf4cpbr4qi0yb7pdbla2lb-binutils-2.46"
            ],
            "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2": [
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "1c2b89r5mx55y9iqgm8kkihh2nxsr8iy-linux-headers-7.2": [],
            "1fa0vd04yxbcgkpdfkdsikd726bjmyiy-isl-0.20": [
                "0imnc2rgisc0d1wdsmfnpjfjxb65bqf9-gmp-6.3.0",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "1fa0vd04yxbcgkpdfkdsikd726bjmyiy-isl-0.20"
            ]
        },
        "roots": {
            "binutils": "1594zm6fdcdf4cpbr4qi0yb7pdbla2lb-binutils-2.46",
            "gcc": "0lf1hajqi5kr935wm9mf0anb2bf0py2w-gcc-16.2.0",
            "gcc-lib": "062gpkf2gcjw895hwhqxain9n1vzjnnj-gcc-16.2.0-lib",
            "glibc": "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
            "glibc-dev": "0rqwfy46h02qm13xp7zvxc9i0f4czd7n-glibc-2.44-25-dev",
            "linux-headers": "1c2b89r5mx55y9iqgm8kkihh2nxsr8iy-linux-headers-7.2"
        }
    },
    "zlib": {
        "digest": "54525cb95243510ca20720d56e29e47cabae38b56857493f046943dda6de9d0d:164",
        "originals": {
            "zlib": "wgw25d181h0qks7qsfp1bh7c5nd3f0s7-zlib-1.3.2",
            "zlib-dev": "879xd5x23lfd4l93jz71yaz06wa15yc1-zlib-1.3.2-dev"
        },
        "references": {
            "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc": [],
            "0gh1s3crs70nlkwaymn0vklw4bhyw379-zlib-1.3.2-static": [],
            "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25": [
                "0czv80mrcx7kjy459f24acq31vnks3rp-xgcc-16.2.0-libgcc",
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25",
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8"
            ],
            "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2": [
                "0ylhxlq26a4n965z5byim72kvk3902lx-glibc-2.44-25"
            ],
            "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8": [
                "13q6fwkvh05pfgsk82nhy7w9b6sazlfl-libidn2-2.3.8",
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2": [
                "15v92bar0qvp0dzv38fzvfqbp6cckscl-libunistring-1.4.2"
            ],
            "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev": [
                "0gh1s3crs70nlkwaymn0vklw4bhyw379-zlib-1.3.2-static",
                "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
                "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev"
            ]
        },
        "roots": {
            "zlib": "117cr1wshpmlan2ghx7a8pvc133bv2dn-zlib-1.3.2",
            "zlib-dev": "1w79nnxdx14qa5bf5vymj8zirkmsgi8r-zlib-1.3.2-dev"
        }
    }
}
