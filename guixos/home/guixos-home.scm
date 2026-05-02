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
  #:use-module (gnu home services sway)
  #:use-module (guix gexp)
  #:use-module (guixos home services environment)
  #:use-module (guixos home services config-files)
  #:use-module (guixos home services mutable-files)
  #:use-module (guixos home services streaming)
  #:use-module (guixos home services udiskie)
  #:use-module (guixos home services desktop-profile)
  #:use-module (guixos home services xdg-desktop-entries)
  #:use-module (guixos home services bash)
  #:use-module (guixos home services sway)
  #:export (guixos-home))


(define guixos-home
  (home-environment
   (services
    (append
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

      ;; Sway Desktop profile configuration
      (service home-desktop-profile-service-type)

      ;; Set environment variables for every session
      (service home-env-vars-configuration-service-type)

      ;; Sway Configuration + package profile
      ;; Intantiate sway service with empty configuration
      (service home-sway-service-type %empty-sway-configuration)
      ;; extend with our custom configuration
      (service home-sway-configuration-service-type)

      ;; Remove undesired desktop entries
      (service home-xdg-desktop-entries-service-type
               (list
                (xdg-desktop-entry "emacsclient"
                                   "Emacs (Client)"
                                   #:no-display? #t)
                (xdg-desktop-entry "footclient"
                                   "Foot Client"
                                   #:no-display? #t)
                (xdg-desktop-entry "foot-server"
                                   "Foot Server"
                                   #:no-display? #t)))

      ;; Bash configuration
      (bash-config->service))

     %base-home-services))))

guixos-home
