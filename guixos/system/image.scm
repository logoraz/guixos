;;; GuixOS - Disk Image
;;; The operating-system of the host selected in (guixos host), with the
;;; disk layout swapped for what `guix system image` expects, so the real
;;; partition UUIDs are not needed to build a bootable image.
(define-module (guixos system image)
  #:use-module (gnu)
  #:use-module (guixos host)
  #:export (%guixos-image))

(define %guixos-image
  (operating-system
    (inherit (host-operating-system))
    (swap-devices '())
    (file-systems
     (cons (file-system
             (device (file-system-label "my-root"))
             (mount-point "/")
             (type "ext4"))
           %base-file-systems))))

%guixos-image
