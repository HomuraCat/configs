;; general
(blink-cursor-mode 0) ;; disable blinking cursor
;; (global-display-line-numbers-mode)

;; theme
(use-package gruvbox-theme)
(load-theme 'gruvbox-dark-medium)

;; font
(setq-default line-spacing 1)
(set-frame-font "Fira Code Retina 12" nil t)
(mac-auto-operator-composition-mode t)

;; macos keybinds
;;      general
(global-set-key (kbd "s-s") 'save-buffer)
(global-set-key (kbd "s-S") 'write-file)
(global-set-key (kbd "s-q") 'save-buffers-kill-emacs)
(global-set-key (kbd "s-a") 'mark-whole-buffer)
(global-set-key (kbd "s-w") (kbd "C-x 0"))

;;      editing
(global-set-key (kbd "s-<backspace>") 'kill-whole-line) ;; kill line
(global-set-key (kbd "M-S-<backspace>") 'kill-word) ;; kill word
(global-set-key (kbd "s-<right>") (kbd "C-e")) ;; end of line
(global-set-key (kbd "S-s-<right>") (kbd "C-S-e")) ;; select to end of line
(global-set-key (kbd "s-<left>") (kbd "M-m")) ;; beginning of line
(global-set-key (kbd "S-s-<left>") (kbd "M-S-m")) ;; select to beginning of line
(global-set-key (kbd "s-<up>") 'beginning-of-buffer) ;; first line
(global-set-key (kbd "s-<down>") 'end-of-buffer) ;; last line
(global-set-key (kbd "s-/") 'comment-line) ;; comment line

;;      split control
(global-set-key (kbd "s-1") (kbd "C-x 1")) ;; cmd-1 to kill others
(global-set-key (kbd "s-2") (kbd "C-x 2")) ;; cmd-2 to split horizontally
(global-set-key (kbd "s-3") (kbd "C-x 3")) ;; cmd-3 to split vertically
(global-set-key (kbd "s-0") (kbd "C-x 0")) ;; cmd-0 close current

;;      buffer navigation
(global-set-key (kbd "s-<") 'previous-buffer)
(global-set-key (kbd "s->") 'next-buffer)
