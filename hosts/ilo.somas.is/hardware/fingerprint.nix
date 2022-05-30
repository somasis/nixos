{
  # TODO: Get fingerprint auth actually working
  services.fprintd.enable = false;
  environment.persistence."/persist".directories = [ "/var/lib/fprint" ];
}
