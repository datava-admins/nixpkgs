{ config, lib, pkgs, ... }:

with lib;

let
  derpFormat = pkgs.formats.yaml {};
  cfg = config.services.headscale;
  derpConfig = types.submodule {
    options = {
      regions = mkOption {
        type = types.attrsOf (types.submodule {
        options = {
          regionid = mkOption {
            type = types.int;
          };
          regioncode = mkOption {
            type = types.str;
          };
          regionname = mkOption {
            type = types.str;
          };
          nodes = mkOption {
            default = [];
            type = types.listOf (types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                  };
                  regionid = mkOption {
                    type = types.int;
                  };
                  hostname = mkOption {
                    type = types.str;
                  };
                  ipv4 = mkOption {
                    type = types.str;
                  };
                  ipv6 = mkOption {
                    type = types.nullOr types.str;
                  };
                  stunport = mkOption {
                    type = types.int;
                    default = 0;
                  };
                  stunonly = mkOption {
                    type = types.bool;
                    default = false;
                  };
                  derptestport = mkOption {
                    type = types.port;
                    default = 0;
                  };
                };
            });
           };
          };
        });
      };
    };
  };
  dnsConfig = types.submodule {
    options = {
      nameservers = mkOption {
        type = types.listOf types.str;
        default = [ "1.1.1.1" ];
      };
      domains = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      magic_dns = mkOption {
        type = types.bool;
        default = true;
      };
      base_domain = mkOption {
        type = types.str;
        default = "";
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
        default = "${config.services.headscale.dataDir}/private.key";
      };
      derp_map_path = mkOption {
        type = types.path;
        default = (derpFormat.generate "derp.yaml" cfg.derp);
      };
      ephemeral_node_inactivity_timeout = mkOption {
        type  = types.str;
        default = "30m";
      };
      db_type = mkOption {
        type = types.enum [ "sqlite3" "postgres" ];
        default = "sqlite3";
      };
      db_path = mkOption {
        type = types.str;
        default = "${config.services.headscale.dataDir}/db.sqlite";
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
        default = "";
      };
      tls_letsencrypt_listen = mkOption {
        type = types.enum [ "http" "https" ];
        default = "http";
      };
      tls_letsencrypt_cache_dir = mkOption {
        type = types.str;
        default = "${config.services.headscale.dataDir}/.cache";
      };
      tls_letsencrypt_challenge_type = mkOption {
        type = types.enum [ "HTTP-01" "TLS-ALPN-01" ];
        default = "HTTP-01";
      };
      tls_cert_path = mkOption {
        type = types.str;
        default = "";
      };
      tls_key_path = mkOption {
        type = types.str;
        default = "";
      };
      acl_policy_path = mkOption {
        type = types.str;
        default = "";
      };
      dns_config = mkOption {
        type = dnsConfig;
        default = {};
      };

    };
  }; 

in {
  meta.maintainers = with maintainers; [ danderson mbaillie ];

  options.services.headscale = {
    enable = mkEnableOption "Tailscale client daemon";
    dataDir = mkOption {
      default = "/var/lib/headscale";
      type = types.path;
    };
    config = mkOption {
      default = {};
      type = configFile;
    };
    derp = mkOption {
      default = {};
      type = derpConfig;
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

    package = mkOption {
      type = types.package;
      default = pkgs.headscale;
      defaultText = literalExpression "pkgs.tailscale";
      description = "The package to use for tailscale";
    };
    user = mkOption {
      type = types.str;
      default = "headscale";
      description = ''
        User account under which headscale runs.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "headscale";
      description = ''
        Group under which headscale runs.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.groups = mkIf (cfg.group == "headscale") {
      headscale = {};
    };

    users.users = mkIf (cfg.user == "headscale") {
      headscale = {
        group = cfg.group;
        #shell = pkgs.bashInteractive;
        home = cfg.dataDir;
        description = "headscale daemon user";
        isSystemUser = true;
      };
    };
    environment.etc."headscale/config.json" = {
      user = cfg.user;
      group = cfg.group;
      text = (builtins.toJSON cfg.config);
    };
#    environment.etc."headscale/derp.json" = mkIf (cfg.derp != null) {
#      user = cfg.user;
#      group = cfg.group;
#      text = (derpFormat.generate "derp.json" cfg.derp);
#    };
    environment.systemPackages = [ cfg.package ]; # for the CLI
    systemd.packages = [ cfg.package ];
    systemd.services.headscaled = {
      ## Should check if private.key exists
      ## Should touch db.sqlite if it does not exist
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = ''
          ${pkgs.headscale}/bin/headscale serve
        '';
     };
    };
    systemd.tmpfiles.rules = [ "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} -" ];
  };
}
