(define-module (guixos home services environment)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (guix gexp)
  #:export (home-env-vars-configuration-service-type))


;;;
;;; GTK Configuration Data
;;;
(define %gtk-theme         "Adwaita:dark")
(define %gtk-theme-name    "Adwaita-dark")  ; settings.ini wants the bare name
(define %gtk-icon-theme    "Qogir-Dark")
(define %xcursor-theme     "Bibata-Modern-Classic")
(define %xcursor-size      "20")

(define %gtk2-rc (string-append "$HOME/.guix-home/profile/share/"
                                "themes/Adwaita-dark/gtk-2.0/gtkrc"))

(define %xdg-data-dirs (string-append "$HOME/.guix-home/profile/share:"
                                      "/run/current-system/profile/share:"
                                      "$XDG_DATA_HOME/flatpak/exports/share:"))

;;;
;;; Build-Time Assets
;;;
(define %gtk3-settings
  (mixed-text-file
   "settings.ini"
   "[Settings]\n"
   "gtk-theme-name=" %gtk-theme-name "\n"
   "gtk-icon-theme-name=" %gtk-icon-theme "\n"
   "gtk-cursor-theme-name=" %xcursor-theme "\n"
   "gtk-cursor-theme-size=" %xcursor-size "\n"))

;; Disable session suspend on ALSA/BlueZ nodes so audio devices
;; don't drop in/out on idle.
(define %wireplumber-no-suspend
  (mixed-text-file
   "52-disable-suspend.conf"
   "monitor.alsa.rules = [\n"
   "  {\n"
   "    matches = [\n"
   "      { node.name = \"~alsa_input.*\" }\n"
   "      { node.name = \"~alsa_output.*\" }\n"
   "    ]\n"
   "    actions = {\n"
   "      update-props = {\n"
   "        session.suspend-timeout-seconds = 0\n"
   "      }\n"
   "    }\n"
   "  }\n"
   "]\n"
   "\n"
   "monitor.bluez.rules = [\n"
   "  {\n"
   "    matches = [\n"
   "      { node.name = \"~bluez_input.*\" }\n"
   "      { node.name = \"~bluez_output.*\" }\n"
   "    ]\n"
   "    actions = {\n"
   "      update-props = {\n"
   "        session.suspend-timeout-seconds = 0\n"
   "      }\n"
   "    }\n"
   "  }\n"
   "]\n"))

;;;
;;; Service Composition
;;;
;; borrowed from https://codeberg.org/daviwil/dotfiles/daviwil/systems/common.scm
(define (home-env-vars-config-gexp config)
  `( ;; Sort hidden (dot) files first in ls listings
    ("LC_COLLATE" . "C")

    ;; Set Emacs as editor
    ("EDITOR" . "emacsclient -c -a emacs")
    ("VISUAL" . "emacsclient -c -a emacs")

    ;; Set quotebrowser as the default
    ("BROWSER" . "Zen Browser")

    ;; Set GnuPG Config Dir env
    ("GNUPGHOME" . "$XDG_CONFIG_HOME/gnupg")

    ;; Set wayland-specific environment variables
    ("XDG_CURRENT_DESKTOP" . "sway")
    ("XDG_SESSION_TYPE"    . "wayland")
    ("RTC_USE_PIPEWIRE"    . "true")
    ("SDL_VIDEODRIVER"     . "wayland")
    ("MOZ_ENABLE_WAYLAND"  . "1")
    ("CLUTTER_BACKEND"     . "wayland")
    ("ELM_ENGINE"          . "wayland-egl")
    ("ECORE_EVAS_ENGINE"   . "wayland-egl")

    ;; GTK/QT/Cursor Theming
    ("GTK_THEME"            . ,%gtk-theme)
    ("GTK_ICON_THEME"       . ,%gtk-icon-theme)
    ("GTK2_RC_FILES"        . ,%gtk2-rc)

    ("QT_STYLE_OVERRIDE"    . "adwaita")
    ("QT_QPA_PLATFORMTHEME" . "gtk3")
    ("QT_QPA_PLATFORM"      . "wayland") ;wayland-egl ?

    ("XCURSOR_THEME" . ,%xcursor-theme)
    ("XCURSOR_SIZE"  . ,%xcursor-size)

    ;; Set XDG environment variables
    ("XDG_LOG_HOME"        . "$HOME/.local/log")
    ("XDG_DOWNLOAD_DIR"    . "$HOME/Downloads")
    ("XDG_PICTURES_DIR"    . "$HOME/Pictures")
    ("XDG_SCREENSHOTS_DIR" . "$HOME/Pictures/Screenshots")

    ;; Flatpak integration
    ("XDG_LOCAL_BIN"    . "$HOME/.local/bin")
    ("XDG_DATA_DIRS"    . ,%xdg-data-dirs)

    ;; Local user binaries (e.g. ocicl, cargo, etc.) on PATH
    ("PATH" . "$XDG_LOCAL_BIN:$PATH")))

(define (home-env-vars-files-service config)
  `((".config/gtk-3.0/settings.ini" ,%gtk3-settings)
    (".config/wireplumber/wireplumber.conf.d/52-disable-suspend.conf"
     ,%wireplumber-no-suspend)))

(define home-env-vars-configuration-service-type
  (service-type (name 'home-profile-env-vars-service)
                (description "Service for profile env vars & related runtime config")
                (extensions
                 (list (service-extension
                        home-environment-variables-service-type
                        home-env-vars-config-gexp)
                       (service-extension
                        home-files-service-type
                        home-env-vars-files-service)))
                (default-value #f)))
