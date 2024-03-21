{ lib
, writeShellApplication

, coreutils
, findutils
, gnugrep
, gnused
}:
writeShellApplication {
  name = "sonapona";

  runtimeInputs = [
    coreutils
    findutils
    gnugrep
    gnused
  ];

  text = builtins.readFile ./sonapona.bash;

  meta = with lib; {
    description = "A fortune-mod(1) workalike that formats text nicely and doesn't use a weird format";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
