(define-module (config utils)
  #:use-module (srfi srfi-1)
  #:use-module (guix store roots)
  #:export (list-gc-roots
            list-gc-roots/shell-profiles
            delete-gc-shell-profiles!))


;;;
;;; Custom guix commands
;;;

(define (list-gc-roots)
  "Return a deduplicated, sorted list of GC roots owned by the current user."
  (delete-duplicates (sort (gc-roots) string<?)))

(define (list-gc-roots/shell-profiles)
  "Return only the hashed guix shell cache profiles from the GC roots."
  (filter (lambda (root)
            (string-contains root "/profiles/per-user"))
          (list-gc-roots)))

(define (delete-gc-shell-profiles!)
  "Delete all hashed guix shell cache profile roots for the current user."
  (for-each delete-file (list-gc-roots/shell-profiles)))
