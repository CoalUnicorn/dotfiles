(setq inhibit-startup-message t)
(tool-bar-mode -1)
(fset 'yes-or-no-p 'y-or-n-p)

(use-package try
  :ensure t)

(use-package which-key
  :ensure t
  :init
  (progn
    (which-key-mode)))

(use-package ace-window
  :ensure t
  :init
  (progn
    (global-set-key [remap other-window] 'ace-window)
    (custom-set-faces
     '(aw-leading-char-face
       ((t (:inherit ace-jump-face-foreground :height 3.0)))))
    ))

(setenv "BROWSER" "chromium-browser")

  (use-package org-bullets
    :ensure t
    :config
    (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

  (custom-set-variables
   '(org-default-notes-file (concat org-directory "/notes.org"))
   '(org-hide-leading-stars t)
   '(org-startup-folded (quote overview))
   '(org-startup-indented t)
  )
  (global-set-key "\C-ca" 'org-agenda)
  (global-set-key "\C-cc" 'org-capture)
  (global-set-key "\C-cl" 'org-store-link)
  (global-set-key "\C-cL" 'org-insert-link-global)
  (global-set-key "\C-co" 'org-open-at-point-global)
(setq org-log-done t)

(use-package counsel
  :ensure t
  )

(use-package swiper
  :ensure try
  :bind (("C-s" . swiper)
	 ("C-r" . swiper)
	 ("C-c C-r" . ivy-resume)
	 ("M-x" . counsel-M-x)
	 ("C-x C-f" . counsel-find-file))
  :config
  (progn
    (ivy-mode 1)
    (setq ivy-use-virtual-buffers t)
    (setq ivy-display-style 'fancy)
    (define-key read-expression-map (kbd "C-r") 'counsel-expresion-history)
    ))

(use-package avy
  :ensure t
  :bind ("M-s" . avy-goto-char))

(use-package auto-complete
  :ensure t
  :init
  (progn
    (ac-config-default)
    (global-auto-complete-mode t)
    ))

(use-package flycheck
  :ensure t
  :init
  (global-flycheck-mode t))

(use-package zenburn-theme
  :ensure t
  :config (load-theme 'zenburn t))

(use-package linum
  :ensure t
  :config
  (progn
    (global-linum-mode 1)
    (setq linum-format "%4d \u2502 ")
    (set-face-attribute 'linum nil :background nil)))

(elpy-enable)
(setq elpy-rpc-python-command "python3")

(add-hook 'after-init-hook #'global-flycheck-mode)
