;;; clasp.scm
;;; Docstring: Defines `clasp-cl-latest', Clasp built from a newer
;;; release than Guix's `clasp-cl'.  Inherits the upstream package but
;;; replaces `configure': Clasp 3.x's koga rejects the stale
;;; --build-mode=bytecode-faso flag that 2.7.0's definition passes.
;;;
;;; Update workflow:
;;;   wget https://github.com/clasp-developers/clasp/releases/download/\
;;;        <version>/clasp-<version>.tar.gz
;;;   guix hash clasp-<version>.tar.gz

(define-module (guixos packages clasp)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (gnu packages lisp)
  #:export (clasp-cl-latest))

(define %clasp-version "3.0.1")
(define %clasp-hash "1vmk4gk6y2pwylgm1vxkq8n2bj3pj4d75kn0ilw9kn499brw8ypc")

(define clasp-cl-latest
  (package
    (inherit clasp-cl)
    (name "clasp-cl-latest")
    (version %clasp-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/clasp-developers/clasp/releases/download/"
             version "/clasp-" version ".tar.gz"))
       (hash (content-hash (base32 %clasp-hash) sha256))))
    (arguments
     ;; Need to modify guix upstream recipe:
     ;; --build-mode=bytecode-faso is an invalid key for koga, instead needs
     ;; --build-mode=bytecode
     (substitute-keyword-arguments (package-arguments clasp-cl)
       ((#:phases phases)
        #~(modify-phases #$phases
            (replace 'configure
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                       (libs (cons (string-append out "/lib")
                                   (map (lambda (input)
                                          (string-append (cdr input) "/lib"))
                                        inputs)))
                       (ldflags (string-append
                                 "-Wl,"
                                 (string-join
                                  (apply append
                                         (map (lambda (dir)
                                                (list "-L" dir "-rpath" dir))
                                              libs))
                                  ","))))
                  (invoke "sbcl" "--script" "./koga"
                          "--skip-sync"
                          "--build-mode=bytecode"
                          (string-append "--cc=" (which "clang"))
                          (string-append "--cxx=" (which "clang++"))
                          (string-append "--ldflags=" ldflags)
                          "--reproducible-build"
                          "--package-path=/"
                          (string-append "--bin-path=" out "/bin")
                          (string-append "--lib-path=" out "/lib/clasp")
                          (string-append "--dylib-path=" out "/lib")
                          (string-append "--pkgconfig-path=" out "/lib/pkgconfig")
                          (string-append "--share-path=" out "/share/clasp")))))))))))
