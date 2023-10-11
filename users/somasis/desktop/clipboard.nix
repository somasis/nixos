{ config
, lib
, pkgs
, ...
}:
let CM_DIR = "${config.xdg.cacheHome}/clipmenu"; in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "clip";

      runtimeInputs = [ pkgs.xclip ];

      text = ''
        [[ -t 1 ]] && exec xclip -selection clipboard -i "$@"
        exec xclip -selection clipboard -o "$@"
      '';
    })
  ];

  services.clipmenu.enable = true;
  # systemd.user.services.clipmenu.Service.Environment = lib.mkMerge [ "CM_DIR=${CM_DIR}" ];
  home.sessionVariables = { inherit CM_DIR; };
  systemd.user.sessionVariables = { inherit CM_DIR; };

  services.sxhkd.keybindings = {
    # Clipboard: show clipboard history - super + x
    "super + x" = "${pkgs.clipmenu}/bin/clipmenu -p clip";

    # Clipboard: run command and copy output to clipboard - super + shift + x
    "super + shift + x" = ''
      printf '%s' \"$(clip)\" \
          | ${pkgs.moreutils}/bin/sponge \
          | sh -c "$(dmenu -p 'clip')" \
          | clip >/dev/null
    '';
  };
}
