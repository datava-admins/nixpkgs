{
  buildPecl,
  mkDerivation,
  lib,
  php,
  fetchurl,
  pam,
  libxml2,
  stdenv,
  autoPatchelfHook,
  libkrb5
}:

let
  db2-odbc-cli = mkDerivation {
    pname = "db2-odbc-cli";
    version = "11.5.6";

    dontConfigure = true;
    dontBuild = true;
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ pam libxml2 stdenv.cc.cc libkrb5 ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R * $out/
      runHook postInstall
    '';
    src = fetchurl {
      url = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz";
      sha256 = "sha256-Cwx/qarZVEAkyvxyvNRP9wTcfsWUMc5/IZvx2ExYu7M=";
    };
  };
in
  buildPecl {
  pname = "PDO_IBM";

  version = "1.5.0";
  sha256 = "sha256-GrAnl1tlyHGyrN/qWIJI6VZ3QauARMSX5WrUVpz8bJk=";

  internalDeps = [  php.extensions.pdo ];
  #nativeBuildInputs = [ libxml2 ];
  #buildInputs = [ pam libxml2 stdenv.cc.cc ];

  configureFlags = [
    "--with-pdo-ibm=${db2-odbc-cli}"
  ];
  meta = with lib; {
    description = "PDO driver for IBM databases";
    license = licenses.unfree;
    homepage = "https://pecl.php.net/package/PDO_IBM";
    maintainers = teams.php.members;
  };
}
