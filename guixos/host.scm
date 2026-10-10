;;; GuixOS - Host Selection
;;; The only file to edit when switching machines. It re-exports the chosen
;;; host's profile (name, user, window manager) and its operating-system
;;; thunk, so system and home entry points both follow.
(define-module (guixos host)
  #:use-module (guixos system hosts framework)   ; change per machine
  #:re-export (%host-profile host-operating-system))
