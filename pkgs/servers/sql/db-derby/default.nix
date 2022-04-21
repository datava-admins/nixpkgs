{ lib, stdenv, fetchurl, jdk17_headless, makeWrapper }:

let
  jre = jdk17_headless; 
in
stdenv.mkDerivation rec {
  pname = "db-derby";
  version = "10.15.2.0";

  src = fetchurl {
    url = "https://dlcdn.apache.org//db/derby/${pname}-${version}/${pname}-${version}-bin.tar.gz";
    sha256 = "sha256-rFEkai2e73DOzWViB1swqplT9iLL0s01Ubw9I53G8Co=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre ];


  installPhase = ''
    mkdir -p $out
    cp -R * $out/
    mkdir -p $out/bin
    #mv $out/${pname}-${version}-bin $out/bin/${pname}
    for p in $out/bin\/* ; do
      wrapProgram $p \
        --set JAVA_HOME "${jre}" \
        --set DERBY_HOME "$out"
    done
    chmod +x $out/bin\/*
  '';

  meta = with lib; {
    description = "Open source relational database implemented entirely in Java";
    homepage = "https://db.apache.org/derby";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = [ maintainers.princemachivaelli ];
  };
}
      #--set CLASSPATH="$DERBY_INSTALL/lib/derby.jar:$DERBY_INSTALL/lib/derbytools.jar:$DERBY_INSTALL/lib/derbyoptionaltools.jar:$DERBY_INSTALL/lib/derbyshared.jar:."
