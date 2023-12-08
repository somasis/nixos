{ lib
, stdenv
, fetchFromGitHub
, pidgin
, pkg-config
, libsecret
}:
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
}
