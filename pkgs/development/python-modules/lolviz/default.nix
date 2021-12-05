{ lib, fetchPypi, buildPythonPackage, graphviz}:

buildPythonPackage rec {
  pname = "lolviz";
  version = "1.4.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-M2RR5JDrvheOgLjP2qkzmbdfW+c+ICAoJ+f6dc+n1Eo=";
  };

  # Upstream doesn't run tests from setup.py
  doCheck = false;
  propagatedBuildInputs = [ graphviz ];

  meta = with lib; {
    description = "Data structure visualization tool";
    homepage = "https://github.com/parrt/lolviz";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}
