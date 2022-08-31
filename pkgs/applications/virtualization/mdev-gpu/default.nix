{ lib, fetchFromGitHub, haskellPackages, makeWrapper }:

with haskellPackages; mkDerivation rec {
  pname = "mdev-gpu";
  version = "0.1.0.0";

  src = fetchFromGitHub {
    owner = "Arc-Compute";
    repo = "Mdev-GPU";
    rev = version;
    sha256 = "sha256-Gj3MUhMaKlyZe24qgz6oaSyxc+P64Wwf/Lvw8eCVw+c=";
  };

  isExecutable = true;

  buildTools = [ ];
  executableHaskellDepends = [
    aeson
    bimap
    fixed-vector
    ioctl
    optparse-applicative
    path
    split
    yamlparse-applicative
  ];

  #prePatch = "hpack";

  #checkPhase = ''
  #  export NAPROCHE_EPROVER=${eprover}/bin/eprover
  #  dist/build/Naproche-SAD/Naproche-SAD examples/cantor.ftl.tex -t 60 --tex=on
  #'';

  #postInstall = ''
  #  wrapProgram $out/bin/Naproche-SAD \
  #    --set-default NAPROCHE_EPROVER ${eprover}/bin/eprover
  #'';

  homepage = "https://github.com/Arc-Compute/Mdev-GPU/";
  description = "Mdev-GPU enables the creation of arbitrary user-configurable Mediated Device types on existing drivers";
  maintainers = with lib.maintainers; [ ];
  license = lib.licenses.gpl2;
}
