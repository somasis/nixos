{ pkgs, ... }: {
  home.package = [
    pkgs.sony-headphones-client
    pkgs.ponymix

    (pkgs.writeShellScriptBin "ponymix-snap" ''
      snap=5
      [ "$FLOCKER" != "$0" ] \
          && export FLOCKER="$0" \
          && exec flock -n "$0" "$0" "$@"

      ${pkgs.ponymix}/bin/ponymix "$@"
      b=$(${pkgs.ponymix}/bin/ponymix --short get-volume)
      c=$((b - $((b % snap))))
      ${pkgs.ponymix}/bin/ponymix --short set-volume "$c" >/dev/null
    '')
  ];

  services.sxhkd.keybindings = {
    "XF86AudioMute" = "ponymix -t sink toggle >/dev/null";
    # "super + XF86AudioMute" = "ponymix -t source toggle >/dev/null";
    "shift + XF86AudioMute" = "ponymix-cycle-default sink";
    "shift + super + XF86AudioMute" = "ponymix-cycle-default source";

    "XF86AudioLowerVolume" = "ponymix-snap -t sink decrease 5 >/dev/null";
    "XF86AudioRaiseVolume" = "ponymix-snap -t sink increase 5 >/dev/null";

    "shift + XF86AudioLowerVolume" = "ponymix-snap -t source decrease 5 >/dev/null";
    "shift + XF86AudioRaiseVolume" = "ponymix-snap -t source increase 5 >/dev/null";
  };
}
