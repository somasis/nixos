{ lib
, writeShellApplication

, coreutils
, table
}:
(writeShellApplication {
  name = "dates";

  runtimeInputs = [
    coreutils
    table
  ];

  text = builtins.readFile ./dates.bash;
}) // {
  meta = with lib; {
    description = "Show the current time/date in multiple timezones";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
