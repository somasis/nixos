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
          ''"'' + escape [ "\"" ] (concatMapStringsSep ":" (escape [ ":" ]) strings') + ''"''
        ;

        exec = command: special {
          type = "exec";
          value = "${command}";
        };

        filter = urlToFilter: filterProgram: special {
          type = "filter";
          value = filterProgram;
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
        discardContent = pkgs.writeShellScript "filter-discard-content" ''
          ${getExe pkgs.yq-go} -p xml -o json --xml-strict-mode \
              | ${getExe config.programs.jq.package} -e '
                  if has("rss") then
                      del(.rss.channel.item[]["description", "encoded"])
                  elif has("feed") then
                      del(.feed.entry[]["content"])
                  else
                      .
                  end
              ' \
              | ${getExe pkgs.yq-go} -p json -o xml --xml-strict-mode
        '';
      };
    };

    colors = rec {
      format = format: color:
        assert (lib.isString format);
        assert (lib.isString color);

        lib.fileContents (pkgs.runCommandLocal "color"
          { inherit color format; }
          # strip out the spaces because some things don't support spaces in rgb/hsl/etc.
          # type formats, and the things that do support spaces tend to allow no spaces.
          ''${lib.getExe pkgs.pastel} format "$format" "$color" > "$out" | tr -d " "''
        );

      hex = format "hex";
      rgb = format "rgb";

      amountOp = operation: amount: color:
        assert (lib.isString operation);
        assert (lib.isFloat amount);
        assert (lib.isString color);

        lib.fileContents (pkgs.runCommandLocal "color"
          { inherit operation amount color; }
          ''${lib.getExe pkgs.pastel} "$operation" "$amount" "$color" > "$out"''
        );

      saturate = amountOp "saturate";
      desaturate = amountOp "desaturate";
      lighten = amountOp "lighten";
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

    drvOrPath = x:
      if ! lib.isDerivation x then
        pkgs.writeText (builtins.baseNameOf x) (builtins.readFile x)
      else
        x
    ;
  };
}
