{ lib
, writeShellApplication

, coreutils
, gnused
}:
writeShellApplication {
  name = "nocolor";

  runtimeInputs = [
    coreutils
    gnused
  ];

  text = ''
    : "''${NO_COLOR:=}"

    if [[ -n "$NO_COLOR" ]]; then
        exec sed -E 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g' "$@"
    else
        exec cat
    fi
  '';

  meta = with lib; {
    description = "Strip color codes from stdin/files only if NO_COLOR is set";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
