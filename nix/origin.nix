# Linux 7.3 with the kernel's $ORIGIN PT_INTERP handler registered at boot.
{ config, lib, pkgs, ... }:

let
  kernel = config.boot.kernelPackages.kernel;
  nixOriginBpf = pkgs.callPackage ./nix-origin-bpf.nix { inherit kernel; };
in
{
  boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.kernelPatches = [{
    name = "binfmt-misc-bpf";
    patch = null;
    structuredExtraConfig = with lib.kernel; {
      # bpf handlers need binfmt_misc built in, not as a module.
      BINFMT_MISC = lib.mkForce yes;
      BINFMT_MISC_BPF = yes;
    };
  }];

  # Register the $ORIGIN handler before anything runs workloads.
  systemd.services.nix-origin-binfmt = {
    description = "binfmt_misc bpf handler: $ORIGIN in PT_INTERP";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];
    after = [ "sys-fs-bpf.mount" ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    path = [ pkgs.bpftools pkgs.util-linux ];
    script = ''
      mountpoint -q /proc/sys/fs/binfmt_misc ||
        mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
      mkdir -p /sys/fs/bpf/nix_origin
      bpftool struct_ops register ${nixOriginBpf}/nix_origin.bpf.o /sys/fs/bpf/nix_origin
      echo ':nix-origin:B::::nix_origin:' > /proc/sys/fs/binfmt_misc/register
    '';
  };
}
