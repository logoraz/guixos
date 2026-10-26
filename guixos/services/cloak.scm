;;; SPDX-License-Identifier: LGPL-2.1-only WITH LLGPL
;;; Copyright (C) 2026 Erik P Almaraz

(define-module (guixos services cloak)
  #:use-module (gnu packages wm)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guixos packages cloak)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (cloak-user
            cloak-wallpaper
            cloak-theme
            cloak-session
            cloak-layout
            cloak-clock
            cloak-commands
            cloak-configuration
            greetd-cloak-sway-session
            cloak-service-type))


;;; Cloak runs as the greetd greeter, and greetd-service-type cannot be
;;; extended, so the greeter is a session record like
;;; greetd-gtkgreet-sway-session.  Use it in a greetd terminal:
;;;
;;;   (service cloak-service-type)
;;;   (service greetd-service-type
;;;            (greetd-configuration
;;;             (terminals
;;;              (list
;;;               (greetd-terminal-configuration
;;;                (terminal-vt "1")
;;;                (default-session-command
;;;                 (greetd-cloak-sway-session
;;;                  (sway-configuration %greetd-conf)
;;;                  (cloak-configuration
;;;                   (cloak-configuration
;;;                    (greeting "Welcome")
;;;                    (theme (cloak-theme (alpha 0.9))))))))))))
;;;
;;; A field left at #f is left out of cloak.sexp, so the greeter keeps its
;;; own default for it.


;;;
;;; Configuration
;;;

(define (maybe-string? x) (or (not x) (string? x)))
(define (maybe-number? x) (or (not x) (number? x)))
(define (maybe-symbol? x) (or (not x) (symbol? x)))
(define (maybe-file? x) (or (not x) (string? x) (file-like? x)))
(define (maybe-command? x) (or (not x) (and (list? x) (every string? x))))
(define (maybe-program? x)
  (or (maybe-command? x) (file-like? x)))

(define-configuration/no-serialization cloak-user
  (name (maybe-string #f) "The user selected first, as :user :name.")
  (avatar (maybe-file #f) "Picture shown for the user."))

(define-configuration/no-serialization cloak-wallpaper
  (path (maybe-file #f) "Wallpaper image.")
  (fit (maybe-symbol #f) "One of cover, contain or fill."))

(define-configuration/no-serialization cloak-theme
  (background (maybe-string #f) "Panel color, such as \"#2e3440\".")
  (foreground (maybe-string #f) "Text color.")
  (border (maybe-string #f) "Border color.")
  (alpha (maybe-number #f) "Panel opacity from 0 to 1.")
  (css (maybe-file #f) "Extra CSS file.")
  (cursor (maybe-string #f) "Cursor theme name.")
  (font (maybe-string #f) "Font family.")
  (wallpaper (cloak-wallpaper (cloak-wallpaper)) "Wallpaper settings."))

(define-configuration/no-serialization cloak-session
  (name (maybe-string #f) "Session preselected, as :session :default.")
  (command (maybe-program #f)
           "Command to start after every login, instead of the command of
the session picked in the menu.  Either a list of strings or a file-like
program, such as a program-file.  The session menu is hidden when it is
set."))

(define-configuration/no-serialization cloak-layout
  (position (maybe-symbol #f) "One of center, left or right.")
  (primary (maybe-string #f) "Output that shows the login form."))

(define-configuration/no-serialization cloak-clock
  (time-format (maybe-string #f) "Clock format, as :clock :format.")
  (color (maybe-string #f) "Clock color, such as \"#81a1c1\".")
  (size (maybe-string #f) "Clock font size, such as \"48px\"."))

(define-configuration/no-serialization cloak-commands
  (reboot (maybe-command #f) "Command list that reboots.")
  (poweroff (maybe-command #f) "Command list that powers off."))

(define-configuration/no-serialization cloak-configuration
  (user (cloak-user (cloak-user)) "User settings.")
  (theme (cloak-theme (cloak-theme)) "Theme settings.")
  (session (cloak-session (cloak-session)) "Session settings.")
  (layout (cloak-layout (cloak-layout)) "Layout settings.")
  (clock (cloak-clock (cloak-clock)) "Clock settings.")
  (greeting (maybe-string #f) "Greeting text.")
  (commands (cloak-commands (cloak-commands)) "Power commands."))


;;;
;;; Writing cloak.sexp
;;;
;;; Each procedure below returns a list of strings and file-like objects,
;;; ready for mixed-text-file.

(define (lisp-string str)
  "Return STR as a Lisp string literal."
  (string-append
   "\""
   (list->string
    (append-map (lambda (char)
                  (if (memv char '(#\" #\\))
                      (list #\\ char)
                      (list char)))
                (string->list str)))
   "\""))

(define (entry key value)
  "Return the pieces of ' :KEY VALUE', or no pieces if VALUE is #f."
  (match value
    (#f '())
    ((? string?)
     (list (string-append " :" key " " (lisp-string value))))
    ((? number?)
     (list (string-append " :" key " " (number->string value))))
    ((? symbol?)
     (list (string-append " :" key " :" (symbol->string value))))
    (((? string?) ...)
     (list (string-append " :" key " ("
                          (string-join (map lisp-string value) " ")
                          ")")))
    ((? file-like?)
     (list (string-append " :" key " \"") value "\""))))

(define (command-entry key value)
  "Return the pieces of ' :KEY (COMMAND)'.  VALUE is #f, a list of strings,
or a file-like program, which becomes the one string of its store path."
  (match value
    (#f '())
    ((? file-like?)
     (list (string-append " :" key " (\"") value "\")"))
    (_ (entry key value))))

(define (group key . entries)
  "Return the pieces of ' :KEY (ENTRIES)', or no pieces if ENTRIES is empty."
  (let ((body (append-map identity entries)))
    (if (null? body)
        '()
        (append (list (string-append " :" key " (")) body (list ")")))))

(define (cloak-configuration->pieces config)
  "Return the pieces of the cloak.sexp text for CONFIG."
  (let ((user (cloak-configuration-user config))
        (theme (cloak-configuration-theme config))
        (session (cloak-configuration-session config))
        (layout (cloak-configuration-layout config))
        (clock (cloak-configuration-clock config))
        (commands (cloak-configuration-commands config)))
    (let ((wallpaper (cloak-theme-wallpaper theme)))
      (append
       '("(")
       (group "user"
              (entry "name" (cloak-user-name user))
              (entry "avatar" (cloak-user-avatar user)))
       (group "theme"
              (entry "background" (cloak-theme-background theme))
              (entry "foreground" (cloak-theme-foreground theme))
              (entry "border" (cloak-theme-border theme))
              (entry "alpha" (cloak-theme-alpha theme))
              (entry "css" (cloak-theme-css theme))
              (entry "cursor" (cloak-theme-cursor theme))
              (entry "font" (cloak-theme-font theme))
              (group "wallpaper"
                     (entry "path" (cloak-wallpaper-path wallpaper))
                     (entry "fit" (cloak-wallpaper-fit wallpaper))))
       (group "session"
              (entry "default" (cloak-session-name session))
              (command-entry "command" (cloak-session-command session)))
       (group "layout"
              (entry "position" (cloak-layout-position layout))
              (entry "primary" (cloak-layout-primary layout)))
       (group "clock"
              (entry "format" (cloak-clock-time-format clock))
              (entry "color" (cloak-clock-color clock))
              (entry "size" (cloak-clock-size clock)))
       (entry "greeting" (cloak-configuration-greeting config))
       (group "commands"
              (entry "reboot" (cloak-commands-reboot commands))
              (entry "poweroff" (cloak-commands-poweroff commands)))
       '(")\n")))))

(define (cloak-config-file config)
  "Return the cloak.sexp file for CONFIG."
  (apply mixed-text-file "cloak.sexp" (cloak-configuration->pieces config)))


;;;
;;; Greeter session
;;;

(define-record-type* <greetd-cloak-sway-session>
  greetd-cloak-sway-session make-greetd-cloak-sway-session
  greetd-cloak-sway-session?
  (sway greetd-cloak-sway-session-sway
        (default sway))
  (sway-configuration greetd-cloak-sway-session-sway-configuration
                      (default #f))
  (cloak greetd-cloak-sway-session-cloak
         (default cloak))
  (cloak-configuration greetd-cloak-sway-session-cloak-configuration
                       (default (cloak-configuration)))
  (style greetd-cloak-sway-session-style
         (default #f)))

(define (make-cloak-sway-config session)
  "Return the sway configuration that runs cloak, then exits sway."
  (match-record session <greetd-cloak-sway-session>
                (sway sway-configuration cloak cloak-configuration style)
    (mixed-text-file
     "cloak-sway-config"
     (if sway-configuration
         #~(string-append "include " #$sway-configuration "\n")
         "")
     "xwayland disable\n"
     "exec \"" (file-append cloak "/bin/cloak")
     " --config " (cloak-config-file cloak-configuration)
     (if style #~(string-append " --style " #$style) "")
     "; " (file-append sway "/bin/swaymsg") " exit\"\n")))

(define (make-cloak-greeter-command session)
  "Return the program greetd runs: sway with the cloak configuration, using
a scratch home directory, since the greeter account has none.  This follows
make-greetd-sway-greeter-command of (gnu services base), which is private,
and also sets XDG_DATA_DIRS so that cloak finds the installed sessions."
  (let ((sway-bin (file-append (greetd-cloak-sway-session-sway session)
                               "/bin/sway"))
        (sway-config (make-cloak-sway-config session)))
    (program-file
     "greeter-cloak-command"
     (with-imported-modules '((guix build utils))
       #~(begin
           (use-modules (guix build utils))

           (let* ((username (getenv "USER"))
                  (user (getpwnam username))
                  (useruid (passwd:uid user))
                  (usergid (passwd:gid user))
                  (user-home-dir "/tmp/.greeter-home")
                  (user-xdg-runtime-dir (string-append user-home-dir "/run"))
                  (user-xdg-cache-dir (string-append user-home-dir "/cache"))
                  (log-file "/var/log/cloak/sway.log")
                  ;; (log-file (string-append user-home-dir "/"
                  ;;                          (number->string (getpid))
                  ;;                          ".log"))
                  )
             (for-each (lambda (dir)
                         (mkdir-p dir)
                         (chown dir useruid usergid)
                         (chmod dir #o700))
                       (list user-home-dir
                             user-xdg-runtime-dir
                             user-xdg-cache-dir))
             (setenv "HOME" user-home-dir)
             (setenv "XDG_CACHE_DIR" user-xdg-cache-dir)
             (setenv "XDG_RUNTIME_DIR" user-xdg-runtime-dir)
             (setenv "XDG_DATA_DIRS" "/run/current-system/profile/share")
             (dup2 (open-fdes log-file
                              (logior O_CREAT O_WRONLY O_APPEND) #o640)
                   1)
             (dup2 1 2)
             (execl #$sway-bin #$sway-bin "-d" "-c" #$sway-config)))))))

(define-gexp-compiler (greetd-cloak-sway-session-compiler
                       (session <greetd-cloak-sway-session>)
                       system target)
  (lower-object (make-cloak-greeter-command session)))


;;;
;;; Service
;;;

(define (cloak-activation greeter-user)
  "Create the log and state directories of cloak, owned by GREETER-USER."
  (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils))
        (let* ((user (getpwnam #$greeter-user))
               (uid (passwd:uid user))
               (gid (passwd:gid user)))
          (for-each (lambda (dir)
                      (mkdir-p dir)
                      (chown dir uid gid)
                      (chmod dir #o750))
                    '("/var/log/cloak" "/var/lib/cloak"))))))

(define cloak-service-type
  (service-type
   (name 'cloak)
   (description
    "Create the log and state directories that the cloak greeter writes to.
The value is the name of the greeter account, \"greeter\" by default.")
   (extensions
    (list (service-extension activation-service-type cloak-activation)))
   (default-value "greeter")))
