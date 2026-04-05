(define-module (config home guixos-home)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages video)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services ssh)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services desktop)
  #:use-module (config home services environment)
  #:use-module (config home services config-files)
  #:use-module (config home services mutable-files)
  #:use-module (config home services desktop-profile)
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

       ;; Setup SSH for home
       (service home-openssh-service-type
                (home-openssh-configuration
                  (add-keys-to-agent "yes")))

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

       ;; Allow Nautilus to show video thumbnails
       (simple-service
        'ffmpegthumbnailer-thumbnailer
        home-xdg-data-files-service-type
        `(("thumbnailers/ffmpegthumbnailer.thumbnailer"
           ,(computed-file
             "ffmpegthumbnailer.thumbnailer"
             #~(begin
                 (define path
                   (string-append #$ffmpegthumbnailer
                                  "/bin/ffmpegthumbnailer"))
                 (define mime-types
                   (string-join
                    (list "video/jpeg"
                          "video/mp4"
                          "video/mpeg"
                          "video/quicktime"
                          "video/x-ms-asf"
                          "video/x-ms-wm"
                          "video/x-ms-wmv"
                          "video/x-ms-asx"
                          "video/x-ms-wmx"
                          "video/x-msvideo"
                          "video/x-flv"
                          "video/x-matroska"
                          "application/mxf"
                          "video/3gp"
                          "video/3gpp"
                          "video/dv"
                          "video/divx"
                          "video/fli"
                          "video/flv"
                          "video/mp2t"
                          "video/mp4v-es"
                          "video/msvideo"
                          "video/ogg"
                          "video/vivo"
                          "video/vnd.divx"
                          "video/vnd.mpegurl"
                          "video/vnd.rn-realvideo"
                          "application/vnd.rn-realmedia"
                          "video/vnd.vivo"
                          "video/webm"
                          "video/x-anim"
                          "video/x-avi"
                          "video/x-flc"
                          "video/x-fli"
                          "video/x-flic"
                          "video/x-m4v"
                          "video/x-mpeg"
                          "video/x-mpeg2"
                          "video/x-nsv"
                          "video/x-ogm+ogg"
                          "video/x-theora+ogg")
                    ";"))
                 (call-with-output-file #$output
                   (lambda (port)
                     (display
                      (string-append
                       "[Thumbnailer Entry]\n"
                       "TryExec=" path "\n"
                       "Exec=" path " -i %i -o %o -s %s -f\n"
                       "MimeType=" mime-types "\n")
                      port))))))))

       ;; Bash configuration
       (bash-config->service))

      %base-home-services))))
