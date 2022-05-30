{ pkgs, config, ... }: {
  systemd.user.services.stw-sonapona = {
    Unit = {
      Description = "len ilo la o pana e sona pona kepeken ilo stw(1)";
      StartLimitInterval = 0;
    };
    Install.WantedBy = [ "stw.target" ];
    Unit.PartOf = [ "stw.target" ];

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.stw}/bin/stw \
          -F 'monospace:style=heavy:size=10' \
          -b "${config.xresources.properties."*color4"}" \
          -f "${config.xresources.properties."*darkForeground"}" \
          -A .15 \
          -x -24 -y -24 \
          -B 12 \
          -p 60 \
          sonapona ! -name "*.long"
      '';
      ExecReload = "${pkgs.coreutils}/bin/kill -ALRM $MAINPID";
    };
  };
}
