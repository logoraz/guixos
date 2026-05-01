(define-module (config system hosts framework)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services guix)             ;; guix-home-service-type
  ;; Local config
  #:use-module (config system system)
  #:use-module (config system identity)        ;; %home-user
  ;; Integrate home into system
  #:use-module (config home guixos-home)       ;; guixos-home

  #:export (%guixos))


;;;
;;; Framework-specific hardware identifiers
;;;

(define %framework-file-systems
  ;; Use 'blkid' to find unique file system identifiers ("UUIDs").
  (cons* (file-system
          (mount-point "/boot/efi")
          (device (uuid "B0B0-C71A" 'fat32))
          (type "vfat"))
         (file-system
          (mount-point "/")
          (device (uuid "7388e57a-177d-45cf-8005-208b79eb6d2d" 'ext4))
          (type "ext4"))
         %base-file-systems))

(define %framework-swap-devices
  (list (swap-space
         (target
          (uuid "6f510da6-67f2-4de7-8b0e-0745de6457d8")))))


;;;
;;; Framework-specific service additions
;;;

(define %framework-extra-services
  (list
   ;; Integrate home configuration into system reconfigure
   ;; (uncomment to activate)
   ;; (service guix-home-service-type
   ;;          `((,(%home-user) ,guixos-home)))
   ))


;;;
;;; Operating System Definition
;;;

(define %guixos
  (make-guixos-system
   #:host-name "framework"
   #:file-systems %framework-file-systems
   #:swap-devices %framework-swap-devices
   #:extra-services %framework-extra-services))
