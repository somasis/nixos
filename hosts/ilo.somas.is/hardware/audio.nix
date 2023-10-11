{ pkgs, ... }: {
  # Enable ALSA and preserve the mixer state across boots.
  sound.enable = true;
  cache.directories = [ "/var/lib/alsa" ];

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

  #   alsa = {
  #     enable = true;
  #     support32Bit = true;
  #   };

  #   pulse.enable = true;
  #   jack.enable = true;
  # };

  # Sonos output functionality using AirPlay
  # environment.etc."pipewire/pipewire.conf.d/network-audio.conf".text = ''
  #   # <https://wiki.archlinux.org/title/PipeWire#Streaming_audio_to_an_AirPlay_receiver>
  #   context.modules = [
  #       {
  #          name = libpipewire-module-raop-discover
  #          args = { }
  #       }

  #       # <https://wiki.archlinux.org/title/PipeWire#Sharing_audio_devices_with_computers_on_the_network>
  #       {
  #          name = libpipewire-module-rtp-session
  #          args = { }
  #       }
  #       {
  #          name = libpipewire-module-zeroconf-discover
  #          args = { }
  #       }
  #   ]

  #   # <https://wiki.archlinux.org/title/PipeWire#Sharing_audio_devices_with_computers_on_the_network>
  #   context.exec = [
  #       { path = "pactl" args = "load-module module-native-protocol-tcp" }
  #   ]
  # '';

  # <https://wiki.archlinux.org/title/PipeWire#Streaming_audio_to_an_AirPlay_receiver>
  # networking.firewall.allowedUDPPorts = [ 6001 6002 ];
}
