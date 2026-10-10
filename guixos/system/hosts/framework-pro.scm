(define-module (guixos system hosts framework-pro)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu services)
  ;; Local config
  #:use-module (guixos system system)
  #:use-module (guixos system host-profile)  ;; make-host-profile & accessors
  #:export (%host-profile
            host-operating-system))


;;;
;;; Framework-Pro specific hardware identifiers
;;;

;; Use 'blkid' to find unique file system identifiers ("UUIDs").
(define %host-file-systems
  (cons* (file-system
           (mount-point "/boot/efi")
           (device (uuid "0000-0000" 'fat32))
           (type "vfat"))
         (file-system
           (mount-point "/")
           (device (uuid "00000000-0000-0000-0000-000000000000" 'ext4))
           (type "ext4"))
         (file-system
           (mount-point "/home")
           (device (uuid "00000000-0000-0000-0000-000000000000" 'ext4))
           (type "ext4"))
         %base-file-systems))

(define %host-swap-devices
  (list (swap-space
         (target
          (uuid "00000000-0000-0000-0000-000000000000")))))


;;;
;;; Framework-Pro specific service additions
;;;

(define %host-extra-services
  (list
   ;; Workaround: force NetworkManager to write /etc/resolv.conf directly
   ;; instead of delegating to openresolv.  openresolv >= 3.17 broke NM's
   ;; auto-detected resolvconf integration: NM thinks resolvconf is handling
   ;; DNS, openresolv silently no-ops, and /etc/resolv.conf is left as the
   ;; Guix placeholder -- breaking all DNS resolution despite a healthy
   ;; connection.  Setting rc-manager=file bypasses openresolv entirely.
   ;;
   ;; Upstream issue: https://github.com/NetworkConfiguration/openresolv/issues/38
   ;; Other distros hitting it: https://github.com/void-linux/void-packages/issues/54888
   ;;
   ;; Remove once Guix's NetworkManager defaults rc-manager to resolvconf...
   (simple-service 'nm-rc-manager
                   activation-service-type
                   #~(begin
                       (use-modules (guix build utils))
                       (mkdir-p "/etc/NetworkManager/conf.d")
                       (call-with-output-file
                           "/etc/NetworkManager/conf.d/rc-manager.conf"
                         (lambda (port)
                           (display "[main]\nrc-manager=file\n" port)))))))

;;;
;;; Framework-Pro specific package additions
;;;

(define %host-extra-packages
  (list
   ;; Add specific packages for this hosts' system
   ))


;;;
;;; Host Profile and Operating System
;;;

;; Describes this machine; read by both system and home entry points.
(define %host-profile
  (make-host-profile "framework-pro" "logoraz" "Farm Craft" 'sway))

(define (host-operating-system)
  "Return the operating-system for this host, built from %host-profile.
It is a thunk so that importing the module does not set any parameters."
  (make-guixos-system
   #:host-name (host-profile-name %host-profile)
   #:user (host-profile-user %host-profile)
   #:window-manager (host-profile-window-manager %host-profile)
   #:comment (host-profile-comment %host-profile)
   #:file-systems %host-file-systems
   #:swap-devices %host-swap-devices
   #:extra-services %host-extra-services
   #:extra-packages %host-extra-packages))
