{
  # TODO: Get fingerprint auth actually working
  services.fprintd.enable = false;
  persist.directories = [ "/var/lib/fprint" ];
}
