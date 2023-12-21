{ lib
, buildPythonApplication
, fetchFromSourcehut
, setuptools
, cssselect
, lxml
, pyrss2gen
, python-dateutil
, requests
}:
buildPythonApplication rec {
  pname = "newslinkrss";
  version = "0.11.0";
  pyproject = true;

  src = fetchFromSourcehut {
    owner = "~ittner";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-b8amC3x7qxSK9t18/VuD1sSg0LjzfV61XQwr0XdsS3E=";
  };

  propagatedBuildInputs = [
    setuptools
    cssselect
    lxml
    pyrss2gen
    python-dateutil
    requests
  ];

  meta = with lib; {
    description = "Create RSS feeds for sites that don't provide them";
    homepage = "https://git.sr.ht/~ittner/newslinkrss";
    license = [ licenses.gpl3Plus ];
  };
}
