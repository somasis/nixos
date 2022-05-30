{
  # Keep system firmware up to date.
  # TODO: Framework still doesn't have their updates in LVFS properly,
  #       and, I can't enable the LVFS testing channel because it's
  #       part of the nix-managed configuration.
  #       <https://knowledgebase.frame.work/en_us/framework-laptop-bios-releases-S1dMQt6F#:~:text=Updating%20via%20LVFS%20is%20available%20in%20the%20testing%20channel>
  #       <https://github.com/NixOS/nixpkgs/issues/158497>
  services.fwupd.enable = true;

  environment.persistence."/cache".directories = [ "/var/lib/fwupd" ];
}
