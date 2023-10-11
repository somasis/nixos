{ lib
, ...
}: {
  programs.qutebrowser.extraConfig = lib.fileContents ./redirects.py;
}
