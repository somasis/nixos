{ config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (inputs) loujine-musicbrainz murdos-musicbrainz;
in
{
  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    # (loujine-musicbrainz + /acoustid-merge-recordings.user.js)
    # (loujine-musicbrainz + /mb-display_count_alias.user.js)
    # (loujine-musicbrainz + /mb-display_rg_timeline.user.js)
    # (loujine-musicbrainz + /mb-display_sortable_table.user.js)
    # (loujine-musicbrainz + /mb-display_split_recordings.user.js)
    # (loujine-musicbrainz + /mb-display_work_relations_for_artist_recordings.user.js)
    # (loujine-musicbrainz + /mb-edit-add_aliases.user.js)
    # (loujine-musicbrainz + /mb-edit-change_release_quality.user.js)
    # (loujine-musicbrainz + /mb-edit-create_from_wikidata.user.js)
    # (loujine-musicbrainz + /mb-edit-create_release_from_recording.user.js)
    # (loujine-musicbrainz + /mb-edit-create_work_arrangement.user.js)
    # (loujine-musicbrainz + /mb-edit-edit_subworks.user.js)
    # (loujine-musicbrainz + /mb-edit-fill_event_setlist.user.js)
    # (loujine-musicbrainz + /mb-edit-merge_from_acoustid.user.js)
    # (loujine-musicbrainz + /mb-edit-replace_rec_artist_from_release_page.user.js)
    # (loujine-musicbrainz + /mb-edit-replace_rec_artist_from_work_page.user.js)
    # (loujine-musicbrainz + /mb-edit-seed_event_from_recording.user.js)
    # (loujine-musicbrainz + /mb-edit-set_video_recordings.user.js)
    # (loujine-musicbrainz + /mb-edit-set_work_aliases.user.js)
    # (loujine-musicbrainz + /mb-edit-set_work_attributes.user.js)
    # (loujine-musicbrainz + /mb-importer-hyperion.user.js)
    # (loujine-musicbrainz + /mb-reledit-clone_relations.user.js)
    # (loujine-musicbrainz + /mb-reledit-copy_dates.user.js)
    # (loujine-musicbrainz + /mb-reledit-guess_works.user.js)
    # (loujine-musicbrainz + /mb-reledit-release_rel_to_recording_rel.user.js)
    # (loujine-musicbrainz + /mb-reledit-set_instruments.user.js)
    # (loujine-musicbrainz + /mb-reledit-set_relation_attrs.user.js)
    # (loujine-musicbrainz + /mbz-idagio-importer.user.js)

    # (murdos-musicbrainz + /batch-add-recording-relationships.user.js)
    # (murdos-musicbrainz + /beatport_classic_importer.user.js)
    # (murdos-musicbrainz + /beatport_importer.user.js)
    # (murdos-musicbrainz + /cdbaby_importer.user.js)
    # (murdos-musicbrainz + /deezer_importer.user.js)
    (murdos-musicbrainz + /discogs_importer.user.js)
    # (murdos-musicbrainz + /edit-instrument-recordings-links.user.js)
    # (murdos-musicbrainz + /expand-collapse-release-groups.user.js)
    (murdos-musicbrainz + /fast-cancel-edits.user.js)
    # (murdos-musicbrainz + /hdtracks_importer.user.js)
    # (murdos-musicbrainz + /juno_download_importer.user.js)
    # (murdos-musicbrainz + /mb_1200px_caa.user.js)
    (murdos-musicbrainz + /mb_discids_detector.user.js)
    (murdos-musicbrainz + /mb_ui_enhancements.user.js)
    # (murdos-musicbrainz + /naxos_library3_importer.user.js)
    # (murdos-musicbrainz + /naxos_library_importer.user.js)
    # (murdos-musicbrainz + /set-recording-comments.user.js)
    # (murdos-musicbrainz + /vgmdb_importer.user.js)

    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_AUTO-FOCUS-KEYBOARD-SELECT.user.js)
    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_REDIRECT-WHEN-UNIQUE-RESULT.user.js)
    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_ELEPHANT-EDITOR.user.js)
  ];
}
