;;; workgroups-specialbufs --- special buffers serialization
;;; Commentary:
;;
;; TODO: Possibly add restore-special-data customization option
;; TODO: These could be a little more thorough
;;
;;; Code:

(require 'dflet)
(require 'workgroups-misc)

;; Dired

(defun wg-deserialize-dired-buffer (buf)
  "Deserialize Dired buffer."
  (wg-dbind (this-function params) (wg-buf-special-data buf)
    (let ((dir (car params)))
      (if (or wg-restore-remote-buffers (not (wg-is-file-remote dir)))
          (if (file-exists-p dir)
              (dired dir)))
      (current-buffer))))

(defun wg-serialize-dired-buffer (buffer)
  "Serialize Dired buffer."
  (with-current-buffer buffer
    (when (eq major-mode 'dired-mode)
      (list 'wg-deserialize-dired-buffer
            (wg-take-until-unreadable (list (or (buffer-file-name) default-directory)))
            ))))

;; Info buffer serdes

(defun wg-deserialize-Info-buffer (buf)
  "Deserialize an Info buffer."
  (require 'info)
  (wg-aif (cdr (wg-buf-special-data buf))
      (apply #'Info-find-node it)
    (info))
  (current-buffer))

(defun wg-serialize-Info-buffer (buffer)
  "Serialize an Info buffer."
  (with-current-buffer buffer
    (when (eq major-mode 'Info-mode)
      (wg-when-boundp (Info-current-file Info-current-node)
        (list 'wg-deserialize-Info-buffer
              Info-current-file
              Info-current-node)))))


;; help buffer serdes

(defun wg-deserialize-help-buffer (buf)
  "Deserialize a help buffer BUF.
See `wg-serialize-help-buffer'."
  (require 'help-mode)
  (wg-dbind (this-function item stack forward-stack) (wg-buf-special-data buf)
    (condition-case err
        (apply (car item) (cdr item))
      (error (message "%s" err)))
    (wg-awhen (get-buffer "*Help*")
      (set-buffer it)
      (wg-when-boundp (help-xref-stack help-xref-forward-stack)
        (setq help-xref-stack stack
              help-xref-forward-stack forward-stack))
      (current-buffer))))

(defun wg-serialize-help-buffer (buffer)
  "Serialize a help buffer BUFFER.
Since `help-mode' is used by many buffers that aren't actually
*Help* buffers (e.g. *Process List*), we also check that
`help-xref-stack-item' has a local binding."
  (with-current-buffer buffer
    (when (and (eq major-mode 'help-mode)
               (local-variable-p 'help-xref-stack-item)
               (boundp 'help-xref-stack-item)
               (boundp 'help-xref-stack)
               (boundp 'help-xref-forward-stack))
      (list 'wg-deserialize-help-buffer
            (wg-take-until-unreadable help-xref-stack-item)
            (mapcar 'wg-take-until-unreadable help-xref-stack)
            (mapcar 'wg-take-until-unreadable help-xref-forward-stack)))))


;; ielm buffer serdes

(defun wg-deserialize-ielm-buffer (buf)
  "Deserialize an `inferior-emacs-lisp-mode' buffer BUF."
  (ielm)
  (current-buffer))

(defun wg-serialize-ielm-buffer (buffer)
  "Serialize an `inferior-emacs-lisp-mode' buffer BUFFER."
  (with-current-buffer buffer
    (when (eq major-mode 'inferior-emacs-lisp-mode)
      (list 'wg-deserialize-ielm-buffer))))


;; Wanderlust modes:
;; WL - folders
(defun wg-deserialize-wl-folders-buffer (buf)
  ""
  (if (fboundp 'wl)
      (wg-dbind (this-function) (wg-buf-special-data buf)
        ;;(when (not (eq major-mode 'wl-folder-mode))
        (wl)
        (goto-char (point-max))
        (current-buffer)
        )))

(defun wg-serialize-wl-folders-buffer (buffer)
  ""
  (if (fboundp 'wl)
      (with-current-buffer buffer
        (when (eq major-mode 'wl-folder-mode)
          (list 'wg-deserialize-wl-folders-buffer
                )))))

;; WL - summary mode (list of mails)
;;(defun wg-deserialize-wl-summary-buffer (buf)
;;  ""
;;  (interactive)
;;  (if (fboundp 'wl)
;;      (wg-dbind (this-function param-list) (wg-buf-special-data buf)
;;        (when (not (eq major-mode 'wl-summary-mode))
;;          (let ((fld-name (car param-list)))
;;            ;;(switch-to-buffer "*scratch*")
;;            ;;(wl)
;;            ;;(wl-folder-jump-folder fld-name)
;;            ;;(message fld-name)
;;            ;;(goto-char (point-max))
;;            ;;(insert fld-name)
;;            (current-buffer)
;;          )))))
;;
;;(defun wg-serialize-wl-summary-buffer (buffer)
;;  ""
;;  (if (fboundp 'wl)
;;      (with-current-buffer buffer
;;        (when (eq major-mode 'wl-summary-mode)
;;          (list 'wg-deserialize-wl-summary-buffer
;;                (wg-take-until-unreadable (list wl-summary-buffer-folder-name))
;;                )))))
;;
;;
;;;; mime-view-mode
;;
;;(defun wg-deserialize-mime-view-buffer (buf)
;;  ""
;;  (wg-dbind (this-function) (wg-buf-special-data buf)
;;    (when (not (eq major-mode 'mime-view-mode))
;;      ;;(wl-summary-enter-handler 3570)     ; only in wl-summary-mode
;;      ;;(wl-summary-enter-handler)     ; only in wl-summary-mode
;;      (current-buffer)
;;      )))
;;
;;(defun wg-serialize-mime-view-buffer (buffer)
;;  ""
;;  (with-current-buffer buffer
;;    (when (eq major-mode 'mime-view-mode)
;;      (list 'wg-deserialize-mime-view-buffer
;;            ))))


;; Magit buffers

(defun wg-deserialize-magit-buffer (buf)
  "Deserialize a Magit-status buffer BUF."
  (if (require 'magit nil 'noerror)
      (if (fboundp 'magit-status)
          (wg-dbind (this-function dir) (wg-buf-special-data buf)
            (let ((default-directory (car dir)))
              (if (file-exists-p default-directory)
                  (magit-status default-directory))
              (current-buffer))))))

(defun wg-serialize-magit-buffer (buf)
  "Serialize a Magit-status buffer BUF."
  (if (fboundp 'magit-status-mode)
      (with-current-buffer buf
        (when (eq major-mode 'magit-status-mode)
          (list 'wg-deserialize-magit-buffer
                (wg-take-until-unreadable (list (or (buffer-file-name) default-directory)))
                )))))


;; shell buffer serdes

(defun wg-deserialize-shell-buffer (buf)
  "Deserialize a `shell-mode' buffer BUF.
Run shell with last working dir"
  (wg-dbind (this-function dir) (wg-buf-special-data buf)
    (let ((default-directory (car dir)))
      (shell (wg-buf-name buf))
      (current-buffer)
      )))

(defun wg-serialize-shell-buffer (buffer)
  "Serialize a `shell-mode' buffer BUFFER.
Save shell directory"
  (with-current-buffer buffer
    (when (eq major-mode 'shell-mode)
      (list 'wg-deserialize-shell-buffer
            (wg-take-until-unreadable (list (or (buffer-file-name) default-directory)))
            ))))


;; org-agenda buffer

(defun wg-get-org-agenda-view-commands ()
  "Return commands to restore the state of Agenda buffer.
Can be restored using \"(eval commands)\"."
  (interactive)
  (when (boundp 'org-agenda-buffer-name)
    (if (get-buffer org-agenda-buffer-name)
        (with-current-buffer org-agenda-buffer-name
          (let* ((p (or (and (looking-at "\\'") (1- (point))) (point)))
                 (series-redo-cmd (get-text-property p 'org-series-redo-cmd)))
            (if series-redo-cmd
                (get-text-property p 'org-series-redo-cmd)
              (get-text-property p 'org-redo-cmd)))))))

(defun wg-run-agenda-cmd (f)
  "Run commands \"F\" in Agenda buffer.
You can get these commands using
\"wg-get-org-agenda-view-commands\"."
  (when (and (boundp 'org-agenda-buffer-name)
             (fboundp 'org-current-line)
             (fboundp 'org-goto-line))
    (if (get-buffer org-agenda-buffer-name)
        (save-window-excursion
          (with-current-buffer org-agenda-buffer-name
            (let* ((line (org-current-line)))
              (if f (eval f))
              (org-goto-line line)))))))

(defun wg-deserialize-org-agenda-buffer (buf)
  "Deserialize an `org-agenda-mode' buffer BUF."
  (org-agenda-list)
  (when (boundp 'org-agenda-buffer-name)
    (wg-dbind (this-function item) (wg-buf-special-data buf)
      (wg-awhen (get-buffer org-agenda-buffer-name)
        (set-buffer it)
        (wg-run-agenda-cmd item)
        (current-buffer)))))

(defun wg-serialize-org-agenda-buffer (buffer)
  "Serialize an `org-agenda-mode' buffer BUFFER."
  (with-current-buffer buffer
    (when (eq major-mode 'org-agenda-mode)
      (list 'wg-deserialize-org-agenda-buffer
            (wg-take-until-unreadable (wg-get-org-agenda-view-commands))
            ))))


;; eshell

(defun wg-deserialize-eshell-buffer (buf)
  "Deserialize an `eshell-mode' buffer BUF."
  (prog1 (eshell t)
    (rename-buffer (wg-buf-name buf) t)))

(defun wg-serialize-eshell-buffer (buffer)
  "Serialize an `eshell-mode' buffer BUFFER."
  (with-current-buffer buffer
    (when (eq major-mode 'eshell-mode)
      (list 'wg-deserialize-eshell-buffer))))


;; term and ansi-term buffer serdes

(defun wg-deserialize-term-buffer (buf)
  "Deserialize a `term-mode' buffer BUF."
  (require 'term)
  ;; flet'ing these prevents scrunched up wrapping when restoring during morph
  (dflet ((term-window-width () 80)
         (window-height () 24))
    (prog1 (term (nth 1 (wg-buf-special-data buf)))
      (rename-buffer (wg-buf-name buf) t))))

(defun wg-serialize-term-buffer (buffer)
  "Serialize a `term-mode' buffer BUFFER.
This should work for `ansi-term's, too, as there doesn't seem to
be any difference between the two except how the name of the
buffer is generated."
  (with-current-buffer buffer
    (when (eq major-mode 'term-mode)
      (wg-when-let ((process (get-buffer-process buffer)))
        (list 'wg-deserialize-term-buffer
              (wg-last1 (process-command process)))))))






;;; buffer-local variable serdes

(defun wg-serialize-buffer-mark-ring ()
  "Return a new list of the positions of the marks in `mark-ring'."
  (mapcar 'marker-position mark-ring))

(defun wg-deserialize-buffer-mark-ring (positions)
  "Set `mark-ring' to a new list of markers created from POSITIONS."
  (setq mark-ring
        (mapcar (lambda (pos) (set-marker (make-marker) pos))
                positions)))

(defun wg-deserialize-buffer-major-mode (major-mode-symbol)
  "Conditionally retore MAJOR-MODE-SYMBOL in `current-buffer'."
  (and (fboundp major-mode-symbol)
       (not (eq major-mode-symbol major-mode))
       (funcall major-mode-symbol)))

(defun wg-deserialize-buffer-local-variables (buf)
  "Restore BUF's buffer local variables in `current-buffer'."
  (loop for ((var . val) . rest) on (wg-buf-local-vars buf)
        do (wg-awhen (assq var wg-buffer-local-variables-alist)
             (wg-dbind (var ser des) it
               (if des (funcall des val)
                 (set var val))))))

(provide 'workgroups-specialbufs)
;;; workgroups-specialbufs.el ends here
