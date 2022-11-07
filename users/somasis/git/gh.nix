{ config
, lib
, nixosConfig
, pkgs
, ...
}:
let
  pass-gh = (pkgs.writeShellApplication {
    name = "pass-gh";
    runtimeInputs = [
      config.programs.password-store.package
      config.programs.gh.package
      pkgs.coreutils
    ];

    text = ''
      set -eu
      set -o pipefail

      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"
      runtime="''${XDG_RUNTIME_DIR}/pass-gh"

      hostname="$1"; shift
      username="$1"; shift
      protocol="$1"; shift

      entry="${nixosConfig.networking.fqdn}/gh/$hostname/$username"

      if pass=$(pass "$entry" 2>/dev/null); then
          [[ -d "$runtime" ]] || mkdir -m 700 "$runtime"
          [[ -d "$runtime/gh" ]] || mkdir -m 700 "$runtime/gh"
          cat "$XDG_CONFIG_HOME"/gh/config.yml > "$runtime"/gh/config.yml

          XDG_CONFIG_HOME="$runtime" \
              gh auth login \
                  --with-token \
                  -h "$hostname" \
                  -p "$protocol" \
                  <<< "$pass"

          e=0
      else
          printf 'pass-gh: "entry %s does not exist"\n' "$entry" > "$runtime"/gh/hosts.yml
          e=1
      fi

      ln -sf "$runtime"/gh/hosts.yml "$XDG_CONFIG_HOME"/gh/hosts.yml
      rm -f "$runtime"/gh/config.yml

      exit "$e"
    '';
  });
in
{
  home.packages = [ pass-gh ];

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      pager = "cat";
    };
  };

  # HACK: `gh` doesn't support reading the token from a command
  systemd.user.services."pass-gh" = {
    Unit = {
      Description = "Authenticate `gh` to github.com using `pass`";
      PartOf = [ "default.target" ];
    };
    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [ "${pass-gh}/bin/pass-gh github.com somasis ssh" ];
      ExecStop = [ "${pkgs.coreutils}/bin/rm -rf %t/pass-gh" ];
    } // (lib.optionalAttrs (nixosConfig.networking.networkmanager.enable) { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; });
  };
}
