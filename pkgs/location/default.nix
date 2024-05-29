{ lib
, symlinkJoin
, writeShellApplication

, curl
, geoclue2-with-demo-agent
, jq
, jc
}:
writeShellApplication {
  name = "location";

  runtimeInputs = [
    curl
    geoclue2-with-demo-agent
    jc
    jq
  ];

  text = ''
    PATH=${geoclue2-with-demo-agent}/libexec/geoclue-2.0/demos:"$PATH"
  '' + builtins.readFile ./location.bash
  ;

  meta = with lib; {
    description = "Get a geolocation using various methods (and resolve it if requested)";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
