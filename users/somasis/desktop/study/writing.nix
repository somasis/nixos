{ pkgs
, lib
, config
, ...
}:
let libreoffice = pkgs.libreoffice-still; in
{
  home = {
    packages = [ libreoffice ];

    # See for more details:
    # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
    persistence."/persist${config.home.homeDirectory}".directories = [{
      method = "symlink";
      directory = "etc/libreoffice";
    }];
  };

  xdg.mimeApps.associations.removed = lib.genAttrs [ "text/plain" ] (_: "libreoffice.desktop");

  systemd.user.services.libreoffice = {
    Unit = {
      Description = libreoffice.meta.description;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service =
      let
        libreofficeWait = pkgs.writeShellScript "libreoffice-wait" ''
          ${pkgs.procps}/bin/pwait -u "$USER" "soffice.bin" || :
          ${pkgs.coreutils}/bin/rm -f "${config.xdg.configHome}/libreoffice/4/.lock"
        '';
      in
      {
        Type = "simple";

        # Wait for any standalone instances of libreoffice to quit; there might be one open,
        # which will cause ExecStart to fail if we don't wait for it to end by itself.
        # We especially do not want to kill it since it might be some in-progress writing.
        # If there is no process matching the pattern, pwait will exit non-zero.
        ExecStartPre = [
          "-${libreofficeWait}"
        ] ++
        # Install the Zotero connector
        lib.optional config.programs.zotero.enable
          "${libreoffice}/bin/unopkg add -f ${config.programs.zotero.package}/usr/lib/zotero-bin-${pkgs.zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
        ;

        ExecStart = [ "${libreoffice}/bin/soffice --quickstart --nologo --nodefault" ];

        Restart = "always";
        KillSignal = "SIGQUIT";

        # TimeoutStopSec = "4s";
      };
  };
}
