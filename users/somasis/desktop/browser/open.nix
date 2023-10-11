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
  programs.qutebrowser = {
    aliases.gallery-dl = "spawn -u ${gallery-dl} {url}";
    aliases.mpv = "spawn -u ${mpv} {url}";
    keyBindings.normal."zpg" = "gallery-dl";
    keyBindings.normal."zpl" = "mpv";
  };

  programs.gallery-dl = {
    enable = true;
    # settings = {
    #   extractor = {
    #     ytdl = {
    #       enabled = true;
    #       module = "yt_dlp";
    #     };
    #   };

    #   downloader = {
    #     ytdl.module = "yt_dlp";
    #   };
    # };
  };

  cache.directories = [ "var/cache/gallery-dl" ];
}
