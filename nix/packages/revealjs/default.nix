{lib, stdenv, fetchFromGitHub}:

let
  version = "5.2.1";
in
stdenv.mkDerivation {
  name = "revealjs";
  inherit version;
  src = fetchFromGitHub {
    owner = "hakimel";
    repo = "reveal.js";
    rev = version;
    sha256 = "sha256-f5g09Xj4XF+v6Y6zW13R4PUTWkAt3wwGpa9nSypUV6w=";
  };
  # Build the revealjs artifact in a way that ox-reveal understands.
  installPhase = ''
    runHook preInstall
    mkdir $out
    mkdir -p $out/css $out/css/theme $out/js $out/plugin
    cp -R dist/*.css $out/css
    cp -R dist/theme/* $out/css/theme
    cp dist/*.js $out/js
    cp dist/*.js.map $out/js
    cp -R plugin/zoom $out/plugin/zoom-js
    cp -R plugin/markdown $out/plugin/markdown
    cp -R plugin/notes $out/plugin/notes
    cp -R plugin/highlight $out/plugin/highlight
    cp -R plugin/math $out/plugin/math
    cp -R plugin/search $out/plugin/search
    runHook postInstall
  '';
  meta = with lib; {
    description = "The HTML Presentation Framework";
    homepage = "https://github.com/hakimel/reveal.js";
    maintainers = with maintainers; [ roman ];
  };
}
