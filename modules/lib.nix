{ lib
, pkgs
, config
, ...
}:
with lib;
{
  config.lib.somasis = rec {
    floatToInt = float:
      let
        inherit (builtins) typeOf toString head tail splitVersion;
        inherit (lib) isFloat toIntBase10;
        inherit (lib.strings) escapeNixString;

        fractional = toIntBase10 (toString (tail (splitVersion (toString float))));
        whole = toIntBase10 (toString (head (splitVersion (toString float))));
      in
      assert (isFloat float);
      if fractional == 0 then
        whole
      else
        throw "floatToInt: Could not convert ${escapeNixString float} to integer."
    ;

    mkPathSafeName = replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

    commaList = concatMapStringsSep "," (lib.escape [ "," ]);

    # testCase -> TEST_CASE
    camelCaseToScreamingSnakeCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "_${c}") upperChars) ++ upperChars)
          x
    ;

    # testCase -> test_case
    camelCaseToSnakeCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "_${c}") lowerChars) ++ lowerChars)
          x
    ;

    # testCase -> test-case
    camelCaseToKebabCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "-${c}") lowerChars) ++ lowerChars)
          x
    ;

    # testCase -> TEST-CASE
    camelCaseToScreamingKebabCase = x:
      if toLower x == x then
        x
      else
        replaceStrings
          (upperChars ++ lowerChars)
          ((map (c: "-${c}") upperChars) ++ upperChars)
          x
    ;

    # test_case -> testCase
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
    programName = p: p.meta.mainProgram or p.pname or p.name;
    programPath = p: "${getBin p}/bin/${programName p}";


    generators = {
      toXML = attrs:
        let
          # xq requires that there be one XML root element; it must be specified as a command argument otherwise
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
              abort "generators.toXML: only one XML root element is allowed"
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
          ${getBin pkgs.yq-go}/bin/yq -p xml -o json --xml-strict-mode \
              | ${getBin config.programs.jq.package}/bin/jq -e '
                  if has("rss") then
                      del(.rss.channel.item[]["description", "encoded"])
                  elif has("feed") then
                      del(.feed.entry[]["content"])
                  else
                      .
                  end
              ' \
              | ${getBin pkgs.yq-go}/bin/yq -p json -o xml --xml-strict-mode
        '';
      };
    };
  };
}
