{ config
, pkgs
, lib
, ...
}:
# TODO: Replace with age-based password store when Android
#       Password Store is usable with it
{
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    ".gnupg"
    "share/password-store"
  ];

  programs.gpg.enable = true;

  programs.password-store = {
    enable = true;

    settings.PASSWORD_STORE_CLIP_TIME = builtins.toString 60;

    package = pkgs.pass-nodmenu.withExtensions (exts: with exts; [
      pass-audit
      pass-checkup
      pass-update

      (pkgs.stdenvNoCC.mkDerivation rec {
        name = "pass-extension-meta";

        src = pkgs.fetchFromGitHub {
          repo = "pass-extension-meta";
          owner = "rjekker";
          rev = "2942bff7bc088422e780a96e5b1139db8508f386";
          hash = "sha256-O/YatXOA4EiGnGkemmGd6pVCNVwrtDeLoDq9PRSlGY4=";
        };

        preInstall = ''
          mkdir -p $out/bin
        '';

        makeFlags = [
          "PREFIX=$(out)"
          "BINDIR=$(PREFIX)/bin"
          "BASHCOMPDIR=$(PREFIX)/share/bash-completion/completions"
        ];

        postFixup = ''
          substituteInPlace $out/lib/password-store/extensions/meta.bash \
            --replace " perl " " ${pkgs.perl}/bin/perl "
        '';
      })

      pass-otp
      (pkgs.stdenvNoCC.mkDerivation rec {
        name = "pass-botp";

        src = pkgs.fetchFromGitHub {
          repo = "pass-botp";
          owner = "msmol";
          rev = "0b0f3e2f7b0ef349fcf6c1cdfc08f5ccdad6b8d1";
          hash = "sha256-63oNeGNUa9TMmxv+5mS1kj44HKajbc0ytQskYIq1YXQ=";
        };

        installPhase = ''
          install -D -m755 $src/src/botp.bash $out/lib/password-store/extensions/botp.bash
        '';
      })

      (pkgs.writeTextFile {
        name = "pass-link";
        executable = true;
        destination = "/lib/password-store/extensions/link.bash";

        text = ''
          #!${pkgs.bash}

          export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.moreutils pkgs.rsync ]}:$PATH"

          usage() {
              cat >&2 <<EOF
          usage: pass link [-nu] SOURCE TARGET...
                 pass link [-nu]
          EOF
              exit 69
          }

          set -eu
          set -o pipefail

          : "''${PASSWORD_STORE_DIR:=$HOME/.password-store}"
          links="$PASSWORD_STORE_DIR/.pass-link"

          dry_run=
          target_may_update_source=false

          while getopts :nu arg >/dev/null 2>&1; do
              case "$arg" in
                  n) dry_run=dry_run ;;
                  u) target_may_update_source=true ;;
                  *) usage ;;
              esac
          done
          shift $(( OPTIND - 1 ))

          [ "$#" -eq 1 ] && usage ;;

          success=true

          dry_run() {
              echo "$@" >&2
          }

          canonicalize_links_file() {
              sort -t ' ' -k1 \
                  | while IFS=" " read -r source targets; do
                      [ -n "$targets" ] || continue
                      for target in $targets; do
                          printf '%s %s\n' "$source" "$target"
                      done
                  done \
                  | uniq
          }

          compress_canonicalized_links_file() {
              awk '
                  $1==last_source { printf " %s",$2; next }
                  NR>1 { print ""; }
                  { last_source=$1; printf "%s",$0; }
                  END { print ""; }
              '
          }

          update_link() {
              source="$1"; shift

              for target; do
                  source_path="$PASSWORD_STORE_DIR/$source"
                  target_path="$PASSWORD_STORE_DIR/$target"

                  if [ -d "$PASSWORD_STORE_DIR/$source" ] && [ -d "$PASSWORD_STORE_DIR/$target" ]; then
                      rsync ''${dry_run:+--dry-run} -u -LKk --delay-updates -r --delete --delete-delay "$PASSWORD_STORE_DIR/$source"/ "$PASSWORD_STORE_DIR/$target"/
                  else
                      source_path="$source_path".gpg
                      target_path="$target_path".gpg

                      from_path="$source_path"
                      to_path="$target_path"

                      if ! [ -e "$source_path" ]; then
                          printf "error: '%s' does not exist\n" "$source" >&2
                          exit 1
                      elif [ -e "$target_path" ]; then
                          if [ "$(pass show "$target" | sha256sum -)" != "$(pass show "$source" | sha256sum -)" ]; then
                              if "$target_may_update_source"; then
                                  from_path="$target_path"
                                  to_path="$source_path"
                              elif ! [ -e "$target_path" ]; then
                                  printf "warning: '%s' is newer than its source '%s', not overwriting\n" "$target" "$source" >&2
                                  success=false
                                  continue
                              fi
                          fi
                      fi

                      cmp -s "$from_path" "$to_path" || $dry_run cp -f "$from_path" "$to_path"
                  fi
                  printf '%s %s\n' "$source" "$target"
              done
          }

          check_sneaky_paths "$@"

          (
              cat "$links"

              if [ "$#" -ge 2 ]; then
                  arg_source="$1"; shift
                  printf '%s %s\n' "$arg_source" "$*"
              fi
          )   | canonicalize_links_file \
              | while read -r source targets; do
                  update_link "$source" $targets
              done \
              | compress_canonicalized_links_file \
              | sponge "$links"

          "$success" || exit 1
        '';
      })
      (pkgs.writeTextFile {
        name = "pass-unlink";

        destination = "/lib/password-store/extensions/unlink.bash";
        executable = true;

        text = ''
          #!${pkgs.bash}
          export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.moreutils pkgs.rsync ]}:$PATH"

          usage() {
              cat >&2 <<EOF
          usage: pass unlink [-n] TARGET...
          EOF
              exit 69
          }

          set -eu
          set -o pipefail

          : "''${PASSWORD_STORE_DIR:=$HOME/.password-store}"
          links="$PASSWORD_STORE_DIR/.pass-link"

          dry_run=
          target_may_update_source=false

          while getopts :nu arg >/dev/null 2>&1; do
              case "$arg" in
                  n) dry_run=dry_run ;;
                  *) usage ;;
              esac
          done
          shift $(( OPTIND - 1 ))

          [ "$#" -ge 1 ] || usage

          success=true

          dry_run() {
              echo "$@" >&2
          }

          canonicalize_links_file() {
              sort -t ' ' -k1 \
                  | while IFS=" " read -r source targets; do
                      [ -n "$targets" ] || continue
                      for target in $targets; do
                          printf '%s %s\n' "$source" "$target"
                      done
                  done \
                  | uniq
          }

          compress_canonicalized_links_file() {
              awk '
                  $1==last_source { printf " %s",$2; next }
                  NR>1 { print ""; }
                  { last_source=$1; printf "%s",$0; }
                  END { print ""; }
              '
          }

          remove_link() {
              remove="$1"

              while read -r source targets; do
                  printf '%s' "$source"

                  remove_path="$PASSWORD_STORE_DIR/$remove"
                  [ -d "$remove_path" ] || remove_path="$remove_path.gpg"

                  found=false
                  for target in $targets; do
                      if [ "$target" = "$remove" ]; then
                          found=true
                          pass rm "$target" >&2
                      else
                          printf ' %s' "$target"
                      fi
                  done

                  if "$success" && ! "$found"; then
                      printf "warning: '%s' does not exist in the target list\n" "$remove" >&2
                      success=false
                  fi

                  printf '\n'
              done
          }

          check_sneaky_paths "$@"

          <"$links" canonicalize_links_file \
              | remove_link "$1" \
              | canonicalize_links_file \
              | compress_canonicalized_links_file \
              | sponge "$links"

          "$success" || exit 1
        '';
      })
    ]);
  };

  # TODO broken with dbus-next check failure
  # services.pass-secret-service.enable = true;

  programs.qutebrowser.keyBindings.normal =
    let
      passGenerateCmd = pkgs.writeShellScript
        "pass-generate-cmd"
        ''
          : "''${QUTE_FIFO:?}"

          password_store_host=$(
              printf '%s\n' "$2" \
                  | sed -E \
                      -e "s|^https?://||" \
                      -e "s|^www\.||" \
                      -e "s|/.*||" \
                      -e "s|^|www/|" \
                      -e "s|$||"
          )

          printf 'set-cmd-text :spawn -u %s %s/\n' "$1" "$password_store_host" >>"''${QUTE_FIFO}"
        '';
      passGenerate = pkgs.writeShellScript
        "pass-generate"
        ''
          : "''${QUTE_FIFO:?}"

          if ${config.programs.password-store.package}/bin/pass generate -c "$1"; then
              ${pkgs.libnotify}/bin/notify-send \
                  -a pass \
                  -i password \
                  -u low \
                  "pass" \
                  "Generated password at '$1'. Copied to clipboard and will be cleared in ''${PASSWORD_STORE_CLIP_TIME} seconds."
          else
              ${pkgs.libnotify}/bin/notify-send \
                  -a pass \
                  -i password \
                  pass \
                  "\`pass generate -c '$1'\` failed for some reason..."
              exit 1
          fi
        '';
    in
    {
      # -n: Don't automatically enter into insert mode, so as to match the input.insert_mode.* settings.
      "zll" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass";
      "zlL" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass -d Enter";
      "zlz" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass -E";
      "zlu" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass -u";
      "zlp" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass -p";
      "zlo" = "spawn -u ${config.home.homeDirectory}/bin/qute-pass -o";
      "zlg" = "spawn -u ${passGenerateCmd} ${passGenerate} {url:host}";
      # "<z><l><z>" = "spawn -u pass-hint-username";
    };
}
