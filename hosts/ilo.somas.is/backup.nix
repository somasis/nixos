{ config
, lib
, pkgs
, ...
}:
let
  runas_user = "somasis";
  runas = ''
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

    extraArgs = lib.cli.toGNUCommandLineShell { } { lock-wait = 600; };
    extraCreateArgs = lib.cli.toGNUCommandLineShell { } {
      stats = true;
      progress = true;
      exclude-if-present = [ ".stfolder" ".stversions" ];
    };

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

    startAt = "daily";
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
      inhibitsSleep
      paths
      prune
      persistentTimer
      startAt
      ;

    repo = repoSpinoza;
  };

  systemd.services."borgbackup-job-spinoza".serviceConfig.Nice = 19;

  environment.systemPackages = let inherit (defaults) extraArgs; in [
    (pkgs.writeShellApplication rec {
      name = "borg-import-letterboxd";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.libarchive
        pkgs.jq
      ];

      text = ''
        set -e

        usage() {
            cat >&2 <<EOF
        usage: ${name} letterboxd-*.zip
        EOF
            exit 69
        }

        [ "$#" -ge 1 ] || usage

        n=$(basename "$1")
        n=''${n#letterboxd-}

        a=''${n%-*-*-*-*-*-utc.zip}

        d=''${n#*-}
        d=''${d%-*.zip}
        d=''${d:0:10}T''${d:11:2}:''${d:14:2}:00Z

        printf '::letterboxd-%s-%s\n' "$a" "$d"

        bsdtar -cf - "''$1" \
            | doas borg-job-spinoza \
                import-tar \
                    ${extraArgs} \
                    --stats -p \
                    --comment="imported with borg import-tar via. borg-import-letterboxd" \
                    "::letterboxd-''${a}-''${d}.failed" \
                    -

        doas borg-job-spinoza \
            rename \
                ${extraArgs} \
                "::letterboxd-''${a}-''${d}.failed" \
                "letterboxd-''${a}-''${d}"

        doas borg-job-spinoza \
            prune \
                ${extraArgs} \
                --keep-monthly=12 --keep-yearly=4 \
                -a "letterboxd-''${a}-*"
      '';
    })

    (pkgs.writeShellApplication rec {
      name = "borg-import-tumblr";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.libarchive
        pkgs.jq
      ];

      text = ''
        set -e

        usage() {
            cat >&2 <<EOF
        usage: ${name} *.zip
        EOF
            exit 69
        }

        [ "$#" -ge 1 ] || usage

        date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

        files=()
        for f; do
            files+=("@''${f}")
        done

        t=$(mktemp -d)

        bsdtar -cf - --format=ustar "''${files[@]}" \
            | bsdtar -C "$t" -x -f - "payload-0.json"

        a=$(
            jq -r '.[0].data.email' < "$t"/payload-0.json
        )

        d=$(
            TZ=UTC date \
                --date="@$(TZ=UTC stat -c %Y "$t"/payload-0.json)" \
                +%Y-%m-%dT%H:%M:%SZ
        )

        rm -r "$t"

        printf '::tumblr-%s-%s (%s)\n' "$a" "$date" "$d"

        bsdtar -cf - --format=ustar "''${files[@]}" \
            | doas borg-job-spinoza \
                import-tar \
                    ${extraArgs} \
                    --stats -p \
                    --comment="imported with borg import-tar via. borg-import-tumblr" \
                    --timestamp="''${d}" \
                    "::tumblr-''${a}-''${date}.failed" \
                    -

        doas borg-job-spinoza \
            rename \
                ${extraArgs} \
                "::tumblr-''${a}-''${date}.failed" \
                "tumblr-''${a}-''${date}"

        doas borg-job-spinoza \
            prune \
                ${extraArgs} \
                --keep-monthly=12 --keep-yearly=4 \
                -a "tumblr-''${a}-*"
      '';
    })

    (pkgs.writeShellApplication rec {
      name = "borg-import-twitter";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.libarchive
        pkgs.gnused
        pkgs.jq
      ];

      text = ''
        set -e

        usage() {
            cat >&2 <<EOF
        usage: ${name} twitter-1970-01-01-*
        EOF
            exit 69
        }

        [ "$#" -ge 1 ] || usage

        date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

        files=()
        for f; do
            files+=("@''${f}")
        done

        a=$(
            bsdtar -cf - --format=ustar "''${files[@]}" \
                | bsdtar -Ox -f - "data/account.js" \
                | sed '/\[$/d; /^\]$/d' \
                | jq -r '"\(.account.accountId)-\(.account.username)"'
        )

        aid=''${a%-*}

        d=''${1##*/}
        d=''${d%.*}
        d=''${d%-*}
        d=''${d#twitter-}
        d="''${d}"T00:00:00

        printf '::twitter-%s-%s (%s)\n' "$a" "$date" "$d"

        bsdtar -cf - --format=ustar "''${files[@]}" \
            | doas borg-job-spinoza \
                import-tar \
                    ${extraArgs} \
                    --stats -p \
                    --comment="imported with borg import-tar via. borg-import-twitter" \
                    --timestamp="''${d}" \
                    "::twitter-''${a}-''${date}.failed" \
                    -

        doas borg-job-spinoza \
            rename \
                ${extraArgs} \
                "::twitter-''${a}-''${date}.failed" \
                "twitter-''${a}-''${date}"

        doas borg-job-spinoza \
            prune \
                ${extraArgs} \
                --keep-monthly=12 --keep-yearly=4 \
                -a "twitter-''${aid}-*"
      '';
    })

    (pkgs.writeShellApplication rec {
      name = "borg-import-google";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.libarchive
        pkgs.htmlq
        pkgs.gnugrep
      ];

      text = ''
        set -e

        usage() {
            cat >&2 <<EOF
        usage: ${name} takeout-19700101T000000Z-*
        EOF
            exit 69
        }

        [[ "$#" -ge 1 ]] || usage

        date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

        d=''${1##*/}
        d=''${d%.tgz}
        d=''${d#takeout-}
        d=''${d%-*}
        d=''${d%Z}
        d="''${d:0:4}"-"''${d:4:2}"-"''${d:6:2}"T"''${d:9:2}":"''${d:11:2}":"''${d:13:2}"

        files=()
        for f; do
            files+=("@''${f}")
        done

        a=$(
            bsdtar -cf - --format=ustar "''${files[@]}" \
                | bsdtar -Oxf - "Takeout/archive_browser.html" \
                | htmlq -t 'html > body h1.header_title' \
                | tr ' ' '\n' \
                | grep '@' \
                | head -n1
        )

        printf '::google-%s-%s (%s)\n' "$a" "$date" "$d"

        bsdtar -cf - --format=ustar "''${files[@]}" \
            | doas borg-job-spinoza \
                import-tar \
                    ${extraArgs} \
                    --stats -p \
                    --comment="imported with borg import-tar via. borg-import-google" \
                    --timestamp="''${d}" \
                    "::google-''${a}-''${date}.failed" \
                    -

            doas borg-job-spinoza \
                rename \
                    ${extraArgs} \
                    "::google-''${a}-''${date}.failed" \
                    "google-''${a}-''${date}"

            doas borg-job-spinoza \
                prune \
                    ${extraArgs} \
                    --keep-monthly=12 --keep-yearly=4 \
                    -a "google-''${a}-*"
      '';
    })
  ];

  environment.persistence."/cache".directories = [{ directory = "/root/.cache/borg"; mode = "0770"; }];
}
