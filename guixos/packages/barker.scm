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
;;;   git clone https://codeberg.org/logoraz/barker /tmp/b
;;;   git rev-parse HEAD
;;;   guix hash -rx /tmp/b

(define %version "0.2.0")
(define %revision "2")
(define %commit "353a9de636da9780d1402e0ccac59a3b6ff43b90")
(define %hash "14ygh41v970z2s4ds7vvz7zjhvzhrz6yd61dn7nm20g9gqvhky6l")

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
           sbcl-jzon
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
