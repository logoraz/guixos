;;; GuixOS - Host Profile
;;; Plain data describing one machine; read by the system and home entry points.
(define-module (guixos system host-profile)
  #:use-module (srfi srfi-9)
  #:export (make-host-profile
            host-profile?
            host-profile-name
            host-profile-user
            host-profile-comment
            host-profile-window-manager))

(define-record-type <host-profile>
  (make-host-profile name user comment window-manager)
  host-profile?
  (name host-profile-name)                      ; string, e.g. "framework"
  (user host-profile-user)                      ; string, login name
  (comment host-profile-comment)                ; string, free-form note
  (window-manager host-profile-window-manager)) ; symbol, 'sway or 'mahogany
