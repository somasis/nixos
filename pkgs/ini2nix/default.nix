{ lib
, writeShellApplication

, json2nix
, jc
, nixfmt

, coreutils
, diffutils
}:
(writeShellApplication {
  name = "ini2nix";

  runtimeInputs = [
    coreutils
    json2nix
    jc
    nixfmt
  ];

  # checkINI = ''
  #   FirstKeyInGlobalSection=first key
  #   SecondKeyInGlobalSection=second key
  #   ThirdKeyInGlobalSectionAlsoANumber=3
  #   FourthKeyInGlobalSectionAlsoABoolean=true

  #   [General]
  #   String = "it's a string"
  #   HasTwoDuplicateKeys=1
  #   HasTwoDuplicateKeys=2
  #   CoerceToTrueBoolean=true
  #   AlsoCoerceToTrueBoolean=True
  #   CoerceToFalseBoolean=false
  #   AlsoCoerceToFalseBoolean=False
  # '';

  # checkExpectedOutput = ''
  #   { General = { AlsoCoerceToFalseBoolean = false; AlsoCoerceToTrueBoolean = true; CoerceToFalseBoolean = false; CoerceToTrueBoolean = true; HasTwoDuplicateKeys = [ 1 2 ]; String = "it's a string"; }; globalSection = { FirstKeyInGlobalSection = "first key"; FourthKeyInGlobalSectionAlsoABoolean = true; SecondKeyInGlobalSection = "second key"; ThirdKeyInGlobalSectionAlsoANumber = 3; }; }
  # '';

  # checkPhase = prev.checkPhase + ''
  #   ${diffutils}/bin/diff -u <($out/bin/ini2nix ${checkIni}) <(printf '%s' ${lib.toShellVar checkExpectedOutput})
  # '';

  text = builtins.readFile ./ini2nix.sh;
}) // {
  meta = with lib; {
    description = "Convert INI to Nix expressions";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
