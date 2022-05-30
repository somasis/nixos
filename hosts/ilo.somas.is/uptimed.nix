{
  services.uptimed.enable = true;
  environment.persistence."/persist".directories = [ "/var/lib/uptimed" ];
}
