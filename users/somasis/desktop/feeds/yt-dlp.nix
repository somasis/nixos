{ config
, pkgs
, lib
, ...
}:
let
  inherit (config.lib.somasis) feeds writeJqScript;
  inherit (lib) makeBinPath;
  inherit (pkgs) writeShellScript;

  yt-dlp =
    { url
    , title ? null
    , tags ? [ ]
    , filter ? null
    }:
    let
      parse = writeJqScript "parse-yt-dlp-json" { slurp = true; } ''
        {
          "+p_xml": "version=\"1.0\" encoding=\"UTF-8\"",
          feed: {
            "+@xmlns": "http://www.w3.org/2005/Atom",
            link: {
              "+@rel": "alternate",
              "+@href": .[0].uploader_url
            },
            id: "\(.[0].extractor):\(.[0].uploader_id)",
            title: "\(.[0].extractor): \(.[0].channel // .[0].playlist_title)",
            author: {
              name: (.[0].uploader // .[0].playlist_uploader),
              uri: .[0].uploader_url
            },
            updated: (
              if (.[0].upload_date // null) != null then
                .[0].upload_date | "\(.[0:4])-\(.[4:6])-\(.[6:8])T00:00:00Z"
              else
                .[0].epoch
              end
            ),
            entry: map(
              {
                id,
                title: "[\(.duration_string)] \(.title)",
                updated: (
                  if (.upload_date // null) != null then
                    .upload_date | "\(.[0:4])-\(.[4:6])-\(.[6:8])T00:00:00Z"
                  else
                    .epoch
                  end
                ),
                author: { name: (.uploader // .playlist_uploader), uri: .uploader_url },
                link: { "+@href": .webpage_url }
              }
              * (
                if .description != "" then
                  { content: { "+@type": "text", "+content": .description } }
                else
                  {}
                end
              )
            )
          }
        }
      '';

      generate = writeShellScript "generate-yt-dlp" ''
        PATH=${makeBinPath [ config.programs.yt-dlp.package config.programs.jq.package pkgs.yq-go ]}:$PATH

        last="$XDG_CACHE_HOME"/newsboat/yt-dlp
        mkdir -p "$last"
        last="$last"/"$(sha256sum <<< "$1" | cut -d' ' -f1)".last
        touch "$last"
        [[ -s "$last" ]] && date=$(cat "$last") || date=$(date --utc +%Y%m%d)

        runtime=$(mktemp -d)
        trap 'cd /; rm -rf "$runtime"' EXIT

        cd "$runtime"

        yt-dlp -sj --dateafter "$date" "$1" | ifne ${parse} | ifne sponge filtered.json
        [[ "$#" -gt 0 ]] && jq "''${1:-.}" filtered.json | ifne sponge filtered.json
        yq -p json -o xml --xml-strict-mode < filtered.json
        date --utc +%Y%m%d >"$last"
      '';

      generateWithURL = writeShellScript "generate-yt-dlp-with-url" "${generate} ${lib.escapeShellArg url}";
    in
    {
      url = feeds.urls.exec generateWithURL;
      inherit title;
      inherit tags;
    }
  ;
in
{
  # cache.directories = [ "var/cache/newsboat/yt-dlp" ];
  programs.newsboat.urls = [
    # YouTube
    (yt-dlp {
      url = "https://www.youtube.com/CathodeRayDude";
      tags = [ "youtube" "tech" ];
    })
    (yt-dlp {
      url = "https://www.youtube.com/RoadGuyRob";
      tags = [ "youtube" "urbanism" ];
    })
    (yt-dlp {
      url = "https://www.youtube.com/brutalmoose";
      tags = [ "youtube" ];
    })
    (yt-dlp {
      url = "https://www.youtube.com/TechnologyConnections";
      tags = [ "youtube" "technology" ];
    })
    (yt-dlp {
      url = "https://www.youtube.com/GeoWizard";
      tags = [ "youtube" "geography" ];
    })
  ];
}