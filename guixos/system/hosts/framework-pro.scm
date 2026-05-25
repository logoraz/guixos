(define-module (guixos system hosts framework-pro)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services guix)             ;; guix-home-service-type
  ;; Local config
  #:use-module (guixos system system)
  #:use-module (guixos system identity)        ;; %home-user
  ;; Integrate home into system
  #:use-module (guixos home guixos-home)       ;; guixos-home

  #:export (%guixos))


;;;
;;; Framework-Pro specific hardware identifiers
;;;

;; Use 'blkid' to find unique file system identifiers ("UUIDs").
(define %host-file-systems
  (cons* (file-system
           (mount-point "/boot/efi")
           (device (uuid "TBD" 'fat32))
           (type "vfat"))
         (file-system
           (mount-point "/")
           (device (uuid "TBD" 'ext4))
           (type "ext4"))
         (file-system
           (mount-point "/home")
           (device (uuid "TBD" 'ext4))
           (type "ext4"))
         %base-file-systems))

(define %host-swap-devices
  (list (swap-space
         (target
          (uuid "TBD")))))


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
   ;; Remove once openresolv ships a fix and Guix picks it up.
   (simple-service 'nm-rc-manager
                   activation-service-type
                   #~(begin
                       (use-modules (guix build utils))
                       (mkdir-p "/etc/NetworkManager/conf.d")
                       (call-with-output-file
                           "/etc/NetworkManager/conf.d/rc-manager.conf"
                         (lambda (port)
                           (display "[main]\nrc-manager=file\n" port)))))

   ;; Integrate home configuration into system reconfigure
   (service guix-home-service-type
            `((,(%home-user) ,guixos-home)))

   ;; TODO
   ))

;;;
;;; Framework-Pro specific package additions
;;;

(define %host-extra-packages
  (list
   ;; Add specific packages for this hosts' system
   ))


;;;
;;; Operating System Definition
;;;

(define %guixos
  (make-guixos-system
   #:host-name "framework-pro"
   #:user "locutus"
   #:comment "Worker Bee"
   #:file-systems %host-file-systems
   #:swap-devices %host-swap-devices
   #:extra-services %host-extra-services
   #:extra-packages %host-extra-packages))
