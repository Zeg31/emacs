;; open clojurescript files in clojure mode
(add-to-list 'auto-mode-alist '("\.cljs$" . clojure-mode))
;; open boot build tool files in clojure mode
(add-to-list 'auto-mode-alist '("\.boot$" . clojure-mode))

;; ENHANCE lISP MODES
(require 'paxedit)

(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'emacs-lisp-mode-hook 'esk-remove-elc-on-save)
(add-hook 'emacs-lisp-mode-hook 'esk-prog-mode-hook)
(add-hook 'emacs-lisp-mode-hook 'elisp-slime-nav-mode)
(add-hook 'emacs-lisp-mode-hook 'paredit-mode)
(add-hook 'emacs-lisp-mode-hook 'paxedit-mode)
(add-hook 'clojure-mode-hook 'paredit-mode)
(add-hook 'clojure-mode-hook 'paxedit-mode)

;; prettify fn in clojure/clojurescript
(add-hook 'clojure-mode-hook 'pretty-fn)
(add-hook 'clojurescript-mode-hook 'pretty-fn)

;;---------------------------------------------------------
(require 'clojure-mode-extra-font-locking)

;;; CIDER CONFIG
(require 'cider)

(defun hide-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(add-hook 'cider-repl-mode-hook 'hide-eol)
(add-hook 'cider-popup-buffer-mode-hook 'hide-eol)

(setq nrepl-hide-special-buffers t)
(setq cider-prompt-save-file-on-load nil)

(setq cider-repl-print-length 100) ; Limit the number of items of each collection the printer will print to 100

(eval-after-load "cider"
  '(progn
     (setq cider-repl-pop-to-buffer-on-connect nil) ; Prevent the auto-display of the REPL buffer in a separate window after connection is established
     (setq cider-repl-use-clojure-font-lock t)
     (setq cider-show-error-buffer nil)
     (setq cider-jump-to-compilation-error nil)
     (setq cider-auto-jump-to-error nil)
     (add-to-list 'same-window-buffer-names "*cider*") ;Make C-c C-z switch to the *nrepl* buffer in the current window
     ))

(add-hook 'cider-mode-hook 'cider-turn-on-eldoc-mode) ; Enable eldoc in clojure buffers
(add-hook 'cider-repl-mode-hook #'subword-mode) ;Enabling CamelCase support for editing commands(like forward-word, backward-word, etc) in nREPL
;;(add-hook 'cider-repl-mode-hook 'smartparens-strict-mode) ;Enable smartparens strict mode in nRepl buffer
(add-hook 'cider-repl-mode-hook #'paredit-mode) ;Enable paredit in nRepl buffer
(add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode) ; rainbow delimiters
(add-hook 'cider-repl-mode-hook '(lambda () (linum-mode 0)))

;; Clojure mode
(add-hook 'clojure-mode-hook 'cider-mode)


;;; RAINBOW DELIMITERS
;;(require 'rainbow-delimiters)
;;(add-hook 'prog-mode-hook 'rainbow-delimiters-mode) ; all programming modes
;;(global-rainbow-delimiters-mode) ; globally

(provide 'lisp-settings)
