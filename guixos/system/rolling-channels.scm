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

(append
 (downloaded-channels
  "https://ci.guix.gnu.org/eval/latest/channels.scm?spec=master")
 (list
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix.git")
    (branch "master")
    (introduction
     (make-channel-introduction
      "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
      (openpgp-fingerprint
       "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))))
