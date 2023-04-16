{ config
, pkgs
, ...
}: {
  programs.pidgin = {
    enable = true;
    plugins = [
      pkgs.pidgin-opensteamworks
      pkgs.pidgin-skypeweb
      pkgs.purple-discord
      pkgs.purple-facebook
      pkgs.purple-googlechat
      pkgs.purple-matrix
      (pkgs.callPackage
        ({ lib, stdenv, fetchFromGitHub, pidgin, pkg-config, glib, json-glib, zlib }:

          stdenv.mkDerivation rec {
            pname = "purple-instagram";
            version = "unstable-2019-11-21";

            src = fetchFromGitHub {
              owner = "EionRobb";
              repo = "purple-instagram";
              rev = "420cef45db2398739ac19c93640e6fff42865bb1";
              hash = "sha256-EbAVa5an6ZJ2aZUdPUKUehVZYhEi3g/52FpNAy6dx94=";
            };

            nativeBuildInputs = [ pkg-config ];
            buildInputs = [
              glib
              json-glib
              pidgin
              zlib
            ];

            makeFlags = [ "DESTDIR=$(out)" ];

            meta = with lib; {
              homepage = "https://github.com/EionRobb/purple-instagram";
              description = "Instagram protocol plugin for Pidgin";
              license = licenses.gpl3;
              platforms = platforms.linux;
            };
          })
        { })

      pkgs.signald
      pkgs.purple-signald

      pkgs.pidgin-window-merge
      pkgs.purple-plugin-pack
      (pkgs.callPackage
        ({ lib, stdenv, fetchFromGitHub, pidgin, pkg-config }:

          stdenv.mkDerivation rec {
            pname = "pidgin-groupchat-typing-notifications";
            version = "3";

            src = fetchFromGitHub {
              owner = "EionRobb";
              repo = "pidgin-groupchat-typing-notifications";
              rev = version;
              hash = "sha256-PVhUlc3dtMXLvmMBjccTjbaUALnxReer0F782VqKVCY=";
            };

            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ pidgin ];

            makeFlags = [ "DESTDIR=$(out)" ];

            meta = with lib; {
              homepage = "https://github.com/EionRobb/pidgin-groupchat-typing-notifications";
              description = "Get typing notifications for members of group chats in Pidgin";
              license = licenses.gpl3;
              platforms = platforms.linux;
            };
          })
        { })

      (pkgs.callPackage
        ({ lib, stdenv, fetchFromGitHub, pidgin, pkg-config, libsecret }:

          stdenv.mkDerivation rec {
            pname = "pidgin-gnome-keyring";
            version = "2.0";

            src = fetchFromGitHub {
              owner = "aebrahim";
              repo = "pidgin-gnome-keyring";
              rev = version;
              hash = "sha256-v0fB2YbkP96kvZhMu/xum5YJ8946rZUCMQBojlp9f0k=";
            };

            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsecret pidgin ];

            makeFlags = [ "-e" "VERSION=${version}" "DESTDIR=$(out)" ];

            meta = with lib; {
              homepage = "https://github.com/aebrahim/pidgin-gnome-keyring";
              description = "Save Pidgin account passwords to system keyring rather than plain text";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
            };
          })
        { })
    ];
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    method = "symlink";
    directory = "etc/pidgin";
  }];
}
