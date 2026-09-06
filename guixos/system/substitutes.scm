(define-module (guixos system substitutes)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 ftw)
  #:use-module (gnu)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:export (substitutes->services
            %guixos-substitute-urls
            %guixos-authorized-keys))


(define %guixos-substitute-urls
  (cons* "https://substitutes.nonguix.org"
         "https://ci.guix.gnu.org"
         %default-substitute-urls))

(define %guixos-authorized-keys
  (cons* (origin
          (method url-fetch)
          (uri "https://substitutes.nonguix.org/signing-key.pub")
          (file-name "nonguix.pub")
          (hash
           (content-hash
            "0j66nq1bxvbxf5n8q2py14sjbkn57my0mjwq7k1qm9ddghca7177")))
         %default-authorized-guix-keys))

;; Use Package substitutes instead of compiling everything
;; https://guix.gnu.org/manual/en/html_node/\
;; Getting-Substitutes-from-Other-Servers.html
;;
;; We update channels via guix pull as opposed to using guix-for-channels
;; as it wasn't using the latest channels.scm

(define* (substitutes->services config)
  (guix-configuration
    (inherit config)
    (substitute-urls %guixos-substitute-urls)
    (authorized-keys %guixos-authorized-keys)))
