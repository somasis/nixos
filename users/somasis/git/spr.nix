{ config
, osConfig
, pkgs
, ...
}:
let
  secret-spr = pkgs.writeShellApplication {
    name = "secret-spr";
    runtimeInputs = [
      config.programs.password-store.package
      pkgs.coreutils
    ];

    text = ''
      umask 0077

      hostname="$1"; shift
      username="$1"; shift

      runtime="''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}/secret-spr"
      config="$runtime/$hostname/$username.conf"
      [ -d "$runtime" ] || mkdir -m 700 "$runtime"
      [ -d "$runtime/$hostname" ] || mkdir -m 700 "$runtime/$hostname"

      touch "$runtime"/gitconfig "$config"
      chmod 640 "$runtime"/gitconfig "$config"

      cat > "$config" <<EOF
      [spr]
      githubAuthToken = $(pass ${lib.escapeShellArg osConfig.networking.fqdnOrHostName}"/spr/$hostname/$username")
      EOF

      for p in "$runtime"/*/*.conf; do
          printf '[include]\npath = "%s"\n' "$p"
      done > "$runtime"/gitconfig
    '';
  };
in
{
  programs.git = {
    includes = [{
      path = "/run/user/${toString osConfig.users.users.somasis.uid}/secret-spr/gitconfig";
    }];

    extraConfig.spr = {
      requireTestPlan = false;
      branchPrefix = "${config.home.username}/";
    };
  };

  systemd.user.services.secret-spr = {
    Unit = {
      Description = "Authenticate `spr` to github.com using `pass`";
      PartOf = [ "default.target" ];
    };
    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [ "${secret-spr}/bin/secret-spr github.com somasis" ];
      ExecStop = [ "${pkgs.coreutils}/bin/rm -rf %t/secret-spr" ];
    };
  };

  home.packages = [
    pkgs.spr
    secret-spr
  ];
}
