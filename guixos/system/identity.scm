(define-module (guixos system identity)
  #:use-module (guixos lib subrx)
  #:export (%home-user
            %window-manager
            config-source
            guixos-system-config
            guixos-home-config))


;;;
;;; Identity values shared across the GuixOS configuration.
;;;
;;; %home-user is a parameter so a user could override it via
;;; `parameterize` in unusual contexts (e.g., building a config for a
;;; different user from the REPL). For normal reconfigure flows, the
;;; default is the value of record.
;;;
;;; %window-manager works the same way: sway is the default for every
;;; host unless a host-specific file overrides it via `parameterize`
;;; (e.g. framework-pro.scm, once mahogany is ready).
;;;


(define-parameter %home-user "logoraz")
(define-parameter %window-manager 'sway)

(define (config-source)
  (string-append "/home/" (%home-user) "/.config/guixos"))

(define (guixos-system-config)
  (string-append (config-source) "/guixos/guixos.scm"))

(define (guixos-home-config)
  (string-append (config-source) "/guixos/home/guixos-home.scm"))
