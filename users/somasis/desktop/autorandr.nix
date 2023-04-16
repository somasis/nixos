{ config
, pkgs
, lib
, nixosConfig
, ...
}:
let
  monitor = {
    ilo = {
      fingerprint = "00ffffffffffff0009e55f0900000000171d0104a51c137803de50a3544c99260f505400000001010101010101010101010101010101115cd01881e02d50302036001dbe1000001aa749d01881e02d50302036001dbe1000001a000000fe00424f452043510a202020202020000000fe004e4531333546424d2d4e34310a00fb";
      mode = "2256x1504";
      dpi = 144;
    };

    # FIXME: Framework's HDMI expansion slots change the EDID depending
    #        on what port they're in... autorandr seems to not be able
    #        to both do match-edid *and* fingerprints with asterisks in
    #        them at the same time
    tv = {
      fingerprint = "00ffffffffffff00593a331000000000011d0103806e3e782a626dad4f48aa250c474a250e00d1c0010001010101010101010101010104740030f2705a80b0588a0048684200001e023a801871382d40582c450048684200001e000000fc00563430352d47390a2020202020000000fd00173e0e883c000a202020202020017602036b715e61605d5e5f621f101405130420223c3e12160307111502066a444b01656629097f07150750570400830f00006e030c002000183c210080010203046dd85dc401788003000000000000e200ffeb0146d0004447439c3f1faae305e000e50f03000031e3060f010000000000000000000000000000000000000000f7";
      mode = "1920x1080";
      dpi = 192;
    };

    deskLeft = {
      fingerprint = "00ffffffffffff000472d302c90518321517010380301b782a40a5a4554ea026115054b30c00714f818081c081009500b300d1c00101023a801871382d40582c4500dd0c11000*";
      mode = "1920x1080";
      dpi = 96;
    };
    deskRight = {
      fingerprint = "00ffffffffffff000472ea028e2940242c16010380301b78ae40a5a4554ea026115054b30c00714f818081009500d1c081c0b3000101023a801871382d40582c4500dd0c1100001e000000fd00374b1e5011000a202020202020000000fc004732323648514c0a2020202020000000ff004c564d4141303031323430310a00bd";
      mode = "1920x1080";
      dpi = 96;
    };
  };

  hook = pkgs.writeShellScript "autorandr-hook" ''
    ${pkgs.autorandr}/bin/autorandr "$@"
  '';
in
{
  # home.activation."autorandr" = ''
  #   if [ -n "''${DISPLAY:-}" ] \
  #       && ${pkgs.systemd}/bin/systemctl --user is-active -q graphical-session.target >/dev/null \
  #       && [ "$($DRY_RUN_CMD ${hook} --detected)" != "$($DRY_RUN_CMD ${hook} --current)" ]; then
  #       $DRY_RUN_CMD ${hook} -c || :
  #   fi
  #   exit
  # '';

  systemd.user.services.xsecurelock.Service.ExecStopPost = [ "-${hook} -c" ];
  services.sxhkd.keybindings."super + p" = "${hook} --cycle";
  xsession.windowManager.bspwm.startupPrograms = lib.mkBefore [ "${hook} -c" ];

  # Match exclusively based on the fingerprint rather than the display name.
  # The EDID can change based on the location that an expansion port ends up on the USB bus.
  # xdg.configFile."autorandr/settings.ini".text = ''
  #   [config]
  #   match-edid=true
  # '';

  programs.autorandr = {
    enable = true;

    hooks.postswitch."dpi" = ''
      dpi=$(${pkgs.gnused}/bin/sed '/^dpi/!d; s/^dpi *//; q' "$AUTORANDR_PROFILE_FOLDER/config")
      printf 'Xft.dpi: %s\n' "$dpi" | ${pkgs.xorg.xrdb}/bin/xrdb -merge
    '';

    profiles = {
      # internal:external: external monitor *only*
      # internal+external: internal monitor *with* external monitor
      "${nixosConfig.networking.fqdnOrHostName}" = {
        fingerprint.eDP-1 = monitor.ilo.fingerprint;
        config = {
          eDP-1 = {
            inherit (monitor.ilo) dpi mode;

            enable = true;
            primary = true;

            position = "0x0";
          };
        };
      };


      # "ilo.somas.is:tv" = {
      #   fingerprint = {
      #     eDP-1 = monitor.ilo.fingerprint;
      #     external = monitor.tv.fingerprint;
      #   };
      #   config = {
      #     internal.enable = false;
      #     external = {
      #       enable = true;
      #       primary = true;
      #       mode = monitor.tv.mode;
      #       position = "0x0";
      #     };
      #   };
      # };

      # "ilo.somas.is+tv" = {
      #   fingerprint = {
      #     eDP-1 = monitor.ilo.fingerprint;
      #     external = monitor.tv.fingerprint;
      #   };
      #   config = {
      #     external = {
      #       # above internal
      #       enable = true;
      #       primary = true;
      #       mode = monitor.tv.mode;
      #       position = "0x0";
      #     };
      #     eDP-1 = {
      #       # below external
      #       enable = true;
      #       dpi = monitor.ilo.dpi;
      #       mode = monitor.ilo.mode;
      #       position = "0x1081";
      #     };
      #   };
      # };

      # "ilo.somas.is+desk:left" = {
      #   fingerprint = {
      #     eDP-1 = monitor.ilo.fingerprint;
      #     external = monitor.deskLeft.fingerprint;
      #   };
      #   config = {
      #     eDP-1 = {
      #       enable = true;
      #       primary = true;
      #       dpi = monitor.ilo.dpi;
      #       mode = monitor.ilo.mode;
      #       position = "0x0";
      #     };
      #     external = {
      #       enable = true;
      #       mode = monitor.deskLeft.mode;
      #       position = "2257x0";
      #     };
      #   };
      # };

      # "ilo.somas.is+desk:right" = {
      #   fingerprint = {
      #     eDP-1 = monitor.ilo.fingerprint;
      #     DP-1 = monitor.deskRight.fingerprint;
      #   };
      #   config = {
      #     eDP-1 = {
      #       enable = true;
      #       primary = true;
      #       mode = monitor.ilo.mode;
      #       position = "0x0";
      #     };
      #     DP-1 = {
      #       enable = true;
      #       mode = monitor.deskRight.mode;
      #       position = "2257x0";
      #     };
      #   };
      # };

      # "ilo.somas.is:desk:right" = {
      #     fingerprint = {
      #       eDP-1 = monitor.ilo.fingerprint;
      #       external = monitor.deskRight.fingerprint;
      #     };
      #     config = {
      #       internal.enable = false;
      #       external = {
      #         enable = true;
      #         primary = true;
      #         mode = monitor.deskRight.mode;
      #         position = "0x0";
      #       };
      #     };
      #   };

      #   "ilo.somas.is+desk" = {
      #     fingerprint = {
      #       eDP-1 = monitor.ilo.fingerprint;
      #       externalRight = monitor.deskLeft.fingerprint;
      #       externalRightRight = monitor.deskRight.fingerprint;
      #     };
      #     config = {
      #       eDP-1 = {
      #         enable = true;
      #         primary = true;
      #         mode = monitor.ilo.mode;
      #         position = "0x0";
      #       };
      #       externalRight = {
      #         enable = true;
      #         mode = monitor.deskLeft.mode;
      #         position = "2257x0";
      #       };
      #       externalRightRight = {
      #         enable = true;
      #         mode = monitor.deskRight.mode;
      #         position = "4177x0";
      #       };
      #     };
      #   };
    };
  };
}
