(define-module (guixos home services sway)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages web)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services sway)
  #:use-module (guixos lib utils)
  #:use-module (guixos system identity)
  #:use-module (guixos home services impure-symlinks)
  ;; #:use-module (guixos packages gubar)
  #:export (sway-configuration-extension
            home-sway-configuration-service-type))

;;;
;;; Build-Time Assets
;;;
(define %bg-path
  (local-file "../../../files/assets/wallpapers/guix-checkered-16-9.svg"))

(define %swaylock-cmd
  (file-append swaylock-effects "/bin/swaylock"))

(define %sway-session-end
  (program-file
   "sway-session-end"
   #~(let* ((args (command-line))
            (action (if (> (length args) 1) (cadr args) "exit"))
            (final-cmd
             (cond
              ((string=? action "exit")
               (string-append #$(file-append sway "/bin/swaymsg") " exit"))
              ((string=? action "reboot")    "loginctl reboot")
              ((string=? action "poweroff")  "loginctl poweroff")
              ((string=? action "suspend")   "loginctl suspend")
              ((string=? action "hibernate") "loginctl hibernate")
              (else
               (string-append #$(file-append sway "/bin/swaymsg") " exit")))))
       (system* "/bin/sh" "-c"
                (string-append
                 "exec >>/tmp/sway-exit.log 2>&1; "
                 "echo \"--- " action " at $(date) ---\"; "
                 "pkill -TERM -x mako || true; "
                 "pkill -TERM -x blueman-applet || true; "
                 "pkill -TERM -x udiskie || true; "
                 "pkill -TERM -x wlsunset || true; "
                 "pkill -TERM -x swayidle || true; "
                 "sleep 0.25; "
                 final-cmd)))))

(define %wlogout-layout
  (mixed-text-file
   "wlogout-layout"
   "{ \"label\": \"lock\","
   " \"action\": \"" %swaylock-cmd
   " -f --screenshots --clock --effect-blur 9x7 --effect-vignette 0.25:0.5\","
   " \"text\": \"Lock\", \"keybind\": \"l\" }\n"
   "{ \"label\": \"logout\","
   " \"action\": \"" %sway-session-end " exit\","
   " \"text\": \"Logout\", \"keybind\": \"e\" }\n"
   "{ \"label\": \"reboot\","
   " \"action\": \"" %sway-session-end " reboot\","
   " \"text\": \"Reboot\", \"keybind\": \"r\" }\n"
   "{ \"label\": \"shutdown\","
   " \"action\": \"" %sway-session-end " poweroff\","
   " \"text\": \"Shutdown\", \"keybind\": \"s\" }\n"
   "{ \"label\": \"suspend\","
   " \"action\": \"" %sway-session-end " suspend\","
   " \"text\": \"Suspend\", \"keybind\": \"u\" }\n"
   "{ \"label\": \"hibernate\","
   " \"action\": \"" %sway-session-end " hibernate\","
   " \"text\": \"Hibernate\", \"keybind\": \"h\" }\n"))

(define %sway-new-workspace
  (program-file
   "sway-new-workspace"
   #~(system*
      "/bin/sh" "-c"
      (string-append
       "next=$(swaymsg -t get_workspaces | "
       #$(file-append jq "/bin/jq")
       " 'map(.num) | max + 1'); "
       "swaymsg workspace number $next"))))

;;;
;;; Sway Configuration Data
;;;
(define %text-scale "1")

(define (dpi-scale identifier)
  (case identifier
    ((eDP-1)    "1.75")
    ((HDMI-A-1) "1.5")
    (else       "1")))

(define workspace-list
  '((ws0 "0" "$laptop")
    (ws2 "2" "$laptop")
    (ws3 "3" "$laptop")
    (ws4 "4" "$acer $laptop")
    (ws5 "5" "$tv $laptop")
    (ws1 "1" "$laptop")))

(define %sway-config-base-variables
  `((mod . "Mod4") ;; Super key (note Super := Mod4, Alt := Mod1)
    (system_theme . "Adwaita-dark")
    (system_icons . "Qogir-dark")
    (system_font  . "Iosevka Aile 11")
    (cursor_theme . "Bibata-Modern-Classic")
    (cursor_size . "20")
    (titlebar_font . "Iosevka Aile")
    (titlebar_text_size . "11")
    (system_text_scaling_factor . ,%text-scale)

    (gnome_schema . "org.gnome.desktop.interface")
    (laptop  . "eDP-1")
    (acer    . "'Acer Technologies K243Y TN6AA0018513'")
    (tv      . "'VIZIO, Inc E32-C1 0x01010101'")

    ;; Define workspace numbers
    (ws0 . "0")
    (ws1 . "1")
    (ws2 . "2")
    (ws3 . "3")
    (ws4 . "4")
    (ws5 . "5")

    ;; Additional non-pinned workspaces
    (ws6 . "6")
    (ws7 . "7")
    (ws8 . "8")
    (ws9 . "9")

    (bgcolor . "#1d1f21dd")
    (bordercolor . "#5e81accc")
    (lock . ,(string-append "swaylock "
                            "-f --screenshots --clock "
                            "--effect-blur 9x7 "
                            "--effect-vignette 0.25:0.5 "
                            "--grace 60 --fade-in 0.25"))
    (qlock . ,(string-append "swaylock "
                             "-f --screenshots --clock "
                             "--effect-blur 9x7 "
                             "--effect-vignette 0.25:0.5"))
    (lbrt_down . "--locked XF86MonBrightnessDown")
    (rbrt_down . "--release XF86MonBrightnessDown")
    (lbrt_up . "--locked XF86MonBrightnessUp")
    (rbrt_up . "--release XF86MonBrightnessUp")
    (lad_mute . "--locked XF86AudioMute")
    (rad_mute . "--release XF86AudioMute")
    (lad_lv . "--locked  XF86AudioLowerVolume")
    (rad_lv . "--release  XF86AudioLowerVolume")
    (lad_rv . "--locked  XF86AudioRaiseVolume")
    (rad_rv . "--release  XF86AudioRaiseVolume")))

(define %sway-config-base-inputs
  (list (sway-input
          (identifier "type:keyboard")
          (layout (keyboard-layout "us,il" #:options '("ctrl:nocaps"))))
        (sway-input
          (identifier "type:touchpad")
          (tap #t)
          (disable-while-typing #t)
          (extra-content
           '("events disabled")))))

(define %sway-config-base-outputs
  (append
   (list
    (sway-output
      (identifier 'eDP-1)
      (position (point (x 1920) (y 0)))
      (extra-content (list (string-append "scale " (dpi-scale 'eDP-1)))))
    (sway-output
      (identifier "Acer Technologies K243Y TN6AA0018513")
      (position (point (x 0) (y 0)))
      (extra-content (list (string-append "scale " (dpi-scale 'DP)))))
    (sway-output
      (identifier "VIZIO, Inc E32-C1 0x01010101")
      (position (point (x 3566) (y 0)))
      (extra-content (list (string-append "scale " (dpi-scale 'DP)))))
    (sway-output
      (identifier '*)
      (background `(,%bg-path . fill))))))

(define %sway-config-base-keybindings
  `(;; Sway System Controls
    ($mod+Shift+q . "kill")
    ($mod+Shift+x . ,#~(string-append "exec " #$%sway-session-end " exit"))
    ($mod+Shift+r . "reload")

    ;; Toggle Trackpad
    ($mod+Shift+t . ,(string-append
                      "exec swaymsg"
                      " input type:touchpad"
                      " events toggle enabled disabled"))
    ;; Window Focus
    ($mod+h . "focus left")
    ($mod+l . "focus right")

    ;; Move workspace to display (Alt --> Mod1)
    ($mod+Alt+h . "move workspace to output left")
    ($mod+Alt+l . "move workspace to output right")
    ($mod+Alt+Left . "move workspace to output left")
    ($mod+Alt+Right .  "move workspace to output right")

    ;; Alternatively, you can use cursor keys:
    ($mod+Shift+h . "move left 30 px")
    ($mod+Shift+j . "move down 30 px")
    ($mod+Shift+k . "move up 30 px")
    ($mod+Shift+l . "move right 30 px")

    ;; Window State
    ($mod+f       . "fullscreen toggle")
    ($mod+Shift+f . "floating toggle")
    ($mod+Shift+p . "sticky toggle")

    ;; Layout State
    ($mod+s . "layout stacking")
    ($mod+w . "layout tabbed")
    ($mod+e . "layout toggle split")
    ($mod+b . "splith")
    ($mod+v . "splitv")

    ;; change focus between tiling / floating windows
    ($mod+Control+space . "focus mode_toggle")

    ;; App launcher - configured in fuzzel.ini (example of g-exp!)
    ($mod+space . ,#~(string-append "exec "
                                    #$fuzzel
                                    "/bin/fuzzel"))

    ;; Create New Workspaces dynamically
    ($mod+n . ,#~(string-append "exec " #$%sway-new-workspace))

    ;; Switch to workspace
    ($mod+grave . "workspace $ws0")
    ($mod+1     . "workspace $ws1")
    ($mod+2     . "workspace $ws2")
    ($mod+3     . "workspace $ws3")
    ($mod+4     . "workspace $ws4")
    ($mod+5     . "workspace $ws5")

    ;; additional workspaces
    ($mod+6 . "workspace $ws6")
    ($mod+7 . "workspace $ws7")
    ($mod+8 . "workspace $ws8")
    ($mod+9 . "workspace $ws9")

    ;; Other workspace gymnastics
    ($mod+Tab        . "workspace back_and_forth")
    ($mod+period     . "workspace next")
    ($mod+comma      . "workspace prev")

    ;; Move focused container to workspace
    ($mod+Shift+grave . "move container to workspace $ws0")
    ($mod+Shift+1 . "move container to workspace $ws1")
    ($mod+Shift+2 . "move container to workspace $ws2")
    ($mod+Shift+3 . "move container to workspace $ws3")
    ($mod+Shift+4 . "move container to workspace $ws4")
    ($mod+Shift+5 . "move container to workspace $ws5")

    ;; additional workspaces
    ($mod+Shift+6 . "move container to workspace $ws6")
    ($mod+Shift+7 . "move container to workspace $ws7")
    ($mod+Shift+8 . "move container to workspace $ws8")
    ($mod+Shift+9 . "move container to workspace $ws9")

    ;; Lock Screen
    ($mod+Shift+o . "exec $qlock")

    ;; Sway session controls
    ($mod+Shift+space . "exec wlogout -p layer-shell -m 300")

    ;; Screenshots
    (Print . "exec grimshot --notify save output")
    (Alt+Print . "exec grimshot --notify save area")))

(define %sway-config-base-extra-content
  `( ;; Mouse
    "seat seat0 xcursor_theme $cursor_theme $cursor_size"

    ;; Fonts
    "font pango:$titlebar_font $titlebar_text_size"

    ;; Brightness control
    "bindsym $lbrt_down exec brightnessctl set 5%-"
    "bindsym $rbrt_down exec pkill -SIGRTMIN+4 -n gubar"
    "bindsym $lbrt_up exec brightnessctl set 5%+"
    "bindsym $rbrt_up exec pkill -SIGRTMIN+4 -n gubar"

    ;; Volume control
    "bindsym $lad_mute exec pactl set-sink-mute @DEFAULT_SINK@ toggle"
    "bindsym $rad_mute exec pkill -SIGRTMIN+2 -n gubar"
    "bindsym $lad_lv exec pactl set-sink-volume @DEFAULT_SINK@ -5%"
    "bindsym $rad_lv exec pkill -SIGRTMIN+2 -n gubar"
    "bindsym $lad_rv exec pactl set-sink-volume @DEFAULT_SINK@ +5%"
    "bindsym $rad_rv exec pkill -SIGRTMIN+2 -n gubar"

    ;; Audio Player controls
    "bindsym --locked XF86AudioPlay exec playerctl play-pause"
    "bindsym --locked XF86AudioNext exec playerctl next"
    "bindsym --locked XF86AudioPrev exec playerctl previous"

    ;; Set defaults
    "default_orientation horizontal"
    "workspace_layout tabbed"

    ;; Configure gaps and borders
    "default_border pixel 1"
    "gaps outer 0"
    "gaps inner 6"
    "smart_borders off"
    "hide_edge_borders --i3 none"

    ;; Floating Screens
    "floating_modifier $mod"

    ;; Pin Workspaces
    ,@(map (match-lambda
             ((ws num outputs)
              (format #f "workspace $~a output ~a" ws outputs)))
           workspace-list)

    ;; Style the UI
    ;; border | background | text | indicator | child border
    "client.focused $bordercolor $bgcolor #ffffffff #5e81accc #5e81accc"
  "client.unfocused $bordercolor #1c1f2bef #ffffffff #5e81accc #5e81accc"))

(define %sway-base-config-startup+reload-programs
  `( ;; GTK
    ;; This is the only place where you must set GTK scaling
    "gsettings set $gnome_schema gtk-theme $system_theme"
    "gsettings set $gnome_schema color-scheme 'prefer-dark'"
    "gsettings set $gnome_schema icon-theme $system_icons"
    "gsettings set $gnome_schema text-scaling-factor $system_text_scaling_factor"
    "gsettings set $gnome_schema cursor-theme $cursor_theme"
    "gsettings set $gnome_schema cursor-size $cursor_size"))

(define %sway-base-config-startup-programs
  `( ;; Set default brightness & backlight
    "brightnessctl set 50%"
    "brightnessctl -d chromeos::kbd_backlight set 10%"

    ;; Idle screen configuration
    ,(string-append "swayidle -w "
                    "timeout 1800 '$lock' "
                    "timeout 1860 'swaymsg \"output * dpms off\"' "
                    "resume 'swaymsg \"output * dpms on\"' "
                    "timeout 7200 'loginctl suspend' "
                    "before-sleep '$lock'")

    ;; Night Light (Chicago lat/lon)
    ,(string-append "wlsunset -l 41.88 -L -87.63")

    ;; Utility applications
    "mako"
    "udiskie -s"
    "blueman-applet"

    ;;Update DBUS activation records to ensure Flatpak apps work
    ,(string-append "dbus-update-activation-environment "
                    "--systemd DISPLAY WAYLAND_DISPLAY "
                    "XDG_CURRENT_DESKTOP=sway")))

;;;
;;; Sway companion packages
;;;
;;; The sway WM itself lives at system level - these are the user-session
;;; companions sway expects

;; Background, idle, & lock helpers
(define %sway-session
  (list swaybg
        swayidle
        wlsunset
        jq))

;; Launchers, notifications, & user-input UI
(define %sway-ui
  (list fuzzel  ;; app launcher
        wlogout ;; logout/lock UI
        mako))  ;; notification daemon

;; Screenshot & clipboard tooling
(define %sway-clipboard+screenshot
  (list grimshot
        wl-clipboard))

;; Status bar (gubar) and its Guile runtime deps
;; guile-fibers installed system level
(define %sway-gubar
  (list gubar
        guile-hall
        (specification->package "guile-json")))

(define %sway-base-packages
  (append %sway-session
          %sway-ui
          %sway-clipboard+screenshot
          %sway-gubar))

(define* (swaybar->config #:key (identifier 'bar0))
  "Return a sway-bar configuration record."
  (sway-bar
    (identifier identifier)
    (position 'top)
    (status-command "gubar")
    (colors
     (sway-color
       (statusline "#eceff4")
       (background "#2e3440")
       (focused-workspace (sway-border-color
                            (border "#81a1c1")
                            (background "#5e81ac")
                            (text "#eceff4")))
       (active-workspace (sway-border-color
                           (border "#81a1c1")
                           (background "#5e81ac")
                           (text "#eceff4")))
       (inactive-workspace (sway-border-color
                             (border "#2e3440")
                             (background "#4c566a")
                             (text "#d8dee9")))))
    (extra-content
     '("font pango:JetBrains Mono 11"
       "icon_theme Qogir-Dark"
       "tray_bindsym button1 Activate"
       "tray_bindsym button2 ContextMenu"))))

;;;
;;; Service Composition
;;;
(define (sway-configuration-extension config)
  (let ((base (or config %empty-sway-configuration)))
    (sway-configuration
      (inherit base)

      (variables
       (append
        (sway-configuration-variables base)
        %sway-config-base-variables))

      (inputs
       (append
        (sway-configuration-inputs base)
        %sway-config-base-inputs))

      (outputs
       (append
        (sway-configuration-outputs base)
        %sway-config-base-outputs))

      (keybindings
       (append
        (sway-configuration-keybindings base)
        %sway-config-base-keybindings))

      (extra-content
       (append
        (sway-configuration-extra-content base)
        %sway-config-base-extra-content))

      (bar (swaybar->config #:identifier 'gubar))

      (startup+reload-programs
       (append
        (sway-configuration-startup+reload-programs base)
        %sway-base-config-startup+reload-programs))

      (startup-programs
       (append
        (sway-configuration-startup-programs base)
        %sway-base-config-startup-programs))

      ;; for some reason these are not being installed!
      (packages
       (append
        (sway-configuration-packages base)
        %sway-base-packages)))))


(define (home-sway-files-service config)
  "Provide symlinks for other programs configs that Sway uses."
  `(;; Sway Bar --> gubar Configuration
    ;; (".config/gubar"
    ;;  ,(resolve (home-source) "files/gubar"))

    ;; Application Selector
    (".config/mako"
     ,(resolve (home-source) "files/mako"))

    ;; Screen Locking
    (".config/fuzzel"
     ,(resolve (home-source) "files/fuzzel"))

    ;; UI Logout Application
    (".config/wlogout/layout" ,%wlogout-layout)

    (".config/wlogout/style.css"
     ,(resolve (home-source) "files/wlogout/style.css"))

    (".config/wlogout/icons"
     ,(resolve (home-source) "files/wlogout/icons"))

    ;; Default Sway/Wayland Terminal
    (".config/foot"
     ,(resolve (home-source) "files/foot"))))

(define (home-sway-gubar-symlink-service config)
  `(;; Sway Bar --> gubar Configuration (Dev)
    (".config/gubar"
     ,(resolve (home-source) "files/gubar" #:string? #t))
    ))

(define home-sway-configuration-service-type
  (service-type
    (name 'home-sway-config)
    (description "Sway configuration and adjacent app configs.")
    (extensions
     (list
      (service-extension
       home-sway-service-type
       (lambda (config)
         (sway-configuration-extension %empty-sway-configuration)))
      (service-extension
       home-files-service-type
       home-sway-files-service)
      (service-extension
       home-impure-symlinks-service-type
       home-sway-gubar-symlink-service)))
    (default-value #f)))
