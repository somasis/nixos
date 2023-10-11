{ lib
, writeShellApplication

, coreutils
}:
(writeShellApplication {
  name = "ellipsis";

  runtimeInputs = [
    coreutils
  ];

  text = builtins.readFile ./ellipsis.sh;
}) // {
  meta = with lib; {
    description = "Truncate a string with ellipsis";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
