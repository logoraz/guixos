(define-module (config system guixos)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages base)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages file-systems)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnome-xyz)
  #:use-module (gnu packages video)
  #:use-module (gnu services guix)
  #:use-module (gnu services cups)
  #:use-module (gnu services ssh)
  #:use-module (gnu services xorg)
  #:use-module (gnu services desktop)
  #:use-module (gnu services networking)
  #:use-module (gnu system nss)
  #:use-module (gnu system keyboard)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages firmware)
  #:use-module (nongnu system linux-initrd)
  #:use-module (guix transformations)
  #:use-module (config system core substitutes)
  #:use-module (config system core guixos-channels)
  #:use-module (config services firmware)
  #:use-module (config home guixos-home)
  #:export (%guixos))

;;;
;;; operating-system parameters
;;;
(define guixos-user-name "logoraz")

(define %guixos-keyboard-layout
  (keyboard-layout "us"))

(define %guixos-bootloader
  (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout %guixos-keyboard-layout)))

(define %guixos-swap-devices
  (list (swap-space
          (target
           (uuid "6f510da6-67f2-4de7-8b0e-0745de6457d8")))))

(define %guixos-file-systems
  ;; Use 'blkid' to find unique file system identifiers ("UUIDs").
  (cons* (file-system
           (mount-point  "/boot/efi")
           (device (uuid "B0B0-C71A"
			 'fat32))
           (type "vfat"))
         (file-system
           (mount-point "/")
           (device (uuid "7388e57a-177d-45cf-8005-208b79eb6d2d"
			 'ext4))
           (type "ext4"))
	 %base-file-systems))

(define %guixos-groups
  ;; Add the 'seat' group
  (cons
   (user-group (system? #t) (name "seat"))
   %base-groups))

(define %guixos-users
  (cons* (user-account
           (name "logoraz")
           (comment "Erik P Almaraz")
           (home-directory (string-append "/home/" guixos-user-name))
           (group "users")
           (supplementary-groups '("wheel"    ;; sudo
                                   "seat"     ;; greetd/wlgreet
                                   "netdev"   ;; network devices
                                   "tty"      ;; -
                                   "input"    ;; -
                                   "lp"       ;; control bluetooth devices
                                   "audio"    ;; control audio devices
                                   "video"))) ;; control video devices
         %base-user-accounts))

;;;
;;; System Services
;;;
(define %guixos-base-services
  (cons*
   (service gnome-desktop-service-type)

   (set-xorg-configuration
    (xorg-configuration (keyboard-layout %guixos-keyboard-layout)))

   (service bluetooth-service-type
            (bluetooth-configuration
              (auto-enable? #t)))

   ;; Firmware Updating Service via fwupd --> Framework Laptops
   (service fwupd-service-type)

   ;; ssh user@host -p 2222
   (service openssh-service-type
            (openssh-configuration
              (openssh openssh-sans-x)
              (port-number 2222)))

   ;; TODO: New - need to look into & configure!!
   (service tor-service-type)


   (service cups-service-type
            (cups-configuration
              (web-interface? #t)
              (default-paper-size "Letter")
              (extensions (list cups-filters hplip-minimal))))

   ;; Set up home configuration
   (service guix-home-service-type
            `((,guixos-user-name ,guixos-home)))

   ;; See: https://guix.gnu.org/manual/en/html_node/Desktop-Services.html
   (modify-services %desktop-services
     ;; Modify GNOME packages here...
     ;;   (gnome-desktop-service-type
     ;;    cfg =>
     ;;    (gnome-desktop-configuration
     ;;      (inherit cfg)
     ;;      (utilities
     ;;       (remove-by-name
     ;;        '("yelp" "gnome-tour" "cheese")
     ;;        (gnome-desktop-configuration-utilities cfg)))
     ;;      (extra-packages
     ;;       (append (gnome-desktop-configuration-extra-packages cfg)
     ;;               (list gnome-software)))))
     (guix-service-type
      config =>
      (substitutes->services
       config
       #:channels %guixos-channels)))))

;;;
;;; Package Transformations & Packages
;;;
;; ref: https://guix.gnu.org/manual/en/guix.html#Defining-Package-Variants
(define latest-guile ;; example of guile-next
  (options->transformation
   '((with-latest . "guile"))))

;;;
;;; Install bare-minimum system packages
;;;
(define %guixos-base-packages
  (append
   (list
    ;; Lambda
    ;; (specification->package "guile")
    (specification->package "guile-json")
    guile-colorized
    guile-ares-rs
    guile-fibers
    guile-hall
    guile-hoot
    guile-g-golf
    guile-goblins
    emacs-pgtk

    ;; File system & firmware tools
    bcachefs-tools
    polkit
    fwupd-nonfree

    ;; Fonts & GNOME Theme
    font-google-noto
    font-google-noto-emoji
    font-google-noto-sans-cjk
    font-sarasa-gothic
    font-fira-code
    font-iosevka-aile
    bibata-cursor-theme
    gnome-themes-extra
    ffmpegthumbnailer
    gnome-software

    ;; Desktop Tools/Utilities
    pipewire
    ;; wireplumber
    ;; egl-wayland
    bluez
    brightnessctl
    lm-sensors
    openssh-sans-x
    git
    (list git "send-email")
    curl
    wget
    zip
    unzip)

   %base-packages))

;;;
;;; Define GuixOS
;;;
(define %guixos
  (operating-system
    ;; (inherit system)
    (host-name "framework")
    (timezone "America/Chicago")
    (locale "en_US.utf8")
    (keyboard-layout %guixos-keyboard-layout)
    (kernel linux)
    (firmware (list linux-firmware))
    (initrd microcode-initrd)

    (bootloader %guixos-bootloader)

    (swap-devices %guixos-swap-devices)

    (file-systems %guixos-file-systems)

    (groups %guixos-groups)

    (users %guixos-users)

    (packages %guixos-base-packages)

    (services %guixos-base-services)

    ;; Allow resolution of '.local' host names with mDNS.
    (name-service-switch %mdns-host-lookup-nss)))

;;; Instantiate GuixOS
%guixos
