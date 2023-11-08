{ config
, pkgs
, lib
, inputs
, osConfig
, ...
}:
let
  inherit (config.lib.somasis)
    camelCaseToScreamingSnakeCase
    getExeName
    ;

  caprine = pkgs.caprine-bin;
  caprineWindowClassName = "Caprine";
  caprineDescription = caprine.meta.description;
  caprineName = getExeName caprine;
  caprinePath = "${caprine}/bin/${caprineName}";

  makeCssFontList = list: lib.pipe list [
    (map (font: ''"${font}"''))
    (lib.concatStringsSep ",")
  ];

  makeCssFontFamily = familyName: fontList: ''
    @font-face {
        font-family: "${familyName}";
        src: ${lib.pipe fontList [
          (map (font: "local(\"${font}\")"))
          (lib.concatStringsSep ",")
        ]};
    }
  '';
in
{
  home.packages = [ caprine ];

  persist.directories = [ "etc/${caprineWindowClassName}" ];

  xdg.configFile."${caprineWindowClassName}/custom.css".text = ''
    ${makeCssFontFamily "system-ui" (osConfig.fonts.fontconfig.defaultFonts.sansSerif)}
    ${makeCssFontFamily "-apple-system" (osConfig.fonts.fontconfig.defaultFonts.sansSerif)}
    ${makeCssFontFamily "BlinkMacSystemFont" (osConfig.fonts.fontconfig.defaultFonts.sansSerif)}
    ${makeCssFontFamily "emoji" osConfig.fonts.fontconfig.defaultFonts.emoji}
    ${makeCssFontFamily "sans-serif" (osConfig.fonts.fontconfig.defaultFonts.sansSerif)}
    ${makeCssFontFamily "serif" (osConfig.fonts.fontconfig.defaultFonts.serif)}
    ${makeCssFontFamily "monospace" (osConfig.fonts.fontconfig.defaultFonts.monospace)}
    ${makeCssFontFamily "ui-sans-serif" (osConfig.fonts.fontconfig.defaultFonts.sansSerif)}
    ${makeCssFontFamily "ui-serif" (osConfig.fonts.fontconfig.defaultFonts.serif)}
    ${makeCssFontFamily "ui-monospace" (osConfig.fonts.fontconfig.defaultFonts.monospace)}

    body,
    button,
    input,
    label,
    select,
    td,
    textarea {
        font-family: ui-sans-serif, sans-serif !important;
    }

    pre,
    code {
        font-family: ui-monospace, monospace !important;
    }
  '';

  systemd.user.services.caprine = {
    Unit = {
      Description = caprineDescription;
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" "tray.target" ];
      Requires = [ "tray.target" ];

      StartLimitIntervalSec = 1;
      StartLimitBurst = 1;
      StartLimitAction = "none";
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";

      ExecStartPre =
        let
          caprineConfig = lib.generators.toJSON { } {
            autoUpdate = false;

            autoHideMenuBar = true;
            emojiStyle = "native";
            theme = "dark";

            autoplayVideos = false;
            notificationMessagePreview = true;

            showTrayIcon = true;
            keepMeSignedIn = true;
            launchMinimized = true;
            quitOnWindowClose = false;

            showMessageButtons = true;
            spellCheckLanguages = [ "en-US" ];
          };
        in
        pkgs.writeShellScript "caprine-write-config" ''
          ${lib.toShellVar "caprine_config" caprineConfig}
          printf '%s\n' "$caprine_config" > "''${XDG_CONFIG_HOME:=$HOME/.config}"/${lib.escapeShellArg caprineWindowClassName}/config.json
        ''
      ;

      ExecStart = caprinePath;
      Restart = "on-abnormal";
    };
  };

  services.dunst.settings.zz-caprine = {
    desktop_entry = caprineWindowClassName;

    # Facebook blue
    background = "#0866ff";
    foreground = "#ffffff";
  };

  # services.sxhkd.keybindings."super + d" = pkgs.writeShellScript "caprine" ''
  #   ${pkgs.jumpapp}/bin/jumpapp \
  #       -c ${lib.escapeShellArg caprineWindowClassName} \
  #       -i ${lib.escapeShellArg caprineName} \
  #       -f ${pkgs.writeShellScript "start-or-switch" ''
  #           if ! ${pkgs.systemd}/bin/systemctl --user is-active -q caprine.service >/dev/null 2>&1; then
  #               ${pkgs.systemd}/bin/systemctl --user start caprine.service && sleep 2
  #           fi
  #           exec ${lib.escapeShellArg caprinePath} >/dev/null 2>&1
  #       ''} \
  #       >/dev/null
  # '';
}
