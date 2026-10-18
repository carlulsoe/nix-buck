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
