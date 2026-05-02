(define-module (config system channels)
  #:use-module (guix channels)
  #:export (%guixos-channels))

;;; Instructions
;;; To pin channels at a certain guix pull do:
;;;
;;; guix describe -f channels > channels.scm
;;;
;;; or to premptively pin at latest master do:
;;;
;;; git ls-remote https://codeberg.org/guix/guix.git master
;;; git ls-remote https://gitlab.com/nonguix/nonguix master

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
    (commit "7911de258df53e5ec6dca6b4e04f16b1afa1d327")
    (introduction
     (make-channel-introduction
      "9edb3f66fd807b096b48283debdcddccfea34bad"
      (openpgp-fingerprint
       "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))

;;;
;;; Auxiliary Channels
;;;
(define %rde-channel
  (channel
    (name 'rde)
    (url "https://git.sr.ht/~abcdw/rde")
    (branch "master")
    (introduction
     (make-channel-introduction
      "257cebd587b66e4d865b3537a9a88cccd7107c95"
      (openpgp-fingerprint
       "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0")))))

(define %guixrus-channel
  (channel
    (name 'guixrus)
    (url "https://git.sr.ht/~whereiseveryone/guixrus")
    (branch "master")
    (introduction
     (make-channel-introduction
      "7c67c3a9f299517bfc4ce8235628657898dd26b2"
      (openpgp-fingerprint
       "CD2D 5EAA A98C CB37 DA91  D6B0 5F58 1664 7F8B E551")))))

(define %saayix-channel
  (channel
    (name 'saayix)
    (url "https://codeberg.org/look/saayix")
    (branch "main")
    (introduction
     (make-channel-introduction
      "12540f593092e9a177eb8a974a57bb4892327752"
      (openpgp-fingerprint
       "3FFA 7335 973E 0A49 47FC  0A8C 38D5 96BE 07D3 34AB")))))


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
