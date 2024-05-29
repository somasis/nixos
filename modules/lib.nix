{ lib
, pkgs
, config
, nixpkgs
, ...
}:
with lib;
{
  config.lib.nixos = import (nixpkgs + "/nixos/lib/utils.nix") { inherit lib config pkgs; };

  config.lib.somasis = rec {
    # Make an absolute path that is refers to a location under $HOME... be relative to $HOME.
    relativeToHome = path: lib.strings.removePrefix "./" (
      builtins.toString (
        lib.path.removePrefix
          (/. + config.home.homeDirectory)
          (/. + (lib.strings.removePrefix "~/" path))
      )
    );

    # Give XDG paths that are relative to $HOME, mainly for use in impermanence settings
    xdgConfigDir = x: (relativeToHome config.xdg.configHome) + "/" + x;
    xdgCacheDir = x: (relativeToHome config.xdg.cacheHome) + "/" + x;
    xdgDataDir = x: (relativeToHome config.xdg.dataHome) + "/" + x;
    xdgStateDir = x: (relativeToHome config.xdg.stateHome) + "/" + x;

    # Convert a float to an integer.
    #
    # Really, we just treat it as a double. We first make it a string
    # (losing accuracy), split the string into its whole and fractional
    # parts, convert those to integers, cut trailing zeros from the
    # fractional part, and if the fractional part is >=5, we return the
    # whole number + 1, and if not, we just return the whole.
    #
    # Type: floatToInt :: float -> int
    floatToInt = float:
      let
        inherit (builtins)
          split
          toString
          ;
        inherit (lib)
          flatten
          isFloat
          isList
          pipe
          remove
          toInt
          ;

        splitFloat = pipe float [
          toString
          (split "(.+)[.](.+)")
          (remove "")
          flatten
        ];

        whole = pipe (elemAt splitFloat 0) [
          toString
          toInt
        ];

        fractional = pipe (elemAt splitFloat 1) [
          toString
          (split "0+$")
          (remove "")
          flatten
          toString

          # Handle fractional == 0. The `split` produced a bunch of
          # empty strings if it's just 0.
          (x: if x == "" then "0" else x)
          toInt
        ];
      in
      assert (isFloat float);
      if fractional >= 5 then whole + 1 else whole
    ;

    # Create a comma,separated,string from a list.
    #
    # Type: commaList :: list -> str
    commaList = concatMapStringsSep "," (lib.escape [ "," ]);

    # Convert a camelCaseString to a SCREAMING_SNAKE_CASE_STRING.
    #
    # Type: camelCaseToScreamingSnakeCase :: str -> str
    camelCaseToScreamingSnakeCase = x:
      if toLower x == x then
        toUpper x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "_${c}") upperChars) ++ upperChars)
          x
    ;

    # Convert a camelCaseString to a snake_case_string.
    #
    # Type: camelCaseToSnakeCase :: str -> str
    camelCaseToSnakeCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "_${c}") lowerChars) ++ lowerChars)
          x
    ;

    # Convert a camelCaseString to a kebab-case-string.
    #
    # Type: camelCaseToKebabCase :: str -> str
    camelCaseToKebabCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "-${c}") lowerChars) ++ lowerChars)
          x
    ;

    # Convert a camelCaseString to a KEBAB-CASE-STRING.
    #
    # Type: camelCaseToScreamingKebabCase :: str -> str
    camelCaseToScreamingKebabCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "-${c}") upperChars) ++ upperChars)
          x
    ;

    # Convert a snake_case_string to a camelCaseString.
    #
    # Type: snakeCaseToCamelCase :: str -> str
    snakeCaseToCamelCase = x:
      let
        x' =
          replaceStrings
            (map (x: "_${x}") (lowerChars ++ upperChars))
            (upperChars ++ lowerChars)
            x
        ;
      in
      "${toLower (builtins.substring 0 1 x)}${builtins.substring 1 ((builtins.stringLength x') - 1) x'}"
    ;

    # Get the program name and path using the same logic as `nix run`.
    #
    # Type: getExeName :: derivation -> string
    getExeName = x: builtins.baseNameOf (lib.getExe x);

    # Remove "# comments" from a given string input.
    #
    # Type: removeComments :: (string | path) -> string
    removeComments = string:
      let
        withCommentsRemoved =
          pkgs.runCommandLocal "removeComments"
            {
              string =
                if lib.isString string then
                  pkgs.writeText "with-comments" string
                else # if lib.isStorePath string then
                  string
              ;
            } ''
            sed -E \
                -e '/^[[:space:]]*#/d' \
                -e 's/[[:space:]]+# .*//' \
                "$string" \
                > "$out"
          ''
        ;
      in
      if lib.isString string then
        builtins.readFile withCommentsRemoved
      else
        withCommentsRemoved
    ;

    generators = {
      # Generate XML from an attrset.
      #
      # The XML makes a roundtrip as JSON, and is validated during generation.
      #
      # Type: toXML :: attrset -> string
      toXML = {}: attrs:
        let
          xml =
            if (builtins.length (builtins.attrNames attrs)) == 1 then
              pkgs.runCommandLocal "xml"
                { json = pkgs.writeText "xml.json" (builtins.toJSON attrs); }
                ''
                  ${pkgs.yq-go}/bin/yq \
                      --indent 0 \
                      --input-format json \
                      --output-format xml \
                      --xml-strict-mode \
                      < "$json" \
                      > xml.xml

                  ${pkgs.xmlstarlet}/bin/xmlstarlet validate -e -b xml.xml

                  ${pkgs.xmlstarlet}/bin/xmlstarlet c14n xml.xml > canonical.xml
                  ${pkgs.xmlstarlet}/bin/xmlstarlet format -n canonical.xml > "$out"
                ''
            else
              abort "generators.toXML: only one root element is allowed"
          ;
        in
        lib.fileContents xml
      ;
    };

    feeds = rec {
      urls = rec {
        special =
          { type
          , value
          , extra ? ""
          }:
          let
            strings = [ type (toString value) ];
            strings' =
              if extra != "" then
                strings ++ [ extra ]
              else
                strings
            ;
          in
          ''"'' + escape [ "\"" ] (concatStringsSep ":" strings') + ''"''
        ;

        exec = command: special {
          type = "exec";

          # Use an additional layer of indirection,
          # because newsboat's backslash escape parsing is a little inscrutable...
          value = builtins.toString (pkgs.writeShellScript "execute-command" "exec ${command}");
        };

        filter = urlToFilter: filterProgram: special {
          type = "filter";
          value = builtins.toString (pkgs.writeShellScript "execute-filter" "exec ${filterProgram} ${lib.escapeShellArg urlToFilter}");
          extra = urlToFilter;
        };

        secret = url: entry:
          let
            secret = pkgs.writeShellScript "fetch-secret-url" ''
              PATH=${lib.makeBinPath [ config.programs.password-store.package pkgs.curl ]}:"$PATH"

              url="$1"   # ex. https://github.com/somasis.private.atom?token=%s
              entry="$2" # ex. www/github.com/somasis.private.atom

              url="\""$(sed 's/"/\\"/g' <<< "$url")"\""

              curl -Lf -G -K - <<EOF
              url = $(printf "$url" "$(pass "$entry")")
              EOF
            '';
          in
          urls.exec "${secret} ${lib.escapeShellArgs [ url entry ]}";
      };

      filters = {
        discardContent =
          let
            filter = pkgs.writeJqScript "filter" { exit-status = true; } ''
              if has("rss") then
                del(.rss.channel.item[]["description", "encoded"])
              elif has("feed") then
                del(.feed.entry[]["content"])
              else
                .
              end
            '';
          in
          pkgs.writeShellScript "discard-content" ''
            ${getExe pkgs.yq-go} -p xml -o json --xml-strict-mode \
                | ${filter} \
                | ${getExe pkgs.yq-go} -p json -o xml --xml-strict-mode
          '';
      };

      urls.gemini = url:
        let
          fetchGemini = pkgs.writeShellScript "fetch-gemini" ''
            PATH=${lib.makeBinPath [
              config.programs.jq.package
              pkgs.coreutils
              pkgs.dateutils
              pkgs.gemget
              pkgs.gmnitohtml
              pkgs.moreutils
              pkgs.pup
              pkgs.teip
            ]}:"$PATH"

            set -euo pipefail

            : "''${XDG_CACHE_HOME:=$HOME/.cache}"

            if [ "$#" -ne 1 ]; then
                printf 'error: no URL provided\n' >&2
                exit 1
            fi

            url="$1" # ex. gemini://git.skyjake.fi/lagrange/release
            url_hash=$(sha256sum <<<"$url")
            url_hash=''${url_hash%% *}

            gmni=$(gemget -o - "$url")
            gmni_hash=$(sha256sum <<<"$gmni")
            gmni_hash=''${gmni_hash%% *}

            output_hash="$XDG_CACHE_HOME/newsboat/gemini/$url_hash.hash"
            output_feed="$XDG_CACHE_HOME/newsboat/gemini/$url_hash.atom"
            output_feed_temp=$(mktemp)

            mkdir -p "$XDG_CACHE_HOME/newsboat/gemini"

            printf '%s\n' "$gmni_hash" > "$output_hash"

            if [ -s "$output_hash" ]; then
                old_gmni_hash=$(cat "$output_hash")
                old_gmni_hash=''${old_gmni_hash%% *}

                if [ -s "$output_feed" ] && [ "$gmni_hash" = "$old_gmni_hash" ]; then
                    cat "$output_feed"
                    exit 0
                fi
            fi

            html=$(gmnitohtml <<<"$gmni")

            # <https://geminiprotocol.net/docs/companion/subscription.gmi>

            title=$(pup 'h1:first-of-type text{}' <<<"$html")
            entries=$(
                <<<"$html" pup -i 0 'a[href] json{}' \
                    | jq -r \
                        --arg url "$url" '
                        .[]
                            | ($url + "/" + (.href | sub("^\\./|//"; ""))) as $link
                            | (.text | match("^[0-9]{4}-[0-9]{2}-[0-9]{2}").string) as $date
                            | (.text | sub("^[0-9]{4}-[0-9]{2}-[0-9]{2}( - |: | )?|^ *"; "")) as $title
                            | [ $date, ($link), ($title | @html) ]
                            | @tsv
                    ' \
                    | teip -d $'\t' -f1 -- dateconv -f '%Y-%m-%dT12:00:00Z'
            )

            updated=$(<<<"$entries" head -n1 | cut -f1)

            {
                cat <<EOF
            <?xml version="1.0" encoding="utf-8"?>
            <feed xmlns="http://www.w3.org/2005/Atom">
              <title>$title</title>
              <id>$url</id>
              <link href="$url" rel="self" />
              <updated>$updated</updated>
            EOF

                while IFS=$(printf '\t') read -r date link title; do
                    content=$(gemget -o - "$link" | gmnitohtml | jq -Rr '@html')

                    cat <<EOF
              <entry>
                <title type="html">$title</title>
                <link rel="alternate" href="$link" />
                <id>$link</id>
                <updated>$date</updated>
                <content type="html">$content</content>
              </entry>
            EOF
                done <<<"$entries"

                printf '</feed>\n'
            } | ifne sponge "$output_feed"
          '';
        in
        feeds.urls.exec "${fetchGemini} ${lib.escapeShellArg url}"
      ;
    };

    colors = rec {
      # Output a given color (any `pastel` format accepted) in a given format, as
      # accepted by `pastel`.
      #
      # Type: :: str -> str
      format = format: color:
        assert (lib.isString format);
        assert (lib.isString color);

        lib.fileContents (pkgs.runCommandLocal "color"
          { inherit color format; }
          # strip out the spaces because some things don't support spaces in rgb/hsl/etc.
          # type formats, and the things that do support spaces tend to allow no spaces.
          ''${lib.getExe pkgs.pastel} format "$format" "$color" > "$out" | tr -d " "''
        );

      # Format a given color to hexadecimal ("#ffffff").
      #
      # Type: :: str -> str
      hex = format "hex";

      # Format a given color to an RGB color ("rgb(255,255,255)").
      #
      # Type: :: str -> str
      rgb = format "rgb";

      # Execute a given `pastel` operation on a given color, accepting a given amount as an argument.
      #
      # Type: :: str -> str
      amountOp = operation: amount: color:
        assert (lib.isString operation);
        assert (lib.isFloat amount);
        assert (lib.isString color);

        lib.fileContents (pkgs.runCommandLocal "color"
          { inherit operation amount color; }
          ''${lib.getExe pkgs.pastel} "$operation" "$amount" "$color" > "$out"''
        );

      # Saturate, with a given amount, a given color.
      #
      # Type: :: str -> str
      saturate = amountOp "saturate";

      # Desaturate, with a given amount, a given color.
      #
      # Type: :: str -> str
      desaturate = amountOp "desaturate";

      # Lighten, with a given amount, a given color.
      #
      # Type: :: str -> str
      lighten = amountOp "lighten";

      # Darken, with a given amount, a given color.
      #
      # Type: :: str -> str
      darken = amountOp "darken";
    };

    types.color = format:
      let
        inherit (builtins) elem;

        pastelTypes = [
          "rgb"
          "rgb-float"
          "hex"
          "hsl"
          "hsl-hue"
          "hsl-saturation"
          "hsl-lightness"
          "lch"
          "lch-lightness"
          "lch-chroma"
          "lch-hue"
          "lab"
          "lab-a"
          "lab-b"
          "luminance"
          "brightness"
          "ansi-8bit"
          "ansi-24bit"
          "ansi-8bit-escapecode"
          "ansi-24bit-escapecode"
          "cmyk"
          "name"
        ];
      in
      assert (elem format pastelTypes);
      mkOptionType {
        name = "color";
        merge = lib.options.mergeDefaultOption;

        description = ''
          a color, as understood by `pastel` (see `pastel format --help` for more information)
        '';
        descriptionClass = "noun";

        check = value: (lib.fileContents
          (pkgs.runCommandLocal "check-value"
            { inherit value; }
            ''
              set -x
              e=0
              ${lib.getExe pkgs.pastel} color "$value" >/dev/null || e=$?
              echo "$e" > "$out"
              exit 0
            ''
          ) == "0"
        );
      }
    ;

    mkColorOption =
      { format
      , default ? null
      , description ? null
        # , type ? (types.color format)
      }:
      mkOption {
        type = types.color format;
        apply = colors.format format;

        inherit default description;
      };

    # Convert an argument (either a path, or a path-like string) into a derivation
    # by reading the path into a text file. If passed a derivation, the function
    # does nothing and simply returns the argument.
    #
    # Type: :: (derivation|str|path) -> derivation
    drvOrPath = x:
      if ! lib.isDerivation x then
        pkgs.writeText (builtins.baseNameOf x) (builtins.readFile x)
      else
        x
    ;

    # jhide can handle multiple lists, but the memory usage is much better
    # if you have a script per list.
    greasemonkey.jhide = excludeDomains: lists:
      assert (lib.isList excludeDomains);
      assert (lib.isString lists || lib.isList lists);

      let
        lists' =
          if lib.isList lists then
            lists
          else
            [ lists ]
        ;

        allowList =
          lib.optionalString (excludeDomains != [ ])
            ''--whitelist ${lib.escapeShellArg (lib.concatStringsSep "," excludeDomains)}''
        ;

        # Create a hash of all lists' hashes combined together.
        hash =
          builtins.hashString "sha256"
            (lib.concatStringsSep "," (
              map (builtins.hashFile "sha256") lists'
            ))
        ;
      in
      pkgs.runCommandLocal "jhide-${hash}.user.js" { } ''
        ${lib.getExe pkgs.jhide} -o $out ${allowList} ${lib.escapeShellArgs lists'}
      '';

    # Return from a flake argument, a string suitable for use as a package version.
    #
    # Type: :: flake -> str
    flakeModifiedDateToVersion = flake:
      let
        year = builtins.substring 0 4 flake.lastModifiedDate;
        month = builtins.substring 4 2 flake.lastModifiedDate;
        day = builtins.substring 6 2 flake.lastModifiedDate;
      in
      "unstable-${year}-${month}-${day}"
    ;

    makeXorgApplicationService =
      command:
      { class ? null
      , className ? null
      , role ? null
      , name ? null
      }:
        assert (class != null || className != null || name != null);
        assert (lib.isPath command || lib.isString command);
        let
          inherit (config.lib.nixos) escapeSystemdExecArgs;

          # the amount of effort I put into this script may
          # indicate that there's something wrong with me
          start-hide-notify =
            pkgs.writeShellScript "start-hide-notify" ''
              set -euo pipefail

              old_PATH="''${PATH:-}"
              ${lib.toShellVar "PATH" (lib.makeBinPath [ config.xsession.windowManager.bspwm.package pkgs.coreutils pkgs.jq pkgs.systemd pkgs.xdotool pkgs.xe pkgs.xorg.xprop ])}

              usage() {
                  # shellcheck disable=SC2059
                  [[ "$#" -eq 0 ]] || printf "$@" >&2
                  cat >&2 <<EOF
              usage: [NOTIFY_SOCKET=...] [WINDOW_CLASS=...] [WINDOW_CLASSNAME=...]
                     [WINDOW_NAME=...] [WINDOW_ROLE=...] ''${0##*/} <command>

              Start an Xorg-utilizing command and wait for its window to appear,
              determining which is the one belonging to the command in question
              according to a given criteria.

              At least one of $WINDOW_CLASS, $WINDOW_CLASSNAME or $WINDOW_NAME
              must be set.

              Environment variables:
                  $WINDOW_CLASS''${WINDOW_CLASS:+ (current value: $WINDOW_CLASS)}
                  $WINDOW_CLASSNAME''${WINDOW_CLASSNAME:+ (current value: $WINDOW_CLASSNAME)}
                  $WINDOW_NAME''${WINDOW_NAME:+ (current value: $WINDOW_NAME)}
                  $WINDOW_ROLE''${WINDOW_ROLE:+ (current value: $WINDOW_ROLE)}
              EOF
                  [[ "$#" -eq 0 ]] || exit 127
                  exit 69
              }

              wait_for_window() {
                  local loops=0
                  local maximum_loops=15

                  # seems like this helps to avoid race conditions
                  until xprop -id "$1" >/dev/null 2>&1 && bspc query -N -n "$1" >/dev/null 2>&1; do
                      loops=$(( loops + 1 ))

                      if [[ "$loops" -gt "$maximum_loops" ]]; then
                          printf 'error: something happened to window %s while we were automating window management. is it still there?\n' "$1" >&2
                          exit 127
                      fi

                      if [[ "$loops" -ge "5" ]]; then
                          systemd-notify --status='Waiting for a moment... (this is a workaround to avoid bspwm/Xorg-originating race conditions that mess up automation)'
                      fi

                      sleep 1
                  done
              }

              window_is_hidden() {
                  bspc query -T -n "$1" | jq -e '.hidden == true' >/dev/null
              }

              get_window() {
                  local xdotool_args=()

                  xdotool_args=(
                      ''${WINDOW_CLASS:+'--class'}
                      ''${WINDOW_CLASSNAME:+'--classname'}
                      ''${WINDOW_NAME:+'--name'}
                      ''${WINDOW_ROLE:+'--role'}
                  )

                  if [[ -z "''${xdotool_args[*]}" ]]; then
                      usage 'error: no class, class name, name, or role was set, but at least one is required\n'
                  fi

                  xdotool search "''${xdotool_args[@]}" --all "$@" "$regex"
              }

              remove_oneshot_rules() {
                  local desired_rule="$1"; shift
                  local desired_rule_flags="$*"

                  local rule_number rule_name rule_oneshot rule_flags

                  bspc rule -l \
                      | nl -b a -d "" -f n -w 1 -s ' ' \
                      | tac \
                      | while IFS=' ' read -r rule_number rule_oneshot rule_name _ rule_flags; do
                          i=$(( i + 1 ))
                          case "$rule_oneshot" in
                              '=>') rule_oneshot=false ;;
                              '->') rule_oneshot=true ;;
                          esac

                          if \
                              [[ "$rule_name" == "$desired_rule" ]] \
                              && [[ "$rule_flags" == "$desired_rule_flags" ]] \
                              && [[ "$rule_oneshot" == true ]]
                              then
                              bspc rule -r ^"$rule_number"
                          fi
                      done
              }

              [[ -v NOTIFY_SOCKET ]] || usage 'error: no NOTIFY_SOCKET was set by systemd\n'

              : "''${WINDOW_CLASS:=}"
              : "''${WINDOW_CLASSNAME:=}"
              : "''${WINDOW_NAME:=}"
              : "''${WINDOW_ROLE:=}"

              regex=
              rule=

              if [[ -z "$WINDOW_CLASS$WINDOW_CLASSNAME$WINDOW_NAME" ]]; then
                  usage 'error: no class, class name, or name was set, but at least one is required\n'
              fi

              if [[ -z "$regex" ]]; then
                  for part in "$WINDOW_CLASS" "$WINDOW_CLASSNAME" "$WINDOW_ROLE"; do
                      [[ -n "$part" ]] || continue

                      # make them literals; `xdotool search` uses POSIX ERE
                      # <https://stackoverflow.com/a/400316>
                      part=''${part//'.'/'\\.'}
                      part=''${part//'^'/'\\^'}
                      part=''${part//'$'/'\\$'}
                      part=''${part//'*'/'\\*'}
                      part=''${part//'+'/'\\+'}
                      part=''${part//'?'/'\\?'}
                      part=''${part//'('/'\\('}
                      part=''${part//')'/'\\)'}
                      part=''${part//'['/'\\['}
                      part=''${part//'{'/'\\{'}
                      part=''${part//'\\'/'\\\\'}
                      part=''${part//'|'/'\\|'}

                      regex+="''${regex:+|}^''${part}$"
                  done

                  if [[ -z "$regex" ]]; then
                      usage \
                          'error: no regex for selecting the main window was determined (%s: %s, %s: %s, %s: %s, %s: %s)\n' \
                          'class'       "''${WINDOW_CLASS@Q}" \
                          'class name'  "''${WINDOW_CLASSNAME@Q}" \
                          'name'        "''${WINDOW_NAME@Q}" \
                          'role'        "''${WINDOW_ROLE@Q}"
                  fi
              fi

              if [[ -z "$rule" ]]; then
                  for part in "$WINDOW_CLASS" "$WINDOW_CLASSNAME" "$WINDOW_NAME"; do
                      rule+="''${rule:+:}''${part:-*}"
                  done

                  if [[ -z "$rule" ]]; then
                      usage \
                          'error: no rule for selecting the main window was determined (%s: %s, %s: %s, %s: %s, %s: %s)\n' \
                          'class'       "''${WINDOW_CLASS@Q}" \
                          'class name'  "''${WINDOW_CLASSNAME@Q}" \
                          'name'        "''${WINDOW_NAME@Q}" \
                          'role'        "''${WINDOW_ROLE@Q}"
                  fi
              fi

              unset part

              {
                  set -euo pipefail
                  trap 'remove_oneshot_rules "$rule" "''${rule_flags[@]}"; kill $$' ERR

                  rule_flags=(
                      hidden=on
                      state=floating
                      layer=below
                      focus=off
                  )

                  remove_bspwm_rules "$rule" "''${rule_flags[@]}" || :

                  # hide the window during start (and also, make it float, so it
                  # doesn't disrupt any already tiled windows on the desktop).
                  systemd-notify --status="Adding window hiding rule (''${rule@Q}) to bspwm..."
                  bspc rule -a "$rule" -o "''${rule_flags[@]}"
                  systemd-notify --status="Added window hiding rule (''${rule@Q}) to bspwm."

                  # wait for a window matching our regex to be created
                  systemd-notify --status="Waiting for window (matched by ''${regex@Q}) to be detected..."
                  window_id=$(get_window --sync --limit 1)
                  [[ -n "$window_id" ]] \
                      || usage \
                          'error: could not find window matching regex %s; unable to mark service ready\n' \
                          "''${regex@Q}"
                  systemd-notify --status="Detected window (matched by ''${regex@Q}) successfully: $window_id"

                  # heavily prone to race conditions, for some reason, so we need this often
                  wait_for_window "$window_id"

                  # and then make sure it's indeed marked hidden, which ensures that the rule matched it
                  window_is_hidden "$window_id" \
                      || usage \
                          'error: could not find window matching rule %s (because window %s is not marked hidden); unable to mark service ready\n' \
                          "''${rule@Q}" "$window_id"
                  systemd-notify --status="Detected window hidden by rule ''${rule@Q} successfully: $window_id"

                  wait_for_window "$window_id"

                  # having found the window that matches both the regex and the rule, unmap it
                  xdotool windowunmap "$window_id"
                  systemd-notify --status="Attempted to unmap window ($window_id)."

                  wait_for_window "$window_id"

                  # revert the window's state to the state it was prior to the one-shot
                  # rule setting it to be floating (probably tiling, but this seems more
                  # right for reverting our rule, to me...)
                  systemd-notify --status="Reverting bspwm one-shot rule changes to window ($window_id)..."
                  bspc node "$window_id" -l normal
                  bspc node "$window_id" -t ~floating
                  while window_is_hidden "$window_id"; do
                      bspc node "$window_id" -g hidden=off || wait_for_window "$window_id"
                  done
                  systemd-notify --status="Reverted bspwm one-shot rule changes to window ($window_id)."

                  # this second unmap seems to be necessary since sometimes,
                  # the unmap won't even work until the window is unhidden...
                  xdotool windowunmap "$window_id"
                  systemd-notify --status="Attempted to unmap window ($window_id)."

                  # and if that's all good and well, then we're finally ready!
                  ! window_is_hidden "$window_id" && exec systemd-notify --ready --status="Window ID: $window_id"

                  printf 'error: something happened to window %s. is it still there?\n' "$window_id" >&2
                  exit 127
              } &

              # restore environment
              export PATH="$old_PATH"
              unset \
                  WINDOW_CLASS \
                  WINDOW_CLASSNAME \
                  WINDOW_ROLE \
                  WINDOW_NAME \
                  NOTIFY_SOCKET \
                  old_PATH \
                  regex \
                  rule

              exec -- "$@"
            '';
        in
        {
          Type = "notify";
          NotifyAccess = "all";

          ExecStart = escapeSystemdExecArgs [ start-hide-notify command ];
          Environment =
            # same method used by NixOS's systemd service generation stuff
            # <nixpkgs/nixos/lib/systemd-lib.nix:498>
            lib.optional (class != null) (builtins.toJSON "WINDOW_CLASS=${class}")
            ++ lib.optional (className != null) (builtins.toJSON "WINDOW_CLASSNAME=${className}")
            ++ lib.optional (name != null) (builtins.toJSON "WINDOW_NAME=${name}")
            ++ lib.optional (role != null) (builtins.toJSON "WINDOW_ROLE=${role}")
          ;

          ExitType = "cgroup";
          Restart = "on-abnormal";

          # Don't restart if start-hide-notify exits with 127; this means that
          # there's some issue with the invocation that was given.
          RestartPreventExitStatus = 127;
        }
    ;
  };
}
