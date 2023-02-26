{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mdev-gpu;
in {

  options.services.mdev-gpu= {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable Mdev-GPU Service";
      };

      config = mkOption {
        type = with types; lines;
        description = lib.mdDoc "Configuration of mdev gpu options in YAML";
      };

  };

  config = mkIf cfg.enable (
    mkMerge [
      {

        systemd.services.mdev-gpu = {
          description = "Configure GPU(s) to a state where they are ready to be virtualized.";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "5";
            ExecStart = "${pkgs.mdev-gpu}/bin/mdev-cli --config ${builtins.toFile "mdev-config" cfg.config}";
          };
        };
      }
    ]
  );
}
