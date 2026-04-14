(define-module (config home guixos-home)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu packages ssh)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services ssh)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services desktop)
  #:use-module (config home services environment)
  #:use-module (config home services config-files)
  #:use-module (config home services mutable-files)
  #:use-module (config home services desktop-profile)
  #:use-module (config home services xdg-desktop-entries)
  #:use-module (config home services nautilus-thumbnails)
  #:use-module (config home services bash)
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

       ;; SSH client configuration
       (service home-openssh-service-type
                (home-openssh-configuration
                  (add-keys-to-agent "yes")))

       ;; SSH agent for key management
       (service home-ssh-agent-service-type
                (home-ssh-agent-configuration
                  (openssh openssh-sans-x)))

       ;; config files configuration
       (service home-config-files-service-type)

       ;; Mutable symlinks configuration
       (service home-mutable-symlinks-service-type)

       ;; Desktop profile configuration
       (service home-desktop-profile-service-type)

       ;; Set environment variables for every session
       (service home-env-vars-configuration-service-type)

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

       ;; Allow Nautilus to show video thumbnails
       (service home-nautilus-thumbnails-service-type)

       ;; Bash configuration
       (bash-config->service))

      %base-home-services))))
