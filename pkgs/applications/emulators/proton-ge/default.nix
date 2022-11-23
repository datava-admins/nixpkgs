{ lib
, fetchFromGitHub
# Depends
, attr
, fontconfig
, lcms2
, libxml2
, xorg.libXcursor
, xorg.libxrandr
, xorg.libXdamage
, xorg.libXi 
, gettext
, freetype # freetype2
, libGLU # glu
, xorg.libSM
#, gcc-libs ?
, libpcap
, lzo
, libxkbcommon
, faudio
, libvpx
, SDL2
, desktop-file-utils
, python39 # pypi?
, steamPackages.steam-runtime
, cabextract
# Makedepends
, stdenv # I assume
, autoconf
, bison
, perl
, fontforge
, flex
, # mingw-w64-gcc
# lld or part of stdenv?
, nasm
, meson
, cmake
# python virtualenv and pip?
, glslang
, vulkan-headers
# clang - part of stdenv?
, giflib
, libpng
, gnutls
, xorg.libXinerama
, xorg.libXmu
, xorg.libXxf86vm
# libldap ?
, mpg123
, openal
, v4l-utils # lib output?
, alsa-lib
, xorg.libxcomposite
, mesa
, libGL # mesa-libgl?
# opencl-icd-loader ?
, libxslt
, libpulseaudio # libpulse ?
, libva
, gtk3
, gst_all_1.gst-plugins-base
# vulkan-icd-loader
# SDL2 again
, rustc # rust ? part of stdenv?
, libgphoto2
, gsm
, opencl-headers
# Optional lots of duplicates
, giflib
, libpng
, # libldap again?
, alsa-plugins
, libjpeg
, dosbox
# AUR package installs from PIP
, python39Packages.afdko
, python39Packages.pefile
, python39Packages.meson # why?
}:

mkDerivation rec {
  pname = "proton-ge";
  version = "7.18";

  src = fetchFromGitHub {
    owner = "gloriouseggroll";
    repo = "proton-ge-custom";
    rev = "GE-Proton${version}";
    sha256 = "";
  };

  nativeBuildInputs = [ attr ];

  buildInputs = [ ];

  buildPhase = ''
  '';

  installPhase = ''
  '';


  meta = with lib; {
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    license = licenses.custom;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
