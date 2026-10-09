(define-module (guixos home services desktop-utilities)
  #:use-module (guix gexp)
  #:use-module (gnu packages terminals)         ;; foot
  #:use-module (gnu packages window-management) ;; mako
  #:use-module (gnu packages xdisorg)           ;; fuzzel
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:export (kbd-backlight-cmd
            home-desktop-utilities-service-type))

;;;
;;; Desktop utilities that do not depend on the window manager:
;;; terminal (foot), notification daemon (mako), launcher (fuzzel).
;;;

;;;
;;; Application Configs
;;;

(define %foot-config
  (mixed-text-file
   "foot.ini"
   "# Base16 Monokai - foot color config\n"
   "font=Fira Code:size=10\n"
   "dpi-aware=no\n"
   "initial-window-size-chars=140x40 # Columns x Rows in Characters\n"
   "\n"
   "[bell]\n"
   "urgent=no\n"
   "notify=no\n"
   "visual=no\n"
   "\n"
   "[scrollback]\n"
   "lines=5000\n"
   "\n"
   "[csd]\n"
   "preferred=client\n" ; Use client-side decorations
   "color=2e3440\n"     ; Keep 5000 lines of history (default is 1000)
   "border-width=1\n"
   "border-color=81a1c1\n"
   "button-color=88c0d0\n"
   "\n"
   "[colors-dark]\n"
   "alpha=0.80\n"
   "background=383838\n" ; Nord Black Polar Night
   "foreground=eceff4\n")) ; Nord White Snow Storm

;; Notification daemon
(define %mako-config
  (mixed-text-file
   "config"
   "font=Hack 9\n"
   "text-color=#ffffff\n"
   "background-color=#1c1f26ee\n"
   "border-color=#89AAEBee\n"
   "border-size=1\n"
   "border-radius=4\n"
   "padding=5\n"
   "height=200\n"
   "width=300\n"
   "\n"
   "layer=overlay\n"
   "default-timeout=7000\n"
   "ignore-timeout=0\n"
   "icons=1\n"
   "anchor=top-right\n"
   "sort=+time\n"
   "\n"
   "max-visible=5\n"
   "\n"
   "[hidden]\n"
   "format=(and %h more)\n"
   "text-color=#777777\n"
   "\n"
   "[urgency=high]\n"
   "background-color=#c00000\n"
   "border-color=#ff0000\n"))

;; Application launcher
;; filter-desktop respects OnlyShowIn/NotShowIn keys against $XDG_CURRENT_DESKTOP
(define %fuzzel-config
  (mixed-text-file
   "fuzzel.ini"
   "[main]\n"
   "prompt=\"❯ \"\n"
   "icon-theme=Qogir-Dark\n"
   "font=JetBrains Mono:weight=bold:size=14\n"
   "dpi-aware=no\n"
   "width=50\n"
   "horizontal-pad=8\n"
   "vertical-pad=8\n"
   "filter-desktop=yes\n"
   "list-executables-in-path=no\n"
   "show-actions=no\n"
   "lines=12\n"
   "exit-on-keyboard-focus-loss=yes\n"
   "\n"
   "[colors]\n"
   "background=1d1f21dd\n"
   "border=5e81accc\n"
   "text=a6accdff\n"
   "match=c792eacc\n"
   "selection=a6accdff\n"
   "selection-text=232635ff\n"
   "\n"
   "[border]\n"
   "radius=25\n"
   "\n"
   "[dmenu]\n"
   "exit-immediately-if-empty=yes\n"))

;;;
;;; Helpers
;;;

(define* (kbd-backlight-cmd direction #:optional (step 10))
  "Generate a bindsym command for keyboard backlight adjustment.
DIRECTION is either \"-\" or \"+\", STEP is the percentage integer."
  (string-append
   "exec brightnessctl -d chromeos::kbd_backlight set "
   (number->string step) "%" direction
   " && notify-send 'Keyboard Backlight'"
   " \"$(brightnessctl -d chromeos::kbd_backlight"
   " -m | cut -d, -f4)\""))

;;;
;;; Service Composition
;;;

(define %desktop-utilities-packages
  (list foot     ;; terminal
        mako     ;; notification daemon
        fuzzel)) ;; app launcher

(define (home-desktop-utilities-profile-service config)
  "Return the packages installed for the desktop utilities."
  %desktop-utilities-packages)

(define (home-desktop-utilities-files-service config)
  "Return the config file symlinks for the desktop utilities."
  `((".config/foot/foot.ini" ,%foot-config)
    (".config/mako/config" ,%mako-config)
    (".config/fuzzel/fuzzel.ini" ,%fuzzel-config)))

(define home-desktop-utilities-service-type
  (service-type
    (name 'home-desktop-utilities)
    (description "Window-manager independent desktop utilities and configs.")
    (extensions
     (list
      (service-extension
       home-profile-service-type
       home-desktop-utilities-profile-service)
      (service-extension
       home-files-service-type
       home-desktop-utilities-files-service)))
    (default-value #f)))
