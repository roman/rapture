inputs: { lib, rsync, stdenv, emacs, coreutils }:

stdenv.mkDerivation {
  pname   = "rapture";
  version = "0.1";
  src = ./src;

  buildInputs = [ emacs coreutils ];
  buildPhase = ''
    echo "GENERATING config.el FROM config.org"
    cp -R $src/* .
    # tangle org files
    emacs --batch -Q -l org \
      --eval '(org-babel-tangle-file "config.org" "config.el")'
  '';

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    ${rsync}/bin/rsync -av *.el *.org $out
  '';

  meta = {
    homepage = "http://github.com/roman/rapture";
    description = "My doom.d configuration";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.roman ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
