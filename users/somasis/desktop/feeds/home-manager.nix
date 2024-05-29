{ config
, lib
, pkgs
, ...
}:
let
  inherit (pkgs) runCommandLocal writeJqScript writeText;
  inherit (lib) makeBinPath;
  inherit (builtins) toJSON;
in
{
  news.display = "silent";

  programs.newsboat.urls = [{
    url = "file://${config.xdg.dataHome}/newsboat/home-manager-news.atom";
    tags = [ "computer" "nixos" ];
    title = "Home Manager";
  }];

  xdg.dataFile."newsboat/home-manager-news.atom".source = runCommandLocal "home-manager-news.atom"
    {
      filter = writeJqScript "home-manager-news-filter" { } ''
        map(select(.condition == true))
            | sort_by(.time)
            | map(
                . + {
                # Generate titles for feed items
                #   1. Strip any ending punctuation (for when it's a short message)
                #   2. Crudely un-hardwrap the first line of the message
                #   3. Keep only the first line of the message
                #   4. Remove any remaining ending punctuation
                  title: (
                      .message
                          | sub("\\.?\n$|:\n.*"; ""; "p")
                          | sub(
                              "(?<pre>[^\\s]+)\n(?<suf>[^\n]+).*";
                              "\(.pre) \(.suf)";
                              "pg"
                          )
                          | rtrimstr(".")
                          | sub("\\. .*"; ""; "p")
                  )
                }
            )
            | map_values(.id = (.time + .message | @base64))
            # Now, shape our input in terms that yq can output as xml
            | {
                feed: {
                  "+@xmlns": "http://www.w3.org/2005/Atom",
                  title: "home-manager",
                  updated: (map(.time) | sort | last),
                  entry: map(
                    {
                      id,
                      updated: .time,
                      title: { "+@type": "text", "+content": .title },
                      content: { "+@type": "text/plain", "+content": .message }
                    }
                  )
                }
            }
      '';

      json = writeText "home-manager-news.json" (toJSON config.news.entries);
    } ''
    $filter < $json > filtered.json
    ${pkgs.yq-go}/bin/yq --input-format json --output-format xml --xml-strict-mode < filtered.json > $out
  '';
}
