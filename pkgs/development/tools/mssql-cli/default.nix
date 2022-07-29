{ lib
, python3Packages
, fetchFromGitHub
}:

python3Packages.buildPythonApplication rec {
  pname = "mssql-cli";
  version = "1.09";

  src = fetchFromGitHub {
    owner = "dbcli";
    repo = pname;
    rev = "0f97c567a1ec63edf3a3d19fe054b0b1e3fe7c61";
    hash = "sha256-EKLvxLnQqhV2hGNBHe4ryzcHEo4p38QKsWZZ3hrgOsk=";
  }; 
  
  postPatch = ''
    substituteInPlace setup.py \
      --replace "click >= 4.1,<7.1" "click >= 4.1,<8.2" \
      --replace "'mssql-cli.bat'," ""
  '';
  propagatedBuildInputs = with python3Packages; [
    applicationinsights
    click
    cli-helpers
    setuptools
    configobj
    future
    humanize
    polib
    prompt-toolkit
    pygments
    sqlparse
  ];

  preCheck = ''
    rm pytest.ini
  '';

  checkInputs = with python3Packages; [
    pytestCheckHook
  ];

  disabledTestPaths = [
    "tests/"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Interactive command line query tool for SQL Server";
    homepage = "https://github.com/dbcli/mssql-cli";
    license = licenses.bsd3;
  };
}
