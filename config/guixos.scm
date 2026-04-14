;;; GuixOS - System Configuration Entry Point
(define-module (config guixos)
  #:use-module (config system guixos-system)
  #:re-export (%guixos))

;;; Entry Point
%guixos
