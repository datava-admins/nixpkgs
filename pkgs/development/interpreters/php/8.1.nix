{ callPackage, ... }@_args:

let
  base = callPackage ./generic.nix (_args // {
    version = "8.1.24";
    hash = "sha256-sK5YBKmtU6fijQoyYpSV+Bb5NbEIMMcfTsFYJxhac8k=";
  });

in
base.withExtensions ({ all, ... }: with all; ([
  # Load OpenSSL first so it's openssl.cnf is loaded.
  openssl
  bcmath
  calendar
  curl
  ctype
  dom
  exif
  fileinfo
  filter
  ftp
  gd
  gettext
  gmp
  iconv
  imap
  intl
  ldap
  mbstring
  mysqli
  mysqlnd
  opcache
  pcntl
  pdo
  pdo_mysql
  pdo_odbc
  pdo_pgsql
  pdo_sqlite
  pgsql
  posix
  readline
  session
  simplexml
  sockets
  soap
  sodium
  sysvsem
  sqlite3
  tokenizer
  xmlreader
  xmlwriter
  zip
  zlib
]))
