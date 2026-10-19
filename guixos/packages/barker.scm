;;; SPDX-License-Identifier: LGPL-2.1-only WITH LLGPL
;;; Copyright (C) 2026 Erik P. Almaraz

(define-module (guixos packages barker)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages lisp-check)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

;;; Pinned release.  To bump: set %commit, bump %revision, then
;;; refresh %hash with
;;;   git clone https://github.com/logoraz/barker /tmp/b
;;;   git -C /tmp/b checkout <commit>
;;;   guix hash -rx /tmp/b

(define %version "0.1.0")
(define %revision "0")
(define %commit "7c0bc6c7c02bb94a246ef969d5be42dcda07f684")
(define %hash "14r41lcximpg6zabd5zv1if040cszhm7gq1acwlpivviy6hs9p90")

(define %trinsic-commit "3a370f91982fba03987ae71d5b75e8527508b3c4")
(define %trinsic-hash "1v9z3wysl9x5gjs72wjabgarq30azrkqnvx9a1f2mdcfrg21pqvj")

(define %khazern-commit "b657262946bfba0e17ee930c58c8fcd6fa6be774")
(define %khazern-hash "0029wx2k9xq0k1ijzjps29dwpq7djpg1yfyy5r3g2p9dg611cmmq")


(define-public sbcl-trinsic
  (package
    (name "sbcl-trinsic")
    (version (git-version "1.0.0" "0" %trinsic-commit))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/s-expressionists/trinsic")
              (commit %trinsic-commit)))
       (file-name (git-file-name "cl-trinsic" version))
       (sha256 (base32 %trinsic-hash))))
    (build-system asdf-build-system/sbcl)
    (inputs
     (list sbcl-trivial-package-locks))
    (home-page "https://github.com/s-expressionists/Trinsic")
    (synopsis "Utilities for building intrinsic and extrinsic Lisp systems")
    (description
     "Trinsic is a Common Lisp utility system that helps construct
systems which are loaded either intrinsically into an implementation, by
replacing its own definitions, or extrinsically, beside them.")
    (license license:expat)))

(define-public sbcl-khazern
  (package
    (name "sbcl-khazern")
    (version (git-version "1.0.0" "0" %khazern-commit))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/s-expressionists/khazern")
             (commit %khazern-commit)))
       (file-name (git-file-name "cl-khazern" version))
       (sha256 (base32 %khazern-hash))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      ;; Only the intrinsic systems barker uses.  The test systems need
      ;; ansi-test-harness and parachute, so skip them.
      #:asd-systems ''("khazern"
                       "khazern-intrinsic"
                       "khazern-extension"
                       "khazern-extension-intrinsic")
      #:tests? #f))
    (inputs
     (list sbcl-acclimation
           sbcl-closer-mop
           sbcl-trinsic
           sbcl-trivial-with-current-source-form))
    (home-page "https://github.com/s-expressionists/Khazern")
    (synopsis "Portable and extensible Common Lisp LOOP implementation")
    (description
     "Khazern is a portable, extensible implementation of the Common Lisp
LOOP macro.  It can replace an implementation's LOOP (intrinsic) or sit
beside it (extrinsic), and offers extension iteration paths.")
    (license license:bsd-2)))

(define-public barker
  (package
    (name "barker")
    (version (git-version %version %revision %commit))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://codeberg.org/logoraz/barker")
              (commit %commit)))
       (file-name (git-file-name name version))
       (sha256 (base32 %hash))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("barker")
      #:asd-test-systems ''("barker/tests")
      ;; The tests fake nmcli, pactl and friends with shell scripts.
      ;; Flip to #f if the build sandbox objects.
      #:tests? #t
      #:phases
      #~(modify-phases %standard-phases
          ;; Dump a standalone image, entry point (barker:main).
          (add-after 'create-asdf-configuration 'build-program
            (lambda* (#:key outputs #:allow-other-keys)
              (build-program
               (string-append (assoc-ref outputs "out") "/bin/barker")
               outputs
               #:dependencies '("barker")
               #:entry-program '((barker:main))
               #:compress? #t))))))
    (native-inputs
     (list sbcl-fiveam))
    (inputs
     (list sbcl-bordeaux-threads
           sbcl-cl-ppcre
           sbcl-jzon
           sbcl-khazern
           sbcl-trivial-gray-streams))
    (home-page "https://codeberg.org/logoraz/barker")
    (synopsis "Swaybar status generator configured in Common Lisp")
    (description
     "Barker generates the status line for swaybar using the swaybar
protocol.  The bar is described in Common Lisp through a small macro DSL,
with blocks for battery, brightness, clock, network-manager, volume,
keyboard layout, and plain labels.  Blocks update on timers, Unix signals,
or event sources, and react to click events.")
    ;; Upstream is LGPL-2.1-only with the LLGPL preamble.
    (license license:lgpl2.1)))
