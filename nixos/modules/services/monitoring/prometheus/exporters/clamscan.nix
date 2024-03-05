{ config, lib, pkgs, options }:
with lib;
let
  cfg = config.services.prometheus.exporters.clamscan;
in
{
  port = 9967;
  extraOpts = {
    importPort = mkOption {
      type = types.port;
      default = 9000;
      description = lib.mdDoc ''
        Port to listen to tcp connections on from clamscan netcat pipe.
      '';
    };
  };

  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-clamscan-exporter}/bin/clamscan-exporter \
         -http-port ${toString cfg.port} \
         -tcp-port ${toString cfg.importPort}
      '';
    };
  };
}
