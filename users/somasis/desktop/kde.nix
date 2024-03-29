{ config, pkgs, ... }: {
  home.packages = [
    pkgs.plasma-desktop
    pkgs.plasma-workspace
    pkgs.dolphin
    pkgs.kwin
    pkgs.systemsettings

    # pkgs.libsForQt5.bismuth
    pkgs.libsForQt5.lightly
    pkgs.plasma-pass
    pkgs.plasma-nm

    pkgs.wtype
    pkgs.wl-clipboard
  ];

  # persist = {
  #   directories = [
  #     "etc/kdedefaults"
  #   ];

  #   files = [
  #     "etc/akregatorrc"
  #     "etc/baloofilerc"
  #     "etc/dolphinrc"
  #     "etc/kactivitymanagerdrc"
  #     "etc/kcminputrc"
  #     "etc/kded5rc"
  #     "etc/kdeglobals"
  #     "etc/kglobalshortcutsrc"
  #     "etc/khotkeysrc"
  #     "etc/klaunchrc"
  #     "etc/klipperrc"
  #     "etc/krunnerrc"
  #     "etc/kscreenlockerrc"
  #     "etc/ksplashrc"
  #     "etc/ktimezonedrc"
  #     "etc/kwalletrc"
  #     "etc/kwinrc"
  #     "etc/kwinrulesrc"
  #     "etc/kxkbrc"
  #     "etc/lightlyrc"
  #     "etc/plasmarc"
  #     "etc/spectaclerc"
  #     "etc/startkderc"
  #     "etc/systemsettingsrc"
  #     "etc/kglobalshortcutsrc"
  #     "etc/plasmashellrc"
  #     "etc/plasmanotifyrc"
  #     "etc/okularpartrc"
  #     "etc/plasma-localerc"
  #     "etc/plasma-org.kde.plasma.desktop-appletsrc"
  #     "etc/powerdevilrc"
  #     "etc/kmixrc"
  #     "etc/ksmserverrc"
  #     "etc/kconf_updaterc"
  #     "etc/kateschemarc"
  #     "etc/gwenviewrc"
  #     "etc/baloofileinformationrc"
  #     "etc/Trolltech.conf"
  #   ];
  # };

  # cache = {
  #   directories = [
  #     "share/baloo"
  #     "share/dolphin"
  #     "share/kactivitymanagerd"
  #     "share/kcookiejar"
  #     "share/klipper"
  #     "share/knewstuff3"
  #     "share/kpeople"
  #     "share/kpeoplevcard"
  #     "share/kscreen"
  #     "share/kxmlgui5"
  #     "share/RecentDocuments"
  #   ];
  # };
}
