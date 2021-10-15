{lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "openSeaChest";
  version = "21.06.21";

  src = fetchurl {
    #url = "https://github.com/Seagate/openSeaChest/archive/refs/tags/v${version}.tar.gz";
    url = "https://github.com/Seagate/openSeaChest/releases/download/v${version}/openseachest_exes_CentOS7_x86_64.tar.gz";
    sha256 = "sha256-0t4TyJUp1fb9/LedSjSTqR3keKSTzgOcETDPuhCiM7Q=";
  };


  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp * $out/bin/
  '';

  meta = with lib; {
    homepage = "https://github.com/Seagate/openSeaChest";
    description = "Seagate Disk Utilities";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
