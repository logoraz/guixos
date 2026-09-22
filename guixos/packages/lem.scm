(define-module (guixos packages lem)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system asdf)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages tree-sitter)
  #:use-module ((gnu packages text-editors) #:prefix upstream:)
  #:export (webview-core sbcl-webview sbcl-jsonrpc-with-transports
            sbcl-frugal-uuid sbcl-tree-sitter-cl lem))

;;;
;;; Updating Lem
;;;
;;; git clone https://github.com/lem-project/lem.git
;;; cd lem && git checkout <new-commit>
;;; cd .. && guix hash -r -x lem/
;;;
;;; guix build -L ~/.config/guixos --expression='(@ (guixos packages lem) lem)'
;;;


;;;
;;; webview-core — the native C/C++ webview/webview library itself.
;;; Its own CMake build exports a versioned shared library target
;;; (webview::core_shared, installed as libwebview.so.0.12.0 on Linux)
;;; that lem-webview's CFFI bindings load directly by that exact name.
;;;
(define-public webview-core
  (let ((commit "3ab4b5d722438fc8a13e6ca830c5e2372d19a01d")
        (version "0.12.0")
        (hash "0xfbcwsgjxsqb1whp18crajhqvm5di7dawrn4n6m08lzbmvahsm6"))
    (package
      (name "webview-core")
      ;; commit is exactly what the 0.12.0 tag points at, so the plain
      ;; release version is accurate here.
      (version version)
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
                (url "https://github.com/webview/webview")
                (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           hash))))
      (build-system cmake-build-system)
      (arguments
       (list
        #:configure-flags
        #~(list "-DWEBVIEW_BUILD_SHARED_LIBRARY=ON"
                "-DWEBVIEW_BUILD_STATIC_LIBRARY=OFF"
                "-DWEBVIEW_BUILD_TESTS=OFF"
                "-DWEBVIEW_BUILD_EXAMPLES=OFF"
                "-DWEBVIEW_BUILD_DOCS=OFF"
                "-DWEBVIEW_INSTALL_DOCS=OFF"
                "-DWEBVIEW_ENABLE_CHECKS=OFF"
                "-DWEBVIEW_ENABLE_PACKAGING=OFF")
        #:tests? #f))
      (native-inputs (list pkg-config))
      (inputs (list gtk webkitgtk))
      (home-page "https://github.com/webview/webview")
      (synopsis "Tiny cross-platform library for HTML/CSS/JS-based GUIs")
      (description
       "Webview is a tiny cross-platform library for building modern GUIs
using a web-based front end.  On Linux it is backed by GTK and
WebKitGTK, on macOS by Cocoa and WebKit, and on Windows by WebView2.")
      (license license:expat))))

;;;
;;; sbcl-webview — lem-project's CFFI bindings around webview-core,
;;; pinned to the commit lem's qlfile.lock actually resolves.
;;;
(define-public sbcl-webview
  (let ((commit "607daff93e9e716a76c5dbd08c48b5233c96b9a3")
        (revision "0")
        (hash "18fgbvpgd587993m8lwdd80djsrc7pb2c5d1bq88znmmnz6rp5bx"))
    (package
      (name "sbcl-webview")
      (version (git-version "0.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
                (url "https://github.com/lem-project/webview")
                (commit commit)))
         (file-name (git-file-name "cl-webview" version))
         (sha256
          (base32
           hash))
         (snippet
          #~(begin
              (use-modules (guix build utils))
              ;; The repo checks in prebuilt libwebview binaries for
              ;; every platform (lib/linux/x64, lib/win/x64,
              ;; lib/macosx/arm64, ...). Strip them all; the
              ;; vendor-native-webview-library phase below repopulates
              ;; just the one file this package actually needs, built
              ;; from source via webview-core.
              (delete-file-recursively "lib")))))
      (build-system asdf-build-system/sbcl)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'vendor-native-webview-library
              ;; webview.lisp's define-foreign-library resolves
              ;; libwebview.so.0.12.0 relative to its own ASDF system
              ;; at lib/<os>/<arch>/ (see its BUILD.md). Rather than
              ;; patch that multi-line form, just drop webview-core's
              ;; build there directly, matching the upstream convention.
              (lambda* (#:key inputs #:allow-other-keys)
                (let ((lib-dir "lib/linux/x64"))
                  (mkdir-p lib-dir)
                  (install-file (search-input-file
                                 inputs "lib/libwebview.so.0.12.0")
                                lib-dir)))))))
      (inputs (list webview-core sbcl-cffi sbcl-float-features))
      (home-page "https://github.com/lem-project/webview")
      (synopsis "Common Lisp CFFI bindings for the webview library")
      (description
       "Common Lisp CFFI bindings around the native webview/webview C
library, used by Lem's webview frontend.")
      (license license:expat))))

;;;
;;; sbcl-jsonrpc-with-transports — Guix's sbcl-jsonrpc has no
;;; arguments override at all, so asdf-build-system/sbcl's default
;;; applies: only the primary "jsonrpc" system gets precompiled.
;;; jsonrpc.asd is a :package-inferred-system, so the transport
;;; variants (transport/stdio.lisp, transport/websocket.lisp,
;;; transport/local-domain-socket.lisp) are each their own separate,
;;; lazily-compiled system that nobody asked for at sbcl-jsonrpc's own
;;; build time. lem-server needs three of them; without this, lem's
;;; own build tries to compile them fresh directly into sbcl-jsonrpc's
;;; already-built, read-only store output, and fails.
;;;
(define-public sbcl-jsonrpc-with-transports
  (package
    (inherit sbcl-jsonrpc)
    (arguments
     (list #:asd-systems
           ''("jsonrpc"
              "jsonrpc/transport/stdio"
              "jsonrpc/transport/websocket"
              "jsonrpc/transport/local-domain-socket")))))

(define-public sbcl-frugal-uuid
  (let ((commit "b25fcddef4c653f072b76993ba7d48d8c063fe61")
        (revision "0")
        (hash "1pj0cg2bcf9bx1xfmzcps0b2a9j4lvi1h5nn0y6sz93mhkkqza16"))
    (package
      (name "sbcl-frugal-uuid")
      (version (git-version "0.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/ak-coram/cl-frugal-uuid")
               (commit commit)))
         (file-name (git-file-name "cl-frugal-uuid" version))
         (sha256
          (base32
           hash))))
      (build-system asdf-build-system/sbcl)
      (arguments (list #:tests? #f))
      (home-page "https://github.com/ak-coram/cl-frugal-uuid")
      (synopsis "Common Lisp UUID library with zero dependencies")
      (description
       "Frugal-uuid is a Common Lisp UUID library covering RFC 9562,
including generating, parsing, and comparing UUID values.")
      (license license:expat))))

;;;
;;; sbcl-tree-sitter-cl — CFFI bindings for tree-sitter. Also builds
;;; the repo's own small C wrapper (c-wrapper/ts-wrapper.c, providing
;;; out-pointer versions of functions that return structs by value)
;;; against Guix's tree-sitter package, since upstream's own Makefile
;;; assumes system-wide headers/libs that don't exist in the build
;;; sandbox. Both libtree-sitter.so and the installed libts-wrapper.so
;;; are found via plain bare-name CFFI search at runtime (not a fixed
;;; relative path, unlike webview) — Guix's own make-dynamic-linker-cache
;;; phase (already observed running for lem itself) should make both
;;; resolve automatically once tree-sitter is a real input here.
;;;
(define-public sbcl-tree-sitter-cl
  (let ((commit "431b572d0e49d64a78320cc5f4b4a90391024ce6")
        (revision "0")
        (hash "11nblk5b8wazpjz0ajhq02l59dm984ikxxxs0w1mljx8j5pa3c2x"))
    (package
      (name "sbcl-tree-sitter-cl")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/lem-project/tree-sitter-cl")
               (commit commit)))
         (file-name (git-file-name "tree-sitter-cl" version))
         (sha256
          (base32
           hash))))
      (build-system asdf-build-system/sbcl)
      (arguments
       (list
        #:tests? #f
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'build-ts-wrapper
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke #$(cc-for-target) "-shared" "-fPIC" "-Wall" "-Wextra"
                        (string-append "-I" (assoc-ref inputs "tree-sitter")
                                      "/include")
                        (string-append "-L" (assoc-ref inputs "tree-sitter")
                                      "/lib")
                        "-o" "c-wrapper/libts-wrapper.so"
                        "c-wrapper/ts-wrapper.c"
                        "-ltree-sitter")))
            (add-after 'build-ts-wrapper 'install-ts-wrapper
              (lambda* (#:key outputs #:allow-other-keys)
                (let ((lib-dir (string-append
                                (assoc-ref outputs "out") "/lib")))
                  (mkdir-p lib-dir)
                  (install-file "c-wrapper/libts-wrapper.so" lib-dir)))))))
      (inputs (list tree-sitter sbcl-cffi sbcl-alexandria
                    sbcl-trivial-garbage sbcl-babel))
      (home-page "https://github.com/lem-project/tree-sitter-cl")
      (synopsis "Common Lisp bindings for tree-sitter")
      (description
       "Tree-sitter-cl provides FFI bindings to tree-sitter, an
incremental parsing library, supporting parsing, AST traversal, and
pattern queries.")
      (license license:expat))))

;;;
;;; lem — inherit Guix's own package but move past the v2.3.0 tag to
;;; the commit that introduced the webview frontend (frontends/webview
;;; does not exist at all in v2.3.0's tree), load lem-webview alongside
;;; ncurses/sdl2, and install the desktop entry + icon that the
;;; inherited build-program phase never touches.
;;;
(define-public lem
  (let* ((commit "8cb20907afff571dddf2baa8feef606b9d2ad648")
         (revision "2")
         (pinned-version (git-version "2.3.0" revision commit)))
    (package
      (inherit upstream:lem)
      (version pinned-version)
      (source
       (origin
         (inherit (package-source upstream:lem))
         (uri (git-reference
               (url "https://github.com/lem-project/lem/")
               (commit commit)))
         (file-name (git-file-name "lem" pinned-version))
         (sha256
          (base32
           "19fmg0ak2wix9ymflhz3y8ghrkfhfqys1yh9aqx0dw76zr0fjdqc"))
         (snippet
          #~(begin
              (use-modules (guix build utils))
              (delete-file-recursively "roswell")
              ;; lem-extension-manager references QL-DIST unconditionally
              ;; in its own main.lisp, not gated behind #+quicklisp like
              ;; the rest of that file, so it cannot compile outside a
              ;; Quicklisp-based build at all. Its only guard upstream is
              ;; #-nix-build, which doesn't help us either (we aren't
              ;; nix-build), so strip both the guard and the dependency
              ;; line entirely rather than fix or stub out third-party
              ;; code.
              (substitute* "lem.asd"
                (("#-nix-build\n") "")
                (("\"lem-extension-manager\"\n") "")
                ((":defsystem-depends-on \\(\"deploy\"\\)\n") "")
                ;; Rather than reactively strip individual broken
                ;; extensions out of lem/extensions' own :depends-on
                ;; list as they surface (lem-zig-mode has a malformed
                ;; cl-ppcre alternation in its syntax table;
                ;; lem-living-canvas needs a micros symbol not present
                ;; in the version inherited from upstream), append a
                ;; fresh redefinition of the whole system instead.
                ;; defsystem is idempotent, and ASDF loads this entire
                ;; file top-to-bottom before building anything, so
                ;; whichever definition comes last simply wins -- no
                ;; need to locate or remove the original at all. This
                ;; is upstream's own extensions list at this commit,
                ;; confirmed working, minus lem-zig-mode and
                ;; lem-living-canvas. Upstream's own #+sbcl / #-clasp /
                ;; #-os-windows conditionals on individual entries are
                ;; dropped, since every one of them is unconditionally
                ;; true for an SBCL-on-Linux build anyway. Appended via
                ;; substitute* (matching the file's own final line)
                ;; rather than raw open-file/display, since the
                ;; checkout sandbox refuses append-mode writes even
                ;; though substitute*'s own rewrites work fine.
                (("\\(:file \"windows\" :if-feature :os-windows\\)\\)\\)\n")
                 (string-append
                  "(:file \"windows\" :if-feature :os-windows)))\n"
                  "\n\n(defsystem \"lem/extensions\"\n  :depends-on ("
                  "\"lem-welcome\" \"lem-lsp-mode\" \"lem-vi-mode\" "
                  "\"lem-lisp-mode\" \"lem-go-mode\" \"lem-swift-mode\" "
                  "\"lem-ansible-mode\" \"lem-c-mode\" \"lem-python-mode\" "
                  "\"lem-posix-shell-mode\" \"lem-xml-mode\" \"lem-js-mode\" "
                  "\"lem-css-mode\" \"lem-html-mode\" \"lem-vue-mode\" "
                  "\"lem-typescript-mode\" \"lem-typst-mode\" "
                  "\"lem-json-mode\" \"lem-rust-mode\" \"lem-kotlin-mode\" "
                  "\"lem-paredit-mode\" \"lem-nim-mode\" \"lem-odin-mode\" "
                  "\"lem-scheme-mode\" \"lem-clojure-mode\" "
                  "\"lem-patch-mode\" \"lem-toml-mode\" \"lem-yaml-mode\" "
                  "\"lem-review-mode\" \"lem-asciidoc-mode\" "
                  "\"lem-dart-mode\" \"lem-scala-mode\" \"lem-dot-mode\" "
                  "\"lem-java-mode\" \"lem-haskell-mode\" \"lem-ocaml-mode\" "
                  "\"lem-asm-mode\" \"lem-wat-mode\" \"lem-makefile-mode\" "
                  "\"lem-shell-mode\" \"lem-sql-mode\" \"lem-base16-themes\" "
                  "\"lem-elixir-mode\" \"lem-ruby-mode\" \"lem-perl-mode\" "
                  "\"lem-erlang-mode\" \"lem-documentation-mode\" "
                  "\"lem-elisp-mode\" \"lem-terraform-mode\" \"lem-nix-mode\" "
                  "\"lem-markdown-mode\" \"lem-color-preview\" "
                  "\"lem-lua-mode\" \"lem-terminal\" \"lem-legit\" "
                  "\"lem-tutor\" \"lem-dashboard\" \"lem-dockerfile-mode\" "
                  "\"lem-copilot\" \"lem-claude-code\" \"lem-bookmark\" "
                  "\"lem-mcp-server\" \"lem-transient\" \"lem-tree-sitter\" "
                  "\"lem-git-gutter\" \"lem-skk-mode\" "
                  "\"lem-emacs-help-mode\" \"lem-display-time-mode\" "
                  "\"lem-tramp\"))\n")))))))
      (inputs
       (modify-inputs (package-inputs upstream:lem)
         (prepend sbcl-webview sbcl-command-line-arguments
                  sbcl-frugal-uuid sbcl-tree-sitter-cl sbcl-cl-mustache)
         (replace "sbcl-jsonrpc" sbcl-jsonrpc-with-transports)))
      (arguments
       (cons*
        #:asd-systems ''("lem-ncurses" "lem-sdl2" "lem-webview")
        (substitute-keyword-arguments (package-arguments upstream:lem)
          ((#:phases phases)
           #~(modify-phases #$phases
               (replace 'build-program
                 (lambda* (#:key outputs #:allow-other-keys)
                   (build-program
                    (string-append (assoc-ref outputs "out") "/bin/lem")
                    outputs
                    #:dependencies '("lem-ncurses" "lem-sdl2"
                                     "lem-webview")
                    #:entry-program '((lem:main) 0))))
               (add-after 'build-program 'install-desktop-file
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (apps (string-append
                                 out "/share/applications"))
                          (icons (string-append
                                  out
                                  "/share/icons/hicolor/scalable/apps")))
                     (mkdir-p apps)
                     (mkdir-p icons)
                     (install-file "scripts/install/lem.svg" icons)
                     (make-desktop-entry-file
                      (string-append apps "/lem.desktop")
                      #:name "Lem"
                      #:comment
                      "Common Lisp editor/IDE with high expansibility"
                      #:exec
                      (string-append out "/bin/lem -i webview %F")
                      #:icon "lem"
                      #:terminal #f
                      #:type "Application"
                      #:mime-type
                      (string-append
                       "text/english;text/plain;text/x-makefile;"
                       "text/x-c++hdr;text/x-c++src;"
                       "application/x-shellscript;text/x-c;text/x-c++;")
                      #:categories
                      '("Development" "TextEditor")))))))))))))
