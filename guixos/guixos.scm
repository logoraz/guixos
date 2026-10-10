;;; GuixOS - System Configuration Entry Point
;;; Builds the operating-system for the host selected in (guixos host).
(define-module (guixos guixos)
  #:use-module (guixos host)
  #:export (%guixos))

(define %guixos (host-operating-system))

%guixos
