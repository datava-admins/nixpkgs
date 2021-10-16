{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "headscale";
  version = "0.10.2";

  src = fetchFromGitHub {
    owner = "juanfont";
    repo = "headscale";
    rev = "v${version}";
    sha256 = "sha256-zPZsOGGE3jljIDv6egNZm2bPgmUqQNhN7tZOHWHJl64=";
  };

  vendorSha256 = "sha256-t7S1jE76AFFIePrFtvrIQcId7hLeNIAm/eA9AVoFy5E=";

  # Ldflags are same as build target in the project's Makefile
  # https://github.com/juanfont/headscale/blob/main/Makefile
  ldflags = [ "-s" "-w" "-X main.version=v${version}" ];

  meta = with lib; {
    description = "An implementation of the Tailscale coordination server";
    homepage = "https://github.com/juanfont/headscale";
    license = licenses.bsd3;
    maintainers = with maintainers; [ nkje ];
  };
}
