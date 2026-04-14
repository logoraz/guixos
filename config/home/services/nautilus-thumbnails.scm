(define-module (config home services nautilus-thumbnails)
  #:use-module (guix gexp)
  #:use-module (gnu packages video)
  #:use-module (gnu home services)
  #:use-module (gnu home services xdg)
  #:export (home-nautilus-thumbnails-service-type))

;;;
;;; Nautilus Video Thumbnails Service
;;;

(define %ffmpegthumbnailer-mime-types
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
        "video/x-theora+ogg"))

(define (home-nautilus-thumbnails-service config)
  `(("thumbnailers/ffmpegthumbnailer.thumbnailer"
     ,(computed-file
       "ffmpegthumbnailer.thumbnailer"
       #~(begin
           (define path
             (string-append #$ffmpegthumbnailer
                            "/bin/ffmpegthumbnailer"))
           (define mime-types
             (string-join '#$%ffmpegthumbnailer-mime-types ";"))
           (call-with-output-file #$output
             (lambda (port)
               (display
                (string-append
                 "[Thumbnailer Entry]\n"
                 "TryExec=" path "\n"
                 "Exec=" path " -i %i -o %o -s %s -f\n"
                 "MimeType=" mime-types "\n")
                port))))))))

(define home-nautilus-thumbnails-service-type
  (service-type
   (name 'home-nautilus-thumbnails)
   (description
    "Service for Nautilus video thumbnails via ffmpegthumbnailer.")
   (extensions
    (list (service-extension
           home-xdg-data-files-service-type
           home-nautilus-thumbnails-service)))
   (default-value #f)))
