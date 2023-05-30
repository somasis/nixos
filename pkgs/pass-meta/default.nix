{ lib
, writeTextFile
, substituteAll

, coreutils
, gawk
, runtimeShell
}:
writeTextFile {
  name = "pass-meta";

  executable = true;
  destination = "/lib/password-store/extensions/meta.bash";

  text = builtins.readFile (substituteAll {
    src = ./pass-meta.bash;
    inherit coreutils gawk runtimeShell;
  });

  meta = with lib; {
    description = "Retrieve metadata from pass(1) entries";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
