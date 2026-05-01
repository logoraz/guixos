(define-module (config lib utils)
  #:use-module (guix gexp)
  #:export (resolve))

;;;
;;; Configuration Helpers
;;;
(define* (resolve source dir #:key file string?)
  "Resolve a path under source.
By default returns a local-file gexp.
When passed #:string? #t returns the absolute path string instead,
for use with impure-symlinks that require such."
  (let* ((filename (if file (string-append "/" file) ""))
         (path (string-append source "/" dir filename)))
    (if string?
        path
        (local-file path #:recursive? #t))))
