{ config, lib, pkgs, ... }:
with lib;
let
  clamavUser = "clamav";
  stateDir = "/var/lib/clamav";
  clamavGroup = clamavUser;
  cfg = config.services.clamav;

  toKeyValue = generators.toKeyValue {
    mkKeyValue = generators.mkKeyValueDefault { } " ";
    listsAsDuplicateKeys = true;
  };

  clamdConfigFile = pkgs.writeText "clamd.conf" (toKeyValue cfg.daemon.settings);
  freshclamConfigFile = pkgs.writeText "freshclam.conf" (toKeyValue cfg.updater.settings);
  fangfrischConfigFile = pkgs.writeText "fangfrisch.conf" ''
    ${lib.generators.toINI {} cfg.fangfrisch.settings}
  '';
in
{
  imports = [
    (mkRemovedOptionModule [ "services" "clamav" "updater" "config" ] "Use services.clamav.updater.settings instead.")
    (mkRemovedOptionModule [ "services" "clamav" "updater" "extraConfig" ] "Use services.clamav.updater.settings instead.")
    (mkRemovedOptionModule [ "services" "clamav" "daemon" "extraConfig" ] "Use services.clamav.daemon.settings instead.")
  ];

  options = {
    services.clamav = {
      package = mkPackageOption pkgs "clamav" { };
      daemon = {
        enable = mkEnableOption "ClamAV clamd daemon";

        settings = mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = ''
            ClamAV configuration. Refer to <https://linux.die.net/man/5/clamd.conf>,
            for details on supported values.
          '';
        };
      };
      updater = {
        enable = mkEnableOption "ClamAV freshclam updater";

        frequency = mkOption {
          type = types.int;
          default = 12;
          description = ''
            Number of database checks per day.
          '';
        };

        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = ''
            How often freshclam is invoked. See systemd.time(7) for more
            information about the format.
          '';
        };

        settings = mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = ''
            freshclam configuration. Refer to <https://linux.die.net/man/5/freshclam.conf>,
            for details on supported values.
          '';
        };
      };
      fangfrisch = {
        enable = mkEnableOption "ClamAV fangfrisch updater";

        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = ''
            How often freshclam is invoked. See systemd.time(7) for more
            information about the format.
          '';
        };

        settings = mkOption {
          type = lib.types.submodule {
            freeformType = with types; attrsOf (attrsOf (oneOf [ str int bool ]));
          };
          default = { };
          example = {
            securiteinfo = {
              enabled = "yes";
              customer_id = "your customer_id";
            };
          };
          description = ''
            fangfrisch configuration. Refer to <https://rseichter.github.io/fangfrisch/#_configuration>,
            for details on supported values.
            Note that by default urlhaus and sanesecurity are enabled.
          '';
        };
      };

      scanner = {
        enable = mkEnableOption ("ClamAV Scheduled Scan");
        sendToExporter = mkOption {
          type = types.bool;
          default = config.services.prometheus.exporters.clamscan.enable;
          defaultText = literalExpression "config.services.prometheus.exporters.clamscan.enable";
          description = ''
            Wether to send the scan results to the Prometheus clamscan exporter or just stdout.
          '';
        };
        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = ''
            How often clascan(d) is invoked. See systemd.time(7) for more
            information about the format.
          '';
        };
        scanPaths = mkOption {
          type = with types; listOf str;
          default = [ "/" ];
          description = ''
            What directories/file patterns to scan (passed to find)
          '';
        };

        scanDirectories = mkOption {
          type = with types; listOf str;
          default = [ "/home" "/var/lib" "/tmp" "/etc" "/var/tmp" ];
          description = ''
            List of directories to scan.
            The default includes everything I could think of that is valid for nixos. Feel free to contribute a PR to add to the default if you see something missing.
          '';
        };
      };
    };
  };

  config = mkIf (cfg.updater.enable || cfg.daemon.enable) {
    environment.systemPackages = [ cfg.package ];

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
      LocalSocket = "/run/clamav/clamd.ctl";
      PidFile = "/run/clamav/clamd.pid";
      User = "clamav";
      Foreground = true;
    };

    services.clamav.updater.settings = {
      DatabaseDirectory = stateDir;
      Foreground = true;
      Checks = cfg.updater.frequency;
      DatabaseMirror = [ "database.clamav.net" ];
    };

    services.clamav.fangfrisch.settings = {
      DEFAULT.db_url = mkDefault "sqlite:////var/lib/clamav/fangfrisch_db.sqlite";
      DEFAULT.local_directory = mkDefault stateDir;
      DEFAULT.log_level = mkDefault "INFO";
      urlhaus.enabled = mkDefault "yes";
      urlhaus.max_size = mkDefault "2MB";
      sanesecurity.enabled = mkDefault "yes";
    };

    environment.etc."clamav/freshclam.conf".source = freshclamConfigFile;
    environment.etc."clamav/clamd.conf".source = clamdConfigFile;

    systemd.slices.system-clamav = {
      description = "ClamAV Antivirus Slice";
    };

    systemd.services.clamav-daemon = mkIf cfg.daemon.enable {
      description = "ClamAV daemon (clamd)";
      after = optionals cfg.updater.enable [ "clamav-freshclam.service" ];
      wants = optionals cfg.updater.enable [ "clamav-freshclam.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ clamdConfigFile ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/clamd";
        ExecReload = "${pkgs.coreutils}/bin/kill -USR2 $MAINPID";
        User = clamavUser;
        Group = clamavGroup;
        StateDirectory = "clamav";
        RuntimeDirectory = "clamav";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        PrivateNetwork = "yes";
        Slice = "system-clamav.slice";
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
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/freshclam";
        SuccessExitStatus = "1"; # if databases are up to date
        StateDirectory = "clamav";
        User = clamavUser;
        Group = clamavGroup;
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        Slice = "system-clamav.slice";
      };
    };

    systemd.services.clamav-fangfrisch-init = mkIf cfg.fangfrisch.enable {
      wantedBy = [ "multi-user.target" ];
      # if the sqlite file can be found assume the database has already been initialised
      script = ''
        db_url="${cfg.fangfrisch.settings.DEFAULT.db_url}"
        db_path="''${db_url#sqlite:///}"

        if [ ! -f "$db_path" ]; then
          ${pkgs.fangfrisch}/bin/fangfrisch --conf ${fangfrischConfigFile} initdb
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "clamav";
        User = clamavUser;
        Group = clamavGroup;
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        Slice = "system-clamav.slice";
      };
    };

    systemd.timers.clamav-fangfrisch = mkIf cfg.fangfrisch.enable {
      description = "Timer for ClamAV virus database updater (fangfrisch)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.fangfrisch.interval;
        Unit = "clamav-fangfrisch.service";
      };
    };

    systemd.services.clamav-fangfrisch = mkIf cfg.fangfrisch.enable {
      description = "ClamAV virus database updater (fangfrisch)";
      restartTriggers = [ fangfrischConfigFile ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" "clamav-fangfrisch-init.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.fangfrisch}/bin/fangfrisch --conf ${fangfrischConfigFile} refresh";
        StateDirectory = "clamav";
        User = clamavUser;
        Group = clamavGroup;
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        Slice = "system-clamav.slice";
      };
    };

    systemd.timers.clamdscan = mkIf cfg.scanner.enable {
      description = "Timer for ClamAV virus scanner";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.scanner.interval;
        Unit = "clamdscan.service";
      };
    };

    systemd.services.clamdscan = mkIf cfg.scanner.enable {
      description = "ClamAV virus scanner";
      after = optionals cfg.updater.enable [ "clamav-freshclam.service" ];
      wants = optionals cfg.updater.enable [ "clamav-freshclam.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/clamdscan --multiscan --fdpass --infected --allmatch ${lib.concatStringsSep " " cfg.scanner.scanDirectories}";
        Slice = "system-clamav.slice";
        #ExecStart = "${pkg}/bin/clamdscan --multiscan --fdpass --infected --allmatch ${lib.concatStringsSep " " cfg.scanner.scanDirectories}";
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
