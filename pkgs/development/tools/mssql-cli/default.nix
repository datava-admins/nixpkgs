{ lib
, python3
, coreutils
, fetchFromGitHub
, azuredatastudio
}:

let
  SQLTOOLS = "${azuredatastudio}/azuredatastudio/resources/app/extensions/mssql/sqltoolsservice/Linux/3.0.0-release.215/";
in
python3.pkgs.buildPythonApplication rec {
  pname = "mssql-cli";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "dbcli";
    repo = pname;
    rev = "b874d0aa09fb1e379100c8ad1409d38c408fe341";
    hash = "sha256-vHVaHreZpP5y45QYWH0gxgO2ch9bZtAZB2dGWb9Kpeo=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace "click >= 4.1,<7.1" "click >= 4.1,<8.2" \
      --replace "'mssql-cli.bat'," ""
    patchShebangs mssql-cli
    substituteInPlace mssql-cli \
      --replace "python " "${python3}/bin/python "
  '';
  propagatedBuildInputs = with python3.pkgs; [
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
    wrapPython
  ];

  preCheck = ''
    rm pytest.ini
  '';

  postInstall = ''
    wrapProgram $out/bin/mssql-cli --set PYTHONPATH $PYTHONPATH --set MSSQLTOOLSSERVICE_PATH ${SQLTOOLS} --prefix PATH : ${lib.makeBinPath [ python3 coreutils ]}
  '';
  checkInputs = with python3.pkgs; [
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
    maintainers = [ maintainers.princemachiavelli ];
    platforms = [ "x86_64-linux" ];
  };

}
