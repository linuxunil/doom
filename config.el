;; Disable confirmation dialogs
(setq confirm-kill-emacs nil)
(setq display-line-numbers-type nil)

;; Prevents some cases of Emacs flickering
(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))

;; Use zsh for shell commands
(setq shell-file-name (executable-find "zsh"))

;; Use zsh for interactive terminals (eshell, vterm)
(setq-default vterm-shell (or (executable-find "fish")
                               "/opt/homebrew/bin/fish"))
(setq-default explicit-shell-file-name (or (executable-find "fish")
                                            "/opt/homebrew/bin/fish"))
;; When I bring up Doom's scratch buffer with SPC x, it's often to play with
;; elisp or note something down (that isn't worth an entry in my notes). I can
;; do both in `lisp-interaction-mode'.
(setq doom-scratch-initial-major-mode 'lisp-interaction-mode)

(setq ns-use-native-fullscreen nil)
(setq frame-resize-pixelwise t)
(setq ns-pop-up-frames nil)
(setq ns-use-proxy-icon nil)
(add-to-list 'default-frame-alist '(undecorated-round . t))
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
(add-to-list 'default-frame-alist '(ns-appearance . dark))
(add-to-list 'initial-frame-alist `(fullscreen . maximized))
(add-to-list 'default-frame-alist `(fullscreen . maximized))
;;; :editor evil
;; Focus new window after splitting
(setq evil-split-window-below t
      evil-vsplit-window-right t)

;; Buffer navigation with H/L
(map! :n "H" #'previous-buffer
      :n "L" #'next-buffer)

(setq doom-theme 'doom-gruvbox)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 13)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font Propo" :size 13))

(after! claude-code
  (setq claude-code-terminal-backend 'vterm)
  (setq claude-code-optimize-window-resize t)
  (setq claude-code-toggle-auto-select t)
  (add-to-list 'display-buffer-alist
                 '("^\\*claude"
                   (display-buffer-in-side-window)
                   (side . right)
                   (window-width . 90)))
  (map! :leader
        :desc "Claude"
        "o c" #'claude-code-toggle
        "o m" #'claude-code-transient))

(after! corfu
  (map! :map corfu-map
        "C-n" #'corfu-next
        "C-p" #'corfu-previous
        "C-y" #'corfu-insert
        ;; Disable other completion keys
        "<tab>" nil
        "TAB" nil
        "<return>" nil
        "RET" nil
        "SPC" nil))

(after! vertico
  (map! :map vertico-map
        "C-n" #'vertico-next
        "C-p" #'vertico-previous
        "C-y" #'vertico-insert))

(after! yasnippet
  ;; Snippet field navigation
  (map! :map yas-keymap
        "<tab>" #'yas-next-field-or-maybe-expand
        "TAB" #'yas-next-field-or-maybe-expand
        "<backtab>" #'yas-prev-field
        "S-TAB" #'yas-prev-field))

(after! ruby-mode
  (set-formatter! 'rubocop
    '("rubocop" "--autocorrect" "--stderr" "--stdin" filepath)
    :modes '(ruby-mode)))

(after! lsp-mode
  ;; Use system elixir-ls (from mise/asdf)
  (setq lsp-elixir-ls-server-dir nil)  ; Don't use bundled version
(setq lsp-zig-zls-executable (executable-find "zls"))

  ;; Find elixir-ls in PATH
  (when-let ((elixir-ls (executable-find "elixir-ls")))
    (setq lsp-elixir-server-command (list elixir-ls)))

  ;; Enable MCP (Model Context Protocol)
  (setq lsp-elixir-enable-mcp t)

  ;; Other Elixir LSP settings
  (setq lsp-elixir-dialyzer-enabled t
        lsp-elixir-dialyzer-warn-opts '()
        lsp-elixir-dialyzer-format "dialyxir_long"
        lsp-elixir-suggest-specs nil
        lsp-elixir-enable-test-lenses t
        lsp-elixir-mix-env "dev"
        lsp-elixir-mix-target "host"
        lsp-elixir-project-dir nil))

(after! mise
  (add-hook 'after-init-hook #'global-mise-mode))

(after! elixir-mode
  (add-hook 'elixir-mode-hook #'mix-minor-mode))

(use-package! gleam-ts-mode
  :mode (rx ".gleam" eos))

(after! treesit
  (add-to-list 'auto-mode-alist '("\\.gleam$" . gleam-ts-mode)))

(after! gleam-ts-mode
  (unless (treesit-language-available-p 'gleam)
    (gleam-ts-install-grammar)))

(map! :leader
      :desc "CD to current file directory"
      "cd" (lambda ()
             (interactive)
             (cd (file-name-directory buffer-file-name))))

(defun my/detect-coding-platform ()
  "Detect which coding platform this project belongs to.
Returns 'codecrafters, 'exercism, or nil."
  (when-let ((root (projectile-project-root)))
    (cond
     ((file-directory-p (expand-file-name ".codecrafters" root)) 'codecrafters)
     ((file-directory-p (expand-file-name ".exercism" root)) 'exercism)
     (t nil))))

(defun my/coding-platform-test ()
  "Run test command for detected coding platform, or normal compile."
  (interactive)
  (pcase (my/detect-coding-platform)
    ('codecrafters (compile "codecrafters test"))
    ('exercism (compile "exercism test"))
    (_ (call-interactively #'projectile-compile-project))))

(defun my/coding-platform-submit ()
  "Submit solution for detected coding platform."
  (interactive)
  (pcase (my/detect-coding-platform)
    ('codecrafters (compile "codecrafters submit"))
    ('exercism (compile "exercism submit"))
    (_ (message "Not a recognized coding platform project"))))

(after! projectile
  ;; Add platform directories as project markers
  (add-to-list 'projectile-project-root-files-bottom-up ".codecrafters")
  (add-to-list 'projectile-project-root-files-bottom-up ".exercism")

  ;; Override projectile commands with platform-aware versions
  (map! :map projectile-command-map
        "c" #'my/coding-platform-test      ; SPC p c: compile/test
        "C" #'my/coding-platform-test      ; SPC p C: test
        "s" #'my/coding-platform-submit    ; SPC p s: submit
        "P" #'projectile-test-project))    ; SPC p P: original test

(after! org
  (setq org-default-notes-file (expand-file-name "inbox.org" org-directory))
  (setq org-mobile-directory "~/Library/Mobile Documents/iCloud-com-mobileorg-mobileorg/Documents"))

(after! org
  (after! yasnippet
    (map! :map org-mode-map
          :leader
          :desc "Insert Source Block"
          "i s" (cmd! (yas-expand-snippet "#+begin_src ${1:emacs-lisp}\n$0\n#+end_src")))))

;; Enhanced nov.el configuration
(after! nov
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
  ;; Reading improvements
  (setq nov-text-width 80
        nov-variable-pitch t
        nov-save-place-file (concat doom-cache-dir "nov-places")))
