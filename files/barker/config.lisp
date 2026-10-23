;;;; SPDX-License-Identifier: LGPL-2.1-only WITH LLGPL
;;;; Copyright (C) 2026 Erik P Almaraz
;;;;
;;;; Licensed under the LGPL-2.1-only with the LLGPL preamble;
;;;; see the LICENSE file in this repository.


(defblock guixos
  :kind label
  :text "GuixOS"
  :color "#81a1c1"
  :click-handler nil)

(defblock network-manager
  :ssid t)

(defblock brightness
  :nerd-icons t)

(defblock volume)

(defblock battery
  :nerd-icons t)

(defblock clock
  :format "%a %b %d %Y %-I:%M:%S %p")
