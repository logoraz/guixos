(define-module (guixos home services mutable-files)
  #:use-module (ice-9 optargs)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu home services dotfiles)
  #:use-module (guixos lib utils)
  #:use-module (guixos system identity)
  #:use-module (guixos home services impure-symlinks)
  #:export (home-mutable-symlinks-service-type))


(define (home-mutable-symlinks-service config)
  `(;; Guix Configuration Channels
    (".config/guix/channels.scm"
     ,(resolve (home-source) "config/system" #:file "channels.scm" #:string? #t))

    ;; GTK Configuration
    (".config/gtk-3.0/settings.ini"
     ,(resolve (home-source) "files/gtk" #:file "settings.ini" #:string? #t))

    ;;TODO
    ))

(define home-mutable-symlinks-service-type
  (service-type (name 'home-mutable-files)
                (description "Service for mutable local file symlinking.")
                (extensions
                 (list (service-extension
                        home-impure-symlinks-service-type
                        home-mutable-symlinks-service)))
                (default-value #f)))
