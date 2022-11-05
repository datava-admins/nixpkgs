{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "vuls";
  version = "0.21.0";
  rev = "v${version}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "future-architect";
    repo = "vuls";
    sha256 = "sha256-B8LszLzx7v6AbC8l2unGMeB9rMofozm3Tmbc4s3PeJw=";
  };
  vendorSha256 = "sha256-n37fs09qCeFA6cciHW0sB+JqllgXp9Q3IkZiAzRE6zo=";

  meta = with lib; {
    description = "Vulnerability scanner for Linux/FreeBSD, agent-less, written in Go";
    homepage = "https://github.com/future-architect/vuls";
    license = licenses.gpl3;
  };
}
