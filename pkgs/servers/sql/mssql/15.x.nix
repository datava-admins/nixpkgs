{lib, stdenv, fetchurl, pkgs,
autoPatchelfHook,
dpkg,
e2fsprogs,
krb5,
libuuid,
numactl,
openldap,
linux-pam,
systemd,
xz,
sssd,
bash
}:
with lib;
let
  packageMSSQL = {year, version, sha256, ...}@args:
    stdenv.mkDerivation ({
      pname = "mssql-server-${year}";
      src =
        fetchurl {
          url = "https://packages.microsoft.com/ubuntu/20.04/mssql-server-${year}/pool/main/m/mssql-server/mssql-server_${version}_amd64.deb";
          inherit sha256;
        };
        unpackPhase = ''
          mkdir -p $TMP/ $out/
          dpkg -x $src $TMP
        '';
        installPhase = ''
          cp -R $TMP/usr/* $out/
          cp -R $TMP/opt/mssql/* $out/
          substituteInPlace $out/bin/mssql-conf --replace '/bin/bash' '${bash}/bin/bash'
        '';
        meta = {
          description = "Microsoft SQL Server";
          license = licenses.unfree;
        } // (args.meta or {});

        nativeBuildInputs = [
          autoPatchelfHook
        ];

        #runtimeDependencies = [ (lib.getLib systemd) (lib.getLib numactl) pkgs.linux-pam ];
        dontBuild = true;
        buildInputs = [
          dpkg
          e2fsprogs
          linux-pam
          numactl
          xz
          krb5
          libuuid
          systemd
          #pam
          openldap
          sssd
        ];

      } // removeAttrs args [ "meta" ]);
in rec {
  mssql2019 = packageMSSQL {
    year = "2019";
    version = "15.0.4123.1-5";
    homepage = "https://docs.microsoft.com/en-us/sql/sql-server/?view=sql-server-ver15";
    sha256 = "sha256-APSIUpOqSrw2jlwrTDuRgAg1nUO0bVDx1Rbj6S4+Ajo=";
  };
}
