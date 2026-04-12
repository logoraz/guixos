(define-module (config home services desktop-profile)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnome-xyz)
  #:use-module (gnu packages gnuzilla)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages libreoffice)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages video)
  #:use-module (gnu packages music)
  #:use-module (gnu packages games)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages password-utils)
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gnucash)
  #:use-module (gnu packages gimp)
  #:use-module (gnu packages inkscape)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages node)
  #:use-module (gnu home services)
  #:export (home-desktop-profile-service-type))


;;; Package Transformations
(define (home-desktop-profile-service config)
  (list
   ;; XDG Utilities
   flatpak
   fontconfig
   xdg-desktop-portal
   xdg-desktop-portal-gtk
   xdg-utils ;; For xdg-open, etc
   xdg-dbus-proxy
   shared-mime-info
   (list glib "bin")

   ;; Fonts (xtras)
   font-jetbrains-mono
   font-liberation
   font-awesome

   ;; Browser Utilities
   enchant
   node

   ;; Authentication
   gnupg
   password-store ;; keepassxc -> password-store

   ;; Audio devices & Media playback
   mpv
   mpv-mpris
   yt-dlp
   playerctl
   steam-devices-udev-rules

   ;; Applications
   gnucash
   gimp-3
   inkscape
   blender
   libreoffice
   gnome-tweaks

   ;; Lisp
   sbcl
   sbcl-slynk

   ;; Utilities
   foot

   trash-cli))

(define home-desktop-profile-service-type
  (service-type (name 'home-desktop-profile)
                (description "Applies my personal GNOME desktop configuration.")
                (extensions
                 (list (service-extension
                        home-profile-service-type
                        home-desktop-profile-service)))
                (default-value #f)))
