{ config, pkgs, ... }:
let
  gallery-dl = pkgs.writeShellScript "gallery-dl" ''
    : "''${QUTE_FIFO:?}"

    exec >>"''${QUTE_FIFO}"

    ${pkgs.gallery-dl}/bin/gallery-dl -G "$@" \
        | ${pkgs.xe}/bin/xe -L printf 'open -r %s\n'
  '';

  mpv = pkgs.writeShellScript "mpv" ''
    ${pkgs.gallery-dl}/bin/gallery-dl -G "$@" \
        | ${config.programs.mpv.package}/bin/mpv \
            --loop=inf \
            --playlist=-
  '';
in
{
  programs.qutebrowser.keyBindings.normal = {
    "<z><p><g>" = "spawn -u ${gallery-dl} {url}";
    "<z><p><l>" = "spawn -u ${mpv} {url}";
  };

  programs.gallery-dl.enable = true;
}
