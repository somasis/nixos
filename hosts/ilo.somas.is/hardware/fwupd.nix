{
  # Keep system firmware up to date.
  # TODO: Framework still doesn't have their updates in LVFS properly,
  #       <https://knowledgebase.frame.work/en_us/framework-laptop-bios-releases-S1dMQt6F#:~:text=Updating%20via%20LVFS%20is%20available%20in%20the%20testing%20channel>
  services.fwupd = {
    enable = true;
    extraRemotes = [ "lvfs-testing" ];
  };

  cache.directories = [ "/var/lib/fwupd" ];
}
