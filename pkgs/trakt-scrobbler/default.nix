{ lib
, stdenvNoCC
, fetchPypi

, buildPythonPackage
, buildPythonApplication

, installShellFiles
, poetry-core

, requests
, urllib3
, guessit
, appdirs
, cleo
, confuse
, pysocks
  # , urlmatch
, pydantic
, tomli
, desktop-notifier # !windows

, enableSocks ? true

  # , pywin32 # windows
  # , win10toast # windows
}:

let
  urlmatch = buildPythonPackage rec {
    pname = "urlmatch";
    version = "1.0.1";

    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Pww1KfA/OzHvxFR85E5lEv9XFL9h9/asNVsWNq0W6y0=";
    };

    meta = with lib; {
      homepage = "https://github.com/jessepollak/urlmatch";
      changelog = "${homepage}/releases/tag/v${version}";
      license = licenses.asl20;
      platforms = platforms.all;
      maintainers = with maintainers; [ somasis ];
    };
  };
in

buildPythonApplication rec {
  pname = "trakt-scrobbler";
  version = "1.6.3";
  format = "pyproject";

  src = fetchPypi {
    inherit version;
    pname = "trakt_scrobbler";
    hash = "sha256-gC+X3JafjuMQeg+VfRybojYDfaQmKOBUMeEcHgazIjQ=";
  };

  nativeBuildInputs = [
    installShellFiles
    poetry-core
  ];

  propagatedBuildInputs = [
    requests
    urllib3
    guessit
    appdirs
    cleo
    confuse
    urlmatch
    pydantic
  ]
  ++ lib.optional enableSocks pysocks
  ++ lib.optional stdenvNoCC.isLinux desktop-notifier
  ;

  postInstall = ''
    installShellCompletion --zsh completions/trakts.zsh
  '';

  meta = with lib; {
    description = "Automatically scrobble TV show episodes and movies to trakt.tv";
    inherit (src.meta) homepage;
    license = licenses.gpl2;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}
