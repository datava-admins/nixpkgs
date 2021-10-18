{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tailscale;
  derpCfgOptions = {
      enable = mkEnableOption "Tailscale DERP Server daemon";
      listenAddress = mkOption {
        type = types.str;
        default = ":443";
      };
      # convert to comma delim. list
      bootstrapDNSNames = mkOption {
        type = types.listOf types.str;
        default = null;
      };
      # config file ?
      # only if listen port is 443?
      certDir = mkOption {
        type = types.path;
        default = "/var/tailscale/derp/certs";
        description = ''
          Directory to store LetsEncrypt certs, if addr's port is :443
        '';
      };
      # default should be 'derp' + fqdn
      hostname = mkOption {
        type = types.str;
        description = ''
          LetsEncrypt host name, if addr's port is :443
        '';
      };
      # log collection?
      meshPSKFile = mkOption {
        type = types.path;
        default = null;
        description = ''
          If non-empty, path to file containing the mesh pre-shared key file. It should contain some hex string; whitespace is trimmed.
        '';
      };
      meshServers = mkOption {
        type = types.listOf types.str;
        description = ''
          Optional comma-separated list of hostnames to mesh with; the server's own hostname can be in the list
        '';
      };
      enableSTUN = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Also run a STUN server
        '';
      };
      # What is this? How?
      verifyClients = mkOption {
        type = types.bool;
        description = ''
          Verify clients to this DERP server through a local tailscaled instance.
        '';
      };
    };
  };
in {
  meta.maintainers = with maintainers; [ danderson mbaillie ];

  options.services.tailscale = {
    enable = mkEnableOption "Tailscale client daemon";

    port = mkOption {
      type = types.port;
      default = 41641;
      description = "The port to listen on for tunnel traffic (0=autoselect).";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "tailscale0";
      description = ''The interface name for tunnel traffic. Use "userspace-networking" (beta) to not use TUN.'';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.tailscale;
      defaultText = literalExpression "pkgs.tailscale";
      description = "The package to use for tailscale";
    };

    derp = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = derpCfgOptions; } ]);
      description = "Tailscale DERP server config";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ]; # for the CLI
    systemd.packages = [ cfg.package ];
    systemd.services.derper = mkIf cfg.derp.enable {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.tailscale ];
      script = ''
        ${pkgs.tailscale}/bin/derper \
          -a ${cfg.derp.listenAddress} \
          ${optionalString (cfg.derp.bootstrapDNSNames != [])
          "-bootstrap-dns-names ${concatStringsSep "," cfg.derp.bootstrapDNSNames}" } \
          -certdir ${cfg.derp.certDir} \
          -hostname ${cfg.derp.hostname} \
          ${optionalString (cfg.derp.meshPKSFile) "-mesh-psk-file-string ${cfg.derp.meshPKSFile}"} \
          ${optionalString (cfg.derp.meshServers != []) "-mesh-with ${concatStringSep "," cfg.derp.meshServers}"} \
          ${optionalString cfg.derp.stun "-stun"} \
          ${optionalString cfg.derp.verifyClients "-verify-clients"}
      '';
    };
    systemd.services.tailscaled = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.openresolv pkgs.procps ];
      serviceConfig.Environment = [
        "PORT=${toString cfg.port}"
        ''"FLAGS=--tun ${lib.escapeShellArg cfg.interfaceName}"''
      ];
    };
  };
}
