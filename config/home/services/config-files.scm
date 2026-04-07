(define-module (config home services config-files)
  #:use-module (guix gexp)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:export (home-config-files-service-type))


;; Edit setting the Home User
(define %user-name "logoraz")

(define %source (string-append "/home"
                               "/" %user-name
                               "/.config/guixos"))

(define* (resolve dir #:key file)
  "Resolve local config dir & file"
  (let ((filename (if file (string-append "/" file) "")))
    (local-file (string-append
                 %source "/"
                 dir filename)
                #:recursive? #t)))

(define (home-config-files-service config)
  `(;; Guix Configuration Channels
    (".config/guix/channels.scm"
     ,(resolve "config/system" #:file "channels.scm"))

    ;; Guile Configuration
    (".guile"
     ,(resolve "files/guile" #:file "dot-guile"))

    ;; SBCL Configuration
    (".sbclrc"
     ,(resolve "files/common-lisp" #:file "dot-sbclrc.lisp"))

    ;; Terminal configurations
    ;; (".config/foot/foot.ini"
    ;;  ,(resolve "files/foot" #:file "foot.ini"))

    ;; (".config/vterm/emacs-vterm-bash.sh"
    ;;  ,(resolve "files/vterm" #:file "emacs-vterm-bash.sh"))

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

