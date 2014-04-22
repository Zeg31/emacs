(require 'color)

(let ((bg (face-attribute 'default :background)))
  (custom-set-faces
   `(company-tooltip ((t (:inherit default :background ,(color-darken-name bg 2)))))
   `(company-scrollbar-bg ((t (:background ,(color-lighten-name bg 10)))))
   `(company-scrollbar-fg ((t (:background ,(color-lighten-name bg 10)))))
   `(company-tooltip-selection ((t (:inherit font-lock-function-name-face :background ,(color-lighten-name bg 5)))))
   `(company-tooltip-common ((t (:inherit font-lock-constant-face))))))

;; Auto-complete
(add-hook 'after-init-hook 'global-company-mode)

;; yasnippet backend shadows other completions, see https://github.com/company-mode/company-mode/blob/master/company-yasnippet.el for solutions
;;(eval-after-load 'company '(add-to-list 'company-backends 'company-yasnippet))

;;(eval-after-load 'company '(add-to-list 'company-backends 'company-files))
(eval-after-load 'company '(add-to-list 'company-transformers 'company-sort-by-occurrence))

;;(setq company-backends '(company-dabbrev (company-keywords company-dabbrev-code) company-files))
;;(setq company-begin-commands '(self-insert-command org-self-insert-command c-electric-lt-gt c-electric-colon))

(setq company-idle-delay 0.3)
(setq company-tooltip-limit 20)
(setq company-minimum-prefix-length 2)
(setq company-echo-delay 0)
(setq company-auto-complete nil)
(setq company-selection-wrap-around t)
(setq company-show-numbers nil)
(setq company-dabbrev-other-buffers t)
;;(setq company-auto-complete-chars nil)

;; org-mode completions
(defun my-pcomplete-capf ()
  (add-hook 'completion-at-point-functions 'pcomplete-completions-at-point nil t))
(add-hook 'org-mode-hook #'my-pcomplete-capf)

(provide 'auto-complete-settings)
