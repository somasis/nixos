{ lib
, writeShellApplication

, coreutils
, unixtools
}:
writeShellApplication {
  name = "table";

  runtimeInputs = [
    coreutils
    unixtools.column
  ];

  text = ''
    if [[ "$#" -gt 0 ]] || [[ -t 1 ]]; then
        exec column -s $'\t' -t -L "$@"
    else
        exec cat
    fi
  '';

  meta = with lib; {
    description = "Use column(1) to format a table while playing well with usage in pipes";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
