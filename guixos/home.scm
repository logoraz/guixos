;;; GuixOS - Home Configuration Entry Point
(define-module (guixos home)
  #:use-module (guixos guixos)            ; first: loads the selected host
  #:use-module (guixos home guixos-home)
  #:export (%guixos-home))


;;; Entry Point - Instantiate GuixOS Home
(define %guixos-home (guixos-home))

%guixos-home
