;;; -*- lexical-binding: t -*-

(defun tangle-init ()
  "If the current buffer is 'init.org' the code-blocks are
tangled, and the tangled file is compiled."
  (when (equal (buffer-file-name)
               (expand-file-name (concat user-emacs-directory "init.org")))
    ;; Avoid running hooks when tangling.
    (let ((prog-mode-hook nil))
      (org-babel-tangle)
      (byte-compile-file (concat user-emacs-directory "init.el")))))

(add-hook 'after-save-hook 'tangle-init)

(add-hook
 'after-init-hook
 (lambda ()
   (let ((private-file (concat user-emacs-directory "private.el")))
     (when (file-exists-p private-file)
       (load-file private-file))
     (when custom-file
       (load-file custom-file))
     (server-start))))

(let ((old-gc-treshold gc-cons-threshold))
  (setq gc-cons-threshold most-positive-fixnum)
  (add-hook 'after-init-hook
            (lambda () (setq gc-cons-threshold old-gc-treshold))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

(require 'package)
(package-initialize)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("MELPA" . "https://melpa.org/packages/"))
      package-archive-priorities
      '(("MELPA" . 5)
        ("gnu" . 0)))

(let* ((package--builtins nil)
       (packages
        '(auto-compile         ; automatically compile Emacs Lisp libraries
          company              ; Modular text completion framework
          company-coq          ; A collection of extensions PG's Coq mode
          counsel              ; Various completion functions using Ivy
          counsel-projectile   ; Ivy integration for Projectile
          define-word          ; display the definition of word at point
          diff-hl              ; Highlight uncommitted changes using VC
          doom-themes          ; An opinionated pack of modern color-themes
          expand-region        ; Increase selected region by semantic units
          focus                ; Dim color of text in surrounding sections
          golden-ratio         ; Automatic resizing windows to golden ratio
          magit                ; control Git from Emacs
          markdown-mode        ; Emacs Major mode for Markdown-formatted files
          multiple-cursors     ; Multiple cursors for Emacs
          olivetti             ; Minor mode for a nice writing environment
          org                  ; Outline-based notes management and organizer
          org-bullets          ; Show bullets in org-mode as UTF-8 characters
          paredit              ; minor mode for editing parentheses
          pdf-tools            ; Emacs support library for PDF files
          projectile           ; Manage and navigate projects in Emacs easily
          proof-general        ; A generic Emacs interface for proof assistants
          slime                ; Superior Lisp Interaction Mode for Emacs
          smex                 ; M-x interface with Ido-style fuzzy matching
          try                  ; Try out Emacs packages
          vterm                ; A terminal via libvterm
          which-key            ; Display available keybindings in popup
          )))
  (when (memq window-system '(mac ns))
    (push 'exec-path-from-shell packages)
    (push 'reveal-in-osx-finder packages))
  (let ((packages (seq-remove 'package-installed-p packages)))
    (print packages)
    (when packages
      ;; Install uninstalled packages
      (package-refresh-contents)
      (mapc 'package-install packages))))

(setq auto-revert-interval 1            ; Refresh buffers fast
      default-input-method "TeX"        ; Use TeX when toggling input method
      echo-keystrokes 0.1               ; Show keystrokes asap
      inhibit-startup-screen t          ; No splash screen please
      initial-scratch-message nil       ; Clean scratch buffer
      recentf-max-saved-items 100       ; Show more recent files
      ring-bell-function 'ignore        ; Quiet
      scroll-margin 1                   ; Space between cursor and top/bottom
      sentence-end-double-space nil     ; No double space
      custom-file                       ; Customizations in a separate file
      (concat user-emacs-directory "custom.el"))
;; Some mac-bindings interfere with Emacs bindings.
(when (boundp 'mac-pass-command-to-system)
  (setq mac-pass-command-to-system nil))

(setq-default tab-width 4                       ; Smaller tabs
              fill-column 79                    ; Maximum line width
              truncate-lines t                  ; Don't fold lines
              indent-tabs-mode nil              ; Use spaces instead of tabs
              split-width-threshold 160         ; Split verticly by default
              split-height-threshold nil        ; Split verticly by default
              frame-resize-pixelwise t          ; Fine-grained frame resize
              auto-fill-function 'do-auto-fill) ; Auto-fill-mode everywhere

(let ((default-directory (concat user-emacs-directory "site-lisp/")))
  (when (file-exists-p default-directory)
    (setq load-path
          (append
           (let ((load-path (copy-sequence load-path)))
             (normal-top-level-add-subdirs-to-load-path)) load-path))))

(fset 'yes-or-no-p 'y-or-n-p)

(defvar emacs-autosave-directory
  (concat user-emacs-directory "autosaves/")
  "This variable dictates where to put auto saves. It is set to a
  directory called autosaves located wherever your .emacs.d/ is
  located.")

;; Sets all files to be backed up and auto saved in a single directory.
(setq backup-directory-alist
      `((".*" . ,emacs-autosave-directory))
      auto-save-file-name-transforms
      `((".*" ,emacs-autosave-directory t)))

(set-language-environment "UTF-8")

(put 'narrow-to-region 'disabled nil)

(add-hook 'doc-view-mode-hook 'auto-revert-mode)

(dolist (mode
         '(tool-bar-mode                ; No toolbars, more room for text
           scroll-bar-mode              ; No scroll bars either
           blink-cursor-mode))          ; The blinking cursor gets old
  (funcall mode 0))

(dolist (mode
         '(abbrev-mode                  ; E.g. sopl -> System.out.println
           column-number-mode           ; Show column number in mode line
           delete-selection-mode        ; Replace selected text
           dirtrack-mode                ; directory tracking in *shell*
           global-company-mode          ; Auto-completion everywhere
           global-diff-hl-mode          ; Highlight uncommitted changes
           global-so-long-mode          ; Mitigate performance for long lines
           counsel-projectile-mode      ; Manage and navigate projects
           recentf-mode                 ; Recently opened files
           show-paren-mode              ; Highlight matching parentheses
           which-key-mode))             ; Available keybindings in popup
  (funcall mode 1))
; TODO warn (auto-compile-on-save-mode 1) is a malformed function
;   (eval-after-load 'auto-compile
;     '((auto-compile-on-save-mode)))  ; compile .el files on save

(load-theme 'doom-one-light t)

(defun cycle-themes ()
  "Returns a function that lets you cycle your themes."
  (let ((themes '#1=(doom-one-light doom-one . #1#)))
    (lambda ()
      (interactive)
      ;; Rotates the thme cycle and changes the current theme.
      (load-theme (car (setq themes (cdr themes))) t)
      (message (concat "Switched to " (symbol-name (car themes)))))))

(cond ((member "Hasklig" (font-family-list))
       (set-face-attribute 'default nil :font "Hasklig-16"))
      ((member "Inconsolata" (font-family-list))
       (set-face-attribute 'default nil :font "Inconsolata-16")))

(add-to-list 'default-frame-alist '(internal-border-width . 24))

;; simplified mode line
(define-key mode-line-major-mode-keymap [header-line]
  (lookup-key mode-line-major-mode-keymap [mode-line]))

(defun mode-line-render (left right)
  (let* ((available-width (- (window-total-width) (length left))))
    (format (format "%%s %%%ds" available-width) left right)))

(setq-default
 header-line-format
 '((:eval
    (propertize
     (mode-line-render
      (format-mode-line
       (list (propertize "☰" 'face `(:inherit mode-line-buffer-id)
                         'help-echo "Mode(s) menu"
                         'mouse-face 'mode-line-highlight
                         'local-map   mode-line-major-mode-keymap)
             " %b "
             (if (and buffer-file-name (buffer-modified-p))
                 (propertize "(modified)" 'face `(:inherit font-lock-comment-face)))))
      (format-mode-line
       (propertize "%4l:%2c  " 'face
                   `(:inherit font-lock-comment-face))))
     'face `(:underline ,(face-foreground 'font-lock-comment-face))))))

(setq-default mode-line-format nil)

(setq-default prettify-symbols-alist '(("lambda" . ?λ)
                                       ("delta" . ?Δ)
                                       ("gamma" . ?Γ)
                                       ("phi" . ?φ)
                                       ("psi" . ?ψ)))

(with-eval-after-load 'olivetti
  (setq-default olivetti-body-width 82)
  (remove-hook 'olivetti-mode-on-hook 'visual-line-mode))

(setq ivy-wrap t
      ivy-height 25
      ivy-use-virtual-buffers t
      ivy-count-format "(%d/%d) "
      ivy-on-del-error-function 'ignore)
(ivy-mode 1)

(add-to-list 'auto-mode-alist '("\\.pdf\\'" . pdf-tools-install))

(add-hook 'pdf-view-mode-hook
          (lambda () (setq header-line-format nil)))

(setq company-idle-delay 0
      company-echo-delay 0
      company-dabbrev-downcase nil
      company-minimum-prefix-length 2
      company-selection-wrap-around t
      company-transformers '(company-sort-by-occurrence
                             company-sort-by-backend-importance))

(add-hook 'text-mode-hook 'turn-on-flyspell)

(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(defun cycle-languages ()
  "Changes the ispell dictionary to the first element in
ISPELL-LANGUAGES, and returns an interactive function that cycles
the languages in ISPELL-LANGUAGES when invoked."
  (let ((ispell-languages '#1=("american" "norsk" . #1#)))
    (ispell-change-dictionary (car ispell-languages))
    (lambda ()
      (interactive)
      ;; Rotates the languages cycle and changes the ispell dictionary.
      (ispell-change-dictionary
       (car (setq ispell-languages (cdr ispell-languages)))))))

(defadvice turn-on-flyspell (before check nil activate)
  "Turns on flyspell only if a spell-checking tool is installed."
  (when (executable-find ispell-program-name)
    (local-set-key (kbd "C-c l") (cycle-languages))))

(defadvice flyspell-prog-mode (before check nil activate)
  "Turns on flyspell only if a spell-checking tool is installed."
  (when (executable-find ispell-program-name)
    (local-set-key (kbd "C-c l") (cycle-languages))))

(setq org-src-fontify-natively t
      org-src-tab-acts-natively t
      org-confirm-babel-evaluate nil
      org-edit-src-content-indentation 0)

(with-eval-after-load 'org
  (require 'org-tempo)
  (setcar (nthcdr 2 org-emphasis-regexp-components) " \t\n,")
  (custom-set-variables `(org-emphasis-alist ',org-emphasis-alist)))

(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))

(defun cycle-spacing-delete-newlines ()
  "Removes whitespace before and after the point."
  (interactive)
  (if (version< emacs-version "24.4")
      (just-one-space -1)
    (cycle-spacing -1)))

(defun jump-to-symbol-internal (&optional backwardp)
  "Jumps to the next symbol near the point if such a symbol
exists. If BACKWARDP is non-nil it jumps backward."
  (let* ((point (point))
         (bounds (find-tag-default-bounds))
         (beg (car bounds)) (end (cdr bounds))
         (str (isearch-symbol-regexp (find-tag-default)))
         (search (if backwardp 'search-backward-regexp
                   'search-forward-regexp)))
    (goto-char (if backwardp beg end))
    (funcall search str nil t)
    (cond ((<= beg (point) end) (goto-char point))
          (backwardp (forward-char (- point beg)))
          (t  (backward-char (- end point))))))

(defun jump-to-previous-like-this ()
  "Jumps to the previous occurrence of the symbol at point."
  (interactive)
  (jump-to-symbol-internal t))

(defun jump-to-next-like-this ()
  "Jumps to the next occurrence of the symbol at point."
  (interactive)
  (jump-to-symbol-internal))

(defun kill-this-buffer-unless-scratch ()
  "Works like `kill-this-buffer' unless the current buffer is the
*scratch* buffer. In witch case the buffer content is deleted and
the buffer is buried."
  (interactive)
  (if (not (string= (buffer-name) "*scratch*"))
      (kill-this-buffer)
    (delete-region (point-min) (point-max))
    (switch-to-buffer (other-buffer))
    (bury-buffer "*scratch*")))

(defun duplicate-thing (comment)
  "Duplicates the current line, or the region if active. If an argument is
given, the duplicated region will be commented out."
  (interactive "P")
  (save-excursion
    (let ((start (if (region-active-p) (region-beginning) (point-at-bol)))
          (end   (if (region-active-p) (region-end) (point-at-eol)))
          (fill-column most-positive-fixnum))
      (goto-char end)
      (unless (region-active-p)
        (newline))
      (insert (buffer-substring start end))
      (when comment (comment-region start end)))))

(defun tidy ()
  "Ident, untabify and unwhitespacify current buffer, or region if active."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
    (indent-region beg end)
    (whitespace-cleanup)
    (untabify beg (if (< end (point-max)) end (point-max)))))

(defadvice eval-last-sexp (around replace-sexp (arg) activate)
  "Replace sexp when called with a prefix argument."
  (if arg
      (let ((pos (point)))
        ad-do-it
        (goto-char pos)
        (backward-kill-sexp)
        (forward-sexp))
    ad-do-it))

(defadvice load-theme
    (before disable-before-load (theme &optional no-confirm no-enable) activate)
  (mapc 'disable-theme custom-enabled-themes))

(let* ((default (face-attribute 'default :height))
         (size default))

    (defun global-scale-default ()
      (interactive)
      (global-scale-internal (setq size default)))

    (defun global-scale-up ()
      (interactive)
      (global-scale-internal (setq size (+ size 20))))

    (defun global-scale-down ()
      (interactive)
      (global-scale-internal (setq size (- size 20))))

;  TODO-warn set-temporary-overlay-map is an obsolete function (as of 24.4); use set-transient-map instead.
    (defun global-scale-internal (arg)
      (set-face-attribute 'default (selected-frame) :height arg)
      (set-transient-map
       (let ((map (make-sparse-keymap)))
         (define-key map (kbd "C-=") 'global-scale-up)
         (define-key map (kbd "C-+") 'global-scale-up)
         (define-key map (kbd "C--") 'global-scale-down)
         (define-key map (kbd "C-0") 'global-scale-default) map))))

(add-hook 'compilation-filter-hook 'comint-truncate-buffer)

(let ((last-vterm ""))
  (defun toggle-vterm ()
    (interactive)
    (cond ((string-match-p "^\\vterm<[1-9][0-9]*>$" (buffer-name))
           (goto-non-vterm-buffer))
          ((get-buffer last-vterm) (switch-to-buffer last-vterm))
          (t (vterm (setq last-vterm "vterm<1>")))))

  (defun switch-vterm (n)
    (let ((buffer-name (format "vterm<%d>" n)))
      (setq last-vterm buffer-name)
      (cond ((get-buffer buffer-name)
             (switch-to-buffer buffer-name))
            (t (vterm buffer-name)
               (rename-buffer buffer-name)))))

  (defun goto-non-vterm-buffer ()
    (let* ((r "^\\vterm<[1-9][0-9]*>$")
           (vterm-buffer-p (lambda (b) (string-match-p r (buffer-name b))))
           (non-vterms (cl-remove-if vterm-buffer-p (buffer-list))))
      (when non-vterms
        (switch-to-buffer (car non-vterms))))))

(defadvice vterm (after kill-with-no-query nil activate)
  (set-process-query-on-exit-flag (get-buffer-process ad-return-value) nil))

(setq vterm-shell "/usr/local/bin/zsh")

(defun clear-comint ()
  "Runs `comint-truncate-buffer' with the
`comint-buffer-maximum-size' set to zero."
  (interactive)
  (let ((comint-buffer-maximum-size 0))
    (comint-truncate-buffer)))

(dolist (mode '(cider-repl-mode
                clojure-mode
                ielm-mode
                racket-mode
                racket-repl-mode
                slime-repl-mode
                lisp-mode
                emacs-lisp-mode
                lisp-interaction-mode
                scheme-mode))
  ;; add paredit-mode to all mode-hooks
  (add-hook (intern (concat (symbol-name mode) "-hook")) 'paredit-mode))

(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)

(add-to-list 'auto-mode-alist '("\\.tex\\'" . latex-mode))

(setq-default bibtex-dialect 'biblatex)

(eval-after-load 'org
  '(add-to-list 'org-latex-packages-alist '("" "minted")))
(setq org-latex-listings 'minted)

(require 'org)
(add-to-list 'org-file-apps '("\\.pdf\\'" . emacs))

(defvar custom-bindings-map (make-keymap)
  "A keymap for custom bindings.")

(define-key custom-bindings-map (kbd "C-c D") 'define-word-at-point)

(define-key custom-bindings-map (kbd "C->")  'er/expand-region)
(define-key custom-bindings-map (kbd "C-<")  'er/contract-region)

(define-key custom-bindings-map (kbd "C-c e")  'mc/edit-lines)
(define-key custom-bindings-map (kbd "C-c a")  'mc/mark-all-like-this)
(define-key custom-bindings-map (kbd "C-c n")  'mc/mark-next-like-this)

(define-key custom-bindings-map (kbd "C-c m") 'magit-status)

(global-set-key (kbd "C-c i")     'swiper-isearch)
(global-set-key (kbd "M-x")     'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "M-y")     'counsel-yank-pop)
(global-set-key (kbd "C-x b")   'ivy-switch-buffer)

(define-key company-active-map (kbd "C-d") 'company-show-doc-buffer)
(define-key company-active-map (kbd "C-n") 'company-select-next)
(define-key company-active-map (kbd "C-p") 'company-select-previous)
(define-key company-active-map (kbd "<tab>") 'company-complete)

(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(define-key custom-bindings-map (kbd "C-c o") 'olivetti-mode)

(define-key custom-bindings-map (kbd "M-u")         'upcase-dwim)
(define-key custom-bindings-map (kbd "M-c")         'capitalize-dwim)
(define-key custom-bindings-map (kbd "M-l")         'downcase-dwim)
(define-key custom-bindings-map (kbd "M-]")         'other-frame)
(define-key custom-bindings-map (kbd "C-j")         'newline-and-indent)
(define-key custom-bindings-map (kbd "C-c s")       'ispell-word)
(define-key comint-mode-map     (kbd "C-l")         'clear-comint)

(define-key global-map          (kbd "M-p")     'jump-to-previous-like-this)
(define-key global-map          (kbd "M-n")     'jump-to-next-like-this)
(define-key custom-bindings-map (kbd "M-,")     'jump-to-previous-like-this)
(define-key custom-bindings-map (kbd "M-.")     'jump-to-next-like-this)
(define-key custom-bindings-map (kbd "C-c .")   (cycle-themes))
(define-key custom-bindings-map (kbd "C-x k")   'kill-this-buffer-unless-scratch)
(define-key custom-bindings-map (kbd "C-c C-0") 'global-scale-default)
(define-key custom-bindings-map (kbd "C-c C-=") 'global-scale-up)
(define-key custom-bindings-map (kbd "C-c C-+") 'global-scale-up)
(define-key custom-bindings-map (kbd "C-c C--") 'global-scale-down)
(define-key custom-bindings-map (kbd "C-c j")   'cycle-spacing-delete-newlines)
(define-key custom-bindings-map (kbd "C-c d")   'duplicate-thing)
(define-key custom-bindings-map (kbd "<C-tab>") 'tidy)
(define-key custom-bindings-map (kbd "C-z")     'toggle-vterm)
(dolist (n (number-sequence 1 9))
  (global-set-key (kbd (concat "M-" (int-to-string n)))
                  (lambda () (interactive) (switch-vterm n))))
(define-key custom-bindings-map (kbd "C-c C-q")
  '(lambda ()
     (interactive)
     (focus-mode 1)
     (focus-read-only-mode 1)))
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-'") 'org-sync-pdf))

(define-minor-mode custom-bindings-mode
  "A mode that activates custom-bindings."
  t nil custom-bindings-map)
