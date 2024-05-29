{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonApplication rec {
  pname = "twscrape";
  version = "0.12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "twscrape";
    rev = "v${version}";
    hash = "sha256-g8mbn7vWmtwttV7b+0wApFTuxZsUaOnwvMtOZGZUvgE=";
  };

  nativeBuildInputs = [
    python3.pkgs.hatchling
  ];

  propagatedBuildInputs = with python3.pkgs; [
    aiosqlite
    fake-useragent
    httpx
    loguru
    pyotp
  ];

  passthru.optional-dependencies = with python3.pkgs; {
    dev = [
      pyright
      pytest
      pytest-asyncio
      pytest-cov
      pytest-httpx
      ruff
    ];
  };

  pythonImportsCheck = [ "twscrape" ];

  meta = with lib; {
    description = "Twitter API scrapper with authorization support";
    homepage = "https://github.com/vladkens/twscrape";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    mainProgram = "twscrape";
  };
}
