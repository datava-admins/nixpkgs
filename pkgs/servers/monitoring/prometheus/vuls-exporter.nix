{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "vuls-exporter";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "PrinceMachiavelli";
    repo = "prometheus-vuls-exporter";
    rev = "ebd18bd3be80aadf95be0e9e4f8eba15fd200234";
    sha256 = "sha256-WtzRzp+do0OtIskKxJlBr1KP5eU3/OxBcKbyCdqD4Tg=";
  } + "/src";
  vendorSha256 = "sha256-rFGpnUsQLil+eJKBn2F7ym33jtZ3Vlh8LETo4xyAcvY=";
}
