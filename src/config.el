;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Roman Gonzalez"
      user-mail-address "open-source@roman-gonzalez.info")

  (setq vterm-shell
        "/run/current-system/sw/bin/bash")

  (add-hook! 'doom-after-init-modules-hook
      (map!
       :leader
       (:prefix ("o" . "open")
        :desc "Toggle vterm popup" :n "t" '+zoo/vterm-toggle)))

  (add-hook! 'doom-after-init-modules-hook
    (map!
       :after vterm
       :map vterm-mode-map
       :desc "Send vterm DELETE" :i (kbd "<deletechar>") 'vterm-send-delete))

(setq doom-theme 'doom-monokai-pro)

(setq display-line-numbers-type t)

(after! ivy
  (setq uniquify-buffer-name-style 'post-forward-angle-brackets))

(after! org-roam
  (setq org-roam-directory "~/Projects/notes"))

(use-package! org
  :preface
  (add-hook 'org-insert-heading-hook
            'zoo/org-insert-heading-hook)

  (add-hook 'org-clock-out-hook
            'zoo/org-clock-out-hook)

  (add-hook 'org-after-todo-state-change-hook
            'zoo/org-after-todo-state-change-hook)

  (add-hook 'org-after-demote-entry-hook
            'zoo/org-after-demote-entry-hook)

  (add-hook 'org-after-promote-entry-hook
            'zoo/org-after-promote-entry-hook)
  :config
  ;; Have a special :LOGBOOK: drawer for clocks
  (setq org-clock-into-drawer "CLOCK")
  ;; Don't register clocks with zero-time length
  (setq org-clock-out-remove-zero-time-clocks t)
  ;; Stop clock when a task gets to state DONE.
  (setq org-clock-out-when-done t)
  ;; Resolve open-clocks if idle more than 10 minutes
  (setq org-clock-idle-time 10)
  ;; When clocking in, change the status of the item to
  ;; STARTED
  (setq org-clock-in-switch-to-state "STARTED")
  ;; Save the clock and entry when I close emacs
  (setq org-clock-persist t)
  ;; When clocking out, change the status of the item to
  ;; PAUSED
  (setq org-clock-out-switch-to-state nil))

(map!
 :leader
 :desc "Switch to alternate buffer"  :n "TAB" 'spacemacs/alternate-buffer
 :desc "Clear vim search highlights" :n "s c" 'spacemacs/evil-search-clear-highlight)

(map!
 :desc "Winner Undo" "C-c <left>" 'winner-undo
 :desc "Winner Redo" "C-c <right>" 'winner-redo)

(add-hook! 'doom-after-init-modules-hook
  (map!
   :leader
   :map global-map
   :desc "Back to jump" :n "c n" 'better-jumper-jump-forward
   :desc "Back from jump" :n "c p" 'better-jumper-jump-backward))

(map!
 :leader
 (:prefix ("r" . "recent")
  :desc "Display recent yanks" :n "y" 'counsel-yank-pop))

(use-package! undo-tree
  :commands global-undo-tree-mode)

(map!
 :leader
 (:prefix ("a" . "app")
  (:desc "Display undo-tree" :n "u" 'undo-tree-visualize)))

(map!
 :leader
 (:prefix ("a" . "app")
  (:prefix ("h" . "hooks")
   :desc "Run continously after save" :n "s" 'zoo/run-continously-after-save
   :desc "Add after-save hook" :n "f" 'zoo/add-after-save-hook
   :desc "Add after-save hook" :n "a" 'zoo/add-after-save-hook-kbd
   :desc "Remove after-save hook" :n "r" 'zoo/remove-after-save-hook
   :desc "Toggle last after-save hook" :n "t" 'zoo/toggle-last-after-save-hook)))

(add-hook! 'doom-after-init-modules-hook
  (progn
    (map!
     :leader
     (:prefix ("f n" . "nix")
      :desc "Find file in flake's nixpkgs" :n "p" #'+zoo/nix-flake-find-file-in-nixpkgs
      :desc "Find file in flake's input" :n "i" #'+zoo/nix-flake-find-file-in-input))
    (map!
     :leader
     (:prefix ("s n" . "nix")
      :desc "Search in flake's nixpkgs" :n "p" #'+zoo/nix-flake-search-in-nixpkgs
      :desc "Search in flake's input"   :n "i" #'+zoo/nix-flake-search-in-input))))

(use-package! golden-ratio
  :config
  (setq golden-ratio-auto-scale t))

(add-hook! 'doom-after-init-modules-hook
  (map!
   :leader
   :desc "Toggle golden-ratio"
   "t G" #'golden-ratio-mode))

(use-package-hook! lsp-ui
  :post-config
  (setq lsp-ui-doc-show-with-cursor t)
  (setq lsp-ui-doc-max-height 60)
  t)

(after! lsp-ui
  (setq lsp-ui-doc-show-with-cursor t)
  (setq lsp-ui-doc-max-height 60))

(use-package! lsp-grammarly
  :hook ((text-mode . lsp-mode)
         (markdown-mode . lsp-mode)
         (org-mode . lsp-mode))
  )
