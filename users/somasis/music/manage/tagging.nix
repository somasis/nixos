{ config
, pkgs
, music
, ...
}: {
  programs.beets.settings = {
    plugins = [
      # Analyze/submit data for tracks missing in the AcoustID database
      "absubmit"

      # Fetch AcoustID data for tracks during import
      "acousticbrainz"

      # Check for corruption during importing
      "badfiles"

      # Fetch release artwork
      "fetchart"

      # Use filenames as hint for importer
      "fromfilename"

      # Preserve modification times of imported music
      "importadded"

      # Fetch genres from Last.fm
      "lastgenre"

      # Fetch/display lyrics
      "lyrics"

      # Keep my MusicBrainz library collection in sync with the library
      "mbcollection"

      # Add a "print tracks" option to the importer prompt
      "mbsubmit"

      # Keep tags in the library in sync with MusicBrainz data
      "mbsync"

      # Use origin.yaml as hint for importer
      "originquery"

      # Calculate/apply ReplayGain
      "replaygain"

      # Add custom fields
      "types"

      # Remove particular fields from imported files (used for ensuring no embedded art)
      "zero"

      # FIXME: broken plugins
      # "bandcamp" # Allow for using bandcamp as an autotagger source
      # "fetchartist" # Fetch artist artwork
    ];

    artist_credit = true;
    asciify_paths = true;
    original_date = true;

    import = {
      languages = [ "tok" "en" "jp" ];

      # Interactive mode
      bell = true;
      detail = true; # Always show release details during import

      # File manipulation
      write = true; # write tags to the files when they're updated
      copy = true; # copy files to the library during importing

      incremental = true;

      # Always start over imports of half-imported releases
      resume = false;

      log = "${config.xdg.userDirs.music}/lossless/beets.log";
    };

    paths =
      let stem = "$album%if{$year, ($year)}/$track - $artist - $title"; in
      rec {
        default = "$albumartist - ${stem}";
        "comp" = "_compilation/${stem}";
        "singleton" = "_single/$artist/$title%if{$year, ($year)}";

        "albumtype:soundtrack" = "_soundtrack/${stem}";

        "sample:true" = "_sample/${default}";
      };

    match.max_rec = {
      # Don't rate media that differs from our guess with anymore than medium confidence
      media = "medium";
      unmatched_tracks = "medium";
    };

    musicbrainz = {
      # NOTE: conflicts with lastgenre
      # genres = true;
      extra_tags = [
        "catalognum"
        "country"
        "label"
        "media"
        "year"
      ];

      searchlimit = 10;
    };

    absubmit = {
      auto = true;
      extractor = "${pkgs.essentia-extractor}/bin/streaming_extractor_music";
    };

    badfiles = {
      check_on_import = true;

      commands = {
        flac = "${pkgs.flac}/bin/flac -s -tw";
        ogg = "${pkgs.liboggz}/bin/oggz-validate -M 0";
        opus = "${pkgs.liboggz}/bin/oggz-validate -M 0";
      };
    };

    bandcamp = {
      art = true;
      genre.mode = "progressive";
    };

    fetchartist.filename = "poster";

    fetchart = {
      auto = true;

      cautious = true;
      high_resolution = true;
      store_source = true;

      cover_names = [ "cover" "front" "art" "album" "folder" ];

      sources = [
        "filesystem"
        "bandcamp"
        { coverart = "release releasegroup"; }
        "itunes"
        "amazon"
      ];
    };

    importadded.preserve_mtimes = true;

    lastgenre = {
      auto = true;

      count = 5;
      prefer_specific = true;
      title_case = false;
    };

    mbcollection = {
      auto = true;

      collection = "222377a0-7e41-4ccf-ba15-0748731106c4";
      remove = true;
    };

    originquery = {
      origin_file = "origin.yaml";

      tag_patterns = {
        media = ''$.Media'';
        year = ''$."Edition year"'';
        label = ''$."Record label"'';
        catalognum = ''$."Catalog number"'';
        albumdisambig = ''$.Edition'';
      };

      use_origin_on_conflict = true;
    };

    replaygain = {
      auto = true;

      backend = "ffmpeg";
    };

    types = {
      rating = "float";
      sample = "bool";
    };

    # Ensure there is never art left embedded in imported files.
    zero = {
      auto = true;

      fields = [
        "images"
        "genre"
      ];
      update_database = true;
    };
  };
}
