{ config
, lib
, nixosConfig
, pkgs
, ...
}:
let
  repoSpinoza = "somasis@spinoza.7596ff.com:/mnt/raid/somasis/backup/borg";

  defaults = {
    archiveBaseName = config.networking.fqdnOrHostName;
    dateFormat = "-u +%Y-%m-%dT%H:%M:%SZ";
    doInit = false;

    encryption = {
      mode = "repokey";
      passCommand = builtins.toString (pkgs.writeShellScript ''pass-borg'' ''
        ${pkgs.buildPackages.doas}/bin/doas -u somasis \
            ${pkgs.coreutils}/bin/env \
                PASSWORD_STORE_DIR=/home/somasis/share/password-store \
                ${pkgs.pass}/bin/pass borg/somasis \
                | ${pkgs.coreutils}/bin/head -n1
      '');
    };

    environment = {
      BORG_RSH = "
            ${pkgs.buildPackages.doas}/bin/doas -u somasis \
                ${config.programs.ssh.package}/bin/ssh \
                    -i /home/somasis/.ssh/id_ed25519 \
                    -o ExitOnForwardFailure=no \
                    -Tx \
                    -l somasis
          ";
    };

    exclude = [
      "*[Cc]ache*"
      "*[Tt]humbnail*"
      ".stversions"
      "/persist/home/somasis/etc/syncthing/index-*.db"
      "pp:/persist/home/somasis/audio/source"
      "re:/persist/home/somasis/etc/discord/[0-9\.]+/.*"
    ];

    extraArgs = "--lock-wait 600";
    extraCreateArgs = "--stats --progress --exclude-if-present '.stfolder' --exclude-if-present '.stversions'";

    inhibitsSleep = true;

    # Force borg's CPU usage to remain low.
    preHook = ''
      borg() {
          ${lib.optionalString (nixosConfig.networking.networkmanager.enable) "${pkgs.networkmanager}/bin/nm-online -q"}
          ${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- ${lib.optionalString (nixosConfig.services.tor.client.enable) "${pkgs.torsocks}/bin/torsocks"} borg "$@"
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
      name = "borg-import-google-takeout";

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

        printf '::google-takeout-%s-%s (%s)\n' "$a" "$date" "$d"

        bsdtar -cf - --format=ustar "''${files[@]}" \
            | doas borg-job-spinoza \
                import-tar \
                    ${extraArgs} \
                    --stats -p \
                    --comment="imported with borg import-tar via. borg-import-google-takeout" \
                    --timestamp="''${d}" \
                    "::google-takeout-''${a}-''${date}.failed" \
                    -

            doas borg-job-spinoza \
                rename \
                    ${extraArgs} \
                    "::google-takeout-''${a}-''${date}.failed" \
                    "google-takeout-''${a}-''${date}"

            doas borg-job-spinoza \
                prune \
                    ${extraArgs} \
                    --keep-monthly=12 --keep-yearly=4 \
                    -a "google-takeout-''${a}-*"
      '';
    })
  ];

  environment.persistence."/cache".directories = [{ directory = "/root/.cache/borg"; mode = "0770"; }];
}
