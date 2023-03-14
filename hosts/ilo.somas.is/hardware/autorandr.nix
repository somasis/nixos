{ pkgs, config, ... }: {
  services.autorandr = {
    enable = true;
    defaultTarget = config.networking.fqdnOrHostName;
  };

  systemd.packages = [ pkgs.autorandr ];

  # TODO(?): Is this still needed? I used acpid for triggering
  #          autorandr on lid events when using my external monitors.
  services.acpid = {
    enable = true;
    lidEventCommands = ''
      ${pkgs.autorandr}/bin/autorandr --batch --default "${config.networking.fqdnOrHostName}" -c
    '';
  };
}
