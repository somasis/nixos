{
  programs.bash = {
    shellAliases = rec {
      # LC_COLLATE=C sorts uppercase before lowercase.
      ls = "LC_COLLATE=C ls -AFlh";
      vi = "$EDITOR";

      # Quick ssh aliases
      "ascii.town" = "ssh play@ascii.town";
      "2048" = "ssh -t play@ascii.town 2048";
      "snake" = "ssh -t play@ascii.town snake";

      # Quick text editing aliases
      note = ''$EDITOR "$(make -C ~/src/www/somas.is -s note-new)"'';
      rhizome = ''$EDITOR "$(make -C ~/src/www/somas.is -s rhizome-new)"'';

      bc = "bc -q";
      diff = "diff --color";

      youtube-dl = "yt-dlp";
      ytmp3 = "yt-dlp --extract-audio --audio-format=mp3";

      g = ''find -L ./ -type f \! -path "*/.*/*" -print0 | xe -0 -N0 grep -n'';

      xz = "xz -T0 -9 -e";
      zstd = "zstd -T0 -19";
      gzip = "pigz -p $(( $(nproc) / 2 )) -9";

      peek = "tee /dev/stderr";

      systemctl = "systemctl -l --legend=false";
      userctl = "systemctl --user";
      journalctl = "journalctl -e";
      syslog = "${journalctl} -b";
      userlog = "${syslog} --user";

      wget = "curl -q -Lf# -Z --no-clobber --remote-name-all --remote-header-name --remove-on-error --retry 20 --retry-delay 10";

      since = "datediff -f '%Yy %mm %ww %dd %0Hh %0Mm %0Ss'";
    };

    initExtra = ''
      # diff() {
      #     command diff "$@" \
      #         | {
      #             if [ -t 1 ] || [ -n "$NO_COLOR" ]; then
      #                 sed \
      #                     -e '/^+/ { s/^/\e[32m/; s/$/\e[0m/' \
      #                     -e '/^-/ { s/^/\e[31m/; s/$/\e[0m/' \
      #                     -e '/^
      # }

      edo() { printf '+ %s\n' "$*" >&2; "$@"; }

      mount() {
          if [ "$#" -eq 0 ] && [ -t 1 ]; then
              # TODO: fuse is hidden because home-manager impermanence mounts are mounted as just "fuse", not as "bindfs" or whatever
              # TODO: also, surely there's some way to hide pseudo filesystems easier than this...?
              findmnt --tree \
                  -mv \
                  -O nox-gvfs-hide \
                  -t noautofs,nobinfmt_misc,nobpf,nocgroup,nocgroup2,noconfigfs,nodevpts,nodevtmpfs,noefivarfs,nofusectl,nohugetlbfs,nomqueue,noproc,nopstore,noramfs,nosecurityfs,nosysfs,notmpfs,nofuse
          else
              command mount "$@"
          fi
      }

      # Spawn a new terminal, detached from the current one, inheriting environment and working directory.
      newt() (
          nohup terminal "$@" >/dev/null 2>&1 &
      )
    '';
  };
}
