{
  lib,
  php,
  fetchurl,
  pam,
  libxml2,
  stdenv,
  autoPatchelfHook,
  libkrb5
}:

stdenv.mkDerivation {
  pname = "db2-odbc-cli";
  version = "11.5.6";
  
  src = fetchurl {
    url = "https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz";
    sha256 = "sha256-Cwx/qarZVEAkyvxyvNRP9wTcfsWUMc5/IZvx2ExYu7M=";
  };

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

  meta = with lib; {
    description = "IBM Data Server Driver for ODBC and CLI";
    license = licenses.unfree;
    homepage = "https://www.ibm.com/support/pages/db2-odbc-cli-driver-download-and-installation-information";
    maintainers = mantainers.princemachiavelli;
  };
}
