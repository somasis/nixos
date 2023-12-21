{ lib
, go
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "firefox-sync-client";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "Mikescher";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Zl+7JkOcX0R15+s1jZPtoIPPW8yWR2VsgkHyj7DW/F4=";
  };

  vendorHash = "sha256-Gb+4fxMBgvPB9Ki7zIwscY9l2kJ+tuE1Mc3W08YTfk8=";

  # requires network
  doCheck = false;

  meta = with lib; rec {
    inherit (src.meta) homepage;

    description = "Interact with Firefox Sync from the command line";
    changelog = "${homepage}/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ somasis ];
    mainProgram = "ffsclient";
  };
}
