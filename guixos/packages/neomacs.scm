(define-module (guixos packages neomacs)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:export (neomacs-bin))

;; Notes on Updating to latest version:
;; curl -s https://api.github.com/repos/eval-exec/neomacs/releases/latest | \
;;      grep '"tag_name"'
;; wget https://github.com/eval-exec/neomacs/releases/download/ \
;;      v<version>/neomacs-<version>-x86_64-unknown-linux-gnu.tar.gz
;; guix hash neomacs-<version>-x86_64-unknown-linux-gnu.tar.gz

(define %version "0.0.19")
(define %neomacs-hash "1a1cs4j0lm9mcwanig0d48adykqz9qsfrhdd1qrana0fz46wn7rq")

(define neomacs-bin
  (package
    (name "neomacs-bin")
    (version %version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/eval-exec/neomacs/releases/download/v"
             version
             "/neomacs-" version "-x86_64-unknown-linux-gnu.tar.gz"))
       (hash (content-hash (base32 %neomacs-hash) sha256))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("." "lib/neomacs"))
           #:modules `((ice-9 regex)
                       (srfi srfi-1)
                       (srfi srfi-26)
                       ,@%copy-build-system-modules
                       ,@%default-gnu-imported-modules)
           #:phases
           #~(modify-phases (@@ (guix build copy-build-system) %standard-phases)
               (add-after 'install 'patch-elf
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((ld.so (string-append #$(this-package-input "glibc")
                                               #$(glibc-dynamic-linker)))
                         (rpath (string-join
                                 (cons*
                                  (string-append #$output "/lib/neomacs")
                                  (map (lambda (input)
                                         (string-append (cdr input) "/lib"))
                                       inputs))
                                 ":")))
                     (define (patch-elf file)
                       (format #t "Patching ~a ..." file)
                       (unless (string-contains file ".so")
                         (invoke "patchelf" "--set-interpreter" ld.so file))
                       (invoke "patchelf" "--set-rpath" rpath file)
                       (display " done\n"))
                     (for-each patch-elf
                               (find-files (string-append #$output "/lib/neomacs")
                                           (lambda (file stat)
                                             (and (eq? 'regular (stat:type stat))
                                                  (elf-file? file))))))))
               (add-after 'patch-elf 'link-libtinfo
                 (lambda _
                   ;; Guix's ncurses folds tinfo into libncursesw
                   (symlink (string-append #$(this-package-input "ncurses")
                                           "/lib/libncursesw.so.6")
                            (string-append #$output
                                           "/lib/neomacs/libtinfo.so.6"))))
               (add-after 'patch-elf 'wrap-program
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (define* (lib-of input #:key (dir "lib"))
                     (string-append (assoc-ref inputs input) "/" dir))
                   (let* ((out (assoc-ref outputs "out"))
                          (lib (string-append out "/lib"))
                          ;; wgpu dlopen()s these at runtime
                          (dlopen-libs (map lib-of '("vulkan-loader" "mesa"
                                                     "wayland" "libxkbcommon"
                                                     "libx11" "libva"))))
                     (wrap-program (car (find-files lib "^neomacs$"))
                       `("LD_LIBRARY_PATH" prefix ,dlopen-libs)
                       ;; Vulkan ICD discovery (mesa radv/anv)
                       `("XDG_DATA_DIRS" prefix
                         (,(lib-of "mesa" #:dir "share")))))))
               (add-after 'wrap-program 'add-dump-file
                 (lambda _
                   ;; wrap-program renames the real binary, so Neomacs no
                   ;; longer finds its pdump on its own; pass it explicitly.
                   (let ((wrapper (car (find-files
                                        (string-append #$output "/lib/neomacs/bin")
                                        "^neomacs$")))
                         (dump (car (find-files
                                     (string-append #$output "/lib/neomacs/libexec")
                                     "^neomacs\\.pdump$"))))
                     (substitute* wrapper
                       (("(\\.neomacs-real\")( +)\"\\$@\"" all real space)
                        (string-append real " --dump-file=" dump " \"$@\""))))))
               (add-after 'add-dump-file 'install-bin
                 (lambda _
                   (let* ((neomacs (car (find-files
                                         (string-append #$output "/lib/neomacs")
                                         "^neomacs$")))
                          (bin-neomacs (string-append #$output "/bin/neomacs")))
                     (mkdir-p (string-append #$output "/bin"))
                     (symlink neomacs bin-neomacs))))
               (add-after 'install-bin 'install-desktop
                 (lambda _
                   (let* ((share-applications (string-append
                                               #$output "/share/applications"))
                          (desktop (string-append
                                    share-applications "/neomacs.desktop")))
                     (mkdir-p share-applications)
                     (make-desktop-entry-file
                      desktop
                      #:name "NEO Emacs"
                      ;; TODO: install an icon if the tarball ships one
                      #:icon "emacs"
                      #:type "Application"
                      #:comment #$(package-synopsis this-package)
                      #:exec (string-append #$output "/bin/neomacs %F")
                      #:keywords '("Text" "Editor" "Emacs")
                      #:categories '("Development" "TextEditor")
                      #:mime-type '("text/plain")
                      #:startup-w-m-class "Emacs")))))))
    (native-inputs (list patchelf))
    (inputs (list gcc-toolchain
                  glibc
                  dbus
                  fontconfig
                  freetype
                  gstreamer
                  gst-plugins-base
                  libva
                  libx11
                  libxkbcommon
                  mesa
                  ncurses
                  vulkan-loader
                  wayland))
    (home-page "https://github.com/eval-exec/neomacs")
    (synopsis "GPU-accelerated Emacs rewritten in Rust")
    (description "NEO Emacs is a hard fork of GNU Emacs with the C core
reimplemented in Rust and a wgpu-based display engine.")
    (properties `((upstream-name . "neomacs")))
    (license (list license:gpl3+))))
