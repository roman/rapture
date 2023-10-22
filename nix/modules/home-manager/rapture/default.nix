{ self, ... } @ inputs: { lib, pkgs, config, ... }:

let
  # get the doom.d configuration from rapture
  doomd = self.packages.${pkgs.system}.default;

  # set rapture to doomPrivateDir
  doomPrivateDir = builtins.toString doomd;

  # doomPackageDir ensures that we do not rebuild all the
  # dependencies on nix-build when modifying config.el
  # doomPackageDir =
  #   pkgs.linkFarm "doom-base" [
  #     { name = "init.el"; path = "${doomd}/init.el"; }
  #     { name = "autoload.el"; path = "${doomd}/autoload.el"; }
  #     { name = "packages.el"; path = "${doomd}/packages.el"; }
  #     { name = "config.el";   path = pkgs.emptyFile; }
  #   ];

  # to have support for lsp-grammarly
  extraPackages = [
    pkgs.nodejs_16.pkgs.grammarly-languageserver
  ];

  emacsPackage = pkgs.emacs28;

  emacsPackagesOverlay = final: prev: {
    # override the lsp-grammarly package to have a direct link to the
    # grammarly-languageserver nix installation
    lsp-grammarly = self.packages.${pkgs.system}.lsp-grammarly;
  };

  cfg = config.rapture;
in

{

  options.rapture = {
    enable = lib.mkEnableOption
      (lib.mdDoc "rapture doom-emacs configuration");
  };

  config = lib.mkIf (cfg.enable) {

    programs.doom-emacs = {
      enable = true;
      inherit
        doomPrivateDir # doomPackageDir
        emacsPackage extraPackages emacsPackagesOverlay;
    };

    # The bash setup bellow allows vterm buffers to change the current path of the
    # editor when performing cd commands.
    programs.bash.initExtra = ''
      vterm_printf() {
        if [ -n "$TMUX" ] && ([ "''${TERM%%-*}" = "tmux" ] || [ "''${TERM%%-*}" = "screen" ] ); then
            # Tell tmux to pass the escape sequences through
            printf "\ePtmux;\e\e]%s\007\e\\" "$1"
        elif [ "''${TERM%%-*}" = "screen" ]; then
            # GNU screen (screen, screen-256color, screen-256color-bce)
            printf "\eP\e]%s\007\e\\" "$1"
        else
            printf "\e]%s\e\\" "$1"
        fi
      }

      vterm_prompt_end() {
        vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
      }

      PROMPT_COMMAND="vterm_prompt_end''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    '';

  };
}
