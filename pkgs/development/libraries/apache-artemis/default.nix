{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "apache-artemis";
  version = "2.27.1";

  src = fetchurl {
    hash = "sha256-8MElmDIbuXm/b/e2m15mziMMP5PO2WkLTu0Rwl+K8uI=";
    url = "mirror://apache/activemq/activemq-artemis/${version}/${pname}-${version}-bin.tar.gz";
  };

  installPhase = ''
    mkdir -p $out
    mv * $out/
    for j in `find $out/lib -name "*.jar"`; do
      cp="''${cp:+"$cp:"}$j";
    done
    echo "CLASSPATH=$cp" > $out/lib/classpath.env
  '';

  meta = {
    homepage = "https://activemq.apache.org/";
    description = "Messaging and Integration Patterns server written in Java";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };

}
