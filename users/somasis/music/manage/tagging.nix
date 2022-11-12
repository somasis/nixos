{ pkgs
, library
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

      # Allow for using barcodes (for when I have physical media)
      "barcode"

      # Fetch release artwork
      "fetchart"

      # Fetch artist artwork
      "fetchartist"

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
    ];

    artist_credit = true;
    asciify_paths = true;
    original_date = true;

    import = {
      # Search
      languages = [ "tok" "en" "jp" ];

      # Interactive mode
      bell = true;
      detail = true;

      # File manipulation
      write = true;
      copy = true;
      move = false;

      incremental = true;
      resume = false;

      log = "${library.lossless}/beets.log";
    };

    paths =
      let stem = "$album%if{$year, ($year)}/$track - $artist - $title"; in
      rec {
        default = "$albumartist - ${stem}";
        "comp:true" = "_compilation/${stem}";
        "albumtype:soundtrack" = "_soundtrack/${stem}";

        "singleton:true" = "_single/$artist/$title%if{$year, ($year)}";

        "sample:true" = "_sample/${default}";
      };

    musicbrainz = {
      genres = true;
      extra_tags = [
        "catalognum"
        "country"
        "label"
        "media"
        "year"
      ];

      searchlimit = 15;
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

    fetchartist.filename = "poster";

    fetchart = {
      cautious = true;
      high_resolution = true;
      store_source = true;

      cover_names = [ "cover" "front" "art" "album" "folder" ];

      sources = [
        "filesystem"
        { coverart = "release releasegroup"; }
        "itunes"
        "amazon"
      ];
    };

    lastgenre = {
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

    replaygain.backend = "ffmpeg";

    types = {
      rating = "float";
      sample = "bool";
    };
  };
}
