(define-module (guixos system identity)
  #:use-module (guixos lib subrx)
  #:export (%home-user
            home-source))

;;;
;;; Identity values shared across the GuixOS configuration.
;;;
;;; %home-user is a parameter so a user could override it via
;;; `parameterize` in unusual contexts (e.g., building a config for a
;;; different user from the REPL). For normal reconfigure flows, the
;;; default is the value of record.
;;;

(define-parameter %home-user "logoraz")

(define (home-source)
  (string-append "/home/" (%home-user) "/.config/guixos"))
