;;; GuixOS - System Configuration Entry Point
(define-module (guixos guixos)
  #:use-module (guixos system hosts framework)
  #:re-export (%guixos))


;;; Entry Point - Instantiate GuixOS
%guixos
