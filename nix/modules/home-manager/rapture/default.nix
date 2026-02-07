{ lib, pkgs, config, ... }:

let
  cfg = config.programs.rapture;
in
{

  options.programs.rapture = {
    enable = lib.mkEnableOption
      (lib.mdDoc "rapture emacs configuration");

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = lib.mdDoc "list of rapture plugins to use on this emacs install.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.emacs;
      description = lib.mdDoc "emacs package to use as base.";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = lib.mdDoc "Resulting customized emacs package.";
    };
  };

  config =
    lib.mkIf cfg.enable (
      {

        programs.rapture.finalPackage = pkgs.rapture.buildEmacs {
	        inherit (cfg) package plugins;
        };

        services.emacs = {
          enable = true;
          client.enable = true;
          defaultEditor = true;
          startWithUserSession = "graphical";
        };
        
        programs.emacs = {
          enable = true;
          package = cfg.finalPackage;
        };

        # [editor]: initializing the EDITOR env var to allow git commit messages to work
        # inside the same emacs session.
        home.sessionVariables = {
          EDITOR = lib.mkForce (lib.getBin (pkgs.writeShellScript "editor" ''
	          exec ${lib.getBin cfg.finalPackage}/bin/emacsclient "''${@:---create-frame}"
          ''));
        };

        # The bash setup below allows vterm buffers to change the current path of the
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

	    }
    );
}
