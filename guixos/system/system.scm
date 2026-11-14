(define-module (guixos system system)
  ;; Guile Modules
  #:use-module (ice-9 match)

  ;; Core Guix DSL & utilities
  #:use-module (gnu)
  #:use-module (gnu packages)
  #:use-module (guix gexp)

  ;; System primitives
  #:use-module (gnu system keyboard)
  #:use-module (gnu system nss)
  #:use-module (gnu system privilege)

  ;; Lisp Dev Stack
  #:use-module (guixos packages egcl)
  #:use-module (guixos packages clasp)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)


  ;; WM, Login & Terminal
  #:use-module (gnu packages window-management) ;; sway, swaylock-effects
  #:use-module (gnu packages terminals)         ;; foot

  ;; Fonts & Themes
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages gnome)             ;; librsvg & themes
  #:use-module (gnu packages gnome-xyz)         ;; bibata-cursor

  ;; Hardware runtimes (audio, bluetooth, brightness, sensors)
  #:use-module (gnu packages linux)

  ;; Filesystem & firmware
  #:use-module (gnu packages disk)             ;; dosfstools
  #:use-module (gnu packages file-systems)     ;; btrfs-progs
  #:use-module (gnu packages polkit)
  #:use-module (nongnu packages firmware)      ;; fwupd-nonfree, linux-firmware
  #:use-module (nongnu packages linux)         ;; linux (kernel)
  #:use-module (nongnu system linux-initrd)    ;; microcode-initrd

  ;; Android / mobile device tooling
  #:use-module (gnu packages android)          ;; android-udev-rules

  ;; Printing
  #:use-module (gnu packages cups)             ;; cups-filters, hplip-minimal

  ;; Containers
  #:use-module (gnu system accounts)
  #:use-module (gnu services containers)
  #:use-module (gnu packages containers)

  ;; CLI essentials
  #:use-module (gnu packages admin)            ;; tree
  #:use-module (gnu packages base)
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
  #:use-module (guixos services firmware)      ;; fwupd-service-type
  #:use-module (guixos services cloak)         ;; cloak greeter
  #:use-module (guixos system identity)        ;; %home-user & %window-manager
  #:use-module (guixos system substitutes)


  #:export (make-guixos-system)
  #:declarative? #f)


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
  (cons* (user-group (system? #t) (name "seat"))
         (user-group (system? #t) (name "adbusers"))
         %base-groups))

(define (guixos-users username comment)
  (cons* (user-account
          (name username)
          (comment comment)
          (home-directory (string-append "/home/" username))
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
                                  "adbusers" ;; fastboot/adb without root
                                  "cgroup")));; rootless podman delegation
         %base-user-accounts))


;;;
;;; System Services
;;;

;; doas.conf — available alongside sudo; actual switch lives in bash.scm's
;; %use-doas?
(define %doas-conf
  (plain-file "doas.conf" "permit persist :wheel\n"))

;;; Greetd Configuration
(define %greetd-backsplash
  (local-file "../../files/assets/wallpapers/guix-bottom-checkered-16-9.svg"))

(define %greetd-avatar
  (local-file "../../files/assets/graphics/gx-logoraz.svg"))

;;; Monitor layout of the greeter, as in the home sway configuration:
;;; the laptop sits between a left and a right monitor, whichever set
;;; of monitors (home or work) is plugged in.
(define (greetd-dpi-scale identifier)
  "Return the sway scale of the output known as IDENTIFIER, a symbol.
Mirrors dpi-scale of the home sway module; the laptop is 1.6 here."
  (case identifier
    ((eDP-1)    1.6)
    ((HDMI-A-1) 1.5)
    (else       1)))

(define %greetd-laptop "eDP-1")
(define %greetd-laptop-pixels 2880)  ; width of the laptop panel
(define %greetd-left-width 1920)     ; width of the left monitors

(define %greetd-monitors
  '(("Acer Technologies K243Y TN6AA0018513" acer left)
    ("VIZIO, Inc E32-C1 0x01010101" tv right)
    ("Dell Inc. DELL P2425HE 1C5FN84" dellM left)
    ("Dell Inc. DELL P2425H CNGJK94" dellS right)))

(define (greetd-output-lines)
  "Return the sway output lines of the greeter, as a list of strings.
The laptop sits between the left and right monitors; the right ones
start after the laptop, whose width follows from its scale."
  (let* ((scale (greetd-dpi-scale 'eDP-1))
         (laptop-x %greetd-left-width)
         (laptop-width (inexact->exact
                        (round (/ %greetd-laptop-pixels scale))))
         (right-x (+ laptop-x laptop-width)))
    (cons*
     "output * enable"
     (format #f "output ~a scale ~a position ~a 0"
             %greetd-laptop scale laptop-x)
     (map (match-lambda
            ((description role side)
             (format #f "output \"~a\" scale ~a position ~a 0"
                     description
                     (greetd-dpi-scale role)
                     (if (eq? side 'left) 0 right-x))))
          %greetd-monitors))))

(define %greetd-conf
  (mixed-text-file
   "sway-greetd.conf"
   "# sway greetd configuration file\n"
   ;; Configure Mouse & Scale
   "seat seat0 xcursor_theme Bibata-Modern-Classic 20\n"
   ;; Warp the pointer to the center of the focused output
   "mouse_warping output\n"
   ;; Output layout
   (string-join (greetd-output-lines) "\n" 'suffix)
   "\n"
   ;; Focus the laptop, so the pointer starts at its center
   "exec swaymsg focus output " %greetd-laptop "\n"
   ;; "# Background image (resolved at build time)\n"
   ;; "output eDP-1 bg " %greetd-backsplash " fill\n"
   ;; "\n"
   "input type:keyboard {\n"
   "  xkb_layout us\n"
   "  xkb_options ctrl:nocaps\n"
   "}\n"))

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

(define %mahogany-logged
  (program-file
   "mahogany-logged"
   #~(begin
       ;; TODO: replace with the real mahogany binary and log redirect,
       ;; mirroring %sway-logged.
       (execl "/path/to/mahogany" "mahogany"))))

(define (wm-session-command)
  "Return the program greetd runs after login for the current window manager."
  (case (%window-manager)
    ((sway) %sway-logged)
    ((mahogany) %mahogany-logged)
    (else (error "Unsupported window manager:" (%window-manager)))))

(define (wm-screen-locker-service)
  "Return the screen-locker service for the current window manager."
  (case (%window-manager)
    ((sway mahogany)
     (service screen-locker-service-type
              (screen-locker-configuration
                (name "swaylock")
                (program (file-append swaylock-effects "/bin/swaylock"))
                (using-pam? #t)
                (using-setuid? #f))))
    (else (error "Unsupported window manager:" (%window-manager)))))

(define (wm-packages)
  "Return the system packages specific to the current window manager."
  (case (%window-manager)
    ((sway) (list swaylock-effects))
    ((mahogany) '())
    (else (error "Unsupported window manager:" (%window-manager)))))

(define (guixos-base-services)
    "Return the system services shared by every host.
The screen locker and the greetd session command follow the window manager
in (%window-manager); the greeter itself is pinned to sway."
  (cons*
   (wm-screen-locker-service)

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

   ;; Log and state directories for cloak
   (service cloak-service-type)

   (service greetd-service-type
            (greetd-configuration
              (greeter-supplementary-groups '("video" "input" "seat" "users"))
              (terminals
               (list
                (greetd-terminal-configuration
                  (terminal-vt "1")
                  (terminal-switch #f)
                  (default-session-command
                    (greetd-cloak-sway-session
                     (sway sway)
                     (sway-configuration %greetd-conf)
                     (cloak-configuration
                      (cloak-configuration
                       (user (cloak-user
                              (name (%home-user))
                              (avatar %greetd-avatar)))
                       (theme (cloak-theme
                               (wallpaper (cloak-wallpaper
                                           (path %greetd-backsplash)
                                           (fit 'cover)))))
                       (layout (cloak-layout (primary "eDP-1")))
                       (session (cloak-session
                                 (command (wm-session-command)))))))))
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

   ;; Udev rules to bootstrap android phones
   (udev-rules-service 'android android-udev-rules)

   ;; Set doas configuration file
   (service special-files-service-type
            `(("/etc/doas.conf" ,%doas-conf)))

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
      (substitutes->services config)))))


;;;
;;; Package Categories
;;;

;;; Lisp Machine Tools
(define %guixos-lisp-stack
  (list sbcl
        clasp-cl-latest
        egcl
        cl-slynk
        emacs-pgtk
        guile-colorized
        ;; guile-ares-rs
        libffi))

;;; File system & firmware tools
(define %guixos-system-tools
  (list efibootmgr
        btrfs-progs
        dosfstools
        opendoas
        polkit
        fwupd-nonfree))

;;; WM & Login Manager — needed for greetd/wlgreet configuration
(define %guixos-greeter
  (list sway
        librsvg
        foot))

;;; Fonts
(define %guixos-fonts
  (list font-jetbrains-mono
        font-google-noto
        font-google-noto-emoji
        font-sarasa-gothic
        font-hack
        font-fira-code
        font-iosevka-aile
        font-liberation
        font-nerd-symbols
        font-inconsolata
        font-kawkab-mono))

;;; Themes
(define %guixos-themes
  (list adwaita-icon-theme
        gnome-themes-extra
        qogir-icon-theme
        bibata-cursor-theme))

;;; Hardware runtimes
(define %guixos-hardware-runtimes
  (list pipewire
        wireplumber
        bluez
        brightnessctl
        lm-sensors))

;;; Containers
(define %guixos-containers
  (list distrobox
        podman))

;;; CLI essentials
(define %guixos-cli
  (list openssh-sans-x
        git
        (list git "send-email")
        binutils
        curl
        wget
        zip
        unzip
        tree))

(define (guixos-base-packages)
  "Return the system packages shared by every host.
The greeter packages (sway, librsvg, foot) are always included; the
window-manager specific packages follow (%window-manager)."
  (append %guixos-lisp-stack
          %guixos-system-tools
          %guixos-greeter
          %guixos-fonts
          %guixos-themes
          %guixos-hardware-runtimes
          %guixos-containers
          %guixos-cli
          (wm-packages)
          %base-packages))


;;;
;;; Operating System Constructor
;;;

(define* (make-guixos-system #:key
                             host-name
                             user
                             comment
                             (window-manager 'sway)
                             file-systems
                             swap-devices
                             (kernel-arguments '())
                             (extra-packages '())
                             (extra-services '()))
  "Build a GuixOS operating-system record for a specific host.
HOST-NAME, FILE-SYSTEMS, and SWAP-DEVICES are required and must be
supplied by the host-specific configuration. EXTRA-PACKAGES and
EXTRA-SERVICES are optional escape hatches for host-specific additions."
  (%home-user user)
  (%window-manager window-manager)
  (operating-system
    (host-name host-name)
    (timezone "America/Chicago")
    (locale "en_US.utf8")
    (keyboard-layout %guixos-keyboard-layout)
    (kernel linux)
    (kernel-arguments (append kernel-arguments
                              %default-kernel-arguments))
    (firmware (list linux-firmware))
    (initrd microcode-initrd)
    (bootloader %guixos-bootloader)
    (swap-devices swap-devices)
    (file-systems file-systems)
    (groups %guixos-groups)
    (privileged-programs
     (cons (privileged-program
             (program (file-append opendoas "/bin/doas"))
             (setuid? #t))
           %default-privileged-programs))
    (users (guixos-users user comment))
    (packages (append (guixos-base-packages) extra-packages))
    (services (append (guixos-base-services) extra-services))
    ;; Allow resolution of '.local' host names with mDNS.
    (name-service-switch %mdns-host-lookup-nss)))
