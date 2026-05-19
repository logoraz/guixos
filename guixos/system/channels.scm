(define-module (guixos system channels)
  #:use-module (guix channels)
  #:export (%guixos-channels))

;;; Instructions
;;; To pin channels at a certain guix pull do:
;;;
;;; guix describe -f channels > channels.scm
;;;
;;; or to premptively pin at latest master do:
;;;
;;; git ls-remote https://gitlab.com/nonguix/nonguix master
;;; git ls-remote https://codeberg.org/guix/guix.git master

;;;
;;; Main Channels
;;;
(define %nonguix-channel
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix.git")
    (branch "master")
    (commit "5f2630e69fbbe9e79c350a67545f0fef7e93e223")
    (introduction
     (make-channel-introduction
      "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
      (openpgp-fingerprint
       "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))

(define %guix-channel
  (channel
    (name 'guix)
    (url "https://codeberg.org/guix/guix.git")
    (branch "master")
    (commit "5f65d3f998bdee32a3aa9690962c6c8eeaaa8ae0")
    (introduction
     (make-channel-introduction
      "9edb3f66fd807b096b48283debdcddccfea34bad"
      (openpgp-fingerprint
       "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))

;;;
;;; Auxiliary Channels
;;;



;;;
;;; Create Channels List & Apply
;;;
(define %guixos-channels
  (append
   (list %nonguix-channel
         %guix-channel)
   %default-channels))

;; For guix pull
%guixos-channels
