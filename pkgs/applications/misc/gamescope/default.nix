{ stdenv
, libseat
, xwayland
, lib
, xcbutil
, xcbutilerrors
, xcbutilwm
, xcbproto
, pixman
, xcbutilrenderutil
, libinput
, libXi
#, wlroots
, meson
, ninja
, fetchFromGitHub
, pkg-config
, makeWrapper
, xorgproto
, libX11
, cmake
, libXdamage
, libXcomposite
, libXrender
, libXext
, libXxf86vm
, libXtst
, libXres
, libdrm
, vulkan-headers
, vulkan-tools
, mesa
, vulkan-loader
, wayland
, wayland-protocols
, libxkbcommon
, libcap
, SDL2
, pipewire
, stb
, libGLU
, libGL
, glslang
}:


stdenv.mkDerivation rec {
  pname = "gamescope";
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "Princemachiavelli";
    deepClone = true;
    repo = "gamescope";
    rev = "c8193227ed7928ff1a8645681cf1ea1baa8dbf55";
    sha256 = "sha256-0/cniPT4kJw2vaKlG8iJ/mxQENXHS+UsYF6wvg9CZzU=";
  };


  libliftoff = fetchFromGitHub {
    owner = "emersion";
    repo = pname;
    rev = "70eca070b644546b5463e62aadfa9e49392f2271";
    sha256 = "sha256-yMSaHNQQ4NObB7I3wtNI5HNRS/yUU2WyznXKtbdTZ1U=";
  };

  wlroots-wrap = fetchFromGitHub {
    owner = "swaywm";
    repo = "wlroots";
    rev = "ce66244fd2fefed00094d0f1e46fff8e8660c184";
    sha256 = "sha256-MtDpWxK29e67gOgPej2IwP6Qf8Ys9X3FFtvdoICDO9I=";
  };

  buildInputs = [
    xorgproto
    libX11
    libXdamage
    libXcomposite
    libXrender
    libXext
    libXxf86vm
    libXtst
    libXres
    libdrm
    vulkan-headers
    vulkan-tools
    mesa
    vulkan-loader
    wayland
    wayland-protocols
    libxkbcommon
    libcap
    SDL2
    pipewire
    stb
    libGL
    libGLU
    glslang
    #wlroots
  ];

  nativeBuildInputs = [
    libXi
    xcbutilerrors
    xcbutil
    xcbutilwm
    xcbproto
    xwayland
    libseat
    pkg-config
    makeWrapper
    meson
    cmake
    ninja
    vulkan-headers
    vulkan-tools
    stb
    #wlroots
    libinput
    pixman
    xcbutilrenderutil
  ];

  stbMeson = ''
project('stb', 'c', version : '0.1.0', license : 'MIT')

stb_dep = declare_dependency(
  include_directories : include_directories('.'),
  version             : meson.project_version()
)

meson.override_dependency('stb', stb_dep)
  '';

  unpackPhase = ''
    cp -r ${src}/* .
    chmod -R u+w -- subprojects
    mkdir -p subprojects/stb
    cp -r ${stb.src}/* subprojects/stb/
    cp -r ${wlroots-wrap}/* subprojects/wlroots/
    cp -r ${libliftoff}/* subprojects/libliftoff/
    #cp subprojects/packagefiles/stb/meson.build  subprojects/stb/meson.build
    #rm subprojects/stb.wrap
    #rm -rf subprojects/packagefiles
    chmod -R u+w -- subprojects
  '';

#  buildPhase = ''
#    meson build/
#    #ninja -C build/
#  '';
  meta = with lib; {
    description = "low latency micro-compositor";
    homepage = "https://github.com/Plagman/gamescope";
    license = licenses.bsd2;
    maintainers = with maintainers; [ princemachiavelli ];
    platforms = with lib.platforms; linux;
  };
}
