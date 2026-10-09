(define-module (guixos home guixos-home)
  #:use-module (gnu)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages ssh)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services pm)
  #:use-module (gnu home services ssh)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services desktop)
  #:use-module (guix gexp)
  #:use-module (guixos system identity)
  #:use-module (guixos home services environment)
  #:use-module (guixos home services config-files)
  #:use-module (guixos home services mutable-files)
  #:use-module (guixos home services streaming)
  #:use-module (guixos home services udiskie)
  #:use-module (guixos home services desktop-profile)
  #:use-module (guixos home services desktop-utilities)
  #:use-module (guixos home services xdg-desktop-entries)
  #:use-module (guixos home services bash)
  #:use-module (guixos home window-manager sway)
  #:use-module (guixos home window-manager mahogany)
  #:export (guixos-home))


(define %guixos-home-base-services
  (list
   ;; Enable bluetooth connections to be handled properly
   ;; bluetooth service only currently available at system level.
   (service home-dbus-service-type)

   ;; Enable pipewire audio
   (service home-pipewire-service-type)

   ;; Setup SSH for home
   (service home-openssh-service-type
            (home-openssh-configuration
              (add-keys-to-agent "yes")))

   (service home-ssh-agent-service-type
            (home-ssh-agent-configuration
              (openssh openssh-sans-x)))

   ;; Monitor battery levels
   (service home-batsignal-service-type)

   ;; Udiskie for auto-mounting
   (service home-udiskie-service-type)

   ;; Streaming profile service
   (service home-streaming-service-type)

   ;; config files configuration
   (service home-config-files-service-type)

   ;; Mutable symlinks configuration
   (service home-mutable-symlinks-service-type)

   ;; Desktop profile packages
   (service home-desktop-profile-service-type)

   ;; WM-independent utilities: foot, mako, fuzzel
   (service home-desktop-utilities-service-type)

   ;; Set environment variables for every session
   (service home-env-vars-configuration-service-type)

   ;; Remove undesired desktop entries
   (service home-xdg-desktop-entries-service-type
            (list
             (xdg-desktop-entry
               "emacsclient"
               "Emacs (Client)"
               #:exec "emacsclient --alternate-editor= --create-frame %F"
               #:no-display? #t)
             (xdg-desktop-entry
               "footclient"
               "Foot Client"
               #:exec "footclient"
               #:no-display? #t)
             (xdg-desktop-entry
               "foot-server"
               "Foot Server"
               #:exec "foot --server"
               #:no-display? #t)))

   ;; Bash configuration
   (bash-config->service)))

(define (window-manager-services)
  "Return the home services for the window manager in (%window-manager)."
  (case (%window-manager)
    ((sway) (sway-home-services))
    (else (error "Unsupported window manager:" (%window-manager)))))

(define* (guixos-home #:key (window-manager (%window-manager)))
  "Return the GuixOS home-environment for the WINDOW-MANAGER in (%window-manager)."
  (%window-manager window-manager)
  (home-environment
    (services
     (append
      %guixos-home-base-services
      (window-manager-services)
      %base-home-services))))
