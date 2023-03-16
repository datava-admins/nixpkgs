{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "vuls";
  version = "0.22.1";
  src = fetchFromGitHub {
    owner = "PrinceMachiavelli";
    repo = "vuls";
    rev = "7de396f2b0648a3e47a692007fca6085dc6a55b2";
    sha256 = "sha256-3Cdb9v6qgAYBuY0sFr6c4Rdx07hy/spx7iOwg+c9Q0Q=";
  };
  vendorSha256 = "sha256-zE3B1+C5Ubu2jnz8Uoeh18bAaY2KoWAYpWx0b/pChYI=";
}
