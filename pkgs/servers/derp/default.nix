{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "derp";
  version = "1.14.6";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "v${version}";
    sha256 = "sha256-Mvt2j1AAkENT0krl2PbtzM7HXgs4miYXDchFm+8cspY=";
  };

  CGO_ENABLED = 0;
  doCheck = false;
  vendorSha256 = "sha256-v/jcNKcjE/c4DuxwfCy09xFTDk3yysP4tBmVW69FI4o=";
  subPackages = [ "derp" ];
  tags = [ "xversion" ];
  ldflags = [ "-X tailscale.com/version.Long=${version}" "-X tailscale.com/version.Short=${version}" ];

  meta = with lib; {
    description = "DERP";
  };
}
