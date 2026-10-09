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
;;; Both values are parameters. Calling one with an argument sets it,
;;; and calling it with none reads it.
;;;
;;; %home-user is set from the #:user keyword of make-guixos-system.
;;; The default, "logoraz", applies only if nothing has set it.
;;;
;;; %window-manager is set from the #:window-manager keyword of
;;; make-guixos-system and guixos-home. The default is 'sway.
;;;
;;; The home entry point (home.scm) loads the selected host first, so
;;; home picks up the same user and window manager as the system.
;;;


(define-parameter %home-user "logoraz")
(define-parameter %window-manager 'sway)

(define (config-source)
  (string-append "/home/" (%home-user) "/.config/guixos"))

(define (guixos-system-config)
  (string-append (config-source) "/guixos/guixos.scm"))

(define (guixos-home-config)
  (string-append (config-source) "/guixos/home.scm"))
