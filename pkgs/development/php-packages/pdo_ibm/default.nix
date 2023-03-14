{ stdenv, buildPecl, mkDerivation, fetchurl, lib, autoPatchelfHook, libkrb5, linux-pam, libxml2, php, libxcrypt }:
let
  db2-odbc-cli = mkDerivation {
    pname = "db2-odbc-cli";
    version = "11.5.8.0";
    dontConfigure = true;

    src = fetchurl {
      url = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz";
      sha256 = "0z6kzc3f39msfg41rsz9pj5hgjfdy1q8wn6w92v96261vhj90xiz";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [ libkrb5 stdenv.cc.cc.lib linux-pam libxml2 libxcrypt ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/
      cp -R * $out/
      runHook postInstall
    '';
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
    platforms = [ "x86_64-linux" ];
  };
}
