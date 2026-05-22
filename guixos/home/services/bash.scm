(define-module (guixos home services bash)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (guixos lib utils)
  #:use-module (guixos system identity)
  #:export (bash-config->service))

;;;
;;; Build-Time Assets
;;;
;; TODO: Add dot-bashrc and dot-bash_profile configs here using gexp's

(define %gosr (string-append "sudo guix system -L "
                             (config-source) " "
                             "reconfigure "
                             (guixos-system-config)))

(define %gohr (string-append "guix home -L "
                             (config-source) " "
                             "reconfigure "
                             (guixos-home-config)))

(define %gop (string-append "guix pull -L "
                            (config-source)))

(define %gostm (string-append "sudo guix time-machine -- "
                              "system -L " (config-source) " "
                              "reconfigure --allow-downgrades "
                              (guixos-system-config)))

(define %gohtm (string-append "guix time-machine -- "
                              "home -L " (config-source) " "
                              "reconfigure --allow-downgrades "
                              (guixos-home-config)))

(define* (bash-config->service #:key
                               (test #f))
  (service home-bash-service-type
           (home-bash-configuration
             (guix-defaults? #f)
             (aliases
              `(("grep"  . "grep --color=auto")
                ("ls"    . "ls -p --color=auto")
                ("ll"    . "ls -l")
                ("la"    . "ls -la")
                ("gosr"  . ,%gosr)
                ("gohr"  . ,%gohr)
                ("gop"   . ,%gop)
                ("gostm" . ,%gostm)
                ("gohtm" . ,%gohtm)))
             (bashrc
              `(,(resolve (config-source) "files/bash"
                          #:file "dot-bashrc.sh")))
             (bash-profile
              `(,(resolve (config-source) "files/bash"
                          #:file "dot-bash_profile.sh"))))))
