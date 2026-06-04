(define-module (guixos home services bash)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (guixos lib utils)
  #:use-module (guixos system identity)
  #:export (bash-config->service))


;;;
;;; Bash Prompt Data
;;;
(define %ps1-user "\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]")
(define %ps1-path "\\[\\033[01;34m\\]\\w\\[\\033[00m\\]")

(define %ps1-env
  (string-append "PS1='" %ps1-user ":" %ps1-path " [env]\\$ '"))

(define %ps1-default
  (string-append "PS1='" %ps1-user ":" %ps1-path "\\$ '"))

;;;
;;; Build-Time Assets
;;;
(define %dot-bash-profile
  (mixed-text-file
   "dot-bash_profile.sh"
   "# Add ~/.guix-profile if it exists\n"
   "if [ -L \"$HOME/.guix-profile\" ]; then\n"
   "    GUIX_PROFILE=\"$HOME/.guix-profile\"\n"
   "    . \"$GUIX_PROFILE/etc/profile\"\n"
   "fi\n"))

(define %dot-bashrc
  (mixed-text-file
   "dot-bashrc.sh"
   "# Bash initialization for interactive non-login shells and\n"
   "# for remote shells (info \"(bash) Bash Startup Files\").\n"
   "\n"
   "# Export 'SHELL' to child processes.  Programs such as 'screen'\n"
   "# honor it and otherwise use /bin/sh.\n"
   "export SHELL\n"
   "\n"
   "if [[ $- != *i* ]]\n"
   "then\n"
   "    # We are being invoked from a non-interactive shell.  If this\n"
   "    # is an SSH session (as in \"ssh host command\"), source\n"
   "    # /etc/profile so we get PATH and other essential variables.\n"
   "    [[ -n \"$SSH_CLIENT\" ]] && source /etc/profile\n"
   "\n"
   "    # Don't do anything else.\n"
   "    return\n"
   "fi\n"
   "\n"
   "# Source the system-wide file.\n"
   "if [[ -e /etc/bashrc ]]; then\n"
   "    source /etc/bashrc\n"
   "fi\n"
   "\n"
   "# Adjust the prompt depending on whether we're in 'guix environment'.\n"
   "# Custom prompt with color\n"
   "if [[ -n \"$GUIX_ENVIRONMENT\" ]]\n"
   "then\n"
   "    " %ps1-env "\n"
   "else\n"
   "    " %ps1-default "\n"
   "fi\n"
   "\n"
   "# containers\n"
   "dbx() {\n"
   "    if [ -z \"$1\" ]; then\n"
   "        echo \"usage: dbx <container> [command...]\" >&2\n"
   "        return 1\n"
   "    fi\n"
   "    local container=\"$1\"\n"
   "    shift\n"
   "    TERM=xterm-256color distrobox enter \"$container\" \"$@\"\n"
   "}\n"))

;;;
;;; Aliases
;;;

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

;; Run mermaid-cli inside its distrobox container (create it once, see
;; the mermaid container notes).  Args after `mmdc' pass straight through.
(define %mmdc "distrobox enter mermaid -- mmdc")

;;;
;;; Service Composition
;;;
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
                ("mmdc"  . ,%mmdc)
                ("gohtm" . ,%gohtm)
                ("gostm" . ,%gostm)
                ("gop"   . ,%gop)
                ("gohr"  . ,%gohr)
                ("gosr"  . ,%gosr)))
             (bashrc (list %dot-bashrc))
             (bash-profile (list %dot-bash-profile)))))
