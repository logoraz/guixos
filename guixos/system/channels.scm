;;; GuixOS channels. Single source of truth.
;;; Consumed by:
;;;   - guix pull / guix time-machine (read directly, sandbox-compatible)
;;;   - mutable-files.scm (symlinked to ~/.config/guix/channels.scm)
;;;   - see: https://codeberg.org/guix/guix/pulls/6745
;;;
;;; To pin channels at a certain guix pull do:
;;;
;;; guix describe -f channels > channels.scm
;;;
;;; or to preemptively pin at latest master do:
;;;
;;; git ls-remote https://gitlab.com/nonguix/nonguix master
;;; git ls-remote https://codeberg.org/guix/guix.git master
;;;

(list
 (channel
   (name 'nonguix)
   (url "https://gitlab.com/nonguix/nonguix.git")
   (branch "master")
   (commit "57b156aa003e2b6eacf979cac377e4b585bf3a19")
   (introduction
    (make-channel-introduction
     "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
     (openpgp-fingerprint
      "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
 (channel
   (name 'guix)
   (url "https://codeberg.org/guix/guix.git")
   (branch "master")
   (commit "505ade83fc62b438c558653dd57f7fb3b197cc8f")
   (introduction
    (make-channel-introduction
     "9edb3f66fd807b096b48283debdcddccfea34bad"
     (openpgp-fingerprint
      "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))


;;; GuixOS rolling channels
;;;
;;; Status: UNTESTED. Nothing loads this file. The pinned channels.scm
;;; stays the active setup until this one is swapped in by hand.
;;;
;;; Idea: roll forward instead of pinning, but only to guix commits that
;;; CI has evaluated successfully, with nonguix following its master
;;; branch. The CI file serves the guix channel only, so nonguix is
;;; added by hand below.
;;;
;;; Needs a Guix new enough to provide `downloaded-channels'
;;; (news commit a6292be).
;;;
;;; Open questions before trusting it:
;;;   - Can `append' combine a list with `downloaded-channels'?
;;;   - Does the channel file sandbox allow `append'?
;;;   - Is nonguix master compatible with CI's latest guix commit?
;;;   - Evaluated by CI does not guarantee every package builds.
;;;
;;; Test as follows:
;;;
;;;  guix time-machine -C rolling-channels.scm -- describe
;;;

;; (append
;;  (downloaded-channels
;;   "https://ci.guix.gnu.org/eval/latest/channels.scm?spec=master")
;;  (list
;;   (channel
;;     (name 'nonguix)
;;     (url "https://gitlab.com/nonguix/nonguix.git")
;;     (branch "master")
;;     (introduction
;;      (make-channel-introduction
;;       "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
;;       (openpgp-fingerprint
;;        "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))))
