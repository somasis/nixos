{ lib

, stdenv
, fetchurl

, wine
}:
stdenv.mkDerivation rec {
  pname = "flstudio";
  version = "21.2.3.4004";
  inherit wine;

  src = fetchurl {
    url = "https://demodownload.image-line.com/flstudio/flstudio_win64_${version}.exe";
    hash = "sha256-CvLr5Pbv+Ps166jj7iP93RAgXxHdLOeVNQNQREb8vhQ=";
  };

  installPhase = ''
  ''
  + ''
    # install offlinehelp
    # https://support.image-line.com/redirect/download_flofflinehelp_win
  '';

  outputs = [ "out" "dev" ];

  meta = with lib; {
    description = "A legendary digital audio workstation for Windows and macOS";
    license = licenses.unfree;
    maintainers = with maintainers; [ somasis ];
    homepage = "https://www.image-line.com/fl-studio/";
    changelog = "https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/WhatsNew.htm";
    platforms = wine.meta.platforms;  };

  passthru.updateScript = writeScript "update-flstudio" ''
    #!/usr/bin/env nix-shell
    #! nix-shell -i bash -p curl jq gnugrep minify common-updater-scripts

    set -eu -o pipefail

    json=$(
        curl -Lf \
            'https://support.image-line.com/api.php?call=get_version_info&callback=il_get_version_info' \
            | minify --type text/javascript - \
            | grep -Eo '\{.*\}'
    )

    version=$(jq -r '.prod[].pc.version' <<<"$json") || exit 1
    checksum=$(jq -r '.prod[].pc.checksum' <<<"$json") || exit 1

    update-source-version \
        ${lib.escapeShellArg pname} "$version"
        "$checksum" "https://demodownload.image-line.com/flstudio/flstudio_win64_${version}.exe"
  '';

}
