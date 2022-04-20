{
  buildPecl,
  lib,
  php,
  fetchurl,
  db2-odbc-cli
}:

buildPecl rec {
  name = "PDO_IBM";
  pname = "pdo_ibm";
  version = "1.5.0";

  src = fetchurl {
    url = "http://pecl.php.net/get/${name}-${version}.tgz";
    sha256 = "sha256-GrAnl1tlyHGyrN/qWIJI6VZ3QauARMSX5WrUVpz8bJk=";
  };

  internalDeps = [  php.extensions.pdo ];
  #nativeBuildInputs = [ libxml2 ];
  #buildInputs = [ pam libxml2 stdenv.cc.cc ];

  configureFlags = [
    "--with-pdo-ibm=${db2-odbc-cli}"
  ];
  meta = with lib; {
    description = "PDO driver for IBM databases";
    license = licenses.unfree;
    homepage = "https://pecl.php.net/package/PDO_IBM";
    maintainers = teams.php.members;
  };
}
