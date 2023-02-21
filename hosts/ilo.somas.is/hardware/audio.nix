{ pkgs, ... }:
{
  # Enable ALSA and preserve the mixer state across boots.
  sound.enable = true;
  environment.persistence."/cache".directories = [ "/var/lib/alsa" ];

  # Necessary for realtime usage.
  security.rtkit.enable = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  # services.pipewire = {
  #   enable = true;
  #   audio.enable = true;

  #   alsa.enable = true;
  #   pulse.enable = true;
  #   jack.enable = true;
  # };
}
