(define-module (guixos home services udiskie)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:export (home-udiskie-service-type))

;;; Borrowed from https://codeberg.org/daviwil/dotfiles/daviwil/home-services/udiskie.scm

(define (home-udiskie-profile-service config)
  (list udiskie))

(define (home-udiskie-shepherd-service config)
  (list
   (shepherd-service
    (provision '(udiskie))
    (auto-start? #f)
    (documentation "Run and control udiskie.")
    (start
     #~(lambda _
         ((make-forkexec-constructor
           '("udiskie" "-s")
           #:environment-variables
           (append
            (map (lambda (p) (string-append (car p) "=" (cdr p)))
                 (call-with-input-file
                     (string-append (getenv "XDG_RUNTIME_DIR")
                                    "/sway-session-env")
                   read))
            (environ))))))
    (stop #~(make-kill-destructor)))))

(define home-udiskie-service-type
  (service-type (name 'home-udiskie)
                (description "A service for launching Udiskie.")
                (extensions
                 (list (service-extension
                        home-profile-service-type
                        home-udiskie-profile-service)
                       (service-extension
                        home-shepherd-service-type
                        home-udiskie-shepherd-service)))
                (default-value #f)))
