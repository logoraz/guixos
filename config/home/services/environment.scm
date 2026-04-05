(define-module (config home services environment)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:export (home-env-vars-configuration-service-type))

(define %xdg-data-dirs (string-append "$HOME/.guix-home/profile/share:"
                                      "/run/current-system/profile/share:"
                                      "$XDG_DATA_HOME/flatpak/exports/share:"))

(define (home-env-vars-config-gexp config)
  `(;; Sort hidden (dot) files first in ls listings
    ("LC_COLLATE" . "C")

    ;; Guile Init File
    ("GUILE_INIT_FILE" . "$HOME/.config/guile/guile.scm")

    ;; Set Emacs as editor
    ("EDITOR" . "emacsclient -c -a emacs")
    ("VISUAL" . "emacsclient -c -a emacs")

    ;; Set Zen Browser as the default (Installed via Flatpaks)
    ("BROWSER" . "Zen Browser")

    ;; Set XDG environment variables
    ("XDG_LOG_HOME"     . "$HOME/.local/log")

    ;; Flatpak integration
    ("XDG_LOCAL_BIN"    . "$HOME/.local/bin")
    ("XDG_DATA_DIRS"    . ,%xdg-data-dirs)))


(define home-env-vars-configuration-service-type
  (service-type (name 'home-profile-env-vars-service)
                (description "Service for setting up profile env vars.")
                (extensions
                 (list (service-extension
                        home-environment-variables-service-type
                        home-env-vars-config-gexp)))
                (default-value #f)))
