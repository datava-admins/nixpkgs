{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "gotestwaf";
  version = "cb5b7df12facc7c4e5d4ad886901fb1f2cd37189";

  src = fetchFromGitHub {
    owner = "wallarm";
    repo = pname;
    rev = version;
    sha256 = "sha256-gw8TbCtOZwFvs/Rv7psZL5WBap2qs25Y/D4k8o9mREk=";
  };

  patches = [ ./blockstatuscodes_first.patch ];

  vendorSha256 = null;
  doCheck = false;

  postFixup = ''
    # Rename binary
    mv $out/bin/cmd $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Tool for API and OWASP attack simulation";
    homepage = "https://github.com/wallarm/gotestwaf";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
