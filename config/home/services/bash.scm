(define-module (config home services bash)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (config lib utils)
  #:use-module (config system identity)
  #:export (bash-config->service))


(define %gosr (string-append "sudo guix system -L "
                             "~/.config/guixos/ "
                             "reconfigure "
                             "~/.config/guixos/config/guixos.scm"))

(define %gohr (string-append "guix home -L "
                             "~/.config/guixos/ "
                             "reconfigure "
                             "~/.config/guixos/config/home/guixos-home.scm"))

(define %gop (string-append "guix pull -L "
                            "~/.config/guixos/"))

(define* (bash-config->service #:key
                               (test #f))
  (service home-bash-service-type
           (home-bash-configuration
             (guix-defaults? #f)
             (aliases
              `(("grep" . "grep --color=auto")
                ("ls"   . "ls -p --color=auto")
                ("ll"   . "ls -l")
                ("la"   . "ls -la")
                ("gosr" . ,%gosr)
                ("gohr" . ,%gohr)
                ("gop"  . ,%gop)))
             (bashrc
              `(,(resolve (home-source) "files/bash"
                          #:file "dot-bashrc.sh")))
             (bash-profile
              `(,(resolve (home-source) "files/bash"
                          #:file "dot-bash_profile.sh"))))))
