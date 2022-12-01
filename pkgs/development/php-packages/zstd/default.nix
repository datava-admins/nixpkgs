{ buildPecl, lib, pkg-config, zstd }:

buildPecl {
  pname = "zstd";

  version = "0.12.0";
  sha256 = "sha256-u2jBdehzN6XYClE3HK53428Wdx+RhNPvrtwRPUoplWQ=";

  configureFlags = [ "--with-libzstd" ];
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ zstd ];

  meta = with lib; {
    description = "Zstd bindings for PHP.";
    license = licenses.mit;
    homepage = "https://pecl.php.net/package/zstd";
    maintainers = teams.php.members;
  };
}
