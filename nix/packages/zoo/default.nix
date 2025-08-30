{ rapture }:

rapture.buildEmacs {
  plugins = with rapture.plugins; [
    evil
    ai
    ui
    basics
    navigation
    help
    coding
    org
    langs
  ];
}
