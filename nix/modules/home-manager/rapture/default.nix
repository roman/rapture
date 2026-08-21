{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.programs.rapture;
in
{

  options.programs.rapture = {
    enable = lib.mkEnableOption (lib.mdDoc "rapture emacs configuration");

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = lib.mdDoc "list of rapture plugins to use on this emacs install.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.emacs;
      description = lib.mdDoc "emacs package to use as base.";
    };

    fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = lib.mdDoc "Font packages to install for the Rapture Emacs configuration.";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = lib.mdDoc "Resulting customized emacs package.";
    };
  };

  config = lib.mkIf cfg.enable ({

    programs.rapture.finalPackage = pkgs.rapture.buildEmacs {
      inherit (cfg) package plugins fontPackages;
      # launchd starts the Emacs daemon outside any login shell, so it never
      # sources hm-session-vars.sh (see programs.bash.initExtra below, which
      # hardcodes ~/.nix-profile for the same gap in bash buffers instead —
      # profileDirectory is the option-driven answer to the same question)
      # and path_helper never knows about a home-manager profile. Restore it
      # directly instead of shelling out to hm-session-vars.sh at runtime.
      extraRuntimePrefixes = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        config.home.profileDirectory
        "/run/current-system/sw"
      ];
    };

    # Any home.packages output carrying an Applications/*.app directory gets
    # published to ~/Applications/Home Manager Apps/ — the emacsClientApp
    # rides that the same way the Emacs.app bundle itself does.
    home.packages =
      (cfg.finalPackage.fontPackages or [ ])
      ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin (pkgs.rapture.mkEmacsClientApp cfg.finalPackage);

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
      EDITOR = lib.mkForce (
        lib.getBin (
          pkgs.writeShellScript "editor" ''
            	          exec ${lib.getBin cfg.finalPackage}/bin/emacsclient "''${@:---create-frame}"
          ''
        )
      );
    };

    programs.bash.initExtra = ''
      # Source home-manager session variables for non-login shells (e.g., vterm).
      # By default, hm-session-vars.sh is only sourced from .profile (login shells),
      # so vterm buffers don't inherit variables like SRC_ENDPOINT.
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

      # The functions below allow vterm buffers to change the current path of the
      # editor when performing cd commands.
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

  });
}
