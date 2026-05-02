(define-module (config home services desktop-profile)
  ;; Guix DSL
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu home services)

  ;; Flatpak, XDG plumbing & cross-toolkit compatibility
  #:use-module (gnu packages package-management)   ;; flatpak
  #:use-module (gnu packages fontutils)            ;; fontconfig
  #:use-module (gnu packages freedesktop)          ;; xdg-*
  #:use-module (gnu packages glib)
  #:use-module (gnu packages xorg)                 ;; xorg-server-xwayland

  ;; Themes & icons
  #:use-module (gnu packages gnome)                ;; adwaita, gnome extra, gvfs
  #:use-module (gnu packages gnome-xyz)            ;; qogir, papirus, matcha
  #:use-module (gnu packages kde-frameworks)       ;; breeze-icons

  ;; Web & toolkit support
  #:use-module (gnu packages qt)                   ;; qtwayland
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages speech)               ;; speech-dispatcher
  #:use-module (gnu packages node)

  ;; Authentication
  #:use-module (gnu packages gnupg)                ;; gnupg, pinentry
  #:use-module (gnu packages password-utils)       ;; keepassxc, password-store

  ;; Media codecs + playback
  #:use-module (gnu packages gstreamer)            ;; gstreamer + plugins
  #:use-module (gnu packages video)                ;; ffmpeg*, mpv*, yt-dlp
  #:use-module (gnu packages music)                ;; playerctl
  #:use-module (gnu packages pulseaudio)           ;; pavucontrol
  #:use-module (gnu packages games)                ;; steam-devices-udev-rules

  ;; Document Tools & Viewers
  #:use-module (gnu packages pdf)                  ;; zathura*,mupdf,poppler
  #:use-module (gnu packages haskell-xyz)          ;; pandoc
  #:use-module (gnu packages image-viewers)        ;; imv
  #:use-module (gnu packages ocr)                  ;; tesseract-ocr
  #:use-module (gnu packages libreoffice)

  ;; Applications
  #:use-module (gnu packages gnucash)
  #:use-module (gnu packages gimp)
  #:use-module (gnu packages inkscape)
  #:use-module (gnu packages graphics)             ;; blender


  ;; Hardware & extra utilities
  #:use-module (gnu packages tls)                  ;; openssl, aws-lc
  #:use-module (gnu packages xdisorg)              ;; wev
  #:use-module (gnu packages linux)                ;; alsa-*, tlp
  #:use-module (gnu packages networking)           ;; nm applet, blueman
  #:use-module (gnu packages shellutils)           ;; trash-cli, udiskie

  #:export (home-desktop-profile-service-type))


;;;
;;; Home Desktop Profile Packages
;;;

;; Flatpak, XDG plumbing & cross-toolkit compatibility
(define %flatpak+xdg
  (list flatpak
        fontconfig
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
        xdg-utils ;; For xdg-open, etc
        xdg-dbus-proxy
        shared-mime-info
        (list glib "bin")
        ;; Compatibility for older Xorg applications
        xorg-server-xwayland))

;; Icon & GTK themes
(define %appearance
  (list qogir-icon-theme
        papirus-icon-theme
        adwaita-icon-theme
        breeze-icons ;; for KDE apps
        matcha-theme
        gnome-themes-extra))

(define %web-utils
  (list qtwayland
        enchant
        speech-dispatcher
        node))

(define %authentication
  (list gnupg
        pinentry
        keepassxc    ;; move to password-store eventually (?)
        password-store))

;; Media codec stack
(define %media-codecs+playback
  (list gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
        ffmpeg
        ffmpegthumbnailer
        mpv
        mpv-mpris
        yt-dlp
        playerctl
        pavucontrol
        steam-devices-udev-rules))

;; Document Tools/Viewers
(define %documents
  (list libreoffice
        mupdf
        poppler
        pandoc
        imv
        tesseract-ocr))

(define %applications
  (list gnucash
        gimp-3
        inkscape
        blender))

(define %xtra-utilities
  (list openssl
        aws-lc
        wev
        alsa-lib
        alsa-utils
        alsa-plugins
        tlp ;; --> alternate for bluetooth & wifi controls
        blueman
        network-manager-applet
        udiskie
        trash-cli))

(define (home-desktop-profile-service config)
  (append %flatpak+xdg
          %appearance
          %web-utils
          %authentication
          %media-codecs+playback
          %documents
          %applications
          %xtra-utilities))

(define home-desktop-profile-service-type
  (service-type (name 'home-sway-desktop-config)
                (description "Applies my personal Sway desktop configuration.")
                (extensions
                 (list (service-extension
                        home-profile-service-type
                        home-desktop-profile-service)))
                (default-value #f)))
