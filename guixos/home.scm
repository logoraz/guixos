;;; GuixOS - Home Configuration Entry Point
;;; Builds the home-environment from the profile of the selected host.
(define-module (guixos home)
  #:use-module (guixos host)
  #:use-module (guixos system host-profile)
  #:use-module (guixos home guixos-home)
  #:export (%guixos-home))

(define %guixos-home
  (guixos-home #:user (host-profile-user %host-profile)
               #:window-manager (host-profile-window-manager %host-profile)))

%guixos-home
