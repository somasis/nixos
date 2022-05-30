{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
      # pkgs.hplip
    ];
  };
  environment.persistence."/cache".directories = [ "/var/cache/cups" ];
  environment.persistence."/log".directories = [ "/var/log/cups" ];
}
