{ lib, stdenv, fetchFromGitHub, cmake, help2man }:

stdenv.mkDerivation rec {
  pname = "katran";
  version = "";

  src = fetchFromGitHub {
    owner = "";
    repo = "";
    rev = version;
    sha256 = "";
  };

  cmakeFlags = [ "-DGENERATE_SRS_SECRET=OFF" "-DINIT_FLAVOR=systemd" ];

  preConfigure = ''
    sed -i "s,\"/etc\",\"$out/etc\",g" CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake help2man ];

  meta = with lib; {
    homepage = "";
    description = "";
    license = licenses.gpl2;
    platforms = platforms.all;
    maintainers = with maintainers; [ ];
  };
}
