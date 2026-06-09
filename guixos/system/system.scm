(define-module (guixos system system)
  ;; Core Guix DSL & utilities
  #:use-module (gnu)
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (guix channels)

  ;; System primitives
  #:use-module (gnu system keyboard)
  #:use-module (gnu system nss)

  ;; Lisp Dev Stack
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages zig)

  ;; WM, Login & Terminal
  #:use-module (gnu packages wm)               ;; sway, swaylock-effects
  #:use-module (gnu packages gnome)            ;; librsvg
  #:use-module (gnu packages terminals)        ;; foot

  ;; Fonts & Themes
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages gnome-xyz)        ;; bibata-cursor

  ;; Hardware runtimes (audio, bluetooth, brightness, sensors)
  #:use-module (gnu packages linux)

  ;; Filesystem & firmware
  #:use-module (gnu packages file-systems)     ;; bcachefs-tools
  #:use-module (gnu packages polkit)
  #:use-module (nongnu packages firmware)      ;; fwupd-nonfree, linux-firmware
  #:use-module (nongnu packages linux)         ;; linux (kernel)
  #:use-module (nongnu system linux-initrd)    ;; microcode-initrd

  ;; Printing
  #:use-module (gnu packages cups)             ;; cups-filters, hplip-minimal

  ;; Containers
  #:use-module (gnu system accounts)
  #:use-module (gnu services containers)
  #:use-module (gnu packages containers)

  ;; CLI essentials
  #:use-module (gnu packages admin)            ;; tree
  #:use-module (gnu packages compression)      ;; zip, unzip
  #:use-module (gnu packages curl)
  #:use-module (gnu packages ssh)              ;; openssh-sans-x
  #:use-module (gnu packages version-control)  ;; git
  #:use-module (gnu packages wget)

  ;; Services
  #:use-module (gnu services shepherd)
  #:use-module (gnu services cups)
  #:use-module (gnu services desktop)
  #:use-module (gnu services guix)
  #:use-module (gnu services networking)       ;; tor-service-type
  #:use-module (gnu services ssh)
  #:use-module (gnu services xorg)             ;; screen-locker, gdm-service-type

  ;; Local config modules
  #:use-module (guixos packages zen-browser)
  #:use-module (guixos services firmware)      ;; fwupd-service-type
  #:use-module (guixos system identity)        ;; %home-user
  #:use-module (guixos system substitutes)
  #:export (make-guixos-system))


;;;
;;; Operating System Parameters
;;;

(define %guixos-keyboard-layout
  (keyboard-layout "us"))

(define %guixos-bootloader
  (bootloader-configuration
   (bootloader grub-efi-bootloader)
   (targets '("/boot/efi"))
   (keyboard-layout %guixos-keyboard-layout)))

(define %guixos-groups
  ;; Add the 'seat' group
  (cons (user-group (system? #t) (name "seat"))
        %base-groups))

(define (%guixos-users username comment)
  (cons* (user-account
          (name (%home-user username))
          (comment comment)
          (home-directory (string-append "/home/" (%home-user)))
          (group "users")
          (supplementary-groups '("wheel"    ;; sudo
                                  "seat"     ;; greetd/wlgreet
                                  "netdev"   ;; network devices
                                  "tty"      ;; -
                                  "input"    ;; -
                                  "lp"       ;; control bluetooth devices
                                  "audio"    ;; control audio devices
                                  "video"    ;; control video devices
                                  "dialout"  ;; serial port access
                                  "cgroup")));; rootless podman delegation
         %base-user-accounts))


;;;
;;; System Services
;;;

;;; Greetd Configuration
(define %greetd-backsplash
  (local-file "../../files/assets/wallpapers/guix-bottom-checkered-16-9.svg"))

(define %greetd-conf
  (mixed-text-file "sway-greetd.conf"
                   "# sway greetd configuration file

# Configure Mouse & Scale
seat seat0 xcursor_theme Bibata-Modern-Classic 20
output eDP-1 scale 1.6

# Background image (resolved at build time)
output * bg " %greetd-backsplash " fill

input type:keyboard {
  xkb_layout us
  xkb_options ctrl:nocaps
}
"))

(define %sway-logged
  (program-file
   "sway-logged"
   #~(begin
       (use-modules (ice-9 popen))
       ;; Open the log for append, redirect both stdout and stderr to it,
       ;; then exec sway so it inherits those fds and replaces this process.
       (let ((log (open-file "/tmp/greetd-sway.log" "a")))
         (dup2 (fileno log) 1)
         (dup2 (fileno log) 2)
         (close-port log))
       (execl #$(file-append sway "/bin/sway")
              "sway"))))

(define %guixos-base-services
  (cons*
   (service screen-locker-service-type
            (screen-locker-configuration
              (name "swaylock")
              (program (file-append swaylock-effects "/bin/swaylock"))
              (using-pam? #t)
              (using-setuid? #f)))

   (service bluetooth-service-type
            (bluetooth-configuration
              (auto-enable? #t)))

   (service cups-service-type
            (cups-configuration
              (web-interface? #t)
              (default-paper-size "Letter")
              (extensions (list cups-filters hplip-minimal))))

   ;; ssh user@host -p 2222
   (service openssh-service-type
            (openssh-configuration
              (openssh openssh-sans-x)
              (port-number 2222)))

   ;; TODO: New - need to look into & configure!!
   (service tor-service-type)

   ;; TODO: Create (greetd-wlgreet-configuration-service-type)
   ;; see fwuupd-service-type
   (service greetd-service-type
            (greetd-configuration
              (greeter-supplementary-groups '("video" "input" "seat" "users"))
              (terminals
               (list
                (greetd-terminal-configuration
                  (terminal-vt "1")
                  (terminal-switch #t)
                  (default-session-command
                    (greetd-wlgreet-sway-session
                      (sway sway)
                      (sway-configuration %greetd-conf)
                      (command %sway-logged))))
                (greetd-terminal-configuration (terminal-vt "2"))
                (greetd-terminal-configuration (terminal-vt "3"))
                (greetd-terminal-configuration (terminal-vt "4"))
                (greetd-terminal-configuration (terminal-vt "5"))
                (greetd-terminal-configuration (terminal-vt "6"))
                (greetd-terminal-configuration (terminal-vt "7"))))))

   ;; Firmware Updating Service via fwupd
   (service fwupd-service-type)

   ;; Rootless containers for distrobox
   (service rootless-podman-service-type
            (rootless-podman-configuration
              (subgids (list (subid-range (name (%home-user)))))
              (subuids (list (subid-range (name (%home-user)))))))

   ;; See: https://guix.gnu.org/manual/en/html_node/Desktop-Services.html
   (modify-services %desktop-services
     ;; remove gdm-service-type
     (delete gdm-service-type)

     ;; greetd-service-type provides "greetd" PAM service
     (delete login-service-type)

     ;; and can be used in place of mingetty-service-type
     (delete mingetty-service-type)

     (shepherd-system-log-service-type
      config =>
      (system-log-configuration
        (inherit config)
        (max-silent-time #f)))

     (guix-service-type
      config =>
      (substitutes->services
       config
       #:channels (load (string-append (config-source)
                                       "/guixos/system/channels.scm")))))))


;;;
;;; Package Categories
;;;

;;; Lisp Machine
(define %guixos-lisp-stack
  (list guile-colorized
        guile-ares-rs
        guile-fibers
        guile-g-golf
        guile-hall
        guile-hoot
        zig
        sbcl
        emacs-pgtk))

;;; File system & firmware tools
(define %guixos-system-tools
  (list efibootmgr
        bcachefs-tools
        polkit
        fwupd-nonfree))

;;; WM & Login Manager — needed for greetd/wlgreet configuration
(define %guixos-wm
  (list sway
        swaylock-effects
        librsvg
        foot))

;;; Fonts
(define %guixos-fonts
  (list font-google-noto
        font-google-noto-emoji
        font-google-noto-sans-cjk
        font-sarasa-gothic
        font-fira-code
        font-hack
        font-iosevka-aile
        font-jetbrains-mono
        font-liberation
        font-awesome))

;;; Themes
(define %guixos-themes
  (list bibata-cursor-theme))

;;; Hardware runtimes
(define %guixos-hardware-runtimes
  (list pipewire
        wireplumber
        bluez
        brightnessctl
        lm-sensors))

;;; Browser
(define %guixos-browsers
  (list zen-browser-bin))

;;; Containers
(define %guixos-containers
  (list distrobox
        podman))

;;; CLI essentials
(define %guixos-cli
  (list openssh-sans-x
        git
        (list git "send-email")
        curl
        wget
        zip
        unzip
        tree))

(define %guixos-base-packages
  (append %guixos-lisp-stack
          %guixos-system-tools
          %guixos-wm
          %guixos-fonts
          %guixos-themes
          %guixos-hardware-runtimes
          %guixos-browsers
          %guixos-containers
          %guixos-cli
          %base-packages))


;;;
;;; Operating System Constructor
;;;

(define* (make-guixos-system #:key
                             host-name
                             user
                             comment
                             file-systems
                             swap-devices
                             (extra-packages '())
                             (extra-services '()))
  "Build a GuixOS operating-system record for a specific host.
HOST-NAME, FILE-SYSTEMS, and SWAP-DEVICES are required and must be
supplied by the host-specific configuration. EXTRA-PACKAGES and
EXTRA-SERVICES are optional escape hatches for host-specific additions."
  (operating-system
    (host-name host-name)
    (timezone "America/Chicago")
    (locale "en_US.utf8")
    (keyboard-layout %guixos-keyboard-layout)
    (kernel linux)
    (firmware (list linux-firmware))
    (initrd microcode-initrd)
    (bootloader %guixos-bootloader)
    (swap-devices swap-devices)
    (file-systems file-systems)
    (groups %guixos-groups)
    (users (%guixos-users user comment))
    (packages (append %guixos-base-packages extra-packages))
    (services (append %guixos-base-services extra-services))
    ;; Allow resolution of '.local' host names with mDNS.
    (name-service-switch %mdns-host-lookup-nss)))
