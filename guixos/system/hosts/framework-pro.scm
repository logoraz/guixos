(define-module (guixos system hosts framework-pro)
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
   ;; Integrate home configuration into system reconfigure
   (service guix-home-service-type
            `((,(%home-user) ,guixos-home)))

   (service bluetooth-block-service-type
            (bluetooth-block-configuration
             (vendor-id "0e8d")
             (product-id "0717")))))

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
