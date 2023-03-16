{ config, lib, pkgs, options }:
with lib;
let
  cfg = config.services.prometheus.exporters.vuls;
in
{
  port = 8080;
  # TODO: implement --basic_password, --log_format
  extraOpts = {
    reportsDir = mkOption {
      type = types.str;
      default = "${config.services.vuls.stateDir}/reports"; 
      defaultText = literalExpression ''"''${config.services.vuls.stateDir}/reports"'';
      description = lib.mdDoc ''
        Path to vuls reports directory.
      '';
    };
  };

  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-vuls-exporter}/bin/prometheus-vuls-exporter \
         --address ${toString cfg.listenAddress}:${toString cfg.port} \
         --reports_dir ${toString cfg.reportsDir}
      '';
    };
  };
}
