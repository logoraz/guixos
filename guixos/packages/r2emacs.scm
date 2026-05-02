(define-module (guixos packages r2emacs)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:))


;;; Note: generate new sha256/base32 via
;;; guix hash -x --serializer=nar .
;;; Get commit via git log
(define-public razemacs
  (package
   (name "r2emacs")
   (version "tbd")
   (source (origin
            (method git-fetch)
            (uri (git-reference
                  (url "https://codeberg.org/logoraz/r2emacs.git")
                  (commit version)))
            (hash
             (content-hash
              "tbd"))))
   (build-system copy-build-system)
   (home-page "https://codeberg.org/logoraz/r2emacs")
   (synopsis "R2Emacs")
   (description "R2Emacs")
   (license license:gpl3+)))
