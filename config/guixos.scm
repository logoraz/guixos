;;; GuixOS - System Configuration Entry Point
(define-module (config guixos)
  #:use-module (config system hosts framework)
  #:re-export (%guixos))

;;; Entry Point - Instantiate GuixOS
%guixos
