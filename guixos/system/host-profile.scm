;;; GuixOS - Host Profile
;;; Plain data describing one machine; read by the system and home entry points.
(define-module (guixos system host-profile)
  #:use-module (srfi srfi-9)
  #:export (make-host-profile
            host-profile?
            host-profile-name
            host-profile-user
            host-profile-comment
            host-profile-window-manager
            host-profile-features))

(define-record-type <host-profile>
  (%make-host-profile name user comment window-manager features)
  host-profile?
  (name host-profile-name)                      ; string, e.g. "framework"
  (user host-profile-user)                      ; string, login name
  (comment host-profile-comment)                ; string, free-form note
  (window-manager host-profile-window-manager)  ; symbol, 'sway or 'mahogany
  (features host-profile-features))


(define* (make-host-profile name user comment window-manager
                            #:key (features '()))
  "Return a host profile for NAME, USER, COMMENT and WINDOW-MANAGER.
FEATURES is a list of symbols naming optional extras, such as '(labview);
it defaults to the empty list."
  (%make-host-profile name user comment window-manager features))
