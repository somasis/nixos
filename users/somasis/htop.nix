{ config, ... }: {
  programs.htop = {
    enable = true;
    settings = {
      # Application settings
      color_scheme = 0;
      delay = 10;

      enable_mouse = 1;
      show_tabs_for_screens = 0;
      hide_function_bar = 1; # "Hide main function bar ... on ESC, until next input"

      # Meters - CPU meter
      cpu_count_from_one = 1;
      show_cpu_temperature = 1;
      show_cpu_frequency = 1;
      show_cpu_usage = 1;
      account_guest_in_cpu_meter = 1; # "Add guest time in CPU meter percentage"
      detailed_cpu_time = 0;
      degree_fahrenheit = 1;

      # Display options > Global options: on updates
      highlight_changes = 1;
      highlight_changes_delay_secs = 5;

      # Display options > Global options: listing
      show_program_path = 0;
      highlight_base_name = 1;
      show_merged_command = 1;
      find_comm_in_cmdline = 1;
      strip_exe_from_cmdline = 1; # Prevent names from being unreadable due to /nix/store prefix
      update_process_names = 1;
      shadow_other_users = 0;

      highlight_deleted_exe = 1; # "Highlight out-dated/removed programs / libraries"
      highlight_megabytes = 1; # "Highlight large numbers in memory counters"


      # Display options > Global options: threads
      hide_kernel_threads = 0;
      hide_userland_threads = 0;
      show_thread_names = 1;
      highlight_threads = 1; # "Display threads in a different color"

      # Display options > Tree view - tree view and sorting
      tree_view = 1;
      tree_view_always_by_pid = 0; # Don't default to sorting tree view by PID
      tree_sort_direction = 1; # Sort lowest to highest even in tree view
      tree_sort_key = 0;
      sort_direction = 0; # Sort lowest to highest
      sort_key = config.lib.htop.fields.PERCENT_CPU; # Sort by PID

      fields = with config.lib.htop.fields; [
        USER
        PID
        STATE
        NICE
        PRIORITY
        IO_PRIORITY
        PERCENT_CPU
        PERCENT_MEM
        IO_RATE
        COMM
      ];

      header_layout = "two_50_50";
      header_margin = 1;
    }
    // (with config.lib.htop;
      leftMeters [
        (bar "CPU")
        (bar "AllCPUs4")
        (bar "Memory")
        (bar "Zram")
        (text "Tasks")
        (text "LoadAverage")
      ])
    // (with config.lib.htop;
      rightMeters [
        (text "Hostname")
        (text "System")
        (text "SystemdState")
        (text "Uptime")
        (text "DiskIO")
        (text "ZFSCARC")
        (text "NetworkIO")
      ]);
  };

  # Silence warning about being unable to write to configuration file.
  programs.bash.shellAliases.htop = "2>/dev/null htop";

  services.sxhkd.keybindings."super + alt + Delete" =
    "terminal ${config.programs.htop.package}/bin/htop";
}
