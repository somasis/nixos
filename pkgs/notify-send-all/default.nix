{ lib
, fetchFromGitHub

, bash
, coreutils
, gnused
, libnotify
, sudo
, which

, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "notify-send-all";
  version = "unstable-2023-06-08";

  src = fetchFromGitHub {
    owner = "hackerb9";
    repo = "notify-send-all";
    rev = "c7da5abd544b87512f7bed33ed73ebba3adc6dc4";
    hash = "sha256-+Y19RaGLQaVmToS3f4z2luBdCxLWo8hoCklMI3BRx44=";
  };

  runtimeInputs = [
    bash
    coreutils
    gnused
    libnotify
    sudo
    which
  ];

  buildPhase = ''
    sed -Ei \
        -e '/^PATH=/d' \
        -e 's|/bin/test|"$(which test)"|' \
        ./notify-send-all
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -m 0755 notify-send-all $out/bin/notify-send-all
    ln -s notify-send-all $out/bin/notify-send-to
  '';

  meta = with lib; {
    inherit (src) homepage;
    description = "Send notifications to all logged in users";
    licenses = with licenses; [ cc0 ];
    maintainers = with maintainers; [ somasis ];
  };
}
