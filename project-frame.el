;;; project-frame.el -- Frame window configuration for MHJ
;;; Commentary:
;;; Various functions that I use to setup my frames with dedicated
;;; windows and buffers.
;;;
;;; Some helpful links:
;;;
;;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Display-Action-Functions.html
;;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Dedicated-Windows.html#Dedicated-Windows
;;;
;;; Code:


;; --------------
;; project explorer.
;; --------------

(defun mhj/toggle-project-explorer ()
  "Toggle the project explorer window."
  (interactive)
  (let* ((buffer (dired-noselect (projectile-project-root)))
        (window (get-buffer-window buffer)))
    (if window
        (mhj/hide-project-explorer)
      (mhj/show-project-explorer))))

(defun mhj/show-project-explorer ()
  "Project dired buffer on the side of the frame.
Shows the projectile root folder using dired on the left side of
the frame and makes it a dedicated window for that buffer."
  (let ((buffer (dired-noselect (projectile-project-root))))
    (progn
      (display-buffer-in-side-window buffer '((side . right) (window-width . 0.2)))
      (set-window-dedicated-p (get-buffer-window buffer) t))))

(defun mhj/hide-project-explorer ()
  "Hide the project-explorer window."
  (let ((buffer (dired-noselect (projectile-project-root))))
    (progn
      (delete-window (get-buffer-window buffer))
      (kill-buffer buffer))))

;; --------------
;; info sidebar.
;; --------------

(defun mhj/show-info-sidebar ()
  "Create and show side windows with a set of buffers."
  (interactive)
  (show-magit-status-window)
  (show-projectile-ibuffer-window)
  (show-flycheck-window))

(defun mhj/hide-info-sidebar ()
  "Create and show side windows with a set of buffers."
  (interactive)
  (hide-magit-status-window)
  (hide-projectile-ibuffer-window)
  (hide-flycheck-window))


;; --------------
;; magit-status
;; --------------

(defun show-magit-status-window ()
  (mhj/magit-setup-status-mode-buffer)
  (let ((magit-status-buffer (magit-mode-get-buffer #'magit-status-mode t)))
    (progn
      (display-buffer-in-side-window
       magit-status-buffer
       '((side . right)
         (window-width . 0.3)
         (slot . 0)))
      (set-window-dedicated-p (get-buffer-window magit-status-buffer) t))))

(defun hide-magit-status-window ()
  (interactive)
  (let ((magit-status-buffer (magit-mode-get-buffer #'magit-status-mode t)))
    (progn
      (delete-window (get-buffer-window magit-status-buffer))
      (kill-buffer magit-status-buffer))))

(defun mhj/magit-setup-status-mode-buffer ()
  "Change of magit-setup-mode that doesn't display the buffer."
  (let ((buffer (magit-mode-get-buffer #'magit-status-mode t)))
    (with-current-buffer buffer
      (setq magit-previous-section nil)
      (magit-status-mode)
      (magit-refresh-buffer))))


;; --------------
;; flycheck
;; --------------

(defun show-flycheck-window ()
    (let ((flycheck-buffer (mhj/get-or-create-flycheck-list-errors-buffer)))
    (progn
      (display-buffer-in-side-window
       flycheck-buffer
       '((side . right)
         (window-width . 0.3)
         (slot . 1)))
      (set-window-dedicated-p (get-buffer-window flycheck-buffer) t)
      (flycheck-error-list-refresh))))

(defun hide-flycheck-window ()
  (let ((flycheck-buffer (mhj/get-or-create-flycheck-list-errors-buffer)))
    (progn
      (delete-window (get-buffer-window flycheck-buffer))
      (kill-buffer flycheck-buffer))))

(defun mhj/get-or-create-flycheck-list-errors-buffer ()
  "Get or create the flycheck list errors buffer.
This is a modified version of `flycheck-list-errors` which returns the
buffer without dislpaying it."
  (unless flycheck-mode
    (user-error "Flycheck mode not enabled"))
  ;; Create and initialize the error list
  (unless (get-buffer flycheck-error-list-buffer)
    (with-current-buffer (get-buffer-create flycheck-error-list-buffer)
      (flycheck-error-list-mode)))
  (flycheck-error-list-set-source (current-buffer))
  ;; Reset the error filter
  (flycheck-error-list-reset-filter)
  ;; Show the error list in a window, and re-select the old window
  (get-buffer flycheck-error-list-buffer))

;; ----------------------------
;; projectile-ibuffer-window
;; ----------------------------

(defun show-projectile-ibuffer-window ()
  (let* ((buffer-name (format "*%s Buffers*" (projectile-project-name)))
         (qualifiers (list (cons 'projectile-files (projectile-project-root))))
         (buffer (mhj/ibuffer buffer-name qualifiers)))
    (progn
      (display-buffer-in-side-window
       buffer
       '((side . right)
         (window-width . 0.3)
         (slot . -1)))
      (set-window-dedicated-p (get-buffer-window buffer) t)
      )))

(defun hide-projectile-ibuffer-window ()
  (let* ((buffer-name (format "*%s Buffers*" (projectile-project-name)))
         (buffer (get-buffer buffer-name)))
    (progn
      (delete-window (get-buffer-window buffer))
      (kill-buffer buffer))))

(defun mhj/ibuffer (name qualifiers)
  "Like ibuffer, but don't display the buffer."
  (interactive "P")
  (setq ibuffer-prev-window-config (current-window-configuration))
  (let ((buf (get-buffer-create name)))
    (progn
      (with-current-buffer buf
        (or (derived-mode-p 'ibuffer-mode)
            (ibuffer-mode))
        (setq ibuffer-restore-window-config-on-quit nil)
        (when qualifiers
          (require 'ibuf-ext)
          (setq ibuffer-filtering-qualifiers qualifiers))
        (ibuffer-update nil)
        ;; Skip the group name by default.
        (ibuffer-forward-line 0 t)
        (unwind-protect
            (progn
              (setq buffer-read-only nil)
              (run-hooks 'ibuffer-hook))
          (setq buffer-read-only t))
        (unless ibuffer-expert
          (message "Commands: m, u, t, RET, g, k, S, D, Q; q to quit; h for help")))
      buf)))

;;; project-frame.el ends here
