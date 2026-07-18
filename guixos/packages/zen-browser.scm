(define-module (guixos packages zen-browser)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xorg)
  #:export (zen-browser-bin))


;; Notes on Updating to latest version:
;; curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | \
;;      grep '"tag_name"'
;; wget https://github.com/zen-browser/desktop/releases/download/ \
;;      <version>/zen.linux-x86_64.tar.xz
;; guix hash zen.linux-x86_64.tar.xz

(define %version "1.21.8b")
(define %zen-hash "1x4nycx7kkyqfjm901ikpsmmcimgyx0kjbjawl0fgny9wibnd8q5")

(define zen-browser-bin
  (package
    (name "zen-browser-bin")
    (version %version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/zen-browser/desktop/releases/download/"
             version
             "/zen.linux-x86_64.tar.xz"))
       (hash (content-hash (base32 %zen-hash) sha256))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("." "lib/zen"))
           #:modules `((ice-9 regex)
                       (ice-9 string-fun)
                       (ice-9 ftw)
                       (srfi srfi-1)
                       (srfi srfi-26)
                       (rnrs bytevectors)
                       (rnrs io ports)
                       (guix elf)
                       (guix build gremlin)
                       ,@%copy-build-system-modules
                       ,@%default-gnu-imported-modules)
           #:phases
           #~(modify-phases (@@ (guix build copy-build-system) %standard-phases)
               (add-after 'install 'wrap-program
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (define* (lib-of input #:key (dir "lib"))
                     (string-append (assoc-ref inputs input) "/" dir))
                   (define (runpath-of lib)
                     (call-with-input-file lib
                       (compose elf-dynamic-info-runpath
                                elf-dynamic-info
                                parse-elf
                                get-bytevector-all)))
                   (define (runpaths-of-input label)
                     (let* ((dir (string-append (assoc-ref inputs label) "/lib"))
                            (libs (find-files dir "\\.so$")))
                       (append-map runpath-of libs)))
                   (let* ((out (assoc-ref outputs "out"))
                          (lib (string-append out "/lib"))
                          (mesa-lib (lib-of "mesa"))
                          ;; For the integration of native notifications
                          (libnotify-lib (lib-of "libnotify"))
                          ;; For hardware video acceleration via VA-API
                          (libva-lib (lib-of "libva"))
                          ;; Needed for video acceleration (via libdrm which mesa
                          ;; and libva depend on).
                          (pciaccess-lib (lib-of "libpciaccess"))
                          ;; Note:
                          ;; VA-API is run in the RDD (Remote Data Decoder)
                          ;; sandbox and must be explicitly given access to files
                          ;; it needs. Rather than adding the whole store
                          ;; (as Nix had upstream do, see
                          ;; <https://github.com/NixOS/nixpkgs/pull/165964> and
                          ;; linked upstream patches), we can just follow the
                          ;; runpaths of the needed libraries to add everything
                          ;; to LD_LIBRARY_PATH.  These will then be accessible
                          ;; in the RDD sandbox.
                          ;; TODO: Properly handle the runpath of libraries needed
                          ;; (for RDD) recursively, so the explicit libpciaccess
                          ;; can be removed.
                          (rdd-whitelist
                           (map (cut string-append <> "/")
                                (delete-duplicates
                                 (append-map runpaths-of-input
                                             '("mesa" "ffmpeg")))))
                          (pulseaudio-lib (lib-of "pulseaudio"))
                          ;; For sharing on Wayland
                          (pipewire-lib (lib-of "pipewire"))
                          ;; For U2F and WebAuthn
                          (eudev-lib (lib-of "eudev"))
                          (gtk-share (lib-of "gtk+" #:dir "share")))
                     (wrap-program (car (find-files lib "^zen$"))
                       `("LD_LIBRARY_PATH" prefix (,mesa-lib
                                                   ,libnotify-lib
                                                   ,libva-lib
                                                   ,pciaccess-lib
                                                   ,pulseaudio-lib
                                                   ,eudev-lib
                                                   ,@rdd-whitelist
                                                   ,pipewire-lib))
                       `("XDG_DATA_DIRS" prefix (,gtk-share))
                       `("MOZ_LEGACY_PROFILES" = ("1"))
                       `("MOZ_ALLOW_DOWNGRADE" = ("1"))))))
               (add-after 'install 'patch-elf
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((ld.so (string-append #$(this-package-input "glibc")
                                               #$(glibc-dynamic-linker)))
                         (rpath (string-join
                                 (cons*
                                  (string-append
                                   #$output "/lib/zen")
                                  (string-append
                                   #$output "/lib/zen/gmp-clearkey/0.1")
                                  (string-append
                                   #$(this-package-input "gtk+") "/share")
                                  (map
                                   (lambda (input)
                                     (string-append (cdr input) "/lib"))
                                   inputs))
                                 ":")))
                     ;; Got this proc from hako's Rosenthal, thanks
                     (define (patch-elf file)
                       (format #t "Patching ~a ..." file)
                       (unless (string-contains file ".so")
                         (invoke "patchelf" "--set-interpreter" ld.so file))
                       (invoke "patchelf" "--set-rpath" rpath file)
                       (display " done\n"))
                     (for-each
                      (lambda (binary)
                        (patch-elf binary))
                      (append
                       (map
                        (lambda (binary)
                          (string-append
                           #$output "/lib/zen/" binary))
                        '("glxtest"
                          "updater"
                          "vaapitest"
                          "vulkantest"
                          "zen"
                          "zen-bin"
                          "pingsender"))
                       (find-files (string-append #$output "/lib/zen")
                                   ".*\\.so.*"))))))
               (add-after 'patch-elf 'install-bin
                 (lambda _
                   (let* ((zen (string-append #$output "/lib/zen/zen"))
                          (bin-zen (string-append #$output "/bin/zen")))
                     (mkdir (string-append #$output "/bin"))
                     (symlink zen bin-zen))))
               (add-after 'install-bin 'install-desktop
                 (lambda _
                   (let* ((share-applications (string-append
                                               #$output "/share/applications"))
                          (desktop (string-append
                                    share-applications "/zen.desktop")))
                     (mkdir-p share-applications)
                     (make-desktop-entry-file
                      desktop
                      #:name "Zen Browser"
                      #:icon "zen"
                      #:type "Application"
                      #:comment #$(package-synopsis this-package)
                      #:exec (string-append #$output "/bin/zen %u")
                      #:keywords '("Internet" "WWW" "Browser" "Web" "Explorer")
                      #:categories '("Network" "Browser")
                      ;; TODO: Not yet supported in Zen Browser
                      ;; #:actions '("new-window"
                      ;;             "new-private-window"
                      ;;             "profilemanager")
                      #:mime-type '("text/html"
                                    "text/xml"
                                    "application/xhtml+xml"
                                    "x-scheme-handler/http"
                                    "x-scheme-handler/https"
                                    "application/x-xpinstall"
                                    "application/pdf"
                                    "application/json")
                      #:startup-w-m-class "zen-alpha"))))
               (add-after 'install-desktop 'install-icons
                 (lambda _
                   (for-each
                    (lambda (size)
                      (let* ((icon-dir (string-append
                                        #$output
                                        "/share/icons/hicolor/"
                                        (number->string size) "x"
                                        (number->string size) "/apps"))
                             (src (string-append
                                   #$output
                                   "/lib/zen/browser/chrome/icons/default/default"
                                   (number->string size) ".png")))
                        (mkdir-p icon-dir)
                        (copy-file src (string-append icon-dir "/zen.png"))))
                    '(16 32 48 64 128)))))))
    (native-inputs (list patchelf))
    (inputs (list alsa-lib
                  eudev
                  gcc-toolchain
                  icu4c
                  gtk+
                  glibc
                  libnotify
                  libva
                  pciutils
                  mesa
                  ffmpeg-6
                  libpciaccess
                  pipewire
                  pulseaudio))
    (home-page "https://zen-browser.app/")
    (synopsis "Privacy-focused web browser based on Firefox")
    (description "Beautifully designed, privacy-focused, and packed with features.
We care about your experience, not your data.")
    (properties `((upstream-name . "zen")
                  (saayix-update? . #f)))
    (license (list license:mpl2.0))))
