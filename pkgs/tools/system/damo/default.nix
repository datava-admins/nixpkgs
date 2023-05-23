{
  buildPythonPackage,
  fetchPypi,
  fetchFromGitHub,
  lib
}:

buildPythonPackage rec {
  pname = "damo";
  version = "1.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-NGdifcJHHaaAupkm9CFQBByAUAOYUrDBH+vB5JtWXmo=";
  };

#  src = fetchFromGitHub {
#    owner = "awslabs";
#    repo = pname;
#    rev = "v${version}";
#    sha256 = "sha256-i/HorMTHE1clWUxeTObRArAlkeoSZXe+rRAOxLHjITM=";
#  };
  
  meta = with lib; {
    description = "User space tool for DAMON. Using this, you can monitor the data access patterns of your system or workloads and make data access-aware memory management optimizations.";
    license = licenses.gpl2;
    homepage = "https://github.com/awslabs/damo";
    platforms = platforms.linux;
  };
}
