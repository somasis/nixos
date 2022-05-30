{ config
, pkgs
, ...
}:
let
  repoSpinoza = "somasis@spinoza.7596ff.com:/mnt/raid/somasis/backup/borg";

  defaults = {
    archiveBaseName = "${config.networking.fqdn}";
    dateFormat = "-u +%Y-%m-%dT%H:%M:%S";
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
      "/persist/home/somasis/etc/GIMP/*/CrashLog"
      "/persist/home/somasis/etc/syncthing/index-*.db"
      "pp:/persist/home/somasis/audio/source"
      "re:/persist/home/somasis/etc/discord/[0-9\.]+/.*"
    ];

    extraArgs = "--lock-wait 600";
    extraCreateArgs = "--stats --exclude-if-present '.stfolder' --exclude-if-present '.stversions'";
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
      paths
      prune
      persistentTimer
      startAt
      ;

    repo = repoSpinoza;
  };

  systemd.services."borgbackup-job-spinoza".serviceConfig.Nice = 19;

  environment.systemPackages = let inherit (defaults) extraArgs; in [
    (pkgs.writeShellScriptBin "borg-import-tumblr" ''
      set -e

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} *.zip
      EOF
          exit 69
      }

      [ "$#" -ge 1 ] || usage

      date=$(TZ=UTC ${pkgs.coreutils}/bin/date +%Y-%m-%dT%H:%M:%S)

      files=()
      for f; do
          files+=("@''${f}")
      done

      t=$(mktemp -d)

      ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
          | ${pkgs.libarchive}/bin/bsdtar -C "$t" -x -f - "payload-0.json"

      a=$(
          ${pkgs.jq}/bin/jq -r '.[0].data.email' < "$t"/payload-0.json
      )

      d=$(
          ${pkgs.coreutils}/bin/date \
              --date="@$(${pkgs.coreutils}/bin/stat -c %Y "$t"/payload-0.json)" \
              +%Y-%m-%dT%H:%M:%S
      )

      rm -r "$t"

      printf '::tumblr-%s-%s (%s)\n' "$a" "$date" "$d"

      ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
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
              -a "tumblr-''${aid}-*"
    '')

    (pkgs.writeShellScriptBin "borg-import-twitter" ''
      set -e

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} twitter-1970-01-01-*
      EOF
          exit 69
      }

      [ "$#" -ge 1 ] || usage

      date=$(TZ=UTC ${pkgs.coreutils}/bin/date +%Y-%m-%dT%H:%M:%S)

      files=()
      for f; do
          files+=("@''${f}")
      done

      a=$(
          ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
              | ${pkgs.libarchive}/bin/bsdtar -Ox -f - "data/account.js" \
              | ${pkgs.gnused}/bin/sed '/\[$/d; /^\]$/d' \
              | ${pkgs.jq}/bin/jq -r '"\(.account.accountId)-\(.account.username)"'
      )

      user=''${a#*-}
      aid=''${a%-*}

      d=''${1##*/}
      d=''${d%.*}
      d=''${d%-*}
      d=''${d#twitter-}
      d="''${d}"T00:00:00

      printf '::twitter-%s-%s (%s)\n' "$a" "$date" "$d"

      ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
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
    '')

    (pkgs.writeShellScriptBin "borg-import-google-takeout" ''
      set -e

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} takeout-19700101T000000Z-*
      EOF
          exit 69
      }

      [[ "$#" -ge 1 ]] || usage

      date=$(TZ=UTC ${pkgs.coreutils}/bin/date +%Y-%m-%dT%H:%M:%S)

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
          ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
              | ${pkgs.libarchive}/bin/bsdtar -Oxf - "Takeout/archive_browser.html" \
              | ${pkgs.htmlq}/bin/htmlq -t 'html > body h1.header_title' \
              | ${pkgs.coreutils}/bin/tr ' ' '\n' \
              | ${pkgs.gnugrep}/bin/grep '@' \
              | ${pkgs.coreutils}/bin/head -n1
      )

      printf '::google-takeout-%s-%s (%s)\n' "$a" "$date" "$d"

      ${pkgs.libarchive}/bin/bsdtar -cf - --format=ustar "''${files[@]}" \
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
    '')
  ];

  environment.persistence."/cache".directories = [
    { directory = "/root/.cache/borg"; mode = "0770"; }
  ];
}
