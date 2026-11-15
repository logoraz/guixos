;;; SPDX-License-Identifier: LGPL-2.1-only WITH LLGPL
;;; Copyright (C) 2026 Erik P. Almaraz

(define-module (guixos packages lpz407)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((guixos packages cloak) #:select (sbcl-cl-gtk4/adw))
  #:use-module (guix packages))


;;; Pinned release, fetched by its git tag.  To bump: set %version to
;;; the new tag without the v, then refresh %hash with
;;;   git clone https://codeberg.org/logoraz/lpz407 /tmp/lpz407
;;;   git -C /tmp/lpz407 checkout v<version>
;;;   guix hash -rx /tmp/lpz407
;;; Until the tag exists, the all-zero hash below makes Guix report the
;;; real one.


(define %version "0.2.1")
(define %hash "1b85vqa9mfw3m1iw1dgh3skni79yxfpmxrri3jm1q8n029mhydc1")

(define-public lpz407
  (package
    (name "lpz407")
    (version %version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/logoraz/lpz407")
              (commit (string-append "v" %version))))
       (file-name (git-file-name name version))
       (sha256 (base32 %hash))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("lpz407")
      #:asd-test-systems ''("lpz407/tests")
      ;; The tests load GTK, so they need the same library paths as the
      ;; program.  Flip to #t once a build confirms the sandbox allows it.
      #:tests? #f
      #:phases
      #~(let ((input-dirs
               ;; The existing SUBDIR of each input, for search paths.
               (lambda (inputs subdir)
                 (filter file-exists?
                         (map (lambda (input)
                                (string-append (cdr input) "/" subdir))
                              inputs)))))
          (modify-phases %standard-phases
            ;; Dump a standalone image, entry point (lpz407:main).
            (add-after 'create-asdf-configuration 'build-program
              (lambda* (#:key outputs #:allow-other-keys)
                (build-program
                 (string-append (assoc-ref outputs "out") "/bin/lpz407")
                 outputs
                 #:dependencies '("lpz407")
                 #:entry-program '((lpz407:main))
                 #:compress? #t)))
            ;; Loading cl-gtk4 opens the GTK typelibs and libraries, so
            ;; the build needs the paths that the program gets below.
            (add-before 'build-program 'set-library-paths
              (lambda* (#:key inputs #:allow-other-keys)
                (setenv "GI_TYPELIB_PATH"
                        (string-join
                         (input-dirs inputs "lib/girepository-1.0") ":"))
                (setenv "LD_LIBRARY_PATH"
                        (string-join (input-dirs inputs "lib") ":"))))
            ;; Point the program at the same typelibs and libraries.
            (add-after 'build-program 'wrap-program
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (wrap-program
                    (string-append (assoc-ref outputs "out") "/bin/lpz407")
                  `("GI_TYPELIB_PATH" ":" prefix
                    ,(input-dirs inputs "lib/girepository-1.0"))
                  `("LD_LIBRARY_PATH" ":" prefix
                    ,(input-dirs inputs "lib")))))
            ;; Install the logo and register the program with launchers
            ;; such as fuzzel.
            (add-after 'wrap-program 'install-desktop-entry
              (lambda* (#:key outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                       (applications (string-append out "/share/applications"))
                       (icons (string-append
                               out "/share/icons/hicolor/scalable/apps"))
                       (graphics (string-append
                                  out "/share/lpz407/graphics")))
                  (mkdir-p applications)
                  (mkdir-p icons)
                  (mkdir-p graphics)
                  ;; The logo the program looks for beside its share
                  ;; directory.
                  (copy-file "data/graphics/lisp-icon-sm.svg"
                             (string-append graphics "/lisp-icon-sm.svg"))
                  ;; The Common Lisp logo, until the app has an icon.
                  (copy-file "data/graphics/lisp-icon-sm.svg"
                             (string-append icons "/lpz407.svg"))
                  (call-with-output-file
                      (string-append applications "/lpz407.desktop")
                    (lambda (port)
                      (display
                       (string-append
                        "[Desktop Entry]\n"
                        "Type=Application\n"
                        "Name=lpz407\n"
                        "GenericName=Speaker Control\n"
                        "Comment=Control a Logitech Z407 Bluetooth speaker\n"
                        "Exec=" out "/bin/lpz407\n"
                        "Icon=lpz407\n"
                        "Terminal=false\n"
                        "Categories=AudioVideo;Audio;\n"
                        "Keywords=Logitech;Z407;Bluetooth;Speaker;\n"
                        "StartupWMClass=org.lpz407.app\n")
                       port))))))))))
    (native-inputs
     (list sbcl-fiveam))
    (inputs
     (list gobject-introspection
           glib
           gtk
           libadwaita
           sbcl-cl-gtk4/adw
           sbcl-dbus
           sbcl-iolib))
    (home-page "https://codeberg.org/logoraz/lpz407")
    (synopsis "Control app for the Logitech Z407 Bluetooth speaker")
    (description
     "lpz407 is a GTK4 and libadwaita control app for the Logitech Z407
Bluetooth speaker.  It connects over BlueZ, sets volume, bass and input, and
remembers the last levels and input.  The window is themed and laid out by a
plain data file, config.sexp, and everything is written in Common Lisp.")
    ;; Upstream is LGPL-2.1-only with the LLGPL preamble.
    (license license:lgpl2.1)))
