{ lib
, stdenv
, fetchFromGitHub
, pidgin
, pkg-config
}:
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
}
