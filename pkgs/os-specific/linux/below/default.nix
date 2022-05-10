{ lib, rustPlatform, fetchCrate,
fetchFromGitHub,
pkg-config,
libbpf,
libelf,
zlib,
llvmPackages,
ncurses5,
rustfmt
}:

rustPlatform.buildRustPackage rec {
  pname = "below";
  version = "0.5.0";

  src = fetchCrate {
    inherit version pname;
    sha256 = "sha256-Km+rfIFdFXSvX5evZ76yJoDIaD3iSdjN+GHiuqWzaNc=";
  };

  nativeBuildInputs = [
    pkg-config
    llvmPackages.clang-unwrapped
    rustfmt
  ];
  RUST_BACKTRACE = 1;

  buildInputs = [
    libelf
    zlib
    libbpf
    ncurses5
  ];

  checkFlags = [
    # Disable tests that require /sys access
    "--skip=test::record_replay_integration"
    "--skip=test::advance_forward_and_reverse"
    "--skip=test::disable_io_stat"
    "--skip=test::disable_disk_stat"
  ];
  cargoSha256 = "sha256-bwGdhRSl1qiTKRNoG9VzxigmftPpHbfWDWRGTmnRdf8=";

  meta = with lib; {
    description = "Interactive tool to view and record historical system data with cgroup2 support";
    homepage = "https://github.com/facebookincubator/below";
    license = with licenses; [ asl20 ];
  };
}
