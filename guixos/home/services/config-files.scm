(define-module (guixos home services config-files)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (gnu home services dotfiles)
  #:use-module (guixos lib utils)
  #:use-module (guixos system identity)
  #:export (home-config-files-service-type))


;;;
;;; Build-Time Assets
;;;
(define %dot-guile
  (resolve (config-source) "files/guile" #:file "dot-guile"))

(define %podman-registries
  (mixed-text-file
   "registries.conf"
   "unqualified-search-registries = [\n"
   "  \"docker.io\",\n"
   "  \"registry.opensuse.org\",\n"
   "  \"registry.fedora.org\",\n"
   "  \"quay.io\",\n"
   "  \"ghcr.io\"\n"
   "]\n\n"
   "# Use the short-name aliases table for common images\n"
   "short-name-mode = \"permissive\"\n"))

(define (home-config-files-service config)
  `( ;; Guile Configuration
    (".guile" ,%dot-guile)

    ;;TODO: prep for GNU guile-next release to store these in XDG_CONFIG_HOME...
    (".config/guile/guile" ,%dot-guile)

    ;; SBCL Configuration
    (".sbclrc"
     ,(resolve (config-source) "files/common-lisp" #:file "dot-sbclrc.lisp"))

    (".config/containers/registries.conf" ,%podman-registries)

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

