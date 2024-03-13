{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  retroarchCache = "${config.xdg.cacheHome}/retroarch";
  retroarchConfig = "${config.xdg.configHome}/retroarch";
  retroarchData = "${config.xdg.dataHome}/retroarch";

  settingsRender = lib.mapAttrs (n: v: lib.generators.mkValueStringDefault { } v);

  settings = rec {
    # Miscellaneous
    gamemode_enable = osConfig.programs.gamemode.enable;
    settings_show_drivers = false;
    video_fullscreen = false;
    video_window_opacity = 100;
    video_window_show_decorations = true;
    video_windowed_fullscreen = true;

    # Video
    settings_show_video = false;
    video_adaptive_vsync = true;
    video_allow_rotate = false;
    video_rotation = 0;
    video_aspect_ratio = "1.333300";
    video_aspect_ratio_auto = false;
    video_autoswitch_refresh_rate = 0;
    video_bfi_dark_frames = 1;
    video_black_frame_insertion = 0;
    video_crop_overscan = true;
    video_ctx_scaling = false;
    video_disable_composition = false;
    video_font_enable = true;
    video_font_size = "13.000000";
    video_force_aspect = true;
    video_force_srgb_disable = true;
    video_frame_delay = 0;
    video_frame_delay_auto = true;
    video_frame_rest = false;
    video_max_frame_latency = 1;
    video_max_swapchain_images = 3;
    video_scale = 3;
    video_scale_integer = false;
    video_scale_integer_overscale = false;

    video_shader_enable = false;
    video_shader_preset_save_reference_enable = true;
    video_shader_remember_last_dir = true;
    video_shader_watch_files = false;
    video_shared_context = true;

    video_smooth = false;

    video_swap_interval = 0; # VSync Swap Interval: set based on core-reported frame rate
    video_vsync = true;
    video_waitable_swapchains = true;


    # Audio
    audio_driver = "alsa";
    microphone_driver = "alsa";
    midi_driver = lib.optionalString config.programs.timidity.enable "alsa";
    settings_show_audio = false;
    audio_enable = true;
    audio_enable_menu = true;
    audio_enable_menu_bgm = false;
    audio_enable_menu_cancel = true;
    audio_enable_menu_notice = true;
    audio_enable_menu_ok = true;
    audio_enable_menu_scroll = false;
    audio_rate_control = true;
    audio_sync = true;

    audio_resampler = "nearest";
    audio_resampler_quality = 2; # lowest
    microphone_resampler = "nearest";
    microphone_resampler_quality = 2; # lowest

    auto_overrides_enable = true;
    auto_remaps_enable = true;
    auto_shaders_enable = true;
    input_remap_binds_enable = true;
    notification_show_config_override_load = true;
    notification_show_remap_load = true;
    quick_menu_show_save_content_dir_overrides = true;
    quick_menu_show_save_core_overrides = false;
    quick_menu_show_save_game_overrides = true;
    remap_save_on_exit = true;

    # Input
    input_driver = "udev";
    input_joypad_driver = "udev";
    menu_driver = "ozone";
    enable_device_vibration = true;
    input_autodetect_enable = true;
    input_duty_cycle = 3;
    input_max_users = 16;

    # Automatically choose home button for menu toggle
    input_menu_toggle = "escape";
    input_menu_toggle_btn = "nul";
    input_menu_toggle_gamepad_combo = 0;

    input_auto_mouse_grab = false;
    input_auto_game_focus = 0;

    input_poll_type_behavior = 0;
    input_rumble_gain = 65;
    input_sensors_enable = true;
    keyboard_gamepad_enable = true;
    keyboard_gamepad_mapping_type = 1;
    menu_unified_controls = true;
    settings_show_input = true;

    # RetroAchievements
    cheevos_enable = true;
    cheevos_appearance_anchor = 0;
    cheevos_appearance_padding_auto = true;
    cheevos_auto_screenshot = true;
    cheevos_badges_enable = false;
    cheevos_challenge_indicators = true;
    cheevos_hardcore_mode_enable = true;
    cheevos_richpresence_enable = true;
    cheevos_start_active = false;
    cheevos_unlock_sound_enable = false;
    cheevos_visibility_account = true;
    cheevos_visibility_lboard_cancel = true;
    cheevos_visibility_lboard_start = true;
    cheevos_visibility_lboard_submit = true;
    cheevos_visibility_lboard_trackers = true;
    cheevos_visibility_mastery = true;
    cheevos_visibility_progress_tracker = true;
    cheevos_visibility_summary = 1;
    cheevos_visibility_unlock = true;
    discord_allow = true;

    # Thumbnails
    network_on_demand_thumbnails = true;
    menu_show_legacy_thumbnail_updater = false;
    menu_left_thumbnails = 2; # boxart
    menu_thumbnails = 2; # title screen
    menu_thumbnail_upscale_threshold = 0;
    ozone_thumbnail_scale_factor = "1.000000";
    quick_menu_show_download_thumbnails = false;

    # Recording, screenshots
    auto_screenshot_filename = true;
    input_screenshot = "f12";
    notification_show_screenshot = true;
    notification_show_screenshot_duration = 1;
    notification_show_screenshot_flash = 2;
    quick_menu_show_take_screenshot = true;
    recording_config_directory = "${retroarchData}/recording_config";
    recording_output_directory = "${retroarchData}/recordings";
    screenshot_directory = "${retroarchData}/screenshots";
    screenshots_in_content_dir = false;
    sort_screenshots_by_content_enable = false;
    video_gpu_record = true;
    video_gpu_screenshot = true;
    video_post_filter_record = true;
    video_record_quality = 2;
    video_record_scale_factor = 1;
    video_record_threads = 2;

    # Saves
    autosave_interval = 15; # SaveRAM autosave interval
    block_sram_overwrite = false;
    camera_allow = true;
    check_firmware_before_loading = true;
    config_save_on_exit = true;

    # Image viewer, video, music, etc.
    builtin_imageviewer_enable = true;
    builtin_mediaplayer_enable = true;
    content_show_images = false;
    content_show_music = false;
    content_show_video = false;
    content_video_directory = config.xdg.userDirs.videos;
    content_image_history_directory = content_history_directory;
    content_music_history_directory = content_history_directory;
    content_video_history_directory = content_history_directory;
    content_image_history_path = "${content_image_history_directory}/content_image_history.lpl";
    content_music_history_path = "${content_music_history_directory}/content_music_history.lpl";
    content_video_history_path = "${content_video_history_directory}/content_video_history.lpl";

    # Playlists

    # Ensure playlists are readable from text editors, and portable
    # across different machines; no compression, portable paths
    playlist_compression = false;
    playlist_portable_paths = true;
    # poorly named; this is the file browser's default directory; this gets
    # used used by portable playlists as the root to start searching from
    rgui_browser_directory = "${retroarchData}/roms";
    show_hidden_files = true;

    playlist_directory = "${retroarchConfig}/playlists";
    playlist_entry_remove_enable = 1;
    playlist_entry_rename = true;
    playlist_fuzzy_archive_match = true;
    playlist_show_entry_idx = true;
    playlist_show_history_icons = 0;
    playlist_show_inline_core_name = 2;
    playlist_show_sublabels = true;
    playlist_sort_alphabetical = true;
    playlist_sublabel_last_played_style = 15;
    playlist_sublabel_runtime_type = 1;
    playlist_use_filename = false;

    content_favorites_size = "-1";
    content_favorites_directory = playlist_directory;
    content_favorites_path = "${playlist_directory}/content_favorites.lpl";

    history_list_enable = true;
    content_history_size = 100;
    content_history_directory = "${retroarchCache}/history";
    content_history_path = "${content_history_directory}/content_history.lpl";

    dynamic_wallpapers_directory = "${retroarchData}/dynamic_wallpapers";
    osk_overlay_directory = "${retroarchData}/keyboard_overlays";
    overlay_directory = "${retroarchData}/overlays";

    thumbnails_directory = "${retroarchCache}/thumbnails";
    audio_filter_dir = "${retroarchData}/filters/audio";
    video_filter_dir = "${retroarchData}/filters/video";
    video_layout_directory = "${retroarchData}/layouts";
    video_shader_dir = "${retroarchData}/shaders";

    runtime_log_directory = "${retroarchData}/runtime";
    savefile_directory = "${retroarchData}/saves";
    savestate_directory = "${retroarchData}/savestates";


    system_directory = "${retroarchData}/system";
    systemfiles_in_content_dir = false;

    cache_directory = "/tmp";
    core_assets_directory = "/var/empty";
    content_database_path = "${retroarchData}/database/rdb";
    cheat_database_path = "${retroarchData}/cheats";

    # Core configuration and remap files
    rgui_config_directory = "${retroarchConfig}/configs";
    input_remapping_directory = "${retroarchConfig}/configs/remaps";

    log_dir = "${retroarchCache}/logs";
    log_verbosity = true;
    settings_show_logging = false;
    frontend_log_level = 0; # verbose
    libretro_log_level = 0; # verbose

    # ROMs/content, saves, statistics
    content_runtime_log = false;
    content_runtime_log_aggregate = true;
    content_show_add = true;
    content_show_add_entry = 2;
    content_show_contentless_cores = 0;
    content_show_explore = true;
    content_show_favorites = true;
    content_show_history = true;
    content_show_netplay = false;
    content_show_playlists = true;
    content_show_settings = true;
    core_info_savestate_bypass = false;
    core_option_category_enable = true;
    core_set_supports_no_game_enable = true;
    filter_by_current_core = true;
    game_specific_options = true;
    load_dummy_on_core_shutdown = true;
    menu_savestate_resume = true;
    notification_show_save_state = true;
    quick_menu_show_save_load_state = false;
    quick_menu_show_savestate_submenu = false;
    quick_menu_show_undo_save_load_state = false;
    save_file_compression = true;

    savefiles_in_content_dir = false;
    savestate_auto_index = true;
    savestate_auto_load = true;
    savestate_auto_save = true;
    savestate_file_compression = true;
    savestate_max_keep = 5;
    savestates_in_content_dir = false;
    savestate_thumbnail_enable = true;
    scan_serial_and_crc = true;
    scan_without_core_match = true;
    sort_savefiles_by_content_enable = true;
    sort_savefiles_enable = false;
    sort_savestates_by_content_enable = true;
    sort_savestates_enable = false;

    # Menu
    desktop_menu_enable = false;
    menu_battery_level_enable = true;
    menu_core_enable = true;
    menu_disable_info_button = false;
    menu_disable_search_button = true;
    menu_dynamic_wallpaper_enable = true;
    menu_enable_widgets = true;
    menu_footer_opacity = "1.000000";
    menu_framebuffer_opacity = "0.950000";
    menu_header_opacity = "1.000000";
    menu_horizontal_animation = true;
    menu_insert_disk_resume = true;
    menu_linear_filter = false;
    menu_mouse_enable = true; # enable mouse interaction with menu
    menu_navigation_browser_filter_supported_extensions_enable = true;
    menu_navigation_wraparound_enable = true;
    menu_pause_libretro = true;
    menu_pointer_enable = true; # enable touch interaction with menu
    menu_remember_selection = 1;
    menu_scale_factor = "1.150000";
    menu_screensaver_animation = 1;
    menu_screensaver_animation_speed = "0.700000";
    menu_screensaver_timeout = 1800;
    menu_scroll_delay = 256;
    menu_scroll_fast = false;
    menu_shader_pipeline = 2;
    menu_show_advanced_settings = true;
    menu_show_configurations = true;
    menu_show_core_updater = false;
    menu_show_dump_disc = true;
    menu_show_help = false;
    menu_show_information = true;
    menu_show_latency = false;
    menu_show_load_content = true;
    menu_show_load_content_animation = true;
    menu_show_load_core = true;
    menu_show_load_disc = true;
    menu_show_online_updater = false;
    menu_show_overlays = false;
    menu_show_quit_retroarch = true;
    menu_show_reboot = true;
    menu_show_restart_retroarch = true;
    menu_show_rewind = false;
    menu_show_shutdown = true;
    menu_show_sublabels = true;
    menu_show_video_layout = false;
    menu_swap_ok_cancel_buttons = false;
    menu_swap_scroll_buttons = false;
    menu_throttle_framerate = true;
    menu_ticker_smooth = true;
    menu_ticker_speed = "2.999999"; # 3.0x ticker speed
    menu_ticker_type = 1;
    menu_timedate_date_separator = 0;
    menu_timedate_enable = true;
    menu_timedate_style = 17;
    menu_widget_scale_auto = true;
    notification_show_autoconfig = true;
    notification_show_cheats_applied = true;
    notification_show_fast_forward = true;
    notification_show_patch_applied = true;
    notification_show_refresh_rate = true;
    notification_show_set_initial_disk = true;
    notification_show_when_menu_is_alive = false;
    ozone_collapse_sidebar = false;
    ozone_menu_color_theme = 10;
    ozone_scroll_content_metadata = true;
    ozone_sort_after_truncate_playlist_name = false;
    ozone_truncate_playlist_name = true;
    pause_nonactive = false;
    pause_on_disconnect = true;
    quick_menu_show_add_to_favorites = true;
    quick_menu_show_cheats = true;
    quick_menu_show_close_content = true;
    quick_menu_show_controls = true;
    quick_menu_show_core_options_flush = true;
    quick_menu_show_information = true;
    quick_menu_show_options = true;
    quick_menu_show_recording = true;
    quick_menu_show_replay = false;
    quick_menu_show_reset_core_association = true;
    quick_menu_show_restart_content = true;
    quick_menu_show_resume_content = true;
    quick_menu_show_set_core_association = true;
    quick_menu_show_shaders = true;
    quick_menu_show_start_recording = true;
    quick_menu_show_start_streaming = false;
    quick_menu_show_streaming = true;
    quit_on_close_content = 0;
    quit_press_twice = true;

    # Misc
    netplay_nickname = config.home.username;
    fastforward_frameskip = true;
    fastforward_ratio = "1.000000";
    gamma_correction = 0;
    run_ahead_enabled = false;
    run_ahead_frames = 1;
    run_ahead_hide_warnings = true;
    run_ahead_secondary_instance = true;
    settings_show_accessibility = true;
    settings_show_achievements = true;
    settings_show_ai_service = true;
    settings_show_configuration = true;
    settings_show_core = true;
    settings_show_directory = false;
    settings_show_file_browser = true;
    settings_show_frame_throttle = true;
    settings_show_latency = true;
    settings_show_network = true;
    settings_show_onscreen_display = true;
    settings_show_playlists = true;
    settings_show_power_management = true;
    settings_show_recording = true;
    settings_show_saving = true;
    settings_show_user = true;
    settings_show_user_interface = true;
    slowmotion_ratio = "3.000000";
    statistics_show = false;
    suspend_screensaver_enable = true;
    sustained_performance_mode = false;
    threaded_data_runloop_enable = true;
    ui_menubar_enable = false;
    use_last_start_directory = true;


  };

  # secret-retroarch = pkgs.writeShellApplication {
  #   name = "secret-retroarch";
  #   runtimeInputs = [
  #     config.programs.password-store.package
  #   ];

  #   text = ''
  #     username=$(pass meta www/retroachievements.org username)
  #     password=$(pass meta www/retroachievements.org password)

  #     printf '%s = "%s"\n' \
  #         cheevos_username "$username" \
  #         cheevos_password "$password"
  #   '';
  # };

  retroarch =
    assert (osConfig.hardware.opengl.enable);
    assert (osConfig.services.udev.enable && osConfig.hardware.uinput.enable);
    assert (builtins.elem "input" osConfig.users.users.${config.home.username}.extraGroups);
    # pkgs.wrapCommand { package =
    pkgs.retroarch.override (prev: {
      cores = with pkgs.libretro; [
        stella # Atari - 2600
        virtualjaguar # Atari - Jaguar
        prboom # DOOM
        mame # MAME
        freeintv # Mattel - Intellivision
        mgba # Nintendo - Game Boy Advance
        sameboy # Nintendo - Game Boy / Nintendo - Game Boy Color
        dolphin # Nintendo - GameCube / Nintendo - Wii
        citra # Nintendo - Nintendo 3DS
        mupen64plus # Nintendo - Nintendo 64
        parallel-n64 # Nintendo - Nintendo 64 (Dr. Mario 64)
        melonds # Nintendo - Nintendo DS
        mesen # Nintendo - Nintendo Entertainment System / Nintendo - Family Computer Disk System
        snes9x # Nintendo - Super Nintendo Entertainment System
        picodrive # Sega - 32X
        flycast # Sega - Dreamcast
        genesis-plus-gx # Sega - Mega-Drive - Genesis
        beetle-saturn # Sega - Saturn
        swanstation # Sony - PlayStation
        pcsx2 # Sony - PlayStation 2
        ppsspp # Sony - PlayStation Portable
      ];

      settings = prev.settings // settingsRender settings
      ;
    });
  # wrappers = [{ prependFlags = "--appendconfig=<(${secret-retroarch}/bin/secret-retroarch)"; }]; };
in
{
  home.packages = [ retroarch ];

  # xsession.windowManager.bspwm.rules."retroarch" = {
  #   state = "fullscreen";
  #   layer = "above";
  #   monitor = "primary";
  # };

  cache.directories =
    map
      (dir: { method = "symlink"; directory = config.lib.somasis.relativeToHome dir; })
      [
        settings.audio_filter_dir
        settings.dynamic_wallpapers_directory
        settings.osk_overlay_directory
        settings.overlay_directory
        settings.thumbnails_directory
        settings.video_filter_dir
        settings.video_layout_directory
        settings.video_shader_dir
        settings.cheat_database_path
      ]
  ;

  log.directories =
    map
      (dir: { method = "symlink"; directory = config.lib.somasis.relativeToHome dir; })
      [
        settings.content_history_directory
        settings.content_favorites_directory
        settings.content_image_history_directory
        settings.content_music_history_directory
        settings.content_video_history_directory

        settings.recording_config_directory
        settings.recording_output_directory
        settings.runtime_log_directory

        settings.log_dir
      ]
  ;

  persist = {
    files = [ (config.lib.somasis.xdgConfigDir "retroarch/retroarch.cfg") ];

    directories =
      (map
        (dir: { method = "symlink"; directory = config.lib.somasis.relativeToHome dir; })
        [
          settings.playlist_directory
          settings.savefile_directory
          settings.savestate_directory
          settings.screenshot_directory
          settings.system_directory
          settings.input_remapping_directory
          settings.content_database_path
          settings.rgui_browser_directory
        ]
      )
      ++ [{
        method = "symlink";
        directory = config.lib.somasis.relativeToHome "${retroarchData}/roms";
      }]
      ++ [{
        method = "bindfs";
        directory = config.lib.somasis.relativeToHome settings.rgui_config_directory;
      }]
    ;
  };
}
