(define-module (config home services config-files)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu home services dotfiles)
  #:use-module (config lib utils)
  #:use-module (config system identity)
  #:export (home-config-files-service-type))


(define (home-config-files-service config)
  `(;; Guix Configuration Channels
    (".config/guix/channels.scm"
     ,(resolve (home-source) "config/system" #:file "channels.scm"))

    ;; Guile Configuration
    (".guile"
     ,(resolve (home-source) "files/guile" #:file "dot-guile"))

    ;; SBCL Configuration
    (".sbclrc"
     ,(resolve (home-source) "files/common-lisp" #:file "dot-sbclrc.lisp"))

    ;;TODO: prep for GNU guile-next release to store these in XDG_CONFIG_HOME...
    (".config/guile/guile"
     ,(resolve (home-source) "files/guile" #:file "dot-guile"))

    ;; TODO
    ))


(define home-config-files-service-type
  (service-type (name 'home-config-files)
                (description "Service for setting up config files.")
                (extensions
                 (list (service-extension
                        home-files-service-type
                        home-config-files-service)))
                (default-value #f)))

