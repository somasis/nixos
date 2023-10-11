{ lib
, pkgs
, config
, ...
}:
with lib;
{
  config.lib.somasis = rec {
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

    # Make a string safe for usage as a systemd path.
    # Ripped from nixpkgs' systemd.nix module.
    #
    # Type: mkPathSafeName :: str -> str
    mkPathSafeName = replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

    # Create a comma,separated,string from a list.
    #
    # Type: commaList :: list -> str
    commaList = concatMapStringsSep "," (lib.escape [ "," ]);

    # Convert a camelCaseString to a SCREAMING_SNAKE_CASE_STRING.
    #
    # Type: camelCaseToScreamingSnakeCase :: str -> str
    camelCaseToScreamingSnakeCase = x:
      if toLower x == x then
        x
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
              pkgs.runCommand "xml"
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
    greasemonkey.jhide = list: pkgs.runCommandLocal "jhide.user.js" { } ''
      ${lib.getExe pkgs.jhide} \
          -o $out \
          ${lib.escapeShellArgs (
            map
              (lib.replaceStrings [ "file://" ] [ "" ])
              (if lib.isList list then list else [ list ])
          )}
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
  };
}
