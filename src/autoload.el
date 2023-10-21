;;; emacs/zoo/autoload.el -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Flash mode line

(defvar zoo/flash-mode-line-activate-color  "#8A2BE2"
  "Color for when signaling an activation via flash-mode-line.")
(defvar zoo/flash-mode-line-success-color "#6AAF6A"
  "Color for when signaling success outcome via flash-mode-line.")
(defvar zoo/flash-mode-line-failed-color  "#FF6347"
  "Color for when signaling failed outcome via flash-mode-line.")

(defvar zoo-mode-line-in-use nil
  "Private var to check usage of mode-line before changing.")

(defvar zoo-mode-line-usage-delay 0.5
  "Number of secs before trying to modify the mode-line again.")

;;;###autoload
(defun zoo/restore-modeline (orig-modeline-fg)
  (set-face-background 'mode-line orig-modeline-fg)
  (setq zoo-mode-line-in-use nil))

;;;###autoload
(defun zoo/flash-mode-line (&optional color time)
  "Flashes the mod-line with a given COLOR for a period of TIME."
  (interactive)
  (if (not zoo-mode-line-in-use)
      (let ((orig-modeline-fg (face-background 'mode-line))
            (time  (or time 2))
            (color (or color "#d70000")))
        (setq zoo-mode-line-in-use t)
        (set-face-background 'mode-line color)
        (run-with-timer time nil
                        'zoo/restore-modeline
                        orig-modeline-fg))
    ;; else
    (run-with-timer zoo-mode-line-usage-delay nil
                    'zoo/flash-mode-line
                    color
                    time)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; After Save Hook

(defvar zoo/last-after-save-hook nil)
(defvar zoo/hook-overrides-hash-table (make-hash-table))

;;;###autoload
(defun zoo/-get-hook-funcs (hook)
  (delq nil (mapcar
             (lambda (e) (if (symbolp e) e))
             hook)))

;;;###autoload
(defun zoo/-get-hook-funcs-names (hook)
  (mapcar 'symbol-name
          (zoo/-get-hook-funcs
           (if (symbolp hook)
               (append (symbol-value hook)
                       (default-value hook))
             hook))))

;;;###autoload
(defun zoo/-get-all-hooks ()
  (let (hlist (list))
    (mapatoms (lambda (a)
                (if (and (not (null (string-match ".*-hook"
                                                  (symbol-name a))))
                         (not (functionp a)))
                    (add-to-list 'hlist a))))
    hlist))

;;;###autoload
(defun zoo/remove-from-hook (hook fname &optional local)
  (interactive
   (let ((hook (intern (ido-completing-read
                        "Which hook? "
                        (mapcar #'symbol-name (zoo/-get-all-hooks))))))
     (list hook
           (ido-completing-read "Which? " (zoo/-get-hook-funcs-names hook)))))
  (remove-hook hook
               (if (stringp fname)
                   (intern fname)
                 fname)
               local))

;;;###autoload
(defun zoo/remove-after-save-hook (fname &optional local)
  (interactive (list (ido-completing-read
                      "aWhich function: "
                      (zoo/-get-hook-funcs-names 'after-save-hook))))
  (zoo/remove-from-hook 'after-save-hook fname local))

;;;###autoload
(defun zoo/add-after-save-hook (fname &optional local)
  (interactive "aWhich function: ")
  ;; write the function to the buffer-file-name for easy
  ;; removal later on
  (setf (gethash (buffer-file-name (current-buffer))
                 zoo/hook-overrides-hash-table)
        fname)
  (setq zoo/last-after-save-hook fname)
  (add-hook 'after-save-hook fname t local)
  (message (format "%s will execute after a save" fname)))

;;;###autoload
(defun zoo/add-after-save-hook-kbd (key-seq &optional local)
  (interactive
   (list (read-key-sequence "Press key: ")))
  (let ((sym (key-binding key-seq)))
    (cond
     ((null sym)
      (user-error "No command is bound to %s" (key-description key-seq)))
     ((commandp sym)
      (zoo/add-after-save-hook sym local)))))

;;;###autoload
(defun zoo/check-after-save-hook (fname)
  (-contains? (zoo/-get-hook-funcs-names 'after-save-hook) (symbol-name fname)))

(defvar zoo/after-save-hook-activated-color "#6AAF6A")
(defvar zoo/after-save-hook-disabled-color  "#D70000")

;;;###autoload
(defun zoo/toggle-last-after-save-hook (&optional local)
  (interactive)
  (when zoo/last-after-save-hook
    (if (zoo/check-after-save-hook zoo/last-after-save-hook)
        (progn
          (zoo/flash-mode-line zoo/after-save-hook-disabled-color 0.5)
          (zoo/remove-after-save-hook zoo/last-after-save-hook local))
      ;; else
      (zoo/flash-mode-line zoo/after-save-hook-activated-color 0.5)
      (zoo/add-after-save-hook zoo/last-after-save-hook local))
    ))

;;;###autoload
(defun zoo/toggle-after-save-hook (fname &optional local)
  (if (zoo/check-after-save-hook fname)
      (progn
        (zoo/flash-mode-line zoo/after-save-hook-disabled-color 0.5)
        (zoo/remove-after-save-hook fname local))

      ;; else
    (zoo/flash-mode-line zoo/after-save-hook-activated-color 0.5)
    (zoo/add-after-save-hook fname local)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spacemacs compat

;;;###autoload
(defun spacemacs/alternate-buffer (&optional window)
  "Switch back and forth between current and last buffer in the
current window.

If `spacemacs-layouts-restrict-spc-tab' is `t' then this only switches between
the current layouts buffers."
  (interactive)
  (cl-destructuring-bind (buf start pos)
      (if (bound-and-true-p spacemacs-layouts-restrict-spc-tab)
          (let ((buffer-list (persp-buffer-list))
                (my-buffer (window-buffer window)))
            ;; find buffer of the same persp in window
            (seq-find (lambda (it) ;; predicate
                        (and (not (eq (car it) my-buffer))
                             (member (car it) buffer-list)))
                      (window-prev-buffers)
                      ;; default if found none
                      (list nil nil nil)))
        (or (cl-find (window-buffer window) (window-prev-buffers)
                     :key #'car :test-not #'eq)
            (list (other-buffer) nil nil)))
    (if (not buf)
        (message "Last buffer not found.")
      (set-window-buffer-start-and-point window buf start pos))))

;;;###autoload
(defun spacemacs/evil-search-clear-highlight ()
  "Clear evil-search or evil-ex-search persistent highlights."
  (interactive)
  (evil-ex-nohighlight))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nix functionality

;;;###autoload
(defun zoo/ivy-find-file-path ()
  "Insert file path from ivy search."
  (unless (featurep 'counsel) (require 'counsel))
  (ivy-read "Find file: " 'read-file-name-internal
            :matcher #'counsel--find-file-matcher))

;;;###autoload
(defun zoo/nix-flake-get-inputs (flake-directory)
  "Use nix evaluations to return all the inputs from a given FLAKE-DIRECTORY directory that contain a flake.nix file."
  (json-parse-string
   (shell-command-to-string
    (format "cd %s && nix eval --impure --expr 'let flk = builtins.getFlake (builtins.toString ./.); in builtins.attrNames flk.inputs' --json"
            flake-directory))
   :array-type 'list))

;;;###autoload
(defun zoo/nix-flake-get-input-store-path (flake-directory input-name)
  "Use nix evaluations to return the nix store path of an INPUT-NAME contained in FLAKE-DIRECTORY."
  (json-read-from-string
   (shell-command-to-string
    (format "cd %s && nix eval --impure --expr 'let flk = builtins.getFlake (builtins.toString ./.); in builtins.toString flk.inputs.%s' --json"
            flake-directory
            input-name))))

;;;###autoload
(defun zoo/nix-flake-find-file-in-input (flake-directory input-name)
  "Use projectile to find a file that belongs to the INPUT-NAME, contained in the flake.nix file of FLAKE-DIRECTORY."
  (let ((default-directory (zoo/nix-flake-get-input-store-path flake-directory input-name)))
    (+default/find-file-under-here)))

;;;###autoload
(defun zoo/nix-flake-search-in-input (flake-directory input-name)
  "Use ivy and projectile to search in files from INPUT-NAME, contained in the flake.nix file of FLAKE-DIRECTORY."
  (interactive)
  (let ((default-directory (zoo/nix-flake-get-input-store-path flake-directory input-name)))
    (+default/search-project)))

;;;###autoload
(defun +zoo/nix-flake-find-file-in-input ()
  "Use ivy and projectile to find a file from an input on the current nix flake."
  (interactive)
  (let* ((flake-directory (or (locate-dominating-file default-directory "flake.nix")
                              (zoo/ivy-find-file-path)))
         (flake-input (ivy-read "Find input: " (zoo/nix-flake-get-inputs flake-directory))))
    (zoo/nix-flake-find-file-in-input flake-directory flake-input)))

;;;###autoload
(defun +zoo/nix-flake-find-file-in-nixpkgs ()
  "Use ivy and projectile to find a file from the nixpkgs input on the current nix flake."
  (interactive)
  (let* ((flake-directory (or (locate-dominating-file default-directory "flake.nix")
                              (zoo/ivy-find-file-path))))
    (zoo/nix-flake-find-file-in-input flake-directory "nixpkgs")))

;;;###autoload
(defun +zoo/nix-flake-search-in-input ()
  "Use ivy and projectile to find search in files from nixpkgs, contained in the flakel.nix file of FLAKE-DIRECTORY."
  (interactive)
  (let* ((flake-directory (or (locate-dominating-file default-directory "flake.nix")
                              (zoo/ivy-find-file-path)))
         (flake-input (ivy-read "Find input: " (zoo/nix-flake-get-inputs flake-directory))))
    (zoo/nix-flake-search-in-input flake-directory flake-input)))


;;;###autoload
(defun +zoo/nix-flake-search-in-nixpkgs ()
  "Use ivy and projectile to find search in files from nixpkgs, contained in the flakel.nix file of FLAKE-DIRECTORY."
  (interactive)
  (let* ((flake-directory (or (locate-dominating-file default-directory "flake.nix")
                              (zoo/ivy-find-file-path))))
    (zoo/nix-flake-search-in-input flake-directory "nixpkgs")))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal extensions

;;;###autoload
(defun +zoo/vterm--configure-project-root-and-display (arg display-fn)
    "Sets the environment variable PROOT and displays a terminal using `display-fn`.

  If prefix ARG is non-nil, cd into `default-directory' instead of project root.

  Returns the vterm buffer."
    (unless (fboundp 'module-load)
      (user-error "Your build of Emacs lacks dynamic modules support and cannot load vterm"))
    (let* ((project-root (or (doom-project-root) default-directory))
           (default-directory
             (if arg
                 default-directory
               project-root)))
      (setenv "PROOT" project-root)
      (funcall display-fn)))

;;;###autoload
(defun +zoo/vterm-toggle (arg)
  "Toggles a terminal popup window at project root.

      If prefix ARG is non-nil, recreate vterm buffer in the current project's root.

      Returns the vterm buffer."
  (interactive "P")
  (+zoo/vterm--configure-project-root-and-display
   arg
   (lambda()
     (let ((buffer-name
            (format "*doom:vterm-popup:%s*"
                    (if (bound-and-true-p persp-mode)
                        (safe-persp-name (get-current-persp))
                      "main")))
           confirm-kill-processes
           current-prefix-arg)
       (when arg
         (let ((buffer (get-buffer buffer-name))
               (window (get-buffer-window buffer-name)))
           (when (buffer-live-p buffer)
             (kill-buffer buffer))
           (when (window-live-p window)
             (delete-window window))))
       (if-let (win (get-buffer-window buffer-name))
           ;; if we are sitting on the terminal window, kill it
           (if (eq (window-buffer win) (window-buffer))
               (delete-window win)
             ;; otherwise, go to the terminal window
             (select-window win))
         ;; else
         (let ((buffer (get-buffer-create buffer-name)))
           (with-current-buffer buffer
             (unless (eq major-mode 'vterm-mode)
               (vterm-mode)))
           (pop-to-buffer buffer)))
       (get-buffer buffer-name)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Last Call feature

(defvar zoo/last-test-buffer nil)
(defvar zoo/last-test-point nil)
(defvar zoo/last-test-function nil)

;;;###autoload
(defun zoo/store-last-test (fname)
  (interactive "aWhich function: ")
  (setq zoo/last-test-function fname)
  (setq zoo/last-test-point (point))
  (setq zoo/last-test-buffer (current-buffer)))

;;;###autoload
(defun zoo/call-last-test ()
  (interactive)
  (when zoo/last-test-buffer
    (save-excursion
      (with-current-buffer zoo/last-test-buffer
        (goto-char zoo/last-test-point)
        (call-interactively zoo/last-test-function)))))

;;;###autoload
(defun zoo/run-continously-after-save (key-seq &optional local)
  "Run the given keybinding after every save on the same buffer and location."
  (interactive
   (list (read-key-sequence "Press key: ")))
  (let ((sym (key-binding key-seq)))
    (cond
     ((null sym)
      (user-error "No command is bound to %s" (key-description key-seq)))
     ((commandp sym)
      (progn
        (zoo/store-last-test sym)
        (zoo/add-after-save-hook 'zoo/call-last-test local))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org utilities

;;;###autoload
(defun zoo/org-current-timestamp ()
  (let ((fmt (concat
              "<" (cdr org-time-stamp-formats) ">")))
    (format-time-string fmt)))

;;;###autoload
(defun zoo/org-current-clock-id ()
  "Get the id of the current item being clocked."
  (save-window-excursion
    (save-excursion
      (org-clock-goto)
      (org-id-get-create))))

;;;###autoload
(defun zoo/org-clocking-p ()
  (interactive)
  (and (fboundp 'org-clocking-p)
       (org-clocking-p)))

;;;###autoload
(defun zoo/org-insert-heading-hook ()
  (interactive)
  ;; Create an ID for the current item
  (org-id-get-create)
  (org-set-property "CREATED"
                    (zoo/org-current-timestamp))
  (when (zoo/org-clocking-p)
    ;; ^ If a clock is active, add a reference to the task
    ;; that is clocked in
    (org-set-property "CLOCK-WHEN-CREATED"
                      (zoo/org-current-clock-id))))

;;;###autoload
(defun zoo/org-after-demote-entry-hook ()
  (interactive)
    (org-delete-property "ID")
    (org-delete-property "CREATED")
    (ignore-errors (org-delete-property "CLOCK-WHEN-CREATED"))
    (org-remove-empty-drawer-at (point)))

;;;###autoload
(defun zoo/org-after-promote-entry-hook ()
  (interactive)
  (when (eq (org-current-level) 1)
    (org-id-get-create)
    (org-set-property "CREATED"
                      (zoo/org-current-timestamp))
    (when (zoo/org-clocking-g)
      ;; ^ If a clock is active, add a reference to the task
      ;; that is clocked in
      (org-set-property "CLOCK-WHEN-CREATED"
                        (zoo/org-current-clock-id)))))

;;;###autoload
(defun zoo/org-clock-out-hook ()
  (org-todo "PAUSED"))

;;;###autoload
(defun zoo/org-after-todo-state-change-hook ()
  (when (string= org-state "DONE")
    (org-set-property "COMPLETED"
                      (zoo/org-current-timestamp))))

;;;###autoload
(defun zoo/org-is-last-task-started-p ()
  (interactive)
  (save-window-excursion
    (org-clock-goto)
    (let ((state (org-get-todo-state)))
      (string= state "IN-PROGRESS"))))

;;;###autoload
(defun zoo/org-clock-in-last ()
  (interactive)
  (if (zoo/org-is-last-task-started-p)
      (org-clock-in-last)
    (message "ignoring org-clock-in-last")))
