{ pkgs
, lib
, config
, osConfig
, ...
}:
let
  inherit (lib) replaceStrings;
  inherit (config.lib.somasis.generators) toXML;

  lo = pkgs.libreoffice-still;
  loInstallExtensions = exts: assert (builtins.isList exts);
    let
      installer = pkgs.writeShellScript "libreoffice-install-extensions" ''
        ext_is_installed() {
            for installed_ext in "''${installed_exts[@]}"; do
                installed_ext_basename=''${installed_ext##*/}
                [[ "$1" == "$installed_ext_basename" ]] && return 0
            done
            return 1
        }

        mapfile -t installed_exts < <(${lo}/bin/unopkg list | grep '^  URL:' | cut -d ' ' -f4-)

        for ext; do
            ext_is_installed "$(basename "$ext")" || ${lo}/bin/unopkg add -v -s "$ext"
        done
      '';
    in
    "${installer} ${lib.escapeShellArgs exts}"
  ;

  loExtensions = [
    # <https://extensions.libreoffice.org/en/extensions/show/27416>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/90/1676301090/TemplateChanger-L-2.0.1.oxt";
      hash = "sha256-i1+Huqsq2fYstUS4HevqpNc0/1zKRBQONMz6PB9HYh4=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/27347>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/73/1672894181/open_recent_doc.oxt";
      hash = "sha256-4ZZlqJKPuEw/9Sg7vyjLHERFL9yqWamtwAvldJkgFTg=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/english-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/41/1680302696/dict-en-20230401_lo.oxt";
      hash = "sha256-TXRr6BgGAQ4xKDY19OtowN6i4MdINS2BEtq2zLJDkZ0=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/spanish-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/98/1659525229/es.oxt";
      hash = "sha256-EPpR3/t48PwV/XkXcIE/VR2kPPAHtSy4+2zLC0EX6F8=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/dictionnaires-francais>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/lo-oo-ressources-linguistiques-fr-v5-7.oxt";
      hash = "sha256-lHPFZQg2QmN5jYd6wy/oSccQhXNyUXBVQzRsi6NCGt8=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/german-de-de-frami-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/dict-de-de-frami-2017-01-12.oxt";
      hash = "sha256-r1FQFeMGxjQ3O1OCgIo5aRIA3jQ5gR0vFQLpuRwjtGo=n";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/latin-spelling-and-hyphenation-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/dict-la-2013-03-31.oxt";
      hash = "sha256-2DDGbz6Fihz7ruGIoA2HZIL78XK7MgJr3UeeoaYywtI=n";
    })

    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/99/1667923733/LanguageTool-5.9.1.oxt";
      hash = "sha256-tWUqzvpeeAdxccgz/LBjK6hPFtxzfR3YGivaldhUN0U=";
    })
  ]
  ++ lib.optional config.programs.zotero.enable "${config.programs.zotero.package}/usr/lib/zotero-bin-${pkgs.zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
  ;
in
{
  home.packages = [
    lo

    # Free replacements for pkgs.corefonts
    # Arial, Times New Roman
    pkgs.noto-fonts-extra

    # Cambria
    pkgs.caladea

    # Calibri
    pkgs.carlito

    # Comic Sans MS
    pkgs.comic-relief

    # Georgia
    pkgs.gelasio

    # Arial Narrow
    pkgs.liberation-sans-narrow

    # Arial, Helvetica, Times New Roman, Courier New
    pkgs.liberation_ttf
  ];

  # See for more details:
  # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
  persist.directories = [
    { method = "symlink"; directory = "etc/libreoffice/4"; }
    { method = "symlink"; directory = "etc/LanguageTool/LibreOffice"; }
  ];

  xdg.configFile."libreoffice/jre".source = pkgs.openjdk19;

  # TODO: why doesn't this work?
  #       LibreOffice will fail to recognize the Java environment at all, if I
  #       generate the javasettings XML file during build time...
  # xdg.configFile =
  #   let
  #     system = osConfig.nixpkgs.localSystem.uname;
  #   in
  #   {
  #     "libreoffice/4/user/config/javasettings_${system.system}_${lib.toUpper system.processor}.xml".text = toXML {
  #       java = {
  #         "@xmlns" = "http://openoffice.org/2004/java/framework/1.0";
  #         "@xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance";

  #         enabled."@xsi:nil" = "true";
  #         userClassPath."@xsi:nil" = "false";
  #         vmParameters."@xsi:nil" = "false";
  #         jreLocations."@xsi:nil" = "true";

  #         # We can't use LibreOffice's own buildInput jdk because it's headless.
  #         # javaInfo = let inherit (lo.unwrapped) jdk; in {
  #         javaInfo = let jdk = pkgs.openjdk19; in {
  #           "@xsi:nil" = "false";
  #           "@vendorUpdate" = "2019-07-26"; # ?
  #           "@autoSelect" = "true";
  #           vendor = "N/A";
  #           location = "file://${jdk}/lib/openjdk";
  #           version = replaceStrings [ "+.*" ] [ "" ] jdk.version;
  #           features = 0;
  #           requirements = 1;

  #           vendorData = "660069006C0065003A002F002F002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F007300650072007600650072002F006C00690062006A0076006D002E0073006F000A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F0063006C00690065006E0074003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F007300650072007600650072003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F006E00610074006900760065005F0074006800720065006100640073003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034000A00"; # wtf
  #         };
  #       };
  #     };
  #   };

  xdg.mimeApps.associations.removed = lib.genAttrs [ "text/plain" ] (_: "libreoffice.desktop");

  # Do some really convoluted stuff to make LibreOffice run in the background.
  systemd.user.services.libreoffice = {
    Unit = {
      Description = lo.meta.description;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service =
      let
        loWait = pkgs.writeShellScript "libreoffice-wait" ''
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
        ExecStartPre = [ "-${loWait}" ]
          ++ [ (loInstallExtensions loExtensions) ]
        ;

        ExecStart = [ "${lo}/bin/soffice --quickstart --nologo --nodefault" ];

        Restart = "always";
        RestartSec = 0;

        KillSignal = "SIGQUIT";
      };
  };

  somasis.tunnels.tunnels.languagetool = {
    location = 3864;
    remote = "somasis@spinoza.7596ff.com";
  };
}
