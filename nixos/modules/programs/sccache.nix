{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.programs.sccache;
in {
  options.programs.sccache = {
    # host configuration
    enable = mkEnableOption "sccache";
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
      systemd.tmpfiles.rules = mkIf (cfg.cacheBackend == "local")
        [ "d ${cfg.cacheUrl} 0770 root nixbld -" ];

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
          exec('${pkgs.sccache}/bin/sccache', map { untaint $_ } @ARGV);
        '';
      };
    })

    # target configuration
    (mkIf (cfg.packageNames != []) {
      nixpkgs.overlays = [
        (self: super: genAttrs cfg.packageNames (pn: super.${pn}.override { stdenv = builtins.trace "with sccache: ${pn}" self.sccacheStdenv; }))

        (self: super: {
          sccacheWrapper = super.sccacheWrapper.override {
            extraConfig = ''
              export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
              export SCCACHE_DIR="${cfg.cacheUrl}"
              export SCCACHE_CACHE_SIZE="${cfg.cacheSize}"
              export SCCACHE_MAX_FRAME_LENGTH=104857600
              export SCCACHE_IGNORE_SERVER_IO_ERROR=1
              export SCCACHE_START_SERVER=1
              export SCCACHE_ERROR_LOG=/tmp/sccache_log.txt
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
