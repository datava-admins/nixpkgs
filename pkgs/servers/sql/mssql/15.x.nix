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
bash,
gcc-unwrapped
}:
with lib;
let
  debPlatform =
    if stdenv.hostPlatform.system == "x86_64-linux" then "amd64"
    else if stdenv.hostPlatform.system == "i686-linux" then "i386"
         else throw "Unsupported system: ${stdenv.hostPlatform.system}";
  packageMSSQL = {year, version, sha256, ...}@args:
    stdenv.mkDerivation ({
      pname = "mssql-server-${year}";
      src =
        fetchurl {
          url = "https://packages.microsoft.com/ubuntu/20.04/mssql-server-${year}/pool/main/m/mssql-server/mssql-server_${version}_${debPlatform}.deb";
          inherit sha256;
        };
        unpackPhase = ''
          mkdir -p $TMP/ $out/
          dpkg -x $src $TMP
        '';
        installPhase = ''
          cp -R $TMP/usr/* $out/
          cp -R $TMP/opt/mssql/* $out/
          substituteInPlace $out/bin/mssql-conf --replace /bin/bash "${bash}/bin/bash"
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
          gcc-unwrapped.lib
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
    version = "15.0.4198.2-10";
    homepage = "https://docs.microsoft.com/en-us/sql/sql-server/?view=sql-server-ver15";
    sha256 = "sha256-AllpkNqiEShtD30ipKDQPFrkxfoUDsFw4rzoz5qfkJQ=";
  };
}
