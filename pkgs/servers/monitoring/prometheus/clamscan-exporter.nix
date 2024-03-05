{ lib, buildGoModule, fetchFromGitHub, nixosTests }:

buildGoModule rec {
  pname = "prometheus-clamscan-exporter";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "PrinceMachiavelli";
    repo = "clamscan-exporter";
    rev = "2bb5fc42c8a1d6d5374e0397e2c8d9129fed78dc";
    sha256 = "sha256-fVLK98x0JLs+ZCoGcVC3j9E5IOwy89ucT8c6gL+wtnI=";
  };
  #vendorSha256 = "sha256-M9Oqp14kUVC5+pMOJhHpMfr6M0g+YKxhZA9laU6qNOQ=";
  vendorSha256 = "sha256-08h0aTfsxMmXAIfa+opUgKtehIDBqu54Sj0A1g3EJqM=";
  
  passthru.tests = { inherit (nixosTests.prometheus-exporters) clamscan; };
}
