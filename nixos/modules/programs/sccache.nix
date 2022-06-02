{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.programs.sccache;
  port = 4226;
in {
  options.programs.sccache = {
    # host configuration
    enable = mkEnableOption "sccache";
    service = mkEnableOption "sccache service";
    cacheBackend = mkOption {
      type = types.enum [ "local" "s3" "redis" "memcached" "gcs" "azure" ];
      description = "cache backend for sccache";
      default = "local";
    };
    cacheUrl = mkOption {
      type = types.str;
      description = "cache path or primary URL e.g. SCCACHE_DIR, SCCACHE_BUCKET"; 
      default = "/var/cache/sccache";
    };
    cacheSize = mkOption {
      type = types.str;
      description = "Size of cache (only local?)";
      default = "10G";
    };
    # target configuration
    packageNames = mkOption {
      type = types.listOf types.str;
      description = "Nix top-level packages to be compiled using sccache";
      default = [];
      example = [ "wxGTK30" "ffmpeg" "libav_all" ];
    };
    # TODO: AWS credentials, secure Redis pw, GCS credentials, etc.
  };

  config = mkMerge [
    # host configuration
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = lib.optional (cfg.cacheBackend == "local")
        "d ${cfg.cacheUrl} 0770 root nixbld -";

      security.wrappers.nix-sccache = {
        owner = "root";
        group = "nixbld";
        setuid = false;
        setgid = true;
        source = pkgs.writeScript "nix-sccache.pl" ''
          #!${pkgs.perl}/bin/perl

          %ENV=( SCCACHE_DIR => '${cfg.cacheUrl}' );
          sub untaint {
            my $v = shift;
            return '-V' if $v eq '-V' || $v eq '--version';
            return '-s' if $v eq '-s' || $v eq '--show-stats';
            return '-z' if $v eq '-z' || $v eq '--zero-stats';
            exec('${pkgs.sccache}/bin/sccache', '-h');
          }
          ''+
          # Open TCP socket if it isn't open already.
          ''
          system("${pkgs.socat} TCP-LISTEN:${toString port},reuseaddr,fork UNIX-CONNECT:/tmp/sccache.sock || : & ");
          ''+''
          exec('${pkgs.sccache}/bin/sccache', map { untaint $_ } @ARGV);
        '';
      };
    })

    (mkIf cfg.service {
      systemd.services.sccache = {
        after = [ "network-online.target" ];
        description = "sccache single instance server.";
        wantedBy = [ "multi-user.target" ];
        environment = {
          SCCACHE_LOG = "debug";
          SCCACHE_NO_DAEMON = "1";
          SCCACHE_START_SERVER = "1";
          SCCACHE_DIR = cfg.cacheUrl;
        };
        # Create UNIX socket for use inside of nix sandbox.
        script = ''
          ${pkgs.sccache}/bin/sccache &
          sleep 10
          ${pkgs.socat}/bin/socat TCP:127.0.0.1:${toString port},reuseaddr UNIX-LISTEN:/tmp/sccache.sock &
          sleep 5
          chmod ug+rw /tmp/sccache.sock
        '';

        serviceConfig = {
          User = "root";
          Group = "nixbld";
          Type = "forking";
        };
      };
    })

    # target configuration
    (mkIf (cfg.packageNames != []) {
      nixpkgs.overlays = [
        (self: super: genAttrs cfg.packageNames (pn: super.${pn}.override { stdenv = builtins.trace "with sccache: ${pn}" self.sccacheStdenv; }))

        (self: super: {
          sccacheWrapper = super.sccacheWrapper.override {
            # How to set port via env variable?
            extraConfig = ''
              export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
              export SCCACHE_DIR="${cfg.cacheUrl}"
              export SCCACHE_CACHE_SIZE="${cfg.cacheSize}"
              export SCCACHE_MAX_FRAME_LENGTH=104857600
              export SCCACHE_IGNORE_SERVER_IO_ERROR=1
              export SCCACHE_START_SERVER=0
              export SCCACHE_LOG=debug
              export SCCACHE_NO_DAEMON=1
              if [ ! -d "$SCCACHE_DIR" ]; then
                echo "====="
                echo "Directory '$SCCACHE_DIR' does not exist"
                echo "Please create it with:"
                echo "  sudo mkdir -m0770 '$SCCACHE_DIR'"
                echo "  sudo chown root:nixbld '$SCCACHE_DIR'"
                echo "====="
                exit 1
              fi
              if [ ! -w "$SCCACHE_DIR" ]; then
                echo "====="
                echo "Directory '$SCCACHE_DIR' is not accessible for user $(whoami)"
                echo "Please verify its access permissions"
                echo "====="
                exit 1
              fi
            '';
          };
        })
      ];
    })
  ];
}
