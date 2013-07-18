;;; workgroups2.el --- New workspaces for Emacs
;;
;; Copyright (C) 2013 Sergey Pashinin
;; Copyright (C) 2010, 2011 tlh
;;
;; Author: Sergey Pashinin <sergey at pashinin dot com>
;; Keywords: session management window-configuration persistence
;; Homepage: https://github.com/pashinin/workgroups2

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;;; Commentary:
;;
;; Workgroups2 is an Emacs session manager. It is based on the
;; experimental branch of the original "workgroups" extension.
;;
;; If you find a bug - please post it here:
;; https://github.com/pashinin/workgroups2/issues
;;
;;
;; Install
;; ----------------------
;; See the README.md file at: https://github.com/pashinin/workgroups2
;; Add the lines below to your .emacs configuration.
;; You can also set some keyboard shortcuts.
;;
;; (require 'workgroups2)
;;
;; (desktop-save-mode t)       ; save all opened files (or disable it)
;; (setq wg-prefix-key (kbd "C-c z")
;;       wg-restore-associated-buffers nil ; all buffers opened in current WG
;;       wg-use-default-session-file nil   ; turn off for "emacs --daemon"
;;       wg-default-session-file "~/.emacs_files/workgroups"
;;       wg-use-faces nil
;;       wg-morph-on nil)    ; animation off
;; (workgroups-mode 1)       ; Activate workgroups
;;
;; (global-set-key (kbd "<pause>")     'wg-reload-session)
;; (global-set-key (kbd "C-S-<pause>") 'wg-save-session)
;; (global-set-key (kbd "s-z")         'wg-switch-to-workgroup)
;; (global-set-key (kbd "s-/")         'wg-switch-to-previous-workgroup)
;;
;;
;; Usage
;; ----------------------
;; Most commands start with prefix `wg-prefix-key' (see above).
;; <prefix> <key>
;;
;; <prefix> c    - create workgroup
;; <prefix> k    - kill workgroup
;; <prefix> v    - switch to workgroup
;; <prefix> C-s  - save session
;; <prefix> C-f  - load session
;;
;; Help
;; ----------------------
;; Type "<prefix> ?" for more help
;;
;; See also: https://github.com/pashinin/workgroups2/wiki
;;
;;; Code:

(require 'dflet)
(require 'workgroups-compat)
(require 'workgroups-utils-basic)
(require 'workgroups-pickel)

(eval-when-compile ;; bytecomp warnings begone!
  (require 'ido nil t)
  (require 'iswitchb nil t))

(require 'workgroups-variables)
(require 'workgroups-functions)
(require 'workgroups-advice)
(require 'workgroups-commands)
(require 'workgroups-keys)



;;; workgroups-everywhere

(define-minor-mode workgroups-everywhere
  "Use Workgroups' buffer list filters everywhere `read-buffer' is used."
  :global t
  :group 'workgroups
  (wg-awhen (get 'workgroups-everywhere 'read-buffer-fn)
    (when (eq read-buffer-function 'wg-read-buffer)
      (setq read-buffer-function it))
    (put 'workgroups-everywhere 'read-buffer-fn nil))
  (when workgroups-everywhere
    (put 'workgroups-everywhere 'read-buffer-fn read-buffer-function)
    (setq read-buffer-function 'wg-read-buffer)))



;;; wg-minibuffer-mode

(defvar wg-minibuffer-mode-minor-mode-map-entry
  (cons 'wg-minibuffer-mode wg-minibuffer-mode-map)
  "`wg-minibuffer-mode's entry in `minor-mode-map-alist'.")

(define-minor-mode wg-minibuffer-mode
  "Minor mode for Workgroups' minibuffer commands."
  :global t
  :group 'workgroups
  (when wg-minibuffer-mode
    (add-to-list 'minor-mode-map-alist
                 wg-minibuffer-mode-minor-mode-map-entry)))

(defun wg-turn-on-minibuffer-mode ()
  "`minibuffer-setup-hook' to turn on `wg-minibuffer-mode'."
  (when wg-current-buffer-list-filter-id
    (wg-minibuffer-mode 1)))

(defun wg-turn-off-minibuffer-mode ()
  "`minibuffer-exit-hook' to turn off `wg-minibuffer-mode'."
  (wg-minibuffer-mode -1))



;;; workgroups-mode

(defun wg-reload-session ()
  "Reload current workgroups session."
  (interactive)
  (let ((file (or (wg-determine-session-save-file-name)
                  wg-default-session-file)))
    (when (file-exists-p file)
      (condition-case err
          (wg-find-session-file wg-default-session-file)
        (error (message "Error finding session-file: %s" err))))))

(defun wg-find-session-file-on-workgroups-mode-entry ()
  "This function is called when activating workgroups mode. It
loads a session file set in `wg-default-session-file' variable if
`wg-use-default-session-file' is t."
  (when (and wg-use-default-session-file
             (file-exists-p wg-default-session-file))
    (condition-case err
        (wg-find-session-file wg-default-session-file)
      (error (message "Error finding `wg-default-session-file': %s" err)))))

(defun wg-save-session-on-emacs-exit ()
  "Call `wg-save-session-on-exit' with `wg-emacs-exit-save-behavior'.
Added to `kill-emacs-query-functions'."
  (wg-save-session-on-exit wg-emacs-exit-save-behavior)
  t)

(defun wg-save-session-on-workgroups-mode-exit ()
  "Call `wg-save-session-on-exit' with `wg-workgroups-mode-exit-save-behavior'.
Called when `workgroups-mode' is turned off."
  (wg-save-session-on-exit wg-workgroups-mode-exit-save-behavior)
  t)

(defun wg-add-or-remove-workgroups-hooks (remove)
  "Add or remove all of Workgroups' hooks, depending on REMOVE."
  (wg-add-or-remove-hooks
   remove
   'kill-emacs-query-functions 'wg-save-session-on-emacs-exit
   'delete-frame-hook 'wg-update-working-wconfig-on-delete-frame
   'wg-pre-window-configuration-change-hook 'wg-update-working-wconfig-hook
   'window-configuration-change-hook 'wg-flag-window-configuration-changed
   'post-command-hook 'wg-undoify-window-configuration-change
   'minibuffer-setup-hook 'wg-turn-on-minibuffer-mode
   'minibuffer-exit-hook 'wg-flag-just-exited-minibuffer
   'minibuffer-exit-hook 'wg-turn-off-minibuffer-mode
   'ido-make-buffer-list-hook 'wg-set-ido-buffer-list
   'iswitchb-make-buflist-hook 'wg-set-iswitchb-buffer-list
   'kill-buffer-hook 'wg-auto-dissociate-buffer-hook
   'kill-buffer-hook 'wg-update-buffer-in-buf-list
   'window-configuration-change-hook 'wg-associate-frame-buffers
   'after-make-frame-functions 'wg-after-make-frame))

(defun wg-add-workgroups-mode-minor-mode-entries ()
  "Add Workgroups' minor-mode entries.
Adds entries to `minor-mode-list', `minor-mode-alist' and
`minor-mode-map-alist'."
  (pushnew 'workgroups-mode minor-mode-list)
  (pushnew '(workgroups-mode " wg") minor-mode-alist :test 'equal)
  (setq minor-mode-map-alist
        (cons (cons 'workgroups-mode (wg-make-workgroups-mode-map))
              (delete (assoc 'workgroups-mode minor-mode-map-alist)
                      minor-mode-map-alist))))

(defun workgroups-mode (&optional arg)
  "Turns `workgroups-mode' on and off.
If ARG is null, toggle `workgroups-mode'.
If ARG is an integer greater than zero, turn on `workgroups-mode'.
If ARG is an integer less one, turn off `workgroups-mode'.
If ARG is anything else, turn on `workgroups-mode'."
  (interactive (list current-prefix-arg))
  (setq workgroups-mode
        (cond ((not arg) (not workgroups-mode))
              ((integerp arg) (if (> arg 0) t nil))
              (t)))
  (cond
   (workgroups-mode
    (wg-reset-internal)
    (wg-add-workgroups-mode-minor-mode-entries)
    (wg-enable-all-advice)
    (wg-add-or-remove-workgroups-hooks nil)
    ;;(mapcar 'wg-after-make-frame (frame-list))
    (mapc 'wg-after-make-frame (frame-list))
    (wg-add-mode-line-display)
    (wg-find-session-file-on-workgroups-mode-entry)
    (run-hooks 'workgroups-mode-hook))
   (t
    (wg-save-session-on-workgroups-mode-exit)
    (wg-disable-all-advice)
    (wg-add-or-remove-workgroups-hooks t)
    (wg-remove-mode-line-display)
    (run-hooks 'workgroups-mode-exit-hook)))
  (wg-fontified-message
    (:cmd "Workgroups Mode: ")
    (:msg (if workgroups-mode "on" "off")))
  workgroups-mode)

(provide 'workgroups2)
;;; workgroups2.el ends here
