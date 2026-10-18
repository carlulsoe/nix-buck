# A NixOS remote-execution worker that has no toolchain of its own.
#
# origin.nix makes the kernel resolve $ORIGIN in PT_INTERP, so a relocated
# closure shipped as an action input runs from wherever NativeLink
# materializes it. The store is an erofs image of this system's closure
# only: no host store is mounted. Every action runs in a sandbox that shows
# it its input root and nothing else of this machine.
{ config, lib, pkgs, modulesPath, ... }:

let
  nativelink = pkgs.stdenvNoCC.mkDerivation {
    pname = "nativelink";
    version = "1.7.7";
    src = pkgs.fetchurl {
      url = "https://github.com/TraceMachina/nativelink/releases/download/v1.7.7/nativelink-1.7.7-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-bo+WTF05Q0QQ6m9cxiUcCDS/av0HXhhFOEJQFlZ4SOk=";
    };
    sourceRoot = ".";
    installPhase = "install -Dm555 nativelink $out/bin/nativelink";
  };

  state = "/var/lib/nativelink";

  # NativeLink runs every action as `sandbox ARGV...` in the action's input
  # root. Only that directory is visible, at the same path, with private
  # /proc, /dev and /tmp: no /nix/store, /bin, /usr or /etc, no other action
  # or the CAS, no network. An action can use only what it declared.
  sandbox = pkgs.writeShellScript "nativelink-sandbox" ''
    root=$(pwd)
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-pid --unshare-net --unshare-ipc --unshare-uts --unshare-cgroup \
      --die-with-parent --new-session \
      --bind "$root" "$root" --chdir "$root" \
      --proc /proc --dev /dev --tmpfs /tmp \
      -- "$@"
  '';

  store = name: {
    filesystem = {
      content_path = "${state}/${name}/content";
      temp_path = "${state}/${name}/tmp";
      eviction_policy.max_bytes = 8000000000;
    };
  };
  instances = f: map (instance_name: f instance_name) [ "" "main" ];

  # CAS, action cache, scheduler and one local worker in a single process.
  nativelinkConfig = {
    stores = [
      ({ name = "AC"; } // store "ac")
      {
        name = "CAS";
        # Workers hardlink inputs out of a filesystem "fast" store.
        fast_slow = { fast = store "cas"; slow.noop = { }; };
      }
    ];
    schedulers = [{
      name = "MAIN";
      simple.supported_platform_properties = {
        OSFamily = "priority";
        "container-image" = "priority";
      };
    }];
    workers = [{
      local = {
        worker_api_endpoint.uri = "grpc://127.0.0.1:50061";
        cas_fast_slow_store = "CAS";
        upload_action_result.ac_store = "AC";
        work_directory = "${state}/work";
        entrypoint = "${sandbox}";
        platform_properties = {
          OSFamily.values = [ "linux" ];
          "container-image".values = [ "" ];
        };
      };
    }];
    servers = [
      {
        name = "public";
        listener.http.socket_address = "0.0.0.0:50051";
        services = {
          cas = instances (i: { instance_name = i; cas_store = "CAS"; });
          ac = instances (i: { instance_name = i; ac_store = "AC"; });
          execution = instances (i: { instance_name = i; cas_store = "CAS"; scheduler = "MAIN"; });
          capabilities = instances (i: { instance_name = i; remote_execution.scheduler = "MAIN"; });
          bytestream = instances (i: { instance_name = i; cas_store = "CAS"; });
          health = { };
        };
      }
      {
        name = "worker_api";
        listener.http.socket_address = "127.0.0.1:50061";
        services.worker_api.scheduler = "MAIN";
      }
    ];
  };
in
{
  imports = [ ./origin.nix "${modulesPath}/virtualisation/qemu-vm.nix" ];

  system.stateVersion = "26.05";
  networking.hostName = "nix-origin-worker";

  systemd.services.nativelink = {
    description = "NativeLink CAS, scheduler and worker";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nix-origin-binfmt.service" ];
    requires = [ "nix-origin-binfmt.service" ];
    serviceConfig = {
      ExecStart = "${nativelink}/bin/nativelink ${pkgs.writeText "nativelink.json" (builtins.toJSON nativelinkConfig)}";
      StateDirectory = "nativelink";
      LimitNOFILE = 65536;
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [ 50051 ];

  # The worker carries its own closure and nothing else: no host store, no Nix.
  nix.enable = false;
  virtualisation = {
    useNixStoreImage = true;
    mountHostNixStore = false;
    writableStore = false;
    graphics = false;
    cores = 8;
    memorySize = 4096;
    diskSize = 16384;
    forwardPorts = [{ from = "host"; host.port = 50051; guest.port = 50051; }];
  };
  services.getty.autologinUser = "root";
}
