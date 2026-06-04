(define-module (guixos system identity)
  #:use-module (guixos lib subrx)
  #:export (%home-user
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

(define-parameter %home-user "logoraz")

(define (config-source)
  (string-append "/home/" (%home-user) "/.config/guixos"))

(define (guixos-system-config)
  (string-append (config-source) "/guixos/guixos.scm"))

(define (guixos-home-config)
  (string-append (config-source) "/guixos/home/guixos-home.scm"))
