{ self, ... } @ inputs: {lib, pkgs, config, ...}:

let
  cfg = config.rapture;
in
{
  options.rapture = {
    enable = lib.mkEnableOption
      (lib.mdDoc "rapture emacs configuration");
  };

  config =
    let
      emacs = self.packages.${pkgs.system}.emacs;
    in
      lib.mkIf (cfg.enable) {
        programs.emacs = {
          enable = true;
          package = emacs;
        };

        services.emacs = {
          enable = true;
          package = emacs;
          client.enable = true;
          client.arguments = [ "-c" ];
          defaultEditor = true;
        };

        # The bash setup below allows vterm buffers to change the current path of the editor
        # when performing cd commands.
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
