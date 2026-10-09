(define-module (guixos home window-manager mahogany)
  #:use-module (gnu services)
  #:export (mahogany-home-services))

(define (mahogany-home-services)
  "Return the home services needed to run mahogany."
  ;; TODO: mahogany config symlinks, companion packages, startup programs.
  '())
