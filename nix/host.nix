# A Nix host on Linux 7.3 that substitutes buck2 outputs and runs them.
#
# Its store starts as an erofs image of its own closure with a writable
# overlay, so whatever it gets beyond that comes through the substituter.
# At boot it runs /mnt/demo/run.sh, from the container's
# /var/lib/vms/host-demo, writes out.txt beside it, and powers off.
{ pkgs, modulesPath, ... }:

{
  imports = [ ./origin.nix "${modulesPath}/virtualisation/qemu-vm.nix" ];

  system.stateVersion = "26.05";
  networking.hostName = "nix-origin-host";

  nix.settings.experimental-features = [ "nix-command" "flakes" "fetch-closure" ];

  systemd.services.demo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nix-origin-binfmt.service" "nix-daemon.socket" "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.bash pkgs.nix pkgs.coreutils pkgs.jq ];
    serviceConfig = { Type = "oneshot"; StandardOutput = "journal+console"; StandardError = "journal+console"; };
    script = ''
      if [ -e /mnt/demo/run.sh ]; then
        sh /mnt/demo/run.sh > /mnt/demo/out.txt 2>&1 || echo "run.sh failed: $?" >> /mnt/demo/out.txt
      fi
      # --no-block: the poweroff job would otherwise wait on this very unit.
      systemctl poweroff --no-block
    '';
  };

  virtualisation = {
    useNixStoreImage = true;
    mountHostNixStore = false;
    writableStore = true;
    graphics = false;
    cores = 4;
    memorySize = 2048;
    # Container-local: the checkout is on a mount that ignores ownership.
    sharedDirectories.demo = { source = "/var/lib/vms/host-demo"; target = "/mnt/demo"; writable = true; };
  };
}
