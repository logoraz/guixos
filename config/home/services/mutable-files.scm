(define-module (config home services mutable-files)
  #:use-module (ice-9 optargs)
  #:use-module (guix gexp)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (config home services home-impure-symlinks)
  #:export (home-mutable-symlinks-service-type))

(define %user-name "logoraz")

(define %guixos-path (string-append "/home"
                                    "/" %user-name
                                    "/.config/guixos/"))

(define (home-mutable-symlinks-service config)
  `(;; Foot
    (".config/foot/foot.ini"
     ,(string-append
       %guixos-path
       "files/foot/foot.ini"))

    ;; TODO
    ))

(define home-mutable-symlinks-service-type
  (service-type (name 'home-mutable-files)
                (description "Service for mutable local file symlinking.")
                (extensions
                 (list (service-extension
                        home-impure-symlinks-service-type
                        home-mutable-symlinks-service)))
                (default-value #f)))
