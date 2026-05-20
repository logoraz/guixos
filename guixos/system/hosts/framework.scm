(define-module (guixos system hosts framework)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services guix)             ;; guix-home-service-type
  ;; Local config
  #:use-module (guixos services bluetooth)
  #:use-module (guixos system system)
  #:use-module (guixos system identity)        ;; %home-user
  ;; Integrate home into system
  #:use-module (guixos home guixos-home)       ;; guixos-home

  #:export (%guixos))


;;;
;;; Framework specific hardware identifiers
;;;

(define %host-file-systems
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

(define %host-swap-devices
  (list (swap-space
         (target
          (uuid "6f510da6-67f2-4de7-8b0e-0745de6457d8")))))


;;;
;;; Framework specific service additions
;;;

(define %host-extra-services
  (list
   ;; Integrate home configuration into system reconfigure
   (service guix-home-service-type
            `((,(%home-user) ,guixos-home)))

   (service bluetooth-block-service-type
            (bluetooth-block-configuration
             (vendor-id "0e8d")
             (product-id "0717")))))

;;;
;;; Framework specific package additions
;;;

(define %host-extra-packages
  (list
   ;; Add specific packages for this hosts' system
   ;; (uncomment to activate)
   ))


;;;
;;; Operating System Definition
;;;

(define %guixos
  (make-guixos-system
   #:host-name "framework"
   #:user "logoraz"
   #:comment "Erik P Almaraz"
   #:file-systems %host-file-systems
   #:swap-devices %host-swap-devices
   #:extra-services %host-extra-services
   #:extra-packages %host-extra-packages))
