{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.headscale;
  dnsConfig = types.submodule {
    options = {
      nameservers = mkOption {
        type = types.listOf types.str;
        default = [ "1.1.1.1" ];
      };
      domains = mkOption {
        type = types.listOf types.str;
      };
      magic_dns = mkOption {
        type = types.bool;
        default = true;
      };
      base_domain = mkOption {
        type = types.str;
        default = config.networking.domain;
      };
    };
  };
  configFile = types.submodule {
    options = {
      server_url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:8080";
      };
      listen_addr = mkOption {
        type = types.str;
        default = "0.0.0.0:8080";
      };
      private_key_path = mkOption {
        type = types.str;
        default = "private.key";
      };
      derp_map_path = mkOption {
        type = types.str;
        default = "derp.yaml";
      };
      ephemeral_node_inactivity_timeout = mkOption {
        type  = types.str;
        default = "30m";
      };
      db_type = mkOption {
        type = types.enum;
        default = "sqlite3";
      };
      db_path = mkOption {
        type = types.str;
        default = "db.sqlite";
      };
      acme_url = mkOption {
        type = types.str;
        default = "https://acme-v02.api.letsencrypt.org/directory";
      };
      acme_email = mkOption {
        type = types.str;
        default = config.security.acme.email;
      };
      tls_letsencrypt_hostname = mkOption {
        type = types.str;
        default = config.networking.fqdn;
      };
      tls_letsencrypt_listen = mkOption {
        type = types.enum;
        default = "http";
      };
      tls_letsencrypt_cache_dir = mkOption {
        type = types.str;
        default = ".cache";
      };
      tls_letsencrypt_challenge_type = mkOption {
        type = types.enum;
        default = "HTTP-01";
      };
      tls_cert_path = mkOption {
        type = types.path;
        default = "";
      };
      tls_key_path = mkOption {
        type = types.path;
        default = "";
      };
      acl_policy_path = mkOption {
        type = types.path;
        default = "";
      };
      dns_config = mkOption {
        type = dnsConfig;
      };

    };
  }; 

in {
  meta.maintainers = with maintainers; [ danderson mbaillie ];

  options.services.tailscale = {
    enable = mkEnableOption "Tailscale client daemon";
    config = mkOption {
      default = {};
      type = configFile;
    };

    # SQLite or Postgresql?
    #  Wireguard public & private key
    # list of namespace(s)
    # map of machine key to namespaces
    # # OR use authkey in secrets?
    # # which is more consistent?
    # # I think having a very long duration auth key stored in the secrets would be OK
    # DERP config and server!!!
    # Policy ACLs
    # Template SQLite DB?
    # other config options 

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
      default = pkgs.headscale;
      defaultText = literalExpression "pkgs.tailscale";
      description = "The package to use for tailscale";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."headscale/config.json" = builtins.toJSON cfg.config;
    environment.systemPackages = [ cfg.package ]; # for the CLI
    systemd.packages = [ cfg.package ];
    systemd.services.headscaled = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.headscale}/bin/headscale serve
        '';
     };
    };
  };
}
