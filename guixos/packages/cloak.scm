;;; SPDX-License-Identifier: LGPL-2.1-only WITH LLGPL
;;; Copyright (C) 2026 Erik P Almaraz

(define-module (guixos packages cloak)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))


;;; Pinned release, fetched by its git tag.  To bump: set %version to
;;; the new tag without the v, then refresh %hash with
;;;   git clone https://codeberg.org/logoraz/cloak /tmp/cloak
;;;   git -C /tmp/cloak checkout v<version>
;;;   guix hash -rx /tmp/cloak
;;;
;;; The program is wrapped so that it can find the GTK typelibs and
;;; preload gtk4-layer-shell, which has to load before libwayland-client.


(define %version "0.6.2")
(define %hash "03ypa15hj7x4a8yvln1lah7vx95s34h253yka8axph63jz2g2khd")

(define-public sbcl-cl-gtk4/adw
  (package
    (inherit sbcl-cl-gtk4)
    (name "sbcl-cl-gtk4-adw")
    (arguments
     ;; Guix builds only cl-gtk4 and cl-gdk4, so cl-gtk4.adw has no
     ;; fasl and ASDF tries to compile it inside the store.
     '(#:asd-systems '("cl-gtk4" "cl-gdk4" "cl-gtk4.adw")))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs sbcl-cl-gtk4)
       (append libadwaita)))
    (synopsis "GTK4 and libadwaita bindings for Common Lisp")))

(define-public cloak
  (package
    (name "cloak")
    (version %version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://codeberg.org/logoraz/cloak")
              (commit (string-append "v" %version))))
       (file-name (git-file-name name version))
       (sha256 (base32 %hash))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("cloak")
      #:asd-test-systems ''("cloak/tests")
      ;; The tests open Unix sockets and temporary files only.  Flip to #f
      ;; if the build sandbox objects.
      #:tests? #t
      #:phases
      #~(modify-phases %standard-phases
          ;; Dump a standalone image, entry point (cloak:main).
          (add-after 'create-asdf-configuration 'build-program
            (lambda* (#:key outputs #:allow-other-keys)
              (build-program
               (string-append (assoc-ref outputs "out") "/bin/cloak")
               outputs
               #:dependencies '("cloak")
               #:entry-program '((cloak:main))
               #:compress? #f)))
          ;; The greeter runs outside any profile, so give it the typelib
          ;; path and the layer-shell library itself.
          (add-after 'build-program 'wrap-program
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (wrap-program
                  (string-append (assoc-ref outputs "out") "/bin/cloak")
                `("GI_TYPELIB_PATH" = (,(getenv "GI_TYPELIB_PATH")))
                `("LD_PRELOAD" ":" prefix
                  (,(search-input-file
                     inputs "/lib/libgtk4-layer-shell.so")))))))))
    (native-inputs
     (list sbcl-fiveam))
    (inputs
     (list gobject-introspection
           gtk4-layer-shell
           libadwaita
           sbcl-cl-gtk4/adw
           sbcl-jzon))
    (home-page "https://codeberg.org/logoraz/cloak")
    (synopsis "Configurable GTK4 greeter for greetd")
    (description
     "Cloak is a greetd greeter written in Common Lisp.  It draws a login
form over every output with GTK4 and the layer-shell protocol, lists the
users and Wayland sessions of the system, and reads its settings from a
plain s-expression file.")
    ;; Upstream is LGPL-2.1-only with the LLGPL preamble.
    (license license:lgpl2.1)))
