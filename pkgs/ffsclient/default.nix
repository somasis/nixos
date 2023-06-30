{ lib
, go
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "firefox-sync-client";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "Mikescher";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-9CxXVSPs5BPlt/g50soatIQdjdydgZLkrwgAliH7/Zk=";
  };

  vendorHash = "sha256-rR9uQ23llvxVD3+GkfyZJh268G8ugNkrHRC/9kmmpdU=";

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
