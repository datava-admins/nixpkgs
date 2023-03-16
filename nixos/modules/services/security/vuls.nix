{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.services.vuls;
  #format = pkgs.formats.toml { };
  #vulsConfig = format.generate "vuls.toml" cfg.settings;
  vulsConfig = (pkgs.writeText "vuls.toml" cfg.settings);
in
{
  # TODO: integrate goval-dictionary and other CVE updaters.
  # TODOσ implement cacheddb setting
  options = {
    services.vuls = {
      enable = mkEnableOption (lib.mdDoc "Vuls");
      interval = mkOption {
        type = types.str;
        default = "daily";
        description = mdDoc ''
          Interval to run Vuls scan.
        '';
      };
      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/vuls";
        description = mdDoc ''
          Interval to run Vuls scan.
        '';
      };
      #TODO implement TOML settings.
      settings = mkOption {
        type = types.str;
        default = ''
          [servers]

          [servers.localhost]
          host = "localhost"
          port = "local"
          scanMode = [ "fast-root" ]
          findLock = false
        '';
        description = mdDoc ''
          See vuls config.toml.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.vuls = {
      description = "Vuls security scanner.";
      path = with pkgs; [ vulnix ];
      #wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecPreStart = "${vuls}/bin/vuls configtest -config ${vulsConfig}";
        ExecStart = "${vuls}/bin/vuls scan -ips -config ${vulsConfig} -results-dir ${cfg.stateDir}/results";
        # Try w/o root?
        #DynamicUser = true;
        Type = "simple";
      };
      startAt = cfg.interval;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 root root -"
      "d ${cfg.stateDir}/reports 0755 root root -"
    ];
  };
}
