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

      gpus = mkOption {
        type = with types; listOf (submodule mdevConfig);
      };

      config = mkOption {
        type = with types; lines;
      };

      mdevConfig = mkOption {
        type = with types; listOf (submodule mdev);
      };

      mdev = with types; {
        num = mkOption {
          # How to make this different per mdev entry?
          type = int;
        };
        name = mkOption {
          type = string; 
        };
        vDevId = mkOption {
          # optional, list of common, custom 
        };
        # pDevId null, one of common, custom
        pDevId = mkOption {
          # optional, list of common, custom 
        };
        #gpuClass optional, default = "Compute"
        gpuClass = mkOption {
          type = string;
          default = "Compute";
        };
        # maxInstances: required 2?
        maxInstances = mkOption {
          type = int;
          default = 2;
        };
        # virtDisplay OPTIONAL submodule
        virtDisplay = {
          numHeads = mkOption {
            type = int;
            default = 4;
          };
          maxResX = mkOption {
            type = int;
            default = 1920;
          };
          maxResY = mkOption {
            type = int;
            default = 1080;
          };
        };

        # ecc: default false
        ecc = mkOption {
          type = bool;
          default = false;
        };
        # mapVideoSize: in MB default 24M (more for 4K?)
        mapVideoSize = mkOption {
          type = int; #int?
          default = 24;
        };
        # bar1Len (rebar?) hex number 
        bar1Len = mkOption {
          type = int; #int?
          default = 0x400;
        };

      };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {

        systemd.services.mdev-gpu = {
          description = "Configure GPU(s) to a state where they are ready to be virtualized.";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.mdev-gpu}/bin/mdev-cli --config ${builtins.toFile "mdev-config" cfg.config}";
          };
        };
      }
    ]
  );
}
