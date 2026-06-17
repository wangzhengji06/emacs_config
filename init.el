(require 'package)
(package-initialize)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/")) 

(use-package emacs
  :ensure nil
  :demand t
  :init
  (defun prot/keyboard-quit-dwim ()
    "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
    (interactive)
    (cond
     ((region-active-p)
      (keyboard-quit))
     ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
     ((> (minibuffer-depth) 0)
      (abort-recursive-edit))
     (t
      (keyboard-quit))))
  :bind
  ("C-g" . prot/keyboard-quit-dwim)
  :config
  (setq frame-resize-pixelwise t)
  ;; Set your favourite font family and height here.  The :height is
  ;; 10x the point size you most commonly find on other applications.
  (set-face-attribute 'default nil :family "0xProto" :height 200)
  ;; Set your favourite font for elements that are designed to always
  ;; be monospaced.  The height SHOULD BE a floating point, which is
  ;; interpreted as relative to the `default'.
  (set-face-attribute 'fixed-pitch nil :family "0xProto" :height 1.0)
  ;; Same as above for proportionately spaced elements.  Make any
  ;; buffer proportionately spaced by enabling the `variable-pitch-mode'.
  ;;
  ;; [ NOTE: If you use the Modus themes or derivatives, set
  ;;   `modus-themes-mixed-fonts', load the theme for the option to
  ;;   take effect, and then enable `variable-pitch-mode':
  ;;   spacing-sensitive elements like Org tables and code blocks will
  ;;   remain monospaced. ]
  (set-face-attribute 'variable-pitch nil :family "0xProto" :height 1.0)

  ;; I have never seen a user say "no" to loading a theme they have
  ;; downloaded.  Technically, any Elisp file can run arbitrary code,
  ;; so this is not doing much on the security front.
  (setq custom-safe-themes t)
  (setq use-short-answers t)
  (setq read-answer-short t)
  (setq help-window-select t) ; also check `display-buffer-alist' below
  (setq help-window-keep-selected t) ; Emacs 29
  (setq find-library-include-other-files nil) ; Emacs 29
  (setq window-combination-resize t)
  (setq save-interprogram-paste-before-kill t)
  ;; Do not jump to the current line in `*occur*' buffers.  The reason
  ;; is that you are already on that line: you want to do `occur' to
  ;; get more than that (and, presumably, to do something with the
  ;; results such as to edit them with `occur-edit-mode').
  (setq list-matching-lines-jump-to-current-line nil)
  (setq completion-category-defaults nil)) 

;; By default, Emacs will save some state to the bottom of your
;; init.el.  This can be confusing, so we want to put all such data in
;; a file called custom.el relative to your init.el
(use-package custom
  :ensure nil
  :config
  (setq custom-file (locate-user-emacs-file "custom.el"))
  (load custom-file :no-error-if-missing))

(use-package vertico
  :ensure t ; install it, if missing
  :config
  (vertico-mode 1))

(use-package savehist
  :ensure nil
  :config
  (savehist-mode 1))

(use-package marginalia
  :ensure t ; install it, if missing
  :config
  (marginalia-mode 1))

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil))

(use-package corfu
  :ensure t
  :init
  (setq tab-always-indent 'complete)
  :config
  (require 'corfu-auto)
  (setq corfu-auto t
      corfu-auto-prefix 3
      corfu-auto-delay 0.2)
  (global-corfu-mode 1)
  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode 1)
  ;; Sort by input history (no need to modify `corfu-sort-function').
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-terminal
  :ensure t
  :if (and (< emacs-major-version 31)
           (not (display-graphic-p)))
  :after corfu
  :config
  (corfu-terminal-mode 1))

(add-hook 'c++-mode-hook #'eglot-ensure)

;; This is automatically activated by Eglot.
(use-package flymake
  :ensure nil ; built-in package
  :config
  ;; Do M-x flymake-show-buffer-diagnostics for the complete listing.
  (setq flymake-show-diagnostics-at-end-of-line nil)
  (setq flymake-no-changes-timeout 3)
  (setq flymake-start-on-flymake-mode t)
  (setq flymake-start-on-save-buffer t))

(use-package display-line-numbers
  :ensure nil
  :config
  (global-display-line-numbers-mode 1))

(use-package consult
  :ensure t
  :bind
  ( :map global-map
    ("C-x b" . consult-buffer)
    ("C-s" .  consult-line)
    ("M-s g" . consult-ripgrep)
    ("M-s f" . consult-find)
    ("M-s s" . consult-outline))
  :config
  (consult-customize consult-find :sort t :state (consult--file-preview)))

(setq split-height-threshold 85)
(setq split-width-threshold 125)
(add-to-list 'display-buffer-alist
             '((or . ((derived-mode . flymake-diagnostics-buffer-mode)
                      (derived-mode . flymake-project-diagnostics-mode)
                      (derived-mode . messages-buffer-mode)
                      (derived-mode . backtrace-mode)))
               (display-buffer-reuse-mode-window display-buffer-at-bottom)
               (mode . ( flymake-diagnostics-buffer-mode flymake-project-diagnostics-mode
                         messages-buffer-mode backtrace-mode))
               (inhibit-switch-frame . t)
               (window-height . 0.2)
               (dedicated . t)
               (preserve-size . (t . t))))

(use-package markdown-mode
  :ensure t
  :config
  (setq markdown-fontify-code-blocks-natively t))

(use-package eglot
  :ensure nil
  :config
(defun my-eglot-format-buffer ()
    (when (eglot-current-server)
      (eglot-format-buffer)))
(add-hook 'after-save-hook #'my-eglot-format-buffer))

(use-package python
  :ensure nil
  :hook
  (python-mode . eglot-ensure)) 

(use-package ruff-format
  :ensure t
  :hook
  (python-mode . ruff-format-on-save-mode))

(use-package dape
  :ensure t)

(use-package csv-mode
  :ensure t) 

(use-package delsel
  :ensure nil
  :config
  (delete-selection-mode 1))

(use-package which-key
  :ensure nil
  :config
  (setq which-key-separator "  ")
  (setq which-key-prefix-prefix "... ")
  (setq which-key-max-display-columns 3)
  (setq which-key-idle-delay 1.0)
  (setq which-key-idle-secondary-delay 0.25)
  (setq which-key-add-column-padding 1)
  (setq which-key-max-description-length 40)

  (which-key-mode 1))

(setq bookmark-save-flag 1)

(setq save-interprogram-paste-before-kill t)

(add-to-list 'load-path "~/.emacs.d/lisp")

(use-package kitty-keyboard-protocl
  :ensure nil
  :hook
  (tty-setup . kitty-keyboard-protocol-enable))


(when (and (eq system-type 'gnu/linux)
           (executable-find "win32yank.exe"))

  ;; Copy from Emacs to Windows clipboard
  (defun wsl-copy (text)
    (with-temp-buffer
      (insert text)
      (call-process-region
       (point-min)
       (point-max)
       "win32yank.exe"
       nil
       nil
       nil
       "-i"
       "--crlf")))

  ;; Paste from Windows clipboard into Emacs
  (defun wsl-paste ()
    (string-trim-right
     (shell-command-to-string "win32yank.exe -o --lf")))

  ;; Integrate with Emacs kill-ring
  (setq interprogram-cut-function #'wsl-copy)
  (setq interprogram-paste-function #'wsl-paste))

(use-package comint
  :ensure nil
  :config
  (setq ansi-color-for-comint-mode t) ; also see `ansi-color-for-compilation-mode'
  (setq comint-prompt-read-only t)
  (setq comint-buffer-maximum-size 9999)
  (setq comint-completion-autolist t)
  (setq comint-input-ignoredups t)
  (setq-default comint-scroll-to-bottom-on-input t)
  (setq-default comint-scroll-to-bottom-on-output nil)
  (setq-default comint-input-autoexpand 'input))

(use-package shell
  :ensure nil
  :bind ( :map shell-mode-map
          ("C-c C-k" . comint-clear-buffer)))

(use-package envrc
  :ensure t
  :config
  (envrc-global-mode 1))

(use-package org
  :ensure nil
  :config
  ;; put your tasks.org or such files here
  (setq org-directory "~/org/")
  ;; M-x org-agenda to read from your files
  (setq org-agenda-files (list org-directory))

  (setq org-todo-keywords
        '((sequence "REPEAT(r)" "NEXT(n)" "TODO(t)" "WAITING(w)" "SOMEDAY(s)" "PROJ(p)" "|" "DONE(d)" "CANCELLED(c)")))

  (defface prot/org-todo-repeat
    '((t :inherit org-todo :foreground "#ff66cc" :weight bold))
    "Face for REPEAT Org keyword.")

  (defface prot/org-todo-next
    '((t :inherit org-todo :foreground "#00d7ff" :weight bold))
    "Face for NEXT Org keyword.")

  (defface prot/org-todo-todo
    '((t :inherit org-todo :foreground "#ff6c6b" :weight bold))
    "Face for TODO Org keyword.")

  (defface prot/org-todo-waiting
    '((t :inherit org-todo :foreground "#d7af5f" :weight bold))
    "Face for WAITING Org keyword.")

  (defface prot/org-todo-someday
    '((t :inherit org-todo :foreground "#a78bfa" :weight bold))
    "Face for SOMEDAY Org keyword.")

  (defface prot/org-todo-proj
    '((t :inherit org-todo :foreground "#51afef" :weight bold))
    "Face for PROJ Org keyword.")

  (defface prot/org-done-done
    '((t :inherit org-done :foreground "#98be65" :weight bold))
    "Face for DONE Org keyword.")

  (defface prot/org-done-cancelled
    '((t :inherit org-done :foreground "#7f8490" :weight bold :strike-through t))
    "Face for CANCELLED Org keyword.")

  (setq org-todo-keyword-faces
        '(("REPEAT" . prot/org-todo-repeat)
          ("NEXT" . prot/org-todo-next)
          ("TODO" . prot/org-todo-todo)
          ("WAITING" . prot/org-todo-waiting)
          ("SOMEDAY" . prot/org-todo-someday)
          ("PROJ" . prot/org-todo-proj)
          ("DONE" . prot/org-done-done)
          ("CANCELLED" . prot/org-done-cancelled))))  

(use-package ef-themes
  :ensure t
  :config
  (load-theme 'ef-summer t))



