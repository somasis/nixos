{ lib
, writeShellApplication

, coreutils
, ffsclient
, gnugrep
, gnused
, jq
, moreutils
, procps
, qutebrowser
, teip
, xe
, yq-go
}:
(writeShellApplication {
  name = "qutebrowser-sync";

  runtimeInputs = [
    coreutils
    ffsclient
    gnugrep
    gnused
    jq
    moreutils
    procps
    qutebrowser
    teip
    xe
    yq-go
  ];

  text = builtins.readFile ./qutebrowser-sync.bash;
}) // {
  meta = with lib; {
    description = "Synchronize qutebrowser profile with Firefox Sync";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
