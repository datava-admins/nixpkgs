{ config, lib, pkgs, ... }:
with lib;
let
  clamavUser = "clamav";
  stateDir = "/var/lib/clamav";
  runDir = "/run/clamav";
  clamavGroup = clamavUser;
  cfg = config.services.clamav;
  pkg = pkgs.clamav;

  toKeyValue = generators.toKeyValue {
    mkKeyValue = generators.mkKeyValueDefault { } " ";
    listsAsDuplicateKeys = true;
  };

  clamdConfigFile = pkgs.writeText "clamd.conf" (toKeyValue cfg.daemon.settings);
  freshclamConfigFile = pkgs.writeText "freshclam.conf" (toKeyValue cfg.updater.settings);
in
{
  imports = [
    (mkRemovedOptionModule [ "services" "clamav" "updater" "config" ] "Use services.clamav.updater.settings instead.")
    (mkRemovedOptionModule [ "services" "clamav" "updater" "extraConfig" ] "Use services.clamav.updater.settings instead.")
    (mkRemovedOptionModule [ "services" "clamav" "daemon" "extraConfig" ] "Use services.clamav.daemon.settings instead.")
  ];

  options = {
    services.clamav = {
      daemon = {
        enable = mkEnableOption (lib.mdDoc "ClamAV clamd daemon");

        settings = mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = lib.mdDoc ''
            ClamAV configuration. Refer to <https://linux.die.net/man/5/clamd.conf>,
            for details on supported values.
          '';
        };
      };
      updater = {
        enable = mkEnableOption (lib.mdDoc "ClamAV freshclam updater");

        frequency = mkOption {
          type = types.int;
          default = 12;
          description = lib.mdDoc ''
            Number of database checks per day.
          '';
        };

        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = lib.mdDoc ''
            How often freshclam is invoked. See systemd.time(7) for more
            information about the format.
          '';
        };

        settings = mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = lib.mdDoc ''
            freshclam configuration. Refer to <https://linux.die.net/man/5/freshclam.conf>,
            for details on supported values.
          '';
        };
      };
      scanner = {
        enable = mkEnableOption (lib.mdDoc "ClamAV Scheduled Scan");
        sendToExporter = mkOption {
          type = types.bool;
          default = config.services.prometheus.exporters.clamscan.enable;
          defaultText = literalExpression "config.services.prometheus.exporters.clamscan.enable";
          description = lib.mdDoc ''
            Wether to send the scan results to the Prometheus clamscan exporter or just stdout.
          '';
        };
        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = lib.mdDoc ''
            How often clascan(d) is invoked. See systemd.time(7) for more
            information about the format.
          '';
        };
        scanPaths = mkOption {
          type = with types; listOf str;
          default = [ "/" ];
          description = lib.mdDoc ''
            What directories/file patterns to scan (passed to find)
          '';
        };
      };
    };
  };

  config = mkIf (cfg.updater.enable || cfg.daemon.enable) {
    environment.systemPackages = [ pkg ];

    users.users.${clamavUser} = {
      uid = config.ids.uids.clamav;
      group = clamavGroup;
      description = "ClamAV daemon user";
      home = stateDir;
    };

    users.groups.${clamavGroup} =
      { gid = config.ids.gids.clamav; };

    services.clamav.daemon.settings = {
      DatabaseDirectory = stateDir;
      LocalSocket = "${runDir}/clamd.ctl";
      PidFile = "${runDir}/clamd.pid";
      TemporaryDirectory = "/tmp";
      User = "clamav";
      Foreground = true;
    };

    services.clamav.updater.settings = {
      DatabaseDirectory = stateDir;
      Foreground = true;
      Checks = cfg.updater.frequency;
      DatabaseMirror = [ "database.clamav.net" ];
    };

    environment.etc."clamav/freshclam.conf".source = freshclamConfigFile;
    environment.etc."clamav/clamd.conf".source = clamdConfigFile;

    systemd.services.clamav-daemon = mkIf cfg.daemon.enable {
      description = "ClamAV daemon (clamd)";
      after = optional cfg.updater.enable "clamav-freshclam.service";
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ clamdConfigFile ];

      preStart = ''
        mkdir -m 0755 -p ${runDir}
        chown ${clamavUser}:${clamavGroup} ${runDir}
      '';

      serviceConfig = {
        ExecStart = "${pkg}/bin/clamd";
        ExecReload = "${pkgs.coreutils}/bin/kill -USR2 $MAINPID";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        PrivateNetwork = "yes";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = "2";
        LimitNOFILE = 1048576;
      };
    };

    systemd.timers.clamav-freshclam = mkIf cfg.updater.enable {
      description = "Timer for ClamAV virus database updater (freshclam)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.updater.interval;
        Unit = "clamav-freshclam.service";
      };
    };

    systemd.services.clamav-freshclam = mkIf cfg.updater.enable {
      description = "ClamAV virus database updater (freshclam)";
      restartTriggers = [ freshclamConfigFile ];
      after = [ "network-online.target" ];
      preStart = ''
        mkdir -m 0755 -p ${stateDir}
        chown ${clamavUser}:${clamavGroup} ${stateDir}
      '';

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkg}/bin/freshclam";
        SuccessExitStatus = "1"; # if databases are up to date
        PrivateTmp = "yes";
        PrivateDevices = "yes";
      };
    };
    
    systemd.timers.clamav-scanner = mkIf cfg.updater.enable {
      description = "Timer for ClamAV Scanner";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.scanner.interval;
        Unit = "clamav-scanner.service";
      };
    };

    systemd.services.clamav-scanner = mkIf cfg.scanner.enable {
      description = "ClamAV Scanner";
      requires = [ "clamav-daemon.service" ];
      path = with pkgs; [ netcat ];

      serviceConfig = let
        # I guess if the daemon is not enabled then we need to call the regular clamscan.
        # For now just require that the daemon is running.
        scanCmd = ''
          ${pkgs.findutils}/bin/find ${builtins.toString cfg.scanner.scanPaths} -xdev -type f | \
          ${pkg}/bin/clamdscan --multiscan --stdout --no-summary --fdpass -f /dev/stdin ${(if cfg.scanner.sendToExporter then " | tee | nc -N 127.0.0.1 9000" else "")}
          '';
      in {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "clamav-scanner" scanCmd;
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        # Needs read access to all files...TODO: restrict fs to RO
        #DynamicUser = "yes";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = "2";
        LimitNOFILE = 1048576;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
