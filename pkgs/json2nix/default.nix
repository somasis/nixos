{ lib
, writeShellApplication
, nix
, coreutils
, nixfmt
}:
writeShellApplication {
  name = "json2nix";

  runtimeInputs = [
    coreutils
    nix
    nixfmt
  ];

  text = builtins.readFile ./json2nix.bash;

  meta = with lib; {
    description = "Convert JSON to Nix expressions";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
