{ lib
, mkWindowsApp
, writeScript
, wine
, winetricks
, fetchurl
}:
let
  version = "20.9.2.2963";
  majorVersion = builtins.head (builtins.splitVersion version);
  c = "drive_c";
  fl = "${c}/Program Files/Image-Line/FL Studio ${majorVersion}";

  configHome = ''''${XDG_CONFIG_HOME:=$HOME/.config}'';
  dataHome = ''''${XDG_CONFIG_HOME:=$HOME/.local/share}'';
in
mkWindowsApp rec {
  pname = "flstudio";
  inherit version wine;

  src = fetchurl {
    url = "https://demodownload.image-line.com/flstudio/flstudio_win64_${version}.exe";
    hash = "sha256-CvLr5Pbv+Ps166jj7iP93RAgXxHdLOeVNQNQREb8vhQ=";
  };

  passthru.updateScript = writeScript "update-flstudio" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl gnused jq common-updater-scripts

    set -eu -o pipefail

    json=$(
        curl -sf \
            'https://support.image-line.com/api.php?call=get_version_info&callback=il_get_version_info_cb' \
            | sed 's/^.* = //; s/.*(//; s/);$//' \
            | jq 'fromjson | .prod[].pc'
    )

    update-source-version ${pname} \
        "$(jq -r '.version' <<<"$json")" \
        "$(jq -r '.checksum' <<<"$json")" \
        "https://demodownload.image-line.com/flstudio/flstudio_win64_${version}.exe"
  '';

  dontUnpack = true;

  persistRegistry = true;

  wineArch = "win64";

  nativeBuildInputs = [
    winetricks
  ];

  winAppInstall = ''
    winetricks -q arial tahoma
    wine $src /S

    c="$WINEPREFIX/${c}"
    fl="$WINEPREFIX/${fl}"

    mkdir -p "$fl/Data/Patches" "$fl/Data/Patches/Plugin presets"

    ln -s "${dataHome}/flstudio/projects"         "$c/ProgramData/Image-Line/Data/FL Studio/Projects";
    ln -s "${dataHome}/flstudio/samples/unsorted" "$c/ProgramData/Image-Line/Data/FL Studio/Audio/Sliced audio"
    ln -s "${dataHome}/flstudio/samples/unsorted" "$c/ProgramData/Image-Line/FL Studio/Audio/Sliced audio"
    ln -s "${dataHome}/flstudio/samples/unsorted" "$fl/Data/Patches/Sliced beats"
  '';

  fileMap = {
    "${dataHome}/flstudio/presets/channels" = "${fl}/Data/Patches/Channel presets";
    "${dataHome}/flstudio/presets/effects" = "${fl}/Data/Patches/Plugin presets/Effects";
    "${dataHome}/flstudio/presets/generators" = "${fl}/Data/Patches/Plugin presets/Generators";
    "${dataHome}/flstudio/presets/mixers" = "${fl}/Data/Patches/Mixer presets";
    "${dataHome}/flstudio/presets/vst" = "${fl}/Data/Patches/Plugin presets/VST";
    "${dataHome}/flstudio/projects" = "${c}/ProgramData/Image-Line/FL Studio/Projects";
    "${dataHome}/flstudio/projects/renders" = "${c}/ProgramData/Image-Line/Data/FL Studio/Audio/Rendered";
    "${dataHome}/flstudio/projects/templates" = "${fl}/Data/Templates";
    "${dataHome}/flstudio/recordings" = "${c}/ProgramData/Image-Line/Data/FL Studio/Audio/Recorded";
    "${dataHome}/flstudio/samples/impulses" = "${fl}/Data/Patches/Impulses";
    "${dataHome}/flstudio/samples/packs" = "${fl}/Data/Patches/Packs";
    "${dataHome}/flstudio/soundfonts" = "${fl}/Data/Patches/Soundfonts";
  };

  # winAppPreRun = ''
  #   : "''${XDG_DATA_HOME:=$HOME/.local/share}"

  #   c="$WINEPREFIX/${c}"

  #   for p in "Program Files" "Program Files (x86)"; do
  #       mkdir -p "$c/$p/Steinberg" "$c/$p/Common Files"

  #       ln -s "$XDG_DATA_HOME/${pname}/vst2" "$c/$p/VstPlugins"
  #       ln -s "$XDG_DATA_HOME/${pname}/vst2" "$c/$p/Steinberg/VstPlugins"
  #       ln -s "$XDG_DATA_HOME/${pname}/vst2" "$c/$p/Common Files/VST2"
  #       ln -s "$XDG_DATA_HOME/${pname}/vst3" "$c/$p/Common Files/VST3"
  #   done
  # '';

  # Add symbolic links to user data locations so they're not stored with program data.

  # mkdir -p \
  #     "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches" \
  #     "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Plugin presets"
  #
  # "$HOME/audio/samples/unsorted" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Sliced beats"
  # "$HOME/audio/samples/impulses" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Impulses"
  # "$HOME/audio/presets/channels" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Channel presets"
  # "$HOME/audio/presets/effects" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Plugin presets/Effects"
  # "$HOME/audio/presets/generators "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Plugin presets/Generators"
  # "$HOME/audio/presets" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Plugin presets/VST"
  # "$HOME/audio/projects" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Projects"
  # "$HOME/audio/projects/templates "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Templates"
  # "$HOME/audio/soundfonts" = "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio ${majorVersion}/Data/Patches/Soundfonts"

  winAppRun = ''
    export WINEDEBUG="''${WINEDEBUG:=fixme-all,+timestamp,+pid}"
    wine start /wait /realtime "C:/Program Files/Image-Line/FL Studio 20/FL.exe" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall
    ln -s $out/bin/.launcher $out/bin/${pname}
    runHook postInstall
  '';

  meta = with lib; {
    description = "A legendary digital audio workstation for Windows and macOS";
    license = licenses.unfree;
    maintainers = with maintainers; [ somasis ];
    homepage = "https://www.image-line.com/fl-studio/";
    changelog = "https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/WhatsNew.htm";
  };
}
