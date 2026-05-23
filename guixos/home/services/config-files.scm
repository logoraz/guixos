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
  (mixed-text-file
   "dot-guile"
   ";; -*- mode: scheme; -*-\n"
   "\n"
   ";; Use globally\n"
   "(use-modules (ice-9 readline)\n"
   "             (ice-9 format)\n"
   "             (ice-9 pretty-print)\n"
   "             (ice-9 colorized))\n"
   "\n"
   "(activate-readline)\n"
   "(activate-colorized)\n"
   "\n"
   ";; G-Golf recommended duplicate binding handler\n"
   "(use-modules (oop goops))\n"
   "(default-duplicate-binding-handler\n"
   "  '(merge-generics replace warn-override-core warn last))\n"))

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

;;;
;;; Service Composition
;;;
(define (home-config-files-service config)
  `( ;; Guile Configuration
    (".guile" ,%dot-guile)

    ;;TODO: prep for GNU guile-next release to store these in XDG_CONFIG_HOME...
    (".config/guile/guile" ,%dot-guile)

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

