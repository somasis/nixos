{ pkgs
, ...
}: {
  programs.jq.enable = true;

  # not using writeJqScript, as it produces a shell script
  home.file.".jq".text = ''
    # <https://rosettacode.org/wiki/URL_decoding#jq>
    def uri_decode:
      # The helper function converts the input string written in the given
      # "base" to an integer
      def to_i(base):
        explode
        | reverse
        | map(if 65 <= . and . <= 90 then . + 32  else . end)   # downcase
        | map(if . > 96  then . - 87 else . - 48 end)  # "a" ~ 97 => 10 ~ 87
        | reduce .[] as $c
            # base: [power, ans]
            ([1,0]; (.[0] * base) as $b | [$b, .[1] + (.[0] * $c)]) | .[1];

      .  as $in
      | length as $length
      | [0, ""]  # i, answer
      | until ( .[0] >= $length;
          .[0] as $i
          |  if $in[$i:$i+1] == "%"
             then [ $i + 3, .[1] + ([$in[$i+1:$i+3] | to_i(16)] | implode) ]
             else [ $i + 1, .[1] + $in[$i:$i+1] ]
             end)
      | .[1];  # answer
  '';

  home.shellAliases = {
    diff = "diff --color";
    g = "find -L ./ -type f \! -path '*/.*/*' -print0 | xe -0 -N0 grep -n";
    number = "nl -b a -d '' -f n -w 1";
  };

  home.packages = [
    pkgs.ellipsis
    pkgs.sqlite-interactive.bin
    pkgs.frangipanni
    pkgs.fx
    pkgs.ijq
    pkgs.json2nix
    pkgs.patchutils

    pkgs.lowdown

    pkgs.html-tidy
    pkgs.pup
    pkgs.xmlstarlet

    pkgs.table
    pkgs.ugrep

    pkgs.ini2nix
    pkgs.json2nix

    pkgs.yq-go
    pkgs.jc
  ];
}
