{ config
, lib
, pkgs
, ...
}:
let
  runas_user = "somasis";
  runas = ''
    export PATH=${config.security.wrapperDir}:"$PATH"

    runas() {
        local runas_user
        ${lib.toShellVar "runas_user" runas_user}
        if test "$(id -un)" = "$runas_user"; then
            "$@"; return $?
        else
            su -l - "$runas_user" sh -c '"$@"' -- "$@"; return $?
        fi
    }

  '' + "runas"
  ;

  repoSpinoza = "somasis@spinoza.7596ff.com:/mnt/raid/somasis/backup/borg";

  defaults = {
    archiveBaseName = config.networking.fqdnOrHostName;
    dateFormat = "-u +%Y-%m-%dT%H:%M:%SZ";
    doInit = false;

    encryption = {
      mode = "repokey";
      passCommand = builtins.toString (pkgs.writeShellScript "borg-pass" ''
        : "''${BORG_REPO:?}"
        ${runas} pass "borg/''${BORG_REPO%%:*}" | head -n1
      '');
    };

    environment = {
      BORG_HOST_ID = config.networking.fqdnOrHostName;

      BORG_RSH = builtins.toString (pkgs.writeShellScript "borg-ssh" ''
        : "''${BORG_REPO:?}"
        case "$BORG_REPO" in
          *@*:*|*@*) ssh_user=''${BORG_REPO%%@*} ;;
        esac

        ${lib.optionalString config.networking.networkmanager.enable "${pkgs.networkmanager}/bin/nm-online -q || exit 255"}
        ${runas} ssh \
            -o ExitOnForwardFailure=no \
            -o BatchMode=yes \
            -Takx ''${ssh_user:+-l "$ssh_user"} "$@"
      '');
    };

    exclude = [
      "*[Cc]ache*"
      "*[Tt]humbnail*"
      ".stversions"
      "/persist/home/somasis/etc/syncthing/index-*.db"
      "pp:/persist/home/somasis/audio/source"
      "re:/persist/home/somasis/etc/discord(canary)?/[0-9\.]+/.*"
    ];

    extraArgs = "--lock-wait 600";
    extraCreateArgs = "-c 300 --stats --exclude-caches --keep-exclude-tags --exclude-if-present .stfolder";

    inhibitsSleep = true;

    # Force borg's CPU usage to remain low.
    preHook = ''
      borg() {
          ${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- borg "$@"
      }
    '';

    paths = [ "/persist" "/log" ];
    persistentTimer = true;

    prune.keep = {
      within = "14d";
      daily = 7;
      weekly = 4;
      monthly = -1;
      yearly = 1;
    };

    startAt = "04:00";
  };
in
{
  services.borgbackup.jobs.spinoza = let inherit defaults; in {
    inherit (defaults)
      archiveBaseName
      dateFormat
      doInit
      encryption
      environment
      exclude
      extraArgs
      extraCreateArgs
      inhibitsSleep
      preHook
      paths
      persistentTimer
      prune
      startAt
      ;

    repo = repoSpinoza;
  };

  systemd = {
    timers."borgbackup-job-spinoza".wants = [ "network-online.target" ];
    services."borgbackup-job-spinoza" = {
      unitConfig.ConditionACPower = true;
      serviceConfig.Nice = 19;
    };
  };

  environment.systemPackages =
    let
      borgJobs = builtins.attrNames config.services.borgbackup.jobs;
      defaultArgs = lib.cli.toGNUCommandLineShell { } {
        progress = true;
        verbose = true;
        lock-wait = 600;
      };
    in
    [
      (pkgs.borg-takeout.override {
        borgConfig = config.services.borgbackup.jobs.spinoza;
      })
    ]
    ++ (lib.optional (builtins.length borgJobs == 1) (
      pkgs.writeShellScriptBin "borg" ''
        exec borg-job-${lib.escapeShellArg (builtins.elemAt borgJobs 0)} ${defaultArgs} "$@"
      ''
    ))
  ;

  cache.directories = [{ directory = "/root/.cache/borg"; mode = "0770"; }];
}
