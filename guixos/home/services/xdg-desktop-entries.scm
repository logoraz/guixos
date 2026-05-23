(define-module (guixos home services xdg-desktop-entries)
  #:use-module (srfi srfi-9)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu home services xdg)
  #:export (xdg-desktop-entry
            xdg-desktop-entry?
            xdg-desktop-entry-file-name
            xdg-desktop-entry-name
            xdg-desktop-entry-type
            xdg-desktop-entry-no-display?
            home-xdg-desktop-entries-service-type))

;;;
;;; XDG Desktop Entry Service
;;;

(define-record-type <xdg-desktop-entry>
  (make-xdg-desktop-entry file-name name type no-display?)
  xdg-desktop-entry?
  (file-name    xdg-desktop-entry-file-name)
  (name         xdg-desktop-entry-name)
  (type         xdg-desktop-entry-type)
  (no-display?  xdg-desktop-entry-no-display?))

(define* (xdg-desktop-entry file-name name
                             #:key
                             (type "Application")
                             (no-display? #f))
  (make-xdg-desktop-entry file-name name type no-display?))

(define (xdg-desktop-entry->file entry)
  (let ((file-name (xdg-desktop-entry-file-name entry))
        (name      (xdg-desktop-entry-name entry))
        (type      (xdg-desktop-entry-type entry))
        (hidden?   (xdg-desktop-entry-no-display? entry)))
    `(,(string-append "applications/" file-name ".desktop")
      ,(mixed-text-file
        (string-append file-name ".desktop")
        "[Desktop Entry]\n"
        "Type=" type "\n"
        "Name=" name "\n"
        (if hidden? "NoDisplay=true\n" "")))))

(define (home-xdg-desktop-entries-service entries)
  (map xdg-desktop-entry->file entries))

(define home-xdg-desktop-entries-service-type
  (service-type
   (name 'home-xdg-desktop-entries)
   (description "Service for managing XDG desktop entries.")
   (extensions
    (list (service-extension
           home-xdg-data-files-service-type
           home-xdg-desktop-entries-service)))
   (default-value '())))
