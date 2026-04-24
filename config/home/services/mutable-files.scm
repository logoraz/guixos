(define-module (config home services mutable-files)
  #:use-module (ice-9 optargs)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu home services dotfiles)
  #:use-module (config home services impure-symlinks)
  #:export (home-mutable-symlinks-service-type))

(define %user-name "logoraz")

(define %guixos-path (string-append "/home"
                                    "/" %user-name
                                    "/.config/guixos/"))

(define (home-mutable-symlinks-service config)
  `(;; GTK Configuration
    (".config/gtk-3.0/settings.ini"
     ,(string-append
       %guixos-path
       "files/gtk/settings.ini"))

    ;; Zathura Configuration File
    (".config/zathura/zathurarc"
     ,(string-append
       %guixos-path
       "files/zathura/zathurarc"))))

(define home-mutable-symlinks-service-type
  (service-type (name 'home-mutable-files)
                (description "Service for mutable local file symlinking.")
                (extensions
                 (list (service-extension
                        home-impure-symlinks-service-type
                        home-mutable-symlinks-service)))
                (default-value #f)))
