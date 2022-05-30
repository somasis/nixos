{ pkgs
, ...
}: {
  home.packages = with pkgs.gnomeExtensions; [
    # advanced-alttab-window-switcher
    # audio-output-switcher
    # dash-to-dock
    # dim-on-battery-power
    # fullscreen-avoider
    # jiggle
    # simply-workspaces
    # toggle-mute-on-middle-click
    adjust-display-brightness
    appindicator
    audio-selector
    # autohide-battery
    bat_consumption_wattmeter
    bluetooth-battery
    # bluetooth-quick-connect
    # colorful-battery-indicator
    duckduckgo-search-provider
    # gradient-top-bar
    # gsconnect
    # keyboard-backlight-slider
    # keyboard-modifiers-status
    night-theme-switcher
    notification-banner-reloaded
    openweather
    # pass-search-provider
    # refresh-wifi-connections
    remove-alttab-delay-v2
    space-bar
    ssh-search-provider-reborn
    syncthing-indicator
    weeks-start-on-monday-again
    user-id-in-top-panel
    username-and-hostname-to-panel
  ];
}
