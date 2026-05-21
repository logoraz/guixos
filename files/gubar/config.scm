;; -*- mode: scheme -*-
(define-module (files gubar config)
  #:use-module (gubar gublock)
  #:use-module (gubar swaybar-protocol)
  #:use-module (gubar blocks date-time)
  #:use-module (gubar blocks label)
  #:use-module (gubar blocks volume-pipewire)
  #:use-module (gubar blocks brightness)
  #:use-module (gubar blocks battery)
  #:use-module (gubar blocks network-manager-wifi)
  #:use-module (srfi srfi-1))


;;; Custom Gublocks

;; load "/home/logoraz/.config/gubar/blocks/battery.scm")
;; (use-modules (files gubar blocks battery))

;; (load "/home/logoraz/.config/gubar/blocks/network-manager-wifi2.scm")
;; (use-modules (files gubar blocks network-manager-wifi2))~Rm"VadA,^m4Aw_

;; (load "/home/logoraz/.config/gubar/blocks/brightness.scm")
;; (use-modules (files gubar blocks brightness))

;;; Configure sway-bar
(list
 (label "GuixOS" #:color "#81a1c1")
 (network-manager-wifi #:ssid #t)
 (brightness #:nerd-icons #t)
 (volume-pipewire)
 (battery #:nerd-icons #t)
 (date-time #:interval 0.1 #:format "%a %b %d %Y %-I:%M:%S %p"))
