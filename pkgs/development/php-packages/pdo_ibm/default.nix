{ stdenv, buildPecl, mkDerivation, fetchurl, lib, autoPatchelfHook, libkrb5, linux-pam, libxml2, php }:
let
  db2-odbc-cli = mkDerivation {
    pname = "db2-odbc-cli";
    version = "11.5.6.0";
    dontConfigure = true;

    src = fetchurl {
      url = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz";
      sha256 = "1cxvb16diwcv45zwwcclqmzdq17p9zabqwpwr8j40m6rmalpy30b";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [ libkrb5 stdenv.cc.cc.lib linux-pam libxml2 ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r * "$out"
      runHook postInstall
    '';

    meta = with lib; {
      description = "IBM Data Server Driver for ODBC and CLI";
      homepage = "https://www.ibm.com/support/pages/db2-odbc-cli-driver-download-and-installation-information";
      license = licenses.unfree; # Only partially redistributable
      maintainers = [ maintainers.princemachiavelli ];
      platforms = [ "x86_64-linux" ];
    };

  };
in
buildPecl rec {
  pname = "pdo_ibm";
  name = "PDO_IBM";
  version = "1.5.0";

  src = fetchurl {
    url = "http://pecl.php.net/get/${name}-${version}.tgz";
    sha256 = "sha256-GrAnl1tlyHGyrN/qWIJI6VZ3QauARMSX5WrUVpz8bJk=";
  };

  internalDeps = [ php.extensions.pdo ];

  configureFlags = [
    "--with-pdo-ibm=${db2-odbc-cli}"
  ];

  meta = with lib; {
    description = "PDO driver for IBM databases";
    homepage = "https://pecl.php.net/package/pdo_ibm";
    license = licenses.asl20;
    maintainers = [ maintainers.princemachiavelli ];
    platforms = [ "x86_64-linux" ];
  };
}
