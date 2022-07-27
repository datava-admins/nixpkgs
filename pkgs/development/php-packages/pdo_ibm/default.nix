{ stdenv, buildPecl, mkDerivation, fetchurl, lib, autoPatchelfHook, libkrb5, linux-pam, libxml2, php }:
let
  db2-odbc-cli = mkDerivation {
    pname = "db2-odbc-cli";
    version = "11.5.6.0";
    dontConfigure = true;

    src = fetchurl {
      url = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz";
      sha256 = "sha256-Cwx/qarZVEAkyvxyvNRP9wTcfsWUMc5/IZvx2ExYu7M=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [ libkrb5 stdenv.cc.cc.lib linux-pam libxml2 ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/
      cp -R * $out/
      runHook postInstall
    '';
};
in
buildPecl {
  pname = "PDO_IBM";

  version = "1.5.0";
  sha256 = "sha256-GrAnl1tlyHGyrN/qWIJI6VZ3QauARMSX5WrUVpz8bJk=";

  internalDeps = [ php.extensions.pdo ];

  configureFlags = [
    "--with-pdo-ibm=${db2-odbc-cli}"
  ];

  meta = with lib; {
    description = "PDO driver for IBM databases";
    license = licenses.asl20;
    homepage = "https://pecl.php.net/package/pdo_ibm";
  };
}
